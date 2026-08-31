export const UpgradeVillage = { home: 'home', builderBase: 'builderBase' } as const;
export type UpgradeVillageValue = (typeof UpgradeVillage)[keyof typeof UpgradeVillage];

export const UpgradeCategory = {
  defenses: 'defenses',
  guardians: 'guardians',
  craftedDefenses: 'craftedDefenses',
  traps: 'traps',
  army: 'army',
  resources: 'resources',
  troops: 'troops',
  spells: 'spells',
  darkTroops: 'darkTroops',
  sieges: 'sieges',
  heroes: 'heroes',
  equipment: 'equipment',
  pets: 'pets',
  walls: 'walls',
  builders: 'builders',
  supercharge: 'supercharge',
} as const;
export type UpgradeCategoryValue = (typeof UpgradeCategory)[keyof typeof UpgradeCategory];
export const upgradeCategories = Object.values(UpgradeCategory);

export const UpgradeQueue = {
  builders: 'builders',
  laboratory: 'laboratory',
  pets: 'pets',
  none: 'none',
} as const;
export type UpgradeQueueValue = (typeof UpgradeQueue)[keyof typeof UpgradeQueue];
export const UpgradeProgressBasis = {
  time: 'time',
  resources: 'resources',
  mixed: 'mixed',
} as const;
export type UpgradeProgressBasisValue =
  (typeof UpgradeProgressBasis)[keyof typeof UpgradeProgressBasis];
export const UpgradeWallResourcePreference = { gold: 'gold', elixir: 'elixir' } as const;
export type UpgradeWallResourcePreferenceValue =
  (typeof UpgradeWallResourcePreference)[keyof typeof UpgradeWallResourcePreference];
export const UpgradePlanStrategy = {
  balanced: 'balanced',
  shortest: 'shortest',
  cheapest: 'cheapest',
} as const;
export type UpgradePlanStrategyValue =
  (typeof UpgradePlanStrategy)[keyof typeof UpgradePlanStrategy];
export const UpgradeResourcePreference = {
  conserve: 'conserve',
  balanced: 'balanced',
  spend: 'spend',
} as const;
export type UpgradeResourcePreferenceValue =
  (typeof UpgradeResourcePreference)[keyof typeof UpgradeResourcePreference];
export const UpgradePlanGoal = {
  maxCurrentHall: 'maxCurrentHall',
  rushNextHall: 'rushNextHall',
  catchUp: 'catchUp',
  unlockFirst: 'unlockFirst',
} as const;
export type UpgradePlanGoalValue = (typeof UpgradePlanGoal)[keyof typeof UpgradePlanGoal];
export const UpgradeCollectionType = {
  skins: 'skins',
  sceneries: 'sceneries',
  decorations: 'decorations',
  obstacles: 'obstacles',
  capitalHouseParts: 'capitalHouseParts',
} as const;
export type UpgradeCollectionTypeValue =
  (typeof UpgradeCollectionType)[keyof typeof UpgradeCollectionType];

export class UpgradeCost {
  constructor(
    readonly resource: string,
    readonly amount: number,
  ) {}
}
export class UpgradeStep {
  constructor(
    readonly targetLevel: number,
    readonly costs: readonly UpgradeCost[],
    readonly seconds: number,
  ) {}
}

export interface UpgradeTrackerItemOptions {
  id: number;
  name: string;
  imageUrl: string;
  village: UpgradeVillageValue;
  category: UpgradeCategoryValue;
  queue: UpgradeQueueValue;
  currentLevel: number;
  targetLevel: number;
  count: number;
  steps: readonly UpgradeStep[];
  completedUpgradeSeconds: number;
  totalUpgradeSeconds: number;
  activeSeconds?: number | null;
  helperSeconds?: number | null;
  cooldownSeconds?: number | null;
  recurrentHelper?: boolean;
  isExtra?: boolean;
  isSupercharge?: boolean;
  progressBasis?: UpgradeProgressBasisValue;
  completedResourceWeight?: number;
  totalResourceWeight?: number;
  parentName?: string | null;
  meta?: Record<string, unknown> | null;
  wardenWeight?: number | null;
  healerWeight?: number | null;
}

export class UpgradeTrackerItem {
  readonly id: number;
  readonly name: string;
  readonly imageUrl: string;
  readonly village: UpgradeVillageValue;
  readonly category: UpgradeCategoryValue;
  readonly queue: UpgradeQueueValue;
  readonly currentLevel: number;
  readonly targetLevel: number;
  readonly count: number;
  readonly steps: readonly UpgradeStep[];
  readonly completedUpgradeSeconds: number;
  readonly totalUpgradeSeconds: number;
  readonly activeSeconds: number | null;
  readonly helperSeconds: number | null;
  readonly cooldownSeconds: number | null;
  readonly recurrentHelper: boolean;
  readonly isExtra: boolean;
  readonly isSupercharge: boolean;
  readonly progressBasis: UpgradeProgressBasisValue;
  readonly completedResourceWeight: number;
  readonly totalResourceWeight: number;
  readonly parentName: string | null;
  readonly meta: Record<string, unknown> | null;
  readonly wardenWeight: number | null;
  readonly healerWeight: number | null;

  constructor(options: UpgradeTrackerItemOptions) {
    Object.assign(this, options);
    this.id = options.id;
    this.name = options.name;
    this.imageUrl = options.imageUrl;
    this.village = options.village;
    this.category = options.category;
    this.queue = options.queue;
    this.currentLevel = options.currentLevel;
    this.targetLevel = options.targetLevel;
    this.count = options.count;
    this.steps = options.steps;
    this.completedUpgradeSeconds = options.completedUpgradeSeconds;
    this.totalUpgradeSeconds = options.totalUpgradeSeconds;
    this.activeSeconds = options.activeSeconds ?? null;
    this.helperSeconds = options.helperSeconds ?? null;
    this.cooldownSeconds = options.cooldownSeconds ?? null;
    this.recurrentHelper = options.recurrentHelper ?? false;
    this.isExtra = options.isExtra ?? false;
    this.isSupercharge = options.isSupercharge ?? false;
    this.progressBasis = options.progressBasis ?? UpgradeProgressBasis.time;
    this.completedResourceWeight = options.completedResourceWeight ?? 0;
    this.totalResourceWeight = options.totalResourceWeight ?? 0;
    this.parentName = options.parentName ?? null;
    this.meta = options.meta ?? null;
    this.wardenWeight = options.wardenWeight ?? null;
    this.healerWeight = options.healerWeight ?? null;
  }
  get isComplete() {
    return this.currentLevel >= this.targetLevel;
  }
  get isUnbuilt() {
    return this.currentLevel <= 0;
  }
  get planKey() {
    return `${this.id}:${this.category}`;
  }
  get levelsRemaining() {
    return clamp(this.targetLevel - this.currentLevel, 0, this.targetLevel);
  }
  get totalSeconds() {
    return this.steps.reduce((sum, step) => sum + step.seconds, 0);
  }
  get resourceCompletion() {
    if (this.totalResourceWeight > 0)
      return clamp(this.completedResourceWeight / this.totalResourceWeight, 0, 1);
    if (this.isComplete) return 1;
    return this.targetLevel <= 0 ? 0 : clamp(this.currentLevel / this.targetLevel, 0, 1);
  }
  get progressCompletion() {
    if (this.progressBasis !== UpgradeProgressBasis.time) return this.resourceCompletion;
    return this.totalUpgradeSeconds <= 0
      ? this.isComplete
        ? 1
        : 0
      : clamp(this.completedUpgradeSeconds / this.totalUpgradeSeconds, 0, 1);
  }
  get totalCosts(): Readonly<Record<string, number>> {
    const result: Record<string, number> = {};
    for (const step of this.steps)
      for (const cost of step.costs)
        result[cost.resource] = (result[cost.resource] ?? 0) + cost.amount;
    return result;
  }
}

export class UpgradeEventModifier {
  constructor(
    readonly name: string,
    readonly startsAt: Date,
    readonly endsAt: Date,
    readonly costReductionPercent: number,
    readonly timeReductionPercent: number,
    readonly resources: ReadonlySet<string> = new Set(),
    readonly categories: ReadonlySet<UpgradeCategoryValue> = new Set(),
  ) {}
  appliesAt(time: Date, item: UpgradeTrackerItem, resource: string) {
    return (
      time >= this.startsAt &&
      time < this.endsAt &&
      (this.resources.size === 0 || this.resources.has(resource)) &&
      (this.categories.size === 0 || this.categories.has(item.category))
    );
  }
}

export interface UpgradeBoostOptions {
  builderBoostSeconds?: number;
  labBoostSeconds?: number;
  clockTowerBoostSeconds?: number;
  clockTowerCooldownSeconds?: number;
  builderConsumableSeconds?: number;
  labConsumableSeconds?: number;
  petConsumableSeconds?: number;
  helperCooldownSeconds?: number;
  builderCostReductionPercent?: number;
  builderTimeReductionPercent?: number;
  labCostReductionPercent?: number;
  labTimeReductionPercent?: number;
}
export class UpgradeBoosts {
  readonly builderBoostSeconds;
  readonly labBoostSeconds;
  readonly clockTowerBoostSeconds;
  readonly clockTowerCooldownSeconds;
  readonly builderConsumableSeconds;
  readonly labConsumableSeconds;
  readonly petConsumableSeconds;
  readonly helperCooldownSeconds;
  readonly builderCostReductionPercent;
  readonly builderTimeReductionPercent;
  readonly labCostReductionPercent;
  readonly labTimeReductionPercent;
  constructor(options: UpgradeBoostOptions = {}) {
    this.builderBoostSeconds = options.builderBoostSeconds ?? 0;
    this.labBoostSeconds = options.labBoostSeconds ?? 0;
    this.clockTowerBoostSeconds = options.clockTowerBoostSeconds ?? 0;
    this.clockTowerCooldownSeconds = options.clockTowerCooldownSeconds ?? 0;
    this.builderConsumableSeconds = options.builderConsumableSeconds ?? 0;
    this.labConsumableSeconds = options.labConsumableSeconds ?? 0;
    this.petConsumableSeconds = options.petConsumableSeconds ?? 0;
    this.helperCooldownSeconds = options.helperCooldownSeconds ?? 0;
    this.builderCostReductionPercent = options.builderCostReductionPercent ?? 0;
    this.builderTimeReductionPercent = options.builderTimeReductionPercent ?? 0;
    this.labCostReductionPercent = options.labCostReductionPercent ?? 0;
    this.labTimeReductionPercent = options.labTimeReductionPercent ?? 0;
  }
  get hasTemporaryBoost() {
    return (
      this.builderBoostSeconds > 0 ||
      this.labBoostSeconds > 0 ||
      this.clockTowerBoostSeconds > 0 ||
      this.builderConsumableSeconds > 0 ||
      this.labConsumableSeconds > 0 ||
      this.petConsumableSeconds > 0
    );
  }
}

const defaultPlanningOrder: readonly UpgradeCategoryValue[] = [
  UpgradeCategory.defenses,
  UpgradeCategory.craftedDefenses,
  UpgradeCategory.traps,
  UpgradeCategory.army,
  UpgradeCategory.resources,
  UpgradeCategory.heroes,
  UpgradeCategory.guardians,
  UpgradeCategory.troops,
  UpgradeCategory.darkTroops,
  UpgradeCategory.spells,
  UpgradeCategory.sieges,
  UpgradeCategory.equipment,
  UpgradeCategory.pets,
  UpgradeCategory.supercharge,
  UpgradeCategory.walls,
];
export interface UpgradePlanPreferencesOptions {
  homeGoal?: UpgradePlanGoalValue;
  builderBaseGoal?: UpgradePlanGoalValue;
  homeCategoryOrder?: readonly UpgradeCategoryValue[];
  builderBaseCategoryOrder?: readonly UpgradeCategoryValue[];
  homeCategoryTargets?: ReadonlyMap<UpgradeCategoryValue, number>;
  builderBaseCategoryTargets?: ReadonlyMap<UpgradeCategoryValue, number>;
  homeCategoryShares?: ReadonlyMap<UpgradeCategoryValue, number>;
  builderBaseCategoryShares?: ReadonlyMap<UpgradeCategoryValue, number>;
  prioritizeUnbuiltBuilders?: boolean;
  prioritizeUnbuiltLaboratory?: boolean;
  prioritizeUnbuiltPets?: boolean;
  wallResourcePreference?: UpgradeWallResourcePreferenceValue;
  wallsPerWeek?: number;
}
export class UpgradePlanPreferences {
  readonly homeGoal;
  readonly builderBaseGoal;
  readonly homeCategoryOrder;
  readonly builderBaseCategoryOrder;
  readonly homeCategoryTargets;
  readonly builderBaseCategoryTargets;
  readonly homeCategoryShares;
  readonly builderBaseCategoryShares;
  readonly prioritizeUnbuiltBuilders;
  readonly prioritizeUnbuiltLaboratory;
  readonly prioritizeUnbuiltPets;
  readonly wallResourcePreference;
  readonly wallsPerWeek;
  constructor(options: UpgradePlanPreferencesOptions = {}) {
    this.homeGoal = options.homeGoal ?? UpgradePlanGoal.maxCurrentHall;
    this.builderBaseGoal = options.builderBaseGoal ?? UpgradePlanGoal.maxCurrentHall;
    this.homeCategoryOrder = options.homeCategoryOrder ?? [];
    this.builderBaseCategoryOrder = options.builderBaseCategoryOrder ?? [];
    this.homeCategoryTargets = options.homeCategoryTargets ?? new Map();
    this.builderBaseCategoryTargets = options.builderBaseCategoryTargets ?? new Map();
    this.homeCategoryShares = options.homeCategoryShares ?? new Map();
    this.builderBaseCategoryShares = options.builderBaseCategoryShares ?? new Map();
    this.prioritizeUnbuiltBuilders = options.prioritizeUnbuiltBuilders ?? true;
    this.prioritizeUnbuiltLaboratory = options.prioritizeUnbuiltLaboratory ?? true;
    this.prioritizeUnbuiltPets = options.prioritizeUnbuiltPets ?? true;
    this.wallResourcePreference =
      options.wallResourcePreference ?? UpgradeWallResourcePreference.gold;
    this.wallsPerWeek = options.wallsPerWeek ?? 0;
  }
  prioritizeUnbuiltFor(queue: UpgradeQueueValue) {
    return queue === UpgradeQueue.builders
      ? this.prioritizeUnbuiltBuilders
      : queue === UpgradeQueue.laboratory
        ? this.prioritizeUnbuiltLaboratory
        : queue === UpgradeQueue.pets
          ? this.prioritizeUnbuiltPets
          : false;
  }
  goalFor(village: UpgradeVillageValue) {
    return village === UpgradeVillage.home ? this.homeGoal : this.builderBaseGoal;
  }
  orderFor(village: UpgradeVillageValue) {
    return village === UpgradeVillage.home ? this.homeCategoryOrder : this.builderBaseCategoryOrder;
  }
  categoryRank(category: UpgradeCategoryValue, village: UpgradeVillageValue = UpgradeVillage.home) {
    const saved = this.orderFor(village).indexOf(category),
      fallback = defaultPlanningOrder.indexOf(category);
    return saved >= 0 ? saved : fallback >= 0 ? fallback : 999;
  }
  targetFor(category: UpgradeCategoryValue, village: UpgradeVillageValue = UpgradeVillage.home) {
    return (
      (village === UpgradeVillage.home
        ? this.homeCategoryTargets
        : this.builderBaseCategoryTargets
      ).get(category) ?? 100
    );
  }
  shareFor(category: UpgradeCategoryValue, village: UpgradeVillageValue = UpgradeVillage.home) {
    return (
      (village === UpgradeVillage.home
        ? this.homeCategoryShares
        : this.builderBaseCategoryShares
      ).get(category) ?? 0
    );
  }
  priorityTierFor(
    category: UpgradeCategoryValue,
    village: UpgradeVillageValue = UpgradeVillage.home,
  ) {
    const saved = this.orderFor(village),
      order = [...saved, ...defaultPlanningOrder.filter((v) => !saved.includes(v))];
    let tier = 0,
      previous = false;
    for (const value of order) {
      const shared = this.shareFor(value, village) > 0;
      if (tier === 0 || !shared || !previous) tier++;
      if (value === category) return tier;
      previous = shared;
    }
    return 999;
  }
  toJson(): Record<string, unknown> {
    return {
      home_goal: this.homeGoal,
      builder_base_goal: this.builderBaseGoal,
      home_category_order: [...this.homeCategoryOrder],
      builder_base_category_order: [...this.builderBaseCategoryOrder],
      home_category_targets: mapToRecord(this.homeCategoryTargets),
      builder_base_category_targets: mapToRecord(this.builderBaseCategoryTargets),
      home_category_shares: mapToRecord(this.homeCategoryShares),
      builder_base_category_shares: mapToRecord(this.builderBaseCategoryShares),
      prioritize_unbuilt_builders: this.prioritizeUnbuiltBuilders,
      prioritize_unbuilt_laboratory: this.prioritizeUnbuiltLaboratory,
      prioritize_unbuilt_pets: this.prioritizeUnbuiltPets,
      wall_resource_preference: this.wallResourcePreference,
      walls_per_week: this.wallsPerWeek,
    };
  }
  static fromJson(json: Record<string, unknown> | null | undefined) {
    if (!json) return new UpgradePlanPreferences();
    const legacyOrder = categoryOrder(json.category_order),
      legacy = boolValue(json.prioritize_unbuilt, true),
      home = categoryOrder(json.home_category_order);
    return new UpgradePlanPreferences({
      homeGoal: goalValue(json.home_goal),
      builderBaseGoal: goalValue(json.builder_base_goal),
      homeCategoryOrder: home.length ? home : legacyOrder,
      builderBaseCategoryOrder: categoryOrder(json.builder_base_category_order),
      homeCategoryTargets: categoryTargets(json.home_category_targets ?? json.category_targets),
      builderBaseCategoryTargets: categoryTargets(
        json.builder_base_category_targets ?? json.category_targets,
      ),
      homeCategoryShares: categoryTargets(json.home_category_shares),
      builderBaseCategoryShares: categoryTargets(json.builder_base_category_shares),
      prioritizeUnbuiltBuilders: boolValue(json.prioritize_unbuilt_builders, legacy),
      prioritizeUnbuiltLaboratory: boolValue(json.prioritize_unbuilt_laboratory, legacy),
      prioritizeUnbuiltPets: boolValue(json.prioritize_unbuilt_pets, legacy),
      wallResourcePreference: Object.values(UpgradeWallResourcePreference).includes(
        json.wall_resource_preference as UpgradeWallResourcePreferenceValue,
      )
        ? (json.wall_resource_preference as UpgradeWallResourcePreferenceValue)
        : UpgradeWallResourcePreference.gold,
      wallsPerWeek: clamp(intValue(json.walls_per_week, 0), 0, 100),
    });
  }
}

export function normalizeUpgradePlanPreferencesForQueue(
  snapshot: UpgradeTrackerSnapshot,
  source: UpgradePlanPreferences,
  village: UpgradeVillageValue,
  queue: UpgradeQueueValue,
) {
  const available = new Set(snapshot.itemsFor({ village, queue }).map((item) => item.category)),
    saved = source.orderFor(village),
    order = [
      ...saved.filter((v) => available.has(v)),
      ...upgradeCategories.filter((v) => available.has(v) && !saved.includes(v)),
    ];
  return new UpgradePlanPreferences({
    ...source,
    homeCategoryOrder: village === UpgradeVillage.home ? order : source.homeCategoryOrder,
    builderBaseCategoryOrder:
      village === UpgradeVillage.builderBase ? order : source.builderBaseCategoryOrder,
  });
}

export interface UpgradeCollectionItemOptions {
  id: number;
  name: string;
  imageUrl: string;
  type: UpgradeCollectionTypeValue;
  owned: boolean;
  village?: UpgradeVillageValue | null;
  count?: number;
  maxCount?: number;
  subtitle?: string | null;
  meta?: Record<string, unknown> | null;
}
export class UpgradeCollectionItem {
  readonly id;
  readonly name;
  readonly imageUrl;
  readonly type;
  readonly owned;
  readonly village;
  readonly count;
  readonly maxCount;
  readonly subtitle;
  readonly meta;
  constructor(o: UpgradeCollectionItemOptions) {
    this.id = o.id;
    this.name = o.name;
    this.imageUrl = o.imageUrl;
    this.type = o.type;
    this.owned = o.owned;
    this.village = o.village ?? null;
    this.count = o.count ?? 0;
    this.maxCount = o.maxCount ?? 1;
    this.subtitle = o.subtitle ?? null;
    this.meta = o.meta ?? null;
  }
}
export class UpgradeCategorySummary {
  constructor(
    readonly category: UpgradeCategoryValue,
    readonly basis: UpgradeProgressBasisValue,
    readonly current: number,
    readonly target: number,
    readonly levelsRemaining: number,
    readonly seconds: number,
    readonly completedSeconds: number,
    readonly totalUpgradeSeconds: number,
    readonly completedProgressWeight: number,
    readonly totalProgressWeight: number,
    readonly costs: Readonly<Record<string, number>>,
  ) {}
  get completion() {
    if (this.basis === UpgradeProgressBasis.time) {
      if (this.totalUpgradeSeconds <= 0) return this.totalProgressWeight <= 0 ? 1 : 0;
      return clamp(this.completedSeconds / this.totalUpgradeSeconds, 0, 1);
    }
    return this.totalProgressWeight <= 0
      ? 1
      : clamp(this.completedProgressWeight / this.totalProgressWeight, 0, 1);
  }
}
export class PlannedUpgrade {
  constructor(
    readonly item: UpgradeTrackerItem,
    readonly instance: number,
    readonly step: UpgradeStep,
    readonly startsAt: Date,
    readonly endsAt: Date,
    readonly costs: readonly UpgradeCost[],
    readonly isOngoing = false,
  ) {}
}
export class UpgradePlanLane {
  constructor(
    readonly index: number,
    readonly upgrades: readonly PlannedUpgrade[],
    readonly reservedUntil: Date | null = null,
  ) {}
  get finishesAt() {
    const last = this.upgrades.at(-1)?.endsAt ?? null;
    if (!last) return this.reservedUntil;
    if (!this.reservedUntil || last > this.reservedUntil) return last;
    return this.reservedUntil;
  }
}

export interface UpgradeTrackerSnapshotOptions {
  tag: string;
  name: string;
  townHallLevel: number;
  builderHallLevel: number;
  homeBuilderCount: number;
  builderBaseBuilderCount: number;
  items: readonly UpgradeTrackerItem[];
  collections: readonly UpgradeCollectionItem[];
  boosts: UpgradeBoosts;
  events: readonly UpgradeEventModifier[];
  capturedAt: Date;
}
export interface ItemsForOptions {
  village?: UpgradeVillageValue;
  category?: UpgradeCategoryValue;
  queue?: UpgradeQueueValue;
  remainingOnly?: boolean;
}
export class UpgradeTrackerSnapshot {
  readonly tag;
  readonly name;
  readonly townHallLevel;
  readonly builderHallLevel;
  readonly homeBuilderCount;
  readonly builderBaseBuilderCount;
  readonly items;
  readonly collections;
  readonly boosts;
  readonly events;
  readonly capturedAt;
  private readonly itemsForCache = new Map<string, readonly UpgradeTrackerItem[]>();
  private readonly summaryCache = new Map<string, UpgradeCategorySummary>();
  constructor(o: UpgradeTrackerSnapshotOptions) {
    this.tag = o.tag;
    this.name = o.name;
    this.townHallLevel = o.townHallLevel;
    this.builderHallLevel = o.builderHallLevel;
    this.homeBuilderCount = o.homeBuilderCount;
    this.builderBaseBuilderCount = o.builderBaseBuilderCount;
    this.items = o.items;
    this.collections = o.collections;
    this.boosts = o.boosts;
    this.events = o.events;
    this.capturedAt = o.capturedAt;
  }
  get builderCount() {
    return this.homeBuilderCount;
  }
  buildersFor(v: UpgradeVillageValue) {
    return v === UpgradeVillage.home ? this.homeBuilderCount : this.builderBaseBuilderCount;
  }
  remainingCapturedSeconds(original: number, now = new Date()) {
    if (original <= 0) return 0;
    const elapsed = Math.floor((now.getTime() - this.capturedAt.getTime()) / 1000);
    return clamp(original - clamp(elapsed, 0, original), 0, original);
  }
  remainingActiveSeconds(item: UpgradeTrackerItem, now = new Date()) {
    return this.remainingCapturedSeconds(item.activeSeconds ?? 0, now);
  }
  activeElapsedSeconds(item: UpgradeTrackerItem, now = new Date()) {
    const original = item.activeSeconds,
      first = item.steps[0]?.seconds ?? 0;
    if (original == null || original <= 0 || first <= 0) return 0;
    return clamp(first - this.remainingActiveSeconds(item, now), 0, first);
  }
  remainingHelperSeconds(item: UpgradeTrackerItem, now = new Date()) {
    return this.remainingCapturedSeconds(item.helperSeconds ?? 0, now);
  }
  remainingCooldownSeconds(item: UpgradeTrackerItem, now = new Date()) {
    return this.remainingCapturedSeconds(item.cooldownSeconds ?? 0, now);
  }
  helperNameFor(item: UpgradeTrackerItem) {
    if ((item.helperSeconds ?? 0) <= 0) return null;
    const match = this.items.find(
      (helper) =>
        helper.category === UpgradeCategory.builders &&
        (item.queue === UpgradeQueue.laboratory
          ? helper.name.toLowerCase().includes('lab') ||
            helper.name.toLowerCase().includes('research')
          : helper.name.toLowerCase().includes('builder')),
    );
    return (
      match?.name ??
      (item.queue === UpgradeQueue.laboratory ? 'Lab Assistant' : 'Builder Apprentice')
    );
  }
  itemsFor(o: ItemsForOptions = {}) {
    const key = `${o.village ?? ''}|${o.category ?? ''}|${o.queue ?? ''}|${o.remainingOnly ?? false}`,
      existing = this.itemsForCache.get(key);
    if (existing) return existing;
    const value = this.items.filter(
      (item) =>
        (!o.village || item.village === o.village) &&
        (!o.category || item.category === o.category) &&
        (!o.queue || item.queue === o.queue) &&
        (!o.remainingOnly || !item.isComplete),
    );
    this.itemsForCache.set(key, value);
    return value;
  }
  summaryFor(category: UpgradeCategoryValue, village: UpgradeVillageValue = UpgradeVillage.home) {
    const key = `${village}|${category}`,
      existing = this.summaryCache.get(key);
    if (existing) return existing;
    const value = this.summaryForItems(this.itemsFor({ village, category }), category);
    this.summaryCache.set(key, value);
    return value;
  }
  summaryForItems(
    matching: Iterable<UpgradeTrackerItem>,
    category: UpgradeCategoryValue = UpgradeCategory.defenses,
  ) {
    let current = 0,
      target = 0,
      levels = 0,
      seconds = 0,
      completedSeconds = 0,
      totalSeconds = 0,
      timed = 0,
      resource = 0,
      normalizedCompleted = 0,
      normalizedTotal = 0,
      resourceCompleted = 0,
      resourceTotal = 0,
      weightedCompleted = 0,
      weightedTotal = 0,
      comparable = true,
      resourceCategory: UpgradeCategoryValue | null = null;
    const costs: Record<string, number> = {};
    for (const item of matching) {
      const count = item.count;
      current += item.currentLevel * count;
      target += item.targetLevel * count;
      levels += item.levelsRemaining * count;
      seconds += item.totalSeconds * count;
      const done = item.completedUpgradeSeconds * count + this.activeElapsedSeconds(item);
      completedSeconds += done;
      totalSeconds += item.totalUpgradeSeconds * count;
      if (item.progressBasis === UpgradeProgressBasis.time) {
        timed += count;
        const ratio =
          item.totalUpgradeSeconds <= 0
            ? item.isComplete
              ? 1
              : 0
            : clamp(done / item.totalUpgradeSeconds, 0, 1);
        normalizedCompleted += ratio * count;
        normalizedTotal += count;
      } else {
        resource += count;
        const ratio = item.resourceCompletion;
        resourceCompleted += ratio * count;
        resourceTotal += count;
        normalizedCompleted += ratio * count;
        normalizedTotal += count;
        const valid = new Set<UpgradeCategoryValue>([
          UpgradeCategory.walls,
          UpgradeCategory.equipment,
          UpgradeCategory.builders,
        ]).has(item.category);
        if (!valid || (resourceCategory != null && resourceCategory !== item.category))
          comparable = false;
        else {
          resourceCategory ??= item.category;
          weightedCompleted += item.completedResourceWeight * count;
          weightedTotal += item.totalResourceWeight * count;
        }
      }
      for (const [key, value] of Object.entries(item.totalCosts))
        costs[key] = (costs[key] ?? 0) + value * count;
    }
    const basis =
      timed > 0 && resource > 0
        ? UpgradeProgressBasis.mixed
        : resource > 0
          ? UpgradeProgressBasis.resources
          : UpgradeProgressBasis.time;
    const completed =
      basis === UpgradeProgressBasis.time
        ? totalSeconds > 0
          ? completedSeconds
          : normalizedCompleted
        : basis === UpgradeProgressBasis.resources
          ? comparable
            ? weightedCompleted
            : resourceCompleted
          : normalizedCompleted;
    const total =
      basis === UpgradeProgressBasis.time
        ? totalSeconds > 0
          ? totalSeconds
          : normalizedTotal
        : basis === UpgradeProgressBasis.resources
          ? comparable
            ? weightedTotal
            : resourceTotal
          : normalizedTotal;
    return new UpgradeCategorySummary(
      category,
      basis,
      current,
      target,
      levels,
      seconds,
      completedSeconds,
      totalSeconds,
      completed,
      total,
      costs,
    );
  }
  overallSummary(village: UpgradeVillageValue = UpgradeVillage.home) {
    return this.summaryForItems(
      this.itemsFor({ village }).filter((item) => item.category !== UpgradeCategory.builders),
      UpgradeCategory.army,
    );
  }
  adjustStep(
    item: UpgradeTrackerItem,
    step: UpgradeStep,
    startsAt: Date,
    goldPassPercent?: number,
  ) {
    const parsedCost =
        item.queue === UpgradeQueue.builders
          ? this.boosts.builderCostReductionPercent
          : item.queue === UpgradeQueue.none
            ? 0
            : this.boosts.labCostReductionPercent,
      parsedTime =
        item.queue === UpgradeQueue.builders
          ? this.boosts.builderTimeReductionPercent
          : item.queue === UpgradeQueue.none
            ? 0
            : this.boosts.labTimeReductionPercent;
    let timeReduction = goldPassPercent ?? parsedTime;
    const costs = step.costs.map((cost) => {
      let reduction = goldPassPercent ?? parsedCost;
      for (const event of this.events)
        if (event.appliesAt(startsAt, item, cost.resource)) {
          reduction = combineReductions(reduction, event.costReductionPercent);
          timeReduction = combineReductions(timeReduction, event.timeReductionPercent);
        }
      return new UpgradeCost(cost.resource, Math.round((cost.amount * (100 - reduction)) / 100));
    });
    return new UpgradeStep(
      step.targetLevel,
      costs,
      Math.round((step.seconds * (100 - timeReduction)) / 100),
    );
  }
  buildPlan(options: {
    queue: UpgradeQueueValue;
    strategy: UpgradePlanStrategyValue;
    village?: UpgradeVillageValue;
    startsAt?: Date;
    includedItemKeys?: ReadonlySet<string>;
    goldPassPercent?: number;
    preferences?: UpgradePlanPreferences;
  }) {
    const { queue, strategy } = options,
      village = options.village ?? UpgradeVillage.home,
      start = options.startsAt ?? new Date(),
      preferences = options.preferences ?? new UpgradePlanPreferences(),
      base = queue === UpgradeQueue.builders ? clamp(this.buildersFor(village), 1, 7) : 1;
    const active = this.itemsFor({ village, queue })
        .map((item) => ({ item, seconds: this.remainingActiveSeconds(item, start) }))
        .filter((x) => x.seconds > 0)
        .sort((a, b) => b.seconds - a.seconds),
      laneCount = Math.max(base, active.length),
      laneEnds = Array.from({ length: laneCount }, () => new Date(start)),
      reserved = new Array<Date | null>(laneCount).fill(null),
      activeEnds = new Map<UpgradeTrackerItem, Date>();
    for (const work of active) {
      let lane = 0;
      for (let i = 1; i < laneEnds.length; i++) if (laneEnds[i]! < laneEnds[lane]!) lane = i;
      const end = addSeconds(laneEnds[lane]!, work.seconds);
      laneEnds[lane] = end;
      reserved[lane] = end;
      activeEnds.set(
        work.item,
        later(activeEnds.get(work.item) ?? start, addSeconds(start, work.seconds)),
      );
    }
    const chains: UpgradeChain[] = [];
    for (const item of this.itemsFor({ queue, village, remainingOnly: true }).filter(
      (item) => !options.includedItemKeys || options.includedItemKeys.has(item.planKey),
    )) {
      if (!item.steps.length || item.count <= 0) continue;
      const activeEnd = activeEnds.get(item);
      if (activeEnd) {
        if (item.steps.length > 1)
          chains.push(new UpgradeChain(item, 0, item.steps.slice(1), activeEnd));
        for (let i = 1; i < item.count; i++)
          chains.push(new UpgradeChain(item, i, item.steps, start));
      } else
        for (let i = 1; i <= item.count; i++)
          chains.push(new UpgradeChain(item, i, item.steps, start));
    }
    const ordered = orderPlanChains(this, chains, strategy, preferences, village),
      ready: PendingChain[] = [],
      future: PendingChain[] = [];
    let sequence = 0;
    const earliest = () => {
      let value = laneEnds[0]!;
      for (let index = 1; index < base; index += 1) {
        if (laneEnds[index]! < value) value = laneEnds[index]!;
      }
      return value;
    };
    const enqueue = (chain: UpgradeChain) => {
      const pending = { chain, sequence: sequence++ };
      (chain.dependencyReadyAt > earliest() ? future : ready).push(pending);
    };
    ordered.forEach(enqueue);
    const laneItems = Array.from({ length: laneCount }, () => [] as PlannedUpgrade[]);
    while (ready.length || future.length) {
      const laneReady = earliest();
      for (let i = future.length - 1; i >= 0; i--)
        if (future[i]!.chain.dependencyReadyAt <= laneReady) ready.push(future.splice(i, 1)[0]!);
      ready.sort((a, b) => a.sequence - b.sequence);
      future.sort(
        (a, b) =>
          a.chain.dependencyReadyAt.getTime() - b.chain.dependencyReadyAt.getTime() ||
          a.sequence - b.sequence,
      );
      const chain = (ready.shift() ?? future.shift())!.chain,
        lane = laneFor(chain.dependencyReadyAt, laneEnds, base),
        cursor = later(laneEnds[lane]!, chain.dependencyReadyAt),
        adjusted = this.adjustStep(chain.item, chain.nextStep, cursor, options.goldPassPercent),
        end = addSeconds(cursor, adjusted.seconds);
      laneItems[lane]!.push(
        new PlannedUpgrade(chain.item, chain.instance, adjusted, cursor, end, adjusted.costs),
      );
      laneEnds[lane] = end;
      chain.advance(end);
      if (chain.hasNextStep) enqueue(chain);
    }
    return laneItems.map(
      (upgrades, index) => new UpgradePlanLane(index, upgrades, reserved[index]),
    );
  }
}

class UpgradeChain {
  nextStepIndex = 0;
  constructor(
    readonly item: UpgradeTrackerItem,
    readonly instance: number,
    readonly steps: readonly UpgradeStep[],
    public dependencyReadyAt: Date,
  ) {}
  get hasNextStep() {
    return this.nextStepIndex < this.steps.length;
  }
  get nextStep() {
    return this.steps[this.nextStepIndex]!;
  }
  advance(end: Date) {
    this.nextStepIndex++;
    this.dependencyReadyAt = end;
  }
}
interface PendingChain {
  chain: UpgradeChain;
  sequence: number;
}
function compareChains(
  a: UpgradeChain,
  b: UpgradeChain,
  strategy: UpgradePlanStrategyValue,
  prefs: UpgradePlanPreferences,
) {
  const seconds = (c: UpgradeChain) => c.steps.reduce((s, x) => s + x.seconds, 0),
    cost = (c: UpgradeChain) =>
      c.steps.reduce((s, x) => s + x.costs.reduce((n, y) => n + y.amount, 0), 0);
  if (strategy === UpgradePlanStrategy.shortest) return seconds(a) - seconds(b);
  if (strategy === UpgradePlanStrategy.cheapest) return cost(a) - cost(b);
  if (prefs.prioritizeUnbuiltFor(a.item.queue) && a.item.isUnbuilt !== b.item.isUnbuilt)
    return a.item.isUnbuilt ? -1 : 1;
  return seconds(b) - seconds(a);
}
function orderPlanChains(
  snapshot: UpgradeTrackerSnapshot,
  chains: UpgradeChain[],
  strategy: UpgradePlanStrategyValue,
  prefs: UpgradePlanPreferences,
  village: UpgradeVillageValue,
) {
  const pools = new Map<UpgradeCategoryValue, UpgradeChain[]>();
  for (const chain of chains) {
    const pool = pools.get(chain.item.category) ?? [];
    pool.push(chain);
    pools.set(chain.item.category, pool);
  }
  for (const pool of pools.values()) pool.sort((a, b) => compareChains(a, b, strategy, prefs));
  const categories = [...pools.keys()].sort(
      (a, b) =>
        prefs.priorityTierFor(a, village) - prefs.priorityTierFor(b, village) ||
        prefs.categoryRank(a, village) - prefs.categoryRank(b, village),
    ),
    ordered: UpgradeChain[] = [];
  let index = 0;
  const append = (values: UpgradeCategoryValue[]) => {
    if (values.length <= 1 || values.some((v) => prefs.shareFor(v, village) <= 0)) {
      for (const v of values) ordered.push(...pools.get(v)!);
      return;
    }
    const remaining = new Map(values.map((v) => [v, [...pools.get(v)!]])),
      scores = new Map(values.map((v) => [v, 0]));
    while ([...remaining.values()].some((p) => p.length)) {
      const active = values.filter((v) => remaining.get(v)!.length),
        total = active.reduce((s, v) => s + prefs.shareFor(v, village), 0);
      for (const v of active) scores.set(v, (scores.get(v) ?? 0) + prefs.shareFor(v, village));
      active.sort(
        (a, b) =>
          (scores.get(b) ?? 0) - (scores.get(a) ?? 0) ||
          prefs.categoryRank(a, village) - prefs.categoryRank(b, village),
      );
      const selected = active[0]!;
      ordered.push(remaining.get(selected)!.shift()!);
      scores.set(selected, (scores.get(selected) ?? 0) - total);
    }
  };
  while (index < categories.length) {
    const tier = prefs.priorityTierFor(categories[index]!, village),
      values: UpgradeCategoryValue[] = [];
    while (index < categories.length && prefs.priorityTierFor(categories[index]!, village) === tier)
      values.push(categories[index++]!);
    const pending = values.filter(
      (v) => snapshot.summaryFor(v, village).completion * 100 < prefs.targetFor(v, village),
    );
    append(pending);
    append(values.filter((v) => !pending.includes(v)));
  }
  return ordered;
}
function laneFor(ready: Date, ends: Date[], count: number) {
  let selected = 0,
    start = later(ends[0]!, ready);
  for (let i = 1; i < count; i++) {
    const candidate = later(ends[i]!, ready);
    if (
      candidate < start ||
      (candidate.getTime() === start.getTime() && ends[i]! < ends[selected]!)
    ) {
      selected = i;
      start = candidate;
    }
  }
  return selected;
}
function combineReductions(first: number, second: number) {
  return clamp(Math.round(100 - ((100 - first) * (100 - second)) / 100), 0, 95);
}
function later(a: Date, b: Date) {
  return a > b ? a : b;
}
function addSeconds(date: Date, seconds: number) {
  return new Date(date.getTime() + seconds * 1000);
}
function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value));
}
function mapToRecord(map: ReadonlyMap<string, number>) {
  return Object.fromEntries(map);
}
function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
function intValue(value: unknown, fallback: number) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  const text = String(value ?? '').trim();
  return /^[+-]?\d+$/.test(text) ? Number.parseInt(text, 10) : fallback;
}
function categoryOrder(value: unknown) {
  if (!Array.isArray(value)) return [];
  const result: UpgradeCategoryValue[] = [];
  for (const raw of value) {
    const entry = String(raw) as UpgradeCategoryValue;
    if (upgradeCategories.includes(entry) && !result.includes(entry)) result.push(entry);
  }
  return result;
}
function categoryTargets(value: unknown) {
  const result = new Map<UpgradeCategoryValue, number>();
  if (!isRecord(value)) return result;
  for (const [key, raw] of Object.entries(value)) {
    const category = key as UpgradeCategoryValue;
    if (upgradeCategories.includes(category))
      result.set(category, clamp(intValue(raw, 100), 1, 100));
  }
  return result;
}
function boolValue(value: unknown, fallback: boolean) {
  if (typeof value === 'boolean') return value;
  const text = String(value ?? '')
    .trim()
    .toLowerCase();
  if (text === 'true' || text === '1') return true;
  if (text === 'false' || text === '0') return false;
  return fallback;
}
function goalValue(value: unknown): UpgradePlanGoalValue {
  const text = String(value ?? '') as UpgradePlanGoalValue;
  return Object.values(UpgradePlanGoal).includes(text) ? text : UpgradePlanGoal.maxCurrentHall;
}
