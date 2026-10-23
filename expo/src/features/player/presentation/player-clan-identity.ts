import { ImageAssets } from '../../../core/assets/image-assets';
import type { Player } from '../models/player';

export function playerProfileClanIdentity(
  player: Player,
  cachedClanTag: string | null | undefined = '',
) {
  const linked =
    player.clan && typeof player.clan === 'object'
      ? (player.clan as { tag?: string; name?: string })
      : null;
  const tag = linked?.tag || player.clanOverview.tag || player.clanTag || cachedClanTag || '';
  return {
    tag,
    name: linked?.name || player.clanOverview.name || tag,
    badgeUrl: ImageAssets.clanBadgeForTag(tag, linked ?? player.clanOverview),
  };
}
