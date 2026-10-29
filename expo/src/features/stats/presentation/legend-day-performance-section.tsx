import { useEffect, useMemo, useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, View } from 'react-native';
import Svg, { Line } from 'react-native-svg';
import { ImageAssets } from '../../../core/assets/image-assets';
import type { ContractApiService } from '../../../core/api/contract-api';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  ErrorState,
  MobileWebImage,
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
import { LegendHitRateDetails } from './legend-hit-rate-details';

type Summary = LegendDayPerformance['periods'][number]['offense'];
type Availability = { firstDay: string; lastDay: string };

export function LegendDayPerformanceSection({
  api,
  dates,
  cohort,
  onShowLatest,
  onAvailability,
  observed = false,
  displayMode = 'days',
}: {
  readonly api: ContractApiService;
  readonly observed?: boolean;
  readonly displayMode?: 'days' | 'battles';
  readonly dates: StatsDateFilter;
  readonly cohort: StatsLegendCohortValue;
  readonly onShowLatest?: (availability: Availability) => void;
  readonly onAvailability?: (availability: Availability) => void;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const repository = useMemo(() => new StatsRepository(api), [api]);
  const [view, setView] = useState<'distribution' | 'trend'>('distribution');
  const [reload, setReload] = useState(0);
  const [result, setResult] = useState<{
    key: string;
    baseKey: string;
    repository: StatsRepository;
    data?: LegendDayPerformance;
    error?: unknown;
  } | null>(null);
  const first = StatsDateFilter.formatDate(dates.start),
    last = StatsDateFilter.formatDate(dates.end);
  const baseKey = `${first}:${last}:${cohort}:${observed}:${reload}`;
  const requestKey = `${baseKey}:${displayMode}`;
  // Keep the same cohort/date summary visible while Hitrate loads army detail.
  // A different date or population must never reuse that visible result.
  const state =
    result?.baseKey === baseKey && result.repository === repository
      ? { ...result, error: result.key === requestKey ? result.error : undefined }
      : { data: undefined, error: undefined };
  useEffect(() => {
    let active = true;
    // Ignore late responses after a cohort/date change or navigation. The
    // repository deduplicates bounded requests and caches by the exact range.
    const query = new StatsLegendQuery(
      new StatsDateFilter(new Date(`${first}T12:00:00`), new Date(`${last}T12:00:00`)),
      cohort,
    );
    void (async () => {
      const data = await repository.loadLegendPerformance(query, reload > 0, observed, false);
      if (active) setResult({ key: `${baseKey}:days`, baseKey, repository, data });
      if (active && displayMode === 'battles') {
        const details = await repository.loadLegendPerformance(query, reload > 0, observed, true);
        if (active) setResult({ key: requestKey, baseKey, repository, data: details });
      }
    })().catch((error: unknown) => {
      if (active)
        setResult((previous) => ({
          key: requestKey,
          baseKey,
          repository,
          error,
          data:
            previous?.baseKey === baseKey && previous.repository === repository
              ? previous.data
              : undefined,
        }));
    });
    return () => {
      active = false;
    };
  }, [repository, first, last, cohort, observed, reload, requestKey, baseKey, displayMode]);
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
  const cohortLabel = observed
    ? t('generalAll')
    : cohort === StatsLegendCohort.legend
      ? t('statsLegendLeagueOne')
      : t('rankingsTopCount', { count: cohort === StatsLegendCohort.top200 ? 200 : 1000 });
  const availability = state.data?.availability;
  useEffect(() => {
    if (availability) onAvailability?.(availability);
  }, [availability, onAvailability]);
  const latestLabel = availability
    ? dateFormat.format(new Date(`${availability.lastDay}T12:00:00`))
    : undefined;
  return (
    <View style={styles.section} testID="legend-day-performance">
      {state.error && !state.data ? (
        <ErrorState
          title={t('sideStatsLoadError')}
          body={t('statsNoDataBody')}
          actionLabel={t('generalRetry')}
          onAction={() => setReload((value) => value + 1)}
        />
      ) : !state.data ? (
        <ActivityIndicator color={theme.primary} />
      ) : !selected ||
        (selected.availableDays === 0 && !(displayMode === 'battles' && state.data.currentDay)) ? (
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
          {displayMode === 'battles' ? (
            <CKText role="titleMedium">{t('statsThreeStarRate')}</CKText>
          ) : null}
          <View style={styles.sideCards}>
            {(['offense', 'defense'] as const).map((direction) => {
              const accent = direction === 'offense' ? ckColors.donationGreen : ckColors.lossRed;
              const today = state.data?.currentDay?.[direction];
              const battles = selected[direction].observedBattles + (today?.battles ?? 0);
              const rate =
                displayMode === 'battles'
                  ? battles
                    ? (selected[direction].observedTriples + (today?.triples ?? 0)) / battles
                    : null
                  : selected[direction].perfectDayRate;
              return (
                <View
                  key={direction}
                  style={[styles.sideCard, { backgroundColor: colorWithAlpha(accent, 0.08) }]}
                >
                  <View style={styles.cardHeading}>
                    <MobileWebImage
                      imageUrl={direction === 'offense' ? ImageAssets.sword : ImageAssets.shield}
                      contentFit="contain"
                      style={{ width: 24, height: 24 }}
                    />
                    <CKText role="bodyMedium" style={{ fontWeight: '600' }}>
                      {t(
                        direction === 'offense' ? 'capitalDetailsOffense' : 'capitalDetailsDefense',
                      )}
                    </CKText>
                  </View>
                  <CKText
                    role="heroMetric"
                    style={{ color: accent, fontSize: 34, fontWeight: '700', lineHeight: 42 }}
                  >
                    {percent(rate)}
                  </CKText>
                  {displayMode === 'days' ? (
                    <CKText role="bodySmall" muted>
                      {t(
                        direction === 'offense'
                          ? 'legendPerfectDays'
                          : 'legendPerfectedDefenseDays',
                      )}
                    </CKText>
                  ) : null}
                </View>
              );
            })}
          </View>
          {displayMode === 'battles' ? (
            <>
              <View style={[styles.chartCard, { backgroundColor: theme.surface }]}>
                <AnalyticsLineChart
                  legendMode="hidden"
                  showTitle={false}
                  title={t('statsThreeStarRate')}
                  exportTitle={`${t('statsThreeStarRate')} · ${cohortLabel} · ${first} – ${last}`}
                  percent
                  includeZero
                  connectGaps={false}
                  responsiveAxes
                  series={(['offense', 'defense'] as const).map((direction) => ({
                    key: direction,
                    label: t(
                      direction === 'offense' ? 'capitalDetailsOffense' : 'capitalDetailsDefense',
                    ),
                    color: direction === 'offense' ? ckColors.donationGreen : ckColors.lossRed,
                    aggregation: 'weightedMean',
                    points: [
                      ...state.data!.items.map((item) => ({
                        day: item.day,
                        value:
                          item[direction].tripleRate === null
                            ? null
                            : item[direction].tripleRate! * 100,
                        weight: item[direction].observedBattles,
                      })),
                      ...(state.data!.currentDay
                        ? [
                            {
                              day: state.data!.currentDay.day,
                              value:
                                state.data!.currentDay[direction].tripleRate === null
                                  ? null
                                  : state.data!.currentDay[direction].tripleRate! * 100,
                              weight: state.data!.currentDay[direction].battles,
                            },
                          ]
                        : []),
                    ],
                  }))}
                />
              </View>
              <LegendHitRateDetails data={state.data} dates={dates} />
              {result?.key !== requestKey ? (
                <ActivityIndicator color={theme.primary} />
              ) : state.error ? (
                <Pressable
                  onPress={() => setReload((value) => value + 1)}
                  accessibilityRole="button"
                >
                  <CKText role="bodySmall" style={{ color: theme.primary }}>
                    {t('generalRetry')}
                  </CKText>
                </Pressable>
              ) : null}
            </>
          ) : (
            <>
              <View style={[styles.chartCard, { backgroundColor: theme.surface }]}>
                <View style={styles.chartHeading}>
                  <CKText role="titleMedium">{t('gameTrophies')}</CKText>
                  <CKText role="bodySmall" muted>
                    {t('rankedLeagueAverage')}
                  </CKText>
                </View>
                <View style={styles.averageRow}>
                  {(['offense', 'defense'] as const).map((direction) => (
                    <View key={direction} style={[styles.cardHeading, { flex: 1 }]}>
                      <View
                        style={{
                          width: 7,
                          height: 7,
                          borderRadius: 4,
                          backgroundColor:
                            direction === 'offense' ? ckColors.donationGreen : ckColors.lossRed,
                        }}
                      />
                      <CKText role="bodySmall" muted>
                        {t(
                          direction === 'offense'
                            ? 'capitalDetailsOffense'
                            : 'capitalDetailsDefense',
                        )}
                      </CKText>
                      <CKText role="titleSmall">
                        {selected[direction].meanTrophies === null
                          ? '—'
                          : `${direction === 'offense' ? '+' : '−'}${format.format(selected[direction].meanTrophies!)}`}
                      </CKText>
                    </View>
                  ))}
                </View>
                <SlidingSegmentControl
                  value={view}
                  isRtl={isRtl}
                  onChange={setView}
                  options={[
                    { value: 'distribution', label: t('legendDistribution') },
                    { value: 'trend', label: t('statsDailyTrend') },
                  ]}
                />
                {view === 'distribution' ? (
                  <StatsChartFrame
                    title={`${t('gameTrophies')} · ${cohortLabel} · ${first} – ${last}`}
                    showTitle={false}
                    copyPlacement="footer"
                  >
                    <Distribution
                      offense={selected.offense}
                      defense={selected.defense}
                      percent={percent}
                      format={format}
                    />
                  </StatsChartFrame>
                ) : (
                  <AnalyticsLineChart
                    legendMode="hidden"
                    title={t('gameTrophies')}
                    showTitle={false}
                    exportTitle={`${t('gameTrophies')} · ${cohortLabel} · ${first} – ${last}`}
                    connectGaps={false}
                    responsiveAxes
                    series={(['offense', 'defense'] as const).map((direction) => ({
                      key: direction,
                      aggregation: 'weightedMean',
                      label: t(
                        direction === 'offense' ? 'capitalDetailsOffense' : 'capitalDetailsDefense',
                      ),
                      color: direction === 'offense' ? ckColors.donationGreen : ckColors.lossRed,
                      points: state.data!.items.map((item) => ({
                        day: item.day,
                        value: item[direction].meanTrophies,
                        weight: item[direction].completePlayerDays,
                      })),
                    }))}
                  />
                )}
              </View>
              {view === 'trend' ? (
                <View style={[styles.chartCard, { backgroundColor: theme.surface }]}>
                  <AnalyticsLineChart
                    legendMode="labels"
                    title={t('legendPerfectDays')}
                    exportTitle={`${t('legendPerfectDays')} · ${cohortLabel} · ${first} – ${last}`}
                    percent
                    includeZero
                    connectGaps={false}
                    responsiveAxes
                    series={(['offense', 'defense'] as const).map((direction) => ({
                      key: direction,
                      label: t(
                        direction === 'offense' ? 'capitalDetailsOffense' : 'capitalDetailsDefense',
                      ),
                      color: direction === 'offense' ? ckColors.donationGreen : ckColors.lossRed,
                      aggregation: 'weightedMean',
                      points: state.data!.items.map((item) => ({
                        day: item.day,
                        value:
                          item[direction].perfectDayRate === null
                            ? null
                            : item[direction].perfectDayRate! * 100,
                        weight: item[direction].completePlayerDays,
                      })),
                    }))}
                  />
                </View>
              ) : null}
            </>
          )}
          {state.data.perfectDayContributions.some(
            (row) => row.offensePlayerDays + row.defensePlayerDays > 0,
          ) ? (
            <View style={[styles.chartCard, { backgroundColor: theme.surface }]}>
              <CKText role="titleMedium">{t('legendPerfectSources')}</CKText>
              {state.data.perfectDayContributions.map((row) => (
                <View key={row.rankBand} style={styles.rankRow}>
                  <CKText role="bodySmall" muted>
                    {row.rankBand === '1_200'
                      ? '#1–200'
                      : row.rankBand === '201_1000'
                        ? '#201–1,000'
                        : '#1,001+'}
                  </CKText>
                  {(['offense', 'defense'] as const).map((direction) => {
                    const total = state.data!.perfectDayContributions.reduce(
                      (sum, item) =>
                        sum +
                        (direction === 'offense' ? item.offensePlayerDays : item.defensePlayerDays),
                      0,
                    );
                    const count =
                      direction === 'offense' ? row.offensePlayerDays : row.defensePlayerDays;
                    return (
                      <CKText
                        key={direction}
                        role="bodyMedium"
                        style={{
                          color:
                            direction === 'offense' ? ckColors.donationGreen : ckColors.lossRed,
                        }}
                      >
                        {percent(total ? count / total : null)}
                      </CKText>
                    );
                  })}
                </View>
              ))}
            </View>
          ) : null}
        </>
      )}
    </View>
  );
}

function Distribution({
  offense,
  defense,
  percent,
  format,
}: {
  offense: Summary;
  defense: Summary;
  percent: (value: number | null) => string;
  format: Intl.NumberFormat;
}) {
  const theme = useCKTheme();
  const [selection, setSelection] = useState<number | null>(null);
  const selectedBucket =
    selection ??
    offense.buckets.reduce(
      (best, bucket, index, buckets) =>
        (bucket.share ?? 0) > (buckets[best]?.share ?? 0) ? index : best,
      0,
    );
  const peak = Math.max(
    0.05,
    ...[offense, defense].flatMap((side) => side.buckets.map((bucket) => bucket.share ?? 0)),
  );
  const max = Math.ceil(peak / 0.05) * 0.05;
  const bucket = offense.buckets[selectedBucket];
  return (
    <View style={{ gap: 14 }}>
      <View style={styles.chartRow}>
        <View style={styles.axis}>
          <CKText role="bodySmall" muted>
            {percent(max)}
          </CKText>
          <CKText role="bodySmall" muted>
            0
          </CKText>
        </View>
        <View style={{ flex: 1, height: 190 }}>
          <Svg
            pointerEvents="none"
            viewBox="0 0 320 190"
            preserveAspectRatio="none"
            style={StyleSheet.absoluteFill}
          >
            {[6, 98, 190].map((y) => (
              <Line
                key={y}
                x1={0}
                x2={320}
                y1={y}
                y2={y}
                stroke={colorWithAlpha(theme.onSurface, 0.07)}
                strokeWidth={1}
              />
            ))}
          </Svg>
          <View style={styles.bars}>
            {offense.buckets.map((value, index) => (
              <Pressable
                key={value.minimum}
                accessibilityRole="button"
                accessibilityState={{ selected: index === selectedBucket }}
                accessibilityLabel={`${format.format(value.minimum)}–${format.format(value.maximum)}`}
                onPress={() => setSelection(index)}
                style={styles.barTouch}
              >
                {([offense, defense] as const).map((side, sideIndex) => (
                  <View
                    key={sideIndex}
                    style={{
                      flex: 1,
                      height: ((side.buckets[index]?.share ?? 0) / max) * 180,
                      borderTopLeftRadius: 3,
                      borderTopRightRadius: 3,
                      backgroundColor: colorWithAlpha(
                        sideIndex === 0 ? ckColors.donationGreen : ckColors.lossRed,
                        index === selectedBucket ? 1 : 0.58,
                      ),
                    }}
                  />
                ))}
              </Pressable>
            ))}
          </View>
        </View>
      </View>
      <View style={[styles.axisLabels, { marginStart: 38 }]}>
        {[0, 80, 160, 240, 320].map((value) => (
          <CKText key={value} role="bodySmall" muted>
            {value}
          </CKText>
        ))}
      </View>
      {bucket ? (
        <View style={[styles.rankRow, { paddingTop: 2 }]} accessibilityLiveRegion="polite">
          <CKText role="bodyMedium">
            {format.format(bucket.minimum)}–{format.format(bucket.maximum)}
          </CKText>
          <View style={styles.cardHeading}>
            <View
              style={{
                width: 6,
                height: 6,
                borderRadius: 3,
                backgroundColor: ckColors.donationGreen,
              }}
            />
            <CKText role="bodyMedium">{percent(bucket.share)}</CKText>
          </View>
          <View style={styles.cardHeading}>
            <View
              style={{ width: 6, height: 6, borderRadius: 3, backgroundColor: ckColors.lossRed }}
            />
            <CKText role="bodyMedium">
              {percent(defense.buckets[selectedBucket]?.share ?? null)}
            </CKText>
          </View>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  section: { gap: 14, marginBottom: 20 },
  sideCards: { flexDirection: 'row', gap: 10 },
  sideCard: { flex: 1, borderRadius: 20, padding: 16, gap: 5 },
  cardHeading: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  averageRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  chartCard: { borderRadius: 24, padding: 16, gap: 16 },
  chartHeading: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  rankRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  chartRow: { flexDirection: 'row', gap: 6, paddingTop: 6 },
  axis: { width: 32, justifyContent: 'space-between' },
  bars: { height: 190, flexDirection: 'row', alignItems: 'flex-end', direction: 'ltr' },
  barTouch: {
    flex: 1,
    height: '100%',
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: 1,
    paddingHorizontal: 1,
  },
  axisLabels: { flexDirection: 'row', justifyContent: 'space-between', direction: 'ltr' },
});
