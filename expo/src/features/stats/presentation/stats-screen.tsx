import { useState, useSyncExternalStore, type ReactNode } from 'react';
import {
  ActivityIndicator,
  Modal,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Switch,
  TextInput,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  ArrowLeft,
  BarChart3,
  CalendarDays,
  Check,
  ChevronDown,
  Filter,
  Network,
  RefreshCw,
  Search,
  TriangleAlert,
  X,
} from 'lucide-react-native';
import Svg, { Line, Polyline, Rect } from 'react-native-svg';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { localizedNameForItemOrFallback } from '../../../core/game-data/game-data-localization';
import { warLeaguesByApiId } from '../../../core/game-data/game-data-normalization';
import {
  gameDataState,
  subscribeToGameDataRevision,
} from '../../../core/game-data/game-data-state';
import { formatCompactNumber, materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  CalendarPicker,
  EmptyState,
  ErrorState,
  GlassSurface,
  MobileWebImage,
  ResponsiveGrid,
  Skeleton,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { StatsLoadStatus, type StatsProvider } from '../data';
import {
  StatsArmiesResponse,
  StatsAudience,
  StatsClanCountsResponse,
  StatsDateFilter,
  StatsItemSelector,
  StatsItemQuantityFilter,
  StatsItemType,
  StatsItemsResponse,
  StatsOverviewResponse,
  StatsPerformanceResponse,
  StatsPlayerCountsResponse,
  StatsSection,
  type StatsAudienceValue,
  type StatsGroupedCount,
  type StatsItemTypeValue,
  type StatsMetrics,
  type StatsSectionValue,
} from '../models';

const battleSections = [
  StatsSection.ranked,
  StatsSection.armies,
  StatsSection.items,
  StatsSection.war,
  StatsSection.cwl,
] as const;
const worldSections = [StatsSection.overview, StatsSection.players, StatsSection.clans] as const;

export function StatsScreen({ provider, onBack }: { provider: StatsProvider; onBack: () => void }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const desktop = Platform.OS === 'web' && width >= 900;
  const horizontal = Math.max(16, (width - 1120) / 2);
  const sections: readonly StatsSectionValue[] =
    provider.audience === StatsAudience.battle ? battleSections : worldSections;
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.fill, { backgroundColor: theme.background }]}
    >
      <ScrollView
        refreshControl={
          <RefreshControl
            refreshing={provider.currentState.isRefreshing}
            onRefresh={() => void provider.refresh()}
            tintColor={theme.primary}
          />
        }
        contentContainerStyle={{ paddingBottom: insets.bottom + 24 }}
      >
        <View style={{ height: insets.top + (desktop ? 210 : 246) }}>
          <MobileWebImage
            imageUrl={sectionBackground(provider.section)}
            contentFit="cover"
            style={StyleSheet.absoluteFill}
          />
          <View style={styles.heroScrim} />
          <View style={[styles.hero, { paddingTop: insets.top }]}>
            <View style={styles.topRow}>
              <IconButton label={materialBackLabel(locale)} onPress={onBack}>
                <ArrowLeft color="#FFF" />
              </IconButton>
              <IconButton label={t('sideRefresh')} onPress={() => void provider.refresh()}>
                <RefreshCw color="#FFF" />
              </IconButton>
            </View>
            <View style={styles.identity}>
              <MobileWebImage
                imageUrl={sectionImage(provider.section)}
                style={styles.heroImage}
                contentFit="contain"
              />
              <CKText role="screenTitle" style={styles.white}>
                {t('sideStatsTitle')}
              </CKText>
              <CKText role="bodyMedium" style={styles.white}>
                {sectionLabel(provider.section, t)}
              </CKText>
            </View>
            <Segmented
              selected={provider.audience}
              onSelect={(value) => provider.selectAudience(value)}
            />
          </View>
        </View>
        <View style={{ paddingHorizontal: horizontal }}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.tabs}
          >
            {sections.map((section) => (
              <Pressable
                key={section}
                accessibilityRole="tab"
                accessibilityState={{ selected: provider.section === section }}
                onPress={() => provider.selectSection(section)}
              >
                <GlassSurface
                  cornerRadius={ckRadius.control}
                  style={[
                    styles.tab,
                    provider.section === section && { borderColor: theme.primary },
                  ]}
                >
                  <MobileWebImage
                    imageUrl={sectionImage(section)}
                    style={styles.tabImage}
                    contentFit="contain"
                  />
                  <CKText role="labelLarge">{sectionLabel(section, t)}</CKText>
                </GlassSurface>
              </Pressable>
            ))}
          </ScrollView>
          <StatsSectionContent provider={provider} />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function StatsSectionContent({ provider }: { provider: StatsProvider }) {
  const state = provider.currentState;
  const { t } = useI18n();
  const theme = useCKTheme();
  if (state.status === StatsLoadStatus.loading) return <StatsSkeleton section={provider.section} />;
  if (state.status === StatsLoadStatus.error)
    return (
      <ErrorState
        title={t('sideStatsLoadError')}
        body={String(state.error)}
        actionLabel={t('generalRetry')}
        onAction={() => void provider.load(provider.section, true)}
        style={styles.state}
      />
    );
  if (state.status === StatsLoadStatus.empty) {
    if (provider.section === StatsSection.items && provider.itemSelectors.length === 0)
      return <ItemsSection provider={provider} data={undefined} />;
    return (
      <EmptyState
        title={t('statsNoDataTitle')}
        body={t('statsNoDataBody')}
        actionLabel={t('generalRetry')}
        onAction={() => void provider.load(provider.section, true)}
        style={styles.state}
      />
    );
  }
  if (!state.data) return <StatsSkeleton section={provider.section} />;
  let content: ReactNode;
  switch (provider.section) {
    case StatsSection.overview:
      content = <OverviewSection data={state.data as StatsOverviewResponse} />;
      break;
    case StatsSection.players:
      content = <PlayersSection data={state.data as StatsPlayerCountsResponse} />;
      break;
    case StatsSection.clans:
      content = <ClansSection data={state.data as StatsClanCountsResponse} />;
      break;
    case StatsSection.armies:
      content = <ArmiesSection provider={provider} data={state.data as StatsArmiesResponse} />;
      break;
    case StatsSection.items:
      content = <ItemsSection provider={provider} data={state.data as StatsItemsResponse} />;
      break;
    case StatsSection.ranked:
    case StatsSection.war:
    case StatsSection.cwl:
      content = (
        <PerformanceSection provider={provider} data={state.data as StatsPerformanceResponse} />
      );
      break;
  }
  return (
    <View style={styles.sectionFrame}>
      {state.isRefreshing ? <ActivityIndicator color={theme.primary} /> : null}
      {state.error ? (
        <InlineNotice
          icon={<TriangleAlert size={20} color={theme.error} />}
          text={String(state.error)}
        />
      ) : null}
      {content}
      {state.updatedAt ? <Badge>{t('statsUpdated')}</Badge> : null}
    </View>
  );
}

function OverviewSection({ data }: { data: StatsOverviewResponse }) {
  const { t, locale } = useI18n();
  const metrics = [
    [t('statsPlayers'), data.counts.playerCount],
    [t('statsClans'), data.counts.clanCount],
    [t('statsPlayersInWar'), data.counts.playersInWar],
    [t('statsClansInWar'), data.counts.clansInWar],
    [t('statsPlayersInLegends'), data.counts.playersInLegends],
    [t('statsWarsStored'), data.counts.warsStored],
    [t('statsJoinLeaves'), data.counts.totalJoinLeaves],
  ] as const;
  return (
    <Section>
      <SectionTitle>{t('statsGlobalCounts')}</SectionTitle>
      <ResponsiveGrid minItemWidth={145} maxColumns={4} gap={10}>
        {metrics.map(([label, value]) => (
          <MetricPanel key={label} label={label} value={compact(value, locale)} />
        ))}
      </ResponsiveGrid>
      <ComingSoon title={t('statsWarsOverTime')} />
    </Section>
  );
}
function PlayersSection({ data }: { data: StatsPlayerCountsResponse }) {
  const { t } = useI18n();
  return (
    <Section>
      <DistributionCard
        title={t('statsTownHallDistribution')}
        subtitle={t('statsTrackedPlayers')}
        values={data.townHalls}
        label={(id) => `TH${id ?? '?'}`}
        color="#2F8CFF"
      />
      <DistributionCard
        title={t('statsLeagueDistribution')}
        subtitle={t('statsTrackedPlayers')}
        values={data.leagueTiers}
        label={distributionLeagueLabel}
        color="#E7B946"
      />
      <DistributionCard
        title={t('statsBuilderHallDistribution')}
        subtitle={t('statsTrackedPlayers')}
        values={data.builderHalls}
        label={(id) => `BH${id ?? '?'}`}
        color="#7A5AF8"
      />
      <ComingSoon title={t('statsEquipmentAdoption')} />
      <ComingSoon title={t('statsExperienceDistribution')} />
    </Section>
  );
}
function ClansSection({ data }: { data: StatsClanCountsResponse }) {
  const { t, locale } = useI18n();
  const cwlLeagues = useLocalizedCwlLeagues(t, locale);
  return (
    <Section>
      <DistributionCard
        title={t('statsCwlLeagueDistribution')}
        subtitle={t('statsTrackedClans')}
        values={data.cwlLeagues}
        label={(id) => cwlLeagues.get(id ?? -1) ?? `${id ?? '?'}`}
        color="#BA1A1A"
      />
      <DistributionCard
        title={t('statsCapitalLeagueDistribution')}
        subtitle={t('statsTrackedClans')}
        values={data.capitalLeagues}
        label={(id) => t('statsLeagueId', { id: id ?? 0 })}
        color="#05A8AA"
      />
      <Surface style={styles.summary}>
        <View style={styles.grow}>
          <CKText role="labelLarge">{t('statsTrackedLocations')}</CKText>
          <CKText role="bodySmall" muted>
            {t('statsLocationCountHelp')}
          </CKText>
        </View>
        <CKText role="titleLarge">
          {data.locations
            .filter((item) => item.id != null)
            .length.toLocaleString(toIntlLocale(locale))}
        </CKText>
      </Surface>
      <ComingSoon title={t('statsCwlRosterSizes')} />
    </Section>
  );
}

function ArmiesSection({ provider, data }: { provider: StatsProvider; data: StatsArmiesResponse }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [query, setQuery] = useState('');
  const [filters, setFilters] = useState(false);
  const needle = query.trim().toLowerCase();
  const items = data.items.filter(
    (army) =>
      !needle ||
      army.armyShareCode.toLowerCase().includes(needle) ||
      Object.keys(army.armyCounts).some((item) => item.toLowerCase().includes(needle)),
  );
  return (
    <Section>
      <BattleContext
        provider={provider}
        summary={`${townHallSummary(provider.armiesTownHall, t)} · ${t('statsMinimumSample')} ${provider.armiesMinimumSample}`}
        onFilters={() => setFilters(true)}
      />
      <SearchField value={query} onChange={setQuery} placeholder={t('statsSearchArmies')} />
      <Surface style={styles.card}>
        <View style={styles.titleRow}>
          <SectionTitle>{t('statsStrategyLenses')}</SectionTitle>
          <Badge>{t('statsPreview')}</Badge>
        </View>
        <CKText role="bodySmall" muted>
          {t('statsStrategyLensesBody')}
        </CKText>
        {(
          [
            [
              t('statsQueenCharge'),
              t('statsQueenChargeRule'),
              ImageAssets.getHeroImage('Archer Queen'),
            ],
            [
              t('statsSuperBowlerCore'),
              t('statsSuperBowlerRule'),
              ImageAssets.getTroopImage('Super Bowler'),
            ],
            [
              t('statsRootRiderCore'),
              t('statsRootRiderRule'),
              ImageAssets.getTroopImage('Root Rider'),
            ],
          ] satisfies readonly (readonly [string, string, string])[]
        ).map(([title, body, image]) => (
          <View key={title} style={styles.strategy}>
            <MobileWebImage imageUrl={image} style={styles.strategyImage} />
            <View style={styles.grow}>
              <CKText role="rowTitle">{title}</CKText>
              <CKText role="bodySmall">{body}</CKText>
            </View>
          </View>
        ))}
        <InlineNotice
          icon={<Network size={20} color={theme.onSurfaceVariant} />}
          text={t('statsPatternDiscoveryBody')}
        />
      </Surface>
      {items.length ? (
        <>
          <ArmyScatter items={items.slice(0, 30)} />
          <SectionTitle>{t('statsExactLoadouts')}</SectionTitle>
          {items.map((army, index) => (
            <MetricsCard
              key={`${army.armyShareCode}-${index}`}
              title={t('statsExactComposition')}
              metrics={army.metrics}
              extra={
                <View style={styles.cardExtra}>
                  <ArmyComposition counts={army.armyCounts} />
                  <CKText>
                    {Object.entries(army.armyCounts).length
                      ? Object.entries(army.armyCounts)
                          .map(([name, count]) => `${count}× ${name}`)
                          .join(' · ')
                      : army.armyItems.join(' · ')}
                  </CKText>
                  {army.armyShareCode ? (
                    <CKText selectable role="labelSmall" muted>
                      {`${t('statsArmyShareCode')}: ${army.armyShareCode}`}
                    </CKText>
                  ) : null}
                </View>
              }
            />
          ))}
        </>
      ) : (
        <EmptyState title={t('statsNoDataTitle')} body={t('generalNoFilteredResults')} />
      )}
      {filters ? (
        <BattleFilters
          section={StatsSection.armies}
          provider={provider}
          onClose={() => setFilters(false)}
        />
      ) : null}
    </Section>
  );
}

function ItemsSection({ provider, data }: { provider: StatsProvider; data?: StatsItemsResponse }) {
  const { t } = useI18n();
  const [filters, setFilters] = useState(false);
  const [adding, setAdding] = useState(false);
  return (
    <Section>
      <BattleContext
        provider={provider}
        summary={`${townHallSummary(provider.itemsTownHall, t)} · ${t('statsLeagueTier')}: ${provider.itemsLeagueTier == null ? t('generalAll') : leagueTierSummary(provider.itemsLeagueTier, t)} · ${t('statsItems')}: ${provider.itemSelectors.length}`}
        onFilters={() => setFilters(true)}
      />
      <Pressable
        accessibilityRole="button"
        onPress={() => setAdding(true)}
        style={styles.primaryButton}
      >
        <CKText role="rowTitle" style={styles.primaryText}>
          {t('statsAddItem')}
        </CKText>
      </Pressable>
      {provider.itemSelectors.length ? (
        <View style={styles.armyItems}>
          {provider.itemSelectors.map((selector, index) => (
            <Pressable
              key={`${selector.type}:${selector.item}:${selector.hero ?? ''}:${index}`}
              accessibilityRole="button"
              accessibilityLabel={t('presetsDelete')}
              onPress={() => {
                provider.setItemSelectors(
                  provider.itemSelectors.filter((_, itemIndex) => itemIndex !== index),
                );
                void provider.load(StatsSection.items);
              }}
            >
              <Badge>{`${selector.item} ×`}</Badge>
            </Pressable>
          ))}
        </View>
      ) : null}
      {provider.itemSelectors.length === 0 ? (
        <EmptyState title={t('statsAddItemsTitle')} body={t('statsAddItemsBody')} />
      ) : (
        data?.items.map((item) => (
          <MetricsCard
            key={`${item.type}:${item.item}:${item.hero ?? ''}`}
            title={item.item}
            metrics={item.metrics}
            extra={
              <View style={styles.titleRow}>
                <Badge>{item.type}</Badge>
                {item.hero ? <Badge>{item.hero}</Badge> : null}
                {item.compositionShare != null ? (
                  <Badge>{`${t('statsCompositionShare')}: ${percent(item.compositionShare)}`}</Badge>
                ) : null}
              </View>
            }
          />
        ))
      )}
      {filters ? (
        <BattleFilters
          section={StatsSection.items}
          provider={provider}
          onClose={() => setFilters(false)}
        />
      ) : null}
      <AddItemDialog
        visible={adding}
        onClose={() => setAdding(false)}
        onAdd={(selector) => {
          provider.setItemSelectors([...provider.itemSelectors, selector]);
          setAdding(false);
          void provider.load(StatsSection.items);
        }}
      />
    </Section>
  );
}

function PerformanceSection({
  provider,
  data,
}: {
  provider: StatsProvider;
  data: StatsPerformanceResponse;
}) {
  const { t, locale } = useI18n();
  const cwlLeagues = useLocalizedCwlLeagues(t, locale);
  const [filters, setFilters] = useState(false);
  const summary =
    provider.section === StatsSection.ranked
      ? `${townHallSummary(provider.rankedTownHall, t)} · ${leagueTierSummary(provider.rankedLeagueTier, t)}`
      : provider.section === StatsSection.war
        ? `${townHallSummary(provider.warTownHall, t)} · ${provider.warEqualTownHalls ? t('statsEqualTownHalls') : t('statsOpponentTownHall')}`
        : `${townHallSummary(provider.cwlTownHall, t)} · ${provider.cwlLeagueId == null ? t('statsAllCwlLeagues') : (cwlLeagues.get(provider.cwlLeagueId) ?? `${provider.cwlLeagueId}`)}`;
  return (
    <Section>
      <BattleContext provider={provider} summary={summary} onFilters={() => setFilters(true)} />
      <MetricsCard title={t('statsPerformance')} metrics={data.metrics} />
      {data.breakdowns.length ? (
        <>
          <SectionTitle>{t('statsSeasonBreakdown')}</SectionTitle>
          {data.breakdowns.map((entry) => (
            <MetricsCard key={entry.key} title={entry.key} metrics={entry.metrics} />
          ))}
        </>
      ) : null}
      {filters ? (
        <BattleFilters
          section={provider.section}
          provider={provider}
          onClose={() => setFilters(false)}
        />
      ) : null}
    </Section>
  );
}

function MetricsCard({
  title,
  metrics,
  extra,
}: {
  title: string;
  metrics: StatsMetrics;
  extra?: ReactNode;
}) {
  const { t, locale } = useI18n();
  return (
    <Surface style={styles.card}>
      <SectionTitle>{title}</SectionTitle>
      {extra}
      <View style={styles.pills}>
        <MetricPill label={t('statsSamples')} value={compact(metrics.sampleSize, locale)} />
        {metrics.usageRate != null ? (
          <MetricPill label={t('statsUsage')} value={percent(metrics.usageRate)} />
        ) : null}
        <MetricPill label={t('statsAverageStars')} value={metrics.averageStars.toFixed(2)} />
        <MetricPill
          label={t('statsAverageDestruction')}
          value={percent(metrics.averageDestruction)}
        />
      </View>
      <CKText role="labelLarge">{t('statsStarRates')}</CKText>
      {[metrics.zeroStarRate, metrics.oneStarRate, metrics.twoStarRate, metrics.threeStarRate].map(
        (rate, index) => (
          <Progress key={index} label={`${index}★`} value={rate} />
        ),
      )}
      {metrics.daily.length ? (
        <>
          <CKText role="labelLarge">{t('statsDailyTrend')}</CKText>
          <Trend metrics={metrics} />
        </>
      ) : null}
    </Surface>
  );
}

function DistributionCard({
  title,
  subtitle,
  values,
  label,
  color,
}: {
  title: string;
  subtitle: string;
  values: readonly StatsGroupedCount[];
  label: (id: number | null) => string;
  color: string;
}) {
  const { locale } = useI18n();
  const [selected, setSelected] = useState<number>();
  const visible = [...values].sort((a, b) => (a.id ?? -1) - (b.id ?? -1)).slice(-18);
  const max = Math.max(1, ...visible.map((item) => item.count));
  const selectedItem = selected === undefined ? undefined : visible[selected];
  return (
    <Surface style={styles.card}>
      <SectionTitle>{title}</SectionTitle>
      <CKText role="bodySmall" muted>
        {subtitle}
      </CKText>
      {selectedItem ? (
        <Badge>{`${label(selectedItem.id)} · ${compact(selectedItem.count, locale)}`}</Badge>
      ) : null}
      <View
        accessibilityLabel={visible.map((item) => `${label(item.id)}: ${item.count}`).join(', ')}
        style={styles.bars}
      >
        {visible.map((item, index) => (
          <Pressable
            key={`${item.id}`}
            accessibilityRole="button"
            accessibilityLabel={`${label(item.id)}: ${item.count}`}
            onPress={() => setSelected(index)}
            style={styles.barColumn}
          >
            <View
              style={[
                styles.bar,
                { height: Math.max(3, (130 * item.count) / max), backgroundColor: color },
              ]}
            />
            <CKText role="bodySmall" numberOfLines={1}>
              {label(item.id)}
            </CKText>
          </Pressable>
        ))}
      </View>
    </Surface>
  );
}
function ArmyComposition({ counts }: { counts: Readonly<Record<string, number>> }) {
  return (
    <View style={styles.armyItems}>
      {Object.entries(counts)
        .slice(0, 8)
        .map(([name, count]) => (
          <View key={name} style={styles.armyIconWrap}>
            <MobileWebImage
              imageUrl={ImageAssets.getTroopImage(name)}
              style={styles.armyIcon}
              contentFit="contain"
            />
            <View style={styles.armyCount}>
              <CKText role="bodySmall" style={styles.white}>
                {count}
              </CKText>
            </View>
          </View>
        ))}
    </View>
  );
}
function ArmyScatter({ items }: { items: StatsArmiesResponse['items'] }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [selected, setSelected] = useState<number>();
  const selectedArmy = selected === undefined ? undefined : items[selected];
  return (
    <Surface style={styles.card}>
      <SectionTitle>{t('statsUsageVsThreeStar')}</SectionTitle>
      <CKText role="bodySmall" muted>
        {t('statsTapPointForLoadout')}
      </CKText>
      {selectedArmy ? (
        <Badge>
          {`${Object.entries(selectedArmy.armyCounts)
            .slice(0, 2)
            .map(([name, count]) => `${count}× ${name}`)
            .join(
              ' · ',
            )} · ${percent(selectedArmy.metrics.usageRate ?? 0)} ${t('statsUsage')} · ${percent(selectedArmy.metrics.threeStarRate)} ${t('statsThreeStarRate')}`}
        </Badge>
      ) : null}
      <View style={styles.scatterChart}>
        <Svg width="100%" height="100%" viewBox="0 0 320 200">
          {[0, 1, 2, 3, 4].map((n) => (
            <Line
              key={n}
              x1="0"
              x2="320"
              y1={n * 50}
              y2={n * 50}
              stroke={colorWithAlpha(theme.outlineVariant, 0.28)}
            />
          ))}
          {items.map((army, index) => {
            const x = Math.min(310, normalizePercent(army.metrics.usageRate ?? 0) * 3.1);
            const y = 190 - Math.min(190, normalizePercent(army.metrics.threeStarRate) * 1.9);
            return (
              <Rect
                key={index}
                x={x - (selected === index ? 6 : 4)}
                y={y - (selected === index ? 6 : 4)}
                width={selected === index ? 12 : 8}
                height={selected === index ? 12 : 8}
                rx="6"
                fill={theme.primary}
              />
            );
          })}
        </Svg>
        {items.map((army, index) => {
          const x = Math.min(310, normalizePercent(army.metrics.usageRate ?? 0) * 3.1);
          const y = 190 - Math.min(190, normalizePercent(army.metrics.threeStarRate) * 1.9);
          return (
            <Pressable
              key={index}
              accessibilityRole="button"
              accessibilityLabel={`${percent(army.metrics.usageRate ?? 0)} ${t('statsUsage')}, ${percent(army.metrics.threeStarRate)} ${t('statsThreeStarRate')}`}
              onPress={() => setSelected(index)}
              style={[
                styles.chartHitTarget,
                { left: `${(x / 320) * 100}%`, top: `${(y / 200) * 100}%` },
              ]}
            />
          );
        })}
      </View>
    </Surface>
  );
}
function Trend({ metrics }: { metrics: StatsMetrics }) {
  const theme = useCKTheme();
  const [selected, setSelected] = useState<number>();
  const points = metrics.daily
    .map(
      (point, index) =>
        `${metrics.daily.length === 1 ? 0 : (index * 320) / (metrics.daily.length - 1)},${100 - Math.min(100, normalizePercent(point.threeStarRate))}`,
    )
    .join(' ');
  const selectedPoint = selected === undefined ? undefined : metrics.daily[selected];
  return (
    <View>
      {selectedPoint ? (
        <Badge>{`${selectedPoint.date} · ${percent(selectedPoint.threeStarRate)}`}</Badge>
      ) : null}
      <View style={styles.trendChart}>
        <Svg
          accessibilityLabel={metrics.daily
            .map((point) => `${point.date}: ${percent(point.threeStarRate)}`)
            .join(', ')}
          width="100%"
          height="100%"
          viewBox="0 0 320 100"
        >
          {[0, 25, 50, 75, 100].map((y) => (
            <Line
              key={y}
              x1="0"
              x2="320"
              y1={y}
              y2={y}
              stroke={colorWithAlpha(theme.outlineVariant, 0.28)}
            />
          ))}
          <Polyline
            points={points}
            fill="none"
            stroke={theme.primary}
            strokeWidth="3"
            strokeLinejoin="round"
            strokeLinecap="round"
          />
          {metrics.daily.length <= 14
            ? metrics.daily.map((point, index) => {
                const x =
                  metrics.daily.length === 1 ? 0 : (index * 320) / (metrics.daily.length - 1);
                const y = 100 - Math.min(100, normalizePercent(point.threeStarRate));
                return (
                  <Rect
                    key={point.date}
                    x={x - 3}
                    y={y - 3}
                    width="6"
                    height="6"
                    rx="3"
                    fill={theme.primary}
                  />
                );
              })
            : null}
        </Svg>
        {metrics.daily.map((point, index) => {
          const x = metrics.daily.length === 1 ? 0 : (index * 320) / (metrics.daily.length - 1);
          const y = 100 - Math.min(100, normalizePercent(point.threeStarRate));
          return (
            <Pressable
              key={point.date}
              accessibilityRole="button"
              accessibilityLabel={`${point.date}, ${percent(point.threeStarRate)}`}
              onPress={() => setSelected(index)}
              style={[styles.chartHitTarget, { left: `${(x / 320) * 100}%`, top: `${y}%` }]}
            />
          );
        })}
      </View>
    </View>
  );
}

function BattleContext({
  provider,
  summary,
  onFilters,
}: {
  provider: StatsProvider;
  summary: string;
  onFilters: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={styles.context}>
      <View style={styles.grow}>
        <CKText role="labelSmall" muted>
          {t('filtersDateRange')}
        </CKText>
        <CKText role="rowTitle">{dateSummary(provider, locale)}</CKText>
        <CKText role="bodySmall" muted>
          {summary}
        </CKText>
      </View>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t('generalFilters')}
        onPress={onFilters}
        style={styles.contextButton}
      >
        <Filter color={theme.onSurface} />
      </Pressable>
    </View>
  );
}
function BattleFilters({
  section,
  provider,
  onClose,
}: {
  section: StatsSectionValue;
  provider: StatsProvider;
  onClose: () => void;
}) {
  const { t, locale } = useI18n();
  const cwlLeagues = useLocalizedCwlLeagues(t, locale);
  const theme = useCKTheme();
  const initialTh =
    section === StatsSection.ranked
      ? provider.rankedTownHall
      : section === StatsSection.armies
        ? provider.armiesTownHall
        : section === StatsSection.items
          ? provider.itemsTownHall
          : section === StatsSection.war
            ? provider.warTownHall
            : provider.cwlTownHall;
  const [townHall, setTownHall] = useState<number | undefined>(initialTh);
  const initialOpponent =
    section === StatsSection.war ? provider.warOpponentTownHall : provider.cwlOpponentTownHall;
  const [opponent, setOpponent] = useState<number | undefined>(initialOpponent);
  const initialEqual =
    section === StatsSection.war ? provider.warEqualTownHalls : provider.cwlEqualTownHalls;
  const [equal, setEqual] = useState(initialEqual);
  const initialLeague =
    section === StatsSection.ranked
      ? provider.rankedLeagueTier
      : section === StatsSection.armies
        ? provider.armiesLeagueTier
        : section === StatsSection.items
          ? provider.itemsLeagueTier
          : provider.cwlLeagueId;
  const [league, setLeague] = useState<number | undefined>(initialLeague);
  const [minimum, setMinimum] = useState(provider.armiesMinimumSample);
  const [sortBy, setSortBy] = useState(provider.armiesSortBy);
  const [include, setInclude] = useState<readonly StatsItemQuantityFilter[]>(
    provider.armiesInclude,
  );
  const [includeItem, setIncludeItem] = useState('');
  const [includeMinimum, setIncludeMinimum] = useState('');
  const [includeMaximum, setIncludeMaximum] = useState('');
  const [exclude, setExclude] = useState(provider.armiesExclude.join(', '));
  const [seasons, setSeasons] = useState(provider.cwlSeasons.join(', '));
  const [start, setStart] = useState(StatsDateFilter.formatDate(provider.dates.start));
  const [end, setEnd] = useState(StatsDateFilter.formatDate(provider.dates.end));
  const [dateError, setDateError] = useState<string>();
  const [showDates, setShowDates] = useState(false);
  const [resetItemSelectors, setResetItemSelectors] = useState(false);
  const apply = () => {
    const parsedStart = parseLocalDate(start);
    const parsedEnd = parseLocalDate(end);
    if (!parsedStart || !parsedEnd) {
      setDateError(t('statsDateRangeHint'));
      return;
    }
    const dates = new StatsDateFilter(parsedStart, parsedEnd);
    if (parsedEnd < parsedStart || dates.inclusiveDays > 90) {
      setDateError(t('statsDateRangeTooLong'));
      return;
    }
    if (section === StatsSection.ranked)
      provider.updateRankedFilters({ townHall: townHall ?? 18, leagueTier: league ?? 1 });
    else if (section === StatsSection.armies)
      provider.updateArmiesFilters({
        townHall: townHall ?? null,
        leagueTier: league ?? null,
        minimumSample: Math.max(1, minimum),
        sortBy,
        include,
        exclude: exclude
          .split(',')
          .map((value) => value.trim())
          .filter(Boolean),
      });
    else if (section === StatsSection.items) {
      provider.updateItemFilters({ townHall: townHall ?? null, leagueTier: league ?? null });
      if (resetItemSelectors) provider.setItemSelectors([]);
    } else if (section === StatsSection.war)
      provider.updateWarFilters({
        townHall: townHall ?? null,
        opponentTownHall: opponent ?? null,
        equalTownHalls: equal,
      });
    else
      provider.updateCwlFilters({
        townHall: townHall ?? null,
        opponentTownHall: opponent ?? null,
        equalTownHalls: equal,
        leagueId: league ?? null,
        seasons: seasons
          .split(',')
          .map((value) => value.trim())
          .filter((value) => /^\d{4}-\d{2}$/.test(value)),
      });
    onClose();
    void provider.setDates(parsedStart, parsedEnd);
  };
  const last30Days = () => {
    const today = new Date();
    const rangeEnd = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const rangeStart = new Date(rangeEnd);
    rangeStart.setDate(rangeStart.getDate() - 29);
    setStart(StatsDateFilter.formatDate(rangeStart));
    setEnd(StatsDateFilter.formatDate(rangeEnd));
    setDateError(undefined);
  };
  const reset = () => {
    setTownHall(section === StatsSection.ranked ? 18 : undefined);
    setOpponent(undefined);
    setEqual(true);
    setLeague(section === StatsSection.ranked ? 1 : undefined);
    setMinimum(100);
    setSortBy('usage_rate');
    setInclude([]);
    setIncludeItem('');
    setIncludeMinimum('');
    setIncludeMaximum('');
    setExclude('');
    setSeasons('');
    setResetItemSelectors(section === StatsSection.items);
    setShowDates(false);
    last30Days();
  };
  return (
    <Modal visible transparent animationType="slide" onRequestClose={onClose}>
      <View style={styles.overlay}>
        <View style={[styles.sheet, { backgroundColor: theme.surface }]}>
          <View style={styles.sheetHeader}>
            <CKText role="titleLarge">{t('generalFilters')}</CKText>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('generalCancel')}
              onPress={onClose}
            >
              <X color={theme.onSurfaceVariant} />
            </Pressable>
          </View>
          <ScrollView contentContainerStyle={styles.sheetBody}>
            <Pressable accessibilityRole="button" onPress={last30Days}>
              <FilterLabel
                label={t('filtersQuickFilters')}
                value={t('filtersLast30Days')}
                icon={<CalendarDays color={theme.onSurfaceVariant} />}
              />
            </Pressable>
            <Pressable accessibilityRole="button" onPress={() => setShowDates((value) => !value)}>
              <FilterLabel
                label={t('filtersDateRange')}
                value={`${start} – ${end}`}
                icon={<CalendarDays color={theme.onSurfaceVariant} />}
              />
            </Pressable>
            {showDates ? (
              <CalendarPicker
                range
                start={parseLocalDate(start) ?? provider.dates.start}
                end={parseLocalDate(end) ?? undefined}
                minimum={new Date(2024, 0, 1)}
                maximum={new Date()}
                onChange={(nextStart, nextEnd) => {
                  setStart(StatsDateFilter.formatDate(nextStart));
                  if (nextEnd) {
                    setEnd(StatsDateFilter.formatDate(nextEnd));
                    setShowDates(false);
                  } else {
                    setEnd('');
                  }
                  setDateError(undefined);
                }}
              />
            ) : null}
            {dateError ? (
              <CKText role="bodySmall" style={{ color: theme.error }}>
                {dateError}
              </CKText>
            ) : null}
            <ChoiceField
              label={t('statsTownHall')}
              value={townHall}
              values={
                section === StatsSection.ranked
                  ? Array.from({ length: 12 }, (_, i) => 18 - i)
                  : [undefined, ...Array.from({ length: 12 }, (_, i) => 18 - i)]
              }
              format={(value) => (value == null ? t('statsAllTownHalls') : `TH${value}`)}
              onChange={setTownHall}
            />
            {section === StatsSection.war || section === StatsSection.cwl ? (
              <>
                <View style={styles.switchRow}>
                  <CKText role="rowTitle">{t('statsEqualTownHalls')}</CKText>
                  <Switch value={equal} onValueChange={setEqual} />
                </View>
                {!equal ? (
                  <ChoiceField
                    label={t('statsOpponentTownHall')}
                    value={opponent}
                    values={[undefined, ...Array.from({ length: 12 }, (_, i) => 18 - i)]}
                    format={(value) => (value == null ? t('statsAllTownHalls') : `TH${value}`)}
                    onChange={setOpponent}
                  />
                ) : null}
              </>
            ) : null}
            {section === StatsSection.ranked ||
            section === StatsSection.armies ||
            section === StatsSection.items ||
            section === StatsSection.cwl ? (
              <ChoiceField
                label={section === StatsSection.cwl ? t('statsCwlLeague') : t('statsLeagueTier')}
                value={league}
                values={[
                  ...(section === StatsSection.ranked ? [] : [undefined]),
                  ...(section === StatsSection.cwl
                    ? [...cwlLeagues.keys()].sort((left, right) => left - right)
                    : Array.from({ length: 10 }, (_, i) => i + 1)),
                ]}
                format={(value) =>
                  value == null
                    ? section === StatsSection.cwl
                      ? t('statsAllCwlLeagues')
                      : t('generalAll')
                    : section === StatsSection.cwl
                      ? (cwlLeagues.get(value) ?? `${value}`)
                      : leagueTierSummary(value, t)
                }
                onChange={setLeague}
              />
            ) : null}
            {section === StatsSection.cwl ? (
              <View>
                <CKText role="labelLarge">{t('statsCwlSeasons')}</CKText>
                <TextInput
                  value={seasons}
                  onChangeText={setSeasons}
                  placeholder={t('statsCwlSeasonsHint')}
                  placeholderTextColor={theme.onSurfaceVariant}
                  style={[
                    styles.input,
                    { color: theme.onSurface, borderColor: theme.outlineVariant },
                  ]}
                />
              </View>
            ) : null}
            {section === StatsSection.armies ? (
              <View style={styles.sheetBody}>
                <InlineNotice
                  icon={<Network size={20} color={theme.onSurfaceVariant} />}
                  text={t('statsCustomLensBody')}
                />
                <CKText role="labelLarge">{t('statsMinimumSample')}</CKText>
                <TextInput
                  keyboardType="number-pad"
                  value={`${minimum}`}
                  onChangeText={(value) => setMinimum(Number.parseInt(value, 10) || 0)}
                  style={[
                    styles.input,
                    { color: theme.onSurface, borderColor: theme.outlineVariant },
                  ]}
                />
                <ChoiceField
                  label={t('statsSortBy')}
                  value={sortBy}
                  values={['usage_rate', 'three_star_rate', 'average_stars', 'average_destruction']}
                  format={(value) =>
                    value === 'usage_rate'
                      ? t('statsUsage')
                      : value === 'three_star_rate'
                        ? t('statsThreeStarRate')
                        : value === 'average_stars'
                          ? t('statsAverageStars')
                          : t('statsAverageDestruction')
                  }
                  onChange={setSortBy}
                />
                <CKText role="labelLarge">{t('statsIncludeItems')}</CKText>
                {include.map((item, index) => (
                  <View key={`${item.item}-${index}`} style={styles.includeRow}>
                    <CKText
                      style={styles.grow}
                    >{`${item.item} · ${item.minQuantity ?? 1}–${item.maxQuantity ?? '∞'}`}</CKText>
                    <Pressable
                      accessibilityRole="button"
                      accessibilityLabel={t('presetsDelete')}
                      onPress={() =>
                        setInclude(include.filter((_, itemIndex) => itemIndex !== index))
                      }
                    >
                      <X size={18} color={theme.onSurfaceVariant} />
                    </Pressable>
                  </View>
                ))}
                <View style={styles.dateInputs}>
                  <TextInput
                    value={includeItem}
                    onChangeText={setIncludeItem}
                    placeholder={t('statsItemId')}
                    placeholderTextColor={theme.onSurfaceVariant}
                    style={[
                      styles.input,
                      styles.grow,
                      { color: theme.onSurface, borderColor: theme.outlineVariant },
                    ]}
                  />
                  <TextInput
                    value={includeMinimum}
                    onChangeText={setIncludeMinimum}
                    keyboardType="number-pad"
                    placeholder={t('generalMinimum')}
                    placeholderTextColor={theme.onSurfaceVariant}
                    style={[
                      styles.input,
                      styles.quantityInput,
                      { color: theme.onSurface, borderColor: theme.outlineVariant },
                    ]}
                  />
                  <TextInput
                    value={includeMaximum}
                    onChangeText={setIncludeMaximum}
                    keyboardType="number-pad"
                    placeholder={t('generalMaximum')}
                    placeholderTextColor={theme.onSurfaceVariant}
                    style={[
                      styles.input,
                      styles.quantityInput,
                      { color: theme.onSurface, borderColor: theme.outlineVariant },
                    ]}
                  />
                  <Pressable
                    accessibilityRole="button"
                    accessibilityLabel={t('statsAddItem')}
                    onPress={() => {
                      const item = includeItem.trim();
                      if (!item) return;
                      setInclude([
                        ...include,
                        new StatsItemQuantityFilter(
                          item,
                          parseOptionalInt(includeMinimum),
                          parseOptionalInt(includeMaximum),
                        ),
                      ]);
                      setIncludeItem('');
                      setIncludeMinimum('');
                      setIncludeMaximum('');
                    }}
                    style={styles.addButton}
                  >
                    <CKText role="titleMedium">+</CKText>
                  </Pressable>
                </View>
                <CKText role="labelLarge">{t('statsExcludeItems')}</CKText>
                <TextInput
                  value={exclude}
                  onChangeText={setExclude}
                  placeholder="u_1, u_2"
                  placeholderTextColor={theme.onSurfaceVariant}
                  style={[
                    styles.input,
                    { color: theme.onSurface, borderColor: theme.outlineVariant },
                  ]}
                />
              </View>
            ) : null}
          </ScrollView>
          <View style={styles.actions}>
            <Pressable accessibilityRole="button" onPress={reset} style={styles.secondaryButton}>
              <CKText role="rowTitle">{t('generalReset')}</CKText>
            </Pressable>
            <Pressable accessibilityRole="button" onPress={onClose} style={styles.secondaryButton}>
              <CKText role="rowTitle">{t('generalCancel')}</CKText>
            </Pressable>
            <Pressable accessibilityRole="button" onPress={apply} style={styles.primaryButton}>
              <CKText role="rowTitle" style={styles.primaryText}>
                {t('generalApply')}
              </CKText>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}
function AddItemDialog({
  visible,
  onClose,
  onAdd,
}: {
  visible: boolean;
  onClose: () => void;
  onAdd: (value: StatsItemSelector) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [item, setItem] = useState('');
  const [type, setType] = useState<StatsItemTypeValue>(StatsItemType.troop);
  const [hero, setHero] = useState('Barbarian King');
  const selector = new StatsItemSelector(
    item,
    type,
    type === StatsItemType.equipment ? hero : undefined,
  );
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={styles.overlay}>
        <View style={[styles.dialog, { backgroundColor: theme.surface }]}>
          <CKText role="titleLarge">{t('statsAddItem')}</CKText>
          <InlineNotice
            icon={<BarChart3 size={20} color={theme.secondary} />}
            text={`${t('statsNoLevels')} ${t('statsRankedCompositionOnly')}`}
          />
          <TextInput
            value={item}
            onChangeText={setItem}
            placeholder={t('statsItemId')}
            placeholderTextColor={theme.onSurfaceVariant}
            style={[styles.input, { color: theme.onSurface, borderColor: theme.outlineVariant }]}
          />
          <ChoiceField
            label={t('statsItemType')}
            value={type}
            values={Object.values(StatsItemType)}
            format={(value) => itemTypeLabel(value, t)}
            onChange={setType}
          />
          {type === StatsItemType.equipment ? (
            <ChoiceField
              label={t('statsOwningHero')}
              value={hero}
              values={[...StatsItemSelector.validEquipmentHeroes]}
              format={(value) => value}
              onChange={setHero}
            />
          ) : null}
          <View style={styles.actions}>
            <Pressable onPress={onClose} style={styles.secondaryButton}>
              <CKText role="rowTitle">{t('generalCancel')}</CKText>
            </Pressable>
            <Pressable
              disabled={!selector.isValid}
              onPress={() => onAdd(selector)}
              style={[styles.primaryButton, !selector.isValid && { opacity: 0.4 }]}
            >
              <CKText role="rowTitle" style={styles.primaryText}>
                {t('generalApply')}
              </CKText>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}

function ChoiceField<T>({
  label,
  value,
  values,
  format,
  onChange,
}: {
  label: string;
  value: T;
  values: readonly T[];
  format: (value: T) => string;
  onChange: (value: T) => void;
}) {
  const theme = useCKTheme();
  const [open, setOpen] = useState(false);
  return (
    <View>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${label}: ${format(value)}`}
        onPress={() => setOpen(!open)}
        style={[styles.choiceField, { borderColor: theme.outlineVariant }]}
      >
        <View style={styles.grow}>
          <CKText role="labelSmall" muted>
            {label}
          </CKText>
          <CKText role="rowTitle">{format(value)}</CKText>
        </View>
        <ChevronDown color={theme.onSurfaceVariant} />
      </Pressable>
      {open ? (
        <View style={[styles.choices, { backgroundColor: theme.surfaceContainerHighest }]}>
          {values.map((entry, index) => (
            <Pressable
              key={`${index}:${format(entry)}`}
              onPress={() => {
                onChange(entry);
                setOpen(false);
              }}
              style={styles.choiceRow}
            >
              <CKText style={styles.grow}>{format(entry)}</CKText>
              {Object.is(entry, value) ? <Check size={18} color={theme.primary} /> : null}
            </Pressable>
          ))}
        </View>
      ) : null}
    </View>
  );
}
function FilterLabel({ label, value, icon }: { label: string; value: string; icon: ReactNode }) {
  const theme = useCKTheme();
  return (
    <View style={[styles.choiceField, { borderColor: theme.outlineVariant }]}>
      {icon}
      <View style={styles.grow}>
        <CKText role="labelSmall" muted>
          {label}
        </CKText>
        <CKText role="rowTitle">{value}</CKText>
      </View>
    </View>
  );
}
function SearchField({
  value,
  onChange,
  placeholder,
}: {
  value: string;
  onChange: (value: string) => void;
  placeholder: string;
}) {
  const theme = useCKTheme();
  return (
    <View style={[styles.search, { backgroundColor: theme.surfaceContainerHighest }]}>
      <Search size={20} color={theme.onSurfaceVariant} />
      <TextInput
        value={value}
        onChangeText={onChange}
        placeholder={placeholder}
        placeholderTextColor={theme.onSurfaceVariant}
        style={[styles.searchInput, { color: theme.onSurface }]}
      />
      {value ? (
        <Pressable accessibilityRole="button" onPress={() => onChange('')}>
          <X size={20} color={theme.onSurfaceVariant} />
        </Pressable>
      ) : null}
    </View>
  );
}
function Progress({ label, value }: { label: string; value: number }) {
  const theme = useCKTheme();
  const normalized = normalizePercent(value);
  return (
    <View style={styles.progressRow}>
      <CKText role="labelLarge" style={styles.progressLabel}>
        {label}
      </CKText>
      <View style={[styles.progressTrack, { backgroundColor: theme.surfaceContainerHighest }]}>
        <View
          style={[styles.progressFill, { width: `${normalized}%`, backgroundColor: theme.primary }]}
        />
      </View>
      <Badge>{percent(value)}</Badge>
    </View>
  );
}
function MetricPanel({ label, value }: { label: string; value: string }) {
  return (
    <Surface style={styles.metricPanel}>
      <CKText role="titleLarge">{value}</CKText>
      <CKText role="bodySmall" muted>
        {label}
      </CKText>
    </Surface>
  );
}
function MetricPill({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.metricPill}>
      <CKText role="bodySmall" muted>
        {label}
      </CKText>
      <CKText role="rowTitle">{value}</CKText>
    </View>
  );
}
function ComingSoon({ title }: { title: string }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <EmptyState
      title={title}
      body={t('generalComingSoon')}
      icon={<BarChart3 color={theme.onSurfaceVariant} />}
    />
  );
}
function Section({ children }: { children: ReactNode }) {
  return <View style={styles.section}>{children}</View>;
}
function SectionTitle({ children }: { children: ReactNode }) {
  return <CKText role="titleMedium">{children}</CKText>;
}
function Badge({ children }: { children: ReactNode }) {
  const theme = useCKTheme();
  return (
    <View style={[styles.badge, { backgroundColor: colorWithAlpha(theme.tertiary, 0.2) }]}>
      <CKText role="labelSmall">{children}</CKText>
    </View>
  );
}
function InlineNotice({ icon, text }: { icon: ReactNode; text: string }) {
  const theme = useCKTheme();
  return (
    <View
      style={[
        styles.inlineNotice,
        { backgroundColor: colorWithAlpha(theme.primary, 0.1), borderColor: theme.outlineVariant },
      ]}
    >
      {icon}
      <CKText role="bodySmall" style={styles.grow}>
        {text}
      </CKText>
    </View>
  );
}
function StatsSkeleton({ section }: { section: StatsSectionValue }) {
  const { t } = useI18n();
  const loadingLabel = t('generalLoading');
  if (section === StatsSection.overview) {
    return (
      <View style={styles.section} accessibilityLabel={loadingLabel}>
        <ResponsiveGrid minItemWidth={145} gap={10}>
          {Array.from({ length: 8 }, (_, key) => (
            <Surface key={key} style={styles.metricPanel}>
              <Skeleton width={84} height={10} />
              <Skeleton width={64} height={24} />
            </Surface>
          ))}
        </ResponsiveGrid>
        <ChartSkeleton height={112} />
      </View>
    );
  }
  if (section === StatsSection.players || section === StatsSection.clans) {
    return (
      <View style={styles.section} accessibilityLabel={loadingLabel}>
        {[0, 1, 2].map((key) => (
          <ChartSkeleton key={key} />
        ))}
      </View>
    );
  }
  if (section === StatsSection.armies) {
    return (
      <View style={styles.section} accessibilityLabel={loadingLabel}>
        <ChartSkeleton height={250} />
        <ResultSkeleton />
        <ResultSkeleton />
      </View>
    );
  }
  if (section === StatsSection.items) {
    return (
      <View style={styles.section} accessibilityLabel={loadingLabel}>
        <ResultSkeleton />
        <ResultSkeleton />
      </View>
    );
  }
  return (
    <View style={styles.section} accessibilityLabel={loadingLabel}>
      <Surface style={styles.card}>
        <Skeleton width={156} height={18} />
        <View style={styles.pills}>
          <Skeleton width={116} height={44} />
          <Skeleton width={132} height={44} />
          <Skeleton width={124} height={44} />
        </View>
        <Skeleton height={64} />
      </Surface>
      <ChartSkeleton height={176} />
    </View>
  );
}
function ChartSkeleton({ height = 224 }: { height?: number }) {
  return (
    <Surface style={styles.card}>
      <Skeleton width={172} height={18} />
      <Skeleton width={230} height={11} />
      <Skeleton height={Math.max(40, height - 71)} />
    </Surface>
  );
}
function ResultSkeleton() {
  return (
    <Surface style={[styles.card, styles.resultSkeleton]}>
      <Skeleton width={48} height={48} />
      <View style={styles.grow}>
        <Skeleton width={180} height={15} />
        <Skeleton width={126} height={10} />
      </View>
    </Surface>
  );
}
function Segmented({
  selected,
  onSelect,
}: {
  selected: StatsAudienceValue;
  onSelect: (value: StatsAudienceValue) => void;
}) {
  const { t } = useI18n();
  return (
    <GlassSurface cornerRadius={ckRadius.pill} style={styles.segmented}>
      {[
        [StatsAudience.battle, t('statsBattle')],
        [StatsAudience.world, t('statsWorld')],
      ].map(([value, label]) => (
        <Pressable
          key={value}
          accessibilityRole="tab"
          accessibilityState={{ selected: value === selected }}
          onPress={() => onSelect(value as StatsAudienceValue)}
          style={[styles.segment, value === selected && styles.segmentSelected]}
        >
          <CKText role="labelLarge" style={styles.white}>
            {label}
          </CKText>
        </Pressable>
      ))}
    </GlassSurface>
  );
}
function IconButton({
  label,
  onPress,
  children,
}: {
  label: string;
  onPress: () => void;
  children: ReactNode;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={styles.iconButton}
    >
      {children}
    </Pressable>
  );
}

type Translate = ReturnType<typeof useI18n>['t'];
export function sectionLabel(section: StatsSectionValue, t: Translate): string {
  switch (section) {
    case StatsSection.overview:
      return t('statsOverview');
    case StatsSection.players:
      return t('statsPlayers');
    case StatsSection.clans:
      return t('statsClans');
    case StatsSection.armies:
      return t('statsArmies');
    case StatsSection.items:
      return t('statsItems');
    case StatsSection.war:
      return t('statsWar');
    case StatsSection.cwl:
      return t('statsCwl');
    case StatsSection.ranked:
      return t('statsMeta');
  }
}
function sectionImage(section: StatsSectionValue): string {
  switch (section) {
    case StatsSection.ranked:
      return ImageAssets.hitrate;
    case StatsSection.armies:
      return ImageAssets.getTroopImage('Super Bowler');
    case StatsSection.items:
      return ImageAssets.getGearImage('Eternal Tome');
    case StatsSection.war:
      return ImageAssets.war;
    case StatsSection.cwl:
      return ImageAssets.getWarLeagueImage('Champion League I');
    case StatsSection.overview:
      return ImageAssets.darkModeLogo;
    case StatsSection.players:
      return ImageAssets.townHall(18);
    case StatsSection.clans:
      return ImageAssets.clanCastle;
  }
}
function sectionBackground(section: StatsSectionValue): string {
  switch (section) {
    case StatsSection.overview:
      return ImageAssets.homeBaseBackground;
    case StatsSection.players:
    case StatsSection.ranked:
      return ImageAssets.legendPageBackground;
    case StatsSection.clans:
      return ImageAssets.clanPageBackground;
    case StatsSection.armies:
      return ImageAssets.playerWarStatsPageBackground;
    case StatsSection.items:
      return ImageAssets.playerAchievementPageBackground;
    case StatsSection.war:
      return ImageAssets.warPageBackground;
    case StatsSection.cwl:
      return ImageAssets.cwlPageBackground;
  }
}
function compact(value: number, locale: string): string {
  return formatCompactNumber(value, locale);
}
function normalizePercent(value: number): number {
  return Math.max(0, Math.min(100, Math.abs(value) <= 1 ? value * 100 : value));
}
function percent(value: number): string {
  const normalized = normalizePercent(value);
  return `${normalized.toFixed(normalized >= 10 ? 1 : 2)}%`;
}
function leagueTierSummary(id: number | null | undefined, t: Translate): string {
  if (id == null) return '?';
  return id === 1 ? t('statsLegendLeagueOne') : `${t('statsLeagueTier')} ${id}`;
}
function distributionLeagueLabel(id: number | null): string {
  if (id === 105000036) return 'LL1';
  if (id === 105000035) return 'LL2';
  if (id === 105000034) return 'LL3';
  if (id != null && id >= 105000010) return `L${id - 105000010}`;
  return id == null ? '—' : `${id}`;
}
function cwlLeagueLabel(id: number | null, t: Translate): string {
  if (id == null) return '?';
  const offset = id - 48_000_000;
  if (offset < 0 || offset > 17) return `${id}`;
  const division = ['III', 'II', 'I'][offset % 3];
  const tier = Math.floor(offset / 3);
  const name =
    tier === 0
      ? t('statsLeagueBronze')
      : tier === 1
        ? t('statsLeagueSilver')
        : tier === 2
          ? t('statsLeagueGold')
          : tier === 3
            ? t('statsLeagueCrystal')
            : tier === 4
              ? t('statsLeagueMaster')
              : t('statsLeagueChampion');
  return `${name} ${division}`;
}
function useLocalizedCwlLeagues(t: Translate, locale: string): ReadonlyMap<number, string> {
  useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => gameDataState.revision,
  );
  const leagues = new Map<number, string>();
  for (let id = 48_000_000; id <= 48_000_017; id += 1) {
    leagues.set(id, cwlLeagueLabel(id, t));
  }
  const languageCode = locale.split(/[-_]/, 1)[0] || 'en';
  for (const [id, item] of warLeaguesByApiId()) {
    const fallback = leagues.get(id) ?? (typeof item.name === 'string' ? item.name : `${id}`);
    leagues.set(id, localizedNameForItemOrFallback(item, { languageCode }, fallback));
  }
  return leagues;
}
function townHallSummary(value: number | undefined, t: Translate): string {
  return value == null ? t('statsAllTownHalls') : `TH${value}`;
}
function dateSummary(provider: StatsProvider, locale: string): string {
  const formatter = new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
  return `${formatter.format(provider.dates.start)} – ${formatter.format(provider.dates.end)}`;
}
function parseLocalDate(value: string): Date | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value.trim());
  if (!match) return null;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const result = new Date(year, month - 1, day);
  return result.getFullYear() === year &&
    result.getMonth() === month - 1 &&
    result.getDate() === day
    ? result
    : null;
}
function parseOptionalInt(value: string): number | undefined {
  const parsed = Number.parseInt(value.trim(), 10);
  return Number.isFinite(parsed) ? parsed : undefined;
}
function itemTypeLabel(value: StatsItemTypeValue, t: Translate): string {
  switch (value) {
    case StatsItemType.troop:
      return t('statsTroop');
    case StatsItemType.spell:
      return t('statsSpell');
    case StatsItemType.hero:
      return t('statsHero');
    case StatsItemType.pet:
      return t('statsPet');
    case StatsItemType.equipment:
      return t('statsEquipment');
  }
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  grow: { flex: 1, minWidth: 0 },
  heroScrim: { ...StyleSheet.absoluteFill, backgroundColor: '#0008' },
  hero: { flex: 1, paddingHorizontal: 12, paddingBottom: 18 },
  topRow: {
    height: 52,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  iconButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  identity: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 3 },
  heroImage: { width: 60, height: 60 },
  white: { color: '#FFF' },
  segmented: {
    height: 44,
    flexDirection: 'row',
    width: '100%',
    maxWidth: 520,
    alignSelf: 'center',
    padding: 4,
  },
  segment: { flex: 1, alignItems: 'center', justifyContent: 'center', borderRadius: 999 },
  segmentSelected: { backgroundColor: '#FFFFFF2E' },
  tabs: { gap: 8, paddingVertical: 12 },
  tab: {
    minHeight: 54,
    minWidth: 145,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  tabImage: { width: 30, height: 30 },
  section: { gap: 12, paddingBottom: 12 },
  sectionFrame: { gap: 10 },
  state: { marginVertical: 24 },
  card: { padding: 16, gap: 12 },
  resultSkeleton: { flexDirection: 'row', alignItems: 'center' },
  summary: { padding: 16, flexDirection: 'row', alignItems: 'center', gap: 12 },
  metricPanel: { padding: 14, minHeight: 88, justifyContent: 'center' },
  bars: { height: 190, flexDirection: 'row', alignItems: 'flex-end', gap: 4, paddingTop: 16 },
  barColumn: { flex: 1, height: 165, justifyContent: 'flex-end', alignItems: 'center', gap: 6 },
  bar: { width: '70%', maxWidth: 14, borderTopLeftRadius: 5, borderTopRightRadius: 5 },
  titleRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 8 },
  strategy: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  strategyImage: { width: 36, height: 36 },
  cardExtra: { gap: 8 },
  inlineNotice: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    padding: 12,
    borderRadius: 12,
    borderWidth: StyleSheet.hairlineWidth,
  },
  badge: {
    minHeight: 26,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
    justifyContent: 'center',
  },
  armyItems: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  armyIconWrap: { width: 44, height: 44 },
  armyIcon: { width: 40, height: 40 },
  armyCount: {
    position: 'absolute',
    right: 0,
    bottom: 0,
    minWidth: 18,
    minHeight: 16,
    borderRadius: 999,
    backgroundColor: '#111',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 3,
  },
  scatterChart: { height: 210, position: 'relative' },
  trendChart: { height: 150, position: 'relative' },
  chartHitTarget: {
    position: 'absolute',
    width: 28,
    height: 28,
    marginLeft: -14,
    marginTop: -14,
    borderRadius: 14,
  },
  pills: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  metricPill: { minWidth: 105, padding: 10, borderRadius: 12, backgroundColor: '#80808018' },
  progressRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  progressLabel: { width: 34 },
  progressTrack: { height: 9, flex: 1, borderRadius: 999, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: 999 },
  context: { minHeight: 72, flexDirection: 'row', alignItems: 'center', gap: 12 },
  contextButton: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  search: {
    minHeight: 54,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 14,
    borderRadius: 16,
  },
  searchInput: { flex: 1, minHeight: 48, fontSize: 16 },
  primaryButton: {
    minHeight: 48,
    paddingHorizontal: 18,
    borderRadius: 14,
    backgroundColor: '#D90709',
    alignItems: 'center',
    justifyContent: 'center',
  },
  primaryText: { color: '#FFF' },
  secondaryButton: {
    minHeight: 48,
    paddingHorizontal: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  overlay: { flex: 1, backgroundColor: '#0007', justifyContent: 'flex-end' },
  sheet: {
    width: '100%',
    maxWidth: 720,
    maxHeight: '92%',
    alignSelf: 'center',
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    padding: 20,
    gap: 12,
  },
  dialog: {
    width: '90%',
    maxWidth: 520,
    alignSelf: 'center',
    borderRadius: 24,
    padding: 20,
    gap: 14,
  },
  sheetHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  sheetBody: { gap: 12 },
  dateInputs: { flexDirection: 'row', gap: 10 },
  includeRow: { minHeight: 44, flexDirection: 'row', alignItems: 'center', gap: 8 },
  quantityInput: { width: 86 },
  addButton: { width: 44, minHeight: 50, alignItems: 'center', justifyContent: 'center' },
  actions: { flexDirection: 'row', justifyContent: 'flex-end', gap: 8 },
  input: { minHeight: 50, borderWidth: 1, borderRadius: 12, paddingHorizontal: 12, fontSize: 16 },
  choiceField: {
    minHeight: 60,
    borderWidth: 1,
    borderRadius: 12,
    padding: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  choices: { borderRadius: 12, padding: 4, maxHeight: 360 },
  choiceRow: { minHeight: 44, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 10 },
  switchRow: {
    minHeight: 52,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
});
