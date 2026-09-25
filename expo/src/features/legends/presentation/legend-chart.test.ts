import {
  formatLegendChartValue,
  legendChartPlotLeft,
  legendChartSegments,
  legendChartY,
} from './legend-chart';

test('formats rank labels as one readable string', () => {
  expect(formatLegendChartValue(1204, true)).toBe('#1,204');
  expect(formatLegendChartValue(5602, false)).toBe('5,602');
});

test('widens the plot gutter so long export rank labels stay inside the canvas', () => {
  expect(legendChartPlotLeft([1, 617_284, 1_234_567], true, 17)).toBeGreaterThanOrEqual(112);
  expect(legendChartPlotLeft([5500, 5600], false, 14)).toBeLessThan(60);
});

test('breaks the line at null snapshots without joining across the gap', () => {
  expect(
    legendChartSegments([
      { day: '2026-09-01', value: 5500 },
      { day: '2026-09-02', value: 5520 },
      { day: '2026-09-03', value: null },
      { day: '2026-09-04', value: 5540 },
    ]),
  ).toEqual([[0, 1], [3]]);
});

test('plots better ranks and higher trophy counts toward the top', () => {
  expect(legendChartY(1, 1, 100, true, 150)).toBeLessThan(legendChartY(100, 1, 100, true, 150));
  expect(legendChartY(5600, 5500, 5600, false, 150)).toBeLessThan(
    legendChartY(5500, 5500, 5600, false, 150),
  );
});
