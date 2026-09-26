import { analyticsChartDays, chartSelectionIndex } from './analytics-chart';

test('scrubbing selects nearest date and clamps outside plot bounds', () => {
  expect(chartSelectionIndex(-100, 360, 10)).toBe(0);
  expect(chartSelectionIndex(500, 360, 10)).toBe(9);
  expect(chartSelectionIndex(200, 360, 3)).toBe(1);
  expect(chartSelectionIndex(50, 0, 3)).toBe(0);
});

test('missing calendar dates remain available to scrubbing without invented values', () => {
  expect(
    analyticsChartDays([
      {
        key: 'a',
        label: 'A',
        points: [
          { day: '2026-09-15', value: 50 },
          { day: '2026-09-17', value: 60 },
        ],
      },
    ]),
  ).toEqual(['2026-09-15', '2026-09-16', '2026-09-17']);
});

test('monthly histories remain monthly', () => {
  expect(
    analyticsChartDays([
      {
        key: 'a',
        label: 'A',
        points: [
          { day: '2026-08', value: 50 },
          { day: '2026-09', value: 60 },
        ],
      },
    ]),
  ).toEqual(['2026-08', '2026-09']);
});
