import {
  PlayerLegendBattle,
  PlayerLegendBattlelog,
  PlayerLegendLeagueData,
  PlayerLegendRank,
} from '../../player/models';
import { legendSeasonLabel, legendsImageFileName, legendsShareSummary } from './legends-share';

test('uses live and selected-day ranks, season armies, and daily trophy changes', () => {
  const shareCode = 'u2x1-1x2';
  const data = new PlayerLegendLeagueData(
    '#P1',
    'Player',
    18,
    5600,
    5900,
    new PlayerLegendBattlelog(
      '#P1',
      '2026-09-11',
      new Date(),
      new Date(),
      false,
      40,
      -20,
      20,
      [
        new PlayerLegendBattle(
          40,
          false,
          new Date(),
          90,
          18,
          '#O',
          'Opponent',
          18,
          3,
          100,
          shareCode,
        ),
        new PlayerLegendBattle(
          20,
          false,
          new Date(),
          90,
          18,
          '#O2',
          'Opponent 2',
          18,
          2,
          80,
          shareCode,
        ),
      ],
      [new PlayerLegendBattle(-20, true)],
    ),
    [],
    '2026-09-11',
    new PlayerLegendRank('#P1', 'Player', 5600, 42),
    new PlayerLegendRank('#P1', 'Player', 5580, 51),
    [
      new PlayerLegendBattlelog(
        '#P1',
        '2026-09-10',
        new Date(),
        new Date(),
        true,
        30,
        -10,
        20,
        [],
        [],
      ),
      new PlayerLegendBattlelog(
        '#P1',
        '2026-09-11',
        new Date(),
        new Date(),
        false,
        40,
        -20,
        20,
        [],
        [],
      ),
    ],
    [shareCode, shareCode],
  );

  expect(legendsShareSummary(data)).toMatchObject({
    currentRank: 42,
    historicalRank: 51,
    favoriteArmy: shareCode,
    favoriteArmyUses: 2,
    battleChanges: [
      { key: '2026-09-10', change: 20 },
      { key: '2026-09-11', change: 20 },
    ],
    dailyContributions: [
      { key: '2026-09-10', change: 20, attackTrophies: 30 },
      { key: '2026-09-11', change: 20, attackTrophies: 40 },
    ],
    graph: [],
  });
});

test('formats the real season window without inventing one', () => {
  expect(legendSeasonLabel('2026-08-31T05:00:00.000Z', '2026-09-28T05:00:00.000Z')).toBe(
    'Aug 31 – Sep 28',
  );
  expect(legendSeasonLabel(null, null)).toBe('Current season');
});

test('builds a stable Legends PNG filename', () => {
  expect(legendsImageFileName('Matt! King', new Date(2026, 8, 11, 9, 5, 4))).toBe(
    'legends_Matt_King_2026-09-11_09-05-04.png',
  );
});
