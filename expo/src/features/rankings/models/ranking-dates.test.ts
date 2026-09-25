import { RankingBoard } from './ranking-models';
import { isRankingSnapshotDate, nextRankingDate, previousRankingDate } from './ranking-dates';

test('Capital moves through Mondays and returns from the latest Monday to Current', () => {
  const today = new Date(2026, 8, 23);
  expect(previousRankingDate(RankingBoard.clanCapital, today)).toEqual(new Date(2026, 8, 21));
  expect(previousRankingDate(RankingBoard.clanCapital, new Date(2026, 8, 21))).toEqual(
    new Date(2026, 8, 14),
  );
  expect(nextRankingDate(RankingBoard.clanCapital, new Date(2026, 8, 14), today)).toEqual(
    new Date(2026, 8, 21),
  );
  expect(nextRankingDate(RankingBoard.clanCapital, new Date(2026, 8, 21), today)).toEqual(today);
  expect(previousRankingDate(RankingBoard.clanCapital, new Date(2026, 8, 7))).toEqual(
    new Date(2026, 7, 31),
  );
});

test('Capital permits only Mondays while other boards retain daily dates', () => {
  for (let day = 20; day < 27; day++) {
    expect(isRankingSnapshotDate(RankingBoard.clanCapital, new Date(2026, 8, day))).toBe(
      day === 21,
    );
    expect(isRankingSnapshotDate(RankingBoard.playerHome, new Date(2026, 8, day))).toBe(true);
  }
  expect(previousRankingDate(RankingBoard.playerBuilder, new Date(2026, 8, 23))).toEqual(
    new Date(2026, 8, 22),
  );
});
