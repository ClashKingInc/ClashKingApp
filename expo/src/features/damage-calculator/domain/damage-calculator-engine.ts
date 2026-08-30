export enum DamageSourceKind {
  Lightning = 'lightning',
  Earthquake = 'earthquake',
  GiantArrow = 'giantArrow',
  Fireball = 'fireball',
  FlameFlinger = 'flameFlinger',
  BalloonDeath = 'balloonDeath',
  RocketBalloonDeath = 'rocketBalloonDeath',
}

export class DamageLevel {
  readonly level: number;
  readonly requiredTownHall: number;
  readonly damage?: number;
  readonly earthquakePercent?: number;

  constructor({
    level,
    requiredTownHall,
    damage,
    earthquakePercent,
  }: {
    level: number;
    requiredTownHall: number;
    damage?: number;
    earthquakePercent?: number;
  }) {
    this.level = level;
    this.requiredTownHall = requiredTownHall;
    this.damage = damage;
    this.earthquakePercent = earthquakePercent;
  }
}

export class DamageSourceDefinition {
  readonly kind: DamageSourceKind;
  readonly name: string;
  readonly imageUrl: string;
  readonly levels: readonly DamageLevel[];
  readonly housingSpace: number;

  constructor({
    kind,
    name,
    imageUrl,
    levels,
    housingSpace = 0,
  }: {
    kind: DamageSourceKind;
    name: string;
    imageUrl: string;
    levels: readonly DamageLevel[];
    housingSpace?: number;
  }) {
    this.kind = kind;
    this.name = name;
    this.imageUrl = imageUrl;
    this.levels = levels;
    this.housingSpace = housingSpace;
  }

  levelsForTownHall(townHall: number): readonly DamageLevel[] {
    return this.levels.filter((level) => level.requiredTownHall <= townHall);
  }

  level(value: number): DamageLevel | undefined {
    return this.levels.find((candidate) => candidate.level === value);
  }
}

export class BuildingLevelDefinition {
  readonly level: number;
  readonly hitpoints: number;
  readonly requiredTownHall: number;
  readonly upgradeResource?: string;
  readonly upgradeCost?: number;

  constructor({
    level,
    hitpoints,
    requiredTownHall,
    upgradeResource,
    upgradeCost,
  }: {
    level: number;
    hitpoints: number;
    requiredTownHall: number;
    upgradeResource?: string;
    upgradeCost?: number;
  }) {
    this.level = level;
    this.hitpoints = hitpoints;
    this.requiredTownHall = requiredTownHall;
    this.upgradeResource = upgradeResource;
    this.upgradeCost = upgradeCost;
  }
}

export class BuildingDefinition {
  readonly id: string;
  readonly name: string;
  readonly imageName: string;
  readonly levels: readonly BuildingLevelDefinition[];
  readonly zapQuakeEligible: boolean;

  constructor({
    id,
    name,
    imageName,
    levels,
    zapQuakeEligible,
  }: {
    id: string;
    name: string;
    imageName: string;
    levels: readonly BuildingLevelDefinition[];
    zapQuakeEligible: boolean;
  }) {
    this.id = id;
    this.name = name;
    this.imageName = imageName;
    this.levels = levels;
    this.zapQuakeEligible = zapQuakeEligible;
  }

  levelsForTownHall(townHall: number): readonly BuildingLevelDefinition[] {
    return this.levels.filter((level) => level.requiredTownHall <= townHall);
  }

  level(value: number): BuildingLevelDefinition | undefined {
    return this.levels.find((candidate) => candidate.level === value);
  }
}

export class DamageTarget {
  readonly building: BuildingDefinition;
  readonly level: BuildingLevelDefinition;

  constructor({
    building,
    level,
  }: {
    building: BuildingDefinition;
    level: BuildingLevelDefinition;
  }) {
    this.building = building;
    this.level = level;
  }

  get id(): string {
    return this.building.id;
  }

  get hitpoints(): number {
    return this.level.hitpoints;
  }
}

export interface DamageStackEntry {
  readonly source: DamageSourceDefinition;
  readonly level: DamageLevel;
  readonly count: number;
}

export class DamageResult {
  readonly target: DamageTarget;
  readonly totalDamage: number;
  readonly remainingHitpoints: number;

  constructor({
    target,
    totalDamage,
    remainingHitpoints,
  }: {
    target: DamageTarget;
    totalDamage: number;
    remainingHitpoints: number;
  }) {
    this.target = target;
    this.totalDamage = totalDamage;
    this.remainingHitpoints = remainingHitpoints;
  }

  get destroyed(): boolean {
    return this.remainingHitpoints <= 0;
  }

  get percentDestroyed(): number {
    return this.target.hitpoints <= 0
      ? 0
      : Math.min(100, (this.totalDamage / this.target.hitpoints) * 100);
  }
}

export interface ZapQuakeCombination {
  readonly lightningCount: number;
  readonly earthquakeCount: number;
  readonly capacityUsed: number;
  readonly damage: number;
}

export class DamageCalculatorEngine {
  earthquakeDamage({
    hitpoints,
    basePercent,
    count,
  }: {
    hitpoints: number;
    basePercent: number;
    count: number;
  }): number {
    if (hitpoints <= 0 || basePercent <= 0 || count <= 0) return 0;
    let total = 0;
    for (let index = 0; index < count; index += 1) {
      total += (hitpoints * (basePercent / 100)) / (index * 2 + 1);
    }
    return Math.min(hitpoints, total);
  }

  evaluate(target: DamageTarget, stack: Iterable<DamageStackEntry>): DamageResult {
    let total = 0;
    for (const entry of stack) {
      if (entry.count <= 0) continue;
      if (
        !target.building.zapQuakeEligible &&
        (entry.source.kind === DamageSourceKind.Lightning ||
          entry.source.kind === DamageSourceKind.Earthquake)
      ) {
        continue;
      }
      if (entry.source.kind === DamageSourceKind.Earthquake) {
        total += this.earthquakeDamage({
          hitpoints: target.hitpoints,
          basePercent: entry.level.earthquakePercent ?? 0,
          count: entry.count,
        });
      } else {
        total += (entry.level.damage ?? 0) * entry.count;
      }
    }
    return new DamageResult({
      target,
      totalDamage: Math.min(target.hitpoints, total),
      remainingHitpoints: Math.max(0, target.hitpoints - total),
    });
  }

  evaluateAll(
    targets: Iterable<DamageTarget>,
    stack: Iterable<DamageStackEntry>,
  ): readonly DamageResult[] {
    const entries = [...stack];
    return [...targets].map((target) => this.evaluate(target, entries));
  }

  validZapQuakeCombinations({
    target,
    lightning,
    earthquake,
    capacity,
  }: {
    target: DamageTarget;
    lightning: DamageLevel;
    earthquake: DamageLevel;
    capacity: number;
  }): readonly ZapQuakeCombination[] {
    if (
      !target.building.zapQuakeEligible ||
      capacity <= 0 ||
      (lightning.damage ?? 0) <= 0 ||
      (earthquake.earthquakePercent ?? 0) <= 0
    ) {
      return [];
    }

    const combinations: ZapQuakeCombination[] = [];
    for (let earthquakes = 0; earthquakes < capacity; earthquakes += 1) {
      for (let lightningCount = 1; lightningCount + earthquakes <= capacity; lightningCount += 1) {
        const damage =
          this.earthquakeDamage({
            hitpoints: target.hitpoints,
            basePercent: earthquake.earthquakePercent!,
            count: earthquakes,
          }) +
          lightning.damage! * lightningCount;
        if (damage + 0.000001 < target.hitpoints) continue;
        combinations.push({
          lightningCount,
          earthquakeCount: earthquakes,
          capacityUsed: lightningCount + earthquakes,
          damage,
        });
        break;
      }
    }

    return combinations.sort((left, right) => {
      const capacityOrder = left.capacityUsed - right.capacityUsed;
      return capacityOrder !== 0 ? capacityOrder : left.earthquakeCount - right.earthquakeCount;
    });
  }
}
