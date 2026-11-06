import type { BookmarkedClan } from '../../../core/bookmarks/bookmark-service';
import type { Player } from '../../player/models/player';
import type { Clan } from '../models';
import type { ClanSpringOrigin } from './clan-spring-transition';
import { ImageAssets } from '../../../core/assets/image-assets';
import { canonicalTag } from '../../../core/domain/tags';
import type { ClanNotificationControls } from './clan-notification-options';

export interface ClansPresentationModel {
  readonly loading?: boolean;
  readonly profiles: readonly Player[];
  readonly bookmarks: readonly BookmarkedClan[];
  readonly hydratedClans: readonly Clan[];
  readonly lastRefresh?: Date;
  readonly notifications?: ClanNotificationControls;
}

export interface ClansPresentationActions {
  refresh(): Promise<void>;
  isNetworkError(error: unknown): boolean;
  openNetworkError(retry: () => Promise<void>): void;
  showMessage(message: string): void;
  hydrateBookmarkedClans(tags: readonly string[]): Promise<void>;
  loadClan(tag: string): Promise<Clan>;
  openClan(clan: Clan, origin?: ClanSpringOrigin): void;
  openClanTag?(tag: string): void;
  reorderLinkedClans(orderedTags: readonly string[]): Promise<void>;
  reorderBookmarkedClans(orderedTags: readonly string[]): Promise<void>;
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
  readonly missingClanTags: string[];
} {
  // Membership comes from the current player payload, not its optional hydrated
  // clan object. Player refreshes replace that object, and a failed clan fetch
  // must never move an owned account's clan into the Bookmarked tab.
  const linkedByTag = new Map<string, Player[]>();
  model.profiles.forEach((player) => {
    const tag = canonicalTag(player.clanTag);
    if (!tag) return;
    const accounts = linkedByTag.get(tag) ?? [];
    accounts.push(player);
    linkedByTag.set(tag, accounts);
  });
  const hydratedByTag = new Map(model.hydratedClans.map((clan) => [canonicalTag(clan.tag), clan]));
  const linked = Array.from(linkedByTag, ([tag, accounts]): ClanRosterItem => {
    const attached = accounts
      .map((player) => player.clan as Clan | null)
      .find((clan) => clan && canonicalTag(clan.tag) === tag);
    const clan = hydratedByTag.get(tag) ?? attached ?? undefined;
    return {
      tag,
      name: clan?.name ?? accounts[0]!.clanOverview.name,
      badgeUrl: ImageAssets.clanBadgeForTag(tag, clan ?? accounts[0]!.clanOverview),
      members: clan?.members ?? 0,
      warLeague: clan?.warLeague?.name ?? '',
      clanPoints: clan?.clanPoints ?? 0,
      countryCode: clan?.location?.countryCode ?? '',
      locationName: clan?.location?.name ?? '',
      type: clan?.type ?? '',
      accountCount: accounts.length,
      bookmarked: false,
      clan,
    };
  });
  const bookmarked = model.bookmarks
    .filter((bookmark) => !linkedByTag.has(canonicalTag(bookmark.tag)))
    .map<ClanRosterItem>((bookmark) => {
      const clan = hydratedByTag.get(canonicalTag(bookmark.tag));
      return {
        tag: bookmark.tag,
        name: clan?.name ?? bookmark.name,
        badgeUrl: ImageAssets.clanBadgeForTag(bookmark.tag, clan ?? bookmark),
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
    missingClanTags: [...linked, ...bookmarked].flatMap((item) => (item.clan ? [] : [item.tag])),
  };
}

export function clanMemberCapacityLabel(members: number): string {
  return `${members}/50`;
}
