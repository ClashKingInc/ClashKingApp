import { useEffect, useState } from 'react';
import { Platform, Pressable, StyleSheet, View } from 'react-native';
import { Effect } from 'effect';
import Svg, { Rect, Line } from 'react-native-svg';
import { PlayerActivityEndpoint, type EndpointResponse } from '@clashking/api-contracts/expo';
import { useAppRuntime } from '../../../core/app/runtime-context';
import { ImageAssets } from '../../../core/assets/image-assets';
import { mapWithConcurrencyLimit } from '../../../core/utils/bounded-concurrency';
import {
  CKText,
  MobileWebImage,
  Skeleton,
  ckColors,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { toIntlLocale, useI18n } from '../../../i18n';
import { HomeCardFrame, HomeAccountDots } from './home-components';
import type { HomeAccountIdentity } from './contracts';

type Summary = EndpointResponse<typeof PlayerActivityEndpoint>;
type MetricKey =
  'gold' | 'elixir' | 'darkElixir' | 'donated' | 'received' | 'attacks' | 'upgradeLevels';
export function HomeActivityCard({
  accounts,
  refreshKey,
}: {
  accounts: readonly HomeAccountIdentity[];
  refreshKey?: string;
}) {
  const runtime = useAppRuntime();
  const theme = useCKTheme();
  const { t, locale } = useI18n();
  const [retry, setRetry] = useState(0);
  const [scope, setScope] = useState('all');
  const [selected, setSelected] = useState<MetricKey>('gold');
  const [chartWidth, setChartWidth] = useState(0);
  const [selectedDay, setSelectedDay] = useState<string>();
  const selectMetric = (key: MetricKey) => {
    if (key === selected) return;
    setSelectedDay(undefined);
    setSelected(key);
  };
  const [loaded, setLoaded] = useState<{ signature: string; data: Record<string, Summary | null> }>(
    { signature: '', data: {} },
  );
  // Load all verified links once. Changing the local scope reuses those results
  // and never labels a partial/failed aggregate as an all-account total.
  const tags = accounts
    .map((account) => account.tag)
    .sort()
    .join('|');
  const signature = tags + ':' + (refreshKey ?? '') + ':' + retry;
  const data = loaded.signature === signature ? loaded.data : {};
  useEffect(() => {
    let active = true;
    void mapWithConcurrencyLimit(
      tags.split('|').filter(Boolean),
      async (tag) => {
        try {
          const summary = await Effect.runPromise(
            runtime.contractApi.execute(PlayerActivityEndpoint, {
              path: { playerTag: tag },
              query: {},
              body: {},
            }),
          );
          return [tag, summary] as const;
        } catch {
          return [tag, null] as const;
        }
      },
      3,
    ).then((entries) => {
      if (active) setLoaded({ signature, data: Object.fromEntries(entries) });
    });
    return () => {
      active = false;
    };
  }, [runtime, tags, signature]);
  const scopedAccounts =
    scope === 'all' ? accounts : accounts.filter((account) => account.tag === scope);
  const selectedAccount = scope === 'all' ? undefined : scopedAccounts[0];
  const summaries = scopedAccounts.map((account) => data[account.tag]);
  const loading = summaries.some((summary) => summary === undefined);
  // Failed requests are not "no recorded data". Never label a partial aggregate
  // as the total for all verified accounts; let the user retry the complete set.
  const unavailable = summaries.some((summary) => summary === null);
  const sum = (key: Exclude<keyof Summary, 'from' | 'until' | 'days'>) =>
    summaries.reduce((total, summary) => total + Number(summary?.[key] ?? 0), 0);
  // Hermes versions can ignore Intl's compact notation. Scale explicitly so
  // mobile always shows K/M/B, while the decimal separator remains localized.
  const compact = (value: string | number) => {
    const n = Number(value);
    const unit = [
      [1e9, 'B'],
      [1e6, 'M'],
      [1e3, 'K'],
    ].find(([divisor]) => Math.abs(n) >= Number(divisor));
    return (
      new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: unit ? 1 : 0 }).format(
        n / Number(unit?.[0] ?? 1),
      ) + (unit?.[1] ?? '')
    );
  };
  const resources = [
    [ImageAssets.gold, 'gold'],
    [ImageAssets.elixir, 'elixir'],
    [ImageAssets.darkElixir, 'darkElixir'],
  ] as const;
  const labels: Record<MetricKey, string> = {
    gold: t('resourceGold'),
    elixir: t('resourceElixir'),
    darkElixir: t('resourceDarkElixir'),
    donated: t('playerDonatedTitle'),
    received: t('playerReceivedTitle'),
    attacks: t('warAttacksTitle'),
    upgradeLevels: t('upgradeTrackerUpgrades') + ' · ' + t('gameItemLevels'),
  };
  const accents: Record<MetricKey, string> = {
    gold: ckColors.warGold,
    elixir: ckColors.upgradePets,
    darkElixir: ckColors.capitalPurple,
    donated: ckColors.donationGreen,
    received: ckColors.donationGreen,
    attacks: ckColors.legendBlue,
    upgradeLevels: ckColors.builderBlue,
  };
  const accent = accents[selected];
  const daily = new Map<string, number>();
  const hasDaily =
    summaries.length > 0 && summaries.every((summary) => summary?.days !== undefined);
  // Merge by UTC date, not response index: cached accounts can have different
  // partial-day boundaries. Never synthesize a trend when daily data is absent.
  if (hasDaily)
    for (const summary of summaries)
      for (const day of summary?.days ?? []) {
        const value =
          selected === 'attacks'
            ? day.farmingAttacks + day.rankedAttacks + day.legendAttacks
            : Number(day[selected]);
        const key = day.from.slice(0, 10);
        daily.set(key, (daily.get(key) ?? 0) + value);
      }
  const points = [...daily].sort(([a], [b]) => a.localeCompare(b));
  const selectedPoint = points.find(([date]) => date === selectedDay);
  const dayLabel = selectedPoint
    ? new Intl.DateTimeFormat(toIntlLocale(locale), {
        month: 'short',
        day: 'numeric',
        timeZone: 'UTC',
      }).format(new Date(selectedPoint[0] + 'T00:00:00Z'))
    : undefined;
  const selectedAmount = selectedPoint
    ? new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 0 }).format(
        selectedPoint[1],
      )
    : undefined;
  const selectChartPosition = (x: number) => {
    if (!points.length || chartWidth <= 0) return;
    const index = Math.max(
      0,
      Math.min(points.length - 1, Math.floor((x / chartWidth) * points.length)),
    );
    const date = points[index]![0];
    setSelectedDay((current) => (current === date ? undefined : date));
  };
  const minimum = Math.min(0, ...points.map(([, value]) => value));
  const maximum = Math.max(0, ...points.map(([, value]) => value));
  const range = maximum - minimum || 1;
  const y = (value: number) => 62 - ((value - minimum) / range) * 58;
  const selectedStyle = (key: MetricKey) => ({
    backgroundColor: selected === key ? colorWithAlpha(accents[key], 0.1) : 'transparent',
    borderBottomColor: selected === key ? accents[key] : 'transparent',
  });
  const metric = (key: MetricKey, value: number, image: string) => (
    <Pressable
      key={key}
      accessibilityRole="button"
      accessibilityLabel={labels[key]}
      accessibilityState={{ selected: selected === key }}
      onPress={() => selectMetric(key)}
      style={[styles.metric, styles.selectable, selectedStyle(key)]}
    >
      <MobileWebImage imageUrl={image} style={styles.metricImage} />
      <View style={styles.metricText}>
        <CKText muted role="labelMedium">
          {labels[key]}
        </CKText>
        <CKText role="bodyLarge" style={{ fontWeight: '700' }}>
          {compact(value)}
        </CKText>
      </View>
    </Pressable>
  );
  return (
    <HomeCardFrame
      accent={accent}
      onPage={
        accounts.length > 1
          ? (direction) => {
              const page =
                scope === 'all' ? 0 : accounts.findIndex((account) => account.tag === scope) + 1;
              const next = (page + direction + accounts.length + 1) % (accounts.length + 1);
              setScope(next === 0 ? 'all' : accounts[next - 1]!.tag);
              setSelectedDay(undefined);
            }
          : undefined
      }
      footer={
        accounts.length > 1 ? (
          <HomeAccountDots
            entries={[
              { tag: 'all', name: t('todoAllAccounts'), subtitle: '', imageUrl: '' },
              ...accounts,
            ]}
            selectedIndex={
              scope === 'all' ? 0 : accounts.findIndex((account) => account.tag === scope) + 1
            }
            onSelect={(index) => {
              setScope(index === 0 ? 'all' : accounts[index - 1]!.tag);
              setSelectedDay(undefined);
            }}
          />
        ) : null
      }
    >
      {/* Keep the heading and totals in one flow, without the frame's separate
          header gap or a nested farming surface competing with the card. */}
      <View style={styles.content}>
        <View style={styles.header}>
          <MobileWebImage imageUrl={ImageAssets.calendar} style={styles.headerImage} />
          <View style={styles.headerText}>
            <CKText role="titleSmall" style={styles.headerTitle}>
              {t('filtersLast30Days')}
            </CKText>
          </View>
          <View style={styles.accountIdentity}>
            {selectedAccount?.imageUrl ? (
              <MobileWebImage
                imageUrl={selectedAccount.imageUrl}
                style={{ width: 22, height: 22 }}
              />
            ) : null}
            <CKText muted role="labelMedium" numberOfLines={1} style={{ flexShrink: 1 }}>
              {scope === 'all' ? t('todoAllAccounts') : selectedAccount?.name}
            </CKText>
          </View>
        </View>
        {loading ? (
          <View style={styles.body} accessibilityLabel={t('generalLoading')}>
            <Skeleton height={22} width="45%" />
            <Skeleton height={44} />
            <Skeleton height={70} />
          </View>
        ) : unavailable ? (
          <View style={styles.body}>
            <CKText muted>{t('apiErrorServer')}</CKText>
            <Pressable
              accessibilityRole="button"
              onPress={() => setRetry((value) => value + 1)}
              style={[
                styles.retry,
                { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.45) },
              ]}
            >
              <CKText role="labelLarge">{t('generalRetry')}</CKText>
            </Pressable>
          </View>
        ) : (
          <View style={styles.body}>
            <View
              style={styles.chart}
              onLayout={(event) => setChartWidth(event.nativeEvent.layout.width)}
            >
              <View style={styles.chartLabels}>
                <CKText muted role="labelMedium">
                  {labels[selected]}
                  {dayLabel ? ` · ${dayLabel}` : ''}
                </CKText>
                {hasDaily ? (
                  <CKText muted role="labelMedium">
                    {selectedAmount ?? `${compact(minimum)}–${compact(maximum)}`}
                  </CKText>
                ) : null}
              </View>
              {hasDaily ? (
                <View style={styles.chartPlot}>
                  <Svg
                    width={chartWidth}
                    height={66}
                    pointerEvents="none"
                    accessible={Platform.OS === 'web' ? undefined : false}
                    aria-hidden
                  >
                    <Line
                      x1={0}
                      x2={chartWidth}
                      y1={y(0)}
                      y2={y(0)}
                      stroke={colorWithAlpha(theme.outlineVariant, 0.3)}
                      strokeWidth={1}
                    />
                    {selectedPoint ? (
                      <Rect
                        x={
                          (points.findIndex(([date]) => date === selectedDay) * chartWidth) /
                          points.length
                        }
                        y={0}
                        width={chartWidth / points.length}
                        height={66}
                        rx={3}
                        fill={accent}
                        opacity={0.14}
                      />
                    ) : null}
                    {points.map(([date, value], index) => {
                      const slot = chartWidth / points.length;
                      return (
                        <Rect
                          key={date}
                          x={index * slot + 1}
                          y={Math.min(y(value), y(0))}
                          width={Math.max(0, slot - 3)}
                          height={Math.abs(y(value) - y(0))}
                          rx={2}
                          fill={accent}
                          opacity={
                            date === selectedDay
                              ? 1
                              : selectedPoint
                                ? 0.4
                                : index === points.length - 1
                                  ? 1
                                  : 0.58 + (Math.abs(value) / range) * 0.35
                          }
                        />
                      );
                    })}
                  </Svg>
                  {/* One full-height touch surface lets users select tiny or zero
                    bars without competing with the Home screen's vertical scroll. */}
                  <Pressable
                    style={StyleSheet.absoluteFill}
                    accessibilityRole="adjustable"
                    accessibilityLabel={labels[selected]}
                    accessibilityValue={{
                      text: selectedPoint
                        ? `${dayLabel}: ${selectedAmount}`
                        : `${compact(minimum)}–${compact(maximum)}`,
                    }}
                    accessibilityActions={[{ name: 'increment' }, { name: 'decrement' }]}
                    onAccessibilityAction={(event) => {
                      const index = selectedPoint
                        ? points.findIndex(([date]) => date === selectedDay)
                        : -1;
                      const next =
                        event.nativeEvent.actionName === 'increment' ? index + 1 : index - 1;
                      const point = points[Math.max(0, Math.min(points.length - 1, next))];
                      if (point) setSelectedDay(point[0]);
                    }}
                    onPress={(event) => selectChartPosition(event.nativeEvent.locationX)}
                  />
                </View>
              ) : (
                <CKText muted role="bodySmall">
                  {t('homeWidgetsUnavailable')}
                </CKText>
              )}
              {points.length > 0 ? (
                <View style={styles.chartLabels}>
                  <CKText muted role="labelMedium">
                    {new Intl.DateTimeFormat(toIntlLocale(locale), {
                      month: 'short',
                      day: 'numeric',
                      timeZone: 'UTC',
                    }).format(new Date(points[0]![0] + 'T00:00:00Z'))}
                  </CKText>
                  <CKText muted role="labelMedium">
                    {new Intl.DateTimeFormat(toIntlLocale(locale), {
                      month: 'short',
                      day: 'numeric',
                      timeZone: 'UTC',
                    }).format(new Date(points[points.length - 1]![0] + 'T00:00:00Z'))}
                  </CKText>
                </View>
              ) : null}
            </View>
            <View style={styles.farming}>
              <CKText muted role="labelMedium">
                {t('playerBattlelogFarming')}
              </CKText>
              <View style={styles.resources}>
                {resources.map(([image, key]) => (
                  <Pressable
                    key={key}
                    accessibilityRole="button"
                    accessibilityLabel={labels[key]}
                    accessibilityState={{ selected: selected === key }}
                    onPress={() => selectMetric(key)}
                    style={[styles.resource, styles.selectable, selectedStyle(key)]}
                  >
                    <MobileWebImage imageUrl={image} style={styles.resourceImage} />
                    <CKText role="titleSmall" style={styles.resourceValue}>
                      {compact(sum(key))}
                    </CKText>
                  </Pressable>
                ))}
              </View>
            </View>
            <View style={styles.metrics}>
              {metric('donated', sum('donated'), ImageAssets.clanCastle)}
              {metric('received', sum('received'), ImageAssets.clanCastle)}
              {metric(
                'attacks',
                sum('farmingAttacks') + sum('rankedAttacks') + sum('legendAttacks'),
                ImageAssets.sword,
              )}
              {metric('upgradeLevels', sum('upgradeLevels'), ImageAssets.builderPotion)}
            </View>
          </View>
        )}
      </View>
    </HomeCardFrame>
  );
}
const styles = StyleSheet.create({
  content: { gap: ckSpacing.sm },
  header: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', gap: ckSpacing.sm },
  headerImage: { width: 32, height: 32 },
  headerText: { flexGrow: 1, flexShrink: 1 },
  headerTitle: { fontWeight: '700' },
  accountCount: { flexShrink: 0 },
  accountIdentity: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    maxWidth: '48%',
    flexShrink: 1,
  },
  body: { gap: ckSpacing.md },
  chart: { gap: 3 },
  chartPlot: { height: 66, position: 'relative' },
  chartLabels: { flexDirection: 'row', justifyContent: 'space-between', gap: 8 },
  selectable: { borderRadius: 8, padding: 4, borderBottomWidth: 2, minHeight: 44 },
  farming: {
    gap: ckSpacing.xs,
  },
  resources: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    columnGap: ckSpacing.sm,
    rowGap: ckSpacing.sm,
  },
  resource: { flexGrow: 1, flexDirection: 'row', alignItems: 'center', gap: ckSpacing.xs },
  resourceImage: { width: 22, height: 22 },
  resourceValue: { fontWeight: '700' },
  metrics: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    columnGap: ckSpacing.sm,
    rowGap: ckSpacing.sm,
  },
  metric: {
    flexGrow: 1,
    flexBasis: '46%',
    minWidth: 120,
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.sm,
  },
  metricImage: { width: 20, height: 20 },
  metricText: { flex: 1, gap: 2 },
  retry: {
    alignSelf: 'flex-start',
    paddingHorizontal: ckSpacing.lg,
    paddingVertical: ckSpacing.sm,
    borderRadius: ckRadius.control,
  },
});
