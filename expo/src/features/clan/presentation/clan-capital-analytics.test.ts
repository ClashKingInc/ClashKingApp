import { CapitalHistoryItem } from '../models';
import {
  attackEfficiency,
  districtDefenseStats,
  districtStats,
  playerAttackStats,
  predictOffensiveReward,
  projectedTotalLoot,
} from './clan-capital-analytics';

function raid(state = 'ongoing') {
  return CapitalHistoryItem.fromJson({
    state,
    startTime: '20260828T070000.000Z',
    endTime: '20260831T070000.000Z',
    capitalTotalLoot: 120000,
    raidsCompleted: 1,
    totalAttacks: 30,
    enemyDistrictsDestroyed: 2,
    offensiveReward: 100,
    defensiveReward: 20,
    members: [],
    attackLog: [
      {
        defender: { tag: '#D', name: 'Defender', level: 10, badgeUrls: {} },
        attackCount: 3,
        districtCount: 2,
        districtsDestroyed: 2,
        districts: [
          {
            id: 70000000,
            name: 'Capital Peak',
            districtHallLevel: 10,
            destructionPercent: 100,
            stars: 3,
            attackCount: 1,
            totalLooted: 10000,
            attacks: [
              {
                attacker: { tag: '#A', name: 'Attacker' },
                destructionPercent: 100,
                stars: 3,
              },
            ],
          },
          {
            id: 70000001,
            name: 'Barbarian Camp',
            districtHallLevel: 5,
            destructionPercent: 100,
            stars: 3,
            attackCount: 2,
            totalLooted: 8000,
            attacks: [
              {
                attacker: { tag: '#A', name: 'Attacker' },
                destructionPercent: 50,
                stars: 1,
              },
            ],
          },
        ],
      },
    ],
    defenseLog: [
      {
        attacker: { tag: '#E', name: 'Enemy', level: 9, badgeUrls: {} },
        attackCount: 2,
        districtCount: 1,
        districtsDestroyed: 0,
        districts: [
          {
            id: 70000001,
            name: 'Barbarian Camp',
            districtHallLevel: 5,
            destructionPercent: 75,
            stars: 2,
            attackCount: 2,
            totalLooted: 7000,
            attacks: [],
          },
        ],
      },
    ],
  });
}

describe('Clan Capital analytics parity', () => {
  test('projects ongoing loot but never finished loot', () => {
    expect(projectedTotalLoot(raid())).toBe(1_200_000);
    expect(projectedTotalLoot(raid('ended'))).toBeNull();
  });

  test('aggregates districts, attackers, defense, and efficiency from the wire logs', () => {
    const item = raid();
    expect(districtStats(item.attackLog)).toMatchObject([
      { name: 'Capital Peak', destroyedCount: 1, attacks: 1, loot: 10000 },
      { name: 'Barbarian Camp', destroyedCount: 1, attacks: 2, loot: 8000 },
    ]);
    expect(attackEfficiency(item.attackLog)).toEqual({ oneshots: 1, fails: 0 });
    expect(playerAttackStats(item.attackLog)).toMatchObject([
      { tag: '#A', attacks: 2, stars: 4, perfectHits: 1, avgDestruction: 75 },
    ]);
    expect(districtDefenseStats(item.defenseLog)).toMatchObject([
      { held: 1, destroyed: 0, attacksTaken: 2, avgDestruction: 75 },
    ]);
  });

  test('ports the offensive medal lookup and six-attack cap', () => {
    expect(predictOffensiveReward(raid().attackLog)).toBe(1620);
  });
});
