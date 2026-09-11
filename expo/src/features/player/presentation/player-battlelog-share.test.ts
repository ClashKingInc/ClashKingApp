import { PlayerBattlelogEntry } from '../models';
import {
  battlelogImageFileName,
  battlelogLootTimeline,
  battlelogShareSummary,
} from './player-battlelog-share';

function entry(day: string, gold: number, stars = 3) {
  return new PlayerBattlelogEntry(
    day,
    'farming',
    'history',
    true,
    '#OPP',
    'Opponent',
    18,
    stars,
    100,
    gold,
    gold / 2,
    1_000,
    new Date(`${day}T12:00:00.000Z`),
    90,
    '',
    {},
  );
}

test('summarizes only the selected battlelog entries with independently scaled loot timelines', () => {
  const first = entry('2026-09-10', 1_000_000);
  const second = entry('2026-09-11', 2_000_000, 2);
  const summary = battlelogShareSummary([first, second]);
  expect(summary).toMatchObject({
    battleCount: 2,
    attackCount: 2,
    totalLoot: first.totalLoot + second.totalLoot,
    tripleRate: 50,
  });
  expect(summary.lootTimelines.gold.slice(-2)).toEqual([
    { day: '2026-09-10', value: 1_000_000, intensity: 0.5 },
    { day: '2026-09-11', value: 2_000_000, intensity: 1 },
  ]);
  expect(summary.lootTimelines.darkElixir.slice(-2).map((day) => day.intensity)).toEqual([1, 1]);
});

test('uses the selected mode in a stable PNG filename', () => {
  expect(battlelogImageFileName('Matt! King', 'farming', new Date(2026, 8, 11, 9, 5, 4))).toBe(
    'battlelog_farming_Matt_King_2026-09-11_09-05-04.png',
  );
});

test('keeps unlike loot resources on independent contribution scales', () => {
  const first = entry('2026-09-10', 1_000_000);
  const second = entry('2026-09-11', 2_000_000);
  expect(battlelogLootTimeline([first, second], 'gold').slice(-2)).toMatchObject([
    { day: '2026-09-10', value: 1_000_000, intensity: 0.5 },
    { day: '2026-09-11', value: 2_000_000, intensity: 1 },
  ]);
  expect(battlelogLootTimeline([first, second], 'elixir').slice(-2)).toMatchObject([
    { value: 500_000, intensity: 0.5 },
    { value: 1_000_000, intensity: 1 },
  ]);
  expect(battlelogLootTimeline([first, second], 'darkElixir').slice(-2)).toMatchObject([
    { value: 1_000, intensity: 1 },
    { value: 1_000, intensity: 1 },
  ]);
});
