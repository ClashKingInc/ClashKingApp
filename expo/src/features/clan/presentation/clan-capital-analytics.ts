import type { CapitalHistoryItem, District, RaidAttackLog, RaidDefender } from '../models';

const CAPITAL_PEAK_ID = 70_000_000;
const DISTRICT_MEDALS: Readonly<Record<number, number>> = {
  1: 135,
  2: 225,
  3: 350,
  4: 405,
  5: 460,
};
const PEAK_MEDALS: Readonly<Record<number, number>> = {
  2: 180,
  3: 360,
  4: 585,
  5: 810,
  6: 1115,
  7: 1240,
  8: 1260,
  9: 1375,
  10: 1450,
};

export type DistrictStat = {
  id: number;
  name: string;
  destroyedCount: number;
  attacks: number;
  loot: number;
  hitRates: ReadonlyMap<number, number>;
  avgAttacksPerDestroy: number;
  avgLootPerAttack: number;
};

export type OpponentStat = {
  clan: RaidDefender;
  attacks: number;
  districtsDestroyed: number;
  districtCount: number;
  loot: number;
  districts: readonly District[];
};

export type PlayerAttackStat = {
  name: string;
  tag: string;
  attacks: number;
  stars: number;
  destruction: number;
  perfectHits: number;
  avgDestruction: number;
};

export type DistrictDefenseStat = {
  id: number;
  name: string;
  defenses: number;
  destroyed: number;
  held: number;
  attacksTaken: number;
  destruction: number;
  lootLost: number;
  avgAttacksTaken: number;
  avgDestruction: number;
};

export function projectedTotalLoot(raid: CapitalHistoryItem): number | null {
  if (raid.state !== 'ongoing' || raid.totalAttacks === 0) return null;
  return Math.round((raid.capitalTotalLoot / raid.totalAttacks) * 300);
}

export function predictTrophyChange(raid: CapitalHistoryItem, current: number) {
  const predictedPoints = Math.round(current * 0.8 + trophyPerformance(raid) * 0.2);
  return { predictedPoints, change: predictedPoints - current };
}

export function trophyPerformance(raid: CapitalHistoryItem): number {
  const averageLoot = raid.totalAttacks === 0 ? 0 : raid.capitalTotalLoot / raid.totalAttacks;
  const loot = raid.state === 'ended' ? raid.capitalTotalLoot : averageLoot * 300;
  const skill = averageLoot - averageDefensiveLoot(raid);
  const center = Math.pow(Math.max(0, loot), 0.6);
  if (skill > 664) return Math.max(0, center + 50 * Math.log(skill) + 360);
  if (skill < -664) return Math.max(0, center - 50 * Math.log(-skill) - 360);
  return Math.max(0, center + skill + 34);
}

export function districtStats(log: readonly RaidAttackLog[]): DistrictStat[] {
  const values = new Map<
    number,
    { name: string; count: number; attacks: number; loot: number; rates: Map<number, number> }
  >();
  for (const opponent of log) {
    for (const district of opponent.districts) {
      if (district.destructionPercent !== 100) continue;
      const value = values.get(district.id) ?? {
        name: district.name,
        count: 0,
        attacks: 0,
        loot: 0,
        rates: new Map<number, number>(),
      };
      value.count += 1;
      value.attacks += district.attackCount;
      value.loot += district.totalLooted;
      value.rates.set(district.attackCount, (value.rates.get(district.attackCount) ?? 0) + 1);
      values.set(district.id, value);
    }
  }
  return [...values.entries()]
    .map(([id, value]) => ({
      id,
      name: value.name,
      destroyedCount: value.count,
      attacks: value.attacks,
      loot: value.loot,
      hitRates: value.rates,
      avgAttacksPerDestroy: value.count === 0 ? 0 : value.attacks / value.count,
      avgLootPerAttack: value.attacks === 0 ? 0 : value.loot / value.attacks,
    }))
    .sort((a, b) => a.id - b.id);
}

export function opponentStats(log: readonly RaidAttackLog[]): OpponentStat[] {
  return log
    .map((opponent) => ({
      clan: opponent.defender,
      attacks: opponent.attackCount,
      districtsDestroyed: opponent.districtsDestroyed,
      districtCount: opponent.districtCount,
      loot: opponent.districts.reduce((sum, district) => sum + district.totalLooted, 0),
      districts: opponent.districts,
    }))
    .sort((a, b) => b.loot - a.loot);
}

export function attackEfficiency(log: readonly RaidAttackLog[]) {
  let oneshots = 0;
  let fails = 0;
  for (const opponent of log) {
    for (const district of opponent.districts) {
      if (district.destructionPercent !== 100) continue;
      if (district.attackCount === 1) oneshots += 1;
      else if (district.attackCount > (district.id === CAPITAL_PEAK_ID ? 3 : 2)) fails += 1;
    }
  }
  return { oneshots, fails };
}

export function playerAttackStats(log: readonly RaidAttackLog[]): PlayerAttackStat[] {
  const values = new Map<string, Omit<PlayerAttackStat, 'avgDestruction'>>();
  for (const opponent of log) {
    for (const district of opponent.districts) {
      for (const attack of district.attacks) {
        const key = attack.tag || attack.name;
        const value = values.get(key) ?? {
          name: attack.name,
          tag: attack.tag,
          attacks: 0,
          stars: 0,
          destruction: 0,
          perfectHits: 0,
        };
        value.attacks += 1;
        value.stars += attack.stars;
        value.destruction += attack.destructionPercent;
        if (attack.stars >= 3 || attack.destructionPercent >= 100) value.perfectHits += 1;
        values.set(key, value);
      }
    }
  }
  return [...values.values()]
    .map((value) => ({
      ...value,
      avgDestruction: value.attacks === 0 ? 0 : value.destruction / value.attacks,
    }))
    .sort(
      (a, b) => b.attacks - a.attacks || b.stars - a.stars || b.avgDestruction - a.avgDestruction,
    );
}

export function districtDefenseStats(log: readonly RaidAttackLog[]): DistrictDefenseStat[] {
  const values = new Map<
    number,
    Omit<DistrictDefenseStat, 'id' | 'avgAttacksTaken' | 'avgDestruction'>
  >();
  for (const opponent of log) {
    for (const district of opponent.districts) {
      const value = values.get(district.id) ?? {
        name: district.name,
        defenses: 0,
        destroyed: 0,
        held: 0,
        attacksTaken: 0,
        destruction: 0,
        lootLost: 0,
      };
      value.defenses += 1;
      value.attacksTaken += district.attackCount;
      value.destruction += district.destructionPercent;
      value.lootLost += district.totalLooted;
      if (district.destructionPercent >= 100) value.destroyed += 1;
      else value.held += 1;
      values.set(district.id, value);
    }
  }
  return [...values.entries()]
    .map(([id, value]) => ({
      id,
      ...value,
      avgAttacksTaken: value.defenses === 0 ? 0 : value.attacksTaken / value.defenses,
      avgDestruction: value.defenses === 0 ? 0 : value.destruction / value.defenses,
    }))
    .sort((a, b) => b.held - a.held || a.avgDestruction - b.avgDestruction);
}

export function predictOffensiveReward(log: readonly RaidAttackLog[]): number {
  let medals = 0;
  let attacks = 0;
  for (const opponent of log) {
    attacks += opponent.attackCount;
    for (const district of opponent.districts) {
      if (district.destructionPercent !== 100) continue;
      medals +=
        (district.id === CAPITAL_PEAK_ID ? PEAK_MEDALS : DISTRICT_MEDALS)[
          district.districtHallLevel
        ] ?? 0;
    }
  }
  return medals === 0 || attacks === 0 ? 0 : Math.min(1620, Math.ceil(medals / attacks) * 6);
}

export function predictDefensiveReward(log: readonly RaidAttackLog[]): number {
  if (!log.length) return 0;
  let housingSpace = 0;
  for (const district of log[0]!.districts) {
    const level = district.districtHallLevel;
    if (district.id === 70_000_001) housingSpace += 3 * (25 + 5 * level);
    else if (district.id === 70_000_002 && level > 1) housingSpace += 25 + 5 * level;
    else if (district.id === 70_000_005) housingSpace += 25 + 5 * level;
  }
  const lower = new Map<number, number>();
  const upper = new Map<number, number>();
  for (const opponent of log) {
    for (const district of opponent.districts) {
      if (district.destructionPercent !== 100) continue;
      lower.set(district.id, Math.max(lower.get(district.id) ?? 0, district.totalLooted - 750));
      upper.set(district.id, Math.min(upper.get(district.id) ?? 100_000, district.totalLooted));
    }
  }
  const weights = new Map<number, number>();
  for (const [id, value] of lower) weights.set(id, Math.trunc((value + (upper.get(id) ?? 0)) / 2));
  let maxKilled = Number.NEGATIVE_INFINITY;
  for (const opponent of log) {
    let killed = 0;
    for (const district of opponent.districts) {
      killed += district.attackCount * housingSpace;
      if (district.destructionPercent === 100) {
        killed -= Math.floor((district.totalLooted - (weights.get(district.id) ?? 0)) / 3);
      }
    }
    maxKilled = Math.max(maxKilled, killed);
  }
  return Math.min(350, Math.floor(maxKilled / 25));
}

function averageDefensiveLoot(raid: CapitalHistoryItem): number {
  const log = raid.defenseLog;
  if (!log.length) return 0;
  const dummyAttacks = 3.5 * log[0]!.districtCount;
  const complete = log.filter((opponent) => opponent.districtsDestroyed === opponent.districtCount);
  const lootPerDefense = complete.length
    ? complete.reduce(
        (sum, opponent) =>
          sum +
          opponent.districts.reduce(
            (districtSum, district) => districtSum + district.totalLooted,
            0,
          ),
        0,
      ) / complete.length
    : 0;
  let loot = 0;
  let attacks = 0;
  for (const opponent of log) {
    for (const district of opponent.districts) {
      if (district.destructionPercent !== 100) continue;
      loot += district.totalLooted;
      attacks += district.attackCount;
    }
  }
  return attacks + dummyAttacks === 0 ? 0 : (loot + lootPerDefense) / (attacks + dummyAttacks);
}
