import {
  memo,
  useCallback,
  useMemo,
  useState,
  useSyncExternalStore,
  type Dispatch,
  type ReactNode,
  type SetStateAction,
} from 'react';
import {
  ActivityIndicator,
  FlatList,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  TextInput,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  CalendarDays,
  Check,
  ChevronDown,
  ChevronUp,
  Network,
  TriangleAlert,
  X,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import type { ContractApiService } from '../../../core/api/contract-api';
import { localizedNameForItemOrFallback } from '../../../core/game-data/game-data-localization';
import { warLeaguesByApiId } from '../../../core/game-data/game-data-normalization';
import {
  gameDataState,
  isRecord,
  subscribeToGameDataRevision,
} from '../../../core/game-data/game-data-state';
import { formatCompactNumber, materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  CalendarPicker,
  EmptyState,
  ErrorState,
  MobileWebImage,
  ProfileTabs,
  Surface,
  ProfilePageHeader,
  ProfileStatChip,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { StatsLoadStatus, type StatsProvider } from '../data';
import {
  isArmyItemIdentity,
  type StatsArmySetupResponse,
  StatsClanCountsResponse,
  StatsCwlResponse,
  StatsDateFilter,
  StatsDailyPoint,
  StatsItemQuantityFilter,
  StatsLegendCohort,
  StatsLegendResponse,
  StatsTroopStatsResponse,
  StatsPerformanceResponse,
  StatsPlayerCountsResponse,
  StatsSection,
  type StatsLegendCohortValue,
  type StatsLegendDay,
  StatsMetrics,
  type StatsSectionValue,
} from '../models';
import { ArmySetupSection } from './army-setup-section';
import { PlayersSection, ClansSection } from './world-stats-sections';
import { CwlParticipationSection } from './cwl-participation-section';
import { AnalyticsLineChart } from './analytics-chart';
import { ChartInteractionBoundary } from './chart-interaction-boundary';
import { LeagueStatsPicker } from './league-stats-picker';
import { StatsChartFrame } from './stats-chart-frame';
import {
  StatsChartPreferencesProvider,
  StatsChartSettings,
  useChartGranularity,
} from './stats-chart-preferences';

type StatsScreenProps = {
  provider: StatsProvider;
  revision?: number;
  onBack: () => void;
  api?: ContractApiService;
};

export function StatsScreen(props: StatsScreenProps) {
  'use no memo';
  return (
    <StatsChartPreferencesProvider key={props.provider.section} provider={props.provider}>
      <ChartInteractionBoundary>
        <StatsScreenBody {...props} />
      </ChartInteractionBoundary>
    </StatsChartPreferencesProvider>
  );
}

function StatsScreenBody({ provider, revision, onBack, api }: StatsScreenProps) {
  'use no memo';
  void revision;
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const granularity = useChartGranularity();
  const horizontal = Math.max(16, (width - 1120) / 2);
  const hasDateFilter =
    provider.section === StatsSection.war ||
    provider.section === StatsSection.ranked ||
    provider.section === StatsSection.armies ||
    provider.section === StatsSection.items;
  const dates =
    provider.section === StatsSection.war ? (provider.warDates ?? provider.dates) : provider.dates;
  const dateFormat = new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'short',
    day: 'numeric',
    ...(dates?.start.getFullYear() !== dates?.end.getFullYear()
      ? { year: 'numeric' as const }
      : {}),
  });
  const hero = (
    <View style={{ paddingBottom: 16 }}>
      <ProfilePageHeader
        testID="stats-header"
        title={sectionLabel(provider.section, t)}
        imageUrl={sectionImage(provider.section)}
        backgroundUrl={sectionBackdrop(provider.section)}
        safeTop={insets.top}
        onBack={onBack}
        backLabel={materialBackLabel(locale)}
        actions={
          hasDateFilter ? (
            <StatsChartSettings provider={provider} triggerColor="#FFFFFF" />
          ) : undefined
        }
      >
        {hasDateFilter && dates ? (
          <View
            style={{ flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', gap: 7 }}
          >
            <ProfileStatChip
              label={t('statsDateRange')}
              value={`${dateFormat.format(dates.start)} – ${dateFormat.format(dates.end)}`}
              iconElement={<CalendarDays size={19} color={theme.onSurface} />}
            />
            <ProfileStatChip
              label={t('statsChartGranularity')}
              value={t(
                granularity === 'day'
                  ? 'statsDaily'
                  : granularity === 'week'
                    ? 'statsWeekly'
                    : 'statsMonthly',
              )}
            />
          </View>
        ) : null}
      </ProfilePageHeader>
    </View>
  );
  const troopState = provider.currentState;
  if (
    provider.section === StatsSection.items &&
    troopState.data instanceof StatsTroopStatsResponse
  ) {
    return (
      <SafeAreaView
        edges={['left', 'right']}
        style={[styles.fill, { backgroundColor: theme.background }]}
      >
        <ItemsSection
          data={troopState.data}
          hero={hero}
          horizontal={horizontal}
          bottomInset={insets.bottom}
          refreshing={troopState.isRefreshing}
          error={troopState.error}
        />
      </SafeAreaView>
    );
  }
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.fill, { backgroundColor: theme.background }]}
    >
      <ScrollView contentContainerStyle={{ paddingBottom: insets.bottom + 24 }}>
        {hero}
        <View style={{ paddingHorizontal: horizontal }}>
          <StatsSectionContent provider={provider} api={api} />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function armyControlsKey(provider: StatsProvider): string {
  return `${provider.dates.start.getTime()}:${provider.dates.end.getTime()}:${provider.armyRankLimit ?? 'all'}:${provider.armySetupSort}`;
}

function StatsSectionContent({
  provider,
  api,
}: {
  provider: StatsProvider;
  api?: ContractApiService;
}) {
  'use no memo';
  const state = provider.currentState;
  const { t } = useI18n();
  const theme = useCKTheme();
  const [emptyFilters, setEmptyFilters] = useState(false);
  if (state.status === StatsLoadStatus.loading) {
    if (provider.section === StatsSection.armies)
      return <ArmySetupSection key={armyControlsKey(provider)} provider={provider} listLoading />;
    return <StatsSkeleton />;
  }
  if (state.status === StatsLoadStatus.error)
    return (
      <View style={styles.section}>
        {provider.section === StatsSection.armies ? (
          <ArmySetupSection key={armyControlsKey(provider)} provider={provider} />
        ) : null}
        <ErrorState
          title={t('sideStatsLoadError')}
          body={statsErrorBody(provider.section, state.error)}
          actionLabel={t('generalRetry')}
          onAction={() => void provider.load(provider.section, true)}
          style={styles.state}
        />
      </View>
    );
  if (
    state.status === StatsLoadStatus.empty &&
    provider.section === StatsSection.cwl &&
    state.data instanceof StatsCwlResponse
  )
    return (
      <CwlParticipationSection
        data={state.data}
        onSelectSeason={(season) => provider.setCwlSeason(season)}
      />
    );
  if (state.status === StatsLoadStatus.empty) {
    return (
      <Section>
        <EmptyState
          title={t('statsNoDataTitle')}
          body={t('statsNoDataBody')}
          actionLabel={t('generalRetry')}
          onAction={() => void provider.load(provider.section, true)}
          style={styles.state}
        />
        {emptyFilters && provider.section === StatsSection.armies ? (
          <BattleFilters
            section={provider.section}
            provider={provider}
            onClose={() => setEmptyFilters(false)}
          />
        ) : null}
      </Section>
    );
  }
  if (!state.data) {
    if (provider.section === StatsSection.armies)
      return <ArmySetupSection key={armyControlsKey(provider)} provider={provider} listLoading />;
    return <StatsSkeleton />;
  }
  let content: ReactNode;
  switch (provider.section) {
    case StatsSection.players:
      content = <PlayersSection data={state.data as StatsPlayerCountsResponse} />;
      break;
    case StatsSection.clans:
      content = <ClansSection data={state.data as StatsClanCountsResponse} />;
      break;
    case StatsSection.armies:
      content = (
        <ArmySetupSection
          key={armyControlsKey(provider)}
          provider={provider}
          data={state.data as StatsArmySetupResponse}
        />
      );
      break;
    case StatsSection.items:
      content = <ItemsSection data={state.data as StatsTroopStatsResponse} />;
      break;
    case StatsSection.ranked:
      content = <RankedOverview data={state.data as StatsLegendResponse} />;
      break;
    case StatsSection.war:
      content = <WarOverview data={state.data as StatsPerformanceResponse} />;
      break;
    case StatsSection.cwl:
      content = (
        <CwlParticipationSection
          data={state.data as StatsCwlResponse}
          onSelectSeason={(season) => provider.setCwlSeason(season)}
        />
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
    </View>
  );
}
function ItemsSection({
  data,
  hero,
  horizontal,
  bottomInset,
  refreshing,
  error,
}: {
  data?: StatsTroopStatsResponse;
  hero?: ReactNode;
  horizontal?: number;
  bottomInset?: number;
  refreshing?: boolean;
  error?: unknown;
}) {
  'use no memo';
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const { width, fontScale } = useWindowDimensions();
  const [category, setCategory] = useState<LegendCategory>('troops');
  const [cohort, setCohort] = useState<'overall' | 'top1000' | 'top200'>('overall');
  const [compareOpen, setCompareOpen] = useState(false);
  const [selected, setSelected] = useState<readonly string[]>([]);
  const [expanded, setExpanded] = useState<ExpandedLegendItem | null>(null);
  const selectedData =
    cohort === 'overall' ? data?.legend : cohort === 'top1000' ? data?.top1000 : data?.top200;
  const index = useMemo(
    () => (selectedData ? buildLegendCategoryIndex(selectedData, category, locale) : null),
    [selectedData, category, locale],
  );
  const cohortIndices = useMemo(() => {
    if (!data) return null;
    return {
      overall:
        cohort === 'overall' && index
          ? legendCategoryUsageFromIndex(index)
          : buildLegendCategoryUsage(data.legend, category),
      top1000:
        cohort === 'top1000' && index
          ? legendCategoryUsageFromIndex(index)
          : data.top1000
            ? buildLegendCategoryUsage(data.top1000, category)
            : null,
      top200:
        cohort === 'top200' && index
          ? legendCategoryUsageFromIndex(index)
          : data.top200
            ? buildLegendCategoryUsage(data.top200, category)
            : null,
    };
  }, [data, cohort, category, index]);
  const largeText = fontScale > 1.4;
  const showCompareText = width >= 375 && !largeText;
  if (!data) return null;
  const controls = (
    <View style={[styles.section, { paddingHorizontal: horizontal ?? 0 }]}>
      {refreshing ? <ActivityIndicator color={theme.primary} /> : null}
      {error ? (
        <InlineNotice icon={<TriangleAlert size={20} color={theme.error} />} text={String(error)} />
      ) : null}
      <View
        testID="troop-league-compare-row"
        style={{
          flexDirection: 'row',
          flexWrap: largeText ? 'wrap' : 'nowrap',
          alignItems: 'center',
          gap: 8,
        }}
      >
        <View style={{ flex: 1, flexBasis: largeText ? '100%' : undefined, minWidth: 0 }}>
          <LeagueStatsPicker />
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityState={{ selected: compareOpen }}
          accessibilityLabel={compareOpen ? t('homeDone') : t('statsCompareItems')}
          accessibilityHint={compareOpen ? `${selected.length}/5` : undefined}
          onPress={() => {
            if (compareOpen) setSelected([]);
            setCompareOpen(!compareOpen);
          }}
          style={({ pressed }) => ({
            minHeight: 44,
            minWidth: showCompareText ? undefined : 44,
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 7,
            paddingHorizontal: showCompareText ? 8 : 6,
            marginLeft: largeText ? 'auto' : undefined,
            opacity: pressed ? 0.65 : 1,
          })}
        >
          {compareOpen ? (
            <Check size={17} color={theme.primary} />
          ) : (
            <Network size={17} color={theme.primary} />
          )}
          {showCompareText ? (
            <CKText role="labelLarge" style={{ color: theme.primary }}>
              {compareOpen ? t('homeDone') : t('statsCompareItems')}
              {compareOpen ? ` ${selected.length}/5` : ''}
            </CKText>
          ) : null}
        </Pressable>
        {compareOpen && selected.length ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={`${t('searchClear')} ${t('statsCompareItems')}`}
            onPress={() => setSelected([])}
            style={({ pressed }) => ({
              minWidth: 44,
              minHeight: 44,
              alignItems: 'center',
              justifyContent: 'center',
              opacity: pressed ? 0.65 : 1,
            })}
          >
            <X size={18} color={theme.primary} />
          </Pressable>
        ) : null}
      </View>
      <ProfileTabs
        variant="underline"
        overflow="scroll"
        tabs={legendCategories(t)}
        selectedKey={category}
        onSelect={(key) => {
          if (key === category) return;
          setCategory(key as LegendCategory);
          setExpanded(null);
          setCompareOpen(false);
          setSelected([]);
        }}
      />
    </View>
  );
  return index ? (
    // Keep the list and its header tabs mounted while local filters change; their native scroll offsets live here.
    <LegendCategoryRanking
      category={category}
      index={index}
      locale={locale}
      compareOpen={compareOpen}
      selected={selected}
      onSelectedChange={setSelected}
      expanded={expanded}
      onExpandedChange={setExpanded}
      header={
        <>
          {hero}
          {controls}
        </>
      }
      horizontal={horizontal ?? 0}
      bottomInset={bottomInset ?? 0}
      cohortIndices={cohortIndices}
      cohort={cohort}
      onSelectCohort={(next) => {
        if (
          next === cohort ||
          (next === 'top1000' && !data.top1000) ||
          (next === 'top200' && !data.top200)
        )
          return;
        setCohort(next);
        setExpanded(null);
        setCompareOpen(false);
        setSelected([]);
      }}
    />
  ) : (
    <FlatList
      data={[]}
      renderItem={() => null}
      ListHeaderComponent={
        <>
          {hero}
          {controls}
          <EmptyState title={t('generalNoDataAvailable')} />
        </>
      }
      contentContainerStyle={{ paddingBottom: (bottomInset ?? 0) + 24 }}
    />
  );
}

function legendMetrics(data: StatsLegendResponse): StatsMetrics {
  const attacks = data.items.reduce((sum, day) => sum + day.attacks, 0);
  const stars = [0, 1, 2, 3].map((index) =>
    data.items.reduce((sum, day) => sum + day.starCounts[index]!, 0),
  );
  const weightedDestruction = data.items.reduce(
    (sum, day) => sum + (day.averageDestruction ?? 0) * day.attacks,
    0,
  );
  const daily = [...data.items]
    .sort((left, right) => left.day.localeCompare(right.day))
    .map((day) => {
      const value = day.metrics;
      return new StatsDailyPoint(
        day.day,
        day.attacks,
        value.averageStars,
        value.averageDestruction,
        value.zeroStarRate,
        value.oneStarRate,
        value.twoStarRate,
        value.threeStarRate,
      );
    });
  return new StatsMetrics(
    attacks > 0,
    attacks,
    attacks === 0 ? 0 : stars.reduce((sum, count, index) => sum + count * index, 0) / attacks,
    attacks === 0 ? 0 : weightedDestruction / attacks,
    attacks === 0 ? 0 : stars[0]! / attacks,
    attacks === 0 ? 0 : stars[1]! / attacks,
    attacks === 0 ? 0 : stars[2]! / attacks,
    attacks === 0 ? 0 : stars[3]! / attacks,
    daily,
  );
}

type LegendCategory =
  | 'troops'
  | 'spells'
  | 'sieges'
  | 'heroes'
  | 'pets'
  | 'equipment'
  | 'equipmentPairs'
  | 'petCombos'
  | 'petAssignments';

interface LegendCategoryValue {
  readonly key: string;
  readonly name: string;
  readonly imageUrls: readonly string[];
  readonly uses: number;
  readonly triples: number;
}
interface LegendCategoryIndex {
  readonly values: readonly LegendCategoryValue[];
  readonly attacks: number;
  readonly backgroundTriples: number;
  readonly days: readonly {
    readonly day: string;
    readonly attacks: number;
    readonly entries: ReadonlyMap<string, LegendCategoryValue>;
  }[];
}
interface LegendCategoryUsage {
  readonly attacks: number;
  readonly uses: ReadonlyMap<string, number>;
}
type LegendPresentation = ReturnType<typeof legendItemPresentation>;
type LegendPresent = (
  type: 'troop' | 'spell' | 'siege' | 'hero' | 'pet' | 'equipment',
  id: number,
) => LegendPresentation;

function legendCategories(t: Translate): readonly { key: LegendCategory; label: string }[] {
  return [
    { key: 'troops', label: t('gameTroops') },
    { key: 'spells', label: t('gameSpells') },
    { key: 'sieges', label: t('gameSiegeMachines') },
    { key: 'heroes', label: t('statsHero') },
    { key: 'pets', label: t('statsPet') },
    { key: 'equipment', label: t('statsEquipment') },
    { key: 'equipmentPairs', label: t('statsEquipmentPairs') },
    { key: 'petCombos', label: t('statsPetCombinations') },
    { key: 'petAssignments', label: `${t('statsPet')} → ${t('statsHero')}` },
  ];
}

const legendCategoryIndexCache = new WeakMap<
  StatsLegendResponse,
  Map<string, LegendCategoryIndex>
>();
const legendCategoryUsageCache = new WeakMap<
  StatsLegendResponse,
  Map<LegendCategory, LegendCategoryUsage>
>();

function legendCategoryUsageFromIndex(index: LegendCategoryIndex): LegendCategoryUsage {
  return {
    attacks: index.attacks,
    uses: new Map(index.values.map((value) => [value.key, value.uses])),
  };
}

function buildLegendCategoryUsage(
  data: StatsLegendResponse,
  category: LegendCategory,
): LegendCategoryUsage {
  const cached = legendCategoryUsageCache.get(data)?.get(category);
  if (cached) return cached;
  const uses = new Map<string, number>();
  let attacks = 0;
  for (const day of data.items) {
    attacks += day.attacks;
    const entries: readonly { key: string; uses: number }[] =
      category === 'equipmentPairs'
        ? day.equipmentPairs.map((item) => ({
            key: `${item.heroId}:${item.equipmentIds.join(':')}`,
            uses: item.uses,
          }))
        : category === 'petCombos'
          ? day.petCombos.map((item) => ({ key: item.petIds.join(':'), uses: item.uses }))
          : category === 'petAssignments'
            ? day.petAssignments.map((item) => ({
                key: `${item.petId}:${item.heroId}`,
                uses: item.uses,
              }))
            : day[category].map((item) => ({ key: String(item.id), uses: item.uses }));
    for (const entry of entries) uses.set(entry.key, (uses.get(entry.key) ?? 0) + entry.uses);
  }
  const result = { attacks, uses };
  const dataCache =
    legendCategoryUsageCache.get(data) ?? new Map<LegendCategory, LegendCategoryUsage>();
  dataCache.set(category, result);
  legendCategoryUsageCache.set(data, dataCache);
  return result;
}

function buildLegendCategoryIndex(
  data: StatsLegendResponse,
  category: LegendCategory,
  locale: string,
): LegendCategoryIndex {
  const cacheKey = `${locale}:${category}`;
  const cached = legendCategoryIndexCache.get(data)?.get(cacheKey);
  if (cached) return cached;
  const values = new Map<string, LegendCategoryValue>();
  const presentations = new Map<string, LegendPresentation>();
  const present: LegendPresent = (type, id) => {
    const key = `${type}:${id}`;
    const existing = presentations.get(key);
    if (existing) return existing;
    const result = legendItemPresentation(type, id, locale);
    presentations.set(key, result);
    return result;
  };
  let attacks = 0;
  let backgroundTriples = 0;
  const days = data.items.map((day) => {
    attacks += day.attacks;
    backgroundTriples += day.starCounts[3];
    const entries = new Map<string, LegendCategoryValue>();
    for (const item of legendCategoryEntries(day, category, locale, present)) {
      const daily = entries.get(item.key);
      entries.set(item.key, {
        ...item,
        uses: (daily?.uses ?? 0) + item.uses,
        triples: (daily?.triples ?? 0) + item.triples,
      });
      const current = values.get(item.key);
      values.set(item.key, {
        ...item,
        uses: (current?.uses ?? 0) + item.uses,
        triples: (current?.triples ?? 0) + item.triples,
      });
    }
    return { day: day.day, attacks: day.attacks, entries };
  });
  const result = {
    values: [...values.values()].sort(
      (left, right) => right.uses - left.uses || left.name.localeCompare(right.name),
    ),
    attacks,
    backgroundTriples,
    days,
  };
  const dataCache = legendCategoryIndexCache.get(data) ?? new Map<string, LegendCategoryIndex>();
  dataCache.set(cacheKey, result);
  legendCategoryIndexCache.set(data, dataCache);
  return result;
}

function legendCategoryEntries(
  day: StatsLegendDay,
  category: LegendCategory,
  locale: string,
  present: LegendPresent = (type, id) => legendItemPresentation(type, id, locale),
): readonly LegendCategoryValue[] {
  if (category === 'equipmentPairs') {
    return day.equipmentPairs.map((item) => {
      const hero = present('hero', item.heroId);
      const equipment = item.equipmentIds.map((id) => present('equipment', id));
      return {
        key: `${item.heroId}:${item.equipmentIds.join(':')}`,
        name: `${hero.name} · ${equipment.map((value) => value.name).join(' + ')}`,
        imageUrls: [hero.imageUrl, ...equipment.map((value) => value.imageUrl)],
        uses: item.uses,
        triples: item.triples,
      };
    });
  }
  if (category === 'petCombos') {
    return day.petCombos.map((item) => {
      const pets = item.petIds.map((id) => present('pet', id));
      return {
        key: item.petIds.join(':'),
        name: pets.map((value) => value.name).join(' + '),
        imageUrls: pets.map((value) => value.imageUrl),
        uses: item.uses,
        triples: item.triples,
      };
    });
  }
  if (category === 'petAssignments') {
    return day.petAssignments.map((item) => {
      const pet = present('pet', item.petId);
      const hero = present('hero', item.heroId);
      return {
        key: `${item.petId}:${item.heroId}`,
        name: `${pet.name} → ${hero.name}`,
        imageUrls: [pet.imageUrl, hero.imageUrl],
        uses: item.uses,
        triples: item.triples,
      };
    });
  }
  const source = day[category];
  const type =
    category === 'troops'
      ? 'troop'
      : category === 'spells'
        ? 'spell'
        : category === 'sieges'
          ? 'siege'
          : category === 'heroes'
            ? 'hero'
            : category === 'pets'
              ? 'pet'
              : 'equipment';
  return source.map((item) => {
    const presentation = present(type, item.id);
    return {
      key: `${item.id}`,
      name: presentation.name,
      imageUrls: [presentation.imageUrl],
      uses: item.uses,
      triples: item.triples,
    };
  });
}

type ExpandedLegendItem = {
  readonly cohort: 'overall' | 'top1000' | 'top200';
  readonly category: LegendCategory;
  readonly key: string;
};

function LegendCategoryRanking({
  category,
  index,
  locale,
  compareOpen,
  selected,
  onSelectedChange,
  expanded,
  onExpandedChange,
  header,
  horizontal,
  bottomInset,
  cohortIndices,
  cohort,
  onSelectCohort,
}: {
  readonly category: LegendCategory;
  readonly index: LegendCategoryIndex;
  readonly locale: string;
  readonly compareOpen: boolean;
  readonly selected: readonly string[];
  readonly onSelectedChange: Dispatch<SetStateAction<readonly string[]>>;
  readonly expanded: ExpandedLegendItem | null;
  readonly onExpandedChange: Dispatch<SetStateAction<ExpandedLegendItem | null>>;
  readonly header: ReactNode;
  readonly horizontal: number;
  readonly bottomInset: number;
  readonly cohortIndices: {
    readonly overall: LegendCategoryUsage | null;
    readonly top1000: LegendCategoryUsage | null;
    readonly top200: LegendCategoryUsage | null;
  } | null;
  readonly cohort: 'overall' | 'top1000' | 'top200';
  readonly onSelectCohort: (cohort: 'overall' | 'top1000' | 'top200') => void;
}) {
  const { t } = useI18n();
  const [comparisonMetric, setComparisonMetric] = useState<'usage' | 'hitrate'>('usage');
  const values = index.values;
  const selectedKeys = selected.filter((key) => values.some((value) => value.key === key));
  const toggleExpanded = useCallback(
    (key: string) => {
      onExpandedChange((current) =>
        current?.cohort === cohort && current.category === category && current.key === key
          ? null
          : { cohort, category, key },
      );
    },
    [category, cohort, onExpandedChange],
  );
  const toggleSelected = useCallback(
    (key: string) => {
      onSelectedChange((current) =>
        current.includes(key)
          ? current.filter((selectedKey) => selectedKey !== key)
          : current.length < 5
            ? [...current, key]
            : current,
      );
    },
    [onSelectedChange],
  );
  const cohortValues = useMemo(() => {
    if (!cohortIndices) return null;
    return (['overall', 'top1000', 'top200'] as const).map((key) => ({
      key,
      label:
        key === 'overall'
          ? t('generalAll')
          : t('rankingsTopCount', { count: key === 'top1000' ? 1000 : 200 }),
      index: cohortIndices[key],
      values: cohortIndices[key]?.uses ?? new Map<string, number>(),
    }));
  }, [cohortIndices, t]);
  const title = legendCategories(t).find((item) => item.key === category)?.label ?? '';
  const listHeader = (
    <>
      {header}
      {!values.length ? (
        <EmptyState
          title={title}
          body={t('generalNoDataAvailable')}
          actionLabel={cohort === 'overall' ? undefined : t('generalAll')}
          onAction={cohort === 'overall' ? undefined : () => onSelectCohort('overall')}
        />
      ) : null}
      <View
        style={{ gap: 12, paddingHorizontal: horizontal }}
        testID={`legend-category-${category}`}
      >
        {compareOpen && selectedKeys.length ? (
          <Surface style={styles.card} testID="legend-item-comparison">
            <ProfileTabs
              variant="underline"
              tabs={[
                { key: 'usage', label: t('statsUsage') },
                { key: 'hitrate', label: t('statsThreeStarRate') },
              ]}
              selectedKey={comparisonMetric}
              onSelect={(metric) => setComparisonMetric(metric as 'usage' | 'hitrate')}
            />
            <AnalyticsLineChart
              title={comparisonMetric === 'usage' ? t('statsUsage') : t('statsThreeStarRate')}
              series={selectedKeys.map((key, seriesIndex) => ({
                key,
                label: values.find((value) => value.key === key)?.name ?? key,
                color: ['#E8A524', '#85BCEB', '#A799EF', '#14A37F', '#E85D9E'][seriesIndex],
                points: index.days.map((day) => {
                  const item = day.entries.get(key);
                  return {
                    day: day.day,
                    weight: comparisonMetric === 'usage' ? day.attacks : (item?.uses ?? 0),
                    value:
                      comparisonMetric === 'usage'
                        ? day.attacks
                          ? (100 * (item?.uses ?? 0)) / day.attacks
                          : null
                        : item?.uses
                          ? (100 * item.triples) / item.uses
                          : null,
                  };
                }),
              }))}
              percent
            />
          </Surface>
        ) : compareOpen ? (
          <CKText role="bodySmall" muted>
            {t('statsCompareItemsHint')}
          </CKText>
        ) : null}
        {cohortValues ? (
          <CKText role="bodySmall" muted>
            {t('statsAcrossCohorts')}
          </CKText>
        ) : null}
      </View>
    </>
  );
  return (
    <FlatList
      testID="troop-ranking-list"
      data={values}
      keyExtractor={(value) => value.key}
      initialNumToRender={8}
      maxToRenderPerBatch={8}
      windowSize={7}
      extraData={{ expanded, selectedKeys, compareOpen, cohortValues }}
      ListHeaderComponent={listHeader}
      contentContainerStyle={{ gap: 8, paddingBottom: bottomInset + 24 }}
      renderItem={({ item: value, index: position }) => (
        <LegendRankingRow
          value={value}
          position={position}
          category={category}
          index={index}
          locale={locale}
          horizontal={horizontal}
          expanded={expanded?.cohort === cohort && expanded.category === category && expanded.key === value.key}
          selected={selectedKeys.includes(value.key)}
          selectionLimitReached={selectedKeys.length >= 5}
          compareOpen={compareOpen}
          cohortValues={cohortValues}
          cohort={cohort}
          onSelectCohort={onSelectCohort}
          onToggleExpanded={toggleExpanded}
          onToggleSelected={toggleSelected}
        />
      )}
    />
  );
}

type CohortRowValue = {
  readonly key: 'overall' | 'top1000' | 'top200';
  readonly label: string;
  readonly index: LegendCategoryUsage | null;
  readonly values: ReadonlyMap<string, number>;
};

const LegendRankingRow = memo(function LegendRankingRow({
  value,
  position,
  category,
  index,
  locale,
  horizontal,
  expanded,
  selected,
  selectionLimitReached,
  compareOpen,
  cohortValues,
  cohort,
  onToggleExpanded,
  onToggleSelected,
  onSelectCohort,
}: {
  readonly value: LegendCategoryValue;
  readonly position: number;
  readonly category: LegendCategory;
  readonly index: LegendCategoryIndex;
  readonly locale: string;
  readonly horizontal: number;
  readonly expanded: boolean;
  readonly selected: boolean;
  readonly selectionLimitReached: boolean;
  readonly compareOpen: boolean;
  readonly cohortValues: readonly CohortRowValue[] | null;
  readonly cohort: 'overall' | 'top1000' | 'top200';
  readonly onSelectCohort: (cohort: 'overall' | 'top1000' | 'top200') => void;
  readonly onToggleExpanded: (key: string) => void;
  readonly onToggleSelected: (key: string) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const { width, fontScale } = useWindowDimensions();
  const overallRate = index.attacks ? index.backgroundTriples / index.attacks : null;
  const showName =
    category !== 'equipmentPairs' && category !== 'petCombos' && category !== 'petAssignments';
  const compactMetrics =
    (width < 375 && (compareOpen || value.imageUrls.length > 2)) || fontScale > 1.4;
  const isPetCombo = category === 'petCombos';
  const visibleImageCount = isPetCombo ? value.imageUrls.length : fontScale > 1.4 ? 2 : 3;
  const petImageSize = fontScale > 1.4 ? 28 : width < 375 ? 32 : 36;
  return (
    <Surface
      radius={ckRadius.tile}
      style={{ padding: 12, gap: 10, marginHorizontal: horizontal }}
      testID={`legend-item-${category}-${value.key}`}
    >
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
        <Pressable
          testID={`legend-item-toggle-${category}-${value.key}`}
          accessibilityRole="button"
          accessibilityLabel={value.name}
          accessibilityState={{ expanded }}
          onPress={() => onToggleExpanded(value.key)}
          style={({ pressed }) => [styles.rankingRow, { flex: 1 }, pressed && { opacity: 0.72 }]}
        >
          <CKText role="labelLarge" style={styles.rankNumber}>
            #{position + 1}
          </CKText>
          <View style={styles.rankingImages} testID={`legend-artwork-${value.key}`}>
            {value.imageUrls.slice(0, visibleImageCount).map((imageUrl, imageIndex) => (
              <MobileWebImage
                key={`${value.key}:${imageIndex}`}
                imageUrl={imageUrl}
                testID={`legend-artwork-image-${value.key}-${imageIndex}`}
                style={[
                  styles.rankingImage,
                  isPetCombo && { width: petImageSize, height: petImageSize },
                  imageIndex > 0 &&
                    (isPetCombo
                      ? { marginLeft: -Math.round(petImageSize / 2) }
                      : styles.rankingImageOverlap),
                ]}
              />
            ))}
            {!isPetCombo && value.imageUrls.length > visibleImageCount ? (
              <CKText role="bodySmall">+{value.imageUrls.length - visibleImageCount}</CKText>
            ) : null}
          </View>
          <View style={styles.rankingCopy} testID={`legend-ranking-copy-${value.key}`}>
            {showName ? (
              <CKText role="rowTitle" numberOfLines={2}>
                {value.name}
              </CKText>
            ) : null}
            <View
              testID={`legend-metrics-${value.key}`}
              style={{
                flexDirection: compactMetrics ? 'column' : 'row',
                flexWrap: compactMetrics ? 'nowrap' : 'wrap',
                alignItems: 'flex-start',
                gap: compactMetrics ? 2 : 8,
                minWidth: 0,
              }}
            >
              <View
                accessible
                accessibilityRole="text"
                accessibilityLabel={`${t('statsThreeStarRate')}: ${value.uses ? percent(value.triples / value.uses) : '—'}`}
                testID={`legend-triple-rate-${value.key}`}
                style={{
                  flexDirection: compactMetrics ? 'column' : 'row',
                  alignItems: 'flex-start',
                  gap: compactMetrics ? 0 : 3,
                }}
              >
                <View
                  accessibilityElementsHidden
                  importantForAccessibility="no-hide-descendants"
                  style={{ flexDirection: 'row', alignItems: 'center', gap: 1 }}
                >
                  {[0, 1, 2].map((star) => (
                    <MobileWebImage
                      key={star}
                      imageUrl={ImageAssets.attackStar}
                      style={{ width: 14, height: 14 }}
                    />
                  ))}
                </View>
                <CKText role="bodySmall">
                  {value.uses ? percent(value.triples / value.uses) : '—'}
                </CKText>
              </View>
              {compactMetrics ? (
                <View
                  accessible
                  accessibilityRole="text"
                  accessibilityLabel={`${t('warAttacksTitle')}: ${compact(value.uses, locale)}`}
                  style={{ flexDirection: 'row', alignItems: 'center', gap: 3 }}
                >
                  <MobileWebImage
                    imageUrl={ImageAssets.attacks}
                    accessibilityElementsHidden
                    importantForAccessibility="no"
                    style={{ width: 14, height: 14 }}
                    testID={`legend-attack-icon-${value.key}`}
                  />
                  <CKText role="bodySmall">{compact(value.uses, locale)}</CKText>
                </View>
              ) : (
                <CKText role="bodySmall" muted>
                  {t('warAttacksTitle')} {compact(value.uses, locale)}
                </CKText>
              )}
            </View>
          </View>
          <View
            testID={`legend-${expanded ? 'collapse' : 'expand'}-caret-${value.key}`}
            style={{ width: 18, height: 18, flexShrink: 0, alignItems: 'center', justifyContent: 'center' }}
          >
            {expanded ? (
              <ChevronUp color={theme.onSurfaceVariant} size={18} />
            ) : (
              <ChevronDown color={theme.onSurfaceVariant} size={18} />
            )}
          </View>
        </Pressable>
        {compareOpen ? (
          <Pressable
            accessibilityRole="checkbox"
            accessibilityLabel={value.name}
            accessibilityState={{ checked: selected, disabled: !selected && selectionLimitReached }}
            disabled={!selected && selectionLimitReached}
            onPress={() => onToggleSelected(value.key)}
            style={{
              width: 44,
              height: 44,
              borderRadius: 22,
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: selected
                ? colorWithAlpha(theme.primary, 0.16)
                : theme.surfaceContainerHighest,
            }}
          >
            {selected ? (
              <Check size={18} color={theme.primary} />
            ) : (
              <View
                style={{
                  width: 18,
                  height: 18,
                  borderRadius: 9,
                  borderColor: theme.onSurfaceVariant,
                  borderWidth: 1.5,
                }}
              />
            )}
          </Pressable>
        ) : null}
      </View>
      {expanded ? (
        <View style={{ gap: 12 }}>
          <CKText role="bodySmall" muted>
            {t('statsVsOverall')} {overallRate == null ? '—' : percent(overallRate)}{' '}
            {value.uses && overallRate != null
              ? `(${signedPoints(value.triples / value.uses - overallRate, locale)} ${t('statsPercentagePoints')})`
              : ''}
          </CKText>
          <LegendItemTrend index={index} value={value} />
        </View>
      ) : null}
      {cohortValues ? (
        <View style={{ flexDirection: 'row', gap: 6 }}>
          {cohortValues.map(({ key, label, index: cohortIndex, values: cohortItems }) => {
            const matching = cohortItems.get(value.key);
            const usage =
              matching != null && cohortIndex?.attacks ? matching / cohortIndex.attacks : null;
            const active = cohort === key;
            return (
              <Pressable
                key={key}
                testID={`legend-cohort-${key}-${value.key}`}
                accessibilityRole="button"
                accessibilityLabel={`${label}: ${usage == null ? '—' : percent(usage)}`}
                accessibilityState={{ selected: active, disabled: cohortIndex === null }}
                disabled={cohortIndex === null}
                onPress={() => onSelectCohort(key)}
                style={{
                  flex: 1,
                  gap: 3,
                  minHeight: 44,
                  padding: 7,
                  borderRadius: ckRadius.control,
                  backgroundColor: active
                    ? colorWithAlpha(theme.primary, 0.12)
                    : colorWithAlpha(theme.onSurface, 0.05),
                }}
              >
                <CKText role="bodySmall" muted numberOfLines={1}>
                  {label}
                </CKText>
                <CKText role="rowTitle" style={active ? { color: theme.primary } : undefined}>
                  {usage == null ? '—' : percent(usage)}
                </CKText>
                <View
                  style={{
                    height: 3,
                    borderRadius: 2,
                    backgroundColor: colorWithAlpha(theme.onSurface, 0.1),
                  }}
                >
                  {usage != null ? (
                    <View
                      style={{
                        width: `${Math.min(100, usage * 100)}%`,
                        height: 3,
                        borderRadius: 2,
                        backgroundColor: active ? theme.primary : theme.secondary,
                      }}
                    />
                  ) : null}
                </View>
              </Pressable>
            );
          })}
        </View>
      ) : null}
    </Surface>
  );
});

function signedPoints(value: number, locale: string): string {
  return `${value >= 0 ? '+' : '−'}${(100 * Math.abs(value)).toLocaleString(toIntlLocale(locale), { maximumFractionDigits: 1, minimumFractionDigits: 1 })}`;
}

function LegendItemTrend({
  index,
  value,
}: {
  readonly index: LegendCategoryIndex;
  readonly value: LegendCategoryValue;
}) {
  const { t } = useI18n();
  return (
    <AnalyticsLineChart
      title={`${value.name} · ${t('statsDailyTrend')}`}
      series={[
        {
          key: 'usage',
          label: t('statsUsage'),
          color: '#E8A524',
          points: index.days.map((day) => {
            const entry = day.entries.get(value.key);
            return {
              day: day.day,
              weight: day.attacks,
              value: day.attacks ? (100 * (entry?.uses ?? 0)) / day.attacks : null,
            };
          }),
        },
        {
          key: 'hitrate',
          label: t('statsThreeStarRate'),
          color: '#85BCEB',
          points: index.days.map((day) => {
            const entry = day.entries.get(value.key);
            return {
              day: day.day,
              weight: entry?.uses ?? 0,
              value: entry?.uses ? (100 * entry.triples) / entry.uses : null,
            };
          }),
        },
      ]}
      percent
    />
  );
}

const legendCatalogCache = new WeakMap<
  object,
  Map<number, { fallback: string; raw: Record<string, unknown> }>
>();

function indexedLegendCatalog(root: object) {
  const cached = legendCatalogCache.get(root);
  if (cached) return cached;
  const catalog = new Map<number, { fallback: string; raw: Record<string, unknown> }>();
  for (const group of Object.values(root)) {
    if (!isRecord(group)) continue;
    for (const [fallback, candidate] of Object.entries(group)) {
      if (!isRecord(candidate)) continue;
      const id = Number(candidate._id);
      if (Number.isFinite(id) && !catalog.has(id)) catalog.set(id, { fallback, raw: candidate });
    }
  }
  legendCatalogCache.set(root, catalog);
  return catalog;
}

function legendItemPresentation(
  type: 'troop' | 'spell' | 'siege' | 'hero' | 'pet' | 'equipment',
  id: number,
  locale: string,
) {
  const root =
    type === 'hero'
      ? gameDataState.heroesData
      : type === 'pet'
        ? gameDataState.petsData
        : type === 'equipment'
          ? gameDataState.gearsData
          : type === 'spell'
            ? gameDataState.spellsData
            : gameDataState.troopsData;
  const recordValue = indexedLegendCatalog(root).get(id);
  const raw = recordValue?.raw;
  const fallback = recordValue?.fallback ?? `#${id}`;
  const name = localizedNameForItemOrFallback(
    raw,
    { languageCode: locale.split('_')[0]! },
    fallback,
  );
  return {
    name,
    imageUrl:
      type === 'hero'
        ? ImageAssets.getHeroImage(name)
        : type === 'pet'
          ? ImageAssets.getPetImage(name)
          : type === 'equipment'
            ? ImageAssets.getGearImage(name)
            : type === 'spell'
              ? ImageAssets.getSpellImage(name)
              : type === 'siege'
                ? ImageAssets.getSiegeMachineImage(name)
                : ImageAssets.getTroopImage(name),
  };
}

function legendCohortLabel(cohort: StatsLegendCohortValue, t: Translate) {
  return cohort === StatsLegendCohort.legend
    ? t('legendsTitle')
    : t('rankingsTopCount', {
        count:
          cohort === StatsLegendCohort.top100
            ? 100
            : cohort === StatsLegendCohort.top200
              ? 200
              : 1000,
      });
}

function preferredLegendCohorts(): readonly StatsLegendCohortValue[] {
  return [StatsLegendCohort.legend, StatsLegendCohort.top1000, StatsLegendCohort.top200];
}

function OverviewMetrics({
  metrics,
  wars,
  missed,
}: {
  readonly metrics: StatsMetrics;
  readonly wars?: number;
  readonly missed?: number;
}) {
  const { t, locale } = useI18n();
  const { fontScale } = useWindowDimensions();
  return (
    <View
      testID="stats-overview-metrics"
      style={{ flexDirection: 'row', flexWrap: 'wrap', rowGap: 18 }}
    >
      {[
        { label: t('statsThreeStarRate'), value: percent(metrics.threeStarRate), primary: true },
        { label: t('warAttacksTitle'), value: formatCompactNumber(metrics.sampleSize, locale) },
        { label: t('statsAverageStars'), value: metrics.averageStars.toFixed(2) },
        { label: t('statsAverageDestruction'), value: percent(metrics.averageDestruction) },
        ...(wars == null
          ? []
          : [{ label: t('warStatsWars'), value: formatCompactNumber(wars, locale) }]),
        ...(missed == null
          ? []
          : [{ label: t('statsMissedAttacks'), value: formatCompactNumber(missed, locale) }]),
      ].map(({ label, value, primary }) => (
        <View
          key={label}
          accessible
          accessibilityLabel={`${label}: ${value}`}
          style={{ width: fontScale > 1.3 ? '100%' : '50%', gap: 4, paddingEnd: 12 }}
        >
          <CKText
            role="titleMedium"
            style={{ fontVariant: ['tabular-nums'], ...(primary ? { color: '#E8A524' } : {}) }}
          >
            {value}
          </CKText>
          <CKText role="bodySmall" muted>
            {label}
          </CKText>
        </View>
      ))}
    </View>
  );
}

function starSeries(daily: readonly StatsDailyPoint[], t: Translate) {
  return [
    {
      key: 'zero',
      label: t('warStarsZero'),
      color: '#8C929C',
      points: daily.map((point) => ({
        day: point.date,
        weight: point.sampleSize,
        value: point.sampleSize ? normalizePercent(point.zeroStarRate) : null,
      })),
    },
    {
      key: 'one',
      label: t('warStarsOne'),
      color: '#85BCEB',
      points: daily.map((point) => ({
        day: point.date,
        weight: point.sampleSize,
        value: point.sampleSize ? normalizePercent(point.oneStarRate) : null,
      })),
    },
    {
      key: 'two',
      label: t('warStarsTwo'),
      color: '#A799EF',
      points: daily.map((point) => ({
        day: point.date,
        weight: point.sampleSize,
        value: point.sampleSize ? normalizePercent(point.twoStarRate) : null,
      })),
    },
    {
      key: 'three',
      label: t('warStarsThree'),
      color: '#E8A524',
      points: daily.map((point) => ({
        day: point.date,
        weight: point.sampleSize,
        value: point.sampleSize ? normalizePercent(point.threeStarRate) : null,
      })),
    },
  ];
}

function RankedOverview({ data }: { readonly data: StatsLegendResponse }) {
  const { t } = useI18n();
  const metrics = legendMetrics(data);
  return (
    <Section>
      <LeagueStatsPicker />
      <StatsChartFrame
        title={t('statsRanked')}
        showTitle={false}
        copyPlacement="footer"
        testID="ranked-overview-copy"
      >
        <View style={{ gap: 20 }}>
          <OverviewMetrics metrics={metrics} />
          <AnalyticsLineChart
            title={t('statsStarRates')}
            showTitle={false}
            series={starSeries(metrics.daily, t)}
            percent
            exportable={false}
          />
        </View>
      </StatsChartFrame>
      <AnalyticsLineChart
        title={t('warAttacksTitle')}
        series={[
          {
            key: 'attacks',
            label: t('warAttacksTitle'),
            points: metrics.daily.map((point) => ({ day: point.date, value: point.sampleSize })),
          },
        ]}
        includeZero
      />
    </Section>
  );
}

function WarOverview({ data }: { readonly data: StatsPerformanceResponse }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [expandedTownHall, setExpandedTownHall] = useState<number | null>(null);
  const summaries = data.warSummaries;
  const totalWars = summaries.reduce((sum, item) => sum + item.wars, 0);
  const missedAttacks = summaries.reduce((sum, item) => sum + (item.missedAttacks ?? 0), 0);
  const townHalls = [
    ...new Set([
      ...data.warHitRates.map((item) => item.townHall),
      ...data.comparisons
        .filter((entry) => entry.metrics.available)
        .flatMap((entry) => {
          const matched = /^TH(\d+)$/u.exec(entry.key);
          return matched ? [Number(matched[1])] : [];
        }),
    ]),
  ].sort((a, b) => b - a);
  const sizes = [...new Map(data.warSizes.map((item) => [item.warSize, item.warSize])).keys()]
    .filter((size): size is number => size != null)
    .map((size) => ({
      size,
      wars: data.warSizes
        .filter((item) => item.warSize === size)
        .reduce((sum, item) => sum + item.wars, 0),
    }))
    .sort((a, b) => b.wars - a.wars);
  return (
    <Section>
      <StatsChartFrame
        title={t('warStatsWars')}
        showTitle={false}
        copyPlacement="footer"
        testID="war-overview-copy"
      >
        <View style={{ gap: 20 }}>
          <OverviewMetrics metrics={data.metrics} wars={totalWars} missed={missedAttacks} />
          {data.metrics.daily.length ? (
            <AnalyticsLineChart
              title={t('statsStarRates')}
              showTitle={false}
              series={starSeries(data.metrics.daily, t)}
              percent
              exportable={false}
            />
          ) : null}
        </View>
      </StatsChartFrame>
      {summaries.length ? (
        <AnalyticsLineChart
          title={t('statsWarsOverTime')}
          series={[
            {
              key: 'wars',
              label: t('warStatsWars'),
              points: summaries.map((item) => ({ day: item.period, value: item.wars })),
            },
          ]}
          includeZero
        />
      ) : null}
      {sizes.length ? (
        <StatsChartFrame title={t('statsWarSizes')} testID="war-sizes-chart">
          <View style={{ gap: 12 }}>
            {sizes.map(({ size, wars }) => (
              <View key={size} style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
                <CKText role="rowTitle" style={{ width: 52 }}>
                  {size}v{size}
                </CKText>
                <View
                  style={{
                    flex: 1,
                    height: 9,
                    borderRadius: 9,
                    backgroundColor: theme.surfaceContainerHighest,
                  }}
                >
                  <View
                    style={{
                      width: `${Math.max(1, (100 * wars) / Math.max(totalWars, 1))}%`,
                      height: 9,
                      borderRadius: 9,
                      backgroundColor: theme.secondary,
                    }}
                  />
                </View>
                <CKText role="bodySmall">{formatCompactNumber(wars, locale)}</CKText>
              </View>
            ))}
          </View>
        </StatsChartFrame>
      ) : null}
      <SectionTitle>{t('statsHitratesByTownHall')}</SectionTitle>
      {townHalls.map((townHall) => {
        const rows = data.warHitRates.filter((row) => row.townHall === townHall);
        const comparison = data.comparisons.find((entry) => entry.key === `TH${townHall}`);
        const attacks = rows.length
          ? rows.reduce((sum, row) => sum + row.attacks, 0)
          : (comparison?.metrics.sampleSize ?? 0);
        const triples = rows.reduce(
          (sum, row) => sum + (row.stars.find((star) => star.stars === 3)?.count ?? 0),
          0,
        );
        const tripleRate = rows.length
          ? attacks
            ? triples / attacks
            : 0
          : (comparison?.metrics.threeStarRate ?? 0);
        const averageStars =
          rows.length && attacks
            ? rows.reduce((sum, row) => sum + row.averageStars * row.attacks, 0) / attacks
            : (comparison?.metrics.averageStars ?? 0);
        const averageDestruction =
          rows.length && attacks
            ? rows.reduce((sum, row) => sum + row.averageDestruction * row.attacks, 0) / attacks
            : (comparison?.metrics.averageDestruction ?? 0);
        const expanded = expandedTownHall === townHall;
        const daily = rows.map(
          (row) =>
            new StatsDailyPoint(
              row.period,
              row.attacks,
              row.averageStars,
              row.averageDestruction,
              ...([0, 1, 2, 3].map((stars) =>
                row.attacks
                  ? (row.stars.find((item) => item.stars === stars)?.count ?? 0) / row.attacks
                  : 0,
              ) as [number, number, number, number]),
            ),
        );
        return (
          <Surface key={townHall} radius={ckRadius.tile} style={{ padding: 16, gap: 12 }}>
            <StatsChartFrame
              title={`${t('statsHitratesByTownHall')} · TH${townHall}`}
              showTitle={false}
              copyEnabled={expanded}
              copyPlacement="footer"
              testID={`townhall-${townHall}-share`}
              exportContent={
                <View style={{ gap: 16 }}>
                  <MobileWebImage
                    imageUrl={ImageAssets.townHall(townHall)}
                    style={{ width: 54, height: 54, alignSelf: 'center' }}
                    contentFit="contain"
                  />
                  <View style={{ flexDirection: 'row', flexWrap: 'wrap', rowGap: 16 }}>
                    {[
                      { label: t('warAttacksTitle'), value: formatCompactNumber(attacks, locale) },
                      { label: t('statsThreeStarRate'), value: percent(tripleRate) },
                      { label: t('statsAverageStars'), value: averageStars.toFixed(2) },
                      { label: t('statsAverageDestruction'), value: percent(averageDestruction) },
                    ].map(({ label, value }) => (
                      <View key={label} style={{ width: '50%', alignItems: 'center', gap: 4 }}>
                        <CKText role="bodySmall" muted>
                          {label}
                        </CKText>
                        <CKText role="titleSmall">{value}</CKText>
                      </View>
                    ))}
                  </View>
                  {daily.length ? (
                    <AnalyticsLineChart
                      title={t('statsStarRates')}
                      showTitle={false}
                      series={starSeries(daily, t)}
                      percent
                      exportable={false}
                    />
                  ) : null}
                </View>
              }
            >
              <Pressable
                accessibilityRole="button"
                accessibilityState={{ expanded }}
                onPress={() => setExpandedTownHall(expanded ? null : townHall)}
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  gap: 10,
                  minHeight: 44,
                }}
              >
                <MobileWebImage
                  imageUrl={ImageAssets.townHall(townHall)}
                  style={{ width: 42, height: 42 }}
                  contentFit="contain"
                />
                <View style={{ flex: 1 }}>
                  <CKText role="rowTitle">TH{townHall}</CKText>
                  <CKText role="bodySmall" muted>
                    {formatCompactNumber(attacks, locale)} {t('warAttacksTitle')}
                  </CKText>
                </View>
                <CKText role="titleSmall" style={{ color: '#E8A524' }}>
                  {percent(tripleRate)}
                </CKText>
                <View
                  testID={`townhall-${townHall}-${expanded ? 'collapse' : 'expand'}-caret`}
                  style={{
                    width: 20,
                    height: 20,
                    flexShrink: 0,
                    justifyContent: 'center',
                    alignItems: 'center',
                  }}
                >
                  {expanded ? (
                    <ChevronUp color={theme.onSurfaceVariant} size={20} />
                  ) : (
                    <ChevronDown color={theme.onSurfaceVariant} size={20} />
                  )}
                </View>
              </Pressable>
              {expanded ? (
                <View style={{ gap: 12 }}>
                  <View style={{ flexDirection: 'row', gap: 20 }}>
                    <View>
                      <CKText role="bodySmall" muted>
                        {t('statsAverageStars')}
                      </CKText>
                      <CKText role="rowTitle">{averageStars.toFixed(2)}</CKText>
                    </View>
                    <View>
                      <CKText role="bodySmall" muted>
                        {t('statsAverageDestruction')}
                      </CKText>
                      <CKText role="rowTitle">{percent(averageDestruction)}</CKText>
                    </View>
                  </View>
                  {daily.length ? (
                    <AnalyticsLineChart
                      title={t('statsStarRates')}
                      showTitle={false}
                      series={starSeries(daily, t)}
                      percent
                      exportable={false}
                    />
                  ) : null}
                </View>
              ) : null}
            </StatsChartFrame>
          </Surface>
        );
      })}
    </Section>
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
  'use no memo';
  return section === StatsSection.items ? (
    <LegendFilters provider={provider} onClose={onClose} />
  ) : (
    <BattleFiltersCore section={section} provider={provider} onClose={onClose} />
  );
}
function BattleFiltersCore({
  section,
  provider,
  onClose,
}: {
  section: StatsSectionValue;
  provider: StatsProvider;
  onClose: () => void;
}) {
  'use no memo';
  const { t, locale } = useI18n();
  const cwlLeagues = useLocalizedCwlLeagues(t, locale);
  const theme = useCKTheme();
  const initialTh =
    section === StatsSection.ranked
      ? provider.rankedTownHall
      : section === StatsSection.armies
        ? provider.armiesTownHall
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
        : provider.cwlLeagueId;
  const [league, setLeague] = useState<number | undefined>(initialLeague);
  const [minimum, setMinimum] = useState(provider.armiesMinimumSample);
  const [armyCohort, setArmyCohort] = useState(provider.legendCohort);
  const [sortBy, setSortBy] = useState(provider.armiesSortBy);
  const [include, setInclude] = useState<readonly StatsItemQuantityFilter[]>(
    provider.armiesInclude,
  );
  const [exclude, setExclude] = useState(provider.armiesExclude.join(', '));
  const [seasons, setSeasons] = useState(provider.cwlSeasons.join(', '));
  const initialDates = section === StatsSection.cwl ? provider.cwlDates : provider.dates;
  const [start, setStart] = useState(StatsDateFilter.formatDate(initialDates.start));
  const [end, setEnd] = useState(StatsDateFilter.formatDate(initialDates.end));
  const [dateError, setDateError] = useState<string>();
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
      provider.updateRankedFilters({ townHall: townHall ?? 18, leagueTier: league ?? 105000033 });
    else if (section === StatsSection.armies) {
      provider.updateLegendCohort(armyCohort);
      provider.updateArmiesFilters({
        townHall: townHall ?? null,
        leagueTier: league ?? null,
        minimumSample: Math.max(1, minimum),
        sortBy,
        include,
        exclude: exclude
          .split(',')
          .map((value) => value.trim())
          .filter(isArmyItemIdentity),
      });
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
  const recentDays = (days: number) => {
    const today = new Date();
    const rangeEnd = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const rangeStart = new Date(rangeEnd);
    rangeStart.setDate(rangeStart.getDate() - days + 1);
    setStart(StatsDateFilter.formatDate(rangeStart));
    setEnd(StatsDateFilter.formatDate(rangeEnd));
    setDateError(undefined);
  };
  const lastCompletedMonth = () => {
    const today = new Date();
    setStart(StatsDateFilter.formatDate(new Date(today.getFullYear(), today.getMonth() - 1, 1)));
    setEnd(StatsDateFilter.formatDate(new Date(today.getFullYear(), today.getMonth(), 0)));
    setDateError(undefined);
  };
  const selectedDays = (() => {
    const parsedStart = parseLocalDate(start);
    const parsedEnd = parseLocalDate(end);
    if (!parsedStart || !parsedEnd) return null;
    const today = new Date();
    if (StatsDateFilter.formatDate(parsedEnd) !== StatsDateFilter.formatDate(today)) return null;
    return new StatsDateFilter(parsedStart, parsedEnd).inclusiveDays;
  })();
  const todayForMonth = new Date();
  const lastMonthSelected =
    start ===
      StatsDateFilter.formatDate(
        new Date(todayForMonth.getFullYear(), todayForMonth.getMonth() - 1, 1),
      ) &&
    end ===
      StatsDateFilter.formatDate(
        new Date(todayForMonth.getFullYear(), todayForMonth.getMonth(), 0),
      );
  const reset = () => {
    setTownHall(section === StatsSection.ranked ? 18 : undefined);
    setOpponent(undefined);
    setEqual(true);
    setLeague(section === StatsSection.ranked ? 105000033 : undefined);
    setMinimum(100);
    setArmyCohort(StatsLegendCohort.legend);
    setSortBy('usage');
    setInclude([]);
    setExclude('');
    setSeasons('');
    if (section === StatsSection.cwl) lastCompletedMonth();
    else recentDays(30);
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
            <View style={styles.datePresetGroup}>
              <CKText role="rowTitle">{t('filtersQuickFilters')}</CKText>
              <View style={styles.datePresets}>
                {[7, 30, 60, 90].map((days) => (
                  <Pressable
                    key={days}
                    accessibilityRole="button"
                    accessibilityState={{ selected: selectedDays === days }}
                    onPress={() => recentDays(days)}
                    style={[
                      styles.datePreset,
                      {
                        backgroundColor:
                          selectedDays === days
                            ? colorWithAlpha(theme.primary, 0.18)
                            : colorWithAlpha(theme.onSurface, 0.08),
                      },
                    ]}
                  >
                    <CKText role="bodyMedium">{t('warStatsLastXDays', { number: days })}</CKText>
                  </Pressable>
                ))}
                {section === StatsSection.cwl ? (
                  <Pressable
                    accessibilityRole="button"
                    onPress={lastCompletedMonth}
                    accessibilityState={{ selected: lastMonthSelected }}
                    style={[
                      styles.datePreset,
                      {
                        backgroundColor: lastMonthSelected
                          ? colorWithAlpha(theme.primary, 0.18)
                          : colorWithAlpha(theme.onSurface, 0.08),
                      },
                    ]}
                  >
                    <CKText role="bodyMedium">{t('presetSuggestionLastMonth')}</CKText>
                  </Pressable>
                ) : null}
              </View>
              <CKText role="bodySmall" muted>{`${start} – ${end}`}</CKText>
            </View>
            {dateError ? (
              <CKText role="bodySmall" style={{ color: theme.error }}>
                {dateError}
              </CKText>
            ) : null}
            {section !== StatsSection.armies ? (
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
            ) : null}
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
            {section === StatsSection.ranked || section === StatsSection.cwl ? (
              <ChoiceField
                label={section === StatsSection.cwl ? t('statsCwlLeague') : t('statsLeagueTier')}
                value={league}
                values={[
                  ...(section === StatsSection.ranked ? [] : [undefined]),
                  ...(section === StatsSection.cwl
                    ? [...cwlLeagues.keys()].sort((left, right) => left - right)
                    : Array.from({ length: 36 }, (_, i) => 105000036 - i)),
                ]}
                format={(value) =>
                  value == null
                    ? section === StatsSection.cwl
                      ? t('statsAllCwlLeagues')
                      : t('generalAll')
                    : section === StatsSection.cwl
                      ? (cwlLeagues.get(value) ?? `${value}`)
                      : leagueTierSummary(value, t, locale)
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
                  label={t('legendsTitle')}
                  value={armyCohort}
                  values={preferredLegendCohorts()}
                  format={(value) => legendCohortLabel(value, t)}
                  onChange={setArmyCohort}
                />
                <ChoiceField
                  label={t('statsSortBy')}
                  value={sortBy}
                  values={['usage', 'tripleRate', 'averageDuration', 'zeroStarRate']}
                  format={(value) =>
                    value === 'usage'
                      ? t('statsUsage')
                      : value === 'tripleRate'
                        ? t('statsThreeStarRate')
                        : value === 'averageDuration'
                          ? t('warAttacksDetailsDuration')
                          : t('warStarsZero')
                  }
                  onChange={setSortBy}
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
function LegendFilters({ provider, onClose }: { provider: StatsProvider; onClose: () => void }) {
  'use no memo';
  const { t } = useI18n();
  const theme = useCKTheme();
  const [cohort, setCohort] = useState(provider.legendCohort);
  const [start, setStart] = useState(StatsDateFilter.formatDate(provider.dates.start));
  const [end, setEnd] = useState(StatsDateFilter.formatDate(provider.dates.end));
  const [dateError, setDateError] = useState<string>();
  const [showDates, setShowDates] = useState(false);
  const apply = () => {
    const parsedStart = parseLocalDate(start);
    const parsedEnd = parseLocalDate(end);
    if (!parsedStart || !parsedEnd) {
      setDateError(t('statsDateRangeHint'));
      return;
    }
    const dates = new StatsDateFilter(parsedStart, parsedEnd);
    if (parsedEnd < parsedStart || dates.inclusiveDays > 35) {
      setDateError(t('statsDateRangeTooLong'));
      return;
    }
    provider.updateLegendCohort(cohort);
    onClose();
    void provider.setDates(parsedStart, parsedEnd);
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
              label={t('legendsTitle')}
              value={cohort}
              values={preferredLegendCohorts()}
              format={(value) => legendCohortLabel(value, t)}
              onChange={setCohort}
            />
          </ScrollView>
          <View style={styles.actions}>
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
function Section({ children }: { children: ReactNode }) {
  return <View style={styles.section}>{children}</View>;
}
function SectionTitle({ children }: { children: ReactNode }) {
  return <CKText role="titleMedium">{children}</CKText>;
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
function StatsSkeleton() {
  const { t } = useI18n();
  const theme = useCKTheme();
  const loadingLabel = t('generalLoading');
  return (
    <View
      style={[styles.section, { minHeight: 96, alignItems: 'center', justifyContent: 'center' }]}
      accessibilityLabel={loadingLabel}
    >
      <ActivityIndicator color={theme.primary} />
      <CKText role="bodySmall" muted>
        {loadingLabel}
      </CKText>
    </View>
  );
}
type Translate = ReturnType<typeof useI18n>['t'];
export function sectionLabel(section: StatsSectionValue, t: Translate): string {
  switch (section) {
    case StatsSection.players:
      return t('statsPlayers');
    case StatsSection.clans:
      return t('statsClans');
    case StatsSection.armies:
      return t('statsArmies');
    case StatsSection.items:
      return t('statsTroopStats');
    case StatsSection.war:
      return t('statsWar');
    case StatsSection.cwl:
      return t('statsCwl');
    case StatsSection.ranked:
      return t('statsRanked');
  }
}
export function sectionImage(section: StatsSectionValue): string {
  switch (section) {
    case StatsSection.ranked:
      return ImageAssets.legendLeagueOne;
    case StatsSection.armies:
      return ImageAssets.getTroopImage('Super Bowler');
    case StatsSection.items:
      return ImageAssets.getTroopImage('Archer');
    case StatsSection.war:
      return ImageAssets.war;
    case StatsSection.cwl:
      return ImageAssets.getWarLeagueImage('Champion League I');
    case StatsSection.players:
      return ImageAssets.townHall(18);
    case StatsSection.clans:
      return ImageAssets.clanCastle;
  }
}
export function sectionBackdrop(section: StatsSectionValue): string {
  if (section === StatsSection.war) return ImageAssets.warPageBackground;
  if (section === StatsSection.cwl) return ImageAssets.cwlPageBackground;
  if (section === StatsSection.armies || section === StatsSection.items)
    return ImageAssets.playerWarStatsPageBackground;
  return ImageAssets.homeBaseBackground;
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
function leagueTierSummary(id: number | null | undefined, t: Translate, locale: string): string {
  if (id == null) return '?';
  const leagues = gameDataState.playerLeagueData.leagues;
  if (isRecord(leagues)) {
    for (const value of Object.values(leagues)) {
      if (!isRecord(value) || Number(value._id ?? value.id) !== id) continue;
      const name = typeof value.name === 'string' ? value.name : `${t('statsLeagueTier')} ${id}`;
      return localizedNameForItemOrFallback(
        value,
        { languageCode: locale.split(/[-_]/, 1)[0] || 'en' },
        name,
      );
    }
  }
  if (id === 105000036) return 'Legend League 1';
  if (id === 105000035) return 'Legend League 2';
  if (id === 105000034) return 'Legend League 3';
  return id === 105000033 ? 'Electro League 33' : `${t('statsLeagueTier')} ${id - 105000000}`;
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
function statsErrorBody(section: StatsSectionValue, error: unknown): string {
  if (section === StatsSection.cwl && isRecord(error) && isRecord(error.body)) {
    if (error.body.code === 'cwl_archive_incomplete' && typeof error.body.message === 'string') {
      return error.body.message;
    }
  }
  return String(error);
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
const styles = StyleSheet.create({
  fill: { flex: 1 },
  grow: { flex: 1, minWidth: 0 },
  datePresetGroup: { gap: 10 },
  datePresets: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  datePreset: {
    minHeight: 40,
    justifyContent: 'center',
    borderRadius: ckRadius.pill,
    paddingHorizontal: 14,
  },
  section: { gap: 12, paddingBottom: 12 },
  sectionFrame: { gap: 10 },
  state: { marginVertical: 24 },
  card: { padding: 16, gap: 12 },
  summary: { padding: 16, flexDirection: 'row', alignItems: 'center', gap: 12 },
  bars: { height: 190, flexDirection: 'row', alignItems: 'flex-end', gap: 4, paddingTop: 16 },
  barColumn: { flex: 1, height: 165, justifyContent: 'flex-end', alignItems: 'center', gap: 6 },
  bar: { width: '70%', maxWidth: 14, borderTopLeftRadius: 5, borderTopRightRadius: 5 },
  categoryTrend: { gap: 4 },
  trendLegend: { flexDirection: 'row', flexWrap: 'wrap', gap: 16 },
  rankingRows: { gap: 8 },
  rankingRow: {
    minHeight: 58,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 4,
  },
  rankNumber: { width: 26, textAlign: 'center' },
  rankingImages: { minWidth: 36, flexDirection: 'row', alignItems: 'center' },
  rankingImage: { width: 36, height: 36, borderRadius: 9 },
  rankingImageOverlap: { marginLeft: -16 },
  rankingCopy: { flex: 1, minWidth: 0, gap: 3 },
  rankingMetrics: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  cardExtra: { gap: 8 },
  armyFilterPanel: { padding: 14, gap: 14 },
  armyFilterGroup: { gap: 6 },
  armyFilterOptions: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  armyFilterOption: {
    minHeight: 36,
    justifyContent: 'center',
    paddingHorizontal: 10,
    borderRadius: 999,
    borderWidth: StyleSheet.hairlineWidth,
  },
  armyResult: { padding: 14, gap: 10 },
  armyResultHeader: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  armyResultMetrics: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  armyUsageHeader: { flexDirection: 'row', justifyContent: 'space-between' },
  armyUsageRows: { gap: 12 },
  armyUsageRow: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  armyUsageRate: { minWidth: 70, textAlign: 'right', fontVariant: ['tabular-nums'] },
  armyUsageTrack: { height: 7, borderRadius: 999, overflow: 'hidden', marginTop: 4 },
  armyUsageFill: { height: '100%', borderRadius: 999 },
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
  scatterChart: {
    width: '100%',
    maxWidth: 600,
    aspectRatio: 320 / 210,
    alignSelf: 'center',
    position: 'relative',
  },
  trendChart: { height: 150, position: 'relative' },
  chartHitTarget: {
    position: 'absolute',
    width: 28,
    height: 28,
    marginLeft: -14,
    marginTop: -14,
    borderRadius: 14,
  },
  metricPill: { minWidth: 105, padding: 10, borderRadius: 12, backgroundColor: '#80808018' },
  progressRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  progressLabel: { width: 34 },
  progressTrack: { height: 9, flex: 1, borderRadius: 999, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: 999 },
  context: { minHeight: 72, flexDirection: 'row', alignItems: 'center', gap: 12 },
  contextButton: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  dayNavigation: {
    minHeight: 50,
    paddingHorizontal: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  dayNavigationButton: {
    minWidth: 44,
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  disabled: { opacity: 0.35 },
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
