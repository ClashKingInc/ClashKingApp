import { apiDateOrEpoch, int, number, record, records, string, type JsonRecord } from './parsing';

export class Attack {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly destructionPercent: number,
    readonly stars: number,
  ) {}
  static fromJson(json: JsonRecord) {
    const attacker = record(json.attacker);
    return new Attack(
      string(attacker.tag),
      string(attacker.name),
      int(json.destructionPercent),
      int(json.stars),
    );
  }
}

export class District {
  constructor(
    readonly id: number,
    readonly name: string,
    readonly districtHallLevel: number,
    readonly destructionPercent: number,
    readonly stars: number,
    readonly attackCount: number,
    readonly totalLooted: number,
    readonly attacks: readonly Attack[],
  ) {}
  static fromJson(json: JsonRecord) {
    return new District(
      int(json.id),
      string(json.name),
      int(json.districtHallLevel),
      int(json.destructionPercent),
      int(json.stars),
      int(json.attackCount),
      int(json.totalLooted),
      records(json.attacks).map(Attack.fromJson),
    );
  }
}

export class RaidDefender {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly level: number,
    readonly badgeUrls: Readonly<Record<string, string>>,
  ) {}
  static fromJson(json: JsonRecord) {
    const badges = Object.fromEntries(
      Object.entries(record(json.badgeUrls)).map(([key, value]) => [key, string(value)]),
    );
    return new RaidDefender(string(json.tag), string(json.name), int(json.level), badges);
  }
}

export class RaidAttackLog {
  constructor(
    readonly defender: RaidDefender,
    readonly attackCount: number,
    readonly districtCount: number,
    readonly districtsDestroyed: number,
    readonly districts: readonly District[],
  ) {}
  static fromJson(json: JsonRecord) {
    return new RaidAttackLog(
      RaidDefender.fromJson(record(json.defender ?? json.attacker)),
      int(json.attackCount),
      int(json.districtCount),
      int(json.districtsDestroyed),
      records(json.districts).map(District.fromJson),
    );
  }
}

export class RaidMember {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly attacks: number,
    readonly attackLimit: number,
    readonly bonusAttackLimit: number,
    readonly capitalResourcesLooted: number,
  ) {}
  static fromJson(json: JsonRecord) {
    return new RaidMember(
      string(json.tag),
      string(json.name),
      int(json.attacks),
      int(json.attackLimit),
      int(json.bonusAttackLimit),
      int(json.capitalResourcesLooted),
    );
  }
}

export class CapitalHistoryItem {
  constructor(
    readonly state: string,
    readonly startTime: Date,
    readonly endTime: Date,
    readonly capitalTotalLoot: number,
    readonly raidsCompleted: number,
    readonly totalAttacks: number,
    readonly enemyDistrictsDestroyed: number,
    readonly offensiveReward: number,
    readonly defensiveReward: number,
    readonly members: readonly RaidMember[],
    readonly attackLog: readonly RaidAttackLog[],
    readonly defenseLog: readonly RaidAttackLog[],
  ) {}
  static fromJson(json: JsonRecord) {
    return new CapitalHistoryItem(
      string(json.state),
      apiDateOrEpoch(json.startTime),
      apiDateOrEpoch(json.endTime),
      int(json.capitalTotalLoot),
      int(json.raidsCompleted),
      int(json.totalAttacks),
      int(json.enemyDistrictsDestroyed),
      int(json.offensiveReward),
      int(json.defensiveReward),
      records(json.members).map(RaidMember.fromJson),
      records(json.attackLog).map(RaidAttackLog.fromJson),
      records(json.defenseLog).map(RaidAttackLog.fromJson),
    );
  }
}

export class CapitalRaidSummary {
  constructor(
    readonly startTime: string,
    readonly capitalTotalLoot: number,
    readonly totalRewards: number,
    readonly raidsCompleted: number,
    readonly totalAttacks: number,
    readonly enemyDistrictsDestroyed: number,
    readonly avgAttacksPerRaid: number,
    readonly avgAttacksPerDistrict: number,
  ) {}
  static fromJson(json: JsonRecord) {
    return new CapitalRaidSummary(
      string(json.startTime),
      int(json.capitalTotalLoot),
      int(json.totalRewards),
      int(json.raidsCompleted),
      int(json.totalAttacks),
      int(json.enemyDistrictsDestroyed),
      number(json.avgAttacksPerRaid),
      number(json.avgAttacksPerDistrict),
    );
  }
}

export class CapitalStats {
  constructor(
    readonly totalLoot: number,
    readonly totalAttacks: number,
    readonly numberOfWeeks: number,
    readonly totalRaids: number,
    readonly totalDistrictsDestroyed: number,
    readonly totalOffensiveRewards: number,
    readonly totalDefensiveRewards: number,
    readonly avgLootPerAttack: number,
    readonly avgLootPerWeek: number,
    readonly avgAttacksPerWeek: number,
    readonly avgAttacksPerRaid: number,
    readonly avgAttacksPerDistrict: number,
    readonly avgOffensiveRewards: number,
    readonly avgDefensiveRewards: number,
    readonly bestRaid: CapitalRaidSummary | null,
    readonly worstRaid: CapitalRaidSummary | null,
  ) {}
  static fromJson(json: JsonRecord) {
    const best = record(json.bestRaid);
    const worst = record(json.worstRaid);
    return new CapitalStats(
      int(json.totalLoot),
      int(json.totalAttacks),
      int(json.numberOfWeeks),
      int(json.totalRaids),
      int(json.totalDistrictsDestroyed),
      int(json.totalOffensiveRewards),
      int(json.totalDefensiveRewards),
      number(json.avgLootPerAttack),
      number(json.avgLootPerWeek),
      number(json.avgAttacksPerWeek),
      number(json.avgAttacksPerRaid),
      number(json.avgAttacksPerDistrict),
      number(json.avgOffensiveRewards),
      number(json.avgDefensiveRewards),
      Object.keys(best).length ? CapitalRaidSummary.fromJson(best) : null,
      Object.keys(worst).length ? CapitalRaidSummary.fromJson(worst) : null,
    );
  }
}

export class CapitalHistoryItems {
  constructor(
    readonly items: readonly CapitalHistoryItem[],
    readonly clanTag: string | null,
    readonly stats: CapitalStats | null = null,
  ) {}

  static fromJson(json: JsonRecord, clanTag: string, statsData?: JsonRecord): CapitalHistoryItems {
    try {
      return new CapitalHistoryItems(
        records(json.history).map(CapitalHistoryItem.fromJson),
        clanTag,
        statsData ? CapitalStats.fromJson(statsData) : null,
      );
    } catch {
      return CapitalHistoryItems.empty();
    }
  }

  static empty(): CapitalHistoryItems {
    return new CapitalHistoryItems([], '');
  }
}
