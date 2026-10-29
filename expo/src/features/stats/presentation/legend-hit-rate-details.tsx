import { useMemo } from 'react';
import { StyleSheet, View } from 'react-native';
import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import { CKText, MobileWebImage, ckColors, colorWithAlpha, useCKTheme } from '../../../ui';
import type { LegendDayPerformance } from '../data/stats-repository';
import { StatsDateFilter } from '../models';
import { RankedCompositionChart, hasRankedCompositionData } from './ranked-composition-chart';
import { AnalyticsLineChart } from './analytics-chart';

type Side = 'offense' | 'defense';
const sides = ['offense', 'defense'] as const;
const colors = { offense: ckColors.donationGreen, defense: ckColors.lossRed };

/** Restore the battle detail independently of complete-day statistics. Current
 * observations belong here, but never contribute to the perfect-day denominator. */
export function LegendHitRateDetails({
  data,
  dates,
}: {
  data: LegendDayPerformance;
  dates: StatsDateFilter;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const number = useMemo(
    () => new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 2 }),
    [locale],
  );
  const rate = useMemo(
    () =>
      new Intl.NumberFormat(toIntlLocale(locale), { style: 'percent', maximumFractionDigits: 1 }),
    [locale],
  );
  const period = data.periods.find((item) => item.kind === 'selected');
  if (!period) return null;
  const totals = Object.fromEntries(
    sides.map((side) => {
      const closed = period[side],
        today = data.currentDay?.[side];
      const count = closed.observedBattles + (today?.battles ?? 0);
      const mean = (field: 'averageStars' | 'averageDestruction' | 'averageDuration') => {
        const rows = [
          { value: closed[field], count: closed.observedBattles },
          { value: today?.[field], count: today?.battles ?? 0 },
        ].filter(
          (row): row is { value: number; count: number } => row.value != null && row.count > 0,
        );
        const weight = rows.reduce((sum, row) => sum + row.count, 0);
        return weight ? rows.reduce((sum, row) => sum + row.value * row.count, 0) / weight : null;
      };
      return [
        side,
        {
          count,
          knownStars: [...(closed.starCounts ?? []), ...(today?.starCounts ?? [])].reduce(
            (sum, value) => sum + value,
            0,
          ),
          stars: Array.from(
            { length: 4 },
            (_, star) => (closed.starCounts?.[star] ?? 0) + (today?.starCounts?.[star] ?? 0),
          ),
          averageStars: mean('averageStars'),
          averageDestruction: mean('averageDestruction'),
          averageDuration: mean('averageDuration'),
        },
      ];
    }),
  ) as Record<
    Side,
    {
      count: number;
      knownStars: number;
      stars: number[];
      averageStars: number | null;
      averageDestruction: number | null;
      averageDuration: number | null;
    }
  >;
  const entries: {
    label: string;
    field: 'averageStars' | 'averageDestruction' | 'averageDuration';
    format: (value: number) => string;
  }[] = [
    {
      label: t('statsAverageStars'),
      field: 'averageStars',
      format: (value) => number.format(value),
    },
    {
      label: t('statsAverageDestruction'),
      field: 'averageDestruction',
      format: (value) => `${number.format(value)}%`,
    },
    {
      label: t('warAttacksDetailsDuration'),
      field: 'averageDuration',
      format: (value) => {
        const seconds = Math.round(value);
        return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
      },
    },
  ];
  // The existing army chart uses only classified armies, exactly as before.
  // An absent composition stays unknown; it cannot be inferred from an attack result.
  const armyDays = [
    ...data.items.map((item) => ({
      day: item.day,
      metrics: item.offense,
      count: item.offense.observedBattles,
    })),
    ...(data.currentDay
      ? [
          {
            day: data.currentDay.day,
            metrics: data.currentDay.offense,
            count: data.currentDay.offense.battles,
          },
        ]
      : []),
  ]
    .filter((item) => item.metrics.attackTypes)
    .map(({ day, metrics, count }) => ({ day, attacks: count, attackTypes: metrics.attackTypes }));
  const icon = (side: Side) => (
    <MobileWebImage
      imageUrl={side === 'offense' ? ImageAssets.sword : ImageAssets.shield}
      contentFit="contain"
      style={{ width: 20, height: 20 }}
    />
  );
  return (
    <>
      <View style={[styles.card, { backgroundColor: theme.surface }]}>
        <View style={styles.row}>
          <View style={styles.label} />
          {sides.map((side) => (
            <View key={side} style={styles.value}>
              {icon(side)}
            </View>
          ))}
        </View>
        {entries.map((entry) => (
          <View key={entry.field} style={styles.row}>
            <CKText role="bodySmall" muted style={styles.label}>
              {entry.label}
            </CKText>
            {sides.map((side) => (
              <CKText key={side} role="bodyMedium" style={styles.value}>
                {totals[side][entry.field] == null ? '—' : entry.format(totals[side][entry.field]!)}
              </CKText>
            ))}
          </View>
        ))}
      </View>
      <View style={[styles.card, { backgroundColor: theme.surface }]}>
        <CKText role="titleMedium">{t('statsStarRates')}</CKText>
        {[2, 1, 0].map((star) => (
          <View key={star} style={styles.row}>
            <View style={styles.starLabel}>
              <CKText role="bodyMedium">{star}</CKText>
              <MobileWebImage
                imageUrl={ImageAssets.attackStar}
                contentFit="contain"
                style={{ width: 18, height: 18 }}
              />
            </View>
            {sides.map((side) => {
              const fraction = totals[side].knownStars
                ? totals[side].stars[star]! / totals[side].knownStars
                : null;
              return (
                <View key={side} style={{ flex: 1, gap: 6 }}>
                  <CKText role="bodyMedium" style={{ textAlign: 'right', color: colors[side] }}>
                    {fraction == null ? '—' : rate.format(fraction)}
                  </CKText>
                  <View
                    style={{
                      height: 4,
                      borderRadius: 2,
                      backgroundColor: colorWithAlpha(colors[side], 0.1),
                    }}
                  >
                    <View
                      style={{
                        height: 4,
                        borderRadius: 2,
                        width: `${100 * (fraction ?? 0)}%`,
                        backgroundColor: colors[side],
                      }}
                    />
                  </View>
                </View>
              );
            })}
          </View>
        ))}
      </View>
      <View style={[styles.card, { backgroundColor: theme.surface }]}>
        <AnalyticsLineChart
          title={`${t('capitalDetailsOffense')} · ${t('statsStarRates')}`}
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
            points: [
              ...data.items.map((item) => ({
                day: item.day,
                metrics: item.offense,
                count: item.offense.observedBattles,
              })),
              ...(data.currentDay
                ? [
                    {
                      day: data.currentDay.day,
                      metrics: data.currentDay.offense,
                      count: data.currentDay.offense.battles,
                    },
                  ]
                : []),
            ].map(({ day, metrics, count }) => ({
              day,
              value: metrics.starCounts && count ? (metrics.starCounts[star]! / count) * 100 : null,
              weight: count,
            })),
          }))}
        />
      </View>
      {hasRankedCompositionData(armyDays, dates) ? (
        <View style={[styles.card, { backgroundColor: theme.surface }]}>
          <RankedCompositionChart daily={armyDays} dates={dates} />
        </View>
      ) : null}
    </>
  );
}
const styles = StyleSheet.create({
  card: { padding: 16, borderRadius: 24, gap: 16 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 16 },
  label: { flex: 1.7 },
  value: { flex: 1, textAlign: 'center', alignItems: 'center' },
  starLabel: { width: 42, flexDirection: 'row', alignItems: 'center', gap: 5 },
});
