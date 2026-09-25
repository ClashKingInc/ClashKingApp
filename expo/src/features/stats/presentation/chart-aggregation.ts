import type { AnalyticsSeries } from './analytics-chart';
import type { ChartGranularity } from './stats-chart-preferences';

export function chartBucket(day: string, granularity: ChartGranularity): string {
  if (granularity === 'day' || day.length !== 10) return day;
  if (granularity === 'month') return day.slice(0, 7);
  const date = new Date(`${day}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() - ((date.getUTCDay() + 6) % 7));
  return date.toISOString().slice(0, 10);
}

/** Percentage points must carry their actual denominator; never average daily rates equally. */
export function aggregateChartSeries(
  series: readonly AnalyticsSeries[],
  granularity: ChartGranularity,
  percent: boolean,
): readonly AnalyticsSeries[] {
  if (granularity === 'day' || series.some((line) => line.points.some((p) => p.day.length !== 10)))
    return series;
  if (
    percent &&
    series.some((line) =>
      line.points.some(
        (p) => p.value != null && (p.weight == null || !Number.isFinite(p.weight) || p.weight <= 0),
      ),
    )
  )
    return series;
  return series.map((line) => {
    const buckets = new Map<string, { sum: number; weight: number; count: number }>();
    const dates = line.points.map((point) => point.day).sort();
    if (dates.length) {
      const cursor = new Date(`${dates[0]}T00:00:00Z`);
      const last = dates[dates.length - 1]!;
      while (cursor.toISOString().slice(0, 10) <= last) {
        buckets.set(chartBucket(cursor.toISOString().slice(0, 10), granularity), {
          sum: 0,
          weight: 0,
          count: 0,
        });
        cursor.setUTCDate(cursor.getUTCDate() + 1);
      }
    }
    for (const point of line.points) {
      const day = chartBucket(point.day, granularity);
      const bucket = buckets.get(day) ?? { sum: 0, weight: 0, count: 0 };
      if (point.value != null && Number.isFinite(point.value)) {
        const weight = percent ? point.weight! : 1;
        bucket.sum += point.value * weight;
        bucket.weight += weight;
        bucket.count++;
      }
      buckets.set(day, bucket);
    }
    return {
      ...line,
      points: [...buckets]
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([day, b]) => ({
          day,
          value: b.count ? (percent ? b.sum / b.weight : b.sum) : null,
          weight: b.weight,
        })),
    };
  });
}
