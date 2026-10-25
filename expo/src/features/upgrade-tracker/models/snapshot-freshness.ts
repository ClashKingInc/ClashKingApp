import type { UpgradeTrackerSnapshot } from './upgrade-tracker-models';

/** A timer ending is an estimate, not a newly observed game state. Re-import
 * when any recorded upgrade has elapsed, even while other builders still work. */
export function upgradeSnapshotNeedsRefresh(
  snapshot: UpgradeTrackerSnapshot,
  now = new Date(),
): boolean {
  return snapshot.items.some(
    (item) =>
      !item.isComplete &&
      (item.activeSeconds ?? 0) > 0 &&
      snapshot.remainingActiveSeconds(item, now) <= 0,
  );
}
