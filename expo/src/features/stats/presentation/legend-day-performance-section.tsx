import { useEffect, useMemo, useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, View } from 'react-native';
import Svg, { Line, Polyline } from 'react-native-svg';
import { ChevronDown, ChevronUp } from 'lucide-react-native';
import type { ContractApiService } from '../../../core/api/contract-api';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  ErrorState,
  ProfileTabs,
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
type Availability = { firstDay: string; lastDay: string };

export function LegendDayPerformanceSection({
  api,
  dates,
  cohort,
  onShowLatest,
  onAvailability,
}: {
  readonly api: ContractApiService;
  readonly dates: StatsDateFilter;
  readonly cohort: StatsLegendCohortValue;
  readonly onShowLatest?: (availability: Availability) => void;
  readonly onAvailability?: (availability: Availability) => void;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const repository = useMemo(() => new StatsRepository(api), [api]);
  const [side, setSide] = useState<Side>('offense');
  const [view, setView] = useState<'distribution' | 'trend'>('distribution');
  const [reload, setReload] = useState(0);
  const [coverageOpen, setCoverageOpen] = useState(false);
  const [result, setResult] = useState<{
    key: string;
    repository: StatsRepository;
    data?: LegendDayPerformance;
    error?: unknown;
  } | null>(null);
  const first = StatsDateFilter.formatDate(dates.start),
    last = StatsDateFilter.formatDate(dates.end);
  const requestKey = `${first}:${last}:${cohort}:${reload}`;
  // Derive loading from the requested identity. Resetting state in an effect
  // adds a render and can briefly expose data from the previous selection.
  const state =
    result?.key === requestKey && result.repository === repository
      ? result
      : { data: undefined, error: undefined };
  useEffect(() => {
    let active = true;
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
          if (active) setResult({ key: requestKey, repository, data });
        },
        (error) => {
          if (active) setResult({ key: requestKey, repository, error });
        },
      );
    return () => {
      active = false;
    };
  }, [repository, first, last, cohort, reload, requestKey]);
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
  const perfectLabel = t(side === 'offense' ? 'legendPerfectDays' : 'legendPerfectedDefenseDays');
  const availability = state.data?.availability;
  useEffect(() => {
    if (availability) onAvailability?.(availability);
  }, [availability, onAvailability]);
  const latestLabel = availability
    ? dateFormat.format(new Date(`${availability.lastDay}T12:00:00`))
    : undefined;
  return (
    <View style={styles.section} testID="legend-day-performance">
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
        <View style={{ gap: 10 }}>
          <EmptyState
            title={t('statsNoDataTitle')}
            body={t('statsNoDataBody')}
            actionLabel={
              availability && onShowLatest ? t('statsViewLatestData') : t('generalRetry')
            }
            onAction={() =>
              availability && onShowLatest
                ? onShowLatest(availability)
                : setReload((value) => value + 1)
            }
          />
          {latestLabel ? (
            <CKText role="bodySmall" muted style={{ textAlign: 'center' }}>
              {t('statsLatestAvailableDate', { date: latestLabel })}
            </CKText>
          ) : null}
        </View>
      ) : (
        <>
          <View style={styles.headline}>
            <CKText
              role="heroMetric"
              style={{ color: side === 'offense' ? ckColors.donationGreen : ckColors.lossRed }}
            >
              {percent(summary.perfectDayRate)}
            </CKText>
            <CKText role="bodyLarge">{perfectLabel}</CKText>
            <CKText role="bodySmall" muted>
              {format.format(summary.perfectPlayerDays)} /{' '}
              {format.format(summary.completePlayerDays)} {t('legendCompleteDays')}
            </CKText>
          </View>
          <View style={styles.metrics}>
            <Metric
              label={t(side === 'offense' ? 'legendsAvgOffense' : 'legendsAvgDefense')}
              value={summary.meanTrophies === null ? '—' : format.format(summary.meanTrophies)}
              detail={gainLabel}
            />
            <Metric
              label={t('statsPlayers')}
              value={unique == null ? '—' : format.format(unique)}
              detail={perfectLabel}
            />
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
              title={`${gainLabel} · ${cohortLabel} · ${dateFormat.format(new Date(`${first}T12:00:00`))} – ${dateFormat.format(new Date(`${last}T12:00:00`))}`}
              showTitle={false}
              copyPlacement="footer"
            >
              <CKText role="bodySmall" muted>
                {gainLabel}
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
                exportTitle={`${gainLabel} · ${cohortLabel} · ${first} – ${last}`}
                includeZero
                connectGaps={false}
                responsiveAxes
                series={[
                  {
                    key: 'mean',
                    aggregation: 'weightedMean',
                    label: gainLabel,
                    color: side === 'offense' ? ckColors.donationGreen : ckColors.lossRed,
                    points: state.data.items.map((item) => ({
                      day: item.day,
                      value: item[side].meanTrophies,
                      weight: item[side].completePlayerDays,
                    })),
                  },
                ]}
              />
              <AnalyticsLineChart
                title={perfectLabel}
                exportTitle={`${perfectLabel} · ${cohortLabel} · ${first} – ${last}`}
                percent
                includeZero
                connectGaps={false}
                responsiveAxes
                series={[
                  {
                    key: 'perfect',
                    label: perfectLabel,
                    color: ckColors.warGold,
                    // The analytics plot consumes percentages on a 0–100 scale;
                    // the canonical API rate is a fraction and retains its day count.
                    points: state.data.items.map((item) => ({
                      day: item.day,
                      value:
                        item[side].perfectDayRate === null ? null : item[side].perfectDayRate * 100,
                      weight: item[side].completePlayerDays,
                    })),
                  },
                ]}
              />
            </>
          )}
          <View style={{ gap: 12 }}>
            <CKText role="bodyMedium">
              {side === 'offense' ? t('legendPerfectSources') : perfectLabel} ·{' '}
              {t('statsLegendLeagueOne')}
            </CKText>
            {state.data.perfectDayContributions.map((row) => {
              const count = side === 'offense' ? row.offensePlayerDays : row.defensePlayerDays;
              const total = state.data!.perfectDayContributions.reduce(
                (sum, item) =>
                  sum + (side === 'offense' ? item.offensePlayerDays : item.defensePlayerDays),
                0,
              );
              const share = total > 0 ? count / total : null;
              return (
                <View key={row.rankBand} style={styles.rankRow}>
                  <CKText role="bodySmall" muted style={{ minWidth: 90 }}>
                    #
                    {row.rankBand === '1_200'
                      ? `${format.format(1)}–${format.format(200)}`
                      : row.rankBand === '201_1000'
                        ? `${format.format(201)}–${format.format(1000)}`
                        : `${format.format(1001)}+`}
                  </CKText>
                  <View
                    style={[
                      styles.rankTrack,
                      { backgroundColor: colorWithAlpha(theme.onSurface, 0.06) },
                    ]}
                  >
                    <View
                      style={{
                        height: '100%',
                        width: `${100 * (share ?? 0)}%`,
                        borderRadius: 4,
                        backgroundColor: colorWithAlpha(ckColors.legendBlue, 0.6),
                      }}
                    />
                  </View>
                  <CKText role="bodySmall" style={{ minWidth: 48, textAlign: 'right' }}>
                    {percent(share)}
                  </CKText>
                </View>
              );
            })}
          </View>
          <Pressable
            onPress={() => setCoverageOpen(!coverageOpen)}
            accessibilityRole="button"
            accessibilityState={{ expanded: coverageOpen }}
            style={styles.coverageToggle}
          >
            <CKText role="bodySmall" muted style={{ flex: 1 }}>
              {t('legendCompleteDayDefinition')}
            </CKText>
            {coverageOpen ? (
              <ChevronUp color={theme.onSurfaceVariant} size={17} />
            ) : (
              <ChevronDown color={theme.onSurfaceVariant} size={17} />
            )}
          </Pressable>
          {selected.availableDays < selected.expectedDays ? (
            <CKText role="bodySmall" muted>
              {t('legendAvailableDays')}: {format.format(selected.availableDays)} /{' '}
              {format.format(selected.expectedDays)}
            </CKText>
          ) : null}
          {coverageOpen ? (
            <View style={styles.coverage}>
              {[
                [t('legendCompleteDays'), summary.completePlayerDays],
                [t('legendPartialDays'), summary.partialPlayerDays],
                [t('legendMissingDays'), summary.missingPlayerDays],
                ...(summary.invalidPlayerDays
                  ? [[t('legendInvalidDays'), summary.invalidPlayerDays]]
                  : []),
              ].map(([label, count]) => (
                <View key={String(label)} style={styles.rankRow}>
                  <CKText role="bodySmall" muted>
                    {label}
                  </CKText>
                  <CKText role="bodySmall">{format.format(Number(count))}</CKText>
                </View>
              ))}
            </View>
          ) : null}
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
  const [selection, setSelection] = useState<number | null>(null);
  const selectedBucket =
    selection ??
    summary.buckets.reduce(
      (best, bucket, index, buckets) =>
        (bucket.share ?? 0) > (buckets[best]?.share ?? 0) ? index : best,
      0,
    );
  const accent = side === 'offense' ? ckColors.donationGreen : ckColors.lossRed;
  const comparisons = data.periods.filter((period) => period.kind !== 'selected');
  const drawableComparisons = comparisons.filter((period) => period[side].completePlayerDays > 0);
  const peak = Math.max(
    0.05,
    ...[summary, ...comparisons.map((period) => period[side])].flatMap((item) =>
      item.buckets.map((bucket) => bucket.share ?? 0),
    ),
  );
  const max = Math.ceil(peak / 0.05) * 0.05;
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
          <Svg
            pointerEvents="none"
            viewBox="0 0 320 176"
            preserveAspectRatio="none"
            style={StyleSheet.absoluteFill}
          >
            {[8, 92, 176].map((y) => (
              <Line
                key={y}
                x1={0}
                x2={320}
                y1={y}
                y2={y}
                stroke={colorWithAlpha(theme.onSurface, 0.08)}
                strokeWidth={1}
              />
            ))}
          </Svg>
          <View style={styles.bars}>
            {summary.buckets.map((value, index) => (
              <Pressable
                key={value.minimum}
                style={styles.barTouch}
                onPress={() => setSelection(index)}
                accessibilityRole="button"
                accessibilityState={{ selected: index === selectedBucket }}
                accessibilityLabel={`${range(value.minimum, value.maximum)} · ${t('legendCompleteDays')}: ${format.format(value.playerDays)} · ${percent(value.share)}`}
              >
                <View
                  style={{
                    height: ((value.share ?? 0) / max) * 168,
                    width: '100%',
                    borderTopLeftRadius: 4,
                    borderTopRightRadius: 4,
                    backgroundColor:
                      index === selectedBucket ? accent : colorWithAlpha(accent, 0.35),
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
        <View style={styles.rankRow} accessibilityLiveRegion="polite">
          <View style={{ gap: 3 }}>
            <CKText role="bodyMedium">{range(bucket.minimum, bucket.maximum)}</CKText>
            <CKText role="bodySmall" muted>
              {format.format(bucket.playerDays)} {t('legendCompleteDays')}
            </CKText>
          </View>
          <CKText role="titleMedium" style={{ color: accent }}>
            {percent(bucket.share)}
          </CKText>
        </View>
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
  section: { gap: 20, marginBottom: 20 },
  headline: { gap: 7, alignItems: 'center', paddingVertical: 10 },
  rankTrack: { flex: 1, height: 6, borderRadius: 4, overflow: 'hidden' },
  coverageToggle: { flexDirection: 'row', alignItems: 'center', gap: 12, minHeight: 44 },
  metrics: { flexDirection: 'row', flexWrap: 'wrap', gap: 16 },
  metric: { flex: 1, minWidth: 110, gap: 3 },
  coverage: { gap: 10 },
  rankRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  chartRow: { flexDirection: 'row', gap: 8, paddingTop: 12 },
  axis: { width: 34, justifyContent: 'space-between' },
  bars: { height: 176, flexDirection: 'row', alignItems: 'flex-end', direction: 'ltr' },
  barTouch: { flex: 1, height: '100%', justifyContent: 'flex-end', paddingHorizontal: 1 },
  axisLabels: { flexDirection: 'row', justifyContent: 'space-between', direction: 'ltr' },
});
