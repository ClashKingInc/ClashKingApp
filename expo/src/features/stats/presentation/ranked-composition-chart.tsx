import { useMemo } from 'react';
import { View } from 'react-native';

import { toIntlLocale, useI18n } from '../../../i18n';
import { ckColors } from '../../../ui';
import type { StatsDateFilter, StatsLegendDay } from '../models';
import { AnalyticsLineChart } from './analytics-chart';

export interface RankedCompositionDay {
  readonly date: string;
  readonly sampleSize: number;
  readonly airCount: number;
  readonly groundCount: number;
  readonly mixedCount: number;
  readonly unknownCount: number;
}

const daysInChart = 14;
const dayMs = 86_400_000;
const datePattern = /^\d{4}-\d{2}-\d{2}$/u;

/** The daily closeout and this chart must describe the same Legend attack cohort. */
export function rankedCompositionWindow(
  daily: readonly StatsLegendDay[],
  end: Date,
): readonly { date: string; point?: RankedCompositionDay }[] {
  const observed = new Map<string, RankedCompositionDay>();
  for (const day of daily) {
    const types = day.attackTypes;
    if (!types) continue;
    const counts = [types.air, types.ground, types.mixed, types.unknown];
    if (
      !datePattern.test(day.day) ||
      !Number.isSafeInteger(day.attacks) ||
      day.attacks < 0 ||
      !counts.every((count) => Number.isSafeInteger(count) && count >= 0) ||
      counts.reduce((sum, count) => sum + count, 0) !== day.attacks
    )
      continue;
    observed.set(day.day, {
      date: day.day,
      sampleSize: day.attacks,
      airCount: types.air,
      groundCount: types.ground,
      mixedCount: types.mixed,
      unknownCount: types.unknown,
    });
  }
  const lastDay = Date.UTC(end.getFullYear(), end.getMonth(), end.getDate());
  return Array.from({ length: daysInChart }, (_, index) => {
    const date = new Date(lastDay - (daysInChart - 1 - index) * dayMs).toISOString().slice(0, 10);
    return { date, point: observed.get(date) };
  });
}

export function hasRankedCompositionData(
  daily: readonly StatsLegendDay[],
  dates: StatsDateFilter,
): boolean {
  const firstDay = new Date(
    Date.UTC(dates.start.getFullYear(), dates.start.getMonth(), dates.start.getDate()),
  )
    .toISOString()
    .slice(0, 10);
  return rankedCompositionWindow(daily, dates.end).some(
    ({ date, point }) =>
      date >= firstDay &&
      point !== undefined &&
      point.airCount + point.groundCount + point.mixedCount > 0,
  );
}

export function RankedCompositionChart({
  daily,
  dates,
  exportContext,
}: {
  readonly daily: readonly StatsLegendDay[];
  readonly dates: StatsDateFilter;
  readonly exportContext?: string;
}) {
  const { t, locale } = useI18n();
  const days = useMemo(
    () =>
      rankedCompositionWindow(daily, dates.end).filter(
        ({ date }) =>
          Date.parse(`${date}T00:00:00Z`) >=
          Date.UTC(dates.start.getFullYear(), dates.start.getMonth(), dates.start.getDate()),
      ),
    [daily, dates],
  );
  const count = (value: number) => value.toLocaleString(toIntlLocale(locale));
  const categories = [
    {
      key: 'air',
      label: t('gameItemTargetsAir'),
      color: ckColors.legendBlue,
      count: (day: RankedCompositionDay) => day.airCount,
    },
    {
      key: 'ground',
      label: t('gameItemTargetsGround'),
      color: ckColors.warGold,
      count: (day: RankedCompositionDay) => day.groundCount,
    },
    {
      key: 'mixed',
      label: `${t('gameItemTargetsAir')} + ${t('gameItemTargetsGround')}`,
      color: ckColors.capitalPurple,
      count: (day: RankedCompositionDay) => day.mixedCount,
    },
  ] as const;
  return (
    <View testID="ranked-composition-chart" style={{ gap: 8 }}>
      <AnalyticsLineChart
        title={`${t('gameItemTargetsAir')} + ${t('gameItemTargetsGround')}`}
        exportTitle={
          exportContext
            ? `${t('gameItemTargetsAir')} + ${t('gameItemTargetsGround')} · ${exportContext}`
            : undefined
        }
        percent
        includeZero
        connectGaps={false}
        showPoints
        series={categories.map((category) => ({
          key: category.key,
          label: category.label,
          color: category.color,
          points: days.map(({ date, point }) => {
            const known = point ? point.sampleSize - point.unknownCount : 0;
            return {
              day: date,
              value: point && known > 0 ? (100 * category.count(point)) / known : null,
              weight: known,
            };
          }),
        }))}
        formatPointDetail={(key, date) => {
          const point = days.find((day) => day.date === date)?.point;
          const category = categories.find((item) => item.key === key);
          return point && category
            ? `${count(category.count(point))} / ${count(point.sampleSize - point.unknownCount)} · ${count(point.unknownCount)} ${t('generalUnknown')}`
            : undefined;
        }}
      />
    </View>
  );
}
