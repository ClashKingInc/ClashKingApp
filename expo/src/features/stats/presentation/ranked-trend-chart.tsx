import {
  createContext,
  useContext,
  useEffect,
  useId,
  useState,
  useRef,
  type ReactNode,
} from 'react';
import { StyleSheet, View, PanResponder } from 'react-native';
import Svg, { Circle, Defs, LinearGradient, Line, Path, Stop } from 'react-native-svg';
import { CKText, colorWithAlpha, useCKTheme } from '../../../ui';
import { toIntlLocale, useI18n } from '../../../i18n';
import type { AnalyticsSeries } from './analytics-chart';

const ChartDismissContext = createContext<Set<() => void> | null>(null);

/** Observe page touches without taking the responder away from scrolling or controls. */
export function RankedChartInteractionScope({ children }: { children: ReactNode }) {
  const [dismissers] = useState(() => new Set<() => void>());
  return (
    <ChartDismissContext.Provider value={dismissers}>
      <View
        style={{ flex: 1 }}
        onStartShouldSetResponderCapture={() => {
          dismissers.forEach((dismiss) => dismiss());
          return false;
        }}
      >
        {children}
      </View>
    </ChartDismissContext.Provider>
  );
}

/** A small comparison chart: exact headline values live outside the plot.
 * Missing dates split paths; smoothing never bridges gaps in the source. */
export function RankedTrendChart({
  series,
  percent = false,
  showLegend = false,
  xKind = 'date',
  xDomain,
  formatPointLabel,
  formatPointDetail,
  formatValue,
}: {
  series: readonly AnalyticsSeries[];
  percent?: boolean;
  showLegend?: boolean;
  xKind?: 'date' | 'rank' | 'number';
  xDomain?: readonly [number, number];
  formatPointLabel?: (value: string) => string;
  formatPointDetail?: (seriesKey: string, value: string) => string | undefined;
  formatValue?: (value: number) => string;
}) {
  const theme = useCKTheme(),
    { locale } = useI18n(),
    id = useId().replace(/[^a-zA-Z0-9]/g, '');
  const [width, setWidth] = useState(300);
  const [selected, setSelected] = useState<string>();
  const dismissers = useContext(ChartDismissContext);
  useEffect(() => {
    const dismiss = () => setSelected(undefined);
    dismissers?.add(dismiss);
    return () => {
      dismissers?.delete(dismiss);
    };
  }, [dismissers]);
  const [tooltipHeight, setTooltipHeight] = useState(70);
  const touch = useRef<{ x: number; y: number } | undefined>(undefined);
  const position = (value: string) =>
    xKind === 'rank'
      ? Math.log10(Math.max(1, Number(value)))
      : xKind === 'number'
        ? Number(value)
        : Date.parse(value);
  const all = series.flatMap((s) => s.points).filter((p) => p.value != null);
  const start = xDomain?.[0] ?? Math.min(...all.map((p) => position(p.day))),
    end = xDomain?.[1] ?? Math.max(...all.map((p) => position(p.day)));
  const values = all.map((p) => p.value!);
  const span = Math.max(...values) - Math.min(...values);
  const step = 10 ** Math.floor(Math.log10(span || Math.abs(values[0] ?? 1) * 0.1 || 1));
  const low = percent ? 0 : Math.floor(Math.min(...values) / step) * step;
  const high = percent
    ? Math.max(10, Math.ceil(Math.max(...values) / 10) * 10)
    : Math.max(low + step, Math.ceil(Math.max(...values) / step) * step);
  const tooltipWidth = Math.min(180, Math.max(100, width / 2 - 16));
  const left = 32,
    right = Math.max(40, width - 8),
    top = 12,
    bottom = 146;
  const format = new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 2 });
  const x = (day: string) => left + ((position(day) - start) / (end - start || 1)) * (right - left),
    y = (value: number) => bottom - ((value - low) / (high - low)) * (bottom - top);
  const date = (v: number) =>
    xKind === 'rank'
      ? `#${Math.round(10 ** v).toLocaleString(toIntlLocale(locale))}`
      : xKind === 'number'
        ? format.format(v)
        : Number.isFinite(v)
          ? new Date(v).toLocaleDateString(toIntlLocale(locale), {
              month: 'short',
              day: 'numeric',
              timeZone: 'UTC',
            })
          : '—';
  const segments = (line: AnalyticsSeries) => {
    const sorted = [...line.points].sort((a, b) => position(a.day) - position(b.day));
    const groups: { x: number; y: number }[][] = [];
    let current: { x: number; y: number }[] = [];
    let previous = 0;
    for (const p of sorted) {
      const time = position(p.day);
      if (p.value == null || (xKind === 'date' && previous && time - previous > 86400000)) {
        if (current.length) groups.push(current);
        current = [];
      }
      if (p.value != null) current.push({ x: x(p.day), y: y(p.value) });
      previous = time;
    }
    if (current.length) groups.push(current);
    return groups;
  };
  const path = (pts: { x: number; y: number }[]) => {
    if (!pts.length) return '';
    let out = `M${pts[0]!.x},${pts[0]!.y}`;
    for (let i = 1; i < pts.length; i++) {
      const p = pts[i - 1]!,
        q = pts[i]!,
        mid = (p.x + q.x) / 2;
      out += ` C${mid},${p.y} ${mid},${q.y} ${q.x},${q.y}`;
    }
    return out;
  };
  const days = [...new Set(all.map((p) => p.day))].sort((a, b) => position(a) - position(b));
  const currentSelected = selected && days.includes(selected) ? selected : undefined;
  const select = (px: number) => {
    const wanted = start + Math.max(0, Math.min(1, (px - left) / (right - left))) * (end - start);
    setSelected(
      days.reduce(
        (best, day) =>
          Math.abs(position(day) - wanted) < Math.abs(position(best) - wanted) ? day : best,
        days[0]!,
      ),
    );
  };
  const pan = PanResponder.create({
    onStartShouldSetPanResponder: () => false,
    onMoveShouldSetPanResponder: (_e, g) =>
      Math.abs(g.dx) > 7 && Math.abs(g.dx) > Math.abs(g.dy) * 1.25,
    onPanResponderMove: (e) => select(e.nativeEvent.locationX),
    onPanResponderTerminationRequest: () => true,
  });
  const describe = (value: number) =>
    formatValue?.(value) ?? `${format.format(value)}${percent ? '%' : ''}`;
  if (!all.length) return null;
  return (
    <View
      onLayout={(e) => setWidth(e.nativeEvent.layout.width)}
      {...pan.panHandlers}
      onTouchStart={(e) => {
        touch.current = { x: e.nativeEvent.pageX, y: e.nativeEvent.pageY };
      }}
      onTouchEnd={(e) => {
        if (
          touch.current &&
          Math.hypot(e.nativeEvent.pageX - touch.current.x, e.nativeEvent.pageY - touch.current.y) <
            8
        )
          select(e.nativeEvent.locationX);
      }}
      accessible
      accessibilityLabel={series
        .map(
          (s) =>
            `${s.label}: ${s.points
              .filter((p) => p.value != null)
              .map((p) => `${p.day} ${p.value!.toFixed(1)}${percent ? '%' : ''}`)
              .join(', ')}`,
        )
        .join('; ')}
    >
      {showLegend ? (
        <View style={{ flexDirection: 'row', gap: 16, paddingBottom: 12 }}>
          {series.map((s) => (
            <CKText key={s.key} role="labelSmall" style={{ color: s.color }}>
              {s.label}
            </CKText>
          ))}
        </View>
      ) : null}
      <View style={{ height: 160 }}>
        <Svg pointerEvents="none" width="100%" height={160}>
          <Defs>
            {series.map((s, i) => (
              <LinearGradient key={s.key} id={`${id}${i}`} x1="0%" y1="0%" x2="0%" y2="100%">
                <Stop offset="0%" stopColor={s.color ?? theme.primary} stopOpacity={0.2} />
                <Stop offset="100%" stopColor={s.color ?? theme.primary} stopOpacity={0} />
              </LinearGradient>
            ))}
          </Defs>
          {[low, (low + high) / 2, high].map((v) => (
            <Line
              key={v}
              x1={left}
              x2={right}
              y1={y(v)}
              y2={y(v)}
              stroke={colorWithAlpha(theme.onSurface, 0.07)}
              strokeWidth={1}
            />
          ))}
          {currentSelected ? (
            <Line
              x1={x(currentSelected)}
              x2={x(currentSelected)}
              y1={top}
              y2={bottom}
              stroke={theme.onSurfaceVariant}
              strokeDasharray="3 4"
              strokeOpacity={0.5}
            />
          ) : null}
          {series.map((s, i) =>
            segments(s).map((pts, j) => (
              <Viewless
                key={`${s.key}${j}`}
                line={path(pts)}
                area={`${path(pts)} L${pts.at(-1)!.x},${bottom} L${pts[0]!.x},${bottom} Z`}
                color={s.color ?? theme.primary}
                fill={`url(#${id}${i})`}
                end={pts.at(-1)!}
              />
            )),
          )}
        </Svg>
        {[high, (high + low) / 2, low].map((v, i) => (
          <CKText
            key={i}
            role="labelSmall"
            muted
            style={{ position: 'absolute', left: 0, top: y(v) - 7, fontSize: 10 }}
          >
            {format.format(v)}
            {percent ? '%' : ''}
          </CKText>
        ))}
        {/* Match the shared analytics popup; keep it out of layout and touch handling. */}
        {currentSelected ? (
          <View
            pointerEvents="none"
            testID="chart-tooltip"
            onLayout={(event) => setTooltipHeight(event.nativeEvent.layout.height)}
            style={[
              styles.tooltip,
              {
                // Keep the selected x-column clear, even when several series coincide.
                width: tooltipWidth,
                left:
                  x(currentSelected) < width / 2
                    ? Math.min(width - tooltipWidth, x(currentSelected) + 12)
                    : Math.max(0, x(currentSelected) - tooltipWidth - 12),
                top: Math.max(
                  2,
                  Math.min(
                    bottom - tooltipHeight,
                    y(
                      series
                        .flatMap((s) => s.points)
                        .find((p) => p.day === currentSelected && p.value != null)?.value ?? high,
                    ) -
                      tooltipHeight -
                      10,
                  ),
                ),
                backgroundColor: theme.surfaceContainerHighest,
              },
            ]}
          >
            <CKText role="labelLarge">
              {formatPointLabel?.(currentSelected) ?? date(position(currentSelected))}
            </CKText>
            {series.map((s) => {
              const p = s.points.find((p) => p.day === currentSelected);
              return p?.value != null ? (
                <View key={s.key} style={styles.tooltipRow}>
                  <View style={[styles.swatch, { backgroundColor: s.color ?? theme.primary }]} />
                  <View style={{ flexShrink: 1 }}>
                    <CKText role="bodySmall">
                      {s.label} {describe(p.value)}
                    </CKText>
                    {formatPointDetail?.(s.key, currentSelected) ? (
                      <CKText role="labelSmall" muted>
                        {formatPointDetail(s.key, currentSelected)}
                      </CKText>
                    ) : null}
                  </View>
                </View>
              ) : null;
            })}
          </View>
        ) : null}
      </View>
      {xKind === 'number' ? (
        <View style={styles.dates}>
          {[0, 1, 2, 3].map((i) => (
            <CKText key={i} role="labelSmall" muted>
              {format.format(start + ((end - start) * i) / 3)}
            </CKText>
          ))}
        </View>
      ) : xKind === 'rank' ? (
        <View style={{ height: 20 }}>
          {Array.from({ length: Math.floor(end) + 1 }, (_, i) => 10 ** i)
            .filter((v) => Math.log10(v) >= start && Math.log10(v) <= end)
            .map((v) => (
              <CKText
                key={v}
                role="labelSmall"
                muted
                style={{ position: 'absolute', left: x(String(v)) - 12, top: 0 }}
              >
                #{format.format(v)}
              </CKText>
            ))}
        </View>
      ) : (
        <View style={styles.dates}>
          <CKText role="labelSmall" muted>
            {date(start)}
          </CKText>
          <CKText role="labelSmall" muted>
            {date(end)}
          </CKText>
        </View>
      )}
    </View>
  );
}
function Viewless({
  line,
  area,
  color,
  fill,
  end,
}: {
  line: string;
  area: string;
  color: string;
  fill: string;
  end: { x: number; y: number };
}) {
  return (
    <>
      <Path d={area} fill={fill} />
      <Path d={line} stroke={color} strokeWidth={2.5} strokeLinecap="round" fill="none" />
      <Circle cx={end.x} cy={end.y} r={3} fill={color} />
    </>
  );
}
const styles = StyleSheet.create({
  tooltip: { position: 'absolute', maxWidth: 180, padding: 8, borderRadius: 12, gap: 4 },
  tooltipRow: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  swatch: { width: 12, height: 3, borderRadius: 2 },
  dates: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingLeft: 32,
    paddingRight: 8,
  },
});
