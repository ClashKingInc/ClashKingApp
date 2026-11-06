import { canonicalTag } from '../../../core/domain/tags';
import { mapWithConcurrencyLimit } from '../../../core/utils/bounded-concurrency';
import type { UpgradeTrackerSnapshot } from '../../upgrade-tracker/models';

export async function loadHomeUpgradeSnapshots(
  players: readonly { tag: string }[],
  load: (tag: string, forceRefresh: boolean) => Promise<UpgradeTrackerSnapshot | null>,
  forceRefresh: boolean,
) {
  const tags = [...new Set(players.map((player) => canonicalTag(player.tag)))];
  const snapshots = await mapWithConcurrencyLimit(
    tags,
    async (tag) => {
      try {
        return [tag, await load(tag, forceRefresh)] as const;
      } catch {
        return [tag, null] as const;
      }
    },
    4,
  );
  return new Map(snapshots);
}
