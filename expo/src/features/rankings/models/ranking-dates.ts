import { RankingBoard, type RankingBoardValue } from './ranking-models';

/** Capital archives are Monday snapshots; other ranking archives are daily. */
export function isRankingSnapshotDate(board: RankingBoardValue, date: Date): boolean {
  return board !== RankingBoard.clanCapital || date.getDay() === 1;
}

export function rankingSnapshotOnOrBefore(board: RankingBoardValue, date: Date): Date {
  const day = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  if (board === RankingBoard.clanCapital) day.setDate(day.getDate() - ((day.getDay() + 6) % 7));
  return day;
}

export function previousRankingDate(board: RankingBoardValue, date: Date): Date {
  const previous = new Date(date.getFullYear(), date.getMonth(), date.getDate() - 1);
  return rankingSnapshotOnOrBefore(board, previous);
}

export function nextRankingDate(board: RankingBoardValue, date: Date, today: Date): Date {
  const next = new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate() + (board === RankingBoard.clanCapital ? 7 : 1),
  );
  // The live board remains reachable after the latest archived Monday.
  return next > today ? today : next;
}
