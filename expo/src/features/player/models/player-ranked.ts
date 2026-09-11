import {
  apiDate,
  int,
  nullableInt,
  nullableString,
  number,
  record,
  records,
  string,
  type JsonRecord,
} from './parsing';
import { canonicalTag } from '../../../core/domain/tags';

export class RankedLeagueTier {
  constructor(
    readonly id: number,
    readonly name: string,
    readonly smallIconUrl: string,
    readonly largeIconUrl: string,
  ) {}
  static fromJson(json: JsonRecord) {
    const icons = record(json.iconUrls);
    return new RankedLeagueTier(
      int(json.id),
      string(json.name, 'Unranked'),
      string(icons.small),
      string(icons.large),
    );
  }
}
export class RankedLeagueMember {
  constructor(
    readonly playerTag: string,
    readonly playerName: string,
    readonly clanTag: string,
    readonly clanName: string,
    readonly leagueTrophies: number,
    readonly attackWinCount: number,
    readonly attackLoseCount: number,
    readonly defenseWinCount: number,
    readonly defenseLoseCount: number,
  ) {}
  static fromJson(json: JsonRecord) {
    return new RankedLeagueMember(
      string(json.playerTag),
      string(json.playerName),
      string(json.clanTag),
      string(json.clanName),
      int(json.leagueTrophies),
      int(json.attackWinCount),
      int(json.attackLoseCount),
      int(json.defenseWinCount),
      int(json.defenseLoseCount),
    );
  }
}
export class RankedLeagueBattle {
  constructor(
    readonly opponentPlayerTag: string,
    readonly opponentName: string,
    readonly stars: number | null,
    readonly destructionPercentage: number | null,
    readonly trophies: number,
    readonly creationTime: Date | null,
    readonly automatic = false,
    readonly opponentTownHallLevel = 0,
    readonly townHallLevel = 0,
    readonly duration = 0,
  ) {}
  static fromAnalytics(json: JsonRecord) {
    if (json.automatic === true) {
      return new RankedLeagueBattle('', '', null, null, int(json.trophies), null, true);
    }
    const opponent = record(json.opponent);
    return new RankedLeagueBattle(
      string(opponent.tag),
      '',
      int(json.stars),
      number(json.destructionPercentage),
      int(json.trophies),
      apiDate(json.time),
      false,
      int(opponent.townHallLevel),
      int(json.townHallLevel),
      int(json.duration),
    );
  }
}

export class RankedLeagueBattlelog {
  constructor(
    readonly tag: string,
    readonly seasonId: string,
    readonly leagueGroupId: string,
    readonly leagueTierId: number,
    readonly attacksComplete: boolean,
    readonly defensesComplete: boolean,
    readonly missingRealAttacks: number,
    readonly missingRealDefenses: number,
    readonly automaticDefensesDerived: boolean,
    readonly registeredAttacks: number,
    readonly registeredDefenses: number,
    readonly maxAttacks: number,
    readonly maxDefenses: number,
    readonly attacks: readonly RankedLeagueBattle[],
    readonly defenses: readonly RankedLeagueBattle[],
  ) {}

  static fromJson(json: JsonRecord) {
    const league = record(json.league);
    const attacks = records(json.attacks);
    const defenses = records(json.defenses);
    const registeredAttacks = int(json.registeredAttacks);
    const registeredDefenses = int(json.registeredDefenses);
    const missingRealAttacks = Math.max(0, registeredAttacks - attacks.length);
    const missingRealDefenses = Math.max(0, registeredDefenses - defenses.length);
    const maxBattles = int(json.maxBattles);
    return new RankedLeagueBattlelog(
      string(json.tag),
      string(json.seasonId),
      string(json.leagueGroupId),
      int(league.id),
      missingRealAttacks === 0,
      missingRealDefenses === 0,
      missingRealAttacks,
      missingRealDefenses,
      defenses.some((defense) => defense.automatic === true),
      registeredAttacks,
      registeredDefenses,
      maxBattles,
      maxBattles,
      attacks.map(RankedLeagueBattle.fromAnalytics),
      defenses.map(RankedLeagueBattle.fromAnalytics),
    );
  }
}
export class RankedLeagueGroup {
  readonly members: readonly RankedLeagueMember[];
  constructor(
    readonly tag: string,
    readonly seasonId: number,
    members: readonly RankedLeagueMember[],
  ) {
    this.members = [...members].sort((a, b) => b.leagueTrophies - a.leagueTrophies);
  }
  static fromJson(json: JsonRecord, tag: string, seasonId: number) {
    return new RankedLeagueGroup(
      tag,
      seasonId,
      records(json.members).map(RankedLeagueMember.fromJson),
    );
  }
}
export class RankedLeagueHistoryEntry {
  constructor(
    readonly leagueSeasonId: number,
    readonly leagueTrophies: number,
    readonly leagueTierId: number,
    readonly placement: number,
    readonly attackWins: number,
    readonly attackLosses: number,
    readonly attackStars: number,
    readonly defenseWins: number,
    readonly defenseLosses: number,
    readonly defenseStars: number,
    readonly maxBattles: number,
  ) {}
  get startsAt() {
    return new Date(this.leagueSeasonId * 1000);
  }
  static fromJson(json: JsonRecord) {
    return new RankedLeagueHistoryEntry(
      int(json.leagueSeasonId),
      int(json.leagueTrophies),
      int(json.leagueTierId),
      int(json.placement),
      int(json.attackWins),
      int(json.attackLosses),
      int(json.attackStars),
      int(json.defenseWins),
      int(json.defenseLosses),
      int(json.defenseStars),
      int(json.maxBattles),
    );
  }
}
export class RankedLeagueData {
  constructor(
    readonly playerTag: string,
    readonly playerName: string,
    readonly townHallLevel: number,
    readonly trophies: number,
    readonly bestTrophies: number,
    readonly currentTier: RankedLeagueTier | null,
    readonly tiers: ReadonlyMap<number, RankedLeagueTier>,
    readonly history: readonly RankedLeagueHistoryEntry[],
    readonly currentGroup: RankedLeagueGroup | null = null,
    readonly previousGroup: RankedLeagueGroup | null = null,
    readonly currentBattlelog: RankedLeagueBattlelog | null = null,
    readonly previousBattlelog: RankedLeagueBattlelog | null = null,
  ) {}
  groupForSeason(id: number) {
    return this.currentGroup?.seasonId === id
      ? this.currentGroup
      : this.previousGroup?.seasonId === id
        ? this.previousGroup
        : null;
  }
  battlelogForSeason(id: number) {
    const seasonId = String(id);
    return this.currentBattlelog?.seasonId === seasonId
      ? this.currentBattlelog
      : this.previousBattlelog?.seasonId === seasonId
        ? this.previousBattlelog
        : null;
  }
  get currentMember() {
    const playerTag = canonicalTag(this.playerTag);
    return (
      this.currentGroup?.members.find((member) => canonicalTag(member.playerTag) === playerTag) ??
      null
    );
  }
  get currentRank() {
    const member = this.currentMember;
    return !member || !this.currentGroup ? null : this.currentGroup.members.indexOf(member) + 1;
  }
  get currentMaxBattles() {
    if (this.currentBattlelog && this.currentBattlelog.maxAttacks > 0) {
      return this.currentBattlelog.maxAttacks;
    }
    const tierId = this.currentTier?.id;
    if (tierId === undefined) return null;
    return (
      this.history.find((entry) => entry.leagueTierId === tierId && entry.maxBattles > 0)
        ?.maxBattles ?? null
    );
  }
}

export class PlayerRankings {
  constructor(
    readonly tag: string,
    readonly homeVillage: PlayerRankingCategory,
    readonly builderBase: PlayerRankingCategory,
  ) {}
  static fromJson(json: JsonRecord) {
    return new PlayerRankings(
      string(json.tag),
      PlayerRankingCategory.fromJson(record(json.homeVillage)),
      PlayerRankingCategory.fromJson(record(json.builderBase)),
    );
  }
}
export class PlayerRankingCategory {
  constructor(
    readonly points: number | null,
    readonly globalRank: number | null,
    readonly locationId: string | null,
    readonly locationName: string | null,
    readonly countryCode: string | null,
    readonly localRank: number | null,
  ) {}
  static fromJson(json: JsonRecord) {
    return new PlayerRankingCategory(
      nullableInt(json.points),
      nullableInt(json.globalRank),
      nullableString(json.locationId),
      nullableString(json.locationName),
      nullableString(json.countryCode),
      nullableInt(json.localRank),
    );
  }
}
