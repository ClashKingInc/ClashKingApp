import { useState, type ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { Filter, RotateCcw } from 'lucide-react-native';

import { useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  MobileWebImage,
  PillSurface,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';

export function ClanFilterBar({
  chips,
  middle,
  actions,
}: {
  chips: ReactNode;
  middle?: ReactNode;
  actions?: ReactNode;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState(false);
  return (
    <View style={styles.filterWrap}>
      <View style={styles.filterRow}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('generalFilters')}
          accessibilityState={{ expanded }}
          onPress={() => setExpanded(!expanded)}
          style={[
            styles.filterButton,
            {
              backgroundColor: colorWithAlpha(
                expanded ? theme.primary : theme.surfaceContainerHighest,
                expanded ? 0.14 : 0.45,
              ),
              borderColor: colorWithAlpha(
                expanded ? theme.primary : theme.outlineVariant,
                expanded ? 0.4 : 0.32,
              ),
            },
          ]}
        >
          <Filter size={18} color={theme.onSurface} />
        </Pressable>
        {actions}
        <View style={styles.filterMiddle}>{middle}</View>
      </View>
      {expanded ? <View style={styles.filterChips}>{chips}</View> : null}
    </View>
  );
}

export function FilterPill({
  label,
  selected,
  onPress,
  icon,
  imageUrl,
  color,
}: {
  label: string;
  selected: boolean;
  onPress: () => void;
  icon?: ReactNode;
  imageUrl?: string;
  color?: string;
}) {
  const theme = useCKTheme();
  const accent = color ?? theme.primary;
  return (
    <Pressable
      accessibilityRole="checkbox"
      accessibilityState={{ checked: selected }}
      accessibilityLabel={label}
      onPress={onPress}
    >
      <View
        style={[
          styles.pill,
          {
            backgroundColor: colorWithAlpha(
              selected ? accent : theme.surfaceContainerHighest,
              selected ? 0.16 : 0.38,
            ),
            borderColor: colorWithAlpha(
              selected ? accent : theme.outlineVariant,
              selected ? 0.42 : 0.28,
            ),
          },
        ]}
      >
        {imageUrl ? <MobileWebImage imageUrl={imageUrl} style={styles.pillImage} /> : icon}
        <CKText role="labelMedium" style={{ fontWeight: selected ? '900' : '700' }}>
          {label}
        </CKText>
      </View>
    </Pressable>
  );
}

export function SummaryChip({
  value,
  label,
  icon,
  imageUrl,
  selected,
  onPress,
}: {
  value: string;
  label: string;
  icon?: ReactNode;
  imageUrl?: string;
  selected?: boolean;
  onPress?: () => void;
}) {
  const theme = useCKTheme();
  const content = (
    <PillSurface
      style={[styles.summary, selected && { borderColor: colorWithAlpha(theme.primary, 0.42) }]}
    >
      {imageUrl ? <MobileWebImage imageUrl={imageUrl} style={styles.summaryImage} /> : icon}
      <View>
        <CKText role="labelLarge" numberOfLines={1}>
          {value}
        </CKText>
        <CKText muted role="labelSmall" numberOfLines={1}>
          {label}
        </CKText>
      </View>
    </PillSurface>
  );
  return onPress ? (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${label}: ${value}`}
      onPress={onPress}
    >
      {content}
    </Pressable>
  ) : (
    content
  );
}

export function SummaryRail({ children }: { children: ReactNode }) {
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.summaryRail}
    >
      {children}
    </ScrollView>
  );
}

export function ClanTabEmpty({
  title,
  body,
  onRetry,
}: {
  title: string;
  body?: string;
  onRetry?: () => void;
}) {
  const theme = useCKTheme();
  const { t } = useI18n();
  return (
    <EmptyState
      title={title}
      body={body}
      icon={<RotateCcw color={theme.onSurfaceVariant} />}
      actionLabel={onRetry ? t('generalRetry') : undefined}
      onAction={onRetry}
    />
  );
}

export function relativeClanEventTime(value: Date, now = new Date()): string {
  const difference = Math.max(0, now.getTime() - value.getTime());
  const minutes = Math.floor(difference / 60_000);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  if (days >= 30) return `${Math.floor(days / 30)}mo ago`;
  if (days >= 1) return `${days}d ago`;
  if (hours >= 1) return `${hours}h ago`;
  if (minutes >= 1) return `${minutes}m ago`;
  return 'now';
}

const styles = StyleSheet.create({
  filterWrap: { gap: 8 },
  filterRow: { minHeight: 40, flexDirection: 'row', alignItems: 'center', gap: 8 },
  filterButton: {
    width: 40,
    height: 40,
    borderRadius: 16,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  filterMiddle: { flex: 1 },
  filterChips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  pill: {
    height: 36,
    paddingHorizontal: 11,
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
  },
  pillImage: { width: 15, height: 15, resizeMode: 'contain' },
  summaryRail: { gap: 8 },
  summary: {
    minHeight: 40,
    paddingHorizontal: 9,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  summaryImage: { width: 18, height: 18, resizeMode: 'contain' },
});
