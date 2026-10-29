import { useMemo } from 'react';
import { StyleSheet, View } from 'react-native';
import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import { CKText, MobileWebImage, ckColors, useCKTheme } from '../../../ui';
import type { LegendDayPerformance } from '../data/stats-repository';
import { StatsDateFilter } from '../models';
import { RankedCompositionChart, hasRankedCompositionData } from './ranked-composition-chart';
import { AnalyticsLineChart } from './analytics-chart';

const sides = ['offense', 'defense'] as const;
const averageFields = ['averageStars', 'averageDestruction', 'averageDuration'] as const;

/** Keep battle averages and complete-day percentages separate. The current day
 * participates in these battle-weighted averages, never in perfect-day totals. */
export function LegendHitRateDetails({
  data,
  dates,
  section,
}: {
  data: LegendDayPerformance;
  dates: StatsDateFilter;
  section: 'summary' | 'charts';
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const format = useMemo(
    () => new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 2 }),
    [locale],
  );
  const period = data.periods.find((item) => item.kind === 'selected');
  if (!period) return null;
  const summaries = sides.map((side) => {
    const closed = period[side],
      today = data.currentDay?.[side];
    return averageFields.map((field) => {
      const rows = [
        { value: closed[field], count: closed.observedBattles },
        { value: today?.[field], count: today?.battles ?? 0 },
      ].filter(
        (row): row is { value: number; count: number } => row.value != null && row.count > 0,
      );
      const weight = rows.reduce((sum, row) => sum + row.count, 0);
      return weight ? rows.reduce((sum, row) => sum + row.value * row.count, 0) / weight : null;
    });
  });
  if (section === 'summary') {
    const labels = [
      t('statsAverageStars'),
      t('statsAverageDestruction'),
      t('warAttacksDetailsDuration'),
    ];
    return (
      <View style={styles.summary}>
        <View style={styles.row}>
          <View style={styles.label} />
          {sides.map((side) => (
            <View key={side} style={styles.value}>
              <MobileWebImage
                imageUrl={side === 'offense' ? ImageAssets.sword : ImageAssets.shield}
                contentFit="contain"
                style={{ width: 18, height: 18 }}
              />
            </View>
          ))}
        </View>
        {labels.map((label, index) => (
          <View key={label} style={styles.row}>
            <CKText role="bodySmall" muted style={styles.label}>
              {label}
            </CKText>
            {sides.map((side, sideIndex) => {
              const value = summaries[sideIndex]![index];
              const seconds = Math.round(value ?? 0);
              const text =
                value == null
                  ? '—'
                  : index === 2
                    ? `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`
                    : `${format.format(value)}${index === 1 ? '%' : ''}`;
              return (
                <CKText key={side} role="bodyMedium" style={styles.value}>
                  {text}
                </CKText>
              );
            })}
          </View>
        ))}
      </View>
    );
  }
  // Adapt only fields used by the existing composition chart. Do not invent
  // player counts or infer missing compositions from battle results.
  const observations = [
    ...data.items.map((item) => ({ day: item.day, offense: item.offense, defense: item.defense })),
    ...(data.currentDay ? [data.currentDay] : []),
  ];
  const armyDays = observations
    .filter((item) => item.offense.attackTypes)
    .map((item) => ({
      day: item.day,
      attacks:
        'observedBattles' in item.offense ? item.offense.observedBattles : item.offense.battles,
      attackTypes: item.offense.attackTypes,
    }));
  return (
    <View style={styles.charts}>
      {sides.map((side) => (
        <View key={side} style={[styles.card, { backgroundColor: theme.surface }]}>
          <AnalyticsLineChart
            title={`${t(side === 'offense' ? 'capitalDetailsOffense' : 'capitalDetailsDefense')} · ${t('statsStarRates')}`}
            percent
            includeZero
            connectGaps={false}
            responsiveAxes
            legendMode="labels"
            series={[3, 2, 1, 0].map((star, index) => ({
              key: `star-${star}`,
              label: `${star} ★`,
              color: [
                ckColors.warGold,
                ckColors.legendBlue,
                ckColors.lossRed,
                theme.onSurfaceVariant,
              ][index],
              aggregation: 'weightedMean',
              points: observations.map((item) => {
                const metrics = item[side],
                  count = 'observedBattles' in metrics ? metrics.observedBattles : metrics.battles;
                return {
                  day: item.day,
                  value:
                    metrics.starCounts && count ? (metrics.starCounts[star]! / count) * 100 : null,
                  weight: count,
                };
              }),
            }))}
          />
        </View>
      ))}
      {hasRankedCompositionData(armyDays, dates) ? (
        <View style={[styles.card, { backgroundColor: theme.surface }]}>
          <RankedCompositionChart daily={armyDays} dates={dates} />
        </View>
      ) : null}
    </View>
  );
}
const styles = StyleSheet.create({
  summary: { gap: 11, paddingTop: 4 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 16 },
  label: { flex: 1.7 },
  value: { flex: 1, textAlign: 'center', alignItems: 'center', fontVariant: ['tabular-nums'] },
  charts: { gap: 18 },
  card: { padding: 20, borderRadius: 26, gap: 16 },
});
