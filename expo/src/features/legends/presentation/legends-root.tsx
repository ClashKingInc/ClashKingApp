import {
  type ViewInstance,
  type ScrollViewInstance,
  Animated,
  Alert,
  Pressable,
  Platform,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
  type GestureResponderEvent,
} from 'react-native';
import { LegendHistoryList } from './legend-history';
import { HeaderArtwork } from '../../../ui/header-artwork';
import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import {
  ArrowLeft,
  CalendarDays,
  ChartLine,
  ChevronRight,
  Download,
  History,
  Share2,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  DateNavigator,
  ProfileTabs,
  EmptyState,
  ErrorState,
  SkeletonContent,
  MobileWebImage,
  PillSurface,
  ProfileHeaderAction,
  statColors,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { ImageAssets } from '../../../core/assets/image-assets';
import { sharePageLink } from '../../../core/deep-links/share-page-link';
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
import { playerProfileClanIdentity } from '../../player/presentation/player-clan-identity';
import { HeroHeaderScrim } from '../../../ui/hero-header-scrim';
import { PagerView, type PagerViewHandle } from '../../../ui/pager';
import { usePrimarySwipeGuard } from '../../../ui/primary-swipe-guard';
import { useCKAccessibility } from '../../../ui/accessibility';
export { legendHistoryTopPercent } from './legend-history';

const LEGENDS_PAGES = ['daily', 'season', 'history'] as const;
type LegendsPage = (typeof LEGENDS_PAGES)[number];

export function LegendsRoot({
  player,
  onBack,
  onOpenOpponent,
  onOpenClan,
}: {
  readonly player: Player;
  readonly onBack: () => void;
  readonly onOpenOpponent?: (tag: string) => void;
  readonly onOpenClan?: (tag: string) => void;
}) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
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
        player={player}
        data={data}
        error={error}
        loading={loading}
        refreshing={refreshing}
        selectedDay={selectedDay}
        onBack={onBack}
        onOpenOpponent={onOpenOpponent}
        onOpenClan={onOpenClan}
        onShareLink={() =>
          void sharePageLink(
            { kind: 'player', tag: player.tag, params: { tab: 'legends' } },
            player.name,
          ).catch(() => Alert.alert(t('generalError'), t('generalTryAgain')))
        }
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
          player={player}
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
  player,
  data,
  error,
  loading,
  refreshing,
  selectedDay,
  onBack,
  onRefresh,
  onSelectDay,
  onExport,
  onShareLink,
  onOpenClan,
  onOpenOpponent,
}: {
  readonly player?: Player;
  readonly data: PlayerLegendLeagueData | null;
  readonly error: string | null;
  readonly loading: boolean;
  readonly refreshing: boolean;
  readonly selectedDay: string;
  readonly onBack: () => void;
  readonly onRefresh: () => Promise<void>;
  readonly onSelectDay: (day: string) => void;
  readonly onExport: () => void;
  readonly onShareLink?: () => void;
  readonly onOpenClan?: (tag: string) => void;
  readonly onOpenOpponent?: (tag: string) => void;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const horizontal = Math.max(16, (width - 1120) / 2);
  const current = data?.currentDay;
  const hasSectionContent = (section: LegendsPage) =>
    section === 'daily'
      ? !!current && data?.selectedDay === selectedDay
      : section === 'season'
        ? !!data?.recentDays.length
        : !!data?.history.length;
  const clanIdentity = player ? playerProfileClanIdentity(player) : null;
  const [page, setPage] = useState<LegendsPage>('daily');
  const [settledPage, setSettledPage] = useState<LegendsPage>('daily');
  const [pageHeights, setPageHeights] = useState<Partial<Record<LegendsPage, number>>>({});
  const [sectionSwipeEnabled, setSectionSwipeEnabled] = useState(true);
  const [tabPosition] = useState(() => new Animated.Value(0));
  const pager = useRef<PagerViewHandle>(null);
  const scroll = useRef<ScrollViewInstance>(null);
  const scrollY = useRef(0);
  const headerHeight = useRef(0);
  const { reduceMotion } = useCKAccessibility();
  const blockPrimarySwipe = usePrimarySwipeGuard();
  const setCalendarInteraction = (active: boolean) => {
    // Calendar scrubbing selects a day; it must not also change the section.
    pager.current?.setScrollEnabled?.(!active);
    setSectionSwipeEnabled(!active);
  };
  useEffect(() => () => blockPrimarySwipe(false), [blockPrimarySwipe]);
  const selectPage = (next: LegendsPage) => {
    setPage(next);
    // A shorter section must not inherit a scroll position below its content.
    // Keep the current header collapse instead of jumping back to the top.
    const offset = Math.min(scrollY.current, headerHeight.current);
    requestAnimationFrame(() => scroll.current?.scrollTo({ y: offset, animated: false }));
  };
  const headerFavorite = data ? popularLegendItems(data.seasonArmyShareCodes)[0] : undefined;
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.fill, { backgroundColor: theme.background }]}
    >
      <ScrollView
        ref={scroll}
        scrollEventThrottle={16}
        onScroll={(event) => {
          scrollY.current = event.nativeEvent.contentOffset.y;
        }}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={() => void onRefresh()} />
        }
        contentContainerStyle={{ paddingBottom: insets.bottom + 28 }}
      >
        <View
          testID="legends-hero"
          onLayout={(event) => {
            headerHeight.current = event.nativeEvent.layout.height;
          }}
          style={[styles.hero, { minHeight: 238 + insets.top }]}
        >
          <HeaderArtwork
            source={require('../../../../assets/clashking/backgrounds/legends-pekka-classic-v1.webp')}
            style={StyleSheet.absoluteFill}
            contentFit="cover"
            contentPosition="center"
            transition={0}
          />
          <HeroHeaderScrim variant="ranked" edgeColor={theme.background} />
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
              <ProfileHeaderAction
                label={materialBackLabel(locale)}
                onPress={onBack}
                icon={<ArrowLeft color="#FFF" />}
              />
              <View style={styles.heroActionGroup}>
                {onShareLink ? (
                  <ProfileHeaderAction
                    label={t('gameAssetsShare')}
                    onPress={onShareLink}
                    icon={<Share2 color="#FFF" />}
                  />
                ) : null}
                <ProfileHeaderAction
                  label={t('generalExport')}
                  onPress={onExport}
                  disabled={!data}
                  icon={<Download color="#FFF" />}
                />
              </View>
            </View>
            <View style={styles.heroIdentity}>
              <View>
                <MobileWebImage
                  testID="legends-league-badge"
                  imageUrl={player?.leagueUrl || ImageAssets.legendLeagueOne}
                  style={styles.leagueIdentity}
                  contentFit="contain"
                />
                <View style={styles.townHallBadgeShell}>
                  <MobileWebImage
                    testID="legends-town-hall"
                    imageUrl={player?.townHallPic || ImageAssets.townHall(data?.townHallLevel ?? 1)}
                    style={styles.townHallBadge}
                    contentFit="contain"
                  />
                </View>
              </View>
              <CKText numberOfLines={1} role="screenTitle" style={styles.white}>
                {data?.playerName ?? ''}
              </CKText>
              {clanIdentity?.tag ? (
                <Pressable
                  accessibilityRole={onOpenClan ? 'button' : undefined}
                  disabled={!onOpenClan}
                  onPress={() => onOpenClan?.(clanIdentity.tag)}
                  style={styles.clanLine}
                >
                  <MobileWebImage imageUrl={clanIdentity.badgeUrl} style={styles.clanBadge} />
                  <CKText numberOfLines={1} role="labelLarge" style={styles.white}>
                    {clanIdentity.name}
                  </CKText>
                  {onOpenClan ? <ChevronRight size={18} color="#FFFFFFAD" /> : null}
                </Pressable>
              ) : null}
            </View>
            {data ? (
              <HeroSeasonSummary
                favorite={headerFavorite}
                location={data.currentRank?.location ?? null}
                stats={data.seasonStats}
                trophies={data.currentRank?.trophies ?? data.trophies}
                rank={data.currentRank?.globalRank ?? null}
              />
            ) : null}
          </View>
        </View>
        <View style={[styles.content, { paddingHorizontal: horizontal }]}>
          <ProfileTabs
            variant="underline"
            selectedKey={page}
            animatedPosition={tabPosition}
            indicatorRtl={isRtl}
            onSelect={(key) => {
              const next = key as LegendsPage;
              const index = LEGENDS_PAGES.indexOf(next);
              selectPage(next);
              if (reduceMotion) {
                pager.current?.setPageWithoutAnimation(index);
                tabPosition.setValue(index);
                setSettledPage(next);
              } else pager.current?.setPage(index);
            }}
            tabs={[
              { key: 'daily', label: t('statsByDay'), icon: <CalendarDays size={20} /> },
              { key: 'season', label: t('filtersSeason'), icon: <ChartLine size={20} /> },
              { key: 'history', label: t('generalHistory'), icon: <History size={20} /> },
            ]}
          />
          <View
            onTouchStart={() => blockPrimarySwipe(true)}
            onTouchEnd={() => {
              blockPrimarySwipe(false);
              setCalendarInteraction(false);
            }}
            onTouchCancel={() => {
              blockPrimarySwipe(false);
              setCalendarInteraction(false);
            }}
          >
            <PagerView
              ref={pager}
              initialPage={0}
              scrollEnabled={sectionSwipeEnabled}
              layoutDirection={isRtl ? 'rtl' : 'ltr'}
              testID="legends-section-pager"
              style={{
                height: Math.max(pageHeights[page] ?? 600, pageHeights[settledPage] ?? 600),
              }}
              onPageScroll={(event) =>
                tabPosition.setValue(event.nativeEvent.position + event.nativeEvent.offset)
              }
              onPageSelected={(event) => {
                const next = LEGENDS_PAGES[event.nativeEvent.position];
                if (!next) return;
                selectPage(next);
                setSettledPage(next);
              }}
            >
              {LEGENDS_PAGES.map((section) => (
                <View
                  key={section}
                  collapsable={false}
                  style={{ flex: 1 }}
                  aria-hidden={section !== page}
                  accessibilityElementsHidden={section !== page}
                  importantForAccessibility={section !== page ? 'no-hide-descendants' : 'auto'}
                >
                  <View
                    style={styles.sectionPage}
                    onLayout={(event) => {
                      const height = Math.ceil(event.nativeEvent.layout.height);
                      if (height > 0)
                        setPageHeights((old) =>
                          old[section] === height ? old : { ...old, [section]: height },
                        );
                    }}
                  >
                    {section === 'daily' ? (
                      <LegendDayNavigation
                        day={selectedDay}
                        onSelect={onSelectDay}
                        today={currentLegendDay()}
                        days={data?.recentDays ?? []}
                        rank={
                          data?.selectedDay === selectedDay
                            ? data.historicalRank?.globalRank
                            : undefined
                        }
                      />
                    ) : null}
                    {loading && !hasSectionContent(section) ? (
                      <LegendContentLoading section={section} player={player} day={selectedDay} />
                    ) : error && !hasSectionContent(section) ? (
                      <ErrorState
                        title={t('apiErrorServer')}
                        actionLabel={t('sideRefresh')}
                        onAction={() => void onRefresh()}
                      />
                    ) : data ? (
                      section === 'season' ? (
                        <LegendRecentSummary
                          data={data}
                          onCalendarInteraction={setCalendarInteraction}
                        />
                      ) : section === 'history' ? (
                        <LegendHistoryList history={data.history} />
                      ) : loading && data.selectedDay !== selectedDay ? (
                        <LegendContentLoading section="daily" player={player} day={selectedDay} />
                      ) : current ? (
                        <LegendBattlePanel data={current} onOpenOpponent={onOpenOpponent} />
                      ) : (
                        <EmptyState
                          title={t('legendsNotInLeague')}
                          body={t('legendsNoDataToday')}
                          style={styles.currentDayEmptyState}
                        />
                      )
                    ) : null}
                  </View>
                </View>
              ))}
            </PagerView>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function LegendContentLoading({
  section,
  player,
  day,
}: {
  section: LegendsPage;
  player?: Player;
  day: string;
}) {
  const battles = [0, 1, 2].map(
    () =>
      new PlayerLegendBattle(
        40,
        false,
        new Date(0),
        180,
        player?.townHallLevel ?? 16,
        '',
        'Opponent player',
        player?.townHallLevel ?? 16,
        3,
        100,
      ),
  );
  const log = new PlayerLegendBattlelog(
    player?.tag ?? '',
    day,
    new Date(0),
    new Date(86_400_000),
    true,
    120,
    -120,
    0,
    battles,
    battles,
  );
  const history = ['2026-01', '2025-12', '2025-11'].map(
    (season) => new PlayerLegendHistoryEntry(season, null, null, 5000, 100, 100, 100),
  );
  const data = new PlayerLegendLeagueData(
    player?.tag ?? '',
    player?.name ?? 'Player name',
    player?.townHallLevel ?? 16,
    player?.trophies ?? 5000,
    player?.bestTrophies ?? 5000,
    log,
    history,
  );
  return (
    <SkeletonContent loading>
      {section === 'daily' ? (
        <LegendBattlePanel data={log} />
      ) : section === 'history' ? (
        <LegendHistoryList history={history} />
      ) : (
        <LegendRecentSummary data={data} onCalendarInteraction={() => undefined} />
      )}
    </SkeletonContent>
  );
}

function LegendRecentSummary({
  data,
  onCalendarInteraction,
}: {
  readonly data: PlayerLegendLeagueData;
  readonly onCalendarInteraction: (active: boolean) => void;
}) {
  const { locale, t } = useI18n();
  const summary = legendsShareSummary(data);
  const [selectedContribution, setSelectedContribution] = useState<string | null>(null);
  const popular = popularLegendItems(data.seasonArmyShareCodes);
  const activeContribution = summary.dailyContributions.some(
    (day) => day.key === selectedContribution,
  )
    ? selectedContribution
    : (summary.dailyContributions.at(-1)?.key ?? null);
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
      {data.recentDays.length ? (
        <SeasonDayTable
          days={data.recentDays}
          selectedDay={activeContribution}
          onSelectDay={setSelectedContribution}
          header={
            summary.dailyContributions.length ? (
              <View style={styles.contributionSection}>
                <CKText role="titleMedium">{t('legendsTrophyGrid')}</CKText>
                <View
                  onTouchStart={() => onCalendarInteraction(true)}
                  onTouchEnd={() => onCalendarInteraction(false)}
                  onTouchCancel={() => onCalendarInteraction(false)}
                >
                  <ContributionCalendar
                    days={summary.dailyContributions}
                    selectedKey={activeContribution}
                    onSelect={setSelectedContribution}
                  />
                </View>
              </View>
            ) : undefined
          }
        />
      ) : null}
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
    </View>
  );
}

function HeroSeasonSummary({
  favorite,
  location,
  stats,
  trophies,
  rank,
}: {
  readonly favorite: ReturnType<typeof popularLegendItems>[number] | undefined;
  readonly location: NonNullable<PlayerLegendLeagueData['currentRank']>['location'];
  readonly stats: PlayerLegendLeagueData['seasonStats'];
  readonly trophies: number;
  readonly rank: number | null;
}) {
  const { t, locale } = useI18n();
  const tripleRate = (triples: number, attacks: number) =>
    attacks > 0 ? `${((triples / attacks) * 100).toFixed(1)}%` : '—';
  return (
    <>
      <View style={styles.heroChips}>
        <HeroChip
          imageUrl={
            location?.countryCode ? ImageAssets.flag(location.countryCode) : ImageAssets.planet
          }
          label={t('sideLocation')}
          value={location?.name ?? '—'}
        />
        <HeroChip
          imageUrl={ImageAssets.trophies}
          label={t('rankedLeagueTrophies')}
          value={trophies.toLocaleString(toIntlLocale(locale))}
        />
        <HeroChip
          imageUrl={ImageAssets.bestTrophies}
          label={t('legendsGlobalRankTitle')}
          value={rank !== null ? `#${rank.toLocaleString(toIntlLocale(locale))}` : '—'}
        />
        <HeroChip
          imageUrl={ImageAssets.attackStar}
          label={t('legendsHitrate')}
          value={stats ? tripleRate(stats.attackTriples, stats.attacks) : '—'}
        />
      </View>
      {favorite ? (
        <View style={styles.favoriteChipRow}>
          <HeroChip
            imageUrl={favorite?.item.imageUrl ?? ImageAssets.defaultImage}
            label={favorite.item.name}
            value={t('legendsPopularTroop')}
          />
        </View>
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

// Rendering, wrapping and scrub hit-testing must share the same pitch.
// Both cell and gap are 75% of their previous size (22px + 4px).
const CONTRIBUTION_CELL = 16.5;
const CONTRIBUTION_GAP = 3;
const CONTRIBUTION_PITCH = CONTRIBUTION_CELL + CONTRIBUTION_GAP;

export function legendContributionAtPoint(
  rows: readonly (readonly (LegendContribution | null | undefined)[])[],
  x: number,
  y: number,
) {
  const column = Math.floor(x / CONTRIBUTION_PITCH);
  const row = Math.floor(y / CONTRIBUTION_PITCH);
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
  const gridRef = useRef<ViewInstance>(null);
  const [width, setWidth] = useState(0);
  const columns = Math.max(1, Math.floor((width - 16 + CONTRIBUTION_GAP) / CONTRIBUTION_PITCH));
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

export function SeasonDayTable({
  days,
  header,
  selectedDay,
  onSelectDay,
}: {
  readonly days: readonly PlayerLegendDaySummary[];
  readonly header?: ReactNode;
  readonly selectedDay?: string | null;
  readonly onSelectDay?: (day: string) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface radius={ckRadius.tile} style={styles.dayTable} testID="legend-season-days">
      {header}
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
        <Pressable
          key={day.day}
          onPress={onSelectDay ? () => onSelectDay(day.day) : undefined}
          accessibilityRole={onSelectDay ? 'button' : undefined}
          accessibilityState={{ selected: selectedDay === day.day }}
          testID={`legend-season-day-${day.day}`}
          style={[
            styles.dayTableRow,
            styles.dayDataRow,
            selectedDay === day.day && {
              backgroundColor: colorWithAlpha(theme.primary, 0.12),
              borderStartColor: theme.primary,
            },
          ]}
        >
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
        </Pressable>
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

const styles = StyleSheet.create({
  fill: { flex: 1 },
  grow: { flex: 1 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  white: { color: '#FFF' },
  whiteSoft: { color: '#FFFFFFCC' },
  hero: { minHeight: 260, overflow: 'hidden' },
  heroScrim: {},
  heroContent: { flex: 1, justifyContent: 'flex-end', paddingBottom: 8, gap: 4 },
  heroActions: {
    position: 'absolute',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  heroActionGroup: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  heroIdentity: { alignItems: 'center', gap: 2 },
  leagueIdentity: { width: 104, height: 104 },
  townHallBadgeShell: {
    position: 'absolute',
    left: -2,
    bottom: 0,
    width: 38,
    height: 38,
    borderRadius: 19,
    padding: 3,
    backgroundColor: 'rgba(24,24,24,.82)',
  },
  townHallBadge: { width: 32, height: 32 },
  clanLine: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 5,
    marginTop: 4,
    maxWidth: '100%',
  },
  clanBadge: { width: 18, height: 18 },
  heroChips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 7,
    marginTop: 10,
  },
  favoriteChipRow: { alignItems: 'center', marginTop: 3 },
  sectionPage: { gap: 12, paddingBottom: 8 },
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
  content: { width: '100%', maxWidth: 1120, alignSelf: 'center', gap: 12 },
  currentDayEmptyState: { minHeight: 180, paddingVertical: 20 },
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
  recentSummary: { padding: 14, gap: 12 },
  contributionSection: { gap: 8, paddingBottom: 6 },
  contributionGrid: {
    width: '100%',
    gap: CONTRIBUTION_GAP,
    paddingVertical: 4,
    paddingHorizontal: 8,
  },
  contributionRow: { flexDirection: 'row', gap: CONTRIBUTION_GAP },
  contributionCell: {
    width: CONTRIBUTION_CELL,
    height: CONTRIBUTION_CELL,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: 'transparent',
    alignItems: 'center',
    gap: 2,
  },
  contributionPlaceholder: { width: CONTRIBUTION_CELL, height: CONTRIBUTION_CELL },
  perfectContributionCell: { backgroundColor: '#E7B946', borderColor: '#E7B946' },
  popularItems: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  popularItem: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  popularItemImage: { width: 48, height: 48 },
  dayTable: { padding: 14, gap: 4 },
  dayTableRow: {
    minHeight: 38,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 8,
    borderStartWidth: 2,
    borderStartColor: 'transparent',
  },
  dayDataRow: { minHeight: 44, borderRadius: 10 },
  dayColumn: { flex: 1.1 },
  numberColumn: { flex: 1, textAlign: 'right' },
  netColumn: { flex: 0.85, textAlign: 'right' },
  rankColumn: { flex: 1.35, textAlign: 'right' },
  historyMetricImage: { width: 24, height: 24 },
});
