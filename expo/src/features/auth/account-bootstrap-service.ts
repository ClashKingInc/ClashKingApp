import type { BookmarkService } from '../../core/bookmarks';
import { canonicalTag } from '../../core/domain/tags';
import { playerClanTagStorageKey, type StringStorage } from '../../core/storage/storage';
import { mapWithConcurrencyLimit } from '../../core/utils/bounded-concurrency';
import type { ClanService } from '../clan/data';
import type { PlayerCardPreferencesService, PlayerService } from '../player/data';
import type { UpgradeTrackerRepository, UpgradeWidgetSyncService } from '../upgrade-tracker/data';
import type { WarCwlService } from '../war/data';
import type { WarWidgetService } from '../widgets';
import type { LegendsWidgetService } from '../widgets/legends-widget-service';
import {
  readHomeStartupSnapshot,
  type HomeStartupPreview,
  type HomeStartupSnapshot,
} from '../home/data/home-startup-snapshot';
import type { CocAccountService } from './account-service';
import type { CocAccountLink } from './models';

// Give a fast profile response time to win before mounting the temporary card.
const HOME_PREVIEW_GRACE_MS = 250;

export interface AccountBootstrapDependencies {
  readonly accounts: CocAccountService;
  readonly bookmarks: BookmarkService;
  readonly players: PlayerService;
  readonly playerCardPreferences?: PlayerCardPreferencesService;
  readonly clans: ClanService;
  readonly wars: WarCwlService;
  readonly upgrades?: UpgradeTrackerRepository;
  readonly upgradeWidgets?: UpgradeWidgetSyncService;
  readonly storage: StringStorage;
  readonly warWidgets?: Pick<WarWidgetService, 'seedClanOptionsFromProfiles'>;
  readonly legendsWidgets?: Pick<LegendsWidgetService, 'syncBookmarkedPlayers' | 'clear'>;
  readonly reportError?: (operation: string, error: unknown) => void;
}

interface AccountBootstrapInitializeOptions {
  readonly links?: readonly CocAccountLink[];
  readonly selectedTagLoaded?: boolean;
  readonly onSelectedAccountReady?: () => void;
  readonly onHomeSnapshot?: (snapshot: HomeStartupSnapshot) => void;
  readonly isCurrent?: () => boolean;
}

/** Shared post-session hydration used by both cold start and completed login. */
export class AccountBootstrapService {
  private homeHydration?: { done: Promise<void>; isCurrent: () => boolean };

  constructor(private readonly dependencies: AccountBootstrapDependencies) {}

  initializeHome(
    userId: string,
    links: readonly CocAccountLink[],
    isCurrent: () => boolean,
  ): Promise<HomeStartupPreview | null> {
    let finishSelected!: () => void;
    const selectedReady = new Promise<void>((resolve) => {
      finishSelected = resolve;
    });
    return new Promise((resolve) => {
      const finish = () => {
        finishSelected();
        resolve(null);
      };
      const isActive = () => isCurrent() && this.dependencies.accounts.accounts === links;
      const done = this.initialize(userId, {
        links,
        selectedTagLoaded: true,
        onSelectedAccountReady: finish,
        onHomeSnapshot: (snapshot) => resolve({ snapshot, selectedReady }),
        isCurrent: isActive,
      }).catch((error) => this.report('startup.accountBootstrap', error));
      const hydration = { done, isCurrent: isActive };
      this.homeHydration = hydration;
      void done.finally(() => {
        if (this.homeHydration === hydration) this.homeHydration = undefined;
        finish();
      });
    });
  }

  async initialize(
    userId: string | null,
    options: AccountBootstrapInitializeOptions = {},
  ): Promise<void> {
    const { accounts, bookmarks, players, playerCardPreferences, upgrades, upgradeWidgets } =
      this.dependencies;
    const isCurrent = options.isCurrent ?? (() => true);
    if (!isCurrent()) return;
    accounts.setCurrentUserId(userId);
    bookmarks.setCurrentUserId(userId);
    if (options.onSelectedAccountReady && options.links) this.configureUpgradeTracker(options.links);

    if (userId === null) {
      playerCardPreferences?.clear();
      players.clearRankedLeagueCache();
      upgrades?.clearCache();
      await upgradeWidgets?.clear();
      await this.dependencies.legendsWidgets?.clear();
    }

    const preferences = Promise.all([
      ...(options.selectedTagLoaded ? [] : [accounts.loadSelectedTag()]),
      ...(userId !== null && playerCardPreferences && !playerCardPreferences.loaded
        ? [playerCardPreferences.load()]
        : []),
    ]);
    const bookmarkLoad = bookmarks.loaded ? Promise.resolve() : bookmarks.load();
    const selectedLoad = options.onSelectedAccountReady
      ? preferences.then(async () => {
          if (!isCurrent()) return;
          const links = options.links ?? [];
          const verified = links.filter((link) => link.isVerified);
          const selectedTag = canonicalTag(accounts.selectedTag ?? '');
          const tag = (
            verified.find((link) => canonicalTag(link.playerTag) === selectedTag) ?? verified[0]
          )?.playerTag;
          const selectedProfile = tag
            ? players.loadOfficialPlayerData([tag], { throwOnError: false }).catch((error) => {
                this.report('accountBootstrap.selectedPlayer', error);
              })
            : Promise.resolve();
          let previewTimer: ReturnType<typeof setTimeout> | undefined;
          let selectedSettled = false;
          if (userId && tag && canonicalTag(tag) === selectedTag && options.onHomeSnapshot) {
            void readHomeStartupSnapshot(this.dependencies.storage, userId, tag).then((snapshot) => {
              if (!snapshot || selectedSettled || !isCurrent()) return;
              previewTimer = setTimeout(() => {
                if (!isCurrent() || canonicalTag(accounts.selectedTag ?? '') !== selectedTag) return;
                const visible =
                  !playerCardPreferences ||
                  (playerCardPreferences.isShownInTodoPage(tag) &&
                    playerCardPreferences.homeIncludedTags(verified.map((link) => link.playerTag), tag)
                      .some((included) => canonicalTag(included) === selectedTag));
                if (visible) options.onHomeSnapshot?.(snapshot);
              }, HOME_PREVIEW_GRACE_MS);
            });
          }
          await selectedProfile;
          selectedSettled = true;
          clearTimeout(previewTimer);
          if (!isCurrent()) return;
          const remaining = links
            .map((link) => link.playerTag)
            .filter((other) => !tag || canonicalTag(other) !== canonicalTag(tag));
          const profiles = remaining.length
            ? players.loadOfficialPlayerData(remaining, { throwOnError: false }).catch((error) => {
                this.report('accountBootstrap.players', error);
                return {};
              })
            : Promise.resolve({});
          options.onSelectedAccountReady?.();
          return { tag, profiles };
        })
      : Promise.resolve(undefined);
    const [selected] = await Promise.all([
      selectedLoad,
      preferences,
      options.onSelectedAccountReady
        ? bookmarkLoad.catch((error) => this.report('accountBootstrap.bookmarks', error))
        : bookmarkLoad,
    ]);
    if (!isCurrent()) return;

    const bookmarkedPlayerTags = bookmarks.players
      .map((player) => player.tag)
      .filter((tag) => !selected?.tag || canonicalTag(tag) !== canonicalTag(selected.tag));
    const bookmarkedClanTags = bookmarks.clans.map((clan) => clan.tag);
    await Promise.all([
      this.loadLinkedAccountData(bookmarkedClanTags, {
        links: options.links,
        profiles: selected?.profiles,
        isCurrent,
      }),
      ...(bookmarkedPlayerTags.length
        ? [players.hydrateBookmarkedPlayers(bookmarkedPlayerTags)]
        : []),
    ]);
    if (!isCurrent()) return;

    if (userId !== null) {
      void this.dependencies.legendsWidgets
        ?.syncBookmarkedPlayers(bookmarks.players)
        .catch((error: unknown) => this.report('accountBootstrap.legendsWidgets', error));
    }

    void this.dependencies.warWidgets
      ?.seedClanOptionsFromProfiles(
        players.profiles.filter((player) =>
          accounts.accounts.some(
            (account) => account.playerTag.toUpperCase() === player.tag.toUpperCase(),
          ),
        ),
        {
          bookmarkedClans: bookmarks.clans,
          hydratedClans: [...this.dependencies.clans.clans.values()],
          selectedPlayerTag: accounts.selectedTag,
          refreshWarData: true,
        },
      )
      .catch((error: unknown) => this.report('accountBootstrap.warWidgets', error));
  }

  /** Flutter's pull-to-refresh path: keep links stable, refresh every hydrated
   * domain, and await the auxiliary Home cards before advancing lastRefresh. */
  async refresh(): Promise<void> {
    const { accounts, bookmarks } = this.dependencies;
    const hydration = this.homeHydration;
    if (hydration?.isCurrent()) {
      await hydration.done;
      if (!hydration.isCurrent()) return;
    }
    const links = accounts.accounts;
    if (!links.length) return;
    await this.loadLinkedAccountData(
      bookmarks.clans.map((clan) => clan.tag),
      { links, forceAuxiliaryRefresh: true },
    );
  }

  private async loadLinkedAccountData(
    bookmarkedClanTags: readonly string[],
    options: {
      links?: readonly CocAccountLink[];
      forceAuxiliaryRefresh?: boolean;
      profiles?: Promise<Readonly<Record<string, string>>>;
      isCurrent?: () => boolean;
    } = {},
  ): Promise<void> {
    const { accounts, players, clans, wars } = this.dependencies;
    const links = options.links ?? (await accounts.fetchAccounts());
    const isCurrent = options.isCurrent ?? (() => true);
    if (!isCurrent()) return;
    if (!options.profiles) this.configureUpgradeTracker(links);
    if (!links.length) {
      await accounts.initializeSelectedTag();
      return;
    }

    const playerTags = links.map((account) => account.playerTag);
    const verifiedTags = links.filter((link) => link.isVerified).map((link) => link.playerTag);
    const rankedTags = verifiedTags;
    const rankedWarmup = players.prefetchRankedLeagueData(
      rankedTags,
      options.forceAuxiliaryRefresh ?? false,
    );
    const upgradeWarmup = this.warmUpgradeTracker(
      links,
      options.forceAuxiliaryRefresh ?? false,
      isCurrent,
    );
    // Flutter deliberately keeps these outside startup's awaited critical
    // path, but pull-to-refresh awaits both so its timestamp covers the cards.
    if (!options.forceAuxiliaryRefresh) {
      void rankedWarmup.catch((error: unknown) =>
        this.report('accountBootstrap.rankedWarmup', error),
      );
      void upgradeWarmup.catch((error: unknown) =>
        this.report('accountBootstrap.upgradeWarmup', error),
      );
    }

    const cachedClanTagsByPlayer = await this.cachedClanTagsByPlayer(playerTags);
    if (!isCurrent()) return;
    const optimisticClanTags = uniqueNonEmpty([
      ...cachedClanTagsByPlayer.values(),
      ...bookmarkedClanTags,
    ]);
    const optimisticClanLoad = optimisticClanTags.length
      ? this.loadInitialClanData(optimisticClanTags)
      : Promise.resolve();

    let clanTagsByPlayer: Readonly<Record<string, string>> = {};
    try {
      clanTagsByPlayer = await (options.profiles ??
        players.loadOfficialPlayerData(playerTags, {
          notify: false,
          throwOnError: false,
          forceRefresh: options.forceAuxiliaryRefresh ?? false,
        }));
    } catch (error) {
      this.report('accountBootstrap.players', error);
    }
    if (!isCurrent()) {
      await optimisticClanLoad;
      return;
    }
    const discoveredClanTags = uniqueNonEmpty([
      ...players.profiles.map((profile) => profile.clanTag),
      ...Object.values(clanTagsByPlayer),
    ]);
    if (!isCurrent()) return;
    const optimisticSet = new Set(optimisticClanTags);
    const missingClanTags = discoveredClanTags.filter((tag) => !optimisticSet.has(tag));

    await Promise.all([
      optimisticClanLoad,
      ...(missingClanTags.length ? [this.loadInitialClanData(missingClanTags)] : []),
      ...(options.forceAuxiliaryRefresh ? [rankedWarmup, upgradeWarmup] : []),
    ]);

    const allClanTags = uniqueNonEmpty([...optimisticClanTags, ...discoveredClanTags]);
    if (allClanTags.length) {
      players.linkClansToPlayer(players.profiles, [...clans.clans.values()]);
      clans.linkWarsToClans([...clans.clans.values()], [...wars.summaries.values()]);
    }
    players.notifyDataChanged();
    clans.notifyDataChanged();
    wars.notifyDataChanged();
    accounts.updateRefreshTime();
    await accounts.initializeSelectedTag();
  }

  private configureUpgradeTracker(links: readonly CocAccountLink[]): void {
    const { accounts, upgrades } = this.dependencies;
    upgrades?.configureRemote({
      accountId: links.length ? accounts.userId : null,
      verifiedPlayerTags: links.filter((link) => link.isVerified).map((link) => link.playerTag),
    });
  }

  private async warmUpgradeTracker(
    links: readonly {
      playerTag: string;
      isVerified: boolean;
      raw: Readonly<Record<string, unknown>>;
    }[],
    forceRefresh: boolean,
    isCurrent: () => boolean,
  ): Promise<void> {
    const { upgrades, upgradeWidgets, accounts } = this.dependencies;
    if (!upgrades) return;
    const verified = links.filter((link) => link.isVerified);
    const homeAccounts = verified.filter(
      (link) =>
        !this.dependencies.playerCardPreferences ||
        this.dependencies.playerCardPreferences.isUpgradeTrackerShownOnHome(link.playerTag),
    );
    const snapshots = (
      await mapWithConcurrencyLimit(homeAccounts, async (link) => {
        try {
          return await upgrades.load(link.playerTag, forceRefresh);
        } catch {
          return null;
        }
      })
    ).filter((snapshot) => snapshot !== null);
    if (!isCurrent()) return;
    await upgradeWidgets?.sync(snapshots, {
      selectedTag: accounts.selectedTag,
      linkedAccounts: verified.map((link) => ({
        tag: link.playerTag,
        name: link.raw.player_name ?? link.raw.name,
        townHallLevel: link.raw.town_hall_level ?? link.raw.townHallLevel,
        builderHallLevel: link.raw.builder_hall_level ?? link.raw.builderHallLevel,
      })),
    });
  }

  private async cachedClanTagsByPlayer(
    playerTags: readonly string[],
  ): Promise<Map<string, string>> {
    const entries = await Promise.all(
      playerTags.map(async (rawTag) => {
        const tag = canonicalTag(rawTag);
        if (!tag) return null;
        const clanTag = await this.dependencies.storage.getString(playerClanTagStorageKey(tag));
        return clanTag ? ([tag, clanTag] as const) : null;
      }),
    );
    return new Map(entries.filter((entry): entry is readonly [string, string] => entry !== null));
  }

  private async loadInitialClanData(clanTags: readonly string[]): Promise<void> {
    const { clans, wars } = this.dependencies;
    await Promise.all([
      clans.loadAllClanData(clanTags, { notify: false, throwOnError: false }),
      wars.loadAllWarData(clanTags, { notify: false, throwOnError: false }),
    ]);
  }

  private report(operation: string, error: unknown): void {
    this.dependencies.reportError?.(operation, error);
  }
}

function uniqueNonEmpty(tags: readonly string[]): string[] {
  return [...new Set(tags.filter((tag) => tag.length > 0))];
}
