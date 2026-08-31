import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import Svg, { Circle, G, Line, Path, Rect, Text as SvgText } from 'react-native-svg';

import { CKText, Surface, colorWithAlpha, useCKTheme } from '../../../ui';
import type { LegendChartPoint } from '../data';

export function RankedLineChart({
  title,
  series,
  xLabel,
  yLabel,
  height = 390,
}: {
  title: string;
  series: readonly (readonly LegendChartPoint[])[];
  xLabel: (point: LegendChartPoint, index: number) => string;
  yLabel: (value: number) => string;
  height?: number;
}) {
  const theme = useCKTheme();
  const [width, setWidth] = useState(0);
  const [selected, setSelected] = useState<LegendChartPoint | null>(null);
  const points = series.flat();
  if (!points.length) return null;
  const chartWidth = Math.max(1, width - 70);
  const chartHeight = height - 92;
  const left = 56;
  const top = 12;
  const minX = Math.min(...points.map((point) => point.x));
  const maxX = Math.max(...points.map((point) => point.x));
  const minValue = Math.min(...points.map((point) => point.y));
  const maxValue = Math.max(...points.map((point) => point.y));
  const minY = Math.max(0, Math.floor(minValue / 100) * 100 - 100);
  const maxY = Math.ceil(maxValue / 100) * 100 + 100;
  const px = (x: number) => left + ((x - minX) / Math.max(1, maxX - minX)) * chartWidth;
  const py = (y: number) =>
    top + chartHeight - ((y - minY) / Math.max(1, maxY - minY)) * chartHeight;
  const labels = points.filter((_, index) => {
    const interval = points.length <= 6 ? 1 : Math.ceil(points.length / 6);
    return index % interval === 0 || index === points.length - 1;
  });
  return (
    <Surface radius={28} style={[styles.shell, { height }]}>
      <CKText role="sectionTitle" style={styles.title}>
        {title}
      </CKText>
      {selected ? (
        <CKText role="labelLarge" style={[styles.tooltip, { backgroundColor: theme.primary }]}>
          {yLabel(selected.y)} · {xLabel(selected, points.indexOf(selected))}
        </CKText>
      ) : null}
      <View style={styles.chart} onLayout={(event) => setWidth(event.nativeEvent.layout.width)}>
        {width > 0 ? (
          <Svg width={width} height={chartHeight + 52}>
            <Rect
              x={left}
              y={top}
              width={chartWidth}
              height={chartHeight}
              fill="none"
              stroke={theme.outlineVariant}
              strokeWidth={1}
            />
            {[0, 0.25, 0.5, 0.75, 1].map((ratio) => {
              const y = top + chartHeight * ratio;
              const value = maxY - (maxY - minY) * ratio;
              return (
                <G key={ratio}>
                  <Line
                    x1={left}
                    x2={left + chartWidth}
                    y1={y}
                    y2={y}
                    stroke={colorWithAlpha(theme.outlineVariant, 0.45)}
                    strokeWidth={1}
                  />
                  <SvgText
                    x={left - 6}
                    y={y + 4}
                    textAnchor="end"
                    fontSize={10}
                    fill={theme.onSurfaceVariant}
                  >
                    {yLabel(value)}
                  </SvgText>
                </G>
              );
            })}
            {series.map((line, lineIndex) => {
              const path = line
                .map((point, index) => `${index === 0 ? 'M' : 'L'} ${px(point.x)} ${py(point.y)}`)
                .join(' ');
              const area = line.length
                ? `${path} L ${px(line.at(-1)!.x)} ${top + chartHeight} L ${px(line[0]!.x)} ${top + chartHeight} Z`
                : '';
              return (
                <G key={lineIndex}>
                  <Path d={area} fill={colorWithAlpha(theme.primary, 0.18)} stroke="none" />
                  <Path d={path} fill="none" stroke={theme.primary} strokeWidth={2} />
                </G>
              );
            })}
            {points.map((point, index) => (
              <Circle
                key={`${point.x}-${index}`}
                cx={px(point.x)}
                cy={py(point.y)}
                r={selected === point ? 5 : 3.5}
                fill={theme.primary}
                onPress={() => setSelected((current) => (current === point ? null : point))}
              />
            ))}
            {labels.map((point) => (
              <SvgText
                key={`label-${point.x}`}
                x={px(point.x)}
                y={top + chartHeight + 22}
                textAnchor="middle"
                fontSize={9}
                fill={theme.onSurfaceVariant}
              >
                {xLabel(point, points.indexOf(point))}
              </SvgText>
            ))}
          </Svg>
        ) : null}
      </View>
    </Surface>
  );
}

const styles = StyleSheet.create({
  shell: { padding: 16 },
  title: { textAlign: 'center' },
  tooltip: {
    position: 'absolute',
    zIndex: 2,
    top: 48,
    alignSelf: 'center',
    color: '#FFF',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 12,
  },
  chart: { flex: 1, marginTop: 12 },
});
