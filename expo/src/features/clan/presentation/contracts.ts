import type { BookmarkedClan } from '../../../core/bookmarks/bookmark-service';
import type { Player } from '../../player/models/player';
import type { Clan } from '../models';

export interface ClansPresentationModel {
  readonly profiles: readonly Player[];
  readonly bookmarks: readonly BookmarkedClan[];
  readonly hydratedClans: readonly Clan[];
  readonly lastRefresh?: Date;
}

export interface ClansPresentationActions {
  refresh(): Promise<void>;
  isNetworkError(error: unknown): boolean;
  openNetworkError(retry: () => Promise<void>): void;
  showMessage(message: string): void;
  hydrateBookmarkedClans(tags: readonly string[]): Promise<void>;
  loadClan(tag: string): Promise<Clan>;
  openClan(clan: Clan): void;
}

export interface ClanRosterItem {
  readonly tag: string;
  readonly name: string;
  readonly badgeUrl: string;
  readonly members: number;
  readonly warLeague: string;
  readonly clanPoints: number;
  readonly countryCode: string;
  readonly locationName: string;
  readonly type: string;
  readonly accountCount: number;
  readonly bookmarked: boolean;
  readonly clan?: Clan;
}

export function buildClanRoster(model: ClansPresentationModel): {
  readonly items: ClanRosterItem[];
  readonly missingBookmarkTags: string[];
} {
  const linkedByTag = new Map<string, Clan>();
  model.profiles.forEach((player) => {
    const clan = player.clan as Clan | null;
    if (clan?.tag) linkedByTag.set(clan.tag, clan);
  });
  const hydratedByTag = new Map(model.hydratedClans.map((clan) => [clan.tag, clan]));
  const linked = Array.from(linkedByTag.values()).map<ClanRosterItem>((clan) => ({
    tag: clan.tag,
    name: clan.name,
    badgeUrl: clan.badgeUrls.smallest,
    members: clan.members,
    warLeague: clan.warLeague?.name ?? 'Unranked',
    clanPoints: clan.clanPoints,
    countryCode: clan.location?.countryCode ?? '',
    locationName: clan.location?.name ?? '',
    type: clan.type,
    accountCount: model.profiles.filter((player) => player.clanTag === clan.tag).length,
    bookmarked: false,
    clan,
  }));
  const bookmarked = model.bookmarks
    .filter((bookmark) => !linkedByTag.has(bookmark.tag))
    .map<ClanRosterItem>((bookmark) => {
      const clan = hydratedByTag.get(bookmark.tag);
      return {
        tag: bookmark.tag,
        name: clan?.name ?? bookmark.name,
        badgeUrl: clan?.badgeUrls.smallest || bookmark.badgeUrl,
        members: clan?.members ?? bookmark.memberCount,
        warLeague: clan?.warLeague?.name ?? '',
        clanPoints: clan?.clanPoints ?? 0,
        countryCode: clan?.location?.countryCode ?? '',
        locationName: clan?.location?.name ?? '',
        type: clan?.type ?? '',
        accountCount: 0,
        bookmarked: true,
        clan,
      };
    });
  return {
    items: [...linked, ...bookmarked],
    missingBookmarkTags: bookmarked.flatMap((item) => (item.clan ? [] : [item.tag])),
  };
}

export function clanMemberCapacityLabel(members: number): string {
  return `${members}/50`;
}
