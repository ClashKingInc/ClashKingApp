import { canonicalTag } from '../../../core/domain/tags';
import type { UpgradeTrackerSnapshot } from '../../upgrade-tracker/models';

export async function loadHomeUpgradeSnapshots(
  players: readonly { tag: string }[],
  load: (tag: string, forceRefresh: boolean) => Promise<UpgradeTrackerSnapshot | null>,
  forceRefresh: boolean,
) {
  const snapshots = new Map<string, UpgradeTrackerSnapshot | null>();
  for (const player of players) {
    try {
      snapshots.set(canonicalTag(player.tag), await load(player.tag, forceRefresh));
    } catch {
      snapshots.set(canonicalTag(player.tag), null);
    }
  }
  return snapshots;
}
