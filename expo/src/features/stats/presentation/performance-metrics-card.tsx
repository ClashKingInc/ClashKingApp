import { useState, type ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import Svg, { Circle, Line, Polyline, Text as SvgText } from 'react-native-svg';

import { ImageAssets } from '../../../core/assets/image-assets';
import { formatCompactNumber, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  MobileWebImage,
  Surface,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  statColors,
  useCKTheme,
} from '../../../ui';
import { type StatsDailyPoint, type StatsMetrics } from '../models';

const CHART_WIDTH = 320;
const CHART_HEIGHT = 164;
const PLOT_LEFT = 44;
const PLOT_RIGHT = 10;
const PLOT_TOP = 12;
const PLOT_BOTTOM = 30;
const DAY_MS = 86_400_000;

type TrendPoint = {
  readonly date: string;
  readonly time: number;
  readonly sampleSize: number;
  readonly rate: number;
  readonly x: number;
  readonly y: number;
};

export type PerformanceTrendSeries = {
  readonly points: readonly TrendPoint[];
  readonly segments: readonly (readonly TrendPoint[])[];
  readonly yTicks: readonly number[];
  readonly firstDate: string | null;
  readonly lastDate: string | null;
};

export function buildPerformanceTrendSeries(
  daily: readonly StatsDailyPoint[],
): PerformanceTrendSeries {
  const dated = daily
    .map((point, sourceIndex) => ({ point, sourceIndex, time: dayTimestamp(point.date) }))
    .filter((entry): entry is typeof entry & { time: number } => entry.time !== null)
    .sort((left, right) => left.time - right.time || left.sourceIndex - right.sourceIndex);
  const firstTime = dated[0]?.time;
  const lastTime = dated.at(-1)?.time;
  const valid = dated.filter(
    ({ point }) =>
      point.sampleSize > 0 && Number.isFinite(point.threeStarRate) && point.threeStarRate >= 0,
  );
  const rates = valid.map(({ point }) => normalizePercent(point.threeStarRate));
  const [minimum, maximum] = trendDomain(rates);
  const plotWidth = CHART_WIDTH - PLOT_LEFT - PLOT_RIGHT;
  const plotHeight = CHART_HEIGHT - PLOT_TOP - PLOT_BOTTOM;
  const points = valid.map(({ point, time }) => ({
    date: point.date,
    time,
    sampleSize: point.sampleSize,
    rate: normalizePercent(point.threeStarRate),
    x:
      firstTime === undefined || lastTime === undefined || firstTime === lastTime
        ? PLOT_LEFT + plotWidth / 2
        : PLOT_LEFT + ((time - firstTime) / (lastTime - firstTime)) * plotWidth,
    y:
      PLOT_TOP +
      (maximum === minimum
        ? 0.5
        : (maximum - normalizePercent(point.threeStarRate)) / (maximum - minimum)) *
        plotHeight,
  }));
  const validDates = new Set(points.map((point) => point.date));
  const segments: TrendPoint[][] = [];
  let segment: TrendPoint[] = [];
  for (const entry of dated) {
    const point = points.find((candidate) => candidate.date === entry.point.date);
    const previous = segment.at(-1);
    const separated =
      !validDates.has(entry.point.date) ||
      (point !== undefined && previous !== undefined && point.time - previous.time > DAY_MS * 1.5);
    if (separated && segment.length) {
      segments.push(segment);
      segment = [];
    }
    if (point) segment.push(point);
  }
  if (segment.length) segments.push(segment);
  return {
    points,
    segments,
    yTicks: [minimum, (minimum + maximum) / 2, maximum],
    firstDate: dated[0]?.point.date ?? null,
    lastDate: dated.at(-1)?.point.date ?? null,
  };
}

export function PerformanceMetricsCard({
  title,
  metrics,
  extra,
  compact = false,
}: {
  readonly title: string;
  readonly metrics: StatsMetrics;
  readonly extra?: ReactNode;
  readonly compact?: boolean;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const hasSample = metrics.available && metrics.sampleSize > 0;

  return (
    <Surface
      radius={compact ? ckRadius.tile : ckRadius.card}
      style={[styles.card, compact && styles.compactCard]}
    >
      <View style={styles.header}>
        <View style={styles.titleBlock}>
          <CKText role={compact ? 'titleSmall' : 'titleMedium'}>{title}</CKText>
        </View>
        {extra == null ? null : <View style={styles.headerExtra}>{extra}</View>}
      </View>
      {!hasSample ? (
        <View
          accessibilityLabel={t('generalNoDataAvailable')}
          style={[
            styles.unavailable,
            { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.4) },
          ]}
        >
          <CKText role="body" muted>
            {t('generalNoDataAvailable')}
          </CKText>
        </View>
      ) : (
        <>
          <View style={styles.primaryRow}>
            <View style={styles.primaryMetric}>
              <CKText role="labelLarge" muted>
                {t('statsThreeStarRate')}
              </CKText>
              <CKText
                role="heroMetric"
                style={[compact && styles.compactHero, { color: statColors.warStarGold }]}
                testID="performance-three-star-rate"
              >
                {formatPercent(metrics.threeStarRate)}
              </CKText>
            </View>
            <Metric
              label={t('warAttacksTitle')}
              value={formatCompactNumber(metrics.sampleSize, locale)}
            />
          </View>

          <View style={styles.secondaryMetrics}>
            <Metric label={t('statsAverageStars')} value={metrics.averageStars.toFixed(2)} />
            <Metric
              label={t('statsAverageDestruction')}
              value={formatPercentValue(metrics.averageDestruction)}
            />
            {metrics.usageRate == null ? null : (
              <Metric label={t('statsUsage')} value={formatPercent(metrics.usageRate)} />
            )}
          </View>

          {compact ? null : (
            <>
              <View style={styles.section}>
                <CKText role="labelLarge">{t('statsStarRates')}</CKText>
                <StarDistribution metrics={metrics} />
              </View>

              {metrics.daily.some((point) => point.sampleSize > 0) ? (
                <View style={styles.section}>
                  <CKText role="labelLarge">{t('statsDailyTrend')}</CKText>
                  <PerformanceMetricsTrend metrics={metrics} />
                </View>
              ) : null}
            </>
          )}
        </>
      )}
    </Surface>
  );
}

function Metric({ label, value }: { readonly label: string; readonly value: string }) {
  const theme = useCKTheme();
  return (
    <View
      style={[
        styles.metric,
        { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.38) },
      ]}
    >
      <CKText role="bodySmall" muted numberOfLines={2}>
        {label}
      </CKText>
      <CKText role="rowTitle">{value}</CKText>
    </View>
  );
}

function StarDistribution({ metrics }: { readonly metrics: StatsMetrics }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const rates = [
    metrics.zeroStarRate,
    metrics.oneStarRate,
    metrics.twoStarRate,
    metrics.threeStarRate,
  ];
  const labels = [t('warStarsZero'), t('warStarsOne'), t('warStarsTwo'), t('warStarsThree')];
  return (
    <View style={styles.distribution}>
      {rates.map((rate, stars) => {
        const normalized = normalizePercent(rate);
        return (
          <View
            key={stars}
            accessibilityLabel={`${labels[stars]}: ${formatPercent(rate)}`}
            style={styles.distributionRow}
            testID={`performance-star-row-${stars}`}
          >
            <StarResult stars={stars} />
            <View
              style={[styles.distributionTrack, { backgroundColor: theme.surfaceContainerHighest }]}
            >
              <View
                style={[
                  styles.distributionFill,
                  {
                    width: `${normalized}%`,
                    backgroundColor:
                      stars === 3 ? statColors.warStarGold : colorWithAlpha(theme.tertiary, 0.72),
                  },
                ]}
              />
            </View>
            {stars === 3 ? (
              <View style={styles.distributionValueSpacer} />
            ) : (
              <CKText role="bodySmall" style={styles.distributionValue}>
                {formatPercent(rate)}
              </CKText>
            )}
          </View>
        );
      })}
    </View>
  );
}

function StarResult({ stars }: { readonly stars: number }) {
  return (
    <View
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      style={styles.stars}
    >
      {[0, 1, 2].map((index) => (
        <MobileWebImage
          key={index}
          imageUrl={index < stars ? ImageAssets.attackStar : ImageAssets.emptyStar}
          style={[styles.star, index >= stars && styles.emptyStar]}
          testID={`performance-star-${stars}-${index}`}
        />
      ))}
    </View>
  );
}

export function PerformanceMetricsTrend({ metrics }: { readonly metrics: StatsMetrics }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const series = buildPerformanceTrendSeries(metrics.daily);
  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const selected =
    series.points.find((point) => point.date === selectedDate) ?? series.points.at(-1) ?? null;
  if (!selected) return null;
  const dateLabel = (date: string) => formatDate(date, locale);
  const selectionLabel = `${dateLabel(selected.date)}, ${formatPercentValue(selected.rate)}, ${formatCompactNumber(selected.sampleSize, locale)} ${t('warAttacksTitle')}`;

  return (
    <View>
      <View
        accessibilityLabel={selectionLabel}
        style={[
          styles.trendSelection,
          { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.38) },
        ]}
        testID="performance-trend-selection"
      >
        <View>
          <CKText role="rowTitle">{dateLabel(selected.date)}</CKText>
          <CKText role="bodySmall" muted>
            {t('warAttacksTitle')}: {formatCompactNumber(selected.sampleSize, locale)}
          </CKText>
        </View>
        <CKText role="titleSmall" style={{ color: statColors.warStarGold }}>
          {formatPercentValue(selected.rate)}
        </CKText>
      </View>

      <View style={styles.chart}>
        <Svg
          accessibilityLabel={series.points
            .map(
              (point) =>
                `${dateLabel(point.date)}: ${formatPercentValue(point.rate)}, ${formatCompactNumber(point.sampleSize, locale)} ${t('warAttacksTitle')}`,
            )
            .join(', ')}
          width="100%"
          height="100%"
          viewBox={`0 0 ${CHART_WIDTH} ${CHART_HEIGHT}`}
        >
          {series.yTicks.map((tick) => {
            const y = yForRate(tick, series.yTicks[0]!, series.yTicks.at(-1)!);
            return (
              <ViewlessTick
                key={tick}
                label={`${Math.round(tick)}%`}
                y={y}
                color={theme.onSurfaceVariant}
                gridColor={colorWithAlpha(theme.outlineVariant, 0.32)}
              />
            );
          })}
          {series.segments.map((segment, index) =>
            segment.length > 1 ? (
              <Polyline
                key={index}
                points={segment.map((point) => `${point.x},${point.y}`).join(' ')}
                fill="none"
                stroke={statColors.warStarGold}
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="3"
              />
            ) : null,
          )}
          {series.points.map((point) => {
            const active = point.date === selected.date;
            return (
              <Circle
                key={point.date}
                cx={point.x}
                cy={point.y}
                fill={active ? theme.card : statColors.warStarGold}
                r={active ? 6 : 4}
                stroke={statColors.warStarGold}
                strokeWidth={active ? 3 : 0}
              />
            );
          })}
          {series.firstDate ? (
            <SvgText
              fill={theme.onSurfaceVariant}
              fontSize="12"
              textAnchor="start"
              x={PLOT_LEFT}
              y={CHART_HEIGHT - 6}
            >
              {dateLabel(series.firstDate)}
            </SvgText>
          ) : null}
          {series.lastDate && series.lastDate !== series.firstDate ? (
            <SvgText
              fill={theme.onSurfaceVariant}
              fontSize="12"
              textAnchor="end"
              x={CHART_WIDTH - PLOT_RIGHT}
              y={CHART_HEIGHT - 6}
            >
              {dateLabel(series.lastDate)}
            </SvgText>
          ) : null}
        </Svg>
        {series.points.map((point) => {
          const label = `${dateLabel(point.date)}, ${formatPercentValue(point.rate)}, ${formatCompactNumber(point.sampleSize, locale)} ${t('warAttacksTitle')}`;
          return (
            <Pressable
              key={point.date}
              accessibilityLabel={label}
              accessibilityRole="button"
              hitSlop={4}
              onPress={() => setSelectedDate(point.date)}
              style={[
                styles.chartHitTarget,
                {
                  left: `${(point.x / CHART_WIDTH) * 100}%`,
                  top: `${(point.y / CHART_HEIGHT) * 100}%`,
                },
              ]}
              testID={`performance-trend-point-${point.date}`}
            />
          );
        })}
      </View>
    </View>
  );
}

function ViewlessTick({
  label,
  y,
  color,
  gridColor,
}: {
  readonly label: string;
  readonly y: number;
  readonly color: string;
  readonly gridColor: string;
}) {
  return (
    <>
      <Line x1={PLOT_LEFT} x2={CHART_WIDTH - PLOT_RIGHT} y1={y} y2={y} stroke={gridColor} />
      <SvgText fill={color} fontSize="12" textAnchor="end" x={PLOT_LEFT - 7} y={y + 4}>
        {label}
      </SvgText>
    </>
  );
}

function trendDomain(rates: readonly number[]): [number, number] {
  if (!rates.length) return [0, 100];
  const minimum = Math.min(...rates);
  const maximum = Math.max(...rates);
  const padding = Math.max(5, (maximum - minimum) * 0.2);
  let lower = Math.max(0, Math.floor((minimum - padding) / 5) * 5);
  let upper = Math.min(100, Math.ceil((maximum + padding) / 5) * 5);
  if (lower === upper) {
    if (upper === 100) lower = Math.max(0, upper - 10);
    else upper = Math.min(100, lower + 10);
  }
  return [lower, upper];
}

function yForRate(rate: number, minimum: number, maximum: number): number {
  const plotHeight = CHART_HEIGHT - PLOT_TOP - PLOT_BOTTOM;
  return PLOT_TOP + ((maximum - rate) / (maximum - minimum)) * plotHeight;
}

function dayTimestamp(date: string): number | null {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return null;
  const value = Date.parse(`${date}T00:00:00.000Z`);
  return Number.isFinite(value) ? value : null;
}

function formatDate(date: string, locale: string): string {
  const timestamp = dayTimestamp(date);
  if (timestamp === null) return date;
  return new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'short',
    day: 'numeric',
    timeZone: 'UTC',
  }).format(timestamp);
}

function normalizePercent(value: number): number {
  const percent = Math.abs(value) <= 1 ? value * 100 : value;
  return Math.max(0, Math.min(100, percent));
}

function formatPercent(value: number): string {
  const normalized = normalizePercent(value);
  return formatPercentValue(normalized);
}

function formatPercentValue(value: number): string {
  return `${value.toFixed(value >= 10 ? 1 : 2)}%`;
}

const styles = StyleSheet.create({
  card: { padding: ckSpacing.xl, gap: ckSpacing.lg },
  compactCard: { padding: ckSpacing.lg, gap: ckSpacing.md },
  header: { width: '100%', alignItems: 'stretch', gap: ckSpacing.sm },
  titleBlock: { width: '100%' },
  headerExtra: { width: '100%' },
  unavailable: {
    minHeight: 72,
    borderRadius: ckRadius.control,
    justifyContent: 'center',
    padding: ckSpacing.lg,
  },
  primaryRow: { flexDirection: 'row', alignItems: 'flex-end', gap: ckSpacing.md },
  primaryMetric: { flex: 1, gap: ckSpacing.xs },
  compactHero: { fontSize: 30, lineHeight: 32 },
  secondaryMetrics: { flexDirection: 'row', flexWrap: 'wrap', gap: ckSpacing.sm },
  metric: {
    flexGrow: 1,
    flexBasis: 104,
    minHeight: 58,
    borderRadius: ckRadius.control,
    justifyContent: 'center',
    paddingHorizontal: ckSpacing.md,
    paddingVertical: ckSpacing.sm,
    gap: 2,
  },
  section: { gap: ckSpacing.sm },
  distribution: { gap: ckSpacing.sm },
  distributionRow: { minHeight: 25, flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm },
  stars: { width: 64, flexDirection: 'row', alignItems: 'center', gap: 2 },
  star: { width: 20, height: 20 },
  emptyStar: { opacity: 0.55 },
  distributionTrack: { flex: 1, height: 8, borderRadius: ckRadius.pill, overflow: 'hidden' },
  distributionFill: { height: '100%', borderRadius: ckRadius.pill },
  distributionValue: { width: 48, textAlign: 'right' },
  distributionValueSpacer: { width: 48 },
  trendSelection: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderRadius: ckRadius.control,
    paddingHorizontal: ckSpacing.md,
    paddingVertical: ckSpacing.sm,
  },
  chart: {
    width: '100%',
    aspectRatio: CHART_WIDTH / CHART_HEIGHT,
    marginTop: ckSpacing.sm,
    position: 'relative',
  },
  chartHitTarget: {
    position: 'absolute',
    width: 44,
    height: 44,
    marginLeft: -22,
    marginTop: -22,
    borderRadius: 22,
  },
});
