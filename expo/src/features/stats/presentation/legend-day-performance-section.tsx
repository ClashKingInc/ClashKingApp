import { useEffect, useMemo, useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, View } from 'react-native';
import Svg, { Polyline } from 'react-native-svg';
import type { ContractApiService } from '../../../core/api/contract-api';
import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  ErrorState,
  MobileWebImage,
  ProfileTabs,
  SelectionPicker,
  ckColors,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { SlidingSegmentControl } from '../../../ui/sliding-segment-control';
import { StatsRepository, type LegendDayPerformance } from '../data/stats-repository';
import {
  StatsDateFilter,
  StatsLegendCohort,
  StatsLegendQuery,
  type StatsLegendCohortValue,
} from '../models';
import { AnalyticsLineChart } from './analytics-chart';
import { StatsChartFrame } from './stats-chart-frame';

type Side = 'offense' | 'defense';
type Summary = LegendDayPerformance['periods'][number]['offense'];

export function LegendDayPerformanceSection({
  api,
  dates,
}: {
  readonly api: ContractApiService;
  readonly dates: StatsDateFilter;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const repository = useMemo(() => new StatsRepository(api), [api]);
  const [cohort, setCohort] = useState<StatsLegendCohortValue>(StatsLegendCohort.legend);
  const [side, setSide] = useState<Side>('offense');
  const [view, setView] = useState<'distribution' | 'trend'>('distribution');
  const [reload, setReload] = useState(0);
  const [state, setState] = useState<{ data?: LegendDayPerformance; error?: unknown }>({});
  const first = StatsDateFilter.formatDate(dates.start),
    last = StatsDateFilter.formatDate(dates.end);
  useEffect(() => {
    let active = true;
    setState({});
    // Ignore late responses after a cohort/date change or navigation. The
    // repository deduplicates bounded requests and caches by the exact range.
    void repository
      .loadLegendPerformance(
        new StatsLegendQuery(
          new StatsDateFilter(new Date(`${first}T12:00:00`), new Date(`${last}T12:00:00`)),
          cohort,
        ),
        reload > 0,
      )
      .then(
        (data) => {
          if (active) setState({ data });
        },
        (error) => {
          if (active) setState({ error });
        },
      );
    return () => {
      active = false;
    };
  }, [repository, first, last, cohort, reload]);
  const format = useMemo(
    () => new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 1 }),
    [locale],
  );
  const percentFormat = useMemo(
    () =>
      new Intl.NumberFormat(toIntlLocale(locale), { style: 'percent', maximumFractionDigits: 1 }),
    [locale],
  );
  const dateFormat = useMemo(
    () =>
      new Intl.DateTimeFormat(toIntlLocale(locale), {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
      }),
    [locale],
  );
  const percent = (value: number | null) => (value === null ? '—' : percentFormat.format(value));
  const selected = state.data?.periods.find((period) => period.kind === 'selected');
  const summary = selected?.[side];
  const unique =
    side === 'offense' ? selected?.perfectOffensePlayers : selected?.perfectedDefensePlayers;
  const cohortLabel =
    cohort === StatsLegendCohort.legend
      ? t('statsLegendLeagueOne')
      : t('rankingsTopCount', { count: cohort === StatsLegendCohort.top200 ? 200 : 1000 });
  const gainLabel = t(side === 'offense' ? 'legendTrophiesGained' : 'legendTrophiesLost');
  return (
    <View style={styles.section} testID="legend-day-performance">
      <CKText role="titleMedium" skeleton={false}>
        {t('legendPerformanceTitle')}
      </CKText>
      <SelectionPicker
        title={t('gameLeague')}
        accessibilityLabel={t('gameLeague')}
        fillWidth
        options={[
          StatsLegendCohort.legend,
          StatsLegendCohort.top1000,
          StatsLegendCohort.top200,
        ].map((key) => ({
          key,
          label:
            key === StatsLegendCohort.legend
              ? t('statsLegendLeagueOne')
              : t('rankingsTopCount', { count: key === StatsLegendCohort.top200 ? 200 : 1000 }),
          icon: (
            <MobileWebImage
              imageUrl={ImageAssets.legendLeagueOne}
              style={{ width: 28, height: 28 }}
              contentFit="contain"
            />
          ),
        }))}
        selectedKey={cohort}
        onSelect={setCohort}
      />
      <SlidingSegmentControl
        value={side}
        isRtl={isRtl}
        onChange={setSide}
        options={[
          { value: 'offense', label: t('capitalDetailsOffense') },
          { value: 'defense', label: t('capitalDetailsDefense') },
        ]}
      />
      {state.error ? (
        <ErrorState
          title={t('sideStatsLoadError')}
          body={t('statsNoDataBody')}
          actionLabel={t('generalRetry')}
          onAction={() => setReload((value) => value + 1)}
        />
      ) : !state.data ? (
        <ActivityIndicator color={theme.primary} />
      ) : !selected || selected.availableDays === 0 || !summary ? (
        <EmptyState
          title={t('statsNoDataTitle')}
          body={t('statsNoDataBody')}
          actionLabel={t('generalRetry')}
          onAction={() => setReload((value) => value + 1)}
        />
      ) : (
        <>
          <View style={styles.metrics}>
            <Metric
              label={t('legendPerfectDays')}
              value={percent(summary.perfectDayRate)}
              detail={`${format.format(summary.perfectPlayerDays)} / ${format.format(summary.completePlayerDays)}`}
            />
            <Metric
              label={t(side === 'offense' ? 'legendsAvgOffense' : 'legendsAvgDefense')}
              value={summary.meanTrophies === null ? '—' : format.format(summary.meanTrophies)}
              detail={gainLabel}
            />
            <Metric
              label={t('statsPlayers')}
              value={unique == null ? '—' : format.format(unique)}
              detail={t('legendPerfectDays')}
            />
          </View>
          <CKText role="bodySmall" style={{ color: theme.onSurfaceVariant }}>
            {t('legendAvailableDays')}: {format.format(selected.availableDays)} /{' '}
            {format.format(selected.expectedDays)}
          </CKText>
          <CKText role="bodySmall" style={{ color: theme.onSurfaceVariant }}>
            {t('legendCompleteOnly')}
          </CKText>
          <View style={styles.coverage}>
            <CKText role="bodySmall">
              {t('legendCompleteDays')}: {format.format(summary.completePlayerDays)}
            </CKText>
            <CKText role="bodySmall">
              {t('legendPartialDays')}: {format.format(summary.partialPlayerDays)}
            </CKText>
            <CKText role="bodySmall">
              {t('legendMissingDays')}: {format.format(summary.missingPlayerDays)}
            </CKText>
            {summary.invalidPlayerDays > 0 ? (
              <CKText role="bodySmall">
                {t('legendInvalidDays')}: {format.format(summary.invalidPlayerDays)}
              </CKText>
            ) : null}
          </View>
          <ProfileTabs
            variant="underline"
            overflow="fit"
            selectedKey={view}
            onSelect={(value) => setView(value as typeof view)}
            tabs={[
              { key: 'distribution', label: t('legendDistribution') },
              { key: 'trend', label: t('statsDailyTrend') },
            ]}
          />
          {view === 'distribution' ? (
            <StatsChartFrame
              title={`${t('legendDistribution')} · ${cohortLabel}`}
              copyPlacement="footer"
            >
              <CKText role="bodySmall" style={{ color: theme.onSurfaceVariant }}>
                {dateFormat.format(new Date(`${first}T12:00:00`))} –{' '}
                {dateFormat.format(new Date(`${last}T12:00:00`))} · {gainLabel}
              </CKText>
              {summary.completePlayerDays === 0 ? (
                <CKText muted>{t('statsNoDataTitle')}</CKText>
              ) : (
                <Distribution
                  data={state.data}
                  side={side}
                  summary={summary}
                  percent={percent}
                  format={format}
                />
              )}
            </StatsChartFrame>
          ) : (
            <>
              <AnalyticsLineChart
                title={gainLabel}
                includeZero
                connectGaps={false}
                series={[
                  {
                    key: 'mean',
                    aggregation: 'weightedMean',
                    label: gainLabel,
                    points: state.data.items.map((item) => ({
                      day: item.day,
                      value: item[side].meanTrophies,
                      weight: item[side].completePlayerDays,
                    })),
                  },
                ]}
              />
              <AnalyticsLineChart
                title={t('legendPerfectDays')}
                percent
                includeZero
                connectGaps={false}
                series={[
                  {
                    key: 'perfect',
                    label: t('legendPerfectDays'),
                    points: state.data.items.map((item) => ({
                      day: item.day,
                      value: item[side].perfectDayRate,
                      weight: item[side].completePlayerDays,
                    })),
                  },
                ]}
              />
            </>
          )}
          <CKText role="titleSmall">
            {t('legendPerfectSources')} · {t('statsLegendLeagueOne')}
          </CKText>
          {state.data.perfectDayContributions.map((row) => {
            const count = side === 'offense' ? row.offensePlayerDays : row.defensePlayerDays;
            const total = state.data!.perfectDayContributions.reduce(
              (sum, item) =>
                sum + (side === 'offense' ? item.offensePlayerDays : item.defensePlayerDays),
              0,
            );
            return (
              <View key={row.rankBand} style={styles.rankRow}>
                <CKText>
                  #
                  {row.rankBand === '1_200'
                    ? `${format.format(1)}–${format.format(200)}`
                    : row.rankBand === '201_1000'
                      ? `${format.format(201)}–${format.format(1000)}`
                      : `${format.format(1001)}+`}
                </CKText>
                <CKText>
                  {format.format(count)} · {percent(total === 0 ? null : count / total)}
                </CKText>
              </View>
            );
          })}
        </>
      )}
    </View>
  );
}

function Metric({ label, value, detail }: { label: string; value: string; detail: string }) {
  const theme = useCKTheme();
  return (
    <View style={styles.metric}>
      <CKText role="titleMedium">{value}</CKText>
      <CKText role="bodySmall">{label}</CKText>
      <CKText role="bodySmall" style={{ color: theme.onSurfaceVariant }}>
        {detail}
      </CKText>
    </View>
  );
}

function Distribution({
  data,
  side,
  summary,
  percent,
  format,
}: {
  data: LegendDayPerformance;
  side: Side;
  summary: Summary;
  percent: (value: number | null) => string;
  format: Intl.NumberFormat;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [selectedBucket, setSelectedBucket] = useState(15);
  const comparisons = data.periods.filter((period) => period.kind !== 'selected');
  const drawableComparisons = comparisons.filter((period) => period[side].completePlayerDays > 0);
  const max = Math.max(
    0.1,
    ...[summary, ...comparisons.map((period) => period[side])].flatMap((item) =>
      item.buckets.map((bucket) => bucket.share ?? 0),
    ),
  );
  const bucket = summary.buckets[selectedBucket];
  const range = (minimum: number, maximum: number) =>
    `${format.format(minimum)}–${format.format(maximum)}`;
  return (
    <View style={{ gap: 12 }}>
      <View style={styles.chartRow}>
        <View style={styles.axis}>
          <CKText role="bodySmall" style={{ color: theme.onSurfaceVariant }}>
            {percent(max)}
          </CKText>
          <CKText role="bodySmall" style={{ color: theme.onSurfaceVariant }}>
            {percent(0)}
          </CKText>
        </View>
        <View style={{ flex: 1, height: 176 }}>
          <View style={styles.bars}>
            {summary.buckets.map((value, index) => (
              <Pressable
                key={value.minimum}
                style={styles.barTouch}
                onPress={() => setSelectedBucket(index)}
                accessibilityRole="button"
                accessibilityState={{ selected: index === selectedBucket }}
                accessibilityLabel={`${range(value.minimum, value.maximum)} · ${t('legendCompleteDays')}: ${format.format(value.playerDays)} · ${percent(value.share)}`}
              >
                <View
                  style={{
                    height: Math.max(1, ((value.share ?? 0) / max) * 168),
                    width: '100%',
                    borderRadius: 3,
                    backgroundColor:
                      index === selectedBucket
                        ? theme.primary
                        : colorWithAlpha(ckColors.legendBlue, 0.7),
                  }}
                />
              </Pressable>
            ))}
          </View>
          <Svg
            pointerEvents="none"
            viewBox="0 0 320 176"
            preserveAspectRatio="none"
            style={StyleSheet.absoluteFill}
          >
            {drawableComparisons.map((period) => (
              <Polyline
                key={period.kind}
                fill="none"
                stroke={period.kind === 'previous_30' ? theme.onSurface : theme.onSurfaceVariant}
                strokeOpacity={period.kind === 'previous_30' ? 0.8 : 0.45}
                strokeWidth={2}
                strokeDasharray={period.kind === 'previous_30' ? '5 4' : undefined}
                points={period[side].buckets
                  .map((value, i) => `${i * 20 + 10},${176 - ((value.share ?? 0) / max) * 168}`)
                  .join(' ')}
              />
            ))}
          </Svg>
        </View>
      </View>
      <View style={[styles.axisLabels, { marginStart: 42 }]}>
        {[0, 80, 160, 240, 320].map((value) => (
          <CKText key={value} role="bodySmall" style={{ color: theme.onSurfaceVariant }}>
            {format.format(value)}
          </CKText>
        ))}
      </View>
      {bucket ? (
        <CKText accessibilityLiveRegion="polite">
          {range(bucket.minimum, bucket.maximum)} · {format.format(bucket.playerDays)}{' '}
          {t('legendCompleteDays')} · {percent(bucket.share)}
        </CKText>
      ) : null}
      {comparisons.map((period) => (
        <View key={period.kind} style={styles.rankRow}>
          <CKText role="bodySmall" style={{ color: theme.onSurfaceVariant }}>
            {t('legendPreviousDays', { count: period.expectedDays })}
            {period[side].completePlayerDays > 0
              ? period.kind === 'previous_30'
                ? ' ┄'
                : ' —'
              : ''}
          </CKText>
          <CKText role="bodySmall" style={{ color: theme.onSurfaceVariant }}>
            {t('legendAvailableDays')}: {format.format(period.availableDays)}/{period.expectedDays}
          </CKText>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  section: { gap: 14, marginBottom: 28 },
  metrics: { flexDirection: 'row', flexWrap: 'wrap', gap: 16 },
  metric: { flexGrow: 1, flexBasis: 90, gap: 3 },
  coverage: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  rankRow: { flexDirection: 'row', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' },
  chartRow: { flexDirection: 'row', gap: 8, paddingTop: 12 },
  axis: { width: 34, justifyContent: 'space-between' },
  bars: { height: 176, flexDirection: 'row', alignItems: 'flex-end', direction: 'ltr' },
  barTouch: { flex: 1, height: '100%', justifyContent: 'flex-end', paddingHorizontal: 1 },
  axisLabels: { flexDirection: 'row', justifyContent: 'space-between', direction: 'ltr' },
});
