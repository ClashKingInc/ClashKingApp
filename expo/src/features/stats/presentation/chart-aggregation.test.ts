import { aggregateChartSeries, chartBucket } from './chart-aggregation';

test('weekly rates use attack denominators instead of averaging daily percentages', () => {
  const series = [
    {
      key: 'rate',
      label: 'Rate',
      points: [
        { day: '2026-09-14', value: 100, weight: 10 },
        { day: '2026-09-15', value: 0, weight: 90 },
      ],
    },
  ];
  expect(aggregateChartSeries(series, 'week', true)[0]?.points[0]?.value).toBe(10);
});

test('counts sum while missing values stay missing', () => {
  const series = [
    {
      key: 'wars',
      label: 'Wars',
      points: [
        { day: '2026-09-14', value: 10 },
        { day: '2026-09-15', value: 20 },
        { day: '2026-10-01', value: null },
      ],
    },
  ];
  expect(aggregateChartSeries(series, 'month', false)[0]?.points.map((p) => p.value)).toEqual([
    30,
    null,
  ]);
});

test('missing denominators never produce misleading averaged rates', () => {
  const series = [{ key: 'rate', label: 'Rate', points: [{ day: '2026-09-14', value: 50 }] }];
  expect(aggregateChartSeries(series, 'week', true)).toBe(series);
});

test('weeks begin Monday even across year boundaries', () => {
  expect(chartBucket('2026-01-01', 'week')).toBe('2025-12-29');
  expect(chartBucket('2026-09-20', 'week')).toBe('2026-09-14');
});
