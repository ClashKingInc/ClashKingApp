import type { BookmarkService } from '../../core/bookmarks';
import { canonicalTag } from '../../core/domain/tags';
import { playerClanTagStorageKey, type StringStorage } from '../../core/storage/storage';
import { mapWithConcurrencyLimit } from '../../core/utils/bounded-concurrency';
import type { ClanService } from '../clan/data';
import type { PlayerCardPreferencesService, PlayerService } from '../player/data';
import type { UpgradeTrackerRepository, UpgradeWidgetSyncService } from '../upgrade-tracker/data';
import type { WarCwlService } from '../war/data';
import type { WarWidgetService } from '../widgets';
import type { CocAccountService } from './account-service';
import type { CocAccountLink } from './models';

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
  readonly reportError?: (operation: string, error: unknown) => void;
}

/** Shared post-session hydration used by both cold start and completed login. */
export class AccountBootstrapService {
  constructor(private readonly dependencies: AccountBootstrapDependencies) {}

  async initialize(userId: string | null): Promise<void> {
    const { accounts, bookmarks, players, playerCardPreferences, upgrades, upgradeWidgets } =
      this.dependencies;
    accounts.setCurrentUserId(userId);
    bookmarks.setCurrentUserId(userId);

    if (userId === null) {
      playerCardPreferences?.clear();
      players.clearRankedLeagueCache();
      upgrades?.clearCache();
      await upgradeWidgets?.clear();
    }

    await Promise.all([
      accounts.loadSelectedTag(),
      ...(bookmarks.loaded ? [] : [bookmarks.load()]),
      ...(userId !== null && playerCardPreferences && !playerCardPreferences.loaded
        ? [playerCardPreferences.load()]
        : []),
    ]);

    const bookmarkedPlayerTags = bookmarks.players.map((player) => player.tag);
    const bookmarkedClanTags = bookmarks.clans.map((clan) => clan.tag);
    await Promise.all([
      this.loadLinkedAccountData(bookmarkedClanTags),
      ...(bookmarkedPlayerTags.length
        ? [players.hydrateBookmarkedPlayers(bookmarkedPlayerTags)]
        : []),
    ]);

    void this.dependencies.warWidgets
      ?.seedClanOptionsFromProfiles(players.profiles, {
        bookmarkedClans: bookmarks.clans,
        selectedPlayerTag: accounts.selectedTag,
        refreshWarData: true,
      })
      .catch((error: unknown) => this.report('accountBootstrap.warWidgets', error));
  }

  /** Flutter's pull-to-refresh path: keep links stable, refresh every hydrated
   * domain, and await the auxiliary Home cards before advancing lastRefresh. */
  async refresh(): Promise<void> {
    const { accounts, bookmarks } = this.dependencies;
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
    } = {},
  ): Promise<void> {
    const { accounts, players, clans, wars } = this.dependencies;
    const links = options.links ?? (await accounts.fetchAccounts());
    this.dependencies.upgrades?.configureRemote({
      accountId: links.length ? accounts.userId : null,
      verifiedPlayerTags: links.filter((link) => link.isVerified).map((link) => link.playerTag),
    });
    if (!links.length) return;

    const playerTags = links.map((account) => account.playerTag);
    const rankedWarmup = players.prefetchRankedLeagueData(
      playerTags,
      options.forceAuxiliaryRefresh ?? false,
    );
    const upgradeWarmup = this.warmUpgradeTracker(links, options.forceAuxiliaryRefresh ?? false);
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
    const optimisticClanTags = uniqueNonEmpty([
      ...cachedClanTagsByPlayer.values(),
      ...bookmarkedClanTags,
    ]);
    const optimisticClanLoad = optimisticClanTags.length
      ? this.loadInitialClanData(optimisticClanTags)
      : Promise.resolve();

    const clanTagsByPlayer = await players.loadOfficialPlayerData(playerTags, {
      notify: false,
      throwOnError: true,
    });
    const discoveredClanTags = uniqueNonEmpty([
      ...players.profiles.map((profile) => profile.clanTag),
      ...Object.values(clanTagsByPlayer),
    ]);
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

  private async warmUpgradeTracker(
    links: readonly {
      playerTag: string;
      isVerified: boolean;
      raw: Readonly<Record<string, unknown>>;
    }[],
    forceRefresh = false,
  ): Promise<void> {
    const { upgrades, upgradeWidgets, accounts } = this.dependencies;
    if (!upgrades) return;
    const verified = links.filter((link) => link.isVerified);
    const snapshots = (
      await mapWithConcurrencyLimit(verified, async (link) => {
        try {
          return await upgrades.load(link.playerTag, forceRefresh);
        } catch {
          return null;
        }
      })
    ).filter((snapshot) => snapshot !== null);
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
