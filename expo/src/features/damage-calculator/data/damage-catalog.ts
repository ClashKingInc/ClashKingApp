import {
  BuildingDefinition,
  BuildingLevelDefinition,
  DamageLevel,
  DamageSourceDefinition,
  DamageSourceKind,
} from '../domain/damage-calculator-engine';
import { ImageAssets } from '../../../core/assets/image-assets';

const unavailableFromTownHall: Readonly<Record<string, number>> = {
  'Eagle Artillery': 17,
};

export class DamageCatalog {
  readonly maxTownHall: number;
  readonly buildings: readonly BuildingDefinition[];
  readonly sources: readonly DamageSourceDefinition[];

  constructor({
    maxTownHall,
    buildings,
    sources,
  }: {
    maxTownHall: number;
    buildings: readonly BuildingDefinition[];
    sources: readonly DamageSourceDefinition[];
  }) {
    this.maxTownHall = maxTownHall;
    this.buildings = buildings;
    this.sources = sources;
  }

  static fromBundle(bundle: Readonly<Record<string, unknown>>): DamageCatalog {
    const buildings = parseBuildings(bundle.buildings);
    const sources = [
      ...spellSource(
        bundle.spells,
        bundle.buildings,
        'Lightning Spell',
        DamageSourceKind.Lightning,
      ),
      ...earthquakeSource(bundle.spells, bundle.buildings),
      ...equipmentSource(bundle.equipment, 'Giant Arrow', DamageSourceKind.GiantArrow),
      ...equipmentSource(bundle.equipment, 'Fireball', DamageSourceKind.Fireball),
      ...flameFlingerSource(bundle.troops),
      ...troopDeathSource(bundle.troops, 'Balloon', DamageSourceKind.BalloonDeath),
      ...troopDeathSource(bundle.troops, 'Rocket Balloon', DamageSourceKind.RocketBalloonDeath),
    ];
    const maxTownHall = buildings
      .flatMap((building) => building.levels)
      .reduce((maximum, level) => Math.max(maximum, level.requiredTownHall), 1);
    return new DamageCatalog({ maxTownHall, buildings, sources });
  }

  source(kind: DamageSourceKind): DamageSourceDefinition | undefined {
    return this.sources.find((source) => source.kind === kind);
  }

  isBuildingAvailableForTownHall(building: BuildingDefinition, townHall: number): boolean {
    const unavailableFrom = unavailableFromTownHall[building.name];
    return (
      building.levelsForTownHall(townHall).length > 0 &&
      (unavailableFrom === undefined || townHall < unavailableFrom)
    );
  }

  buildingsForTownHall(townHall: number): readonly BuildingDefinition[] {
    return this.buildings.filter((building) =>
      this.isBuildingAvailableForTownHall(building, townHall),
    );
  }
}

function parseBuildings(rawBuildings: unknown): readonly BuildingDefinition[] {
  if (!Array.isArray(rawBuildings)) return [];
  const buildings: BuildingDefinition[] = [];
  for (const rawValue of rawBuildings) {
    const raw = asRecord(rawValue);
    if (!raw || raw.village !== 'home') continue;
    const name = optionalString(raw.name)?.trim() ?? '';
    if (!name) continue;
    const levels = parseLevels(raw.levels, (level) => {
      const levelNumber = intValue(level.level);
      const hitpoints = intValue(level.hitpoints);
      if (hitpoints <= 0) return undefined;
      return new BuildingLevelDefinition({
        level: levelNumber,
        hitpoints,
        requiredTownHall: name === 'Town Hall' ? levelNumber : intValue(level.required_townhall, 1),
        upgradeResource: optionalString(raw.upgrade_resource),
        upgradeCost: optionalIntValue(level.build_cost),
      });
    });
    if (levels.length === 0) continue;
    buildings.push(
      new BuildingDefinition({
        id: raw._id === undefined || raw._id === null ? name : String(raw._id),
        name,
        imageName: name,
        levels,
        zapQuakeEligible: !name.toLowerCase().includes('storage'),
      }),
    );
  }
  return buildings.sort((left, right) => {
    if (left.name === 'Town Hall') return -1;
    if (right.name === 'Town Hall') return 1;
    return left.name.localeCompare(right.name);
  });
}

function spellSource(
  rawSources: unknown,
  rawBuildings: unknown,
  name: string,
  kind: DamageSourceKind,
): readonly DamageSourceDefinition[] {
  const source = findNamed(rawSources, name);
  if (!source) return [];
  const levels = parseLevels(source.levels, (raw) => {
    const damage = doubleValue(raw.damage);
    if (damage <= 0) return undefined;
    return new DamageLevel({
      level: intValue(raw.level),
      requiredTownHall: sourceRequiredTownHall(raw, source, rawBuildings),
      damage,
    });
  });
  return levels.length === 0
    ? []
    : [
        new DamageSourceDefinition({
          kind,
          name,
          imageUrl: ImageAssets.getSpellImage(name),
          levels,
          housingSpace: intValue(source.housing_space, 1),
        }),
      ];
}

function earthquakeSource(
  rawSources: unknown,
  rawBuildings: unknown,
): readonly DamageSourceDefinition[] {
  const source = findNamed(rawSources, 'Earthquake Spell');
  if (!source) return [];
  const buildingPercent: Readonly<Record<number, number>> = {
    1: 14.5,
    2: 17,
    3: 21,
    4: 25,
    5: 29,
    6: 29,
    7: 29,
    8: 29,
  };
  const levels = parseLevels(source.levels, (raw) => {
    const level = intValue(raw.level);
    const earthquakePercent = buildingPercent[level];
    if (earthquakePercent === undefined) return undefined;
    return new DamageLevel({
      level,
      requiredTownHall: sourceRequiredTownHall(raw, source, rawBuildings),
      earthquakePercent,
    });
  });
  return levels.length === 0
    ? []
    : [
        new DamageSourceDefinition({
          kind: DamageSourceKind.Earthquake,
          name: 'Earthquake Spell',
          imageUrl: ImageAssets.getSpellImage('Earthquake Spell'),
          levels,
          housingSpace: intValue(source.housing_space, 1),
        }),
      ];
}

function equipmentSource(
  rawSources: unknown,
  name: string,
  kind: DamageSourceKind,
): readonly DamageSourceDefinition[] {
  const source = findNamed(rawSources, name);
  if (!source) return [];
  const levels = parseLevels(source.levels, (raw) => {
    if (!Array.isArray(raw.abilities)) return undefined;
    const ability = asRecord(raw.abilities[0]);
    if (!ability) return undefined;
    const damage = doubleValue(ability.Damage ?? ability.damage);
    if (damage <= 0) return undefined;
    return new DamageLevel({
      level: intValue(raw.level),
      requiredTownHall: intValue(raw.required_townhall, 1),
      damage,
    });
  });
  return levels.length === 0
    ? []
    : [
        new DamageSourceDefinition({
          kind,
          name,
          imageUrl: ImageAssets.getGearImage(name),
          levels,
        }),
      ];
}

function flameFlingerSource(rawSources: unknown): readonly DamageSourceDefinition[] {
  const source = findNamed(rawSources, 'Flame Flinger');
  if (!source) return [];
  const attackSpeedMilliseconds = doubleValue(source.attack_speed);
  if (attackSpeedMilliseconds <= 0) return [];
  const attackSpeedSeconds = attackSpeedMilliseconds / 1000;
  const levels = parseLevels(source.levels, (raw) => {
    const dps = doubleValue(raw.dps);
    if (dps <= 0) return undefined;
    return new DamageLevel({
      level: intValue(raw.level),
      requiredTownHall: intValue(raw.required_townhall, 1),
      damage: dps * attackSpeedSeconds,
    });
  });
  return levels.length === 0
    ? []
    : [
        new DamageSourceDefinition({
          kind: DamageSourceKind.FlameFlinger,
          name: 'Flame Flinger hit',
          imageUrl: ImageAssets.getSiegeMachineImage('Flame Flinger'),
          levels,
        }),
      ];
}

function troopDeathSource(
  rawSources: unknown,
  name: string,
  kind: DamageSourceKind,
): readonly DamageSourceDefinition[] {
  const source = findNamed(rawSources, name);
  if (!source) return [];
  const levels = parseLevels(source.levels, (raw) => {
    const damage = doubleValue(raw.death_damage ?? raw.deathDamage ?? raw.death_damage_on_death);
    if (damage <= 0) return undefined;
    return new DamageLevel({
      level: intValue(raw.level),
      requiredTownHall: intValue(raw.required_townhall, 1),
      damage,
    });
  });
  return levels.length === 0
    ? []
    : [
        new DamageSourceDefinition({
          kind,
          name: `${name} death damage`,
          imageUrl: ImageAssets.getTroopImage(name),
          levels,
        }),
      ];
}

function sourceRequiredTownHall(
  rawLevel: Readonly<Record<string, unknown>>,
  source: Readonly<Record<string, unknown>>,
  rawBuildings: unknown,
): number {
  const levelRequirement = intValue(rawLevel.required_townhall, 1);
  const productionBuilding = optionalString(source.production_building);
  const productionLevel = intValue(source.production_building_level);
  if (!Array.isArray(rawBuildings) || !productionBuilding || productionLevel <= 0) {
    return levelRequirement;
  }
  const building = findNamed(rawBuildings, productionBuilding);
  if (!building || !Array.isArray(building.levels)) return levelRequirement;
  for (const rawValue of building.levels) {
    const raw = asRecord(rawValue);
    if (raw && intValue(raw.level) === productionLevel) {
      return Math.max(levelRequirement, intValue(raw.required_townhall, 1));
    }
  }
  return levelRequirement;
}

function parseLevels<T>(
  rawLevels: unknown,
  parse: (raw: Readonly<Record<string, unknown>>) => T | undefined,
): readonly T[] {
  if (!Array.isArray(rawLevels)) return [];
  const levels: T[] = [];
  for (const rawValue of rawLevels) {
    const raw = asRecord(rawValue);
    if (!raw) continue;
    const value = parse(raw);
    if (value !== undefined) levels.push(value);
  }
  return levels;
}

function findNamed(
  rawSources: unknown,
  name: string,
): Readonly<Record<string, unknown>> | undefined {
  if (!Array.isArray(rawSources)) return undefined;
  for (const rawValue of rawSources) {
    const raw = asRecord(rawValue);
    if (raw?.name === name) return raw;
  }
  return undefined;
}

function asRecord(value: unknown): Readonly<Record<string, unknown>> | undefined {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Readonly<Record<string, unknown>>)
    : undefined;
}

function optionalString(value: unknown): string | undefined {
  return value === undefined || value === null ? undefined : String(value);
}

function intValue(value: unknown, fallback = 0): number {
  if (typeof value === 'number') return Math.round(value);
  if (typeof value === 'string') {
    const parsed = Number.parseInt(value, 10);
    return Number.isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}

function optionalIntValue(value: unknown): number | undefined {
  if (typeof value === 'number') return Math.round(value);
  if (typeof value === 'string') {
    const parsed = Number.parseInt(value, 10);
    return Number.isNaN(parsed) ? undefined : parsed;
  }
  return undefined;
}

function doubleValue(value: unknown): number {
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const parsed = Number.parseFloat(value);
    return Number.isNaN(parsed) ? 0 : parsed;
  }
  return 0;
}
