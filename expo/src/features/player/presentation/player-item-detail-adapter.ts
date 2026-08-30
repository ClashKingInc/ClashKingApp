import {
  PlayerEquipment,
  PlayerPet,
  PlayerSiegeMachine,
  type PlayerItem,
} from '../models/player-items';
import {
  UpgradeBoosts,
  UpgradeCategory,
  UpgradeCost,
  UpgradeQueue,
  UpgradeStep,
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
  UpgradeVillage,
} from '../../upgrade-tracker/models';

export function upgradeDetailsItem(item: PlayerItem) {
  const category =
    item instanceof PlayerEquipment
      ? UpgradeCategory.equipment
      : item instanceof PlayerPet
        ? UpgradeCategory.pets
        : item instanceof PlayerSiegeMachine
          ? UpgradeCategory.sieges
          : item.type === 'hero'
            ? UpgradeCategory.heroes
            : item.type === 'spell'
              ? UpgradeCategory.spells
              : UpgradeCategory.troops;
  const queue =
    category === UpgradeCategory.pets
      ? UpgradeQueue.pets
      : [UpgradeCategory.troops, UpgradeCategory.spells, UpgradeCategory.sieges].includes(
            category as never,
          )
        ? UpgradeQueue.laboratory
        : UpgradeQueue.builders;
  const levels = Array.isArray(item.meta?.levels)
    ? item.meta.levels.filter(
        (row): row is Record<string, unknown> => !!row && typeof row === 'object',
      )
    : [];
  const steps = Array.from(
    { length: Math.max(0, item.maxLevel - item.level) },
    (_, index) => item.level + index + 1,
  ).flatMap((target) => {
    const row = levels.find((candidate) => candidate.level === target - 1);
    if (!row) return [];
    const rawCost = row.upgrade_cost;
    const costs =
      rawCost && typeof rawCost === 'object' && !Array.isArray(rawCost)
        ? Object.entries(rawCost)
            .filter(
              (entry): entry is [string, number] => typeof entry[1] === 'number' && entry[1] > 0,
            )
            .map(([resource, amount]) => new UpgradeCost(normalizeResource(resource), amount))
        : typeof rawCost === 'number' && rawCost > 0
          ? [new UpgradeCost(normalizeResource(String(item.meta?.upgrade_resource ?? '')), rawCost)]
          : [];
    return [
      new UpgradeStep(target, costs, typeof row.upgrade_time === 'number' ? row.upgrade_time : 0),
    ];
  });
  return new UpgradeTrackerItem({
    id: typeof item.meta?._id === 'number' ? item.meta._id : stableStringId(item.name),
    name: item.name,
    imageUrl: item.imageUrl,
    village:
      item.type === 'builderBase' ||
      String(item.meta?.village ?? '')
        .toLowerCase()
        .includes('builder')
        ? UpgradeVillage.builderBase
        : UpgradeVillage.home,
    category,
    queue,
    currentLevel: item.level,
    targetLevel: item.maxLevel,
    count: 1,
    steps,
    completedUpgradeSeconds: 0,
    totalUpgradeSeconds: steps.reduce((sum, step) => sum + step.seconds, 0),
    meta: item.meta,
    wardenWeight: optionalNumber(item.meta?.warden_weight),
    healerWeight: optionalNumber(item.meta?.healer_weight),
  });
}

export function upgradeDetailsSnapshot(item: PlayerItem | null) {
  const detail = item ? upgradeDetailsItem(item) : null;
  return new UpgradeTrackerSnapshot({
    tag: '',
    name: '',
    townHallLevel: 0,
    builderHallLevel: 0,
    homeBuilderCount: 0,
    builderBaseBuilderCount: 0,
    items: detail ? [detail] : [],
    collections: [],
    boosts: new UpgradeBoosts(),
    events: [],
    capturedAt: new Date(),
  });
}

function normalizeResource(value: string) {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}
function optionalNumber(value: unknown) {
  const parsed = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}
function stableStringId(value: string) {
  let hash = 0;
  for (let index = 0; index < value.length; index += 1)
    hash = ((hash << 5) - hash + value.charCodeAt(index)) | 0;
  return hash;
}
