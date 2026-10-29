import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { useCallback, useMemo, useRef, useState } from 'react';
import { PanResponder, Pressable, StyleSheet, View } from 'react-native';
import Svg, { Circle, Line, Polyline, Text as SvgText } from 'react-native-svg';
import {
  CKText,
  Skeleton,
  ckColors,
  colorWithAlpha,
  useCKTheme,
  useSkeletonContent,
} from '../../../ui';
import { toIntlLocale, useI18n } from '../../../i18n';
import { StatsChartFrame } from './stats-chart-frame';
import { aggregateChartSeries } from './chart-aggregation';
import { useChartGranularity } from './stats-chart-preferences';
import { useChartDismissal } from './chart-interaction-boundary';

export interface AnalyticsSeries {
  readonly key: string;
  readonly label: string;
  readonly color?: string;
  /** Means must preserve their denominator when grouped into weeks/months. */
  readonly aggregation?: 'sum' | 'weightedMean';
  readonly points: readonly { day: string; value: number | null; weight?: number }[];
}
const palette = [
  ckColors.legendBlue,
  ckColors.warGold,
  ckColors.donationGreen,
  ckColors.capitalPurple,
  '#E887A6',
];
const LEFT = 40,
  RIGHT = 354,
  TOP = 14,
  WIDTH = 360;

export function chartSelectionIndex(
  x: number,
  width: number,
  count: number,
  bounds = { left: LEFT, right: RIGHT, width: WIDTH },
): number {
  if (count <= 1 || width <= 0) return 0;
  return Math.max(
    0,
    Math.min(
      count - 1,
      Math.round(
        (((x / width) * bounds.width - bounds.left) / (bounds.right - bounds.left)) * (count - 1),
      ),
    ),
  );
}

export function analyticsChartDays(series: readonly AnalyticsSeries[]): string[] {
  const days = [...new Set(series.flatMap((line) => line.points.map((point) => point.day)))].sort();
  if (days.length < 2 || !days.every((day) => /^\d{4}-\d{2}-\d{2}$/.test(day))) return days;
  const first = Date.parse(days[0]!);
  const last = Date.parse(days[days.length - 1]!);
  if (!Number.isFinite(first) || !Number.isFinite(last) || last - first > 20000 * 86400000)
    return days;
  return Array.from({ length: Math.round((last - first) / 86400000) + 1 }, (_, i) =>
    new Date(first + i * 86400000).toISOString().slice(0, 10),
  );
}

/** Connect observed points across gaps; tooltips still report missing dates as unavailable. */
export function AnalyticsLineChart({
  title,
  exportTitle,
  series: sourceSeries,
  percent = false,
  height: requestedHeight = 192,
  includeZero = false,
  inverted = false,
  connectGaps = true,
  showPoints = false,
  axisMinimum = 0,
  formatAxisValue,
  formatValue,
  formatDay,
  formatAxisDay,
  formatPointDetail,
  showTitle = true,
  exportable = true,
  xDomain = 'calendar',
  responsiveAxes = false,
  legendMode = 'interactive',
}: {
  readonly title: string;
  readonly exportTitle?: string;
  readonly series: readonly AnalyticsSeries[];
  readonly percent?: boolean;
  readonly height?: number;
  readonly includeZero?: boolean;
  readonly inverted?: boolean;
  readonly connectGaps?: boolean;
  readonly showPoints?: boolean;
  readonly axisMinimum?: number;
  readonly formatAxisValue?: (value: number) => string;
  readonly formatValue?: (value: number) => string;
  readonly formatDay?: (day: string) => string;
  readonly formatAxisDay?: (day: string) => string;
  readonly formatPointDetail?: (seriesKey: string, day: string) => string | undefined;
  readonly showTitle?: boolean;
  readonly exportable?: boolean;
  /** Non-daily series (for example raid weekends) must select observations,
   * not synthetic days inserted between their reporting periods. */
  readonly xDomain?: 'calendar' | 'observations';
  /** Use unscaled axis text and measured-width gutters for small inset charts. */
  readonly responsiveAxes?: boolean;
  /** Comparison views can keep both series visible and show values only on chart interaction. */
  readonly legendMode?: 'interactive' | 'labels' | 'hidden';
}) {
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const height = layout.isExpanded ? Math.max(260, requestedHeight) : requestedHeight;
  // The closed Duo has a narrower plot after the system rail. Use measured
  // label gutters there too, without changing ordinary phone chart geometry.
  const useResponsiveAxes = responsiveAxes || layout.isExpanded || layout.isDuo;
  const contentLoading = useSkeletonContent();
  const { t, locale } = useI18n();
  const [width, setWidth] = useState(0);
  const [selectedDay, setSelectedDay] = useState<string>();
  const clearSelection = useCallback(() => setSelectedDay(undefined), []);
  const dismissCharts = useChartDismissal(clearSelection);
  const [hidden, setHidden] = useState<readonly string[]>([]);
  const granularity = useChartGranularity();
  const series = useMemo(
    () => aggregateChartSeries(sourceSeries, granularity, percent),
    [sourceSeries, granularity, percent],
  );
  const pointMaps = useMemo(
    () =>
      new Map(
        series.map((line) => [
          line.key,
          new Map(line.points.map((point) => [point.day, point.value])),
        ]),
      ),
    [series],
  );
  const touchStart = useRef<{ x: number; y: number } | undefined>(undefined);
  const days = useMemo(
    () =>
      series === sourceSeries && xDomain === 'calendar'
        ? analyticsChartDays(series)
        : [...new Set(series.flatMap((line) => line.points.map((point) => point.day)))].sort(),
    [series, sourceSeries, xDomain],
  );
  const visible = series.filter((line) => !hidden.includes(line.key));
  const values = visible.flatMap((line) =>
    line.points.flatMap((point) =>
      point.value !== null && Number.isFinite(point.value) ? [point.value] : [],
    ),
  );
  const low = values.length ? Math.min(...values) : 0;
  const high = values.length ? Math.max(...values) : 1;
  const padding = Math.max(percent ? 2 : 1, (high - low) * 0.15);
  const rawMinimum = includeZero ? axisMinimum : Math.max(axisMinimum, Math.floor(low - padding));
  const rawMaximum = Math.max(
    rawMinimum + 1,
    Math.min(percent ? 100 : Infinity, Math.ceil(high + padding)),
  );
  // Round display bounds to useful intervals rather than labeling arbitrary
  // data-derived fractions such as 607,813.5. Keep legacy chart scales intact.
  const rawStep = (rawMaximum - rawMinimum) / 3;
  const magnitude = 10 ** Math.floor(Math.log10(rawStep));
  const step =
    ([1, 2, 2.5, 5, 10].find((factor) => factor * magnitude >= rawStep) ?? 10) * magnitude;
  const minimum = useResponsiveAxes
    ? Math.max(axisMinimum, Math.floor(rawMinimum / step) * step)
    : rawMinimum;
  const maximum = useResponsiveAxes ? Math.ceil(rawMaximum / step) * step : rawMaximum;
  const ticks = useResponsiveAxes
    ? Array.from(
        { length: Math.round((maximum - minimum) / step) + 1 },
        (_, index) => minimum + index * step,
      )
    : [minimum, (minimum + maximum) / 2, maximum];
  const formatTick = (value: number) =>
    formatAxisValue?.(value) ??
    formatValue?.(value) ??
    Math.round(value).toLocaleString(toIntlLocale(locale));
  const tickLabels = ticks.map(formatTick);
  // Compact notation can collapse nearby ticks to the same label. Fall back
  // to exact rounded values rather than presenting an ambiguous value axis.
  const yLabels =
    useResponsiveAxes && new Set(tickLabels).size < tickLabels.length
      ? ticks.map((value) =>
          value.toLocaleString(toIntlLocale(locale), { maximumFractionDigits: 2 }),
        )
      : tickLabels;
  const axisFontSize = layout.isExpanded ? 15 : useResponsiveAxes ? 13 : 12;
  const labelWidth = (label: string) =>
    [...label].reduce(
      (total, character) =>
        total +
        axisFontSize * (character === ' ' ? 0.35 : character.codePointAt(0)! > 255 ? 1.05 : 0.68),
      0,
    );
  const viewWidth = useResponsiveAxes && width > 0 ? width : WIDTH;
  const left = useResponsiveAxes
    ? Math.max(36, ...yLabels.map((label) => labelWidth(label) + 10))
    : LEFT;
  const right = useResponsiveAxes ? viewWidth - 4 : RIGHT;
  const top = useResponsiveAxes ? 8 : TOP;
  const bottom = height - (useResponsiveAxes ? 32 : 30);
  const x = (index: number) => left + (index / Math.max(1, days.length - 1)) * (right - left);
  const y = (value: number) =>
    Math.max(
      top,
      Math.min(
        bottom,
        inverted
          ? top + ((value - minimum) / (maximum - minimum)) * (bottom - top)
          : bottom - ((value - minimum) / (maximum - minimum)) * (bottom - top),
      ),
    );
  const activeIndex = Math.max(
    0,
    selectedDay && days.includes(selectedDay) ? days.indexOf(selectedDay) : days.length - 1,
  );
  const selected = selectedDay && days.includes(selectedDay) ? selectedDay : undefined;
  const legendDay =
    selected ??
    days.findLast((day) =>
      series.some((line) => {
        const value = pointMaps.get(line.key)?.get(day);
        return value != null && Number.isFinite(value);
      }),
    );
  const dayLabel = (day: string) =>
    formatDay?.(day) ??
    new Date(`${day.length === 7 ? `${day}-01` : day}T12:00:00Z`).toLocaleDateString(
      toIntlLocale(locale),
      {
        month: 'short',
        ...(day.length === 7 ? {} : { day: 'numeric' }),
        ...(days[0]?.slice(0, 4) !== days.at(-1)?.slice(0, 4) ? { year: '2-digit' as const } : {}),
      },
    );
  const format =
    formatValue ??
    ((value: number) =>
      percent
        ? `${value.toLocaleString(toIntlLocale(locale), { maximumFractionDigits: 1 })}%`
        : Math.round(value).toLocaleString(toIntlLocale(locale), { notation: 'compact' }));
  const axisDayLabel = (day: string) => formatAxisDay?.(day) ?? dayLabel(day);
  const candidateIndexes = [
    0,
    Math.round((days.length - 1) / 3),
    Math.round(((days.length - 1) * 2) / 3),
    days.length - 1,
  ].filter((value, index, all) => all.indexOf(value) === index);
  const labelBounds = (index: number) => {
    const textWidth = labelWidth(axisDayLabel(days[index] ?? ''));
    const start =
      index === 0
        ? x(index)
        : index === days.length - 1
          ? x(index) - textWidth
          : x(index) - textWidth / 2;
    return { start, end: start + textWidth };
  };
  const xTicks =
    useResponsiveAxes &&
    days.length > 1 &&
    labelBounds(0).end + 16 > labelBounds(days.length - 1).start
      ? [days.length - 1]
      : useResponsiveAxes
        ? candidateIndexes.reduce<number[]>((accepted, index) => {
            if (index === 0 || index === days.length - 1) return [...accepted, index];
            const previous = accepted.at(-1) ?? 0;
            const current = labelBounds(index);
            return current.start >= labelBounds(previous).end + 16 &&
              current.end + 16 <= labelBounds(days.length - 1).start
              ? [...accepted, index]
              : accepted;
          }, [])
        : candidateIndexes;
  const selectDay = (day: string | undefined) => {
    dismissCharts();
    setSelectedDay(day);
  };
  const selectAt = (position: number) =>
    selectDay(
      days[chartSelectionIndex(position, width, days.length, { left, right, width: viewWidth })],
    );
  const responder = PanResponder.create({
    onStartShouldSetPanResponder: () => false,
    onMoveShouldSetPanResponder: (_, gesture) =>
      Math.abs(gesture.dx) > 6 && Math.abs(gesture.dx) > Math.abs(gesture.dy) * 1.3,
    onPanResponderGrant: (event) => selectAt(event.nativeEvent.locationX),
    onPanResponderMove: (event) => selectAt(event.nativeEvent.locationX),
    onPanResponderTerminationRequest: () => true,
  });
  const summary = visible
    .map(
      (line) =>
        `${line.label}: ${pointMaps.get(line.key)?.get(selected ?? '') == null ? '—' : format(pointMaps.get(line.key)!.get(selected!)!)}`,
    )
    .join(', ');
  return (
    <StatsChartFrame
      title={title}
      exportTitle={exportTitle}
      showTitle={showTitle}
      copyEnabled={exportable}
    >
      {series.length > 1 && legendMode !== 'hidden' ? (
        <View style={[styles.legend, !showTitle && exportable && { paddingRight: 38 }]}>
          {series.map((line, index) => {
            const value = pointMaps.get(line.key)?.get(legendDay ?? '');
            return (
              <Pressable
                key={line.key}
                accessibilityRole={legendMode === 'interactive' ? 'button' : undefined}
                disabled={legendMode === 'labels'}
                accessibilityLabel={line.label}
                accessibilityState={{ selected: !hidden.includes(line.key) }}
                onPress={() =>
                  setHidden((current) =>
                    current.includes(line.key)
                      ? current.filter((key) => key !== line.key)
                      : current.length < series.length - 1
                        ? [...current, line.key]
                        : current,
                  )
                }
                style={({ pressed }) => [
                  styles.legendItem,
                  { opacity: hidden.includes(line.key) ? 0.45 : pressed ? 0.65 : 1 },
                ]}
              >
                <View
                  style={[
                    styles.swatch,
                    { backgroundColor: line.color ?? palette[index % palette.length] },
                  ]}
                />
                <View style={styles.legendLabel}>
                  <CKText role="bodySmall">{line.label}</CKText>
                  {legendMode === 'interactive' ? (
                    <CKText
                      testID={`chart-selection-value-${line.key}`}
                      role="bodySmall"
                      numberOfLines={1}
                      style={styles.legendValue}
                    >
                      {value == null ? '—' : format(value)}
                    </CKText>
                  ) : null}
                </View>
              </Pressable>
            );
          })}
        </View>
      ) : null}
      {contentLoading ? (
        <Skeleton height={height} radius={12} />
      ) : values.length ? (
        <View
          {...responder.panHandlers}
          onLayout={(event) => setWidth(event.nativeEvent.layout.width)}
          onTouchStart={(event) => {
            touchStart.current = { x: event.nativeEvent.pageX, y: event.nativeEvent.pageY };
          }}
          onTouchEnd={(event) => {
            const start = touchStart.current;
            if (
              start &&
              Math.abs(event.nativeEvent.pageY - start.y) < 10 &&
              Math.abs(event.nativeEvent.pageX - start.x) < 10
            )
              selectAt(event.nativeEvent.locationX);
          }}
          accessible
          accessibilityRole="adjustable"
          accessibilityLabel={selected ? `${title}. ${dayLabel(selected)}. ${summary}` : title}
          accessibilityValue={{ min: 0, max: Math.max(0, days.length - 1), now: activeIndex }}
          accessibilityActions={[{ name: 'increment' }, { name: 'decrement' }]}
          onAccessibilityEscape={clearSelection}
          onAccessibilityAction={(event) =>
            selectDay(
              days[
                Math.max(
                  0,
                  Math.min(
                    days.length - 1,
                    activeIndex + (event.nativeEvent.actionName === 'increment' ? 1 : -1),
                  ),
                )
              ],
            )
          }
        >
          <Svg
            width="100%"
            height={height}
            viewBox={`0 0 ${viewWidth} ${height}`}
            pointerEvents="none"
          >
            {ticks.map((value, index) => (
              <ViewlessTick
                key={value}
                y={y(value)}
                label={
                  useResponsiveAxes ? yLabels[index]! : (formatAxisValue?.(value) ?? format(value))
                }
                left={left}
                right={right}
                fontSize={axisFontSize}
                labelGap={useResponsiveAxes ? 10 : 7}
                color={theme.onSurfaceVariant}
                grid={colorWithAlpha(theme.onSurface, 0.1)}
              />
            ))}
            {series.map((line, index) => {
              if (hidden.includes(line.key)) return null;
              const points = days.map((day) => ({
                day,
                value: pointMaps.get(line.key)?.get(day) ?? null,
              }));
              const color = line.color ?? palette[index % palette.length];
              const observed = points.flatMap((point, i) =>
                point.value != null && Number.isFinite(point.value) ? [i] : [],
              );
              const segments: number[][] = [];
              for (const i of observed) {
                const previous = segments.at(-1);
                if (previous && (connectGaps || previous.at(-1) === i - 1)) previous.push(i);
                else segments.push([i]);
              }
              const lines = segments.map((segment, part) =>
                segment.length === 1 ? (
                  <Circle
                    testID={`chart-point-${line.key}-${points[segment[0]!]!.day}`}
                    key={`${line.key}-${part}`}
                    cx={x(segment[0]!)}
                    cy={y(points[segment[0]!]!.value!)}
                    r={3}
                    fill={color}
                  />
                ) : (
                  <Polyline
                    testID={`chart-line-${line.key}`}
                    key={`${line.key}-${part}`}
                    points={segment.map((i) => `${x(i)},${y(points[i]!.value!)}`).join(' ')}
                    fill="none"
                    stroke={color}
                    strokeWidth={2.5}
                    strokeLinejoin="round"
                    strokeLinecap="round"
                    strokeDasharray={
                      index === 0
                        ? undefined
                        : index === 1
                          ? '7 3'
                          : index === 2
                            ? '2 3'
                            : '8 3 2 3'
                    }
                  />
                ),
              );
              return [
                ...lines,
                ...(showPoints
                  ? segments.flatMap((segment) =>
                      segment.length > 1
                        ? segment.map((i) => (
                            <Circle
                              key={`${line.key}-dot-${i}`}
                              testID={`chart-point-${line.key}-${points[i]!.day}`}
                              cx={x(i)}
                              cy={y(points[i]!.value!)}
                              r={3}
                              fill={color}
                            />
                          ))
                        : [],
                    )
                  : []),
              ];
            })}
            {selected ? (
              <Line
                x1={x(activeIndex)}
                x2={x(activeIndex)}
                y1={top}
                y2={bottom}
                stroke={theme.onSurfaceVariant}
                strokeOpacity={0.35}
              />
            ) : null}
            {selected
              ? series.map((line, index) => {
                  const value = pointMaps.get(line.key)?.get(selected);
                  return value == null || hidden.includes(line.key) ? null : (
                    <Circle
                      key={`selected-${line.key}`}
                      cx={x(activeIndex)}
                      cy={y(value)}
                      r={4}
                      fill={line.color ?? palette[index % palette.length]}
                      stroke={theme.surface}
                      strokeWidth={2}
                    />
                  );
                })
              : null}
            {xTicks.map((index) => (
              <SvgText
                key={index}
                x={x(index)}
                y={useResponsiveAxes ? bottom + 22 : height - 5}
                textAnchor={index === 0 ? 'start' : index === days.length - 1 ? 'end' : 'middle'}
                fill={theme.onSurfaceVariant}
                fontSize={axisFontSize}
              >
                {days[index] ? axisDayLabel(days[index]!) : null}
              </SvgText>
            ))}
          </Svg>
          {selected ? (
            <View
              pointerEvents="none"
              testID="chart-tooltip"
              style={[
                styles.tooltip,
                {
                  left: Math.max(
                    0,
                    Math.min(Math.max(0, width - 180), (x(activeIndex) / viewWidth) * width - 90),
                  ),
                  top: Math.max(
                    2,
                    Math.min(
                      bottom - 65,
                      y(
                        visible
                          .map((line) => pointMaps.get(line.key)?.get(selected))
                          .find((value) => value != null) ?? maximum,
                      ) - 70,
                    ),
                  ),
                  backgroundColor: theme.surfaceContainerHighest,
                },
              ]}
            >
              <CKText testID="chart-selection-date" role="labelLarge">
                {dayLabel(selected)}
              </CKText>
              {visible.map((line) => {
                const value = pointMaps.get(line.key)?.get(selected);
                return (
                  <View key={line.key} style={styles.tooltipRow}>
                    <View
                      style={[
                        styles.swatch,
                        {
                          backgroundColor:
                            line.color ?? palette[series.indexOf(line) % palette.length],
                        },
                      ]}
                    />
                    <View style={{ flexShrink: 1 }}>
                      <CKText role="bodySmall">
                        {line.label} {value == null ? '—' : format(value)}
                      </CKText>
                      {formatPointDetail?.(line.key, selected) ? (
                        <CKText muted role="labelSmall">
                          {formatPointDetail(line.key, selected)}
                        </CKText>
                      ) : null}
                    </View>
                  </View>
                );
              })}
            </View>
          ) : null}
        </View>
      ) : (
        <CKText muted role="bodySmall">
          {t('generalNoDataAvailable')}
        </CKText>
      )}
    </StatsChartFrame>
  );
}
function ViewlessTick({
  y,
  label,
  color,
  grid,
  left = LEFT,
  right = RIGHT,
  fontSize = 12,
  labelGap = 7,
}: {
  y: number;
  label: string;
  color: string;
  grid: string;
  left?: number;
  right?: number;
  fontSize?: number;
  labelGap?: number;
}) {
  return (
    <>
      <Line x1={left} x2={right} y1={y} y2={y} stroke={grid} />
      <SvgText x={left - labelGap} y={y + 4} textAnchor="end" fill={color} fontSize={fontSize}>
        {label}
      </SvgText>
    </>
  );
}
const styles = StyleSheet.create({
  root: { gap: 10 },
  flex: { flexShrink: 1 },
  legend: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  legendItem: { minHeight: 36, flexDirection: 'row', alignItems: 'center', gap: 5 },
  legendLabel: { gap: 2 },
  legendValue: { fontVariant: ['tabular-nums'] },
  tooltip: { position: 'absolute', maxWidth: 180, padding: 8, borderRadius: 12, gap: 4 },
  tooltipRow: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  swatch: { width: 12, height: 3, borderRadius: 2 },
});
