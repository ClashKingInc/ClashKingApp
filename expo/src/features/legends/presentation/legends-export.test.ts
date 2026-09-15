import {
  PlayerLegendBattle,
  PlayerLegendBattlelog,
  PlayerLegendHistoryEntry,
  PlayerLegendLeagueData,
} from '../../player/models';
import { legendsCsv, legendsExportFileName } from './legends-export';

test('exports current Legend battles and completed season history', () => {
  const battle = new PlayerLegendBattle(
    40,
    false,
    new Date('2026-09-11T12:00:00Z'),
    90,
    18,
    '#OPP',
    'Opponent, One',
    18,
    3,
    100,
    null,
  );
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
      0,
      40,
      [battle],
      [],
    ),
    [new PlayerLegendHistoryEntry('2026-08', 1, 'Legend League', 5800, 200, 190, 123)],
  );

  const csv = legendsCsv(data);
  expect(csv).toContain('battle,2026-09-11T12:00:00.000Z,attack,#OPP,"Opponent, One",3,100,90,40');
  expect(csv).toContain('season,2026-08,,,,,,,5800,200,190,123');
});

test('builds a stable Legends export filename', () => {
  expect(legendsExportFileName('Matt! King', new Date(2026, 8, 11, 9, 5, 4))).toBe(
    'legends_Matt_King_2026-09-11_09-05-04.csv',
  );
});
