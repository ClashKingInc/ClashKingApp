import { gameDataState } from '../../core/game-data/game-data-state';
import { Player } from '../player/models/player';
import {
  BuildingDefinition,
  BuildingLevelDefinition,
  DamageCalculatorSession,
  DamageCatalog,
  DamageLevel,
  DamageSourceDefinition,
  DamageSourceKind,
} from '../damage-calculator';
import type {
  UpgradeCost,
  UpgradeStep,
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
} from '../upgrade-tracker/models/upgrade-tracker-models';
import {
  applyQuickSetup,
  farmAttackScenarios,
  farmLeagueLootEstimate,
  farmSelectableBuildings,
  farmTargetLevels,
  farmTrackerTargets,
  farmUnpaidTargetLevels,
  trackerCostForSelection,
  verifiedDamageAccountPresets,
} from './calculator-logic';

const level = (value: number, resource = 'Gold') =>
  new BuildingLevelDefinition({
    level: value,
    hitpoints: value * 100,
    requiredTownHall: value,
    upgradeResource: resource,
  });
const building = (name: string, levels: number[]) =>
  new BuildingDefinition({
    id: name.toLowerCase().replaceAll(' ', '-'),
    name,
    imageName: name,
    zapQuakeEligible: true,
    levels: levels.map((value) => level(value)),
  });
const item = (
  name: string,
  currentLevel: number,
  steps: readonly UpgradeStep[],
  extras: Partial<UpgradeTrackerItem> = {},
) => ({ name, currentLevel, steps, count: 1, isComplete: false, ...extras }) as UpgradeTrackerItem;
const cost = (resource: string, amount: number): UpgradeCost => ({ resource, amount });
const step = (targetLevel: number, costs: readonly UpgradeCost[] = []): UpgradeStep => ({
  targetLevel,
  costs,
  seconds: 100,
});

describe('calculator edge contracts', () => {
  it('clears unsupported quick setups and rejects unusable farming inputs', () => {
    const lightning = new DamageSourceDefinition({
      kind: DamageSourceKind.Lightning,
      name: 'Lightning Spell',
      imageUrl: '',
      levels: [new DamageLevel({ level: 1, requiredTownHall: 1, damage: 100 })],
    });
    const session = new DamageCalculatorSession(
      new DamageCatalog({ maxTownHall: 1, buildings: [], sources: [lightning] }),
      { townHall: 1 },
    );
    session.setSourceCount(DamageSourceKind.Lightning, 4);
    applyQuickSetup(session, 'unknown');
    expect(session.sources.get(DamageSourceKind.Lightning)?.count).toBe(0);
    expect(farmAttackScenarios()).toEqual([]);
    expect(farmAttackScenarios(-1, 10)).toEqual([]);
    expect(farmAttackScenarios(10, 0)).toEqual([]);
  });

  it('builds verified account presets case-insensitively and keeps owned positive levels', () => {
    const player = Player.empty();
    player.tag = '#abc';
    player.name = 'One';
    player.townHallLevel = 17;
    player.league = 'Legend League';
    player.spells = [
      { name: 'Lightning Spell', level: 12 },
      { name: 'Earthquake Spell', level: 0 },
    ] as never;
    player.equipments = [{ name: 'Giant Arrow', level: 18 }] as never;
    player.siegeMachines = [{ name: 'Flame Flinger', level: 4 }] as never;
    player.troops = [{ name: 'Balloon', level: 11 }] as never;
    player.superTroops = [{ name: 'Rocket Balloon', level: 10 }] as never;

    const result = verifiedDamageAccountPresets([' ABC ', '#MISSING'], [player]);
    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({ tag: ' ABC ', name: 'One', townHall: 17 });
    expect([...result[0]!.ownedLevels!.entries()]).toEqual([
      [DamageSourceKind.Lightning, 12],
      [DamageSourceKind.GiantArrow, 18],
      [DamageSourceKind.FlameFlinger, 4],
      [DamageSourceKind.BalloonDeath, 11],
      [DamageSourceKind.RocketBalloonDeath, 10],
    ]);
  });

  it('selects and sanitizes league rewards while returning null for unavailable data', () => {
    gameDataState.playerLeagueData.leagues = {
      Crystal: {
        rewards: [
          { townhall_level: Number.NaN, resources: { gold: 99 } },
          { townhall_level: 10, resources: { gold: -2 }, star_bonus: { gold: 5.6 } },
        ],
      },
    };
    expect(farmLeagueLootEstimate(undefined, 10, 'Gold')).toBeNull();
    expect(farmLeagueLootEstimate('Missing', 10, 'Gold')).toBeNull();
    expect(farmLeagueLootEstimate('Crystal', 9, 'Gold')).toBeNull();
    expect(farmLeagueLootEstimate('Crystal', 10, 'Gold')).toEqual({
      loot: undefined,
      starBonus: 6,
    });
  });

  it('resolves tracker costs by level and normalized resource, with planned costs taking priority', () => {
    const cannon = new BuildingDefinition({
      id: 'cannon',
      name: 'Cannon',
      imageName: 'Cannon',
      zapQuakeEligible: true,
      levels: [level(2, 'Gold')],
    });
    const selectedStep = step(2, [cost('Elixir', 20), cost('Gold', 10)]);
    const target = { item: item(' cannon ', 1, [selectedStep]) };
    expect(trackerCostForSelection(target, cannon, cannon.levels[0])).toEqual(cost('Gold', 10));

    const planned = { ...target, plannedStep: selectedStep, plannedCosts: [cost('Gold', 7)] };
    expect(trackerCostForSelection(planned, cannon, cannon.levels[0])).toEqual(cost('Gold', 7));
    expect(
      trackerCostForSelection(target, building('Archer Tower', [2]), cannon.levels[0]),
    ).toBeUndefined();
    expect(trackerCostForSelection(undefined, cannon, cannon.levels[0])).toBeUndefined();
    expect(
      trackerCostForSelection({ item: item('Cannon', 1, []) }, cannon, cannon.levels[0]),
    ).toBeUndefined();
  });

  it('derives planned and idle tracker targets once, skipping active and unsupported upgrades', () => {
    const cannon = building('Cannon', [2, 3]);
    const archer = building('Archer Tower', [2]);
    const cannonStep = step(2, [cost('Gold', 100)]);
    const plannedCannon = item('Cannon', 1, [cannonStep]);
    const idleArcher = item('Archer Tower', 1, [step(2)]);
    const activeDuplicate = item('Cannon', 1, [step(3)]);
    const unsupported = item('Mortar', 1, [step(2)]);
    const snapshot = {
      buildPlan: () => [
        {
          upgrades: [
            {
              item: plannedCannon,
              step: cannonStep,
              costs: [cost('Gold', 80)],
              startsAt: new Date('2026-08-01T00:00:00Z'),
            },
          ],
        },
      ],
      itemsFor: () => [plannedCannon, idleArcher, activeDuplicate, unsupported],
      remainingActiveSeconds: (candidate: UpgradeTrackerItem) =>
        candidate === activeDuplicate ? 10 : 0,
    } as unknown as UpgradeTrackerSnapshot;

    const result = farmTrackerTargets({
      snapshot,
      buildings: [cannon, archer],
      townHall: 3,
      maxTownHall: 3,
      now: new Date('2026-08-01T00:00:00Z'),
    });
    expect(result.map((entry) => entry.item.name)).toEqual(['Cannon', 'Archer Tower']);
    expect(result[0]?.plannedCosts).toEqual([cost('Gold', 80)]);
  });

  it('handles missing snapshots, unknown buildings, and concurrent active copies', () => {
    const cannon = building('Cannon', [2, 3]);
    expect(farmTargetLevels(undefined, 1, 1)).toEqual([]);
    expect(farmSelectableBuildings([cannon], null, 2, 3)).toEqual([cannon]);
    expect(farmUnpaidTargetLevels(cannon, null, 2, 3)).toBeNull();

    const complete = item('Cannon', 3, [], { isComplete: true });
    const activeCopy = item('Cannon', 1, [step(2)], {
      count: 2,
    });
    const snapshot = {
      itemsFor: () => [complete, activeCopy],
      remainingActiveSeconds: (candidate: UpgradeTrackerItem) =>
        candidate === activeCopy ? 10 : 0,
    } as unknown as UpgradeTrackerSnapshot;
    expect(farmSelectableBuildings([cannon], snapshot, 2, 3)).toEqual([cannon]);
    expect(farmUnpaidTargetLevels(cannon, snapshot, 2, 3)).toEqual(new Set([2]));

    const unknownSnapshot = {
      itemsFor: () => [item('Unknown', 1, [])],
      remainingActiveSeconds: () => 0,
    } as unknown as UpgradeTrackerSnapshot;
    expect(farmUnpaidTargetLevels(cannon, unknownSnapshot, 2, 3)).toBeNull();
  });
});
