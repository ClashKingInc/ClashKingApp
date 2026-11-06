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
import { ImageAssets } from '../../../core/assets/image-assets';
import { gameDataState } from '../../../core/game-data/game-data-state';
import type { PlayerBattlelogEntry } from './player-battlelog';

export class RankedLeagueTier {
  constructor(
    readonly id: number,
    readonly name: string,
    readonly smallIconUrl: string,
    readonly largeIconUrl: string,
  ) {}
  get iconUrl(): string {
    // Small official icons omit the tier plaque. Use our full league artwork
    // consistently so numbered tiers remain visible on cards and detail pages.
    const fullBadge = ImageAssets.getLeagueImage(this.name);
    return fullBadge !== ImageAssets.defaultImage
      ? fullBadge
      : this.largeIconUrl || this.smallIconUrl;
  }
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
    readonly shareCode = '',
  ) {}
  static fromOfficial(json: JsonRecord) {
    return new RankedLeagueBattle(
      string(json.opponentPlayerTag),
      string(json.opponentName),
      int(json.stars),
      number(json.destructionPercentage),
      int(json.trophies),
      apiDate(json.creationTime),
    );
  }
  static fromAnalytics(json: JsonRecord) {
    if (json.automatic === true) {
      return new RankedLeagueBattle('', '', null, null, int(json.trophies), null, true);
    }
    const opponent = record(json.opponent);
    return new RankedLeagueBattle(
      string(opponent.tag),
      string(opponent.name),
      int(json.stars),
      number(json.destructionPercentage),
      int(json.trophies),
      apiDate(json.time),
      false,
      int(opponent.townHallLevel),
      int(json.townHallLevel),
      int(json.duration),
      string(json.shareCode),
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

  withAttackArmies(history: readonly PlayerBattlelogEntry[]): RankedLeagueBattlelog {
    const enrich = (battle: RankedLeagueBattle, attack: boolean) => {
      if (!battle.creationTime || battle.automatic) return battle;
      // Never infer historical TH from today's profile. Match exact time,
      // direction and result; reject conflicting opponent identities.
      const matches = history.filter(
        (entry) =>
          entry.mode === 'ranked' &&
          entry.attack === attack &&
          entry.timestamp?.getTime() === battle.creationTime!.getTime() &&
          entry.stars === battle.stars &&
          entry.destructionPercentage === battle.destructionPercentage &&
          (!entry.opponentTag ||
            !battle.opponentPlayerTag ||
            canonicalTag(entry.opponentTag) === canonicalTag(battle.opponentPlayerTag)),
      );
      const official = matches.filter((entry) => entry.source === 'official');
      const archived = matches.filter((entry) => entry.source === 'history');
      const detail = official.length === 1 ? official[0] : undefined;
      const stored = archived.length === 1 ? archived[0] : undefined;
      if (!detail && !stored) return battle;
      return new RankedLeagueBattle(
        battle.opponentPlayerTag || detail?.opponentTag || '',
        battle.opponentName || detail?.opponentName || '',
        battle.stars,
        battle.destructionPercentage,
        battle.trophies,
        battle.creationTime,
        false,
        battle.opponentTownHallLevel || detail?.opponentTownHall || 0,
        battle.townHallLevel,
        battle.duration || detail?.duration || stored?.duration || 0,
        battle.shareCode || detail?.armyShareCode || stored?.armyShareCode || '',
      );
    };
    return new RankedLeagueBattlelog(
      this.tag,
      this.seasonId,
      this.leagueGroupId,
      this.leagueTierId,
      this.attacksComplete,
      this.defensesComplete,
      this.missingRealAttacks,
      this.missingRealDefenses,
      this.automaticDefensesDerived,
      this.registeredAttacks,
      this.registeredDefenses,
      this.maxAttacks,
      this.maxDefenses,
      this.attacks.map((battle) => enrich(battle, true)),
      this.defenses.map((battle) => enrich(battle, false)),
    );
  }

  // The official group response is scoped to the requested player by playerTag.
  // Archived analytics may not have a membership snapshot for a live period yet.
  static fromOfficialGroup(
    json: JsonRecord,
    playerTag: string,
    group: RankedLeagueGroup,
    leagueTierId: number,
  ): RankedLeagueBattlelog | null {
    const member = group.members.find(
      (entry) => canonicalTag(entry.playerTag) === canonicalTag(playerTag),
    );
    const hasAttacks = Array.isArray(json.attackLogs);
    const hasDefenses = Array.isArray(json.defenseLogs);
    if (!member || (!hasAttacks && !hasDefenses)) return null;
    const attacks = records(json.attackLogs).map(RankedLeagueBattle.fromOfficial);
    const defenses = records(json.defenseLogs).map(RankedLeagueBattle.fromOfficial);
    const attackCount = member.attackWinCount + member.attackLoseCount;
    const defenseCount = member.defenseWinCount + member.defenseLoseCount;
    return new RankedLeagueBattlelog(
      playerTag,
      String(group.seasonId),
      group.tag,
      leagueTierId,
      hasAttacks && attacks.length === attackCount,
      hasDefenses && defenses.length === defenseCount,
      Math.max(0, attackCount - attacks.length),
      Math.max(0, defenseCount - defenses.length),
      false,
      attackCount,
      defenseCount,
      0, // The official group contract does not supply a battle limit.
      0,
      attacks,
      defenses,
    );
  }

  static fromJson(json: JsonRecord) {
    const league = record(json.league);
    const attacks = records(json.attacks);
    const defenses = records(json.defenses);
    const registeredAttacks = int(json.registeredAttacks);
    const registeredDefenses = int(json.registeredDefenses);
    const missingRealAttacks = Math.max(0, registeredAttacks - attacks.length);
    // Automatic defenses are not registered real battles. Counting them here
    // can hide missing logs and incorrectly mark a partial week complete.
    const missingRealDefenses = Math.max(
      0,
      registeredDefenses - defenses.filter((item) => item.automatic !== true).length,
    );
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
  withBattleDetails(entries: readonly PlayerBattlelogEntry[]): RankedLeagueData {
    return new RankedLeagueData(
      this.playerTag,
      this.playerName,
      this.townHallLevel,
      this.trophies,
      this.bestTrophies,
      this.currentTier,
      this.tiers,
      this.history,
      this.currentGroup,
      this.previousGroup,
      this.currentBattlelog?.withAttackArmies(entries) ?? null,
      this.previousBattlelog?.withAttackArmies(entries) ?? null,
    );
  }
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
        ?.maxBattles ?? rankedTierBattleLimit(tierId)
    );
  }
}

/** The public group response omits its cap. Use the live published game-data
 * tier's battle_count only after period-specific logs/history, never a guessed
 * daily Legend cap or an old bundled table. */
function rankedTierBattleLimit(tierId: number): number | null {
  const tiers = Object.values(record(gameDataState.playerLeagueData.leagues));
  const tier = tiers.find((value) => int(record(value)._id) === tierId);
  const limit = int(record(tier).battle_count);
  return limit > 0 ? limit : null;
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

/** Share the same rounded placement counts between Home and the ranked table.
 * group_size is only a capacity check: partially filled groups use their actual
 * membership. For 94 players, 3% promotes 3 and 15% demotes 14 (#81 onward).
 * Round to nearest, rather than flooring or anchoring positions to 100 slots. */
export function rankedGroupCutoffs(tierId: number | undefined, size: number) {
  const tiers = Object.values(record(gameDataState.playerLeagueData.leagues));
  const metadata = tiers.map(record).find((tier) => Number(tier._id) === tierId);
  if (!metadata || !Number.isSafeInteger(size) || size <= 0) return null;
  const maximum = Number(metadata.group_size);
  if (!Number.isSafeInteger(maximum) || maximum <= 0 || size > maximum) return null;
  if (metadata.promote_percentage == null || metadata.demote_percentage == null) return null;
  const promotePercentage = Number(metadata.promote_percentage);
  const demotePercentage = Number(metadata.demote_percentage);
  if (
    !Number.isFinite(promotePercentage) ||
    !Number.isFinite(demotePercentage) ||
    promotePercentage < 0 ||
    demotePercentage < 0 ||
    promotePercentage + demotePercentage > 100
  )
    return null;
  const promotion = Math.round((size * promotePercentage) / 100);
  const demotion = Math.round((size * demotePercentage) / 100);
  return { promotion, demotionStart: size - demotion, demotion };
}

export function rankedPlacementZone(
  tierId: number | undefined,
  size: number,
  rank: number | null,
): 'promotion' | 'demotion' | 'neutral' {
  const cutoffs = rankedGroupCutoffs(tierId, size);
  if (!cutoffs || rank === null || rank < 1 || rank > size) return 'neutral';
  if (rank <= cutoffs.promotion) return 'promotion';
  if (rank > cutoffs.demotionStart) return 'demotion';
  return 'neutral';
}
