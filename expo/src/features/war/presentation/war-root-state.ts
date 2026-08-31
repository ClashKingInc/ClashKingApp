import type { BookmarkedClan, BookmarkedPlayer } from '../../../core/bookmarks';
import { canonicalTag } from '../../../core/domain/tags';
import type { Clan } from '../../clan/models';
import type { PlayerCardPreferencesService } from '../../player/data';
import type { Player } from '../../player/models/player';

export function hiddenWarPlayerTags(
  profiles: readonly Player[],
  bookmarkedPlayers: readonly BookmarkedPlayer[],
  preferences: Pick<PlayerCardPreferencesService, 'isShownInWarTab'>,
): ReadonlySet<string> {
  return new Set(
    [...profiles.map((player) => player.tag), ...bookmarkedPlayers.map((player) => player.tag)]
      .filter((tag) => !preferences.isShownInWarTab(tag))
      .map(canonicalTag),
  );
}

export function extraWarClanTags(
  profiles: readonly Player[],
  ownedPlayerTags: readonly string[],
  bookmarkedPlayers: readonly BookmarkedPlayer[],
  bookmarkedClans: readonly BookmarkedClan[],
  preferences: Pick<PlayerCardPreferencesService, 'isShownInWarTab'>,
): string[] {
  const owned = new Set(ownedPlayerTags.map(canonicalTag));
  const profilesByTag = new Map(profiles.map((player) => [canonicalTag(player.tag), player]));
  const linkedClanTags = new Set(
    profiles
      .filter(
        (player) => owned.has(canonicalTag(player.tag)) && preferences.isShownInWarTab(player.tag),
      )
      .map((player) => player.clanTag)
      .filter(Boolean),
  );
  const fromPlayers = bookmarkedPlayers
    .filter(
      (player) => !owned.has(canonicalTag(player.tag)) && preferences.isShownInWarTab(player.tag),
    )
    .map((bookmark) => profilesByTag.get(canonicalTag(bookmark.tag))?.clanTag || bookmark.clanTag);
  return [
    ...new Set(
      [...bookmarkedClans.map((clan) => clan.tag), ...fromPlayers].filter(
        (tag) => tag.length > 0 && !linkedClanTags.has(tag),
      ),
    ),
  ];
}

export function hydratedClanValues(clans: ReadonlyMap<string, Clan>): readonly Clan[] {
  return [...clans.values()];
}
