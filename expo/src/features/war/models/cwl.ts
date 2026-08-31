import { ClanBadgeUrls } from '../../clan/models';
import {
  int,
  intMap,
  nullableNumber,
  number,
  record,
  records,
  string,
  stringList,
  type JsonRecord,
} from './parsing';

export class CwlAttackStats {
  constructor(
    readonly stars: number,
    readonly threeStars: Readonly<Record<string, number>>,
    readonly twoStars: Readonly<Record<string, number>>,
    readonly oneStar: Readonly<Record<string, number>>,
    readonly zeroStar: Readonly<Record<string, number>>,
    readonly totalDestruction: number,
    readonly attackCount: number,
    readonly missedAttacks: number,
    readonly warsParticipated: number | null = null,
    readonly attacksPerWar: number | null = null,
  ) {}
  static fromJson(json: JsonRecord): CwlAttackStats {
    try {
      return new CwlAttackStats(
        int(json.stars),
        intMap(json['3_stars']),
        intMap(json['2_stars']),
        intMap(json['1_star']),
        intMap(json['0_star']),
        number(json.total_destruction),
        int(json.attack_count),
        int(json.missed_attacks),
      );
    } catch {
      return new CwlAttackStats(0, {}, {}, {}, {}, 0, 0, 0);
    }
  }
  get averageStars(): number {
    return this.attackCount ? this.stars / this.attackCount : 0;
  }
  get averageDestruction(): number {
    return this.attackCount ? this.totalDestruction / this.attackCount : 0;
  }
  get calculatedMissedAttacks(): number {
    if (this.warsParticipated === null || this.attacksPerWar === null) return this.missedAttacks;
    return Math.max(0, this.warsParticipated * this.attacksPerWar - this.attackCount);
  }
  toJson(): JsonRecord {
    return {
      stars: this.stars,
      '3_stars': this.threeStars,
      '2_stars': this.twoStars,
      '1_star': this.oneStar,
      '0_star': this.zeroStar,
      total_destruction: this.totalDestruction,
      attack_count: this.attackCount,
      missed_attacks: this.missedAttacks,
    };
  }
}

export class CwlDefenseStats {
  constructor(
    readonly stars: number,
    readonly threeStars: Readonly<Record<string, number>>,
    readonly twoStars: Readonly<Record<string, number>>,
    readonly oneStar: Readonly<Record<string, number>>,
    readonly zeroStar: Readonly<Record<string, number>>,
    readonly totalDestruction: number,
    readonly defenseCount: number,
    readonly missedDefenses: number,
  ) {}
  static fromJson(json: JsonRecord): CwlDefenseStats {
    try {
      return new CwlDefenseStats(
        int(json.stars),
        intMap(json['3_stars']),
        intMap(json['2_stars']),
        intMap(json['1_star']),
        intMap(json['0_star']),
        number(json.total_destruction),
        int(json.defense_count),
        int(json.missed_defenses),
      );
    } catch {
      return new CwlDefenseStats(0, {}, {}, {}, {}, 0, 0, 0);
    }
  }
  get averageStars(): number {
    return this.defenseCount ? this.stars / this.defenseCount : 0;
  }
  get averageDestruction(): number {
    return this.defenseCount ? this.totalDestruction / this.defenseCount : 0;
  }
  toJson(): JsonRecord {
    return {
      stars: this.stars,
      '3_stars': this.threeStars,
      '2_stars': this.twoStars,
      '1_star': this.oneStar,
      '0_star': this.zeroStar,
      total_destruction: this.totalDestruction,
      defense_count: this.defenseCount,
    };
  }
}

export class CwlMember {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly townhallLevel: number,
    readonly avgMapPosition: number | null = null,
    readonly avgOpponentPosition: number | null = null,
    readonly avgAttackOrder: number | null = null,
    readonly avgTownHallLevel: number | null = null,
    readonly avgOpponentTownHallLevel: number | null = null,
    readonly avgAttackerPosition: number | null = null,
    readonly avgDefenseOrder: number | null = null,
    readonly avgAttackerTownHallLevel: number | null = null,
    readonly attackLowerTHLevel: number | null = null,
    readonly defenseLowerTHLevel: number | null = null,
    readonly attackUpperTHLevel: number | null = null,
    readonly defenseUpperTHLevel: number | null = null,
    readonly attackStats: CwlAttackStats | null = null,
    readonly defenseStats: CwlDefenseStats | null = null,
  ) {}
  static fromJson(json: JsonRecord): CwlMember {
    try {
      return new CwlMember(
        string(json.tag),
        string(json.name),
        int(json.townHallLevel),
        nullableNumber(json.avgMapPosition),
        nullableNumber(json.avgOpponentPosition),
        nullableNumber(json.avgAttackOrder),
        nullableNumber(json.avgTownHallLevel),
        nullableNumber(json.avgOpponentTownHallLevel),
        nullableNumber(json.avgAttackerPosition),
        nullableNumber(json.avgDefenseOrder),
        nullableNumber(json.avgAttackerTownHallLevel),
        nullableNumber(json.attackLowerTHLevel),
        nullableNumber(json.defenseLowerTHLevel),
        nullableNumber(json.attackUpperTHLevel),
        nullableNumber(json.defenseUpperTHLevel),
        json.attacks == null ? null : CwlAttackStats.fromJson(record(json.attacks)),
        json.defense == null ? null : CwlDefenseStats.fromJson(record(json.defense)),
      );
    } catch {
      return new CwlMember(
        string(json.tag, 'No tag'),
        string(json.name, 'No name'),
        int(json.townHallLevel),
      );
    }
  }
  private sum(
    stats: CwlAttackStats | CwlDefenseStats | null,
    field: 'threeStars' | 'twoStars' | 'oneStar' | 'zeroStar',
  ) {
    return Object.values(stats?.[field] ?? {}).reduce((total, count) => total + count, 0);
  }
  get threeStars() {
    return this.sum(this.attackStats, 'threeStars');
  }
  get twoStars() {
    return this.sum(this.attackStats, 'twoStars');
  }
  get oneStar() {
    return this.sum(this.attackStats, 'oneStar');
  }
  get zeroStar() {
    return this.sum(this.attackStats, 'zeroStar');
  }
  get threeStarsDef() {
    return this.sum(this.defenseStats, 'threeStars');
  }
  get twoStarsDef() {
    return this.sum(this.defenseStats, 'twoStars');
  }
  get oneStarDef() {
    return this.sum(this.defenseStats, 'oneStar');
  }
  get zeroStarDef() {
    return this.sum(this.defenseStats, 'zeroStar');
  }
  toJson(): JsonRecord {
    return {
      tag: this.tag,
      name: this.name,
      townHallLevel: this.townhallLevel,
      attacks: this.attackStats?.toJson() ?? null,
      defense: this.defenseStats?.toJson() ?? null,
    };
  }
}

export class CwlClan {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly badgeUrls: ClanBadgeUrls,
    readonly clanLevel: number,
    readonly attackCount: number,
    readonly stars: number,
    readonly destructionPercentage: number,
    readonly destructionPercentageInflicted: number,
    readonly members: readonly CwlMember[],
    readonly rank: number,
    readonly warsPlayed: number,
    readonly townHallLevels: Readonly<Record<string, number>>,
  ) {}
  static fromJson(value: unknown): CwlClan {
    try {
      const json = record(value);
      return new CwlClan(
        string(json.tag, 'No tag'),
        string(json.name, 'No name'),
        ClanBadgeUrls.fromJson(json.badgeUrls),
        int(json.clanLevel),
        int(json.attack_count),
        int(json.total_stars),
        number(json.total_destruction),
        number(json.total_destruction_inflicted),
        records(json.members).map(CwlMember.fromJson),
        int(json.rank),
        int(json.wars_played),
        intMap(json.town_hall_levels),
      );
    } catch {
      return new CwlClan('No tag', 'No name', ClanBadgeUrls.empty(), 0, 0, 0, 0, 0, [], 0, 0, {});
    }
  }
  static empty(): CwlClan {
    return new CwlClan('', '', ClanBadgeUrls.empty(), 0, 0, 0, 0, 0, [], 0, 0, {});
  }
  private attackStarCount(field: 'threeStars' | 'twoStars' | 'oneStar' | 'zeroStar') {
    return this.members.reduce((total, member) => total + member[field], 0);
  }
  get missedAttacks() {
    return this.members.reduce((sum, m) => sum + (m.attackStats?.missedAttacks ?? 0), 0);
  }
  get totalThreeStars() {
    return this.attackStarCount('threeStars');
  }
  get totalTwoStars() {
    return this.attackStarCount('twoStars');
  }
  get totalOneStar() {
    return this.attackStarCount('oneStar');
  }
  get totalZeroStar() {
    return this.attackStarCount('zeroStar');
  }
  get threeStars() {
    return this.attackStarCount('threeStars');
  }
  get twoStars() {
    return this.attackStarCount('twoStars');
  }
  get oneStar() {
    return this.attackStarCount('oneStar');
  }
  get zeroStar() {
    return this.attackStarCount('zeroStar');
  }
  get averageStars() {
    const attempts = this.members.reduce((sum, m) => sum + (m.attackStats?.attackCount ?? 0), 0);
    const stars = this.members.reduce((sum, m) => sum + (m.attackStats?.stars ?? 0), 0);
    return attempts ? stars / attempts : 0;
  }
  get averageDestruction() {
    const attempts = this.members.reduce((sum, m) => sum + (m.attackStats?.attackCount ?? 0), 0);
    const destruction = this.members.reduce(
      (sum, m) => sum + (m.attackStats?.totalDestruction ?? 0),
      0,
    );
    return attempts ? destruction / attempts : 0;
  }
  get defenseCount() {
    return this.members.reduce((sum, m) => sum + (m.defenseStats?.defenseCount ?? 0), 0);
  }
  get defStars() {
    return this.members.reduce((sum, m) => sum + (m.defenseStats?.stars ?? 0), 0);
  }
  get defAverageStars() {
    return this.defenseCount ? this.defStars / this.defenseCount : 0;
  }
  get defAverageDestruction() {
    const destruction = this.members.reduce(
      (sum, m) => sum + (m.defenseStats?.totalDestruction ?? 0),
      0,
    );
    return this.defenseCount ? destruction / this.defenseCount : 0;
  }
  get missedDefenses() {
    return this.members.reduce((sum, m) => sum + (m.defenseStats?.missedDefenses ?? 0), 0);
  }
  get threeStarsDef() {
    return this.members.reduce((sum, m) => sum + m.threeStarsDef, 0);
  }
  get twoStarsDef() {
    return this.members.reduce((sum, m) => sum + m.twoStarsDef, 0);
  }
  get oneStarDef() {
    return this.members.reduce((sum, m) => sum + m.oneStarDef, 0);
  }
  get zeroStarDef() {
    return this.members.reduce((sum, m) => sum + m.zeroStarDef, 0);
  }
  toJson(): JsonRecord {
    return {
      tag: this.tag,
      name: this.name,
      clanLevel: this.clanLevel,
      attacks: this.attackCount,
      stars: this.stars,
      destructionPercentage: this.destructionPercentage,
      members: this.members.map((member) => member.toJson()),
    };
  }
}

export class CwlLeagueRound {
  constructor(
    readonly roundNumber: number,
    readonly warTags: readonly string[],
  ) {}
  static fromJson(json: JsonRecord, index: number) {
    return new CwlLeagueRound(index + 1, stringList(json.warTags));
  }
  containsWar(warTag: string | null | undefined): boolean {
    return warTag != null && this.warTags.includes(warTag);
  }
}

export class CwlLeague {
  constructor(
    readonly state: string,
    readonly season: string,
    readonly clans: CwlClan[],
    readonly rounds: CwlLeagueRound[],
  ) {}
  static fromJson(value: unknown): CwlLeague {
    try {
      const json = record(value);
      const rounds = records(json.rounds)
        .map((round, index) => ({ round, index }))
        .filter(({ round }) => stringList(round.warTags).some((tag) => tag !== '#0'))
        .map(({ round, index }) => CwlLeagueRound.fromJson(round, index));
      return new CwlLeague(
        string(json.state, 'unknown'),
        string(json.season, 'unknown'),
        records(json.clans).map(CwlClan.fromJson),
        rounds,
      );
    } catch {
      return new CwlLeague('unknown', 'unknown', [], []);
    }
  }
  getStarsGapFromRank(clanTag: string, targetRank: number): number | null {
    if (!this.clans.length) return null;
    const current = this.clans.find((clan) => clan.tag === clanTag);
    if (!current) return null;
    const target =
      this.clans.find((clan) => clan.rank === targetRank) ??
      [...this.clans].sort(
        (left, right) => Math.abs(left.rank - targetRank) - Math.abs(right.rank - targetRank),
      )[0]!;
    return target.stars - current.stars;
  }
  getClanDetails(tag: string): CwlClan | null {
    return this.clans.find((clan) => clan.tag === tag) ?? null;
  }
  sortClans(sortBy: string): void {
    if (sortBy === 'stars') this.clans.sort((left, right) => right.stars - left.stars);
    if (sortBy === 'percentage')
      this.clans.sort((left, right) => right.destructionPercentage - left.destructionPercentage);
  }
  getRounds(): readonly CwlLeagueRound[] {
    return this.rounds.filter((round) => round.warTags.some((tag) => tag !== '#0'));
  }
  getCurrentRounds(): CwlLeagueRound | null {
    if (!this.rounds.length) return null;
    if (this.rounds.length === 1) return this.rounds[0]!;
    if (this.rounds.length <= 6) return this.rounds[this.rounds.length - 2]!;
    return this.rounds[this.rounds.length - 1]!;
  }
}
