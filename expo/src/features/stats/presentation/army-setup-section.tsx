import { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, View } from 'react-native';
import { ChevronDown, ChevronRight } from 'lucide-react-native';
import { AnalyticsLineChart } from './analytics-chart';
import { LeagueStatsPicker } from './league-stats-picker';

import { useI18n } from '../../../i18n';
import { ImageAssets } from '../../../core/assets/image-assets';
import {
  CKText,
  MobileWebImage,
  SelectionPicker,
  ProfileTabs,
  Surface,
  ckColors,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import {
  LegendArmy,
  prefetchLegendArmyArtwork,
} from '../../legends/presentation/legend-army-presentation';
import { PlayerBattlelogArmyCatalog } from '../../player/models/player-battlelog';
import type { StatsProvider } from '../data';
import type {
  StatsArmySetupItem,
  StatsArmySetupResponse,
  StatsArmySetupTimelineResponse,
} from '../models';

export function ArmySetupSection({
  provider,
  data,
  listLoading = false,
}: {
  readonly provider: StatsProvider;
  readonly data?: StatsArmySetupResponse;
  readonly listLoading?: boolean;
}) {
  'use no memo';
  const { t } = useI18n();
  const theme = useCKTheme();
  const [groupKey, setGroupKey] = useState<string>();
  const [variantKey, setVariantKey] = useState<string>();
  const [variants, setVariants] = useState<StatsArmySetupResponse>();
  const [timeline, setTimeline] = useState<StatsArmySetupTimelineResponse>();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>();
  const [revision, setRevision] = useState(0);
  const variantCache = useRef(new Map<string, StatsArmySetupResponse>());
  const timelineCache = useRef(new Map<string, StatsArmySetupTimelineResponse>());
  const rangeKey = `${provider.dates.start.getTime()}:${provider.dates.end.getTime()}:${provider.armyRankLimit ?? 'all'}:${provider.armySetupSort}`;

  useEffect(() => {
    if (!groupKey) return;
    let active = true;
    const key = `${rangeKey}:${groupKey}`;
    const cached = variantCache.current.get(key);
    setVariants(cached);
    if (cached) return;
    const load = async () => {
      setError(undefined);
      try {
        const nextVariants = await provider.loadArmySetupVariants(groupKey);
        if (!active) return;
        variantCache.current.set(key, nextVariants);
        setVariants(nextVariants);
      } catch (caught) {
        if (active) setError(caught);
      }
    };
    void load();
    return () => {
      active = false;
    };
  }, [groupKey, rangeKey, provider, revision]);

  useEffect(() => {
    if (!groupKey) return;
    let active = true;
    const key = `${rangeKey}:${groupKey}:${variantKey ?? 'overview'}`;
    const cached = timelineCache.current.get(key);
    setTimeline(cached);
    if (cached) return;
    const load = async () => {
      setLoading(!cached);
      setError(undefined);
      try {
        const nextTimeline = await provider.loadArmySetupTimeline(groupKey, variantKey);
        if (!active) return;
        timelineCache.current.set(key, nextTimeline);
        setTimeline(nextTimeline);
      } catch (caught) {
        if (active) setError(caught);
      } finally {
        if (active) setLoading(false);
      }
    };
    void load();
    return () => {
      active = false;
    };
  }, [groupKey, variantKey, rangeKey, provider, revision]);

  useEffect(() => {
    // Warm the likely next disclosures while the list is being read. Keep this
    // bounded so a long list does not start hundreds of artwork downloads.
    void prefetchLegendArmyArtwork(data?.items.slice(0, 2).map((item) => item.shareCode) ?? []);
  }, [data]);

  const rankOptions = [
    { key: 'overall', label: t('generalAll') },
    { key: '1000', label: t('rankingsTopCount', { count: 1000 }) },
    { key: '200', label: t('rankingsTopCount', { count: 200 }) },
  ];
  return (
    <View style={styles.section}>
      <View style={styles.controls}>
        <View style={styles.leagueControl}>
          <LeagueStatsPicker />
        </View>
        <View style={styles.sortControl}>
          <SelectionPicker
            fillWidth
            title={t('statsSortBy')}
            options={[
              { key: 'usage', label: t('statsUsage') },
              { key: 'tripleRate', label: t('statsThreeStarRate') },
            ]}
            selectedKey={provider.armySetupSort}
            onSelect={(key) =>
              provider.updateArmySetupFilters({ sort: key as 'usage' | 'tripleRate' })
            }
          />
        </View>
      </View>
      <ProfileTabs
        tabs={rankOptions}
        variant="underline"
        selectedKey={provider.armyRankLimit?.toString() ?? 'overall'}
        onSelect={(key) => {
          provider.updateArmySetupFilters({
            rankLimit: key === 'overall' ? null : (Number(key) as 200 | 1000),
          });
          setGroupKey(undefined);
          setVariantKey(undefined);
        }}
      />
      {listLoading ? (
        <ActivityIndicator color={theme.primary} accessibilityLabel={t('generalLoading')} />
      ) : null}
      {data?.items.map((item, index) => (
        <Surface key={item.groupKey} radius={ckRadius.tile} style={styles.family}>
          <SetupRow
            item={item}
            position={index + 1}
            selected={groupKey === item.groupKey}
            onPress={() => {
              const nextGroup = groupKey === item.groupKey ? undefined : item.groupKey;
              setGroupKey(nextGroup);
              setVariantKey(undefined);
              setVariants(
                nextGroup ? variantCache.current.get(`${rangeKey}:${nextGroup}`) : undefined,
              );
              setTimeline(
                nextGroup
                  ? timelineCache.current.get(`${rangeKey}:${nextGroup}:overview`)
                  : undefined,
              );
            }}
          />
          {groupKey === item.groupKey ? (
            <View
              style={[
                styles.expanded,
                { borderTopColor: colorWithAlpha(theme.outlineVariant, 0.4) },
              ]}
            >
              {variants?.items.length ? (
                <SelectionPicker
                  fillWidth
                  title={t('upgradeTrackerPlanCategoryArmy')}
                  accessibilityLabel={t('upgradeTrackerPlanCategoryArmy')}
                  options={[
                    { key: 'overview', label: t('generalAll') },
                    ...variants.items.map((variant) => ({
                      key: variant.variantKey,
                      label: conditionLabel(variant.conditions),
                      icon: <SetupConditionIcons conditions={variant.conditions} />,
                    })),
                  ]}
                  selectedKey={variantKey ?? 'overview'}
                  onSelect={(key) => {
                    const nextVariant = key === 'overview' ? undefined : key;
                    setVariantKey(nextVariant);
                    setTimeline(
                      timelineCache.current.get(
                        `${rangeKey}:${groupKey}:${nextVariant ?? 'overview'}`,
                      ),
                    );
                  }}
                />
              ) : null}
              {variantKey && variants?.items.find((v) => v.variantKey === variantKey) ? (
                <SetupMetrics item={variants.items.find((v) => v.variantKey === variantKey)!} />
              ) : null}
              {item.comparisons?.length ? (
                <CohortUsageComparison
                  item={item}
                  selectedKey={provider.armyRankLimit?.toString() ?? 'overall'}
                />
              ) : null}
              <LegendArmy
                shareCode={
                  (variants?.items.find((v) => v.variantKey === variantKey) ?? item).shareCode
                }
                siegeContent={
                  visibleSieges(variants?.items.find((v) => v.variantKey === variantKey) ?? item)
                    .length ? (
                    <SiegeUsage
                      item={variants?.items.find((v) => v.variantKey === variantKey) ?? item}
                    />
                  ) : null
                }
              />
              {loading ? <ActivityIndicator color={theme.primary} /> : null}
              {timeline ? <SetupTimeline data={timeline} /> : null}
              {error ? (
                <Pressable
                  accessibilityRole="button"
                  onPress={() => {
                    variantCache.current.delete(`${rangeKey}:${groupKey}`);
                    timelineCache.current.delete(
                      `${rangeKey}:${groupKey}:${variantKey ?? 'overview'}`,
                    );
                    setRevision((value) => value + 1);
                  }}
                >
                  <CKText style={{ color: theme.error }}>{t('generalRetry')}</CKText>
                </Pressable>
              ) : null}
            </View>
          ) : null}
        </Surface>
      ))}
      {data && !data.items.length && !listLoading ? (
        <CKText role="bodyMedium" muted>
          {t('statsNoDataBody')}
        </CKText>
      ) : null}
    </View>
  );
}

function CohortUsageComparison({
  item,
  selectedKey,
}: {
  readonly item: StatsArmySetupItem;
  readonly selectedKey: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const cohorts = [
    { key: 'overall' as const, label: t('generalAll') },
    { key: '1000' as const, label: t('rankingsTopCount', { count: 1000 }) },
    { key: '200' as const, label: t('rankingsTopCount', { count: 200 }) },
  ];
  const rates = new Map(
    item.comparisons?.map((entry) => [entry.rankLimit?.toString() ?? 'overall', entry.usageRate]),
  );
  const maxRate = Math.max(0.001, ...cohorts.map(({ key }) => rates.get(key) ?? 0));
  return (
    <View style={styles.comparison}>
      <CKText role="bodyMedium">{t('statsAcrossCohorts')}</CKText>
      {cohorts.map(({ key, label }) => {
        const rate = rates.get(key);
        return (
          <View key={key} style={styles.comparisonRow}>
            <CKText role="bodySmall" muted={key !== selectedKey} style={styles.comparisonLabel}>
              {label}
            </CKText>
            <View
              style={[
                styles.comparisonTrack,
                { backgroundColor: colorWithAlpha(theme.outlineVariant, 0.55) },
              ]}
            >
              {rate != null ? (
                <View
                  style={[
                    styles.comparisonFill,
                    {
                      width: `${Math.max(1, (rate / maxRate) * 100)}%`,
                      backgroundColor: key === selectedKey ? theme.primary : theme.secondary,
                    },
                  ]}
                />
              ) : null}
            </View>
            <CKText role="bodySmall" style={styles.comparisonRate}>
              {formatRate(rate ?? null)}
            </CKText>
          </View>
        );
      })}
    </View>
  );
}

function SetupRow({
  item,
  position,
  selected = false,
  onPress,
}: {
  readonly item: StatsArmySetupItem;
  readonly position: number;
  readonly selected?: boolean;
  readonly onPress: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const name = item.conditions.length
    ? conditionLabel(item.conditions)
    : item.coreTroops
        .filter((id) => id !== 4000007)
        .map((id) => PlayerBattlelogArmyCatalog.resolve(`u_${id}`).name)
        .join(' + ');
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ expanded: selected }}
      onPress={onPress}
    >
      <View style={styles.row}>
        <View style={styles.rowHeader} testID="army-setup-card-row">
          <View style={styles.rankBlock} testID="army-setup-rank">
            <CKText role="rowTitle">#{position}</CKText>
            {item.rankChange != null && item.rankChange !== 0 ? (
              <CKText
                role="bodySmall"
                style={{ color: item.rankChange > 0 ? ckColors.donationGreen : theme.error }}
              >
                {item.rankChange > 0 ? '↑' : '↓'}
                {Math.abs(item.rankChange)}
              </CKText>
            ) : null}
          </View>
          {item.conditions.length ? (
            <SetupConditionIcons conditions={item.conditions} featured />
          ) : (
            <CoreTroopArtwork ids={item.coreTroops} />
          )}
          <View style={styles.usageMetric} testID="army-setup-usage">
            <CKText role="bodySmall" muted numberOfLines={1}>
              {t('statsUsage')}
            </CKText>
            <CKText role="bodyMedium">{formatRate(item.usageRate)}</CKText>
          </View>
          {selected ? (
            <ChevronDown size={18} color={theme.onSurfaceVariant} />
          ) : (
            <ChevronRight size={18} color={theme.onSurfaceVariant} />
          )}
        </View>
        <View style={styles.secondaryRow}>
          <CKText role="rowTitle" style={styles.armyName}>
            {name}
          </CKText>
          <TripleRate value={item.threeStarRate} />
        </View>
      </View>
    </Pressable>
  );
}

function CoreTroopArtwork({ ids }: { readonly ids: readonly number[] }) {
  const items = ids.map((id) => PlayerBattlelogArmyCatalog.resolve(`u_${id}`));
  return (
    <View style={styles.featuredArtwork} testID="army-setup-artwork">
      {items.slice(0, 3).map((item, index) => (
        <MobileWebImage
          key={ids[index]}
          imageUrl={item.imageUrl}
          style={styles.featuredIcon}
          testID="army-setup-troop-icon"
        />
      ))}
    </View>
  );
}

function TripleRate({ value }: { readonly value: number | null }) {
  const { t } = useI18n();
  return (
    <View
      accessible
      accessibilityRole="text"
      accessibilityLabel={`${t('statsThreeStarRate')}: ${formatRate(value)}`}
      style={styles.tripleRate}
      testID="army-setup-triple-rate"
    >
      <View
        accessibilityElementsHidden
        importantForAccessibility="no-hide-descendants"
        style={styles.starArtwork}
      >
        {[0, 1, 2].map((index) => (
          <MobileWebImage
            key={index}
            imageUrl={ImageAssets.attackStar}
            style={styles.starIcon}
            testID="army-setup-star"
          />
        ))}
      </View>
      <CKText role="bodyMedium">{formatRate(value)}</CKText>
    </View>
  );
}

function SetupMetrics({ item }: { readonly item: StatsArmySetupItem }) {
  const { t } = useI18n();
  return (
    <View style={styles.metrics}>
      <View style={styles.grow}>
        <CKText role="bodySmall" muted>
          {t('statsUsage')}
        </CKText>
        <CKText role="titleSmall">{formatRate(item.usageRate)}</CKText>
      </View>
      <View style={styles.grow}>
        <CKText role="bodySmall" muted>
          {t('statsThreeStarRate')}
        </CKText>
        <CKText role="titleSmall">{formatRate(item.threeStarRate)}</CKText>
      </View>
    </View>
  );
}

function conditionLabel(conditions: StatsArmySetupItem['conditions']): string {
  return conditions
    .map(
      (condition) =>
        `${PlayerBattlelogArmyCatalog.resolve(`${condition.kind === 'spell' ? 's' : 'e'}_${condition.id}`).name}${condition.minimum && condition.minimum > 1 ? ` ×${condition.minimum}` : ''}`,
    )
    .join(' + ');
}

function SetupConditionIcons({
  conditions,
  featured = false,
}: {
  readonly conditions: StatsArmySetupItem['conditions'];
  readonly featured?: boolean;
}) {
  return (
    <View
      style={featured ? styles.featuredArtwork : styles.item}
      testID={featured ? 'army-setup-artwork' : undefined}
    >
      {conditions.map((condition, index) => (
        <MobileWebImage
          key={index}
          imageUrl={
            PlayerBattlelogArmyCatalog.resolve(
              `${condition.kind === 'spell' ? 's' : 'e'}_${condition.id}`,
            ).imageUrl
          }
          style={featured ? styles.conditionIcon : styles.icon}
          contentFit="contain"
        />
      ))}
    </View>
  );
}

function visibleSieges(item: StatsArmySetupItem) {
  return item.sieges.filter((siege) => siege.attacks > 0 && Math.round(siege.usageRate * 1000) > 0);
}

function SiegeUsage({ item }: { readonly item: StatsArmySetupItem }) {
  const { t } = useI18n();
  const sieges = visibleSieges(item);
  if (!sieges.length) return null;
  return (
    <View style={styles.list}>
      <CKText role="bodySmall" muted>
        {t('gameSiegeMachines')}
      </CKText>
      <View style={styles.metrics}>
        {sieges.map((siege) => {
          const unit = PlayerBattlelogArmyCatalog.resolve(`u_${siege.id}`);
          return (
            <View
              key={siege.id}
              style={styles.grow}
              accessibilityLabel={`${unit.name}: ${formatRate(siege.usageRate)}`}
            >
              <MobileWebImage
                imageUrl={unit.imageUrl}
                style={styles.siegeIcon}
                contentFit="contain"
              />
              <CKText role="bodySmall">{formatRate(siege.usageRate)}</CKText>
            </View>
          );
        })}
      </View>
    </View>
  );
}

export function SetupTimeline({ data }: { readonly data: StatsArmySetupTimelineResponse }) {
  const { t } = useI18n();
  return (
    <View style={styles.timeline}>
      <AnalyticsLineChart
        title={t('statsThreeStarRate')}
        percent
        series={[
          {
            key: 'army',
            label: t('statsArmies'),
            points: data.items.map((entry) => ({
              day: entry.day,
              weight: entry.observation?.attacks ?? 0,
              value:
                entry.observation?.threeStarRate == null
                  ? null
                  : entry.observation.threeStarRate * 100,
            })),
          },
          ...(data.benchmarks ?? []).map((benchmark) => ({
            key: `league-${benchmark.rankLimit}`,
            label: benchmark.rankLimit
              ? t('rankingsTopCount', { count: benchmark.rankLimit })
              : t('statsLegendLeagueOne'),
            points: benchmark.points.map((point) => ({
              day: point.day,
              weight: point.attacks,
              value: point.threeStarRate == null ? null : point.threeStarRate * 100,
            })),
          })),
        ]}
      />
      <AnalyticsLineChart
        title={t('statsUsage')}
        percent
        includeZero
        series={[
          {
            key: 'usage',
            label: t('statsUsage'),
            points: data.items.map((entry) => ({
              day: entry.day,
              weight: entry.totalAttacks,
              value:
                entry.observation?.usageRate == null ? null : entry.observation.usageRate * 100,
            })),
          },
        ]}
      />
    </View>
  );
}

function formatRate(value: number | null): string {
  return value == null ? '—' : `${(value * 100).toFixed(1)}%`;
}

const styles = StyleSheet.create({
  section: { gap: 16, paddingBottom: 24 },
  controls: { flexDirection: 'row', alignItems: 'stretch', gap: 8 },
  leagueControl: { flex: 2, minWidth: 0 },
  sortControl: { flex: 1, minWidth: 0 },
  list: { gap: 10 },
  family: { overflow: 'hidden' },
  expanded: { padding: 12, gap: 16, borderTopWidth: StyleSheet.hairlineWidth },
  metricLabels: { flexShrink: 1, maxWidth: '34%' },
  siegeIcon: { width: 36, height: 36 },
  row: { paddingHorizontal: 14, paddingVertical: 11, gap: 4 },
  rowHeader: { flexDirection: 'row', alignItems: 'center', gap: 8, minHeight: 42 },
  rankBlock: { width: 32, alignItems: 'center', justifyContent: 'center' },
  grow: { flex: 1 },
  featuredArtwork: { flexDirection: 'row', alignItems: 'center', gap: 4, minHeight: 42 },
  featuredIcon: { width: 42, height: 42 },
  usageMetric: { flex: 1, minWidth: 0, alignItems: 'flex-end' },
  secondaryRow: {
    paddingLeft: 40,
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 6,
  },
  armyName: { flexGrow: 1, flexShrink: 1, minWidth: 110 },
  tripleRate: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  starArtwork: { flexDirection: 'row', alignItems: 'center', gap: 1 },
  starIcon: { width: 14, height: 14 },
  item: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  conditionIcon: { width: 32, height: 32 },
  icon: { width: 24, height: 24 },
  metrics: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  comparison: { gap: 9, paddingVertical: 6 },
  comparisonRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  comparisonLabel: { width: 76 },
  comparisonTrack: { flex: 1, height: 8, borderRadius: 4, overflow: 'hidden' },
  comparisonFill: { height: '100%', borderRadius: 4 },
  comparisonRate: { width: 48, textAlign: 'right' },
  back: { flexDirection: 'row', alignItems: 'center', gap: 8, minHeight: 44 },
  representative: { padding: 16, gap: 8 },
  timeline: { gap: 10 },
  day: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 12,
    minHeight: 32,
  },
});
