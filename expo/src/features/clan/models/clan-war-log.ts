import { ApiClient } from '../../../core/api/client';
import { WarInfoSnapshot } from '../../player/models';
import { ClanBadgeUrls } from './clan-core';
import {
  apiDateOrEpoch,
  int,
  number,
  record,
  records,
  roundTo,
  string,
  type JsonRecord,
} from './parsing';

export class ClanDetails {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly badgeUrls: ClanBadgeUrls,
    readonly clanLevel: number,
    readonly attacks: number,
    readonly stars: number,
    readonly destructionPercentage: number,
    readonly expEarned: number,
  ) {}
  static fromJson(json: JsonRecord) {
    return new ClanDetails(
      string(json.tag),
      string(json.name),
      ClanBadgeUrls.fromJson(json.badgeUrls),
      int(json.clanLevel),
      int(json.attacks),
      int(json.stars),
      number(json.destructionPercentage),
      int(json.expEarned),
    );
  }
}

export class WarLogDetails {
  constructor(
    readonly result: string,
    readonly clanTag: string,
    readonly endTime: Date,
    readonly teamSize: number,
    readonly attacksPerMember: number,
    readonly clan: ClanDetails,
    readonly opponent: ClanDetails,
  ) {}
  static fromJson(json: JsonRecord, clanTag: string) {
    return new WarLogDetails(
      string(json.result),
      clanTag,
      apiDateOrEpoch(json.endTime),
      int(json.teamSize),
      int(json.attacksPerMember, 1),
      ClanDetails.fromJson(record(json.clan)),
      ClanDetails.fromJson(record(json.opponent)),
    );
  }
}

export class WarLogStats {
  constructor(
    readonly totalWins: number,
    readonly totalLosses: number,
    readonly totalTies: number,
    readonly totalWars: number,
    readonly averageMembers: number,
    readonly averageClanDestruction: number,
    readonly averageClanStarsPerMember: number,
    readonly averageOpponentDestruction: number,
    readonly averageOpponentStarsPerMember: number,
    readonly averageAttacksPerMember: number,
    readonly winPercentage: string,
    readonly lossPercentage: string,
    readonly tiePercentage: string,
    readonly averageDestructionDifference: number,
    readonly averageClanStarsPercentage: number,
    readonly averageOpponentStarsPercentage: number,
  ) {}

  static empty() {
    return new WarLogStats(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0', '0', '0', 0, 0, 0);
  }
}

export class ClanWarLog {
  private stats: WarLogStats | null = null;

  constructor(
    readonly items: readonly WarLogDetails[],
    readonly clanTag: string,
    readonly wars: readonly WarInfoSnapshot[] = [],
    readonly isPrivate = false,
    readonly reconstructed = false,
  ) {}

  static fromJson(json: JsonRecord, clanTag: string): ClanWarLog {
    const rawItems = records(json.items);
    const items = rawItems
      .filter((item) => strictWarDate(item.endTime).getUTCFullYear() >= 2022)
      .map((item) => WarLogDetails.fromJson(item, clanTag));
    const wars = rawItems.map((item) =>
      WarInfoSnapshot.fromJson({
        ...item,
        state: 'warEnded',
        warType: item.warType ?? (string(item.result) ? 'random' : 'friendly'),
      }),
    );
    return new ClanWarLog(
      items,
      clanTag,
      wars,
      json.isPrivate === true,
      json.reconstructed === true,
    );
  }

  get warLogStats(): WarLogStats {
    return this.stats ?? WarLogStats.empty();
  }

  set warLogStats(value: WarLogStats) {
    this.stats = value;
  }
}

export function analyzeWarLogs(warLogs: readonly WarLogDetails[]): WarLogStats {
  let totalWins = 0;
  let totalLosses = 0;
  let totalTies = 0;
  let totalWars = 0;
  let totalMembers = 0;
  let totalAttacks = 0;
  let clanTotalDestruction = 0;
  let clanTotalStars = 0;
  let opponentTotalDestruction = 0;
  let opponentTotalStars = 0;
  let maxPossibleStars = 0;

  for (const log of warLogs) {
    if (log.attacksPerMember !== 2) continue;
    totalWars += 1;
    if (log.result === 'win') totalWins += 1;
    if (log.result === 'lose') totalLosses += 1;
    if (log.result === 'tie') totalTies += 1;
    maxPossibleStars += log.teamSize * 3;
    totalMembers += log.teamSize;
    totalAttacks += log.clan.attacks;
    clanTotalDestruction += log.clan.destructionPercentage;
    clanTotalStars += log.clan.stars;
    opponentTotalDestruction += log.opponent.destructionPercentage;
    opponentTotalStars += log.opponent.stars;
  }

  const averageMembers = totalWars ? totalMembers / totalWars : 0;
  const averageClanDestruction = totalWars ? clanTotalDestruction / totalWars : 0;
  const averageOpponentDestruction = totalWars ? opponentTotalDestruction / totalWars : 0;
  return new WarLogStats(
    totalWins,
    totalLosses,
    totalTies,
    totalWars,
    Math.round(averageMembers),
    roundTo(averageClanDestruction, 0),
    roundTo(totalMembers ? clanTotalStars / totalMembers : 0, 1),
    roundTo(averageOpponentDestruction, 0),
    roundTo(totalMembers ? opponentTotalStars / totalMembers : 0, 1),
    roundTo(totalMembers ? totalAttacks / totalMembers : 0, 1),
    (totalWars ? (totalWins / totalWars) * 100 : 0).toFixed(0),
    (totalWars ? (totalLosses / totalWars) * 100 : 0).toFixed(0),
    (totalWars ? (totalTies / totalWars) * 100 : 0).toFixed(0),
    roundTo(averageClanDestruction - averageOpponentDestruction, 1),
    roundTo(maxPossibleStars ? (clanTotalStars / maxPossibleStars) * 100 : 0, 1),
    roundTo(maxPossibleStars ? (opponentTotalStars / maxPossibleStars) * 100 : 0, 1),
  );
}

export class WarLogStatsService {
  static analyzeWarLogs(warLogs: readonly WarLogDetails[]): Promise<WarLogStats> {
    return Promise.resolve(analyzeWarLogs(warLogs));
  }
}

export class WarLogService {
  static async fetchWarLogData(
    api: ApiClient,
    tag: string,
    options: { isWarLogPublic: boolean },
  ): Promise<ClanWarLog> {
    const endpoint = options.isWarLogPublic
      ? `/clans/${encodeURIComponent(tag)}/warlog?limit=50`
      : `/clan/${encodeURIComponent(tag)}/warlog?limit=50`;
    const response = options.isWarLogPublic
      ? await api.proxyGet(endpoint)
      : await api.get(endpoint, { requiresAuth: true });
    const parsed: unknown = JSON.parse(response.bodyText);
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed))
      throw new TypeError('Invalid war log response.');
    const result = ClanWarLog.fromJson(parsed as JsonRecord, tag);
    result.warLogStats = analyzeWarLogs(result.items);
    return result;
  }
}

function strictWarDate(value: unknown): Date {
  const date = apiDateOrEpoch(value);
  if (date.getTime() === 0 && String(value) !== '1970-01-01T00:00:00.000Z')
    throw new RangeError(`Invalid war endTime: ${String(value)}`);
  return date;
}
