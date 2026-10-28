import { Children, useRef, type ReactNode } from 'react';
import { Pressable, StyleSheet, View, type LayoutChangeEvent } from 'react-native';
import { CKText } from './text';
import { useCKTheme } from './theme';
import { ckColors, ckRadius, colorWithAlpha } from './tokens';
import { useTabletTypography } from './typography-context';

export const DASHBOARD_METRIC_HEIGHT = 44;
export const DASHBOARD_METRIC_GAP = 6;

/** Home and detail cards share their surface and swipe-safe press behavior. */
export function DashboardCardFrame({
  children,
  header,
  onPress,
  actionLabel,
  actionHint,
  footer,
  pressEnabled = true,
  onLayout,
}: {
  children: ReactNode;
  header?: ReactNode;
  onPress?: () => void;
  actionLabel?: string;
  actionHint?: string;
  footer?: ReactNode;
  pressEnabled?: boolean;
  onLayout?: (event: LayoutChangeEvent) => void;
}) {
  const theme = useCKTheme();
  const tablet = useTabletTypography();
  const pressStart = useRef({ x: 0, y: 0 });
  const pressDelta = useRef({ x: 0, y: 0 });
  return (
    <View
      onLayout={onLayout}
      style={[styles.frame, tablet && styles.tabletFrame, { backgroundColor: theme.surface }]}
    >
      {onPress ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={actionLabel}
          accessibilityHint={actionHint}
          onPressIn={(event) => {
            pressStart.current = { x: event.nativeEvent.pageX, y: event.nativeEvent.pageY };
            pressDelta.current = { x: 0, y: 0 };
          }}
          onTouchMove={(event) => {
            pressDelta.current = {
              x: event.nativeEvent.pageX - pressStart.current.x,
              y: event.nativeEvent.pageY - pressStart.current.y,
            };
          }}
          onPress={(event) => {
            if (!pressEnabled) return;
            // A scroll or held drag must not open a home card or flip a detail card.
            const dx = Math.max(
              Math.abs(event.nativeEvent.pageX - pressStart.current.x),
              Math.abs(pressDelta.current.x),
            );
            const dy = Math.max(
              Math.abs(event.nativeEvent.pageY - pressStart.current.y),
              Math.abs(pressDelta.current.y),
            );
            if (dx > 12 || dy > 12) return;
            onPress();
          }}
        >
          {header}
          {children}
        </Pressable>
      ) : (
        <>
          {header}
          {children}
        </>
      )}
      {footer ? <View style={[styles.footer, tablet && styles.tabletFooter]}>{footer}</View> : null}
    </View>
  );
}

export function DashboardMetric({
  artwork,
  label,
  value,
  meta,
  detail,
  valueColor,
  tone,
}: {
  artwork: ReactNode;
  label: string;
  value: string;
  meta?: string;
  detail?: string;
  valueColor?: string;
  tone?: 'danger';
}) {
  const theme = useCKTheme();
  const tablet = useTabletTypography();
  return (
    <View
      accessible
      accessibilityLabel={detail ? `${label}, ${detail}` : `${label}, ${value}`}
      style={[
        styles.metric,
        tablet && styles.tabletMetric,
        {
          backgroundColor:
            tone === 'danger'
              ? colorWithAlpha(ckColors.lossRed, 0.12)
              : colorWithAlpha(theme.surfaceContainerHighest, 0.18),
        },
      ]}
    >
      {artwork}
      <View style={styles.flex}>
        <View style={styles.labelRow}>
          {/* The metric is known before its value arrives. */}
          <CKText skeleton={false} muted role="labelMedium" numberOfLines={1} style={styles.flex}>
            {label}
          </CKText>
          {meta ? (
            <CKText muted role="labelMedium">
              {meta}
            </CKText>
          ) : null}
        </View>
        <CKText
          role="labelLarge"
          numberOfLines={1}
          style={[styles.heavy, valueColor ? { color: valueColor } : undefined]}
        >
          {value}
        </CKText>
      </View>
    </View>
  );
}
export function DashboardMetricGrid({ children }: { children: ReactNode }) {
  return (
    <View style={styles.grid}>
      {Children.map(children, (child) => (
        <View style={styles.gridCell}>{child}</View>
      ))}
    </View>
  );
}
const styles = StyleSheet.create({
  frame: { borderRadius: ckRadius.card, padding: 14, gap: 10, overflow: 'hidden' },
  footer: { marginHorizontal: -14, marginBottom: -14 },
  tabletFrame: { padding: 22, gap: 16 },
  tabletFooter: { marginHorizontal: -22, marginBottom: -22 },
  tabletMetric: {
    minHeight: 62,
    height: 'auto',
    paddingVertical: 10,
    gap: 10,
    paddingHorizontal: 15,
  },
  metric: {
    height: DASHBOARD_METRIC_HEIGHT,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    paddingHorizontal: 11,
    borderRadius: ckRadius.pill,
    borderWidth: 0,
  },
  flex: { flex: 1 },
  labelRow: { flexDirection: 'row', gap: 5 },
  heavy: { fontWeight: '900' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', margin: -DASHBOARD_METRIC_GAP / 2 },
  gridCell: { width: '50%', padding: DASHBOARD_METRIC_GAP / 2 },
});
