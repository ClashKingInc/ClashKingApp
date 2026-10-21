import { warLeaguesByApiId } from '../../../core/game-data/game-data-normalization';
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
    /** Sum of completed war destruction percentages, not the per-war average. */
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
    const leagueId = nullableInt(warLeague.id);
    // Some cached history responses contain a valid league ID but an empty name.
    // Recover from authoritative game data, rather than rendering unknown art.
    const leagueName =
      nullableString(warLeague.name)?.trim() ||
      nullableString(json.league)?.trim() ||
      nullableString(warLeaguesByApiId().get(leagueId ?? -1)?.name);
    const hasStandingObject = isRecord(json.standing);
    return new CwlRankingHistoryEntry(
      string(json.season),
      leagueId,
      leagueName,
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
