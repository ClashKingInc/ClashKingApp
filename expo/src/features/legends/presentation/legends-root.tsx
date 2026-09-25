import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Pressable,
  Platform,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
  type GestureResponderEvent,
} from 'react-native';
import { ArrowLeft, ChevronRight, Upload } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  DateNavigator,
  DestinationPicker,
  EmptyState,
  ErrorState,
  LoadingIndicator,
  MobileWebImage,
  PillSurface,
  ResponsiveGrid,
  statColors,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
  useCKThemeMode,
} from '../../../ui';
import { ImageAssets } from '../../../core/assets/image-assets';
import type { ContractApiService } from '../../../core/api/contract-api';
import { useAppRuntime } from '../../../core/app/runtime-context';
import {
  PlayerLegendBattle,
  PlayerLegendBattlelog,
  PlayerLegendDaySummary,
  PlayerLegendHistoryEntry,
  PlayerLegendLeagueData,
  currentLegendDay,
  type Player,
} from '../../player/models';
import { LegendsShareModal, legendsShareSummary } from './legends-share';
import { legendDayOffset } from './legend-day';
import { LegendChart } from './legend-chart';
import { popularLegendItems } from './legend-army';
import { LegendBattlePanel } from './legend-battle-panel';
import { ArmyDetailModal } from '../../stats/presentation/army-detail-modal';

export function LegendsRoot({
  player,
  onBack,
  onOpenOpponent,
}: {
  readonly player: Player;
  readonly onBack: () => void;
  readonly onOpenOpponent?: (tag: string) => void;
}) {
  const runtime = useAppRuntime();
  const [selectedDay, setSelectedDay] = useState(() => currentLegendDay());
  const baseline = useMemo(
    () => legendLeagueDataFromPlayer(player, selectedDay),
    [player, selectedDay],
  );
  const [data, setData] = useState<PlayerLegendLeagueData | null>(baseline);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [shareVisible, setShareVisible] = useState(false);
  const load = useCallback(
    async (force: boolean) => {
      if (force) setRefreshing(true);
      else setLoading(true);
      setError(null);
      try {
        setData(
          await runtime.players.loadLegendLeagueData(player.tag, force, selectedDay, baseline),
        );
      } catch (caught) {
        setError(caught instanceof Error ? caught.message : String(caught));
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [baseline, player.tag, runtime.players, selectedDay],
  );
  useEffect(() => {
    let current = true;
    void runtime.players
      .loadLegendLeagueData(player.tag, false, selectedDay, baseline)
      .then((value) => {
        if (current) setData(value);
      })
      .catch((caught) => {
        if (current) setError(caught instanceof Error ? caught.message : String(caught));
      })
      .finally(() => {
        if (current) setLoading(false);
      });
    return () => {
      current = false;
    };
  }, [baseline, player.tag, runtime.players, selectedDay]);

  return (
    <View style={styles.fill}>
      <LegendsScreen
        data={data}
        error={error}
        loading={loading}
        refreshing={refreshing}
        selectedDay={selectedDay}
        onBack={onBack}
        api={runtime.contractApi}
        onOpenOpponent={onOpenOpponent}
        onRefresh={() => load(true)}
        onSelectDay={(day) => {
          setLoading(true);
          setSelectedDay(day);
        }}
        onExport={() => setShareVisible(true)}
      />
      {data ? (
        <LegendsShareModal
          data={data}
          onClose={() => setShareVisible(false)}
          visible={shareVisible}
        />
      ) : null}
    </View>
  );
}

export function legendLeagueDataFromPlayer(player: Player, day: string) {
  const season = player.legendsBySeason?.getSpecificSeason(new Date(`${day}T00:00:00.000Z`));
  const storedDay = season?.days[day] ?? null;
  const startsAt = new Date(`${day}T05:10:00.000Z`);
  const currentDay = storedDay
    ? new PlayerLegendBattlelog(
        player.tag,
        day,
        startsAt,
        new Date(startsAt.getTime() + 86_400_000),
        startsAt.getTime() + 86_400_000 <= Date.now(),
        storedDay.trophiesGainedTotal,
        storedDay.trophiesLostTotal,
        storedDay.trophiesTotal,
        storedDay.attacks.map((trophies) => new PlayerLegendBattle(trophies, false)),
        storedDay.defenses.map((trophies) => new PlayerLegendBattle(trophies, false)),
      )
    : null;
  const recentDays = season
    ? Object.entries(season.days)
        .filter(([stored]) => stored <= day)
        .sort(([left], [right]) => left.localeCompare(right))
        .slice(-28)
        .map(
          ([stored, value]) =>
            new PlayerLegendDaySummary(
              stored,
              value.trophiesGainedTotal,
              value.trophiesLostTotal,
              value.trophiesTotal,
            ),
        )
    : [];
  const history = player.legendRanking.map(
    (entry) =>
      new PlayerLegendHistoryEntry(
        entry.season,
        null,
        'Legend League',
        entry.trophies,
        entry.attackWins,
        entry.defenseWins,
        entry.rank,
      ),
  );
  return new PlayerLegendLeagueData(
    player.tag,
    player.name,
    player.townHallLevel,
    player.trophies,
    player.bestTrophies,
    currentDay,
    history,
    day,
    null,
    null,
    recentDays,
  );
}

export function LegendsScreen({
  api,
  data,
  error,
  loading,
  refreshing,
  selectedDay,
  onBack,
  onRefresh,
  onSelectDay,
  onExport,
  onOpenOpponent,
}: {
  readonly api?: ContractApiService;
  readonly data: PlayerLegendLeagueData | null;
  readonly error: string | null;
  readonly loading: boolean;
  readonly refreshing: boolean;
  readonly selectedDay: string;
  readonly onBack: () => void;
  readonly onRefresh: () => Promise<void>;
  readonly onSelectDay: (day: string) => void;
  readonly onExport: () => void;
  readonly onOpenOpponent?: (tag: string) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const themeMode = useCKThemeMode();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const horizontal = Math.max(16, (width - 1120) / 2);
  const current = data?.currentDay;
  const [page, setPage] = useState('daily');
  const [selectedArmy, setSelectedArmy] = useState<string | null>(null);
  const headerFavorite = data ? popularLegendItems(data.seasonArmyShareCodes)[0] : undefined;
  const seasonRange = legendSeasonDateRange(
    data?.seasonStart ?? null,
    data?.seasonEnd ?? null,
    selectedDay,
  );
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.fill, { backgroundColor: theme.background }]}
    >
      <ScrollView
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={() => void onRefresh()} />
        }
        contentContainerStyle={{ paddingBottom: insets.bottom + 28 }}
      >
        <View testID="legends-hero" style={[styles.hero, { minHeight: 238 + insets.top }]}>
          <MobileWebImage
            imageUrl={ImageAssets.homeBaseBackground}
            style={StyleSheet.absoluteFill}
            contentFit="cover"
            contentPosition="center"
          />
          <View
            style={[
              StyleSheet.absoluteFill,
              styles.heroScrim,
              { backgroundColor: themeMode === 'dark' ? '#000000A8' : '#00000082' },
            ]}
          />
          <View
            style={[
              styles.heroContent,
              { paddingTop: insets.top + 56, paddingHorizontal: horizontal },
            ]}
          >
            <View
              testID="legends-hero-actions"
              style={[
                styles.heroActions,
                { top: insets.top + 4, left: horizontal, right: horizontal },
              ]}
            >
              <HeroAction
                label={materialBackLabel(locale)}
                onPress={onBack}
                icon={<ArrowLeft color="#FFF" />}
              />
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={t('generalExport')}
                disabled={!data}
                onPress={onExport}
                style={styles.exportButton}
              >
                <Upload color="#FFF" size={20} />
                <CKText role="labelLarge" style={styles.white}>
                  {t('generalExport')}
                </CKText>
              </Pressable>
            </View>
            <View style={styles.heroIdentity}>
              <MobileWebImage
                imageUrl={ImageAssets.townHall(data?.townHallLevel ?? 1)}
                style={styles.townHallIdentity}
              />
              <CKText numberOfLines={1} role="screenTitle" style={styles.white}>
                {data?.playerName ?? ''}
              </CKText>
              <CKText role="metadata" style={styles.whiteSoft}>
                {data?.playerTag}
              </CKText>
            </View>
            {data ? (
              <View style={styles.heroChips}>
                <HeroChip
                  label={t('rankedLeagueTrophies')}
                  value={(data.currentRank?.trophies ?? data.trophies).toLocaleString(
                    toIntlLocale(locale),
                  )}
                  imageUrl={ImageAssets.legendLeagueOne}
                />
                {data.currentRank ? (
                  <HeroChip
                    label={t('legendsGlobalRankTitle')}
                    value={`#${data.currentRank.globalRank.toLocaleString(toIntlLocale(locale))}`}
                    imageUrl={ImageAssets.trophies}
                  />
                ) : null}
                <HeroSeasonSummary
                  favorite={headerFavorite}
                  location={data.currentRank?.location ?? null}
                  stats={data.seasonStats}
                />
              </View>
            ) : null}
          </View>
        </View>
        <View style={[styles.content, { paddingHorizontal: horizontal }]}>
          <DestinationPicker
            selectedKey={page}
            onSelect={setPage}
            options={[
              { key: 'daily', label: t('statsByDay') },
              { key: 'season', label: t('filtersSeason') },
              { key: 'history', label: t('generalHistory') },
            ]}
          />
          {page === 'daily' && (
            <LegendDayNavigation
              day={selectedDay}
              onSelect={onSelectDay}
              today={currentLegendDay()}
              days={data?.recentDays ?? []}
              rank={data?.selectedDay === selectedDay ? data.historicalRank?.globalRank : undefined}
            />
          )}
          {loading && !data ? (
            <LoadingIndicator />
          ) : error ? (
            <ErrorState
              title={t('apiErrorServer')}
              actionLabel={t('sideRefresh')}
              onAction={() => void onRefresh()}
            />
          ) : data ? (
            <>
              {page === 'season' && (
                <LegendRecentSummary data={data} onOpenArmy={api ? setSelectedArmy : undefined} />
              )}

              {page === 'daily' &&
                (loading && data.selectedDay !== selectedDay ? (
                  <LoadingIndicator />
                ) : current ? (
                  <LegendBattlePanel
                    data={current}
                    onOpenOpponent={onOpenOpponent}
                    onOpenArmy={api ? setSelectedArmy : undefined}
                  />
                ) : (
                  <EmptyState
                    title={t('legendsNotInLeague')}
                    body={t('legendsNoDataToday')}
                    style={styles.currentDayEmptyState}
                  />
                ))}
              {page === 'history' && (
                <>
                  {data.history.length ? (
                    <ResponsiveGrid minItemWidth={430} maxColumns={2} gap={12}>
                      {data.history.map((season) => (
                        <LegendHistoryRow key={season.season} season={season} locale={locale} />
                      ))}
                    </ResponsiveGrid>
                  ) : (
                    <EmptyState
                      showSticker={false}
                      title={t('generalNoDataAvailable')}
                      style={styles.historyEmptyState}
                    />
                  )}
                </>
              )}
            </>
          ) : null}
        </View>
      </ScrollView>
      {api && selectedArmy ? (
        <ArmyDetailModal
          api={api}
          shareCode={selectedArmy}
          cohort="legend_i"
          start={seasonRange.start}
          end={seasonRange.end}
          visible
          onClose={() => setSelectedArmy(null)}
        />
      ) : null}
    </SafeAreaView>
  );
}

function LegendRecentSummary({
  data,
  onOpenArmy,
}: {
  readonly data: PlayerLegendLeagueData;
  readonly onOpenArmy?: (shareCode: string) => void;
}) {
  const { locale, t } = useI18n();
  const summary = legendsShareSummary(data);
  const [selectedContribution, setSelectedContribution] = useState<string | null>(null);
  const popular = popularLegendItems(data.seasonArmyShareCodes);
  const activeContribution = selectedContribution ?? summary.dailyContributions.at(-1)?.key ?? null;
  const detailDay = data.recentDays.find((entry) => entry.day === activeContribution);
  const seasonRange = legendSeasonDateRange(data.seasonStart, data.seasonEnd, data.selectedDay);
  const dateFormat = new Intl.DateTimeFormat(toIntlLocale(locale), { dateStyle: 'medium' });
  return (
    <View style={styles.seasonContent} testID="legend-recent-summary">
      <View style={styles.row}>
        <CKText role="sectionTitle" style={styles.grow}>
          {t('statsSeasonStats')}
        </CKText>
        <CKText muted role="metadata">
          {t('statsIndexDays', { index: data.recentDays.length })}
        </CKText>
      </View>
      {data.seasonStart && data.seasonEnd ? (
        <CKText muted role="metadata">
          {dateFormat.format(seasonRange.start)} – {dateFormat.format(seasonRange.end)}
        </CKText>
      ) : null}
      <Surface radius={ckRadius.tile} style={styles.recentSummary}>
        <LegendChart
          title={t('rankedLeagueTrophies')}
          points={data.recentDays.map((day) => ({
            day: day.day,
            value: day.closingTrophies ?? null,
          }))}
        />
        <LegendChart
          title={t('legendsGlobalRankTitle')}
          rank
          points={data.recentDays.map((day) => ({ day: day.day, value: day.globalRank ?? null }))}
        />
      </Surface>
      {summary.dailyContributions.length ? (
        <Surface radius={ckRadius.tile} style={styles.recentSummary}>
          <CKText role="titleMedium">{t('legendsTrophyGrid')}</CKText>
          <View>
            <ContributionCalendar
              days={summary.dailyContributions}
              selectedKey={activeContribution}
              onSelect={setSelectedContribution}
            />
          </View>
          <View style={styles.contributionDetail}>
            <CKText role="rowTitle">{detailDay?.day ?? t('generalDetails')}</CKText>
            {detailDay ? (
              <View style={styles.row}>
                <CKText muted role="metadata">
                  {detailDay.trophyChange > 0 ? '+' : ''}
                  {detailDay.trophyChange}
                </CKText>
                <CKText muted role="metadata">
                  {t('legendsGlobalRankTitle')} ·{' '}
                  {detailDay.globalRank ? `#${detailDay.globalRank.toLocaleString()}` : '—'}
                </CKText>
              </View>
            ) : null}
          </View>
        </Surface>
      ) : null}
      {data.recentDays.length ? <SeasonDayTable days={data.recentDays} /> : null}
      <Surface radius={ckRadius.tile} style={styles.recentSummary}>
        <CKText role="titleMedium">{t('legendsPopularArmyItems')}</CKText>
        {popular.length ? (
          <View style={styles.popularItems}>
            {popular.map((entry) => (
              <View
                key={entry.category}
                accessible
                accessibilityLabel={`${t(entry.category === 'Troop' ? 'gameTroops' : entry.category === 'Spell' ? 'gameSpells' : 'gameSiegeMachines')}: ${entry.item.name}`}
                style={styles.popularItem}
                testID={`legend-popular-${entry.category}`}
              >
                <MobileWebImage imageUrl={entry.item.imageUrl} style={styles.popularItemImage} />
              </View>
            ))}
          </View>
        ) : (
          <CKText muted role="body">
            {t('generalNoDataAvailable')}
          </CKText>
        )}
      </Surface>
      {data.comparisons.length ? <LegendPerformanceComparisons data={data} /> : null}
      {data.armyComparison ? (
        <LegendArmyPerformanceComparisons data={data} onOpenArmy={onOpenArmy} />
      ) : null}
    </View>
  );
}

function HeroSeasonSummary({
  favorite,
  location,
  stats,
}: {
  readonly favorite: ReturnType<typeof popularLegendItems>[number] | undefined;
  readonly location: NonNullable<PlayerLegendLeagueData['currentRank']>['location'];
  readonly stats: PlayerLegendLeagueData['seasonStats'];
}) {
  const { t } = useI18n();
  if (!location && !stats && !favorite) return null;
  const tripleRate = (triples: number, attacks: number) =>
    attacks > 0 ? `${((triples / attacks) * 100).toFixed(1)}%` : '—';
  return (
    <>
      <HeroChip
        imageUrl={
          location?.countryCode ? ImageAssets.flag(location.countryCode) : ImageAssets.planet
        }
        label={t('sideLocation')}
        value={location?.name ?? '—'}
      />
      <HeroChip
        imageUrl={ImageAssets.attackStar}
        label={t('legendsHitrate')}
        value={stats ? tripleRate(stats.attackTriples, stats.attacks) : '—'}
      />
      {favorite ? (
        <HeroChip
          imageUrl={favorite?.item.imageUrl ?? ImageAssets.defaultImage}
          label={favorite.item.name}
          value={t('legendsPopularTroop')}
        />
      ) : null}
    </>
  );
}

function HeroChip({
  imageUrl,
  label,
  value,
  detail,
}: {
  readonly imageUrl: string;
  readonly label: string;
  readonly value: string;
  readonly detail?: string;
}) {
  return (
    <PillSurface
      accessible
      accessibilityLabel={`${label}: ${value}${detail ? `, ${detail}` : ''}`}
      style={styles.heroChip}
    >
      <MobileWebImage imageUrl={imageUrl} style={styles.heroChipImage} />
      <View style={styles.heroChipText}>
        <CKText numberOfLines={1} role="labelLarge">
          {value}
        </CKText>
      </View>
      {detail ? (
        <CKText numberOfLines={1} role="metadata" style={styles.whiteSoft}>
          {detail}
        </CKText>
      ) : null}
    </PillSurface>
  );
}

function LegendPerformanceComparisons({ data }: { readonly data: PlayerLegendLeagueData }) {
  const { locale, t } = useI18n();
  const format = new Intl.NumberFormat(toIntlLocale(locale));
  const cohortLabel = (cohort: PlayerLegendLeagueData['comparisons'][number]['cohort']) =>
    cohort === 'top_200'
      ? t('rankingsTopCount', { count: format.format(200) })
      : cohort === 'top_1000'
        ? t('rankingsTopCount', { count: format.format(1000) })
        : t('statsLegendLeagueOne');
  return (
    <View style={styles.comparisons} testID="legend-performance-comparisons">
      <CKText role="titleMedium">{t('statsPerformance')}</CKText>
      <PerformanceComparisonPanel
        comparisons={data.comparisons}
        playerName={data.playerName}
        cohortLabel={cohortLabel}
      />
    </View>
  );
}

function LegendArmyPerformanceComparisons({
  data,
  onOpenArmy,
}: {
  readonly data: PlayerLegendLeagueData;
  readonly onOpenArmy?: (shareCode: string) => void;
}) {
  const { locale, t } = useI18n();
  const theme = useCKTheme();
  const comparison = data.armyComparison;
  if (!comparison) return null;
  const cues = popularLegendItems([comparison.shareCode]);
  const format = new Intl.NumberFormat(toIntlLocale(locale));
  const cohortLabel = (cohort: (typeof comparison.items)[number]['cohort']) =>
    cohort === 'top_200'
      ? t('rankingsTopCount', { count: format.format(200) })
      : cohort === 'top_1000'
        ? t('rankingsTopCount', { count: format.format(1000) })
        : t('statsLegendLeagueOne');
  return (
    <View style={styles.comparisons} testID="legend-army-performance-comparisons">
      <CKText muted role="metadata">
        {t('statsArmies')}
      </CKText>
      <Pressable
        accessibilityLabel={`${t('statsArmies')}: ${comparison.name ?? t('statsArmyFallback', { id: comparison.familyId })}`}
        accessibilityRole={onOpenArmy ? 'button' : undefined}
        disabled={!onOpenArmy}
        onPress={() => onOpenArmy?.(comparison.shareCode)}
        style={styles.armyComparisonIdentity}
      >
        <View style={styles.armyComparisonImages}>
          {cues.map((cue) => (
            <MobileWebImage
              key={cue.category}
              imageUrl={cue.item.imageUrl}
              style={styles.armyComparisonImage}
            />
          ))}
        </View>
        <CKText numberOfLines={1} role="titleMedium" style={styles.grow}>
          {comparison.name ?? t('statsArmyFallback', { id: comparison.familyId })}
        </CKText>
        {onOpenArmy ? <ChevronRight color={theme.onSurfaceVariant} size={20} /> : null}
      </Pressable>
      <PerformanceComparisonPanel
        comparisons={comparison.items}
        playerName={data.playerName}
        cohortLabel={cohortLabel}
      />
    </View>
  );
}

type LegendComparison = PlayerLegendLeagueData['comparisons'][number];

export function groupLegendComparisons(comparisons: readonly LegendComparison[]) {
  const groups = new Map<string, LegendComparison[]>();
  for (const comparison of comparisons.filter(hasComparisonSamples)) {
    const key = `${comparison.days}:${comparison.playerAttacks}:${comparison.playerTriples}`;
    groups.set(key, [...(groups.get(key) ?? []), comparison]);
  }
  return [...groups.values()];
}

function PerformanceComparisonPanel({
  comparisons,
  playerName,
  cohortLabel,
}: {
  readonly comparisons: readonly LegendComparison[];
  readonly playerName: string;
  readonly cohortLabel: (cohort: LegendComparison['cohort']) => string;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const format = new Intl.NumberFormat(toIntlLocale(locale));
  const rate = (triples: number, attacks: number) =>
    attacks > 0 ? (triples / attacks) * 100 : null;
  const percentage = new Intl.NumberFormat(toIntlLocale(locale), {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
  const rateLabel = (value: number | null) =>
    value === null ? '—' : `${percentage.format(value)}%`;
  return (
    <View style={styles.comparisons}>
      {groupLegendComparisons(comparisons).map((group) => {
        const baseline = group[0]!;
        const personalRate = rate(baseline.playerTriples, baseline.playerAttacks);
        return (
          <Surface
            key={`${baseline.days}:${baseline.playerAttacks}:${baseline.playerTriples}`}
            radius={ckRadius.tile}
            style={styles.comparisonCard}
          >
            <View style={styles.row}>
              <MobileWebImage imageUrl={ImageAssets.attackStar} style={styles.historyMetricImage} />
              <View style={styles.grow}>
                <CKText role="rowTitle">
                  {playerName} · {t('legendsHitrate')}
                </CKText>
                <CKText muted role="metadata">
                  {format.format(baseline.playerTriples)}/{format.format(baseline.playerAttacks)} ·{' '}
                  {t('statsIndexDays', { index: baseline.days })}
                </CKText>
              </View>
              <CKText role="titleLarge">{rateLabel(personalRate)}</CKText>
            </View>
            {group.map((comparison) => {
              const cohortRate = rate(comparison.triples, comparison.attacks);
              return (
                <View key={comparison.cohort} style={styles.comparisonBenchmark}>
                  <View style={styles.row}>
                    <CKText role="bodyMedium" style={styles.grow}>
                      {cohortLabel(comparison.cohort)}
                    </CKText>
                    <CKText role="rowTitle">{rateLabel(cohortRate)}</CKText>
                  </View>
                  <View
                    style={[
                      styles.comparisonTrack,
                      { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.5) },
                    ]}
                  >
                    <View
                      style={[
                        styles.comparisonFill,
                        {
                          width: `${Math.max(0, Math.min(100, cohortRate ?? 0))}%`,
                          backgroundColor: theme.onSurfaceVariant,
                        },
                      ]}
                    />
                    {personalRate === null ? null : (
                      <View
                        style={[
                          styles.comparisonMarker,
                          {
                            left: `${Math.max(0, Math.min(100, personalRate))}%`,
                            backgroundColor: theme.primary,
                          },
                        ]}
                      />
                    )}
                  </View>
                  <CKText muted role="metadata">
                    {format.format(comparison.triples)}/{format.format(comparison.attacks)} ·{' '}
                    {t('statsThreeStarRate')}
                  </CKText>
                </View>
              );
            })}
          </Surface>
        );
      })}
    </View>
  );
}

function hasComparisonSamples(comparison: PlayerLegendLeagueData['comparisons'][number]) {
  return comparison.attacks > 0 || comparison.playerAttacks > 0;
}

type LegendContribution = ReturnType<typeof legendsShareSummary>['dailyContributions'][number];

export function legendContributionRows(days: readonly LegendContribution[], columns = 12) {
  if (!days.length) return [];
  const ordered = [...days].sort((left, right) => left.key.localeCompare(right.key));
  const byDay = new Map(ordered.map((day) => [day.key, day]));
  const first = new Date(`${ordered[0]!.key}T00:00:00.000Z`);
  const last = new Date(`${ordered.at(-1)!.key}T00:00:00.000Z`);
  const slots: (LegendContribution | null)[] = [];
  for (let cursor = first; cursor <= last; cursor = new Date(cursor.getTime() + 86_400_000)) {
    slots.push(byDay.get(cursor.toISOString().slice(0, 10)) ?? null);
  }
  const width = Math.max(1, Math.floor(columns));
  return Array.from({ length: Math.ceil(slots.length / width) }, (_, row) =>
    slots.slice(row * width, (row + 1) * width),
  );
}

export function legendContributionAtPoint(
  rows: readonly (readonly (LegendContribution | null | undefined)[])[],
  x: number,
  y: number,
) {
  const column = Math.floor(x / 26);
  const row = Math.floor(y / 26);
  return rows[row]?.[column] ?? null;
}

function ContributionCalendar({
  days,
  selectedKey,
  onSelect,
}: {
  readonly days: readonly LegendContribution[];
  readonly selectedKey: string | null;
  readonly onSelect: (key: string) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const gridRef = useRef<View>(null);
  const [width, setWidth] = useState(0);
  const columns = Math.max(1, Math.floor((width - 16 + 4) / 26));
  const rows = legendContributionRows(days, width ? columns : 12);
  const selectFromPoint = (event: GestureResponderEvent) => {
    const nativeEvent = event.nativeEvent as GestureResponderEvent['nativeEvent'] & {
      readonly clientX?: number;
      readonly clientY?: number;
    };
    const pageX =
      Platform.OS === 'web' && nativeEvent.clientX !== undefined
        ? nativeEvent.clientX
        : nativeEvent.pageX -
          (Platform.OS === 'web' && typeof window !== 'undefined' ? window.scrollX : 0);
    const pageY =
      Platform.OS === 'web' && nativeEvent.clientY !== undefined
        ? nativeEvent.clientY
        : nativeEvent.pageY -
          (Platform.OS === 'web' && typeof window !== 'undefined' ? window.scrollY : 0);
    gridRef.current?.measureInWindow((left, top) => {
      const day = legendContributionAtPoint(rows, pageX - left - 8, pageY - top - 4);
      if (day) onSelect(day.key);
    });
  };
  return (
    <View
      ref={gridRef}
      onLayout={(event) => setWidth(event.nativeEvent.layout.width)}
      onResponderGrant={selectFromPoint}
      onResponderMove={selectFromPoint}
      onMoveShouldSetResponder={() => true}
      onStartShouldSetResponder={() => true}
      style={styles.contributionGrid}
      testID="legend-contribution-calendar"
    >
      {rows.map((row, rowIndex) => (
        <View key={rowIndex} style={styles.contributionRow}>
          {row.map((day, columnIndex) =>
            day ? (
              <Pressable
                key={day.key}
                accessibilityLabel={`${day.key}, ${day.change > 0 ? '+' : ''}${day.change}`}
                accessibilityRole="button"
                accessibilityState={{ selected: selectedKey === day.key }}
                onFocus={() => onSelect(day.key)}
                onHoverIn={() => onSelect(day.key)}
                onPress={() => onSelect(day.key)}
                onPressIn={() => onSelect(day.key)}
                style={[
                  styles.contributionCell,
                  {
                    backgroundColor: colorWithAlpha(
                      day.change > 0
                        ? statColors.win
                        : day.change < 0
                          ? theme.error
                          : theme.surfaceContainerHighest,
                      0.34,
                    ),
                  },
                  day.attackTrophies === 320 && styles.perfectContributionCell,
                  selectedKey === day.key && { borderColor: theme.onSurface },
                ]}
                testID={day.attackTrophies === 320 ? `legend-perfect-day-${day.key}` : undefined}
              />
            ) : day === null ? (
              <View
                key={`missing-${rowIndex}-${columnIndex}`}
                accessibilityLabel={t('generalNoDataAvailable')}
                style={[
                  styles.contributionPlaceholder,
                  { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.36) },
                ]}
              />
            ) : (
              <View
                key={`empty-${rowIndex}-${columnIndex}`}
                style={styles.contributionPlaceholder}
              />
            ),
          )}
        </View>
      ))}
    </View>
  );
}

export function legendHistoryTopPercent(rank: number, population: number | null) {
  if (
    population === null ||
    !Number.isFinite(population) ||
    !Number.isFinite(rank) ||
    population <= 0 ||
    rank <= 0 ||
    rank > population
  )
    return null;
  return Math.ceil((rank / population) * 1000) / 10;
}

function LegendHistoryRow({
  season,
  locale,
}: {
  readonly season: PlayerLegendHistoryEntry;
  readonly locale: string;
}) {
  const { t } = useI18n();
  const format = new Intl.NumberFormat(toIntlLocale(locale));
  const topPercent = legendHistoryTopPercent(season.rank, season.population);
  return (
    <Surface radius={ckRadius.tile} style={styles.seasonCard}>
      <View style={styles.historyHeader}>
        <MobileWebImage imageUrl={ImageAssets.legendLeagueOne} style={styles.historyBadge} />
        <CKText role="titleMedium" style={styles.grow}>
          {formatSeason(season.season, locale)}
        </CKText>
        <View style={styles.historyRank}>
          <CKText role="rowTitle">{season.rank ? `#${format.format(season.rank)}` : '—'}</CKText>
          {topPercent === null ? null : (
            <CKText muted role="metadata">
              {t('rankingsTopCount', { count: `${format.format(topPercent)}%` })}
            </CKText>
          )}
        </View>
      </View>
      <View style={styles.historyMetrics}>
        <HistoryMetric
          imageUrl={ImageAssets.trophies}
          label={t('rankedLeagueTrophies')}
          value={format.format(season.trophies)}
        />
        <HistoryMetric
          imageUrl={ImageAssets.sword}
          label={t('rankedLeagueAttacks')}
          value={format.format(season.attackWins)}
        />
        <HistoryMetric
          imageUrl={ImageAssets.shieldWithArrow}
          label={t('rankedLeagueDefenses')}
          value={format.format(season.defenseWins)}
        />
      </View>
    </Surface>
  );
}

function HistoryMetric({
  imageUrl,
  label,
  value,
}: {
  readonly imageUrl: string;
  readonly label: string;
  readonly value: string;
}) {
  return (
    <View style={styles.historyMetric}>
      <MobileWebImage imageUrl={imageUrl} style={styles.historyMetricImage} />
      <View style={styles.grow}>
        <CKText muted numberOfLines={1} role="metadata">
          {label}
        </CKText>
        <CKText role="rowTitle">{value}</CKText>
      </View>
    </View>
  );
}

export function SeasonDayTable({ days }: { readonly days: readonly PlayerLegendDaySummary[] }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface radius={ckRadius.tile} style={styles.dayTable}>
      <View style={styles.dayTableRow}>
        <CKText muted role="metadata" style={styles.dayColumn}>
          {t('statsByDay')}
        </CKText>
        <CKText muted role="metadata" style={styles.numberColumn}>
          {t('rankedLeagueAttacks')}
        </CKText>
        <CKText muted role="metadata" style={styles.numberColumn}>
          {t('rankedLeagueDefenses')}
        </CKText>
        <CKText muted role="metadata" style={styles.netColumn}>
          +/-
        </CKText>
        <CKText muted role="metadata" style={styles.rankColumn}>
          {t('legendsGlobalRankTitle')}
        </CKText>
      </View>
      {[...days].reverse().map((day) => (
        <View key={day.day} style={styles.dayTableRow}>
          <CKText role="metadata" style={styles.dayColumn}>
            {day.day.slice(5)}
          </CKText>
          <CKText role="rowTitle" style={styles.numberColumn}>
            +{day.attackTrophies}
          </CKText>
          <CKText role="rowTitle" style={styles.numberColumn}>
            {day.defenseTrophies}
          </CKText>
          <CKText
            testID={`legend-day-net-${day.day}`}
            role="rowTitle"
            style={[
              styles.netColumn,
              {
                color:
                  day.trophyChange > 0
                    ? statColors.win
                    : day.trophyChange < 0
                      ? statColors.loss
                      : theme.onSurfaceVariant,
              },
            ]}
          >
            {day.trophyChange > 0 ? '+' : ''}
            {day.trophyChange}
          </CKText>
          <CKText role="metadata" style={styles.rankColumn}>
            {day.globalRank ? `#${day.globalRank.toLocaleString()}` : '—'}
          </CKText>
        </View>
      ))}
    </Surface>
  );
}

function LegendDayNavigation({
  day,
  today,
  onSelect,
  days,
  rank,
}: {
  readonly day: string;
  readonly today: string;
  readonly onSelect: (day: string) => void;
  readonly days: readonly PlayerLegendDaySummary[];
  readonly rank?: number | null;
}) {
  const { locale, t } = useI18n();
  const theme = useCKTheme();
  const labels = new Map(days.map((value) => [value.day, value]));
  const previous = legendDayOffset(day, -1);
  const next = legendDayOffset(day, 1);
  const selected = labels.get(day);
  const change = selected?.trophyChange;
  const globalRank = rank ?? selected?.globalRank;
  const date = new Intl.DateTimeFormat(toIntlLocale(locale), {
    dateStyle: 'long',
    timeZone: 'UTC',
  }).format(new Date(`${day}T00:00:00Z`));
  return (
    <DateNavigator
      label={date}
      accessibilityLabel={t('statsByDay')}
      onPrevious={() => onSelect(previous)}
      onNext={() => onSelect(next)}
      nextDisabled={next > today}
    >
      <View style={styles.row}>
        {change === undefined ? null : (
          <CKText
            role="bodyMedium"
            style={{
              color:
                change < 0 ? statColors.loss : change > 0 ? statColors.win : theme.onSurfaceVariant,
            }}
          >
            {change > 0 ? '+' : ''}
            {change}
          </CKText>
        )}
        {globalRank ? (
          <CKText role="bodyMedium" muted>
            #{globalRank.toLocaleString(toIntlLocale(locale))}
          </CKText>
        ) : null}
      </View>
    </DateNavigator>
  );
}

function HeroAction({
  label,
  onPress,
  icon,
}: {
  label: string;
  onPress: () => void;
  icon: React.ReactNode;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={styles.heroAction}
    >
      {icon}
    </Pressable>
  );
}

export function legendSeasonDateRange(
  seasonStart: string | null,
  exclusiveSeasonEnd: string | null,
  fallbackDay: string,
  today = currentLegendDay(),
) {
  const startDay = legendCalendarDay(seasonStart) ?? fallbackDay;
  const exclusiveEndDay = legendCalendarDay(exclusiveSeasonEnd);
  const requestedEndDay = exclusiveEndDay ? legendDayOffset(exclusiveEndDay, -1) : fallbackDay;
  const cappedEndDay = requestedEndDay < today ? requestedEndDay : today;
  const endDay = cappedEndDay < startDay ? startDay : cappedEndDay;
  return {
    start: localCalendarDate(startDay),
    end: localCalendarDate(endDay),
  };
}

function legendCalendarDay(value: string | null) {
  const day = value?.slice(0, 10) ?? '';
  return /^\d{4}-\d{2}-\d{2}$/.test(day) ? day : null;
}

function localCalendarDate(day: string) {
  const [year, month, date] = day.split('-').map(Number);
  return new Date(year!, month! - 1, date!);
}

function formatSeason(season: string, locale: string) {
  const value = season.startsWith('v2-')
    ? season.slice(3)
    : season.length === 7
      ? `${season}-01T00:00:00Z`
      : season;
  const date = new Date(value);
  if (!Number.isFinite(date.getTime())) return season;
  return new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'long',
    year: 'numeric',
    ...(season.length === 7 ? {} : { day: 'numeric' as const }),
    timeZone: 'UTC',
  }).format(date);
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  grow: { flex: 1 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  white: { color: '#FFF' },
  whiteSoft: { color: '#FFFFFFCC' },
  hero: { minHeight: 260, overflow: 'hidden' },
  heroScrim: {},
  heroContent: { flex: 1, justifyContent: 'flex-end', paddingBottom: 24, gap: 4 },
  heroActions: {
    position: 'absolute',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  exportButton: {
    minHeight: 42,
    paddingHorizontal: 12,
    borderRadius: ckRadius.control,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#00000066',
  },
  heroAction: {
    width: 44,
    height: 44,
    borderRadius: ckRadius.pill,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#00000066',
  },
  heroIdentity: { alignItems: 'center', gap: 2 },
  townHallIdentity: { width: 62, height: 62 },
  heroChips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 7,
    marginTop: 10,
  },
  heroChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    maxWidth: '100%',
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  heroChipImage: { width: 19, height: 19, resizeMode: 'contain' },
  heroChipText: { minWidth: 0, flexShrink: 1 },
  content: { width: '100%', maxWidth: 1120, alignSelf: 'center', paddingTop: 16, gap: 12 },
  currentDayEmptyState: { minHeight: 180, paddingVertical: 20 },
  historyEmptyState: { minHeight: 88, paddingVertical: 16 },
  seasonContent: { gap: 12 },
  comparisons: { gap: 10, paddingTop: 4 },
  comparisonCard: { padding: 14, gap: 12 },
  comparisonBenchmark: { gap: 6, paddingTop: 6 },
  comparisonTrack: { height: 6, borderRadius: 3, marginVertical: 3 },
  comparisonFill: { height: 6, borderRadius: 3 },
  comparisonMarker: {
    position: 'absolute',
    top: -3,
    width: 2,
    height: 12,
    marginLeft: -1,
    borderRadius: 1,
  },
  armyComparisonIdentity: { minHeight: 44, flexDirection: 'row', alignItems: 'center', gap: 10 },
  armyComparisonImages: { flexDirection: 'row' },
  armyComparisonImage: { width: 38, height: 38, marginRight: -6 },
  recentSummary: { padding: 14, gap: 12 },
  contributionGrid: { width: '100%', gap: 4, paddingVertical: 4, paddingHorizontal: 8 },
  contributionRow: { flexDirection: 'row', gap: 4 },
  contributionCell: {
    width: 22,
    height: 22,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: 'transparent',
    alignItems: 'center',
    gap: 2,
  },
  contributionPlaceholder: { width: 22, height: 22 },
  perfectContributionCell: { backgroundColor: '#E7B946', borderColor: '#E7B946' },
  contributionDetail: { minHeight: 54, justifyContent: 'center', gap: 2 },
  popularItems: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  popularItem: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  popularItemImage: { width: 48, height: 48 },
  dayTable: { padding: 14, gap: 4 },
  dayTableRow: { minHeight: 38, flexDirection: 'row', alignItems: 'center', gap: 8 },
  dayColumn: { flex: 1.1 },
  numberColumn: { flex: 1, textAlign: 'right' },
  netColumn: { flex: 0.85, textAlign: 'right' },
  rankColumn: { flex: 1.35, textAlign: 'right' },
  seasonCard: { padding: 14, gap: 8 },
  historyHeader: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  historyRank: { alignItems: 'flex-end', gap: 3 },
  historyBadge: { width: 40, height: 40 },
  historyMetrics: { flexDirection: 'row', gap: 8 },
  historyMetric: { flex: 1, minWidth: 0, flexDirection: 'row', alignItems: 'center', gap: 6 },
  historyMetricImage: { width: 24, height: 24 },
});
