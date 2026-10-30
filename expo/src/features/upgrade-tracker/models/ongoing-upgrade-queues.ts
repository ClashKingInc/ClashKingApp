import {
  UpgradeQueue,
  UpgradeVillage,
  type UpgradeTrackerSnapshot,
  type UpgradeVillageValue,
} from './upgrade-tracker-models';
import { maximumBuildingLevelAtHall } from '../../../core/game-data/hall-item-limits';

/** Shared by the tracker and native widget payload. One timer occupies one
 * normal slot; Goblin jobs must not inflate permanent builder/lab capacity. */
export function ongoingUpgradeQueues(
  snapshot: UpgradeTrackerSnapshot,
  village: UpgradeVillageValue,
  now = new Date(),
) {
  const active = snapshot.items.filter(
    (item) => item.village === village && snapshot.remainingActiveSeconds(item, now) > 0,
  );
  const ownsPetHouse = snapshot.items.some(
    (item) =>
      item.village === UpgradeVillage.home && item.name === 'Pet House' && item.currentLevel > 0,
  );
  const isBuilder = village === UpgradeVillage.builderBase;
  const hall = isBuilder ? snapshot.builderHallLevel : snapshot.townHallLevel;
  const laboratory = isBuilder ? 'Star Laboratory' : 'Laboratory';
  const hasLaboratory =
    snapshot.items.some((item) => item.village === village && item.name === laboratory) ||
    maximumBuildingLevelAtHall(laboratory, hall, isBuilder) > 0;
  const definitions = [
    ...(hall > 0 ? [{ queue: UpgradeQueue.builders, facility: null }] : []),
    ...(hasLaboratory
      ? [
          {
            queue: UpgradeQueue.laboratory,
            facility: laboratory,
          },
        ]
      : []),
    ...(village === UpgradeVillage.home &&
    (maximumBuildingLevelAtHall('Pet House', hall) > 0 || ownsPetHouse)
      ? [{ queue: UpgradeQueue.pets, facility: 'Pet House' }]
      : []),
  ];
  return definitions.map(({ queue, facility }) => {
    const building = facility
      ? snapshot.items.find(
          (item) => item.village === village && item.name === facility && !item.isSupercharge,
        )
      : null;
    const construction =
      building && building.currentLevel === 0 ? snapshot.remainingActiveSeconds(building, now) : 0;
    // A completed initial construction remains available as its timer expires,
    // even before the next imported JSON updates the stored building level.
    const capacity =
      queue === UpgradeQueue.builders
        ? snapshot.buildersFor(village)
        : building && (building.currentLevel > 0 || (building.activeSeconds ?? 0) > 0)
          ? 1
          : 0;
    const work = active
      .filter((item) => item.queue === queue && !item.isExtra)
      .sort(
        (a, b) => snapshot.remainingActiveSeconds(a, now) - snapshot.remainingActiveSeconds(b, now),
      );
    const extra = active.filter((item) => item.queue === queue && item.isExtra).length;
    const times = [
      ...work.map((item) => snapshot.remainingActiveSeconds(item, now)),
      ...(construction > 0 ? [construction] : []),
    ];
    return {
      queue,
      capacity,
      work,
      extra,
      times,
      used: times.length,
      free: Math.max(0, capacity - times.length),
    };
  });
}
