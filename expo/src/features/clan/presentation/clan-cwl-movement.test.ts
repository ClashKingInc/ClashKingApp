import { CwlRankingHistoryEntry } from '../models';
import { cwlLeagueAccent, cwlMovement } from './clan-statistics-tabs';

function entry(season: string, leagueId: number | null) {
  return new CwlRankingHistoryEntry(season, leagueId, null, 0, 0, 0, 0, 0, 0, false);
}

describe('CWL history movement', () => {
  it('compares the newest season with the current clan league', () => {
    expect(cwlMovement([entry('2026-08', 10)], 0, 11)).toBe('up');
    expect(cwlMovement([entry('2026-08', 10)], 0, 10)).toBeNull();
  });

  it('skips duplicate records from the same month before comparing leagues', () => {
    const entries = [entry('2026-08-15', 12), entry('2026-08-01', 11), entry('2026-07-01', 10)];
    expect(cwlMovement(entries, 1, 13)).toBeNull();
    expect(cwlMovement(entries, 2, 13)).toBe('up');
  });

  it('uses distinct Flutter-style league accents for CWL history cards', () => {
    expect(cwlLeagueAccent('Champion League I')).toBe('#FF8A2B');
    expect(cwlLeagueAccent('Crystal League II')).toBe('#8C63FF');
    expect(cwlLeagueAccent('Gold League III')).toBe('#FFC83D');
  });
});
