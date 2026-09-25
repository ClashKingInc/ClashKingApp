import { createContext, useContext, useState, type ReactNode } from 'react';
import { Modal, Pressable, View } from 'react-native';
import { SlidersHorizontal, X } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { CKText, ProfileTabs, colorWithAlpha, useCKTheme } from '../../../ui';
import { HeaderIconButton } from '../../../ui/header';
import { useI18n } from '../../../i18n';
import { StatsDateFilter, StatsSection } from '../models';
import type { StatsProvider } from '../data';

export type ChartGranularity = 'day' | 'week' | 'month';
const Preferences = createContext({
  granularity: 'day' as ChartGranularity,
  setGranularity: (_: ChartGranularity) => {},
});
export function StatsChartPreferencesProvider({
  children,
  provider,
}: {
  children: ReactNode;
  provider?: StatsProvider;
}) {
  'use no memo';
  const [local, setLocal] = useState({ granularity: 'day' as ChartGranularity });
  const stored = provider
    ? (provider.chartGranularities?.get(provider.section) ?? 'day')
    : local.granularity;
  const days =
    provider?.section === StatsSection.war
      ? (provider.warDates?.inclusiveDays ?? 90)
      : (provider?.dates?.inclusiveDays ?? 90);
  const allowed = statsIntervalOptions(provider?.section ?? StatsSection.war, days);
  const granularity = allowed.includes(stored) ? stored : allowed[0]!;
  const setGranularity = (value: ChartGranularity) => {
    if (provider) provider.chartGranularities?.set(provider.section, value);
    setLocal({ granularity: value });
  };
  return (
    <Preferences.Provider value={{ granularity, setGranularity }}>{children}</Preferences.Provider>
  );
}
export const useChartGranularity = () => useContext(Preferences).granularity;

export function statsIntervalOptions(section: string, days: number): readonly ChartGranularity[] {
  if (section === StatsSection.armies || section === StatsSection.items) return ['day'];
  return days >= 365 ? ['week', 'month'] : ['day', 'week', 'month'];
}

export function statsPresetDates(preset: number | 'all', now = new Date()): StatsDateFilter {
  const end = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const start = preset === 'all' ? new Date(2012, 7, 2) : new Date(end);
  if (preset !== 'all') start.setDate(start.getDate() - preset + 1);
  return new StatsDateFilter(start, end);
}

function sameDates(left: StatsDateFilter, right: StatsDateFilter): boolean {
  return (
    StatsDateFilter.formatDate(left.start) === StatsDateFilter.formatDate(right.start) &&
    StatsDateFilter.formatDate(left.end) === StatsDateFilter.formatDate(right.end)
  );
}

export function StatsChartSettings({
  provider,
  triggerColor,
}: {
  provider: StatsProvider;
  triggerColor?: string;
}) {
  'use no memo';
  const { t } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const prefs = useContext(Preferences);
  const isWar = provider.section === StatsSection.war;
  const activeDates = isWar ? (provider.warDates ?? provider.dates) : provider.dates;
  const [open, setOpen] = useState(false);
  const [preset, setPreset] = useState<number | 'all' | null>(null);
  const [rangeDirty, setRangeDirty] = useState(false);
  const [granularity, setGranularity] = useState(prefs.granularity);
  const presets: readonly (number | 'all')[] = isWar ? [7, 30, 90, 365, 'all'] : [7, 30, 90];
  const draftDays =
    rangeDirty && preset !== null
      ? preset === 'all'
        ? Infinity
        : preset
      : activeDates.inclusiveDays;
  const intervals = statsIntervalOptions(provider.section, draftDays);
  return (
    <>
      <HeaderIconButton
        glass={false}
        icon={<SlidersHorizontal color={triggerColor ?? theme.onSurface} size={22} />}
        label={t('generalSettings')}
        onPress={() => {
          setPreset(
            presets.find((value) => sameDates(activeDates, statsPresetDates(value))) ?? null,
          );
          setRangeDirty(false);
          setGranularity(prefs.granularity);
          setOpen(true);
        }}
      />
      <Modal visible={open} transparent animationType="fade" onRequestClose={() => setOpen(false)}>
        <View style={{ flex: 1, justifyContent: 'flex-end', backgroundColor: '#0008' }}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('generalCancel')}
            onPress={() => setOpen(false)}
            style={{ flex: 1 }}
          />
          <View
            style={{
              backgroundColor: theme.surface,
              borderTopLeftRadius: 28,
              borderTopRightRadius: 28,
              padding: 20,
              paddingBottom: Math.max(20, insets.bottom),
              gap: 16,
            }}
          >
            <View
              style={{
                flexDirection: 'row',
                alignItems: 'center',
                justifyContent: 'space-between',
              }}
            >
              <CKText role="titleMedium">{t('generalSettings')}</CKText>
              <HeaderIconButton
                glass={false}
                label={t('generalCancel')}
                onPress={() => setOpen(false)}
                icon={<X color={theme.onSurface} />}
              />
            </View>
            <CKText role="rowTitle">{t('statsDateRange')}</CKText>
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
              {presets.map((value) => (
                <Pressable
                  key={value}
                  accessibilityRole="radio"
                  accessibilityState={{ checked: preset === value }}
                  onPress={() => {
                    setPreset(value);
                    setRangeDirty(true);
                    const allowed = statsIntervalOptions(
                      provider.section,
                      value === 'all' ? Infinity : value,
                    );
                    if (!allowed.includes(granularity)) setGranularity(allowed[0]!);
                  }}
                  style={({ pressed }) => ({
                    paddingHorizontal: 16,
                    minHeight: 44,
                    justifyContent: 'center',
                    borderRadius: 12,
                    backgroundColor: colorWithAlpha(
                      preset === value ? theme.primary : theme.onSurface,
                      preset === value ? 0.16 : 0.06,
                    ),
                    opacity: pressed ? 0.65 : 1,
                  })}
                >
                  <CKText style={{ color: preset === value ? theme.primary : theme.onSurface }}>
                    {value === 'all'
                      ? t('generalAllTime')
                      : value === 365
                        ? `1 ${t('filtersYear')}`
                        : t('warStatsLastXDays', { number: value })}
                  </CKText>
                </Pressable>
              ))}
            </View>
            <CKText role="rowTitle">{t('statsChartGranularity')}</CKText>
            {intervals.length === 1 ? (
              <CKText muted>{t('statsDaily')}</CKText>
            ) : (
              <ProfileTabs
                variant="underline"
                tabs={intervals.map((key) => ({
                  key,
                  label: t(
                    key === 'day' ? 'statsDaily' : key === 'week' ? 'statsWeekly' : 'statsMonthly',
                  ),
                }))}
                selectedKey={granularity}
                onSelect={(key) => setGranularity(key as ChartGranularity)}
              />
            )}
            <Pressable
              accessibilityRole="button"
              onPress={() => {
                prefs.setGranularity(intervals.includes(granularity) ? granularity : intervals[0]!);
                setOpen(false);
                if (rangeDirty && preset !== null) {
                  const dates = statsPresetDates(preset);
                  if (!sameDates(activeDates, dates)) {
                    if (isWar) void provider.setWarDates(dates.start, dates.end);
                    else void provider.setDates(dates.start, dates.end);
                  }
                }
              }}
              style={({ pressed }) => ({
                alignItems: 'center',
                padding: 14,
                borderRadius: 16,
                backgroundColor: theme.primary,
                opacity: pressed ? 0.7 : 1,
              })}
            >
              <CKText style={{ color: theme.onPrimary }}>{t('generalApply')}</CKText>
            </Pressable>
          </View>
        </View>
      </Modal>
    </>
  );
}
