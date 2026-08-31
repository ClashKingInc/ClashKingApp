import { ImageAssets } from '../../../core/assets/image-assets';

import {
  UpgradeCategory,
  UpgradeCost,
  UpgradePlanLane,
  UpgradePlanPreferences,
  UpgradePlanStrategy,
  UpgradeQueue,
  UpgradeWallResourcePreference,
  UpgradeVillage,
  PlannedUpgrade,
  type UpgradeCategoryValue,
  type UpgradeTrackerItem,
  type UpgradeTrackerSnapshot,
  type UpgradeVillageValue,
} from '../models';

export const trackerTabs = ['home', 'builder', 'calendar', 'plan', 'collection'] as const;
export type TrackerTab = (typeof trackerTabs)[number];

export interface TrackerPlanData {
  readonly startsAt: Date;
  readonly homeBuilders: readonly UpgradePlanLane[];
  readonly builderBuilders: readonly UpgradePlanLane[];
  readonly laboratory: readonly UpgradePlanLane[];
  readonly builderLaboratory: readonly UpgradePlanLane[];
  readonly pets: readonly UpgradePlanLane[];
  readonly walls: readonly PlannedUpgrade[];
  readonly allLanes: readonly UpgradePlanLane[];
  readonly upgrades: readonly PlannedUpgrade[];
  readonly finishesAt: Date | null;
  readonly costs: Readonly<Record<string, number>>;
}

export interface UpgradeTrackerAccountMetadata {
  readonly tag: string;
  readonly name: string;
  readonly townHallLevel: number;
  readonly builderHallLevel: number;
  readonly capturedAt?: Date;
}

export function buildUpgradeTrackerAccountOptions(
  saved: readonly UpgradeTrackerAccountMetadata[],
  verifiedTags: readonly string[],
  players: readonly UpgradeTrackerAccountMetadata[],
): readonly UpgradeTrackerAccountMetadata[] {
  const normalized = (tag: string) => {
    const value = tag.trim().toUpperCase();
    return value.startsWith('#') ? value : `#${value}`;
  };
  const savedByTag = new Map(saved.map((item) => [normalized(item.tag), item]));
  const playersByTag = new Map(players.map((item) => [normalized(item.tag), item]));
  return verifiedTags.map((tag) => {
    const canonicalTag = normalized(tag);
    const player = playersByTag.get(canonicalTag);
    const previous = savedByTag.get(canonicalTag);
    return {
      tag: canonicalTag,
      name: player?.name ?? previous?.name ?? canonicalTag,
      townHallLevel: player?.townHallLevel ?? previous?.townHallLevel ?? 0,
      builderHallLevel: player?.builderHallLevel ?? previous?.builderHallLevel ?? 0,
      ...(previous?.capturedAt ? { capturedAt: previous.capturedAt } : null),
    };
  });
}

export function buildTrackerPlanData(
  snapshot: UpgradeTrackerSnapshot,
  goldPassPercent: number,
  preferences: UpgradePlanPreferences,
  now = new Date(),
): TrackerPlanData {
  const options = {
    strategy: UpgradePlanStrategy.balanced,
    startsAt: now,
    goldPassPercent,
    preferences,
  };
  const homeBuilders = buildPlannerLanes(snapshot, {
    ...options,
    queue: UpgradeQueue.builders,
    village: UpgradeVillage.home,
  });
  const builderBuilders = buildPlannerLanes(snapshot, {
    ...options,
    queue: UpgradeQueue.builders,
    village: UpgradeVillage.builderBase,
  });
  const laboratory = buildPlannerLanes(snapshot, {
    ...options,
    queue: UpgradeQueue.laboratory,
    village: UpgradeVillage.home,
  });
  const builderLaboratory = buildPlannerLanes(snapshot, {
    ...options,
    queue: UpgradeQueue.laboratory,
    village: UpgradeVillage.builderBase,
  });
  const pets = buildPlannerLanes(snapshot, {
    ...options,
    queue: UpgradeQueue.pets,
    village: UpgradeVillage.home,
  });
  const walls = buildWallPlan(snapshot, preferences, goldPassPercent, now);
  const allLanes = [
    ...homeBuilders,
    ...builderBuilders,
    ...laboratory,
    ...builderLaboratory,
    ...pets,
    ...(walls.length ? [new UpgradePlanLane(0, walls)] : []),
  ];
  const upgrades = allLanes
    .flatMap((lane) => lane.upgrades)
    .sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime());
  const finishesAt = allLanes.reduce<Date | null>((latest, lane) => {
    const finish = lane.finishesAt;
    return finish && (!latest || finish > latest) ? finish : latest;
  }, null);
  const costs: Record<string, number> = {};
  for (const upgrade of upgrades)
    for (const cost of upgrade.costs)
      costs[cost.resource] = (costs[cost.resource] ?? 0) + cost.amount;
  return {
    startsAt: now,
    homeBuilders,
    builderBuilders,
    laboratory,
    builderLaboratory,
    pets,
    walls,
    allLanes,
    upgrades,
    finishesAt,
    costs,
  };
}

/** Adds the currently running work that Flutter renders ahead of each planned lane. */
function buildPlannerLanes(
  snapshot: UpgradeTrackerSnapshot,
  options: {
    queue: (typeof UpgradeQueue)[keyof typeof UpgradeQueue];
    village: UpgradeVillageValue;
    strategy: (typeof UpgradePlanStrategy)[keyof typeof UpgradePlanStrategy];
    startsAt: Date;
    goldPassPercent: number;
    preferences: UpgradePlanPreferences;
  },
) {
  const lanes = snapshot.buildPlan(options);
  const active = snapshot
    .itemsFor({ village: options.village, queue: options.queue })
    .filter(
      (item) =>
        item.steps.length > 0 && snapshot.remainingActiveSeconds(item, options.startsAt) > 0,
    )
    .sort(
      (left, right) =>
        snapshot.remainingActiveSeconds(right, options.startsAt) -
        snapshot.remainingActiveSeconds(left, options.startsAt),
    );
  return lanes.map((lane, index) => {
    const item = active[index];
    const step = item?.steps[0];
    const ongoing =
      item && step
        ? new PlannedUpgrade(
            item,
            0,
            step,
            new Date(
              options.startsAt.getTime() -
                snapshot.activeElapsedSeconds(item, options.startsAt) * 1000,
            ),
            new Date(
              options.startsAt.getTime() +
                snapshot.remainingActiveSeconds(item, options.startsAt) * 1000,
            ),
            step.costs,
            true,
          )
        : null;
    return new UpgradePlanLane(
      lane.index,
      [...(ongoing ? [ongoing] : []), ...lane.upgrades],
      lane.reservedUntil,
    );
  });
}

/** Mirrors Flutter's optional, resource-aware weekly wall schedule. */
export function buildWallPlan(
  snapshot: UpgradeTrackerSnapshot,
  preferences: UpgradePlanPreferences,
  goldPassPercent: number,
  startsAt: Date,
) {
  if (preferences.wallsPerWeek <= 0) return [];
  const candidates = snapshot
    .itemsFor({
      village: UpgradeVillage.home,
      category: UpgradeCategory.walls,
      remainingOnly: true,
    })
    .flatMap((item) =>
      Array.from({ length: item.count }, (_, index) => ({ item, instance: index + 1 })),
    )
    .sort(
      (left, right) =>
        left.item.name.localeCompare(right.item.name) || left.instance - right.instance,
    );
  const upgrades: PlannedUpgrade[] = [];
  let week = 0;
  let completedThisWeek = 0;
  for (const candidate of candidates) {
    let dependencyReadyAt = startsAt;
    for (const step of candidate.item.steps) {
      if (completedThisWeek >= preferences.wallsPerWeek) {
        week += 1;
        completedThisWeek = 0;
      }
      const weekStart = new Date(startsAt.getTime() + week * 7 * 86_400_000);
      const scheduledAt = weekStart > dependencyReadyAt ? weekStart : dependencyReadyAt;
      const adjusted = snapshot.adjustStep(candidate.item, step, scheduledAt, goldPassPercent);
      const endsAt = new Date(scheduledAt.getTime() + adjusted.seconds * 1000);
      upgrades.push(
        new PlannedUpgrade(
          candidate.item,
          candidate.instance,
          adjusted,
          scheduledAt,
          endsAt,
          preferredWallCosts(adjusted.costs, preferences),
        ),
      );
      completedThisWeek += 1;
      dependencyReadyAt = endsAt;
    }
  }
  return upgrades;
}

function preferredWallCosts(costs: readonly UpgradeCost[], preferences: UpgradePlanPreferences) {
  if (costs.length <= 1) return costs;
  const preferred = costs.filter((cost) =>
    preferences.wallResourcePreference === UpgradeWallResourcePreference.gold
      ? cost.resource === 'gold' || cost.resource === 'builder_gold'
      : cost.resource === 'elixir',
  );
  return preferred.length ? [preferred[0]!] : [costs[0]!];
}

export function activeTrackerItems(snapshot: UpgradeTrackerSnapshot, now = new Date()) {
  return snapshot.items.filter((item) => snapshot.remainingActiveSeconds(item, now) > 0);
}

export function filteredUpgradeItems(
  snapshot: UpgradeTrackerSnapshot,
  village: UpgradeVillageValue,
  query: string,
  remainingOnly: boolean,
) {
  const needle = query.trim().toLocaleLowerCase();
  return snapshot
    .itemsFor({ village })
    .filter(
      (item) =>
        (!remainingOnly || !item.isComplete) &&
        (!needle || item.name.toLocaleLowerCase().includes(needle)),
    );
}

export function groupUpgradeItems(items: readonly UpgradeTrackerItem[]) {
  const groups = new Map<UpgradeCategoryValue, UpgradeTrackerItem[]>();
  for (const item of items) groups.set(item.category, [...(groups.get(item.category) ?? []), item]);
  return [...groups.entries()].sort(
    ([left], [right]) => categoryOrder(left) - categoryOrder(right),
  );
}

function categoryOrder(category: UpgradeCategoryValue) {
  const order = Object.values(UpgradeCategory);
  const index = order.indexOf(category);
  return index < 0 ? 999 : index;
}

export function formatTrackerDuration(seconds: number) {
  const value = Math.max(0, Math.round(seconds));
  if (value <= 0) return 'Now';
  const days = Math.floor(value / 86400);
  const hours = Math.floor((value % 86400) / 3600);
  const minutes = Math.floor((value % 3600) / 60);
  if (days) return hours ? `${days}d ${hours}h` : `${days}d`;
  if (hours) return minutes ? `${hours}h ${minutes}m` : `${hours}h`;
  return `${Math.max(1, Math.min(59, minutes))}m`;
}

export function sceneryMusicUrl(item: { type?: string; meta: Record<string, unknown> | null }) {
  if (item.type !== undefined && item.type !== 'sceneries') return null;
  const music = item.meta?.music;
  if (typeof music === 'string' && music.length > 0)
    return music.startsWith('http') ? music : `${ImageAssets.baseUrl}/${music}`;
  const thumbnail = item.meta?.thumbnail;
  if (typeof thumbnail !== 'string' || !thumbnail) return null;
  const root = thumbnail.replace(/\/thumbnail\.[a-zA-Z0-9]+$/, '');
  return root === thumbnail ? null : `${ImageAssets.baseUrl}/${root}/music.ogg`;
}

export function planLaneLabel(queue: string, index: number, capacity: number) {
  if (index < capacity) return `Slot ${index + 1}`;
  if (queue === UpgradeQueue.builders) return 'Goblin Builder';
  if (queue === UpgradeQueue.laboratory) return 'Goblin Researcher';
  return 'Goblin';
}

/** Matches Flutter's daily wall batching while retaining one row for every timed upgrade. */
export function groupPlannedUpgrades(upgrades: readonly PlannedUpgrade[]) {
  const groups = new Map<string, PlannedUpgrade[]>();
  for (const upgrade of upgrades) {
    const date = upgrade.startsAt;
    const key =
      upgrade.item.category === UpgradeCategory.walls
        ? `wall:${upgrade.item.planKey}:${upgrade.step.targetLevel}:${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`
        : `single:${upgrade.item.planKey}:${upgrade.instance}:${upgrade.step.targetLevel}:${date.getTime()}`;
    groups.set(key, [...(groups.get(key) ?? []), upgrade]);
  }
  return [...groups.values()].map((values) => {
    const costs = new Map<string, number>();
    for (const upgrade of values)
      for (const cost of upgrade.costs)
        costs.set(cost.resource, (costs.get(cost.resource) ?? 0) + cost.amount);
    return {
      upgrades: values,
      startsAt: values.reduce(
        (value, upgrade) => (upgrade.startsAt < value ? upgrade.startsAt : value),
        values[0]!.startsAt,
      ),
      endsAt: values.reduce(
        (value, upgrade) => (upgrade.endsAt > value ? upgrade.endsAt : value),
        values[0]!.endsAt,
      ),
      isOngoing: values.some((upgrade) => upgrade.isOngoing),
      costs: [...costs].map(([resource, amount]) => ({ resource, amount })),
    };
  });
}
