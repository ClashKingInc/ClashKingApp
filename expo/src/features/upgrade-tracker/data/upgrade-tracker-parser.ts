import { ImageAssets } from '../../../core/assets/image-assets';
import { gameDataState } from '../../../core/game-data/game-data-state';
import {
  UpgradeBoosts,
  UpgradeCategory,
  UpgradeCollectionItem,
  UpgradeCollectionType,
  UpgradeCost,
  UpgradeProgressBasis,
  UpgradeQueue,
  UpgradeStep,
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
  UpgradeVillage,
  type UpgradeCategoryValue,
  type UpgradeCollectionTypeValue,
  type UpgradeQueueValue,
  type UpgradeVillageValue,
} from '../models';

type JsonRecord = Record<string, unknown>;

export class UpgradeTrackerParser {
  private static cachedBundle: JsonRecord | null = null;
  private static cachedLookup: StaticLookup | null = null;

  parse(account: JsonRecord, options: { staticData?: JsonRecord; now?: Date } = {}) {
    const bundle = options.staticData ?? gameDataState.bundleData;
    const lookup = UpgradeTrackerParser.lookupFor(bundle);
    const items: UpgradeTrackerItem[] = [];
    const buildings = [...mapList(account.buildings), ...mapList(account.buildings2)];
    const townHallLevel = hallLevel(buildings, lookup, 'Town Hall');
    const builderHallLevel = hallLevel(buildings, lookup, 'Builder Hall');
    let builderHuts = 0,
      bobUnlocked = false;
    for (const raw of buildings) {
      const data = lookup.byId.get(int(raw.data));
      if (!data) continue;
      const name = itemName(data);
      if (name === "Builder's Hut") builderHuts += int(raw.cnt, 1);
      if (name === "B.O.B's Hut" && int(raw.lvl) > 0) bobUnlocked = true;
      addBuildingItems(items, raw, data, townHallLevel, builderHallLevel, lookup);
    }

    addLeveledSection(
      items,
      [...mapList(account.traps), ...mapList(account.traps2)],
      lookup,
      townHallLevel,
      builderHallLevel,
      () => UpgradeCategory.traps,
      () => UpgradeQueue.builders,
      (data, level) =>
        village(data) === UpgradeVillage.home
          ? ImageAssets.getHomeVillageTrapImage(itemName(data), level)
          : ImageAssets.getBuilderBaseTrapImage(itemName(data), level),
      true,
    );
    addLeveledSection(
      items,
      mapList(account.guardians),
      lookup,
      townHallLevel,
      builderHallLevel,
      () => UpgradeCategory.guardians,
      () => UpgradeQueue.builders,
      (data) => ImageAssets.getGuardianImage(itemName(data)),
    );
    addLeveledSection(
      items,
      [...mapList(account.units), ...mapList(account.units2), ...mapList(account.siege_machines)],
      lookup,
      townHallLevel,
      builderHallLevel,
      (data) =>
        data.production_building === 'Workshop'
          ? UpgradeCategory.sieges
          : normalizeResource(data.upgrade_resource).includes('dark')
            ? UpgradeCategory.darkTroops
            : UpgradeCategory.troops,
      () => UpgradeQueue.laboratory,
      (data) =>
        village(data) === UpgradeVillage.home
          ? data.production_building === 'Workshop'
            ? ImageAssets.getSiegeMachineImage(itemName(data))
            : ImageAssets.getTroopImage(itemName(data))
          : ImageAssets.getBuilderBaseTroopImage(itemName(data)),
    );
    addLeveledSection(
      items,
      mapList(account.spells),
      lookup,
      townHallLevel,
      builderHallLevel,
      () => UpgradeCategory.spells,
      () => UpgradeQueue.laboratory,
      (data) => ImageAssets.getSpellImage(itemName(data)),
    );
    addLeveledSection(
      items,
      [...mapList(account.heroes), ...mapList(account.heroes2)],
      lookup,
      townHallLevel,
      builderHallLevel,
      () => UpgradeCategory.heroes,
      () => UpgradeQueue.builders,
      (data) =>
        village(data) === UpgradeVillage.home
          ? ImageAssets.getHeroImage(itemName(data))
          : ImageAssets.getBuilderBaseHeroImage(itemName(data)),
    );
    addLeveledSection(
      items,
      mapList(account.pets),
      lookup,
      townHallLevel,
      builderHallLevel,
      () => UpgradeCategory.pets,
      () => UpgradeQueue.pets,
      (data) => ImageAssets.getPetImage(itemName(data)),
    );
    addLeveledSection(
      items,
      mapList(account.equipment),
      lookup,
      townHallLevel,
      builderHallLevel,
      () => UpgradeCategory.equipment,
      () => UpgradeQueue.none,
      (data) => ImageAssets.getGearImage(itemName(data)),
    );
    addLeveledSection(
      items,
      mapList(account.helpers),
      lookup,
      townHallLevel,
      builderHallLevel,
      () => UpgradeCategory.builders,
      () => UpgradeQueue.none,
      (data) => ImageAssets.getHelperImage(itemName(data)),
    );

    items.sort(
      (a, b) =>
        Object.values(UpgradeVillage).indexOf(a.village) -
          Object.values(UpgradeVillage).indexOf(b.village) ||
        Object.values(UpgradeCategory).indexOf(a.category) -
          Object.values(UpgradeCategory).indexOf(b.category) ||
        Number(a.isComplete) - Number(b.isComplete) ||
        a.name.localeCompare(b.name),
    );
    const timestamp = optionalInt(account.timestamp);
    const capturedAt =
      timestamp == null ? new Date(options.now ?? new Date()) : new Date(timestamp * 1000);
    return new UpgradeTrackerSnapshot({
      tag: String(account.tag ?? ''),
      name: String(account.name ?? 'Player'),
      townHallLevel,
      builderHallLevel,
      homeBuilderCount: clamp(builderHuts + (bobUnlocked ? 1 : 0), 1, 7),
      builderBaseBuilderCount: builderHallLevel >= 6 ? 2 : 1,
      items,
      collections: parseCollections(account, lookup),
      boosts: parseBoosts(account.boosts, mapList(account.helpers)),
      events: [],
      capturedAt,
    });
  }

  private static lookupFor(bundle: JsonRecord) {
    if (bundle === this.cachedBundle && this.cachedLookup) return this.cachedLookup;
    this.cachedBundle = bundle;
    return (this.cachedLookup = new StaticLookup(bundle));
  }
}

function addBuildingItems(
  output: UpgradeTrackerItem[],
  raw: JsonRecord,
  data: JsonRecord,
  townHall: number,
  builderHall: number,
  lookup: StaticLookup,
) {
  const itemVillage = village(data),
    current = int(raw.lvl),
    hall = itemVillage === UpgradeVillage.home ? townHall : builderHall,
    target = maxLevelForHall(data, hall),
    type = String(data.type ?? ''),
    name = itemName(data),
    category = buildingCategory(type, name, target),
    image =
      itemVillage === UpgradeVillage.home
        ? ImageAssets.getHomeVillageBuildingImage(name, current)
        : name === 'Battle Machine' || name === 'Battle Copter'
          ? ImageAssets.getBuilderBaseHeroImage(name)
          : ImageAssets.getBuilderBaseBuildingImage(name, current),
    steps = buildSteps(data, current, target, true),
    totals = upgradeTimeTotals(data, current, steps, true),
    resource =
      category === UpgradeCategory.walls
        ? resourceProgressTotals(data, current, true, category, steps)
        : null;
  output.push(
    new UpgradeTrackerItem({
      id: int(data._id),
      name,
      imageUrl: image,
      village: itemVillage,
      category,
      queue: type === 'Wall' ? UpgradeQueue.none : UpgradeQueue.builders,
      currentLevel: current,
      targetLevel: target,
      count: int(raw.cnt, 1),
      steps,
      completedUpgradeSeconds: totals.completed,
      totalUpgradeSeconds: totals.total,
      meta: data,
      progressBasis: resource ? UpgradeProgressBasis.resources : UpgradeProgressBasis.time,
      completedResourceWeight: resource?.completed ?? 0,
      totalResourceWeight: resource?.total ?? 0,
      activeSeconds: seconds(raw, ['timer', 'upgrade_timer']),
      helperSeconds: seconds(raw, ['helper_timer', 'helperTimer']),
      recurrentHelper: bool(raw.recurrent_helper ?? raw.helper_recurrent ?? raw.recurrentHelper),
      isExtra: bool(raw.extra),
    }),
  );
  addSupercharge(output, raw, data, image, itemVillage);
  addCraftedDefenses(output, raw, data, lookup, itemVillage, hall);
}

function addSupercharge(
  output: UpgradeTrackerItem[],
  raw: JsonRecord,
  data: JsonRecord,
  image: string,
  itemVillage: UpgradeVillageValue,
) {
  const levels = Array.isArray(data.levels) ? data.levels : [],
    last = levels.at(-1);
  if (!isRecord(last) || !isRecord(last.supercharge)) return;
  const supercharge = last.supercharge,
    superLevels = mapList(supercharge.levels);
  if (!superLevels.length) return;
  const current = int(raw.supercharge),
    target = maxLevel(superLevels),
    superData = { levels: superLevels, upgrade_resource: supercharge.upgrade_resource },
    steps = buildSteps(superData, current, target, true),
    totals = upgradeTimeTotals(superData, current, steps, true);
  output.push(
    new UpgradeTrackerItem({
      id: int(data._id),
      name: `${itemName(data)} Supercharge`,
      imageUrl: image,
      village: itemVillage,
      category: UpgradeCategory.supercharge,
      queue: UpgradeQueue.builders,
      currentLevel: current,
      targetLevel: target,
      count: int(raw.cnt, 1),
      steps,
      completedUpgradeSeconds: totals.completed,
      totalUpgradeSeconds: totals.total,
      isSupercharge: true,
      parentName: itemName(data),
      meta: data,
    }),
  );
}

function addCraftedDefenses(
  output: UpgradeTrackerItem[],
  raw: JsonRecord,
  data: JsonRecord,
  lookup: StaticLookup,
  itemVillage: UpgradeVillageValue,
  hall: number,
) {
  for (const type of mapList(raw.types)) {
    const seasonal = lookup.byId.get(int(type.data));
    if (!seasonal) continue;
    for (const moduleRaw of mapList(type.modules)) {
      const module = lookup.byId.get(int(moduleRaw.data));
      if (!module) continue;
      const current = int(moduleRaw.lvl),
        target = maxLevelForHall(module, hall),
        steps = buildSteps(module, current, target, true),
        totals = upgradeTimeTotals(module, current, steps, true);
      output.push(
        new UpgradeTrackerItem({
          id: int(module._id),
          name: itemName(module),
          imageUrl: ImageAssets.getSeasonalDefenseImage(itemName(seasonal), current),
          village: itemVillage,
          category: UpgradeCategory.craftedDefenses,
          queue: UpgradeQueue.builders,
          currentLevel: current,
          targetLevel: target,
          count: 1,
          steps,
          completedUpgradeSeconds: totals.completed,
          totalUpgradeSeconds: totals.total,
          meta: module,
          activeSeconds: seconds(moduleRaw, ['timer', 'upgrade_timer']),
          helperSeconds: seconds(moduleRaw, ['helper_timer', 'helperTimer']),
          recurrentHelper: bool(
            moduleRaw.recurrent_helper ?? moduleRaw.helper_recurrent ?? moduleRaw.recurrentHelper,
          ),
          isExtra: bool(moduleRaw.extra),
          parentName: itemName(seasonal),
        }),
      );
    }
  }
}

function addLeveledSection(
  output: UpgradeTrackerItem[],
  rows: JsonRecord[],
  lookup: StaticLookup,
  townHall: number,
  builderHall: number,
  category: (data: JsonRecord) => UpgradeCategoryValue,
  queue: (data: JsonRecord) => UpgradeQueueValue,
  image: (data: JsonRecord, level: number) => string,
  usesBuildFields = false,
) {
  for (const raw of rows) {
    const data = lookup.byId.get(int(raw.data));
    if (!data || data.is_seasonal === true) continue;
    const itemVillage = village(data),
      hall = itemVillage === UpgradeVillage.home ? townHall : builderHall,
      current = int(raw.lvl),
      target = maxLevelForHall(data, hall),
      itemCategory = category(data),
      itemQueue = queue(data),
      steps = buildSteps(data, current, target, usesBuildFields),
      totals = upgradeTimeTotals(data, current, steps, usesBuildFields),
      resource =
        itemCategory === UpgradeCategory.equipment ||
        (itemCategory === UpgradeCategory.builders && itemQueue === UpgradeQueue.none)
          ? resourceProgressTotals(data, current, usesBuildFields, itemCategory, steps)
          : null;
    output.push(
      new UpgradeTrackerItem({
        id: int(data._id),
        name: itemName(data),
        imageUrl: image(data, current),
        village: itemVillage,
        category: itemCategory,
        queue: itemQueue,
        currentLevel: current,
        targetLevel: target,
        count: int(raw.cnt, 1),
        steps,
        completedUpgradeSeconds: totals.completed,
        totalUpgradeSeconds: totals.total,
        meta: data,
        wardenWeight: optionalNumber(data.warden_weight),
        healerWeight: optionalNumber(data.healer_weight),
        progressBasis: resource ? UpgradeProgressBasis.resources : UpgradeProgressBasis.time,
        completedResourceWeight: resource?.completed ?? 0,
        totalResourceWeight: resource?.total ?? 0,
        activeSeconds: seconds(raw, ['timer', 'upgrade_timer']),
        helperSeconds: seconds(raw, ['helper_timer', 'helperTimer']),
        cooldownSeconds: seconds(raw, ['helper_cooldown', 'helperCooldown', 'cooldown']),
        recurrentHelper: bool(raw.recurrent_helper ?? raw.helper_recurrent ?? raw.recurrentHelper),
        isExtra: bool(raw.extra),
      }),
    );
  }
}

function buildingCategory(type: string, name: string, target: number): UpgradeCategoryValue {
  const normalized = name.toLowerCase().replace(/[^a-z]/g, '');
  if (
    type === 'Worker' &&
    target > 1 &&
    (normalized === 'builderhut' || normalized === 'buildershut')
  )
    return UpgradeCategory.defenses;
  if (type === 'Defense') return UpgradeCategory.defenses;
  if (type === 'Resource') return UpgradeCategory.resources;
  if (type === 'Wall') return UpgradeCategory.walls;
  if (['Worker', 'Worker2', 'Helper'].includes(type)) return UpgradeCategory.builders;
  return UpgradeCategory.army;
}
function resourceProgressTotals(
  data: JsonRecord,
  current: number,
  usesBuild: boolean,
  category: UpgradeCategoryValue,
  steps: readonly UpgradeStep[],
) {
  const byLevel = new Map(mapList(data.levels).map((level) => [int(level.level), level])),
    key = usesBuild ? 'build_cost' : 'upgrade_cost',
    through = usesBuild ? current : current - 1;
  let completed = 0;
  for (let level = 1; level <= through; level++)
    completed += resourceCostsWeight(
      category,
      costs(byLevel.get(level)?.[key], String(data.upgrade_resource ?? '')),
    );
  const remaining = steps.reduce((sum, step) => sum + resourceCostsWeight(category, step.costs), 0);
  return { completed, total: completed + remaining };
}
function resourceCostsWeight(category: UpgradeCategoryValue, values: readonly UpgradeCost[]) {
  if (category === UpgradeCategory.walls) {
    return (
      values.find((x) => x.resource === 'gold' || x.resource === 'builder_gold')?.amount ??
      values.find((x) => x.resource === 'elixir' || x.resource === 'builder_elixir')?.amount ??
      0
    );
  }
  return values.reduce(
    (sum, cost) =>
      sum +
      (category !== UpgradeCategory.equipment
        ? cost.amount
        : cost.resource === 'shiny_ore'
          ? cost.amount
          : cost.resource === 'glowy_ore'
            ? cost.amount * 5
            : cost.resource === 'starry_ore'
              ? cost.amount * 35
              : 0),
    0,
  );
}
function buildSteps(data: JsonRecord, current: number, target: number, usesBuild: boolean) {
  const byLevel = new Map(mapList(data.levels).map((level) => [int(level.level), level])),
    result: UpgradeStep[] = [];
  for (let next = current + 1; next <= target; next++) {
    const stats = byLevel.get(usesBuild ? next : next - 1);
    if (!stats) continue;
    result.push(
      new UpgradeStep(
        next,
        costs(
          stats[usesBuild ? 'build_cost' : 'upgrade_cost'],
          String(data.upgrade_resource ?? ''),
        ),
        int(stats[usesBuild ? 'build_time' : 'upgrade_time']),
      ),
    );
  }
  return result;
}
function upgradeTimeTotals(
  data: JsonRecord,
  current: number,
  steps: readonly UpgradeStep[],
  usesBuild: boolean,
) {
  const byLevel = new Map(mapList(data.levels).map((level) => [int(level.level), level])),
    key = usesBuild ? 'build_time' : 'upgrade_time',
    through = usesBuild ? current : current - 1;
  let completed = 0;
  for (let level = 1; level <= through; level++) completed += int(byLevel.get(level)?.[key]);
  return { completed, total: completed + steps.reduce((sum, step) => sum + step.seconds, 0) };
}
function costs(value: unknown, fallbackResource = '') {
  if (isRecord(value))
    return Object.entries(value)
      .filter(([, amount]) => typeof amount === 'number' && amount > 0)
      .map(([resource, amount]) => new UpgradeCost(normalizeResource(resource), amount as number));
  return typeof value === 'number' && value > 0
    ? [new UpgradeCost(normalizeResource(fallbackResource), value)]
    : [];
}

function parseCollections(account: JsonRecord, lookup: StaticLookup) {
  const ownedCounts = new Map<number, number>();
  for (const key of ['decos', 'decos2', 'obstacles', 'obstacles2'])
    for (const row of mapList(account[key]))
      ownedCounts.set(int(row.data), (ownedCounts.get(int(row.data)) ?? 0) + int(row.cnt, 1));
  const ownedIds = new Set(ownedCounts.keys());
  for (const key of ['skins', 'skins2', 'sceneries', 'sceneries2', 'house_parts'])
    if (Array.isArray(account[key])) for (const raw of account[key]) ownedIds.add(int(raw));
  const result: UpgradeCollectionItem[] = [],
    seen = new Set<string>();
  const add = (
    staticKey: string,
    type: UpgradeCollectionTypeValue,
    image: (data: JsonRecord) => string,
    options: {
      defaultOwned?: (data: JsonRecord) => boolean;
      subtitle?: (data: JsonRecord) => string | null;
      villageOverride?: UpgradeVillageValue;
    } = {},
  ) => {
    for (const data of mapList(lookup.bundle[staticKey])) {
      const id = int(data._id),
        key = `${type}:${id}`;
      if (seen.has(key)) continue;
      seen.add(key);
      const owned = ownedIds.has(id) || (options.defaultOwned?.(data) ?? false);
      let itemVillage: UpgradeVillageValue | null = null;
      if (type === UpgradeCollectionType.skins)
        itemVillage = options.villageOverride ?? skinVillage(data);
      else if (type === UpgradeCollectionType.sceneries)
        itemVillage =
          data.type === 'builderBase' ? UpgradeVillage.builderBase : UpgradeVillage.home;
      else if (
        type === UpgradeCollectionType.decorations ||
        type === UpgradeCollectionType.obstacles
      )
        itemVillage = village(data);
      result.push(
        new UpgradeCollectionItem({
          id,
          name: itemName(data),
          imageUrl: image(data),
          type,
          owned,
          village: itemVillage,
          count: ownedCounts.get(id) ?? (owned ? 1 : 0),
          maxCount: int(data.max_count, 1),
          subtitle: options.subtitle?.(data) ?? null,
          meta: data,
        }),
      );
    }
  };
  add(
    'skins',
    UpgradeCollectionType.skins,
    (data) => `${ImageAssets.baseUrl}/skins/${slug(itemName(data))}/icon.webp`,
    {
      defaultOwned: (data) => data.tier === 'Default',
      subtitle: (data) => String(data.character ?? '') || null,
    },
  );
  add(
    'skins2',
    UpgradeCollectionType.skins,
    (data) => `${ImageAssets.baseUrl}/skins/${slug(itemName(data))}/icon.webp`,
    {
      defaultOwned: (data) => data.tier === 'Default',
      subtitle: (data) => String(data.character ?? '') || null,
      villageOverride: UpgradeVillage.builderBase,
    },
  );
  add(
    'sceneries',
    UpgradeCollectionType.sceneries,
    (data) => `${ImageAssets.baseUrl}/${String(data.thumbnail ?? '')}`,
    {
      defaultOwned: (data) => itemName(data) === 'Classic Scenery',
      subtitle: (data) => String(data.type ?? '') || null,
    },
  );
  add(
    'decorations',
    UpgradeCollectionType.decorations,
    (data) =>
      `${ImageAssets.baseUrl}/decorations/${villageFolder(data)}/${slug(itemName(data))}.webp`,
  );
  add(
    'obstacles',
    UpgradeCollectionType.obstacles,
    (data) =>
      `${ImageAssets.baseUrl}/obstacles/${villageFolder(data)}/${slug(itemName(data))}.webp`,
  );
  add(
    'capital_house_parts',
    UpgradeCollectionType.capitalHouseParts,
    (data) => `${ImageAssets.baseUrl}/capital_house_parts/${String(data._id)}.webp`,
    { subtitle: (data) => String(data.slot_type ?? '') || null },
  );
  return result.sort(
    (a, b) =>
      Object.values(UpgradeCollectionType).indexOf(a.type) -
        Object.values(UpgradeCollectionType).indexOf(b.type) ||
      Number(b.owned) - Number(a.owned) ||
      a.name.localeCompare(b.name),
  );
}

function parseBoosts(raw: unknown, helpers: JsonRecord[]) {
  const boosts = isRecord(raw) ? raw : {},
    percent = (keys: string[]) => {
      for (const key of keys) {
        const value = optionalInt(boosts[key]);
        if (value != null) return clamp(value, 0, 50);
      }
      return 0;
    },
    duration = (keys: string[]) => {
      for (const key of keys) {
        const value = optionalInt(boosts[key]);
        if (value != null) return clamp(value, 0, 31536000);
      }
      return 0;
    };
  let helperCooldown = duration(['helper_cooldown', 'helperCooldown']);
  for (const helper of helpers)
    helperCooldown = Math.max(
      helperCooldown,
      seconds(helper, ['helper_cooldown', 'helperCooldown', 'cooldown']) ?? 0,
    );
  return new UpgradeBoosts({
    builderBoostSeconds: duration(['town_hall_builder_boost', 'townHallBuilderBoost']),
    labBoostSeconds: duration(['town_hall_lab_boost', 'townHallLabBoost']),
    clockTowerBoostSeconds: duration(['clocktower_boost', 'clockTowerBoost']),
    clockTowerCooldownSeconds: duration(['clocktower_cooldown', 'clockTowerCooldown']),
    builderConsumableSeconds: duration([
      'builder_boost',
      'builderBoost',
      'builder_consumable',
      'builder_potion',
      'builderPotion',
    ]),
    labConsumableSeconds: duration([
      'lab_boost',
      'labBoost',
      'lab_consumable',
      'research_potion',
      'researchPotion',
    ]),
    petConsumableSeconds: duration([
      'pet_consumable',
      'pet_potion',
      'petPotion',
      'pet_boost',
      'petBoost',
    ]),
    helperCooldownSeconds: helperCooldown,
    builderCostReductionPercent: percent(['builder_cost_reduction', 'building_cost_reduction']),
    builderTimeReductionPercent: percent(['builder_time_reduction', 'building_time_reduction']),
    labCostReductionPercent: percent(['lab_cost_reduction', 'research_cost_reduction']),
    labTimeReductionPercent: percent(['lab_time_reduction', 'research_time_reduction']),
  });
}

class StaticLookup {
  readonly byId = new Map<number, JsonRecord>();
  constructor(readonly bundle: JsonRecord) {
    for (const key of [
      'buildings',
      'traps',
      'troops',
      'guardians',
      'spells',
      'heroes',
      'pets',
      'equipment',
      'decorations',
      'obstacles',
      'sceneries',
      'skins',
      'skins2',
      'capital_house_parts',
      'helpers',
    ])
      for (const raw of mapList(bundle[key])) {
        this.byId.set(int(raw._id), raw);
        if (key === 'buildings')
          for (const seasonal of mapList(raw.seasonal_defenses)) {
            this.byId.set(int(seasonal._id), seasonal);
            for (const module of mapList(seasonal.modules)) this.byId.set(int(module._id), module);
          }
      }
  }
}
function hallLevel(rows: JsonRecord[], lookup: StaticLookup, name: string) {
  for (const row of rows) if (lookup.byId.get(int(row.data))?.name === name) return int(row.lvl);
  return 0;
}
function maxLevelForHall(data: JsonRecord, hall: number) {
  const levels = mapList(data.levels);
  let max = 0;
  for (const level of levels) {
    const required = optionalInt(level.required_townhall);
    if (required == null || hall <= 0 || required <= hall) max = Math.max(max, int(level.level));
  }
  return max > 0 ? max : maxLevel(levels);
}
function maxLevel(levels: JsonRecord[]) {
  return levels.reduce((max, level) => Math.max(max, int(level.level)), 0);
}
function mapList(value: unknown): JsonRecord[] {
  return Array.isArray(value) ? value.filter(isRecord) : [];
}
function optionalInt(value: unknown) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  if (typeof value === 'string' && /^[+-]?\d+$/.test(value.trim()))
    return Number.parseInt(value.trim(), 10);
  return null;
}
function int(value: unknown, fallback = 0) {
  return optionalInt(value) ?? fallback;
}
function optionalNumber(value: unknown) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() && Number.isFinite(Number(value)))
    return Number(value);
  return null;
}
function seconds(row: JsonRecord, keys: string[]) {
  for (const key of keys) {
    const value = optionalInt(row[key]);
    if (value != null) return clamp(value, 0, 31536000);
  }
  return null;
}
function bool(value: unknown) {
  return (
    value === true ||
    value === 1 ||
    (typeof value === 'string' && (value.toLowerCase() === 'true' || value === '1'))
  );
}
function itemName(data: JsonRecord) {
  return String(data.name ?? 'Unknown');
}
function village(data: JsonRecord): UpgradeVillageValue {
  return data.village === 'builderBase' ? UpgradeVillage.builderBase : UpgradeVillage.home;
}
function skinVillage(data: JsonRecord) {
  return String(data.character ?? '')
    .toLowerCase()
    .startsWith('bb ')
    ? UpgradeVillage.builderBase
    : village(data);
}
function villageFolder(data: JsonRecord) {
  return village(data) === UpgradeVillage.home ? 'home-village' : 'builder-base';
}
function normalizeResource(value: unknown) {
  return String(value ?? 'resource')
    .trim()
    .toLowerCase()
    .replaceAll(' ', '_')
    .replaceAll('-', '_');
}
function slug(value: string) {
  return value
    .toLowerCase()
    .replaceAll(' ', '_')
    .replaceAll('.', '')
    .replaceAll('?', '')
    .replaceAll('\\q', '')
    .replaceAll('’', '');
}
function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value));
}
function isRecord(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
