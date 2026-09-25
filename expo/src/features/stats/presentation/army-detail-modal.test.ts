import {
  armyDetailTimeQuery,
  armyUsageRate,
  formatArmyPlayerCount,
} from './army-detail-modal';

test('uses inclusive date labels so the API applies Legend-day boundaries', () => {
  expect(armyDetailTimeQuery(new Date(2026, 8, 1), new Date(2026, 8, 28))).toEqual({
    'time[after]': '2026-09-01',
    'time[before]': '2026-09-28',
  });
  expect(armyDetailTimeQuery(new Date(2026, 8, 20), new Date(2026, 8, 20))).toEqual({
    'time[after]': '2026-09-20',
    'time[before]': '2026-09-20',
  });
});

test('calculates army usage against all recorded Legend attacks', () => {
  expect(armyUsageRate(250, 1000)).toBe(0.25);
  expect(armyUsageRate(10, 0)).toBe(0);
});

test('keeps unavailable multi-day player counts distinct from zero players', () => {
  expect(formatArmyPlayerCount(null, 'en', 'Unknown')).toBe('Unknown');
  expect(formatArmyPlayerCount(0, 'en', 'Unknown')).toBe('0');
  expect(formatArmyPlayerCount(1234, 'en', 'Unknown')).toBe('1,234');
});
