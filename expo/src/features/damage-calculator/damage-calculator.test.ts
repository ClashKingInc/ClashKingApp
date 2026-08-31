import { DamageCatalog } from './data/damage-catalog';
import {
  BuildingDefinition,
  BuildingLevelDefinition,
  DamageCalculatorEngine,
  DamageLevel,
  DamageSourceDefinition,
  DamageSourceKind,
  DamageTarget,
} from './domain/damage-calculator-engine';
import { DamageCalculatorSession } from './domain/damage-calculator-session';

const engine = new DamageCalculatorEngine();
const lightningLevel = new DamageLevel({ level: 7, requiredTownHall: 10, damage: 400 });
const earthquakeLevel = new DamageLevel({
  level: 5,
  requiredTownHall: 11,
  earthquakePercent: 29,
});
const lightning = new DamageSourceDefinition({
  kind: DamageSourceKind.Lightning,
  name: 'Lightning Spell',
  imageUrl: '',
  housingSpace: 1,
  levels: [lightningLevel],
});

describe('DamageCalculatorEngine', () => {
  it('adds fixed damage and ignores zero or negative counts', () => {
    expect(
      engine.evaluate(target(2000), [{ source: lightning, level: lightningLevel, count: 3 }]),
    ).toMatchObject({ totalDamage: 1200, remainingHitpoints: 800 });
    for (const count of [0, -1]) {
      expect(
        engine.evaluate(target(1000), [{ source: lightning, level: lightningLevel, count }]),
      ).toMatchObject({ totalDamage: 0, remainingHitpoints: 1000 });
    }
  });

  it('uses the odd-denominator earthquake sequence with its boundaries', () => {
    expect(engine.earthquakeDamage({ hitpoints: 1000, basePercent: 29, count: 4 })).toBeCloseTo(
      486.095,
      3,
    );
    expect(engine.earthquakeDamage({ hitpoints: 1000, basePercent: 0, count: 4 })).toBe(0);
    expect(engine.earthquakeDamage({ hitpoints: 0, basePercent: 29, count: 4 })).toBe(0);
    expect(engine.earthquakeDamage({ hitpoints: 100, basePercent: 100, count: 2 })).toBe(100);
  });

  it('returns only destructive zap-quake combinations within capacity', () => {
    const combinations = engine.validZapQuakeCombinations({
      target: target(1000),
      lightning: lightningLevel,
      earthquake: earthquakeLevel,
      capacity: 3,
    });
    expect(
      combinations.map(({ lightningCount, earthquakeCount, capacityUsed }) => [
        lightningCount,
        earthquakeCount,
        capacityUsed,
      ]),
    ).toEqual([
      [3, 0, 3],
      [2, 1, 3],
    ]);
    expect(combinations.every((combination) => combination.damage >= 1000)).toBe(true);
    expect(
      engine.validZapQuakeCombinations({
        target: target(1000, false),
        lightning: lightningLevel,
        earthquake: earthquakeLevel,
        capacity: 20,
      }),
    ).toEqual([]);
  });

  it('evaluates buildings independently and excludes spells from storage targets', () => {
    const results = engine.evaluateAll(
      [target(1000), target(2000)],
      [{ source: lightning, level: lightningLevel, count: 3 }],
    );
    expect(results[0]).toMatchObject({ destroyed: true, remainingHitpoints: 0 });
    expect(results[1]).toMatchObject({ destroyed: false, remainingHitpoints: 800 });
    expect(
      engine.evaluate(target(1000, false), [
        { source: lightning, level: lightningLevel, count: 3 },
      ]),
    ).toMatchObject({ totalDamage: 0, remainingHitpoints: 1000 });
  });
});

describe('DamageCatalog', () => {
  it('parses attack speed, unlock constraints, costs, and conditional sources', () => {
    const catalog = DamageCatalog.fromBundle(bundle);
    expect(catalog.maxTownHall).toBe(12);
    expect(catalog.buildingsForTownHall(9).map((item) => item.name)).toEqual(['Town Hall']);
    expect(catalog.buildingsForTownHall(12).map((item) => item.name)).toEqual([
      'Town Hall',
      'X-Bow',
    ]);
    expect(catalog.buildings[0]!.levelsForTownHall(9)[0]!.level).toBe(9);
    expect(catalog.buildings[0]!.level(10)).toMatchObject({
      upgradeResource: 'Gold',
      upgradeCost: 250000,
    });
    expect(catalog.source(DamageSourceKind.Lightning)!.levelsForTownHall(9)[0]!.level).toBe(1);
    expect(catalog.source(DamageSourceKind.Fireball)!.levels[0]!.damage).toBe(1500);
    expect(catalog.source(DamageSourceKind.Earthquake)!.levelsForTownHall(7)).toEqual([]);
    expect(catalog.source(DamageSourceKind.Earthquake)!.levelsForTownHall(8)[0]!.level).toBe(1);
    expect(catalog.source(DamageSourceKind.FlameFlinger)!.levels[0]!.damage).toBe(635);
    expect(catalog.source(DamageSourceKind.BalloonDeath)).toBeUndefined();
    expect(catalog.source(DamageSourceKind.RocketBalloonDeath)).toBeUndefined();
  });

  it('removes the Eagle after its Town Hall merge', () => {
    const catalog = mergedBuildingCatalog();
    expect(catalog.buildingsForTownHall(16).map((item) => item.name)).toEqual(['Eagle Artillery']);
    expect(catalog.buildingsForTownHall(17)).toEqual([]);
  });
});

describe('DamageCalculatorSession', () => {
  it('uses max valid levels and repairs state after a Town Hall change', () => {
    const session = new DamageCalculatorSession(sessionCatalog, { townHall: 12 });
    expect(session.addTarget('town-hall')).toBe(true);
    expect(session.targets[0]!.level).toBe(2);
    expect(session.sources.get(DamageSourceKind.Lightning)!.level).toBe(3);
    session.setTownHall(9);
    expect(session.targets[0]!.level).toBe(1);
    expect(session.sources.get(DamageSourceKind.Lightning)!.level).toBe(1);
  });

  it('applies account presets and clamps unsupported levels', () => {
    const session = new DamageCalculatorSession(sessionCatalog, { townHall: 12 });
    session.applyPreset({
      tag: '#ABC',
      name: 'Chief',
      townHall: 9,
      ownedLevels: new Map([[DamageSourceKind.Lightning, 99]]),
    });
    expect(session.selectedAccountTag).toBe('#ABC');
    expect(session.townHall).toBe(9);
    expect(session.sources.get(DamageSourceKind.Lightning)!.level).toBe(1);
  });

  it('rejects duplicate/invalid targets and removes a merged building', () => {
    const session = new DamageCalculatorSession(sessionCatalog, { townHall: 9 });
    expect(session.addTarget('town-hall')).toBe(true);
    expect(session.addTarget('town-hall')).toBe(false);
    expect(session.addTarget('locked')).toBe(false);

    const merged = new DamageCalculatorSession(mergedBuildingCatalog(), { townHall: 16 });
    expect(merged.addTarget('eagle')).toBe(true);
    merged.setTownHall(17);
    expect(merged.targets).toEqual([]);
    expect(merged.resolvedTargets()).toEqual([]);
  });
});

function target(hitpoints: number, eligible = true): DamageTarget {
  const level = new BuildingLevelDefinition({ level: 1, hitpoints, requiredTownHall: 1 });
  return new DamageTarget({
    building: new BuildingDefinition({
      id: `building-${hitpoints}-${eligible}`,
      name: 'Building',
      imageName: 'Building',
      levels: [level],
      zapQuakeEligible: eligible,
    }),
    level,
  });
}

function mergedBuildingCatalog(): DamageCatalog {
  return new DamageCatalog({
    maxTownHall: 18,
    buildings: [
      new BuildingDefinition({
        id: 'eagle',
        name: 'Eagle Artillery',
        imageName: 'Eagle Artillery',
        zapQuakeEligible: true,
        levels: [new BuildingLevelDefinition({ level: 7, hitpoints: 6200, requiredTownHall: 16 })],
      }),
    ],
    sources: [],
  });
}

const sessionCatalog = new DamageCatalog({
  maxTownHall: 12,
  buildings: [
    new BuildingDefinition({
      id: 'town-hall',
      name: 'Town Hall',
      imageName: 'Town Hall',
      zapQuakeEligible: true,
      levels: [
        new BuildingLevelDefinition({ level: 1, hitpoints: 1000, requiredTownHall: 9 }),
        new BuildingLevelDefinition({ level: 2, hitpoints: 2000, requiredTownHall: 12 }),
      ],
    }),
    new BuildingDefinition({
      id: 'locked',
      name: 'Locked',
      imageName: 'Locked',
      zapQuakeEligible: true,
      levels: [new BuildingLevelDefinition({ level: 1, hitpoints: 2000, requiredTownHall: 12 })],
    }),
  ],
  sources: [
    new DamageSourceDefinition({
      kind: DamageSourceKind.Lightning,
      name: 'Lightning Spell',
      imageUrl: '',
      levels: [
        new DamageLevel({ level: 1, requiredTownHall: 3, damage: 150 }),
        new DamageLevel({ level: 2, requiredTownHall: 10, damage: 180 }),
        new DamageLevel({ level: 3, requiredTownHall: 12, damage: 210 }),
      ],
    }),
  ],
});

const bundle = {
  buildings: [
    {
      _id: 1,
      name: 'Town Hall',
      village: 'home',
      upgrade_resource: 'Gold',
      levels: [
        { level: 9, hitpoints: 4600, required_townhall: 9 },
        { level: 10, hitpoints: 5500, required_townhall: 10, build_cost: 250000 },
        { level: 12, hitpoints: 7000, required_townhall: 11 },
      ],
    },
    {
      _id: 2,
      name: 'X-Bow',
      village: 'home',
      levels: [{ level: 5, hitpoints: 1500, required_townhall: 12 }],
    },
    {
      _id: 3,
      name: 'Dark Spell Factory',
      village: 'home',
      levels: [{ level: 2, required_townhall: 8 }],
    },
  ],
  spells: [
    {
      name: 'Lightning Spell',
      housing_space: 1,
      levels: [
        { level: 1, damage: 150, required_townhall: 3 },
        { level: 2, damage: 180, required_townhall: 10 },
      ],
    },
    {
      name: 'Earthquake Spell',
      housing_space: 1,
      production_building: 'Dark Spell Factory',
      production_building_level: 2,
      levels: [
        { level: 1, damage: 0, required_townhall: 8 },
        { level: 2, damage: 0, required_townhall: 10 },
      ],
    },
  ],
  equipment: [
    {
      name: 'Fireball',
      levels: [{ level: 1, required_townhall: 8, abilities: [{ Damage: 1500 }] }],
    },
  ],
  troops: [
    {
      name: 'Flame Flinger',
      attack_speed: 5000,
      levels: [{ level: 1, dps: 127, required_townhall: 11 }],
    },
    {
      name: 'Balloon',
      levels: [{ level: 1, dps: 25, required_townhall: 3 }],
    },
  ],
};
