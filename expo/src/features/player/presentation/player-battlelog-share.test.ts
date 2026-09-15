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

test('summarizes exactly 30 UTC calendar days ending today across all loot resources', () => {
  const first = entry('2026-09-10', 1_000_000);
  const second = entry('2026-09-11', 2_000_000, 2);
  const summary = battlelogShareSummary([first, second], new Date('2026-09-11T23:59:59.000Z'));
  expect(summary).toMatchObject({
    attackCount: 2,
    totalLoot: first.totalLoot + second.totalLoot,
  });
  expect(summary.lootTimeline).toHaveLength(30);
  expect(summary.lootTimeline.slice(-2)).toEqual([
    {
      day: '2026-09-10',
      gold: 1_000_000,
      elixir: 500_000,
      darkElixir: 1_000,
      total: 1_501_000,
      intensity: 0.75,
    },
    {
      day: '2026-09-11',
      gold: 2_000_000,
      elixir: 1_000_000,
      darkElixir: 1_000,
      total: 3_001_000,
      intensity: 1,
    },
  ]);
});

test('uses the selected mode in a stable PNG filename', () => {
  expect(battlelogImageFileName('Matt! King', 'farming', new Date(2026, 8, 11, 9, 5, 4))).toBe(
    'battlelog_farming_Matt_King_2026-09-11_09-05-04.png',
  );
});

test('uses combined daily loot intensity and includes zero-value days', () => {
  const first = entry('2026-09-10', 1_000_000);
  const second = entry('2026-09-11', 2_000_000);
  const timeline = battlelogLootTimeline([first, second], new Date('2026-09-11T12:00:00Z'));
  expect(timeline[0]).toMatchObject({ day: '2026-08-13', total: 0, intensity: 0 });
  expect(timeline.slice(-2)).toMatchObject([
    { day: '2026-09-10', total: 1_501_000, intensity: 0.75 },
    { day: '2026-09-11', total: 3_001_000, intensity: 1 },
  ]);
});
