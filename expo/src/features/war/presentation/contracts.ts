import type { BookmarkedClan, BookmarkedPlayer } from '../../../core/bookmarks/bookmark-service';
import type { Clan } from '../../clan/models';
import type { Player } from '../../player/models/player';
import type { WarCwl, WarInfo } from '../models';

export interface WarPresentationModel {
  /** Profiles can include hydrated bookmarks; ownedPlayerTags is the authority for linked accounts. */
  readonly profiles: readonly Player[];
  readonly ownedPlayerTags: readonly string[];
  readonly bookmarkedPlayers: readonly BookmarkedPlayer[];
  readonly bookmarkedClans: readonly BookmarkedClan[];
  readonly hydratedBookmarkedClans: readonly Clan[];
  readonly summaries: ReadonlyMap<string, WarCwl>;
  readonly hiddenPlayerTags?: ReadonlySet<string>;
  readonly lastRefresh?: Date;
}

export interface WarPresentationActions {
  refresh(): Promise<void>;
  hydrateBookmarkedPlayers(tags: readonly string[]): Promise<void>;
  loadWarSummaries(tags: readonly string[]): Promise<void>;
  isNetworkError(error: unknown): boolean;
  openNetworkError(retry: () => Promise<void>): void;
  showMessage(message: string): void;
  openClan(tag: string): void;
  openPlayer(tag: string): void;
  copyText(value: string): Promise<void>;
  exportCwl?(clanTag: string): Promise<void>;
  fetchPreviousWar?(clanTag: string, before: Date): Promise<WarInfo | null>;
}

export interface WarAccountItem {
  readonly tag: string;
  readonly name: string;
  readonly bookmarked: boolean;
}

export interface WarAccountStatus {
  readonly account: WarAccountItem;
  readonly inWar: boolean;
  readonly done: number;
  readonly left: number;
}

export interface WarRosterItem {
  readonly tag: string;
  readonly name: string;
  readonly badgeUrl: string;
  readonly bookmarked: boolean;
  readonly accounts: readonly WarAccountItem[];
  readonly clan: Clan | null;
  readonly summary: WarCwl | null;
  readonly displayWar: WarInfo | null;
  readonly cwlRoundNumber: number | null;
  readonly cwlRank: number | null;
  readonly sortWeight: number;
  readonly accountStatuses: readonly WarAccountStatus[];
}

export interface WarRosterBuildResult {
  readonly items: readonly WarRosterItem[];
  readonly missingBookmarkedPlayerTags: readonly string[];
  readonly missingWarClanTags: readonly string[];
}

export function normalizeTagKey(tag: string): string {
  return tag.replaceAll('#', '').trim().toUpperCase();
}

export function buildWarRoster(model: WarPresentationModel): WarRosterBuildResult {
  const owned = new Set(model.ownedPlayerTags.map(normalizeTagKey));
  const hidden = new Set(Array.from(model.hiddenPlayerTags ?? []).map(normalizeTagKey));
  const profilesByTag = new Map(
    model.profiles.map((profile) => [normalizeTagKey(profile.tag), profile]),
  );
  const ownedProfiles = model.profiles.filter(
    (profile) =>
      owned.has(normalizeTagKey(profile.tag)) && !hidden.has(normalizeTagKey(profile.tag)),
  );
  const bookmarkedPlayers = model.bookmarkedPlayers.filter(
    (bookmark) =>
      !owned.has(normalizeTagKey(bookmark.tag)) &&
      !hidden.has(normalizeTagKey(bookmark.tag)) &&
      bookmark.clanTag.length > 0,
  );
  const missingBookmarkedPlayerTags = bookmarkedPlayers
    .filter((bookmark) => !profilesByTag.has(normalizeTagKey(bookmark.tag)))
    .map((bookmark) => bookmark.tag);

  const linkedClans = new Map<string, Clan>();
  for (const profile of ownedProfiles) {
    const clan = asClan(profile.clan);
    if (clan?.tag) linkedClans.set(clan.tag, clan);
  }

  const accountsByClan = new Map<string, WarAccountItem[]>();
  const addAccount = (clanTag: string, account: WarAccountItem) => {
    if (!clanTag) return;
    const accounts = accountsByClan.get(clanTag) ?? [];
    accounts.push(account);
    accountsByClan.set(clanTag, accounts);
  };
  ownedProfiles.forEach((profile) =>
    addAccount(profile.clanTag, { tag: profile.tag, name: profile.name, bookmarked: false }),
  );

  const hydratedByTag = new Map(model.hydratedBookmarkedClans.map((clan) => [clan.tag, clan]));
  for (const bookmark of bookmarkedPlayers) {
    const clan = asClan(profilesByTag.get(normalizeTagKey(bookmark.tag))?.clan);
    if (clan) hydratedByTag.set(clan.tag, clan);
  }
  const bookmarkSnapshotByTag = new Map(
    model.bookmarkedClans.map((bookmark) => [bookmark.tag, bookmark]),
  );
  const bookmarkNameByTag = new Map(
    bookmarkedPlayers.map((bookmark) => [bookmark.clanTag, bookmark.clanName]),
  );
  const bookmarkedClanTags = unique([
    ...model.bookmarkedClans.map((bookmark) => bookmark.tag),
    ...bookmarkedPlayers.map((bookmark) => {
      const profile = profilesByTag.get(normalizeTagKey(bookmark.tag));
      return profile?.clanTag || bookmark.clanTag;
    }),
  ]).filter((tag) => tag && !linkedClans.has(tag));

  const summaries = new Map(
    Array.from(model.summaries.entries()).map(([tag, summary]) => [normalizeHash(tag), summary]),
  );
  const inputs = [
    ...Array.from(linkedClans.values()).map((clan) => ({
      clan,
      tag: clan.tag,
      name: clan.name,
      badgeUrl: clan.badgeUrls.smallest,
      bookmarked: false,
    })),
    ...bookmarkedClanTags.map((tag) => {
      const clan = hydratedByTag.get(tag) ?? null;
      const snapshot = bookmarkSnapshotByTag.get(tag);
      return {
        clan,
        tag,
        name: clan?.name || snapshot?.name || bookmarkNameByTag.get(tag) || tag,
        badgeUrl: clan?.badgeUrls.smallest || snapshot?.badgeUrl || '',
        bookmarked: true,
      };
    }),
  ];

  const items = inputs.map<WarRosterItem>((input) => {
    const summary = summaries.get(normalizeHash(input.tag)) ?? null;
    const displayWar = resolveDisplayWar(summary, input.tag);
    const round =
      summary?.isInCwl && !summary.isInWar && displayWar
        ? (summary.leagueInfo?.rounds.find((value) => value.containsWar(displayWar.tag)) ?? null)
        : null;
    const accounts = accountsByClan.get(input.tag) ?? [];
    const accountStatuses = displayWar
      ? accounts.map((account) => accountStatus(account, displayWar, input.tag))
      : [];
    const linked = accounts.length > 0 && !input.bookmarked;
    const inLineup = accountStatuses.some((status) => status.inWar);
    const active =
      displayWar !== null && !['notInWar', 'unknown', 'accessDenied'].includes(displayWar.state);
    const sortWeight =
      linked && inLineup && displayWar?.state === 'inWar'
        ? 0
        : linked && inLineup && displayWar?.state === 'preparation'
          ? 1
          : linked && active
            ? 2
            : input.bookmarked && active
              ? 3
              : linked
                ? 4
                : input.bookmarked
                  ? 5
                  : 6;
    return {
      ...input,
      accounts,
      summary,
      displayWar,
      cwlRoundNumber: round?.roundNumber ?? null,
      cwlRank: round ? (summary?.leagueInfo?.getClanDetails(input.tag)?.rank ?? null) : null,
      sortWeight,
      accountStatuses,
    };
  });
  items.sort((left, right) => left.sortWeight - right.sortWeight);

  return {
    items,
    missingBookmarkedPlayerTags,
    missingWarClanTags: bookmarkedClanTags.filter((tag) => !summaries.has(normalizeHash(tag))),
  };
}

function accountStatus(account: WarAccountItem, war: WarInfo, clanTag: string): WarAccountStatus {
  const inWar = war.isPlayerInWar(account.tag, clanTag);
  const done = inWar ? war.getAttacksDoneByPlayer(account.tag, clanTag) : 0;
  const total = war.effectiveAttacksPerMember;
  return { account, inWar, done, left: inWar ? Math.max(0, total - done) : 0 };
}

function resolveDisplayWar(summary: WarCwl | null, tag: string): WarInfo | null {
  if (!summary) return null;
  if (summary.isInWar) return summary.warInfo;
  if (summary.isInCwl) return summary.getActiveWarByTag(tag);
  return null;
}

function normalizeHash(tag: string): string {
  const key = normalizeTagKey(tag);
  return key ? `#${key}` : '';
}

function unique(values: readonly string[]): string[] {
  return [...new Set(values)];
}

function asClan(value: unknown): Clan | null {
  if (!value || typeof value !== 'object') return null;
  const clan = value as Partial<Clan>;
  return typeof clan.tag === 'string' && typeof clan.name === 'string' ? (value as Clan) : null;
}
