import { gameDataState } from '../../core/game-data/game-data-state';
import {
  BuildingDefinition,
  BuildingLevelDefinition,
  DamageCatalog,
  DamageCalculatorSession,
  DamageLevel,
  DamageSourceDefinition,
  DamageSourceKind,
} from '../damage-calculator';
import {
  applyQuickSetup,
  availableSetupIds,
  calculatorSetupIds,
  defaultFarmLoot,
  farmAttackScenarios,
  farmLeagueLootEstimate,
  farmSelectableBuildings,
  farmTargetLevels,
  farmUnpaidTargetLevels,
  parseFarmAmount,
} from './calculator-logic';
import type {
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
} from '../upgrade-tracker/models/upgrade-tracker-models';

const lightning = new DamageSourceDefinition({
  kind: DamageSourceKind.Lightning,
  name: 'Lightning Spell',
  imageUrl: 'lightning.png',
  levels: [new DamageLevel({ level: 1, requiredTownHall: 1, damage: 100 })],
});
const earthquake = new DamageSourceDefinition({
  kind: DamageSourceKind.Earthquake,
  name: 'Earthquake Spell',
  imageUrl: 'earthquake.png',
  levels: [new DamageLevel({ level: 1, requiredTownHall: 1, earthquakePercent: 14.5 })],
});
const townHall = new BuildingDefinition({
  id: 'town-hall',
  name: 'Town Hall',
  imageName: 'Town Hall',
  zapQuakeEligible: true,
  levels: [
    new BuildingLevelDefinition({ level: 10, hitpoints: 5000, requiredTownHall: 10 }),
    new BuildingLevelDefinition({ level: 11, hitpoints: 6000, requiredTownHall: 11 }),
  ],
});
const catalog = new DamageCatalog({
  maxTownHall: 11,
  buildings: [townHall],
  sources: [lightning, earthquake],
});

describe('calculator parity logic', () => {
  it('applies the exact zap-quake stack and only exposes supported quick setups', () => {
    const session = new DamageCalculatorSession(catalog, { townHall: 10 });
    expect(availableSetupIds(session)).toEqual(['custom', 'zap-quake']);
    applyQuickSetup(session, calculatorSetupIds.zapQuake);
    expect(session.sources.get(DamageSourceKind.Lightning)?.count).toBe(5);
    expect(session.sources.get(DamageSourceKind.Earthquake)?.count).toBe(1);
  });

  it('preserves farm defaults, numeric parsing, TH+1 targets, and 100/80/60 projections', () => {
    expect(defaultFarmLoot('Dark Elixir')).toBe(10_250);
    expect(defaultFarmLoot('Gold')).toBe(1_013_000);
    expect(parseFarmAmount('1,234,567 gold')).toBe(1_234_567);
    expect(farmTargetLevels(townHall, 10, 11).map((level) => level.level)).toEqual([10, 11]);
    expect(farmAttackScenarios(1_000_000, 250_000)).toEqual([
      { destructionPercent: 100, lootPerAttack: 250_000, attacks: 4 },
      { destructionPercent: 80, lootPerAttack: 200_000, attacks: 5 },
      { destructionPercent: 60, lootPerAttack: 150_000, attacks: 7 },
    ]);
  });

  it('selects the last league reward valid for the account Town Hall', () => {
    gameDataState.playerLeagueData.leagues = {
      Crystal: {
        rewards: [
          { townhall_level: 1, resources: { gold: 10 }, star_bonus: { gold: 5 } },
          { townhall_level: 10, resources: { gold: 20 }, star_bonus: { gold: 7 } },
          { townhall_level: 12, resources: { gold: 30 }, star_bonus: { gold: 9 } },
          { resources: { gold: 999 }, star_bonus: { gold: 999 } },
        ],
      },
    };
    expect(farmLeagueLootEstimate('Crystal', 10, 'Gold')).toEqual({ loot: 20, starBonus: 7 });
  });

  it('mirrors tracker paid-level filtering while retaining a completed Town Hall upgrade', () => {
    const cannon = building('Cannon', [1, 2]);
    const inferno = building('Inferno Tower', [1, 2, 3]);
    const completeCannon = trackerItem('Cannon', 2, true, []);
    const completeTownHall = trackerItem('Town Hall', 10, true, []);
    const activeInferno = trackerItem('Inferno Tower', 1, false, [2, 3], 1);
    const snapshot = {
      itemsFor: () => [completeCannon, completeTownHall, activeInferno],
      remainingActiveSeconds: (item: UpgradeTrackerItem) => (item === activeInferno ? 100 : 0),
    } as unknown as UpgradeTrackerSnapshot;

    expect(
      farmSelectableBuildings([cannon, townHall, inferno], snapshot, 10, 11).map(
        (candidate) => candidate.name,
      ),
    ).toEqual(['Town Hall', 'Inferno Tower']);
    expect(farmUnpaidTargetLevels(inferno, snapshot, 10, 11)).toEqual(new Set([3]));
    expect(farmUnpaidTargetLevels(townHall, snapshot, 10, 11)).toEqual(new Set([11]));
  });
});

function building(name: string, levels: readonly number[]) {
  return new BuildingDefinition({
    id: name.toLowerCase().replaceAll(' ', '-'),
    name,
    imageName: name,
    zapQuakeEligible: true,
    levels: levels.map(
      (level) =>
        new BuildingLevelDefinition({ level, hitpoints: level * 100, requiredTownHall: level }),
    ),
  });
}

function trackerItem(
  name: string,
  currentLevel: number,
  isComplete: boolean,
  targetLevels: readonly number[],
  activeSeconds = 0,
) {
  return {
    name,
    currentLevel,
    isComplete,
    count: 1,
    activeSeconds,
    steps: targetLevels.map((targetLevel) => ({ targetLevel, costs: [], seconds: 100 })),
  } as unknown as UpgradeTrackerItem;
}
