import { apiDate, int, record, string, type JsonRecord } from './parsing';

export class PlayerLegendHistoryEntry {
  constructor(
    readonly season: string,
    readonly leagueId: number | null,
    readonly leagueName: string | null,
    readonly trophies: number,
    readonly attackWins: number,
    readonly defenseWins: number,
    readonly rank: number,
    readonly population: number | null = null,
    readonly seasonStart: Date | null = null,
    readonly seasonEnd: Date | null = null,
    readonly leagueNamespace: 'legacy' | 'tier' | null = null,
    readonly leagueIconUrls: Readonly<Record<string, string>> | null = null,
  ) {}

  static fromJson(json: JsonRecord) {
    const league = json.league == null ? null : record(json.league);
    const icons = record(league?.iconUrls);
    const leagueIconUrls = Object.fromEntries(
      ['tiny', 'small', 'medium', 'large'].flatMap((key) =>
        typeof icons[key] === 'string' ? [[key, icons[key]]] : [],
      ),
    );
    return new PlayerLegendHistoryEntry(
      string(json.season),
      league && int(league.id) > 0 ? int(league.id) : null,
      league ? string(league.name) || null : null,
      int(json.trophies),
      int(json.attackWins),
      int(json.defenseWins),
      int(json.rank),
      json.population == null ? null : int(json.population),
      apiDate(json.seasonStart),
      apiDate(json.seasonEnd),
      league?.namespace === 'legacy' || league?.namespace === 'tier' ? league.namespace : null,
      Object.keys(leagueIconUrls).length ? leagueIconUrls : null,
    );
  }
}
