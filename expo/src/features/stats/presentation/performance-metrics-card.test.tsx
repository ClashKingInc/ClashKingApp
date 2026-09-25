import { fireEvent, render } from '@testing-library/react-native';
import { View } from 'react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { StatsDailyPoint, StatsMetrics } from '../models';
import {
  buildPerformanceTrendSeries,
  PerformanceMetricsCard,
  PerformanceMetricsTrend,
} from './performance-metrics-card';

function Harness({ children }: { readonly children: React.ReactNode }) {
  return (
    <I18nProvider locale="en">
      <CKThemeProvider preference="light">{children}</CKThemeProvider>
    </I18nProvider>
  );
}

function daily(date: string, sampleSize: number, threeStarRate: number) {
  return new StatsDailyPoint(date, sampleSize, 2.1, 82, 0.1, 0.15, 0.25, threeStarRate);
}

function metrics({
  available = true,
  sampleSize = 120,
  dailyPoints = [],
  averageDestruction = 84.6,
}: {
  readonly available?: boolean;
  readonly sampleSize?: number;
  readonly dailyPoints?: readonly StatsDailyPoint[];
  readonly averageDestruction?: number;
} = {}) {
  return new StatsMetrics(
    available,
    sampleSize,
    2.18,
    averageDestruction,
    0.08,
    0.15,
    0.35,
    0.42,
    dailyPoints,
  );
}

test('does not present zero samples as a perfect result', async () => {
  const view = await render(
    <Harness>
      <PerformanceMetricsCard title="Attacks" metrics={metrics({ sampleSize: 0 })} />
    </Harness>,
  );

  expect(view.getByText('No data available.')).toBeTruthy();
  expect(view.queryByTestId('performance-three-star-rate')).toBeNull();
  expect(view.queryByText('42.0%')).toBeNull();
});

test('emphasizes three-star rate once and renders earned and empty star artwork', async () => {
  const view = await render(
    <Harness>
      <PerformanceMetricsCard title="Attacks" metrics={metrics()} />
    </Harness>,
  );

  expect(view.getByTestId('performance-three-star-rate')).toHaveTextContent('42.0%');
  expect(view.getAllByText('42.0%')).toHaveLength(1);
  expect(view.getByText('120')).toBeTruthy();

  const earned = view.getByTestId('performance-star-1-0', { includeHiddenElements: true });
  const empty = view.getByTestId('performance-star-1-1', { includeHiddenElements: true });
  expect(
    view.getAllByTestId(/^performance-star-\d-\d$/, { includeHiddenElements: true }),
  ).toHaveLength(12);
  expect(earned.props.style).not.toMatchObject({ opacity: 0.55 });
  expect(empty.props.style).toMatchObject({ opacity: 0.55 });
});

test('sorts daily points, excludes missing samples, and breaks the line across gaps', () => {
  const series = buildPerformanceTrendSeries([
    daily('2026-09-03', 30, 0.6),
    daily('2026-09-02', 0, 1),
    daily('2026-09-01', 10, 0.2),
  ]);

  expect(series.points.map((point) => point.date)).toEqual(['2026-09-01', '2026-09-03']);
  expect(series.segments.map((segment) => segment.map((point) => point.date))).toEqual([
    ['2026-09-01'],
    ['2026-09-03'],
  ]);
  expect(series.yTicks[0]).toBeGreaterThan(0);
  expect(series.firstDate).toBe('2026-09-01');
  expect(series.lastDate).toBe('2026-09-03');
});

test('keeps destruction on its 0 to 100 scale and omits repeated detail when compact', async () => {
  const view = await render(
    <Harness>
      <PerformanceMetricsCard
        compact
        extra={<View testID="season-extra" />}
        metrics={metrics({
          averageDestruction: 1,
          dailyPoints: [daily('2026-09-01', 10, 0.2)],
        })}
        title="Season"
      />
    </Harness>,
  );

  expect(view.getByText('1.00%')).toBeTruthy();
  expect(view.queryByText('Star rates')).toBeNull();
  expect(view.queryByText('Daily trend')).toBeNull();
  expect(view.queryByTestId('performance-star-row-0')).toBeNull();
  expect(view.getByTestId('season-extra')).toBeTruthy();
});

test('selects the latest trend point by default and exposes every point for selection', async () => {
  const trendMetrics = metrics({
    dailyPoints: [daily('2026-09-03', 30, 0.6), daily('2026-09-01', 10, 0.2)],
  });
  const view = await render(
    <Harness>
      <PerformanceMetricsTrend metrics={trendMetrics} />
    </Harness>,
  );

  expect(view.getByTestId('performance-trend-selection').props.accessibilityLabel).toContain(
    'Sep 3, 60.0%, 30 Attacks',
  );

  await fireEvent.press(view.getByTestId('performance-trend-point-2026-09-01'));

  expect(view.getByTestId('performance-trend-selection').props.accessibilityLabel).toContain(
    'Sep 1, 20.0%, 10 Attacks',
  );
});

test('does not renormalize low percentage trend values', async () => {
  const view = await render(
    <Harness>
      <PerformanceMetricsTrend
        metrics={metrics({
          dailyPoints: [daily('2026-09-01', 10, 0.01), daily('2026-09-02', 12, 0.005)],
        })}
      />
    </Harness>,
  );

  expect(view.getByTestId('performance-trend-selection').props.accessibilityLabel).toContain(
    'Sep 2, 0.50%, 12 Attacks',
  );

  await fireEvent.press(view.getByTestId('performance-trend-point-2026-09-01'));

  expect(view.getByTestId('performance-trend-selection').props.accessibilityLabel).toContain(
    'Sep 1, 1.00%, 10 Attacks',
  );
});
