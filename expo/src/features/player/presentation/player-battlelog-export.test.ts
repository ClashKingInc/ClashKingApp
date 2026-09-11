import { PlayerBattlelogEntry } from '../models';
import { playerBattlelogCsv, playerBattlelogExportFileName } from './player-battlelog-export';

test('exports the selected battlelog data as a stable CSV', () => {
  const entry = new PlayerBattlelogEntry(
    'battle-1',
    'legend',
    'history',
    true,
    '#OPP',
    'Opponent, One',
    18,
    3,
    100,
    1_000_000,
    900_000,
    8_000,
    new Date('2026-09-11T01:02:03.000Z'),
    87,
    'https://link.clashofclans.com/?army=u1x1',
    {},
  );

  expect(playerBattlelogCsv([entry])).toBe(
    'battle_mode,direction,battle_time,opponent_tag,opponent_name,opponent_town_hall,stars,destruction_percentage,duration_seconds,gold,elixir,dark_elixir,army_share_code\n' +
      'legend,attack,2026-09-11T01:02:03.000Z,#OPP,"Opponent, One",18,3,100,87,1000000,900000,8000,https://link.clashofclans.com/?army=u1x1\n',
  );
});

test('uses the selected mode and a filesystem-safe player name', () => {
  expect(
    playerBattlelogExportFileName('Matt! King', 'farming', new Date(2026, 8, 11, 9, 5, 4)),
  ).toBe('battlelog_farming_Matt_King_2026-09-11_09-05-04.csv');
});
