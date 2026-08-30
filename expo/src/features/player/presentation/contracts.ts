import type { CocAccountLink } from '../../auth/models';
import type { PlayerCardOptions } from '../models/player-support';
import type { Player } from '../models/player';

export type PlayerRosterMode = 'linked' | 'bookmarked';
export type PlayerCardOption = 'notifications' | 'todo' | 'upgrade' | 'ranked' | 'war' | 'hidden';

export interface BookmarkedPlayerSummary {
  readonly tag: string;
  readonly name: string;
  readonly townHallLevel: number;
  readonly townHallPic: string;
  readonly clanName: string;
  readonly trophies: number;
  readonly league: string;
  readonly leagueUrl: string;
}

export interface PlayersFeatureFlags {
  readonly upgradeTracker: boolean;
  readonly rankedLeague: boolean;
}

export interface PlayersPresentationModel {
  readonly profiles: readonly Player[];
  readonly accountLinks: readonly CocAccountLink[];
  readonly bookmarks: readonly BookmarkedPlayerSummary[];
  readonly optionsByTag: Readonly<Record<string, PlayerCardOptions>>;
  readonly notificationsEnabled: boolean;
  readonly notificationAccountTags: ReadonlySet<string>;
  readonly updatingNotificationTags: ReadonlySet<string>;
  readonly lastRefresh?: Date;
  readonly featureFlags: PlayersFeatureFlags;
}

export interface PlayersPresentationActions {
  refresh(): Promise<void>;
  showMessage(message: string): void;
  openManageAccounts(): void;
  openPlayer(player: Player): void;
  hydrateBookmarkedPlayers(tags: readonly string[]): Promise<void>;
  loadBookmarkedPlayer(tag: string): Promise<Player>;
  verifyAccount(
    playerTag: string,
    apiToken: string,
  ): Promise<{ success: boolean; message: string | null }>;
  refreshAccounts(): Promise<void>;
  openGameSettings(): void;
  setAccountNotifications(playerTag: string, enabled: boolean): Promise<void>;
  setAccountHidden(playerTag: string, hidden: boolean): Promise<void>;
  setCardOption(
    playerTag: string,
    option: Exclude<PlayerCardOption, 'notifications' | 'hidden'>,
    enabled: boolean,
  ): Promise<void>;
}

export type PlayerRosterEntry =
  | { readonly kind: 'linked'; readonly player: Player; readonly link: CocAccountLink }
  | {
      readonly kind: 'bookmarked';
      readonly bookmark: BookmarkedPlayerSummary;
      readonly player?: Player;
    };

export function normalizeRosterTag(tag: string): string {
  return tag.trim().toUpperCase();
}

export function buildPlayerRosters(model: PlayersPresentationModel): {
  linked: PlayerRosterEntry[];
  bookmarked: PlayerRosterEntry[];
  missingBookmarkTags: string[];
} {
  const profiles = new Map(
    model.profiles.map((player) => [normalizeRosterTag(player.tag), player]),
  );
  const linksByTag = new Map<string, CocAccountLink>();
  model.accountLinks.forEach((link) => {
    const tag = normalizeRosterTag(link.playerTag);
    if (tag && !linksByTag.has(tag)) linksByTag.set(tag, link);
  });
  const linkedTags = new Set(linksByTag.keys());
  const linked = Array.from(linksByTag.entries()).flatMap<PlayerRosterEntry>(([tag, link]) => {
    const player = profiles.get(tag);
    return player ? [{ kind: 'linked', player, link }] : [];
  });
  const bookmarked = model.bookmarks
    .filter((bookmark) => !linkedTags.has(normalizeRosterTag(bookmark.tag)))
    .map<PlayerRosterEntry>((bookmark) => ({
      kind: 'bookmarked',
      bookmark,
      player: profiles.get(normalizeRosterTag(bookmark.tag)),
    }));
  return {
    linked,
    bookmarked,
    missingBookmarkTags: bookmarked.flatMap((entry) =>
      entry.kind === 'bookmarked' && !entry.player ? [entry.bookmark.tag] : [],
    ),
  };
}

export function playerGridColumns(width: number): number {
  return Math.max(1, Math.min(3, Math.floor((width + 12) / 432)));
}

export function resolveRosterSwipeTarget({
  startIndex,
  deltaX,
  velocityX,
  segmentWidth,
  isRtl,
}: {
  startIndex: number;
  deltaX: number;
  velocityX: number;
  segmentWidth: number;
  isRtl: boolean;
}): 0 | 1 {
  if (segmentWidth <= 0) return startIndex <= 0 ? 0 : 1;
  const direction = isRtl ? -1 : 1;
  const projected =
    startIndex + direction * (deltaX / segmentWidth + (velocityX / segmentWidth) * 0.08);
  return projected >= 0.5 ? 1 : 0;
}
