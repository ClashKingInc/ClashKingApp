import { canMoveToNextLegendDay, legendDayOffset } from './legend-day';

test('moves selected Legend days across month boundaries in UTC', () => {
  expect(legendDayOffset('2026-09-01', -1)).toBe('2026-08-31');
  expect(legendDayOffset('2026-09-30', 1)).toBe('2026-10-01');
});

test('allows forward navigation only before the current Legend day', () => {
  expect(canMoveToNextLegendDay('2026-09-10', '2026-09-11')).toBe(true);
  expect(canMoveToNextLegendDay('2026-09-11', '2026-09-11')).toBe(false);
  expect(canMoveToNextLegendDay('2026-09-12', '2026-09-11')).toBe(false);
});
