import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import Svg, { Circle, Line, Polyline, Text } from 'react-native-svg';

import { useI18n } from '../../../i18n';
import { CKText, useCKTheme } from '../../../ui';

export interface LegendChartPoint {
  readonly day: string;
  readonly value: number | null;
}

const VIEWBOX_WIDTH = 360;
const PLOT_RIGHT = 348;
const PLOT_TOP = 16;

export function formatLegendChartValue(value: number, rank = false): string {
  const formatted = Math.round(value).toLocaleString('en-US');
  return rank ? `#${formatted}` : formatted;
}

export function legendChartPlotLeft(
  ticks: readonly number[],
  rank: boolean,
  fontSize: number,
): number {
  const widest = ticks.reduce((width, value) => {
    const label = formatLegendChartValue(value, rank);
    const estimatedWidth = [...label].reduce(
      (sum, character) => sum + fontSize * (character === ',' ? 0.34 : 0.62),
      0,
    );
    return Math.max(width, estimatedWidth);
  }, 0);
  return Math.min(124, Math.max(54, Math.ceil(widest + 16)));
}

export function legendChartSegments(points: readonly LegendChartPoint[]): readonly number[][] {
  const segments: number[][] = [];
  let current: number[] = [];
  points.forEach((point, index) => {
    if (point.value === null) {
      if (current.length) segments.push(current);
      current = [];
      return;
    }
    current.push(index);
  });
  if (current.length) segments.push(current);
  return segments;
}

export function legendChartY(
  value: number,
  minimum: number,
  maximum: number,
  rank: boolean,
  plotBottom: number,
): number {
  if (maximum === minimum) return (PLOT_TOP + plotBottom) / 2;
  const progress = (value - minimum) / (maximum - minimum);
  const visualProgress = rank ? progress : 1 - progress;
  return PLOT_TOP + visualProgress * (plotBottom - PLOT_TOP);
}

export function LegendChart({
  title,
  points,
  rank = false,
  dark = false,
  height = 184,
  large = false,
}: {
  readonly title: string;
  readonly points: readonly LegendChartPoint[];
  readonly rank?: boolean;
  readonly dark?: boolean;
  readonly height?: number;
  readonly large?: boolean;
}) {
  const theme = useCKTheme();
  const { t } = useI18n();
  const [selected, setSelected] = useState<string | null>(null);
  const valid = points.filter(
    (point): point is { day: string; value: number } => point.value !== null,
  );
  const minimum = valid.length ? Math.min(...valid.map((point) => point.value)) : 0;
  const maximum = valid.length ? Math.max(...valid.map((point) => point.value)) : 0;
  const plotBottom = Math.max(92, height - 34);
  const ticks = [...new Set([minimum, Math.round((minimum + maximum) / 2), maximum])];
  const axisFontSize = large ? 17 : 14;
  const plotLeft = legendChartPlotLeft(ticks, rank, axisFontSize);
  const x = (index: number) =>
    plotLeft + index * ((PLOT_RIGHT - plotLeft) / Math.max(1, points.length - 1));
  const y = (value: number) => legendChartY(value, minimum, maximum, rank, plotBottom);
  const focus = valid.find((point) => point.day === selected) ?? valid.at(-1);
  const focusIndex = focus ? points.findIndex((point) => point.day === focus.day) : -1;
  const palette = dark
    ? {
        grid: '#4B4C5A',
        label: '#C8CBD8',
        line: '#C6A7FF',
        marker: '#E2D4FF',
        focus: '#FFFFFF',
      }
    : {
        grid: theme.outlineVariant,
        label: theme.onSurfaceVariant,
        line: theme.primary,
        marker: theme.primary,
        focus: theme.onSurface,
      };
  const labelIndexes = [
    ...new Set([0, Math.floor((points.length - 1) / 2), points.length - 1]),
  ].filter((index) => index >= 0 && points[index]);

  return (
    <View style={styles.container}>
      <View style={styles.heading}>
        <CKText
          role="titleMedium"
          style={[
            styles.headingTitle,
            dark ? styles.white : undefined,
            large ? styles.largeTitle : undefined,
          ]}
        >
          {title}
        </CKText>
        <CKText
          role="bodySmall"
          style={[
            styles.headingValue,
            dark ? styles.soft : undefined,
            large ? styles.largeValue : undefined,
          ]}
          muted={!dark}
        >
          {focus
            ? `${focus.day.replace(/^\d{4}-/u, '')}  ·  ${formatLegendChartValue(focus.value, rank)}`
            : t('generalNoDataAvailable')}
        </CKText>
      </View>
      {valid.length ? (
        <Svg
          width="100%"
          height={height}
          viewBox={`0 0 ${VIEWBOX_WIDTH} ${height}`}
          accessibilityLabel={`${title}: ${valid
            .map((point) => `${point.day} ${formatLegendChartValue(point.value, rank)}`)
            .join(', ')}`}
        >
          {ticks.map((value) => (
            <Line
              key={`grid-${value}`}
              x1={plotLeft}
              x2={PLOT_RIGHT}
              y1={y(value)}
              y2={y(value)}
              stroke={palette.grid}
              strokeOpacity={0.44}
              strokeWidth={1}
            />
          ))}
          <Line
            x1={plotLeft}
            x2={plotLeft}
            y1={PLOT_TOP}
            y2={plotBottom}
            stroke={palette.grid}
            strokeOpacity={0.7}
          />
          <Line
            x1={plotLeft}
            x2={PLOT_RIGHT}
            y1={plotBottom}
            y2={plotBottom}
            stroke={palette.grid}
            strokeOpacity={0.7}
          />
          {ticks.map((value) => (
            <Text
              key={`label-${value}`}
              x={plotLeft - 10}
              y={y(value) + 5}
              textAnchor="end"
              fontSize={axisFontSize}
              fontWeight="600"
              fill={palette.label}
            >
              {formatLegendChartValue(value, rank)}
            </Text>
          ))}
          {focusIndex >= 0 ? (
            <Line
              x1={x(focusIndex)}
              x2={x(focusIndex)}
              y1={PLOT_TOP}
              y2={plotBottom}
              stroke={palette.focus}
              strokeOpacity={0.2}
              strokeDasharray="3 5"
            />
          ) : null}
          {legendChartSegments(points)
            .filter((segment) => segment.length > 1)
            .map((segment) => (
              <Polyline
                key={segment.join('-')}
                points={segment.map((index) => `${x(index)},${y(points[index]!.value!)}`).join(' ')}
                fill="none"
                stroke={palette.line}
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={3}
              />
            ))}
          {points.map((point, index) => {
            if (point.value === null) return null;
            return (
              <Circle
                key={`hit-${point.day}`}
                cx={x(index)}
                cy={y(point.value)}
                r={13}
                fill="transparent"
                onPress={() => setSelected(point.day)}
                accessibilityLabel={`${point.day}: ${formatLegendChartValue(point.value, rank)}`}
              />
            );
          })}
          {points.map((point, index) => {
            if (point.value === null) return null;
            const isSelected = focus?.day === point.day;
            return (
              <Circle
                key={point.day}
                cx={x(index)}
                cy={y(point.value)}
                r={isSelected ? 6 : 4}
                fill={isSelected ? palette.focus : palette.marker}
                stroke={palette.line}
                strokeWidth={isSelected ? 3 : 1.5}
                pointerEvents="none"
              />
            );
          })}
          {labelIndexes.map((index) => (
            <Text
              key={`day-${points[index]!.day}`}
              x={x(index)}
              y={height - 8}
              textAnchor={index === 0 ? 'start' : index === points.length - 1 ? 'end' : 'middle'}
              fontSize={large ? 16 : 13}
              fontWeight="600"
              fill={palette.label}
            >
              {points[index]!.day.replace(/^\d{4}-/u, '')}
            </Text>
          ))}
        </Svg>
      ) : (
        <View style={[styles.empty, { height }]}>
          <CKText role="bodySmall" style={dark ? styles.soft : undefined} muted={!dark}>
            {t('generalNoDataAvailable')}
          </CKText>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { gap: 8 },
  heading: {
    minHeight: 26,
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: 12,
  },
  headingTitle: { minWidth: 120, flexShrink: 1 },
  headingValue: { marginLeft: 'auto', flexShrink: 1, fontSize: 14, lineHeight: 19 },
  empty: { alignItems: 'center', justifyContent: 'center' },
  white: { color: '#FFFFFF' },
  soft: { color: '#C8CBD8' },
  largeTitle: { fontSize: 25, lineHeight: 29 },
  largeValue: { fontSize: 18, lineHeight: 22 },
});
