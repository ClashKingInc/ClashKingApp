import { currentLegendSeasonStart } from './legend-season-window';

test('uses official v2 tournament anchors rather than calendar months', () => {
  expect(currentLegendSeasonStart(['v2-2026-09-07T05:00:00Z'], '2026-09-21')).toBe('2026-09-07');
  expect(currentLegendSeasonStart(['v2-2026-09-07T05:00:00Z'], '2026-10-05')).toBe('2026-10-05');
  expect(currentLegendSeasonStart(['2026-09', 'invalid'], '2026-09-21')).toBeNull();
});
