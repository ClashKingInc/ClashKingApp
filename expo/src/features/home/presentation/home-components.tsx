import type { ScrollViewInstance } from 'react-native';
import { ASSET_ORIGIN } from '../../../core/assets/asset-origin';
import { Children, createContext, useContext, useRef, useState, type ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { Check, ChevronLeft, ChevronRight, Group, ImageOff } from 'lucide-react-native';
import Svg, { Circle as SvgCircle } from 'react-native-svg';

import { ImageAssets } from '../../../core/assets/image-assets';
import { CardAtmosphere } from '../../../ui/card-appearance';
import { AccountBarScrollView } from '../../../ui/account-bar-scroll-view';
import { materialNextPageTooltip, materialPreviousPageTooltip, useI18n } from '../../../i18n';
import {
  CKText,
  MobileWebImage,
  Skeleton,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  statColors,
  useCKTheme,
} from '../../../ui';
import {
  homeComparisonCardWidth,
  homeComparisonNeedsNavigation,
  normalizedProgress,
  type HomeAccountIdentity,
  type HomeMetricModel,
} from './contracts';

export const HOME_METRIC_HEIGHT = 44;
export const HOME_METRIC_GAP = 6;
export const HomeDragContext = createContext(false);

export function HomeCardFrame({
  children,
  header,
  onPress,
  actionLabel,
  accent,
  footer,
}: {
  children: ReactNode;
  header?: ReactNode;
  onPress?: () => void;
  actionLabel?: string;
  accent?: string;
  footer?: ReactNode;
}) {
  const theme = useCKTheme();
  const dragging = useContext(HomeDragContext);
  const pressStart = useRef({ x: 0, y: 0 });
  const pressDelta = useRef({ x: 0, y: 0 });
  return (
    <View
      style={[
        styles.frame,
        { backgroundColor: theme.surface, borderColor: colorWithAlpha(theme.outlineVariant, 0.32) },
      ]}
    >
      <CardAtmosphere color={accent} />
      {header}
      {onPress ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={actionLabel}
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
            if (dragging) return;
            // Swipes belong to the outer page, never account selection or detail navigation.
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
          {children}
        </Pressable>
      ) : (
        children
      )}
      {footer ? <View style={styles.footer}>{footer}</View> : null}
    </View>
  );
}

export function HomeCardSkeleton({ rows }: { rows: number }) {
  return (
    <HomeCardFrame>
      <View style={styles.skeletonHeader}>
        <Skeleton width={46} height={46} radius={12} />
        <View style={styles.flex}>
          <Skeleton width={120} />
          <Skeleton width={70} height={12} />
        </View>
        <Skeleton width={46} height={46} radius={23} />
      </View>
      <Skeleton height={14} />
      {Array.from({ length: rows }, (_, index) => (
        <View key={index} style={styles.metricRow}>
          <Skeleton height={HOME_METRIC_HEIGHT} style={styles.flex} />
          <Skeleton height={HOME_METRIC_HEIGHT} style={styles.flex} />
        </View>
      ))}
    </HomeCardFrame>
  );
}

const metricAssets: Record<HomeMetricModel['kind'], string> = {
  legendAttacks: `${ASSET_ORIGIN}/icons/Icon_HV_League_Legend_3_No_Padding.png`,
  warAttacks: `${ASSET_ORIGIN}/icons/Icon_DC_War.png`,
  cwlAttacks: `${ASSET_ORIGIN}/icons/Icon_DC_CWL_No_Border.png`,
  raidAttacks: `${ASSET_ORIGIN}/icons/Icon_HV_Raid_Attack.png`,
  clanGames: `${ASSET_ORIGIN}/icons/Icon_HV_Clan_Games_Medal.png`,
  seasonPass: `${ASSET_ORIGIN}/icons/Icon_HV_Gold_Pass.png`,
  rankedAttacks: `${ASSET_ORIGIN}/icons/Icon_HV_Sword.png`,
  rankedDefenses: `${ASSET_ORIGIN}/icons/Icon_HV_Shield_Arrow.png`,
  builders: ImageAssets.getHomeVillageBuildingImage("Builder's Hut", 1),
  laboratory: ImageAssets.getHomeVillageBuildingImage('Laboratory', 1),
  pets: ImageAssets.getHomeVillageBuildingImage('Pet House', 1),
  walls: ImageAssets.getHomeVillageBuildingImage('Wall', 1),
};

export function HomeMetricPill({ metric, label }: { metric: HomeMetricModel; label: string }) {
  const theme = useCKTheme();
  const progress = normalizedProgress(metric.done, metric.total);
  const value =
    metric.displayValue ??
    (metric.total === null ? `${metric.done}` : `${metric.done}/${metric.total}`);
  return (
    <View
      accessible
      accessibilityLabel={metric.detail ? `${label}, ${metric.detail}` : `${label}, ${value}`}
      style={[
        styles.metric,
        {
          backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.18),
        },
      ]}
    >
      <MobileWebImage
        imageUrl={metricAssets[metric.kind]}
        style={styles.metricImage}
        errorFallback={<ImageOff color={theme.onSurfaceVariant} size={18} />}
      />
      <View style={styles.flex}>
        <View style={styles.metricLabelRow}>
          <CKText muted role="labelMedium" numberOfLines={1} style={styles.flex}>
            {label}
          </CKText>
          {metric.meta ? (
            <CKText muted role="labelMedium">
              {metric.meta}
            </CKText>
          ) : null}
        </View>
        <CKText
          role="labelLarge"
          numberOfLines={1}
          style={progress === 1 ? { color: statColors.win, fontWeight: '900' } : styles.heavy}
        >
          {value}
        </CKText>
      </View>
    </View>
  );
}

export function HomeMetricGrid({ children }: { children: ReactNode }) {
  return (
    <View style={styles.grid}>
      {Children.map(children, (child) => (
        <View style={styles.gridCell}>{child}</View>
      ))}
    </View>
  );
}

export interface HomeRailEntry extends HomeAccountIdentity {
  readonly pending?: boolean | null;
}

/** Only the footer scrolls between account choices; the card itself never pages. */
export function HomeAccountBar({
  entries,
  selectedIndex,
  onSelect,
}: {
  entries: readonly HomeRailEntry[];
  selectedIndex: number;
  onSelect: (index: number) => void;
}) {
  const theme = useCKTheme();
  const { isRtl } = useI18n();
  if (entries.length < 2) return null;
  return (
    <AccountBarScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      testID="home-account-bar"
      contentContainerStyle={[styles.accountBar, isRtl && styles.rowRtl]}
      style={[{ backgroundColor: colorWithAlpha(theme.onSurface, 0.035) }]}
    >
      {entries.map((entry, index) => {
        const selected = index === selectedIndex;
        return (
          <Pressable
            key={entry.tag}
            accessibilityRole="button"
            accessibilityLabel={entry.name}
            accessibilityState={{ selected }}
            hitSlop={{ top: 10, bottom: 10 }}
            onPress={() => onSelect(index)}
            style={({ pressed }) => [
              styles.accountTarget,
              {
                backgroundColor: colorWithAlpha(
                  theme.onSurface,
                  pressed ? 0.14 : selected ? 0.08 : 0,
                ),
              },
            ]}
          >
            {entry.imageUrl ? (
              <MobileWebImage imageUrl={entry.imageUrl} style={styles.accountImage} />
            ) : (
              <Group size={13} color={theme.onSurfaceVariant} />
            )}
            <CKText
              role="labelMedium"
              muted={!selected}
              numberOfLines={1}
              style={[styles.accountName, { opacity: selected ? 1 : 0.65 }]}
            >
              {entry.name}
            </CKText>
          </Pressable>
        );
      })}
    </AccountBarScrollView>
  );
}

export function ProgressRing({
  progress,
  size,
  label,
  labelFontSize,
  showLabel = true,
}: {
  progress: number;
  size: number;
  label?: string;
  labelFontSize?: number;
  showLabel?: boolean;
}) {
  const theme = useCKTheme();
  const value = normalizeHomeProgress(progress);
  const progressLabel = label ?? formatHomeProgressRingLabel(value);
  const stroke = 4;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  return (
    <View
      accessibilityRole="progressbar"
      accessibilityValue={{ min: 0, max: 100, now: Math.round(value * 100) }}
      style={{ width: size, height: size }}
    >
      <Svg width={size} height={size} style={StyleSheet.absoluteFill}>
        <SvgCircle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={theme.surfaceContainerHighest}
          strokeWidth={stroke}
        />
        <SvgCircle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={statColors.win}
          strokeWidth={stroke}
          strokeDasharray={`${circumference} ${circumference}`}
          strokeDashoffset={circumference * (1 - value)}
          strokeLinecap="round"
          // Keep the pivot in the SVG transform: origin emits an invalid
          // transform-origin DOM prop on web. Both platforms start at noon.
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </Svg>
      {showLabel ? (
        <View style={styles.ringLabel}>
          <CKText
            role="titleSmall"
            numberOfLines={1}
            style={[styles.heavy, { fontSize: labelFontSize ?? Math.max(12, size * 0.28) }]}
          >
            {progressLabel}
          </CKText>
        </View>
      ) : null}
    </View>
  );
}

export function formatHomeProgressRingLabel(progress: number): string {
  return `${Math.round(normalizeHomeProgress(progress) * 100)}%`;
}

function normalizeHomeProgress(progress: number): number {
  return Number.isFinite(progress) ? Math.max(0, Math.min(1, progress)) : 0;
}

export function DesktopComparison({
  items,
  summaryFirst = false,
  renderItem,
}: {
  items: readonly string[];
  summaryFirst?: boolean;
  renderItem: (index: number) => ReactNode;
}) {
  const theme = useCKTheme();
  const { isRtl, locale } = useI18n();
  const [availableWidth, setAvailableWidth] = useState(1120);
  const [scrollX, setScrollX] = useState(0);
  const [contentWidth, setContentWidth] = useState(0);
  const railRef = useRef<ScrollViewInstance>(null);
  const width = homeComparisonCardWidth(availableWidth, items.length, summaryFirst);
  const showsNavigation = homeComparisonNeedsNavigation(availableWidth, items.length);
  const start = summaryFirst ? 1 : 0;
  const railViewport = Math.max(
    0,
    availableWidth - (summaryFirst ? width + ckSpacing.md : 0) - (showsNavigation ? 88 : 0),
  );
  const maxScroll = Math.max(0, contentWidth - railViewport);
  const scrollBy = (delta: number) =>
    railRef.current?.scrollTo({
      x: Math.max(0, Math.min(maxScroll, scrollX + delta)),
      animated: true,
    });
  return (
    <View
      style={[styles.comparison, isRtl && styles.rowRtl]}
      onLayout={(event) => setAvailableWidth(event.nativeEvent.layout.width)}
    >
      {summaryFirst ? <View style={{ width }}>{renderItem(0)}</View> : null}
      {summaryFirst ? <View style={{ width: ckSpacing.md }} /> : null}
      <ScrollView
        ref={railRef}
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.comparisonRail}
        scrollEventThrottle={16}
        onScroll={(event) => setScrollX(event.nativeEvent.contentOffset.x)}
        onContentSizeChange={(content) => setContentWidth(content)}
        style={isRtl ? styles.rtlScroll : undefined}
      >
        {items.slice(start).map((key, localIndex) => (
          <View key={key} style={[{ width }, isRtl && styles.rtlItem]}>
            {renderItem(localIndex + start)}
          </View>
        ))}
      </ScrollView>
      {showsNavigation ? (
        <View style={styles.comparisonButtons}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={materialPreviousPageTooltip(locale)}
            disabled={scrollX <= 1}
            onPress={() => scrollBy(-(width + ckSpacing.md))}
            style={styles.comparisonButton}
          >
            {isRtl ? (
              <ChevronRight color={theme.onSurfaceVariant} />
            ) : (
              <ChevronLeft color={theme.onSurfaceVariant} />
            )}
          </Pressable>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={materialNextPageTooltip(locale)}
            disabled={scrollX >= maxScroll - 1}
            onPress={() => scrollBy(width + ckSpacing.md)}
            style={styles.comparisonButton}
          >
            {isRtl ? (
              <ChevronLeft color={theme.onSurfaceVariant} />
            ) : (
              <ChevronRight color={theme.onSurfaceVariant} />
            )}
          </Pressable>
        </View>
      ) : null}
    </View>
  );
}

export function CardHeader({
  imageUrl,
  title,
  subtitle,
  trailing,
  size = 46,
  cornerImageUrl,
  detail,
}: {
  imageUrl: string;
  title: string;
  subtitle?: string;
  trailing?: ReactNode;
  size?: number;
  cornerImageUrl?: string;
  detail?: ReactNode;
}) {
  return (
    <View style={styles.header}>
      <View style={{ width: size, height: size }}>
        <MobileWebImage
          imageUrl={imageUrl}
          style={{ width: size, height: size, resizeMode: 'contain' }}
        />
        {cornerImageUrl ? (
          <MobileWebImage
            imageUrl={cornerImageUrl}
            style={{
              position: 'absolute',
              right: -5,
              top: -5,
              width: 26,
              height: 26,
              resizeMode: 'contain',
            }}
          />
        ) : null}
      </View>
      <View style={styles.headerCopy}>
        <CKText role="titleSmall" numberOfLines={1} style={styles.heavy}>
          {title}
        </CKText>
        {subtitle ? (
          <CKText muted role="labelLarge" numberOfLines={1}>
            {subtitle}
          </CKText>
        ) : null}
        {detail}
      </View>
      {trailing ? <View style={styles.headerTrailing}>{trailing}</View> : null}
    </View>
  );
}

export function StatusRow({
  children,
  chevron = false,
}: {
  children: ReactNode;
  chevron?: boolean;
}) {
  const theme = useCKTheme();
  const { isRtl } = useI18n();
  return (
    <View style={styles.statusRow}>
      <View style={styles.flex}>{children}</View>
      {chevron ? (
        isRtl ? (
          <ChevronLeft size={22} color={theme.onSurfaceVariant} />
        ) : (
          <ChevronRight size={22} color={theme.onSurfaceVariant} />
        )
      ) : null}
    </View>
  );
}

export function CaughtUp({ label }: { label: string }) {
  return (
    <View style={styles.caughtUp}>
      <Check size={18} color={statColors.win} />
      <CKText muted role="labelMedium" numberOfLines={1}>
        {label}
      </CKText>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  heavy: { fontWeight: '900' },
  frame: {
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 28,
    padding: 14,
    gap: 10,
    overflow: 'hidden',
  },
  footer: { marginHorizontal: -14, marginBottom: -14 },
  accountBar: {
    // Fill spare width to center short rows; overflowing content still scrolls.
    flexGrow: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
    paddingHorizontal: 16,
    paddingVertical: 6,
  },
  accountTarget: {
    // Keep the footer height and label spacing unchanged while giving the
    // selection/press fill breathing room and a rounded edge around the icon.
    maxWidth: 120,
    flexShrink: 0,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 4,
    paddingVertical: 4,
    borderRadius: ckRadius.pill,
  },
  accountImage: { width: 13, height: 13 },
  accountName: { flexShrink: 1, minWidth: 0, fontWeight: '700' },
  skeletonHeader: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  metricRow: { flexDirection: 'row', gap: HOME_METRIC_GAP },
  metric: {
    height: HOME_METRIC_HEIGHT,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    paddingHorizontal: 11,
    borderRadius: ckRadius.pill,
    borderWidth: 0,
  },
  metricImage: { width: 20, height: 20, resizeMode: 'contain' },
  metricLabelRow: { flexDirection: 'row', gap: 5 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', margin: -HOME_METRIC_GAP / 2 },
  gridCell: { width: '50%', padding: HOME_METRIC_GAP / 2 },
  singleRail: { flexDirection: 'row', alignItems: 'center', gap: 6, paddingVertical: 3 },
  singleRailImage: { width: 20, height: 20, resizeMode: 'contain' },
  railContainer: { minWidth: 0 },
  rail: { minHeight: 44, flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', gap: 4 },
  railTarget: {
    height: 28,
    minWidth: 28,
    maxWidth: 126,
    borderRadius: ckRadius.pill,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingRight: 9,
    paddingLeft: 1,
  },
  railImage: { width: 26, height: 26, resizeMode: 'contain' },
  recede: { opacity: 0.5 },
  rtlScroll: { transform: [{ scaleX: -1 }] },
  rtlItem: { transform: [{ scaleX: -1 }] },
  rowRtl: { flexDirection: 'row-reverse' },
  railName: { flexShrink: 1, minWidth: 0, fontWeight: '900' },
  pending: { position: 'absolute', width: 9, height: 9, borderRadius: 5, right: 0, top: 0 },
  ringLabel: { ...StyleSheet.absoluteFill, alignItems: 'center', justifyContent: 'center' },
  comparison: { flexDirection: 'row', alignItems: 'stretch' },
  comparisonRail: { gap: ckSpacing.md },
  comparisonButtons: {
    width: 88,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
  },
  comparisonButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  header: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  headerCopy: { flex: 1, gap: 2 },
  headerTrailing: { alignSelf: 'flex-start', alignItems: 'center' },
  statusRow: { minHeight: 22, flexDirection: 'row', alignItems: 'center' },
  caughtUp: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
});
