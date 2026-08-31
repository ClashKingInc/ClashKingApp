import {
  int,
  isRecord,
  nullableInt,
  nullableString,
  number,
  record,
  string,
  type JsonRecord,
} from './parsing';

export class CwlRankingHistoryEntry {
  constructor(
    readonly season: string,
    readonly leagueId: number | null,
    readonly league: string | null,
    readonly rank: number,
    readonly stars: number,
    readonly destruction: number,
    readonly roundsWon: number,
    readonly roundsTied: number,
    readonly roundsLost: number,
    readonly hasStanding: boolean,
  ) {}
  static fromJson(json: JsonRecord) {
    const standing = record(json.standing);
    const rounds = record(json.rounds);
    const warLeague = record(json.warLeague);
    const hasStandingObject = isRecord(json.standing);
    return new CwlRankingHistoryEntry(
      string(json.season),
      nullableInt(warLeague.id),
      nullableString(warLeague.name ?? json.league),
      int(standing.groupRank, int(json.rank)),
      int(standing.stars, int(json.stars)),
      number(standing.destruction, number(json.destruction)),
      int(standing.wins, int(rounds.won)),
      int(standing.ties, int(rounds.tied)),
      int(standing.losses, int(rounds.lost)),
      hasStandingObject || json.rank != null || json.stars != null || json.destruction != null,
    );
  }
}
