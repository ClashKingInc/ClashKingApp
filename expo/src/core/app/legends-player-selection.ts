import type { Player } from '../../features/player/models';
import { canonicalTag } from '../domain/tags';

export function selectLegendsPlayer(
  profiles: readonly Player[],
  verifiedPlayerTags: readonly string[],
  requestedPlayerTag?: string,
) {
  if (requestedPlayerTag) {
    return profiles.find(
      (player) => canonicalTag(player.tag) === canonicalTag(requestedPlayerTag),
    );
  }

  const verified = new Set(verifiedPlayerTags.map(canonicalTag));
  return profiles.find((player) => verified.has(canonicalTag(player.tag)));
}
