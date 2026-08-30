import {
  bool,
  dateOrEpoch,
  nullableString,
  record,
  records,
  string,
  type JsonRecord,
} from './parsing';

export const ClanLeaderboardType = {
  homeVillage: 'clan_home_points',
  builderBase: 'clan_builder_base_points',
  clanCapital: 'clan_capital_points',
} as const;
export type ClanLeaderboardTypeValue =
  (typeof ClanLeaderboardType)[keyof typeof ClanLeaderboardType];

export class ClanLeaderboardLocation {
  constructor(
    readonly id: number,
    readonly name: string,
    readonly isCountry: boolean,
    readonly countryCode: string | null,
  ) {}
  static fromJson(json: JsonRecord) {
    return new ClanLeaderboardLocation(
      historyInt(json.id),
      string(json.name),
      bool(json.isCountry),
      nullableString(json.countryCode),
    );
  }
}

export class ClanLeaderboardHistoryEntry {
  constructor(
    readonly date: Date,
    readonly rank: number,
    readonly points: number,
    readonly members: number,
    readonly location: ClanLeaderboardLocation | null,
  ) {}
  static fromJson(json: JsonRecord) {
    const location = record(json.location);
    return new ClanLeaderboardHistoryEntry(
      dateOrEpoch(json.date),
      historyInt(json.rank),
      historyInt(json.clanPoints ?? json.builderBasePoints ?? json.capitalPoints),
      historyInt(json.members),
      Object.keys(location).length ? ClanLeaderboardLocation.fromJson(location) : null,
    );
  }
}

export class ClanLeaderboardHistory {
  constructor(readonly items: readonly ClanLeaderboardHistoryEntry[]) {}
  static fromJson(json: JsonRecord) {
    return new ClanLeaderboardHistory(
      records(json.items).map(ClanLeaderboardHistoryEntry.fromJson),
    );
  }
}

export class ClanLeaderboardSeasonSummary {
  constructor(
    readonly season: string,
    readonly after: Date,
    readonly before: Date,
    readonly daysInTop200: number,
    readonly bestRank: number,
    readonly peakPoints: number,
  ) {}
  static fromJson(json: JsonRecord) {
    return new ClanLeaderboardSeasonSummary(
      string(json.season),
      dateOrEpoch(json.after),
      dateOrEpoch(json.before),
      historyInt(json.daysInTop200),
      historyInt(json.bestRank),
      historyInt(json.peakPoints),
    );
  }
}

export class ClanLeaderboardHistorySummary {
  constructor(readonly seasons: readonly ClanLeaderboardSeasonSummary[]) {}
  static fromJson(json: JsonRecord) {
    return new ClanLeaderboardHistorySummary(
      records(json.seasons).map(ClanLeaderboardSeasonSummary.fromJson),
    );
  }
}

export class ClanLegendHistoryEntry {
  constructor(
    readonly season: string,
    readonly tag: string,
    readonly name: string,
    readonly expLevel: number,
    readonly trophies: number,
    readonly attackWins: number,
    readonly defenseWins: number,
    readonly rank: number,
  ) {}
  static fromJson(json: JsonRecord) {
    return new ClanLegendHistoryEntry(
      string(json.season),
      string(json.tag),
      string(json.name),
      historyInt(json.expLevel),
      historyInt(json.trophies),
      historyInt(json.attackWins),
      historyInt(json.defenseWins),
      historyInt(json.rank),
    );
  }
}

export class ClanLegendHistory {
  constructor(readonly items: readonly ClanLegendHistoryEntry[]) {}
  static fromJson(json: JsonRecord) {
    return new ClanLegendHistory(records(json.items).map(ClanLegendHistoryEntry.fromJson));
  }
}

export class ClanLegendSeasonSummary {
  constructor(
    readonly season: string,
    readonly after: Date,
    readonly before: Date,
    readonly playerCount: number,
  ) {}
  static fromJson(json: JsonRecord) {
    return new ClanLegendSeasonSummary(
      string(json.season),
      dateOrEpoch(json.after),
      dateOrEpoch(json.before),
      historyInt(json.playerCount),
    );
  }
}

export class ClanLegendHistorySummary {
  constructor(
    readonly seasons: readonly ClanLegendSeasonSummary[],
    readonly topFinishes: readonly ClanLegendHistoryEntry[],
  ) {}
  static fromJson(json: JsonRecord) {
    return new ClanLegendHistorySummary(
      records(json.seasons).map(ClanLegendSeasonSummary.fromJson),
      records(json.topFinishes).map(ClanLegendHistoryEntry.fromJson),
    );
  }
}

export class ClanRecord {
  constructor(
    readonly value: number,
    readonly time: Date,
  ) {}
  static fromJson(json: JsonRecord) {
    return new ClanRecord(historyInt(json.value), dateOrEpoch(json.time));
  }
}

export class ClanRecords {
  constructor(
    readonly clanPoints: ClanRecord | null,
    readonly warWinStreak: ClanRecord | null,
  ) {}
  static fromJson(json: JsonRecord) {
    const points = record(json.clanPoints);
    const streak = record(json.warWinStreak);
    return new ClanRecords(
      Object.keys(points).length ? ClanRecord.fromJson(points) : null,
      Object.keys(streak).length ? ClanRecord.fromJson(streak) : null,
    );
  }
  get isEmpty() {
    return this.clanPoints === null && this.warWinStreak === null;
  }
}

export type ClanProfileChangeType = 'clanLevel' | 'description' | 'unknown';

export class ClanProfileChange {
  constructor(
    readonly time: Date,
    readonly type: ClanProfileChangeType,
    readonly previous: unknown,
    readonly current: unknown,
  ) {}
  static fromJson(json: JsonRecord) {
    const type = string(json.type);
    return new ClanProfileChange(
      dateOrEpoch(json.time),
      type === 'clanLevel' || type === 'description' ? type : 'unknown',
      json.previous,
      json.current,
    );
  }
}

export class ClanProfileHistory {
  constructor(readonly items: readonly ClanProfileChange[]) {}
  static fromJson(json: JsonRecord) {
    return new ClanProfileHistory(records(json.items).map(ClanProfileChange.fromJson));
  }
}

export function clanLeaderboardApiValue(type: ClanLeaderboardTypeValue): string {
  return type;
}

function historyInt(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  const parsed = Number.parseInt(String(value ?? ''), 10);
  return Number.isNaN(parsed) ? 0 : parsed;
}
