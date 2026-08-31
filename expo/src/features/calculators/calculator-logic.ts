import { gameDataState } from '../../core/game-data/game-data-state';
import type { Player } from '../player/models/player';
import {
  BuildingDefinition,
  BuildingLevelDefinition,
  DamageCalculatorSession,
  DamageSourceKind,
  type DamageAccountPreset,
} from '../damage-calculator';
import {
  UpgradePlanPreferences,
  UpgradePlanStrategy,
  UpgradeQueue,
  UpgradeVillage,
  normalizeUpgradePlanPreferencesForQueue,
  type UpgradeCost,
  type UpgradeStep,
  type UpgradeTrackerItem,
  type UpgradeTrackerSnapshot,
} from '../upgrade-tracker/models/upgrade-tracker-models';

export const calculatorSetupIds = {
  custom: 'custom',
  zapQuake: 'zap-quake',
  fireballQuake: 'fireball-quake',
  giantArrow: 'giant-arrow',
  flameFlinger: 'flame-flinger',
} as const;

export const calculatorSetupCounts: Readonly<
  Record<string, ReadonlyMap<DamageSourceKind, number>>
> = {
  [calculatorSetupIds.zapQuake]: new Map([
    [DamageSourceKind.Lightning, 5],
    [DamageSourceKind.Earthquake, 1],
  ]),
  [calculatorSetupIds.fireballQuake]: new Map([
    [DamageSourceKind.Fireball, 1],
    [DamageSourceKind.Earthquake, 1],
  ]),
  [calculatorSetupIds.giantArrow]: new Map([[DamageSourceKind.GiantArrow, 1]]),
  [calculatorSetupIds.flameFlinger]: new Map([[DamageSourceKind.FlameFlinger, 1]]),
};

export interface FarmAttackScenario {
  readonly destructionPercent: number;
  readonly lootPerAttack: number;
  readonly attacks: number;
}

export interface FarmLeagueLootEstimate {
  readonly loot?: number;
  readonly starBonus?: number;
}

export interface FarmTrackerTarget {
  readonly item: UpgradeTrackerItem;
  readonly plannedStep?: UpgradeStep;
  readonly plannedCosts?: readonly UpgradeCost[];
}

export function applyQuickSetup(session: DamageCalculatorSession, setupId: string): void {
  const counts = calculatorSetupCounts[setupId] ?? new Map<DamageSourceKind, number>();
  for (const kind of session.sources.keys()) session.setSourceCount(kind, counts.get(kind) ?? 0);
}

export function availableSetupIds(session: DamageCalculatorSession): readonly string[] {
  return [
    calculatorSetupIds.custom,
    ...[
      calculatorSetupIds.zapQuake,
      calculatorSetupIds.fireballQuake,
      calculatorSetupIds.giantArrow,
      calculatorSetupIds.flameFlinger,
    ].filter((id) =>
      [...calculatorSetupCounts[id]!.keys()].every((kind) => session.sources.has(kind)),
    ),
  ];
}

export function verifiedDamageAccountPresets(
  verifiedTags: Iterable<string>,
  players: readonly Player[],
): readonly DamageAccountPreset[] {
  const profiles = new Map(players.map((player) => [normalizeTag(player.tag), player]));
  return [...verifiedTags].flatMap((tag) => {
    const player = profiles.get(normalizeTag(tag));
    if (!player) return [];
    const ownedLevels = new Map<DamageSourceKind, number>();
    addOwned(ownedLevels, DamageSourceKind.Lightning, player.spells, 'Lightning Spell');
    addOwned(ownedLevels, DamageSourceKind.Earthquake, player.spells, 'Earthquake Spell');
    addOwned(ownedLevels, DamageSourceKind.GiantArrow, player.equipments, 'Giant Arrow');
    addOwned(ownedLevels, DamageSourceKind.Fireball, player.equipments, 'Fireball');
    addOwned(ownedLevels, DamageSourceKind.FlameFlinger, player.siegeMachines, 'Flame Flinger');
    addOwned(ownedLevels, DamageSourceKind.BalloonDeath, player.troops, 'Balloon');
    addOwned(
      ownedLevels,
      DamageSourceKind.RocketBalloonDeath,
      player.superTroops,
      'Rocket Balloon',
    );
    return [
      {
        tag,
        name: player.name,
        townHall: player.townHallLevel,
        league: player.league,
        ownedLevels,
      },
    ];
  });
}

export function farmAttackScenarios(
  upgradeCost?: number,
  perfectLoot = 0,
): readonly FarmAttackScenario[] {
  if (!upgradeCost || upgradeCost <= 0 || perfectLoot <= 0) return [];
  return [100, 80, 60].map((destructionPercent) => {
    const lootPerAttack = Math.round((perfectLoot * destructionPercent) / 100);
    return { destructionPercent, lootPerAttack, attacks: Math.ceil(upgradeCost / lootPerAttack) };
  });
}

export function parseFarmAmount(value: string): number {
  return Number.parseInt(value.replace(/[^0-9]/g, ''), 10) || 0;
}

export function defaultFarmLoot(resource?: string): number {
  return normalizeResource(resource) === 'dark_elixir' ? 10_250 : 1_013_000;
}

export function farmLeagueLootEstimate(
  league: string | undefined,
  townHall: number,
  resource: string | undefined,
): FarmLeagueLootEstimate | null {
  if (!league || !resource) return null;
  const leagues = record(gameDataState.playerLeagueData.leagues);
  const leagueData = record(leagues?.[league]);
  const rewards = Array.isArray(leagueData?.rewards) ? leagueData.rewards : [];
  let selected: Record<string, unknown> | undefined;
  for (const value of rewards) {
    const reward = record(value);
    if (
      reward &&
      typeof reward.townhall_level === 'number' &&
      Number.isFinite(reward.townhall_level) &&
      reward.townhall_level <= townHall
    ) {
      selected = reward;
    }
  }
  const key = normalizeResource(resource);
  if (!key || !selected) return null;
  const loot = rewardAmount(selected.resources, key);
  const starBonus = rewardAmount(selected.star_bonus, key);
  return loot === undefined && starBonus === undefined ? null : { loot, starBonus };
}

export function farmTargetLevels(
  building: BuildingDefinition | undefined,
  townHall: number,
  maxTownHall: number,
): readonly BuildingLevelDefinition[] {
  if (!building) return [];
  const targetTownHall =
    building.name === 'Town Hall' && townHall < maxTownHall ? townHall + 1 : townHall;
  return building.levelsForTownHall(targetTownHall);
}

export function trackerCostForSelection(
  target: FarmTrackerTarget | undefined,
  building: BuildingDefinition | undefined,
  level: BuildingLevelDefinition | undefined,
): UpgradeCost | undefined {
  if (!target || !building || !level || normalize(target.item.name) !== normalize(building.name))
    return undefined;
  const step =
    target.plannedStep?.targetLevel === level.level
      ? target.plannedStep
      : target.item.steps.find((candidate) => candidate.targetLevel === level.level);
  if (!step?.costs.length) return undefined;
  const costs =
    target.plannedStep?.targetLevel === level.level
      ? (target.plannedCosts ?? step.costs)
      : step.costs;
  const selectedResource = normalizeResource(level.upgradeResource);
  return (
    costs.find(
      (cost) => !selectedResource || normalizeResource(cost.resource) === selectedResource,
    ) ?? costs[0]
  );
}

export function farmTrackerTargets(options: {
  snapshot: UpgradeTrackerSnapshot;
  buildings: readonly BuildingDefinition[];
  townHall: number;
  maxTownHall: number;
  goldPassPercent?: number;
  preferences?: UpgradePlanPreferences;
  now?: Date;
}): readonly FarmTrackerTarget[] {
  const { snapshot, buildings, townHall, maxTownHall } = options;
  const now = options.now ?? new Date();
  const byName = new Map(buildings.map((building) => [normalize(building.name), building]));
  const seen = new Set<string>();
  const result: FarmTrackerTarget[] = [];
  const planned = snapshot
    .buildPlan({
      queue: UpgradeQueue.builders,
      strategy: UpgradePlanStrategy.balanced,
      village: UpgradeVillage.home,
      startsAt: now,
      goldPassPercent: options.goldPassPercent ?? 0,
      preferences: normalizeUpgradePlanPreferencesForQueue(
        snapshot,
        options.preferences ?? new UpgradePlanPreferences(),
        UpgradeVillage.home,
        UpgradeQueue.builders,
      ),
    })
    .flatMap((lane) => lane.upgrades)
    .sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime());
  for (const upgrade of planned) {
    const target = resolveTrackerTarget(
      upgrade.item,
      byName,
      seen,
      townHall,
      maxTownHall,
      upgrade.step,
      upgrade.costs,
    );
    if (target) result.push(target);
  }
  for (const item of snapshot.itemsFor({
    village: UpgradeVillage.home,
    queue: UpgradeQueue.builders,
    remainingOnly: true,
  })) {
    if (snapshot.remainingActiveSeconds(item, now) > 0) continue;
    const target = resolveTrackerTarget(item, byName, seen, townHall, maxTownHall);
    if (target) result.push(target);
  }
  return result;
}

export function farmSelectableBuildings(
  buildings: readonly BuildingDefinition[],
  snapshot: UpgradeTrackerSnapshot | null,
  townHall: number,
  maxTownHall: number,
  now = new Date(),
): readonly BuildingDefinition[] {
  if (!snapshot) return buildings;
  const itemsByName = new Map<string, UpgradeTrackerItem[]>();
  for (const item of snapshot.itemsFor({
    village: UpgradeVillage.home,
    queue: UpgradeQueue.builders,
  })) {
    const matching = itemsByName.get(normalize(item.name)) ?? [];
    matching.push(item);
    itemsByName.set(normalize(item.name), matching);
  }
  return buildings.filter((building) => {
    const matching = itemsByName.get(normalize(building.name));
    if (!matching?.length) return true;
    if (matching.some((item) => hasUnpaidFarmUpgrade(snapshot, item, now))) return true;
    if (building.name !== 'Town Hall' || !matching.every((item) => item.isComplete)) return false;
    const completedLevel = Math.max(...matching.map((item) => item.currentLevel));
    return farmTargetLevels(building, townHall, maxTownHall).some(
      (level) => level.level > completedLevel,
    );
  });
}

export function farmUnpaidTargetLevels(
  building: BuildingDefinition,
  snapshot: UpgradeTrackerSnapshot | null,
  townHall: number,
  maxTownHall: number,
  now = new Date(),
): ReadonlySet<number> | null {
  if (!snapshot) return null;
  const matching = snapshot
    .itemsFor({ village: UpgradeVillage.home, queue: UpgradeQueue.builders })
    .filter((item) => normalize(item.name) === normalize(building.name));
  if (!matching.length) return null;
  const levels = new Set<number>();
  for (const item of matching.filter((candidate) => !candidate.isComplete)) {
    const active = snapshot.remainingActiveSeconds(item, now) > 0;
    const unpaid = active && item.count === 1 ? item.steps.slice(1) : item.steps;
    for (const step of unpaid)
      if (step.targetLevel > item.currentLevel) levels.add(step.targetLevel);
  }
  if (building.name === 'Town Hall' && matching.every((item) => item.isComplete)) {
    const completedLevel = Math.max(...matching.map((item) => item.currentLevel));
    for (const level of farmTargetLevels(building, townHall, maxTownHall)) {
      if (level.level > completedLevel) levels.add(level.level);
    }
  }
  return levels;
}

function hasUnpaidFarmUpgrade(
  snapshot: UpgradeTrackerSnapshot,
  item: UpgradeTrackerItem,
  now: Date,
) {
  if (item.isComplete) return false;
  const active = snapshot.remainingActiveSeconds(item, now) > 0;
  if (active && item.count > 1) {
    return item.steps.some((step) => step.targetLevel > item.currentLevel);
  }
  const unpaid = active ? item.steps.slice(1) : item.steps;
  return unpaid.some((step) => step.targetLevel > item.currentLevel);
}

function resolveTrackerTarget(
  item: UpgradeTrackerItem,
  buildings: ReadonlyMap<string, BuildingDefinition>,
  seen: Set<string>,
  townHall: number,
  maxTownHall: number,
  plannedStep?: UpgradeStep,
  plannedCosts?: readonly UpgradeCost[],
): FarmTrackerTarget | undefined {
  if (item.isComplete || item.steps.length === 0) return undefined;
  const step =
    plannedStep && plannedStep.targetLevel > item.currentLevel
      ? plannedStep
      : item.steps.find((candidate) => candidate.targetLevel > item.currentLevel);
  const name = normalize(item.name);
  const building = buildings.get(name);
  if (
    !step ||
    !building ||
    seen.has(name) ||
    !farmTargetLevels(building, townHall, maxTownHall).some(
      (level) => level.level === step.targetLevel,
    )
  )
    return undefined;
  seen.add(name);
  return { item, plannedStep: step, plannedCosts: step === plannedStep ? plannedCosts : undefined };
}

function addOwned(
  destination: Map<DamageSourceKind, number>,
  kind: DamageSourceKind,
  items: readonly { name: string; level: number }[],
  name: string,
) {
  const item = items.find((candidate) => candidate.name === name && candidate.level > 0);
  if (item) destination.set(kind, item.level);
}

function normalizeTag(value: string) {
  return value.trim().toUpperCase().replaceAll('#', '');
}
function normalize(value: string) {
  return value.trim().toLowerCase();
}
function normalizeResource(value?: string) {
  return value?.trim().toLowerCase().replaceAll(' ', '_') || undefined;
}
function record(value: unknown): Record<string, unknown> | undefined {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}
function rewardAmount(value: unknown, key: string): number | undefined {
  const amount = record(value)?.[key];
  return typeof amount === 'number' && Number.isFinite(amount) && amount > 0
    ? Math.round(amount)
    : undefined;
}
