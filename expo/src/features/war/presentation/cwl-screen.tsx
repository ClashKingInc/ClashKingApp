import type { ScrollViewInstance } from 'react-native';
import {
  memo,
  useEffect,
  useMemo,
  useRef,
  useState,
  useSyncExternalStore,
  type ReactNode,
} from 'react';
import {
  AccessibilityInfo,
  Animated,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import {
  ArrowLeft,
  ChevronDown,
  ChevronRight,
  ChevronUp,
  Download,
  Share2,
  Info,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { ImageAssets } from '../../../core/assets/image-assets';
import {
  gameDataState,
  subscribeToGameDataRevision,
} from '../../../core/game-data/game-data-state';
import { warLeaguesByApiId } from '../../../core/game-data/game-data-normalization';
import { useLinkParameters, linkChoice } from '../../../core/deep-links/link-parameters';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  CardStatsFooter,
  EmptyState,
  MobileWebImage,
  ProfileTabs,
  SelectionPicker,
  Surface,
  SkeletonContent,
  useSkeletonContent,
  useCKTheme,
} from '../../../ui';
import { HeaderIconButton } from '../../../ui/header';
import { ckColors, ckSpacing, colorWithAlpha } from '../../../ui/tokens';
import { PagerView, type PagerViewHandle } from '../../../ui/pager';
import { usePrimarySwipeGuard } from '../../../ui/primary-swipe-guard';
import { CwlLeagueBackdrop } from './cwl-league-backdrop';
import { CompactWarScoreboard } from './war-components';
import type { CwlClan, CwlMember, WarCwl, WarInfo } from '../models';
import {
  cwlOutlook,
  cwlCoverage,
  cwlFinished,
  cwlStandings,
  remainingCwlOpponents,
  type CwlStanding,
} from '../models/cwl-outlook';
import type { WarPresentationActions } from './contracts';
import { loadingCwl } from './war-loading-model';
import { formatPercent, sortCwlMembers, warTimeRemaining } from './presentation-utils';
import { TownHallBreakdown, WarLineupComparison } from './town-hall-breakdown';

type CwlTab = 'rounds' | 'teams' | 'members';
export function CwlScreen({
  clanTag,
  summary: sourceSummary,
  warLeagueName,
  actions,
  onBack,
  onOpenWar,
  loading = false,
  failed = false,
  refreshing = false,
  onRefresh,
  placeholder = false,
}: {
  clanTag: string;
  summary: WarCwl;
  warLeagueName?: string | null;
  actions: WarPresentationActions;
  onBack: () => void;
  onOpenWar: (war: WarInfo, round: number) => void;
  loading?: boolean;
  failed?: boolean;
  refreshing?: boolean;
  onRefresh?: () => void;
  placeholder?: boolean;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const placeholderIdentity =
    placeholder || (loading && !sourceSummary.leagueInfo?.getClanDetails(clanTag));
  const summary =
    loading && !sourceSummary.leagueInfo?.getClanDetails(clanTag)
      ? loadingCwl(clanTag)
      : sourceSummary;
  const link = useLinkParameters();
  const [tab, setTab] = useState<CwlTab>(
    linkChoice(link.tab, ['rounds', 'teams', 'members'], 'rounds'),
  );
  const [perspectiveSelection, setPerspectiveSelection] = useState({
    origin: clanTag,
    tag: clanTag,
  });
  const perspective = perspectiveSelection.origin === clanTag ? perspectiveSelection.tag : clanTag;
  const setPerspective = (tag: string) => setPerspectiveSelection({ origin: clanTag, tag });
  const [pageHeights, setPageHeights] = useState<Partial<Record<CwlTab, number>>>({});
  const pager = useRef<PagerViewHandle>(null);
  const [tabPosition] = useState(
    () => new Animated.Value(['rounds', 'teams', 'members'].indexOf(tab)),
  );
  const [reduceMotion, setReduceMotion] = useState(false);
  useEffect(() => {
    let active = true;
    void AccessibilityInfo.isReduceMotionEnabled().then((value) => {
      if (active) setReduceMotion(value);
    });
    const listener = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduceMotion);
    return () => {
      active = false;
      listener.remove();
    };
  }, []);
  const [pagerSwipeEnabled, setPagerSwipeEnabled] = useState(true);
  const blockPrimarySwipe = usePrimarySwipeGuard();
  useEffect(() => () => blockPrimarySwipe(false), [blockPrimarySwipe]);
  const scroll = useRef<ScrollViewInstance>(null);
  const scrollY = useRef(0);
  const headerHeight = useRef(0);
  const tabStart = useRef(0);
  useEffect(() => {
    const frame = requestAnimationFrame(() =>
      scroll.current?.scrollTo({ y: tabStart.current, animated: false }),
    );
    return () => cancelAnimationFrame(frame);
  }, [tab]);
  const clan = summary.leagueInfo?.getClanDetails(perspective);
  const standings = useMemo(() => cwlStandings(summary), [summary]);
  const coverage = cwlCoverage(summary);
  const standing = standings.find((row) => row.tag === perspective);
  const select = (key: string) => {
    tabStart.current = Math.max(0, Math.min(scrollY.current, headerHeight.current));
    setTab(key as CwlTab);
  };
  if (!clan)
    return (
      <SafeAreaView style={{ flex: 1, backgroundColor: theme.background }}>
        <EmptyState
          title={t('generalNoDataAvailable')}
          actionLabel={materialBackLabel(locale)}
          onAction={onBack}
        />
      </SafeAreaView>
    );
  return (
    <SafeAreaView edges={['left', 'right']} style={{ flex: 1, backgroundColor: theme.background }}>
      <ScrollView
        ref={scroll}
        stickyHeaderIndices={[1]}
        scrollEventThrottle={100}
        onScroll={(event) => {
          scrollY.current = event.nativeEvent.contentOffset.y;
        }}
        contentContainerStyle={{ paddingBottom: insets.bottom + ckSpacing.xl }}
        refreshControl={
          onRefresh ? (
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor={theme.onSurface}
            />
          ) : undefined
        }
      >
        <View
          onLayout={(event) => {
            headerHeight.current = event.nativeEvent.layout.height;
          }}
        >
          <CwlHero
            topInset={insets.top}
            loading={placeholderIdentity}
            clan={clan}
            season={summary.leagueInfo?.season}
            league={warLeagueName ?? summary.leagueInfo?.warLeagueName}
            standing={standing}
            totalRounds={(summary.leagueInfo?.clans.length ?? 1) - 1}
            clans={summary.leagueInfo?.clans ?? []}
            onSelectClan={setPerspective}
            navigation={
              <View style={styles.actions}>
                <HeaderIconButton
                  icon={<ArrowLeft color="#fff" size={24} />}
                  label={materialBackLabel(locale)}
                  onPress={onBack}
                  glass={false}
                />
                <View style={styles.grow} />
                {actions.exportCwl &&
                summary.leagueInfo?.season.slice(0, 7) === new Date().toISOString().slice(0, 7) ? (
                  <HeaderIconButton
                    icon={
                      Platform.OS === 'web' ? (
                        <Download color="#fff" size={24} />
                      ) : (
                        <Share2 color="#fff" size={24} />
                      )
                    }
                    label={Platform.OS === 'web' ? t('downloadTooltip') : t('gameAssetsShare')}
                    onPress={() => void actions.exportCwl!(perspective)}
                    glass={false}
                  />
                ) : null}
              </View>
            }
          />
        </View>
        <View style={[styles.tabs, { backgroundColor: theme.background }]}>
          <ProfileTabs
            variant="underline"
            animatedPosition={tabPosition}
            indicatorRtl={isRtl}
            selectedKey={tab}
            onSelect={(key) => {
              select(key);
              const index = ['rounds', 'teams', 'members'].indexOf(key);
              if (reduceMotion) pager.current?.setPageWithoutAnimation(index);
              else pager.current?.setPage(index);
            }}
            tabs={[
              {
                key: 'rounds',
                label: t('cwlMatches'),
                icon: (
                  <MobileWebImage imageUrl={ImageAssets.cwlSwordsNoBorder} style={styles.tabIcon} />
                ),
              },
              {
                key: 'teams',
                label: t('esportsStandings'),
                icon: <MobileWebImage imageUrl={ImageAssets.podium} style={styles.tabIcon} />,
              },
              {
                key: 'members',
                label: t('warPlayersTitle'),
                icon: <MobileWebImage imageUrl={ImageAssets.sword} style={styles.tabIcon} />,
              },
            ]}
          />
        </View>
        <View style={styles.content}>
          {!loading && !coverage.complete ? (
            <Surface
              style={[styles.coverage, { backgroundColor: colorWithAlpha(ckColors.warGold, 0.09) }]}
            >
              <Info size={18} color={theme.onSurfaceVariant} />
              <View style={styles.grow}>
                <CKText role="body">
                  {t('cwlArchiveCoverage', {
                    available: coverage.available,
                    total: coverage.expected,
                  })}
                </CKText>
                <CKText role="metadata" muted>
                  {t('cwlStandingsIncomplete')}
                </CKText>
              </View>
            </Surface>
          ) : null}
          {loading ? (
            <SkeletonContent loading>
              {tab === 'rounds' ? (
                <CwlMatches
                  summary={loadingCwl(perspective)}
                  clanTag={perspective}
                  onOpenWar={onOpenWar}
                />
              ) : tab === 'teams' ? (
                <CwlClans
                  summary={loadingCwl(perspective)}
                  clanTag={perspective}
                  standings={cwlStandings(loadingCwl(perspective))}
                  actions={actions}
                  league={warLeagueName}
                />
              ) : (
                <CwlPlayers
                  summary={loadingCwl(perspective)}
                  clanTag={perspective}
                  actions={actions}
                />
              )}
            </SkeletonContent>
          ) : failed ? (
            <EmptyState
              title={t('errorNetworkTitle')}
              actionLabel={t('generalRetry')}
              onAction={onRefresh}
            />
          ) : (
            <View
              onTouchStart={() => blockPrimarySwipe(true)}
              onTouchEnd={() => blockPrimarySwipe(false)}
              onTouchCancel={() => blockPrimarySwipe(false)}
            >
              <PagerView
                ref={pager}
                initialPage={['rounds', 'teams', 'members'].indexOf(tab)}
                scrollEnabled={pagerSwipeEnabled}
                layoutDirection={isRtl ? 'rtl' : 'ltr'}
                onPageScroll={(event) =>
                  tabPosition.setValue(event.nativeEvent.position + event.nativeEvent.offset)
                }
                style={{ height: pageHeights[tab] ?? 600 }}
                onPageSelected={(event) =>
                  select(['rounds', 'teams', 'members'][event.nativeEvent.position]!)
                }
              >
                {(['rounds', 'teams', 'members'] as const).map((key) => (
                  <View key={key} collapsable={false} style={{ flex: 1 }}>
                    <View
                      onLayout={(event) => {
                        const height = Math.ceil(event.nativeEvent.layout.height);
                        if (height > 0)
                          setPageHeights((old) =>
                            old[key] === height ? old : { ...old, [key]: height },
                          );
                      }}
                    >
                      {/* Adjacent pages must already exist while the finger moves the pager. */}
                      {
                        <>
                          {key === 'rounds' ? (
                            <CwlMatches
                              key={perspective}
                              summary={summary}
                              clanTag={perspective}
                              onOpenWar={onOpenWar}
                              onRoundInteraction={(active) => setPagerSwipeEnabled(!active)}
                            />
                          ) : key === 'teams' ? (
                            <CwlClans
                              summary={summary}
                              clanTag={perspective}
                              standings={standings}
                              actions={actions}
                              league={warLeagueName ?? summary.leagueInfo?.warLeagueName}
                            />
                          ) : (
                            <CwlPlayers summary={summary} clanTag={perspective} actions={actions} />
                          )}
                        </>
                      }
                    </View>
                  </View>
                ))}
              </PagerView>
            </View>
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}
function CwlHero({
  topInset,
  clan,
  season,
  league,
  navigation,
  standing,
  totalRounds,
  clans,
  onSelectClan,
  loading = false,
}: {
  topInset: number;
  clan: CwlClan;
  season?: string;
  league?: string | null;
  navigation: ReactNode;
  standing?: CwlStanding;
  totalRounds: number;
  clans: readonly CwlClan[];
  onSelectClan: (tag: string) => void;
  loading?: boolean;
}) {
  const { t, locale } = useI18n();
  const match = /^(\d{4})-(\d{2})/.exec(season ?? '');
  const date = match
    ? new Date(Number(match[1]), Number(match[2]) - 1, 1).toLocaleDateString(toIntlLocale(locale), {
        month: 'long',
        year: 'numeric',
      })
    : season;
  const theme = useCKTheme();
  return (
    // Apply the status-bar inset to content, not the screen container, so the
    // backdrop also covers the safe area instead of leaving a black strip.
    <View style={[styles.hero, { backgroundColor: theme.background, paddingTop: topInset }]}>
      <CwlLeagueBackdrop league={league} />
      {navigation}
      <SkeletonContent loading={loading}>
        <View style={styles.identity}>
          <View style={styles.heroHeading}>
            <MobileWebImage
              imageUrl={ImageAssets.getWarLeagueImage(league ?? '')}
              style={styles.heroBadge}
            />
            <View style={styles.heroTitleGroup}>
              <CKText
                role="screenTitle"
                numberOfLines={2}
                style={[styles.heroText, { color: theme.onSurface }]}
              >
                {league ?? t('cwlTitle')}
              </CKText>
              <View style={styles.league}>
                <CKText role="bodyMedium" style={styles.heroDate}>
                  {date}
                </CKText>
              </View>
            </View>
          </View>
          <View style={{ maxWidth: 320, alignSelf: 'center' }}>
            <SelectionPicker
              plain
              wrapLabel
              title={t('searchTabClans')}
              selectedKey={clan.tag}
              onSelect={onSelectClan}
              options={clans.map((item) => ({
                key: item.tag,
                label: item.name,
                icon: (
                  <MobileWebImage imageUrl={item.badgeUrls.smallest} style={styles.smallBadge} />
                ),
              }))}
            />
          </View>
        </View>
        {standing ? (
          <View style={styles.heroMetrics}>
            <HeroMetric
              label={t('cwlRankTitle')}
              value={standing.rank ? `#${standing.rank}` : '—'}
              image={ImageAssets.podium}
            />
            <HeroMetric
              label={t('warStarsTitle')}
              value={String(standing.stars)}
              image={ImageAssets.attackStar}
            />
            <HeroMetric
              label={t('warWinsTitle')}
              value={`${standing.wins}/${totalRounds}`}
              image={ImageAssets.cwlSwordsNoBorder}
            />
          </View>
        ) : null}
      </SkeletonContent>
    </View>
  );
}
function HeroMetric({ label, value, image }: { label: string; value: string; image?: string }) {
  const theme = useCKTheme();
  return (
    <View style={styles.heroMetric}>
      <View style={styles.metricValue}>
        {image ? <MobileWebImage imageUrl={image} style={styles.metricIcon} /> : null}
        <CKText role="titleSmall" style={{ color: theme.onSurface, fontVariant: ['tabular-nums'] }}>
          {value}
        </CKText>
      </View>
      <CKText role="metadata" muted>
        {label}
      </CKText>
    </View>
  );
}
const CwlMatches = memo(function CwlMatches({
  summary,
  clanTag,
  onOpenWar,
  onRoundInteraction,
}: {
  summary: WarCwl;
  clanTag: string;
  onOpenWar: (war: WarInfo, round: number) => void;
  onRoundInteraction?: (active: boolean) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const loading = useSkeletonContent();
  const link = useLinkParameters();
  const rounds = summary.leagueInfo?.rounds ?? [];
  const active = summary.getActiveWarByTag(clanTag);
  const initial = Number(link.round) || summary.getRoundForWarTag(active?.tag ?? null).roundNumber;
  const [selected, setSelected] = useState(String(initial));
  const [lineup, setLineup] = useState(false);
  const roundRail = useRef<ScrollViewInstance>(null);
  const index = Math.max(
    0,
    rounds.findIndex((round) => String(round.roundNumber) === selected),
  );
  const round = rounds[index];
  const wars =
    round?.warTags
      .map((tag) => summary.getWarInfoFromTag(tag))
      .filter((war) => war.clan && war.opponent) ?? [];
  const ours = wars
    .find((war) => war.clan?.tag === clanTag || war.opponent?.tag === clanTag)
    ?.reorderForClan(clanTag);
  const next = summary.warLeagueInfos
    .find(
      (war) =>
        war.state === 'preparation' &&
        war.tag !== active?.tag &&
        (war.clan?.tag === clanTag || war.opponent?.tag === clanTag),
    )
    ?.reorderForClan(clanTag);
  const select = (key: string) => {
    setSelected(key);
    setLineup(false);
  };
  const others = wars.filter((war) => war.tag !== ours?.tag);
  const missing = (round?.warTags.filter((tag) => tag !== '#0').length ?? 0) - wars.length;
  const selectedResult = ours ? matchState(ours, t) : null;
  return (
    <View style={styles.stack}>
      <View style={styles.sectionHeading}>
        <CKText skeleton={false} role="sectionTitle">
          {t('cwlRounds')}
        </CKText>
        <CKText role="metadata" muted>
          {t('cwlRoundNumber', { number: round?.roundNumber ?? 1 })}
        </CKText>
      </View>
      <ScrollView
        horizontal
        // Horizontal round browsing must not also switch the main CWL section.
        onTouchStart={() => onRoundInteraction?.(true)}
        onTouchEnd={() => onRoundInteraction?.(false)}
        onTouchCancel={() => onRoundInteraction?.(false)}
        style={{ flexGrow: 0 }}
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.roundRail}
        onContentSizeChange={() => roundRail.current?.scrollTo({ x: index * 76, animated: false })}
        ref={roundRail}
      >
        {rounds.map((item) => {
          const war = item.warTags
            .map((tag) => summary.getWarInfoFromTag(tag))
            .find((war) => war.clan?.tag === clanTag || war.opponent?.tag === clanTag)
            ?.reorderForClan(clanTag);
          const picked = item.roundNumber === round?.roundNumber;
          const score =
            war && war.state !== 'preparation' ? `${war.clan?.stars}–${war.opponent?.stars}` : '—';
          const result = war ? matchState(war, t) : null;
          return (
            <Pressable
              key={item.roundNumber}
              accessibilityRole="tab"
              accessibilityLabel={`${t('cwlRoundNumber', { number: item.roundNumber })}: ${score}${result ? `, ${result.label}` : ''}`}
              accessibilityState={{ selected: picked }}
              onPress={() => select(String(item.roundNumber))}
              style={[
                styles.roundTile,
                {
                  // White scores need a dark base even in light mode. The
                  // result tint belongs to the tile, not individual digits.
                  backgroundColor: loading ? theme.surfaceContainerHighest : '#0B0B0C',
                },
              ]}
            >
              <View
                pointerEvents="none"
                style={[
                  StyleSheet.absoluteFill,
                  {
                    // Selection is the white marker, not another outcome
                    // color. Keep every round's result equally readable.
                    // Placeholder scores do not represent a draw or any other
                    // result. Reserve outcome colors for the loaded rounds.
                    backgroundColor: loading
                      ? theme.surfaceContainerHighest
                      : colorWithAlpha(result?.color ?? '#757575', 0.55),
                  },
                ]}
              />
              <CKText role="metadata" style={{ color: '#FFFFFF' }}>
                {t('cwlRoundShort', { round: item.roundNumber })}
              </CKText>
              <View style={styles.metricValue}>
                <MobileWebImage
                  imageUrl={ImageAssets.attackStar}
                  style={{ width: 12, height: 12 }}
                />
                <CKText role="rowTitle" style={[styles.numeric, { color: '#FFFFFF' }]}>
                  {score}
                </CKText>
              </View>
              {picked && !loading ? (
                <View style={[styles.roundMarker, { backgroundColor: '#FFFFFF' }]} />
              ) : null}
            </Pressable>
          );
        })}
      </ScrollView>
      {ours ? (
        <Surface
          style={[
            styles.section,
            styles.featuredMatch,
            {
              backgroundColor: theme.card,
              borderWidth: 1,
              borderColor: colorWithAlpha(
                loading ? theme.outlineVariant : (selectedResult?.color ?? theme.outlineVariant),
                0.7,
              ),
              overflow: 'hidden',
            },
          ]}
        >
          <View style={[styles.sectionHeading, { minHeight: 44 }]}>
            {/* Keep the leading slot when an ended war has no countdown. */}
            <View style={styles.grow}>
              <CwlBattleTime war={ours} />
            </View>
            <Pressable
              accessibilityRole="button"
              onPress={() => onOpenWar(ours, round!.roundNumber)}
              style={[styles.detailLink, { marginLeft: 'auto' }]}
            >
              <CKText skeleton={false} role="metadata">
                {t('generalDetails')}
              </CKText>
              <ChevronRight size={18} color={theme.onSurfaceVariant} />
            </Pressable>
          </View>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={`${ours.clan?.name} · ${ours.opponent?.name}`}
            onPress={() => onOpenWar(ours, round!.roundNumber)}
          >
            <CwlScoreboard war={ours} featured />
          </Pressable>
          <View style={styles.sectionHeading}>
            <Disclosure
              label={t('statsTownHallDistribution')}
              expanded={lineup}
              onPress={() => setLineup((value) => !value)}
            />
          </View>
          {lineup ? <WarLineupComparison war={ours} showNames={false} compact /> : null}
        </Surface>
      ) : (
        <EmptyState title={t('generalNoDataAvailable')} />
      )}
      {next && ours?.tag === active?.tag ? (
        <View style={styles.stack}>
          <CKText skeleton={false} role="sectionTitle">
            {t('cwlNextMatchup')}
          </CKText>
          <MatchRow
            war={next}
            onPress={() => onOpenWar(next, summary.getRoundForWarTag(next.tag).roundNumber)}
          />
          <WarLineupComparison war={next} showNames={false} compact />
        </View>
      ) : null}
      {others.length ? (
        <View style={styles.stack}>
          <CKText skeleton={false} role="sectionTitle">
            {t('cwlOtherMatches')}
          </CKText>
          {others.map((war) => (
            <MatchRow key={war.tag} war={war} onPress={() => onOpenWar(war, round!.roundNumber)} />
          ))}
        </View>
      ) : null}
      {missing > 0 ? (
        <CKText role="metadata" muted>
          {t('cwlMissingMatchups', { count: missing })}
        </CKText>
      ) : null}
    </View>
  );
});
/** Result labels remain provisional until the service marks the war as ended. */
function matchState(war: WarInfo, t: ReturnType<typeof useI18n>['t']) {
  const delta =
    (war.clan?.stars ?? 0) - (war.opponent?.stars ?? 0) ||
    (war.clan?.destructionPercentage ?? 0) - (war.opponent?.destructionPercentage ?? 0);
  const active = war.state === 'inWar';
  return {
    color:
      war.state === 'preparation'
        ? ckColors.builderBlue
        : delta > 0
          ? ckColors.donationGreen
          : delta < 0
            ? ckColors.lossRed
            : ckColors.capitalPurple,
    delta,
    label:
      war.state === 'preparation'
        ? t('warPreparation')
        : active
          ? delta > 0
            ? t('cwlLeading')
            : delta < 0
              ? t('cwlTrailing')
              : t('warClanDraw')
          : delta > 0
            ? t('warVictory')
            : delta < 0
              ? t('warDefeat')
              : t('warDraw'),
  };
}
function CwlBattleTime({ war }: { war: WarInfo }) {
  const { locale } = useI18n();
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 30_000);
    return () => clearInterval(id);
  }, []);
  const end = war.state === 'preparation' ? war.startTime : war.endTime;
  return end && war.state !== 'warEnded' ? (
    <CKText role="metadata" muted>
      {warTimeRemaining(end, now, locale)}
    </CKText>
  ) : null;
}
function leadingSideFirst(war: WarInfo): WarInfo {
  if (war.state === 'preparation' || !war.clan || !war.opponent) return war;
  const delta =
    war.clan.stars - war.opponent.stars ||
    war.clan.destructionPercentage - war.opponent.destructionPercentage;
  // Only reorder the schedule. The featured card must keep the chosen clan perspective.
  return delta < 0 ? war.reorderForClan(war.opponent.tag) : war;
}
function CwlScoreboard({ war: inputWar, featured = false }: { war: WarInfo; featured?: boolean }) {
  const war = featured ? inputWar : leadingSideFirst(inputWar);
  const { t } = useI18n();
  const theme = useCKTheme();
  const result = matchState(war, t);
  const sideColor = (index: number) =>
    war.state === 'preparation'
      ? theme.onSurface
      : result.delta === 0
        ? ckColors.capitalPurple
        : (index === 0 ? result.delta > 0 : result.delta < 0)
          ? ckColors.donationGreen
          : ckColors.lossRed;
  return (
    <CompactWarScoreboard
      war={war}
      leftColor={featured ? undefined : sideColor(0)}
      rightColor={featured ? undefined : sideColor(1)}
      aboveScore={
        featured ? (
          <View style={[styles.resultPill, { backgroundColor: '#000000B8' }]}>
            <CKText role="metadata" style={{ color: '#FFFFFF', textAlign: 'center' }}>
              {result.label}
            </CKText>
          </View>
        ) : undefined
      }
    />
  );
}
function MatchRow({ war, onPress }: { war: WarInfo; onPress: () => void }) {
  return (
    <Surface style={styles.scheduleSurface}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${war.clan?.name} ${war.clan?.stars} · ${war.opponent?.name} ${war.opponent?.stars}`}
        onPress={onPress}
        style={{ padding: 8 }}
      >
        <CwlScoreboard war={war} />
      </Pressable>
    </Surface>
  );
}
const CwlClans = memo(function CwlClans({
  summary,
  clanTag,
  standings,
  actions,
  league,
}: {
  summary: WarCwl;
  clanTag: string;
  standings: CwlStanding[];
  actions: WarPresentationActions;
  league?: string | null;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState<string>();
  useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => gameDataState.revision,
  );
  const rule = [...warLeaguesByApiId().values()].find((value) => value.name === league);
  const promotions = typeof rule?.promotions === 'number' ? rule.promotions : 0;
  const demotions = typeof rule?.demotions === 'number' ? rule.demotions : 0;
  return (
    <View style={styles.stack}>
      {standings.map((standing) => {
        const clan = summary.leagueInfo!.getClanDetails(standing.tag)!;
        const selected = clan.tag === clanTag;
        const tied = standings.filter((row) => row.rank === standing.rank).length;
        // A tie crossing a cutoff is not a secured promotion.
        const promoting = standing.rank > 0 && standing.rank + tied - 1 <= promotions;
        const demoting = standing.rank > standings.length - demotions;
        const zoneColor = promoting
          ? ckColors.donationGreen
          : demoting
            ? ckColors.lossRed
            : theme.onSurfaceVariant;
        return (
          <Surface
            key={clan.tag}
            style={[
              styles.clanStandingCard,
              {
                backgroundColor: selected ? colorWithAlpha(ckColors.builderBlue, 0.1) : theme.card,
              },
            ]}
          >
            <View style={[styles.clanHeading, styles.clanStandingHeading]}>
              <CKText role="titleSmall" style={[styles.rank, { color: zoneColor }]}>
                {standing.rank || '—'}
              </CKText>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={clan.name}
                onPress={() => actions.openClan(clan.tag)}
                style={styles.entityLink}
              >
                <MobileWebImage imageUrl={clan.badgeUrls.smallest} style={styles.clanBadge} />
              </Pressable>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={clan.name}
                accessibilityState={{ expanded: expanded === clan.tag }}
                onPress={() => setExpanded(expanded === clan.tag ? undefined : clan.tag)}
                style={[styles.clanHeading, styles.grow]}
              >
                <View style={styles.grow}>
                  <CKText role="rowTitle">{clan.name}</CKText>
                  {promoting || demoting ? (
                    <CKText role="metadata" style={{ color: zoneColor }}>
                      {promoting ? '↑ ' : '↓ '}
                      {t(promoting ? 'cwlPromotionZone' : 'cwlDemotionZone')}
                    </CKText>
                  ) : null}
                </View>
                {expanded === clan.tag ? (
                  <ChevronUp size={17} color={theme.onSurfaceVariant} />
                ) : (
                  <ChevronDown size={17} color={theme.onSurfaceVariant} />
                )}
              </Pressable>
            </View>
            <CardStatsFooter>
              <View style={styles.metricValue}>
                <MobileWebImage imageUrl={ImageAssets.attackStar} style={styles.metricIcon} />
                <CKText role="body">
                  {standing.stars}{' '}
                  <CKText skeleton={false} role="metadata" muted>
                    {t('warStarsTitle')}
                  </CKText>
                </CKText>
              </View>
              <View style={styles.metricValue}>
                <MobileWebImage
                  imageUrl={ImageAssets.cwlSwordsNoBorder}
                  style={styles.metricIcon}
                />
                <CKText role="body">
                  {standing.wins}{' '}
                  <CKText skeleton={false} role="metadata" muted>
                    {t('warWinsTitle')}
                  </CKText>
                </CKText>
              </View>
              <CKText role="body">{formatPercent(standing.destruction, 1)}</CKText>
            </CardStatsFooter>
            {expanded === clan.tag ? (
              <View style={styles.compactClanDetail}>
                <View style={styles.performanceRow}>
                  <Metric label={t('esportsTriples')} value={String(clan.threeStars)} />
                  <Metric label={t('warAttacksTitle')} value={String(clan.attackCount)} />
                  <Metric label={t('warAttacksMissedShort')} value={String(clan.missedAttacks)} />
                </View>
                <TownHallBreakdown members={clan.members} compact />
              </View>
            ) : null}
          </Surface>
        );
      })}
      {!cwlFinished(summary) ? (
        <SeasonOutlook summary={summary} clanTag={clanTag} standings={standings} league={league} />
      ) : null}
    </View>
  );
});
function formatForecast(chance: number) {
  // A bootstrap sample cannot prove certainty. Reserve 0/100 for exact outcomes.
  if (chance < 0.01) return '<1%';
  if (chance > 0.99) return '>99%';
  return formatPercent(chance * 100, 0);
}
function Metric({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.metric}>
      <CKText role="titleSmall" style={[styles.numeric, { textAlign: 'center' }]}>
        {value}
      </CKText>
      <CKText role="metadata" muted style={{ textAlign: 'center' }}>
        {label}
      </CKText>
    </View>
  );
}
function SeasonOutlook({
  summary,
  clanTag,
  standings,
  league,
}: {
  summary: WarCwl;
  clanTag: string;
  standings: CwlStanding[];
  league?: string | null;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const revision = useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => gameDataState.revision,
  );
  const promotions = useMemo(() => {
    // Static metadata refreshes independently of the CWL response.
    void revision;
    // Use the loaded game rules, never assume that every league promotes two.
    const rule = [...warLeaguesByApiId().values()].find((value) => value.name === league);
    return rule &&
      typeof rule.promotions === 'number' &&
      Number.isInteger(rule.promotions) &&
      rule.promotions >= 0
      ? rule.promotions
      : undefined;
  }, [league, revision]);
  const [show, setShow] = useState(false);
  const [forecast, setForecast] = useState<{
    summary: WarCwl;
    promotions: number | undefined;
    rows: CwlStanding[];
  }>();
  const finished = cwlFinished(summary);
  const coverage = cwlCoverage(summary);
  useEffect(() => {
    if (finished || !coverage.complete || promotions === 0) return;
    const timer = setTimeout(
      () => setForecast({ summary, promotions, rows: cwlOutlook(summary, promotions) }),
      0,
    );
    return () => clearTimeout(timer);
  }, [summary, promotions, finished, coverage.complete]);
  const projected =
    forecast?.summary === summary && forecast.promotions === promotions
      ? forecast.rows.find((row) => row.tag === clanTag)
      : null;
  const standing = standings.find((row) => row.tag === clanTag);
  const remaining = remainingCwlOpponents(summary, clanTag);
  const clan = summary.leagueInfo?.getClanDetails(clanTag);
  return (
    <Surface style={styles.section}>
      <View style={styles.sectionHeading}>
        <CKText role="sectionTitle">{finished ? t('cwlSeasonFinished') : t('cwlOutlook')}</CKText>
        {!finished ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('generalDetails')}
            accessibilityState={{ expanded: show }}
            onPress={() => setShow(!show)}
            style={styles.smallAction}
          >
            <Info size={20} color={theme.onSurfaceVariant} />
          </Pressable>
        ) : null}
      </View>
      <View style={styles.performanceRow}>
        <Metric
          label={t('warStarsAverage')}
          value={clan?.attackCount ? clan.averageStars.toFixed(2) : '—'}
        />
        <Metric
          label={t('playerBattlelogTripleRate')}
          value={
            clan?.attackCount ? formatPercent((clan.threeStars / clan.attackCount) * 100, 1) : '—'
          }
        />
        <Metric label={t('warAttacksMissed')} value={String(clan?.missedAttacks ?? 0)} />
      </View>
      {!finished && coverage.complete ? (
        <>
          <View style={styles.sectionHeading}>
            <View style={styles.grow}>
              <CKText role="body">
                {promotions === 0
                  ? t('cwlHighestLeague')
                  : promotions !== undefined
                    ? t('cwlPromotionChance')
                    : t('cwlFirstPlace')}
              </CKText>
              <CKText role="metadata" muted>
                {promotions && promotions > 0
                  ? t('cwlPromotionPlaces', { count: promotions })
                  : t('capitalRaidEstimated')}
              </CKText>
            </View>
            {promotions !== 0 ? (
              <CKText role="titleLarge" style={styles.numeric}>
                {projected?.firstChance !== null && projected?.firstChance !== undefined
                  ? formatForecast(projected.promotionChance ?? projected.firstChance)
                  : '—'}
              </CKText>
            ) : null}
          </View>
          {projected && projected.firstChance === null ? (
            <CKText role="metadata" muted>
              {t('cwlForecastWaiting')}
            </CKText>
          ) : null}
        </>
      ) : null}
      <CKText role="metadata" muted>
        {coverage.complete
          ? t('cwlSeasonProgress', {
              played: standing?.played ?? 0,
              total: (summary.leagueInfo?.clans.length ?? 1) - 1,
            })
          : t('cwlRecordedStats')}
      </CKText>
      {show ? (
        <View style={styles.stack}>
          <CKText role="metadata" muted>
            {t('cwlEstimateNote')}
          </CKText>
          {remaining.length ? (
            <CKText skeleton={false} role="rowTitle">
              {t('cwlRemainingOpponents')}
            </CKText>
          ) : null}
          {remaining.map((opponent) => (
            <View key={opponent.tag} style={styles.clanHeading}>
              <MobileWebImage imageUrl={opponent.badgeUrls.smallest} style={styles.smallBadge} />
              <CKText style={styles.grow}>{opponent.name}</CKText>
            </View>
          ))}
        </View>
      ) : null}
    </Surface>
  );
}
const CwlPlayers = memo(function CwlPlayers({
  summary,
  clanTag,
  actions,
}: {
  summary: WarCwl;
  clanTag: string;
  actions: WarPresentationActions;
}) {
  const clan = summary.leagueInfo?.getClanDetails(clanTag);
  return clan ? (
    <StarLeaderboard
      key={clanTag}
      members={clan.members}
      actions={actions}
      summary={summary}
      clanTag={clanTag}
    />
  ) : null;
});
const StarLeaderboard = memo(function StarLeaderboard({
  members,
  actions,
  summary,
  clanTag,
}: {
  members: readonly CwlMember[];
  actions: WarPresentationActions;
  summary: WarCwl;
  clanTag: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState<string>();
  const ranking = useMemo(() => sortCwlMembers(members, 'stars'), [members]);
  return (
    <View style={styles.stack}>
      {ranking.map((member, index) => {
        const missed = member.attackStats?.missedAttacks ?? 0;
        return (
          <Surface key={member.tag} style={styles.standingCard}>
            <View style={styles.playerHeading}>
              <CKText role="metadata" muted style={styles.rank}>
                {index + 1}
              </CKText>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={member.name}
                onPress={() => actions.openPlayer(member.tag)}
                style={styles.entityLink}
              >
                <MobileWebImage
                  imageUrl={ImageAssets.townHall(member.townhallLevel)}
                  style={styles.clanBadge}
                />
              </Pressable>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={member.name}
                accessibilityState={{ expanded: expanded === member.tag }}
                onPress={() => setExpanded((old) => (old === member.tag ? undefined : member.tag))}
                style={[styles.playerHeading, styles.grow]}
              >
                <View style={styles.grow}>
                  <CKText role="rowTitle">{member.name}</CKText>
                  <View style={styles.playerSummaryLine}>
                    <CKText role="metadata" muted>
                      {member.attackStats?.attackCount ?? 0} {t('warAttacksTitle')}
                    </CKText>
                    {missed > 0 ? (
                      <CKText role="metadata" style={{ color: ckColors.lossRed }}>
                        × {missed} {t('warAttacksMissedShort')}
                      </CKText>
                    ) : null}
                  </View>
                </View>
                <View style={styles.metricValue}>
                  <CKText role="titleSmall">{member.attackStats?.stars ?? 0}</CKText>
                  <MobileWebImage imageUrl={ImageAssets.attackStar} style={styles.metricIcon} />
                </View>
                {expanded === member.tag ? (
                  <ChevronUp size={17} color={theme.onSurfaceVariant} />
                ) : (
                  <ChevronDown size={17} color={theme.onSurfaceVariant} />
                )}
              </Pressable>
            </View>
            {expanded === member.tag ? (
              <View style={styles.playerDetails}>
                <PlayerRoundList member={member} summary={summary} clanTag={clanTag} />
                <PlayerRoundList member={member} summary={summary} clanTag={clanTag} defending />
              </View>
            ) : null}
          </Surface>
        );
      })}
    </View>
  );
});
/** Round logs distinguish missing archives, unused attacks and absence from the lineup.
 * Defenses come from actual opponent attacks (including multiple attacks on one base);
 * a known bestOpponentAttack is only a fallback, never an invented defense result. */
function PlayerRoundList({
  member,
  summary,
  clanTag,
  defending = false,
}: {
  member: CwlMember;
  summary: WarCwl;
  clanTag: string;
  defending?: boolean;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={{ gap: 4 }}>
      <View style={[styles.sectionHeading, { marginBottom: 4, flexWrap: 'wrap' }]}>
        <CKText role="rowTitle">{t(defending ? 'warDefensesTitle' : 'warAttacksTitle')}</CKText>
        {!defending ? (
          <CKText role="metadata" muted>
            {member.threeStars} {t('esportsTriples')}
          </CKText>
        ) : null}
      </View>
      {summary.leagueInfo?.rounds.flatMap((round) => {
        const war = round.warTags
          .map((tag) => summary.getWarInfoFromTag(tag))
          .find((item) => item.clan?.tag === clanTag || item.opponent?.tag === clanTag)
          ?.reorderForClan(clanTag);
        const participant = war?.clan?.members.find((item) => item.tag === member.tag);
        const defenses =
          war?.opponent?.members
            .flatMap((item) => item.attacks ?? [])
            .filter((hit) => hit.defenderTag === member.tag) ?? [];
        const hits = defending
          ? defenses.length
            ? defenses
            : participant?.bestOpponentAttack
              ? [participant.bestOpponentAttack]
              : []
          : (participant?.attacks ?? []);
        const missed = !defending && !!participant && !hits.length && war?.state === 'warEnded';
        const emptyLabel = !war
          ? t('generalNoDataAvailable')
          : !participant
            ? t('cwlNotInLineup')
            : defending
              ? t('capitalRaidFilterNotAttacked')
              : missed
                ? t('warAttacksMissedShort')
                : t('warAttacksNone');
        const rows = hits.length ? hits : [null];
        return rows.map((hit, index) => {
          const otherTag = defending ? hit?.attackerTag : hit?.defenderTag;
          const other =
            war?.opponent?.members.find((item) => item.tag === otherTag) ??
            (defending ? hit?.attacker : hit?.defender);
          return (
            <View
              key={`${round.roundNumber}-${index}`}
              style={[
                styles.roundLogRow,
                missed && { backgroundColor: colorWithAlpha(ckColors.lossRed, 0.06) },
              ]}
              accessible
              accessibilityLabel={`${t('cwlRoundNumber', { number: round.roundNumber })}: ${hit ? `${other?.name ?? ''}, ${other?.townhallLevel ? t('gameTownHallLevelNumber', { level: other.townhallLevel }) : ''}, ${hit.stars} ${t('warStarsTitle')}, ${formatPercent(hit.destructionPercentage)}` : emptyLabel}`}
            >
              <CKText role="metadata" muted style={styles.roundLogLabel}>
                {t('cwlRoundShort', { round: round.roundNumber })}
              </CKText>
              {hit ? (
                <>
                  <View style={styles.roundTownHall}>
                    {other?.townhallLevel ? (
                      <>
                        <MobileWebImage
                          imageUrl={ImageAssets.townHall(other.townhallLevel)}
                          style={{ width: 28, height: 28 }}
                        />
                      </>
                    ) : (
                      <CKText muted>—</CKText>
                    )}
                  </View>
                  <CKText role="metadata" style={styles.grow}>
                    {other?.name ?? '—'}
                  </CKText>
                  <View style={styles.roundStars}>
                    {hit.stars > 0 ? (
                      Array.from({ length: hit.stars }, (_, star) => (
                        <MobileWebImage
                          key={star}
                          imageUrl={ImageAssets.attackStar}
                          style={{ width: 11, height: 11 }}
                        />
                      ))
                    ) : (
                      <CKText role="metadata">0</CKText>
                    )}
                  </View>
                  <CKText role="metadata" style={styles.roundPercent}>
                    {formatPercent(hit.destructionPercentage, 0)}
                  </CKText>
                </>
              ) : (
                <CKText
                  role="metadata"
                  style={[
                    styles.grow,
                    {
                      textAlign: 'right',
                      color: missed ? ckColors.lossRed : theme.onSurfaceVariant,
                    },
                  ]}
                >
                  {missed ? '× ' : '— '}
                  {emptyLabel}
                </CKText>
              )}
            </View>
          );
        });
      })}
    </View>
  );
}
function Disclosure({
  label,
  expanded,
  onPress,
}: {
  label: string;
  expanded: boolean;
  onPress: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ expanded }}
      onPress={onPress}
      style={styles.disclosure}
    >
      <CKText role="metadata" style={styles.grow}>
        {expanded ? t('generalCollapse') : label}
      </CKText>
      {expanded ? (
        <ChevronUp color={theme.onSurfaceVariant} size={22} />
      ) : (
        <ChevronDown color={theme.onSurfaceVariant} size={22} />
      )}
    </Pressable>
  );
}
export function hasCwlMemberStats(member: CwlMember) {
  return (member.attackStats?.attackCount ?? 0) > 0 || (member.defenseStats?.defenseCount ?? 0) > 0;
}
export function hasCwlClanStats(clan: CwlClan) {
  return clan.members.some(hasCwlMemberStats);
}
const styles = StyleSheet.create({
  // Every scoreboard row shares these two equal columns. Long names may grow
  // their row, but never shift the badge or numeric columns underneath it.
  scoreboardRow: { flexDirection: 'row', gap: 18, alignItems: 'stretch' },
  scoreboardHeader: { flexDirection: 'row', gap: 18, alignItems: 'center' },
  scoreboardColumn: { flex: 1, minWidth: 0, alignItems: 'center', justifyContent: 'center' },
  scoreboardScore: {
    position: 'absolute',
    left: '50%',
    top: 0,
    bottom: 0,
    width: 104,
    marginLeft: -52,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  matchAttackValue: { width: 88, position: 'relative', justifyContent: 'center', minHeight: 18 },
  matchAttackIcon: { width: 17, height: 17, position: 'absolute', left: -2 },
  matchNumber: { width: 88, textAlign: 'center', fontVariant: ['tabular-nums'] },
  entityLink: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  playerHeading: { flexDirection: 'row', alignItems: 'center', gap: 8, minHeight: 48 },
  playerSummaryLine: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    columnGap: 10,
    rowGap: 2,
  },
  compactClanDetail: { gap: 12, padding: 14 },
  roundLogRow: {
    flexDirection: 'row',
    gap: 6,
    alignItems: 'center',
    minHeight: 44,
    paddingVertical: 5,
    borderRadius: 8,
  },
  roundLogLabel: { width: 54 },
  roundTownHall: { width: 32, height: 32, alignItems: 'center', justifyContent: 'center' },
  roundStars: { width: 38, flexDirection: 'row', gap: 1, justifyContent: 'flex-end' },
  roundPercent: { width: 47, textAlign: 'right', fontVariant: ['tabular-nums'] },
  duelCenter: {
    position: 'absolute',
    left: '50%',
    marginLeft: -54,
    width: 108,
    top: 0,
    alignItems: 'center',
    gap: 8,
  },
  scheduleCenter: {
    position: 'absolute',
    left: '50%',
    marginLeft: -36,
    width: 72,
    top: 4,
    alignItems: 'center',
  },
  duelNames: { flexDirection: 'row', gap: 18 },
  resultPill: { borderRadius: 20, paddingVertical: 5, paddingHorizontal: 9 },
  compactScore: { fontSize: 22, lineHeight: 28, fontWeight: '700', fontVariant: ['tabular-nums'] },
  standingCard: { padding: 14, gap: 8, borderWidth: 0 },
  clanStandingCard: { borderWidth: 0, overflow: 'hidden' },
  clanStandingHeading: { padding: 14 },
  homeMark: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    borderRadius: 10,
    padding: 3,
    backgroundColor: '#2A9FD622',
  },
  detailLink: {
    minHeight: 44,
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
    justifyContent: 'flex-end',
  },
  grow: { flex: 1, minWidth: 0 },
  stack: { gap: ckSpacing.lg },
  // Keep scoreboards readable on tablets; the backdrop remains full bleed.
  content: { padding: ckSpacing.lg, width: '100%', maxWidth: 680, alignSelf: 'center', gap: 16 },
  tabs: {
    paddingHorizontal: ckSpacing.lg,
    paddingTop: 0,
    paddingBottom: ckSpacing.sm,
    width: '100%',
    maxWidth: 680,
    alignSelf: 'center',
  },
  hero: { overflow: 'hidden' },
  heroDate: {
    color: '#FFFFFF',
    fontSize: 15,
    lineHeight: 21,
    fontWeight: '600',
    textShadowColor: '#000000B3',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 3,
  },
  heroArtwork: { position: 'absolute', top: 0, left: 0, right: 0, height: 190 },
  tabIcon: { width: 22, height: 22 },
  // Grow only to the viewport: center rounds when they fit, retain scrolling
  // and the existing chip width when a narrow phone cannot show every round.
  roundRail: { gap: 8, paddingBottom: 2, flexGrow: 1, justifyContent: 'center' },
  roundTile: {
    width: 68,
    minHeight: 62,
    borderRadius: 16,
    padding: 8,
    gap: 6,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  roundMarker: { position: 'absolute', bottom: 0, width: 28, height: 3, borderRadius: 2 },
  featuredMatch: { paddingHorizontal: 16, paddingTop: 2, paddingBottom: 4, gap: 0 },
  duel: { flexDirection: 'row', gap: 110, position: 'relative', minHeight: 68 },
  duelSide: { flex: 1, minWidth: 0, alignItems: 'center', gap: 8 },
  duelBadge: { width: 62, height: 62 },
  duelName: { textAlign: 'center', flexShrink: 1 },
  duelScore: { fontSize: 30, lineHeight: 36, fontWeight: '700', fontVariant: ['tabular-nums'] },
  duelAttack: { flexDirection: 'row', gap: 6, alignItems: 'center' },
  duelVersus: { position: 'absolute', left: '50%', marginLeft: -15, top: 80 },
  progressTrack: { height: 4, borderRadius: 3, width: '100%', overflow: 'hidden' },
  scheduleSurface: { borderWidth: 0, borderRadius: 18 },
  scheduleMatch: { flexDirection: 'row', alignItems: 'flex-start', gap: 76, position: 'relative' },
  scheduleSide: { flex: 1, minWidth: 0, alignItems: 'center', gap: 6 },
  scheduleScore: { minWidth: 66, alignItems: 'center', gap: 4 },
  leagueTable: { borderWidth: 0, padding: 4 },
  tableHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 8,
    minHeight: 40,
  },
  tableRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 8,
    paddingVertical: 8,
    minHeight: 66,
  },
  tableRank: { width: 22, textAlign: 'center', fontVariant: ['tabular-nums'] },
  tableStars: {
    width: 40,
    textAlign: 'right',
    alignItems: 'flex-end',
    fontVariant: ['tabular-nums'],
  },
  tableRecord: { width: 36, textAlign: 'center', fontVariant: ['tabular-nums'] },
  tablePercent: { width: 47, textAlign: 'right', fontVariant: ['tabular-nums'] },
  tableBadge: { width: 28, height: 28 },
  tableDetail: { padding: 14, gap: 14 },
  openClan: {
    minHeight: 44,
    alignSelf: 'flex-end',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  heroText: { color: '#fff', fontSize: 23, lineHeight: 27, textAlign: 'center' },
  heroHeading: {
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    marginHorizontal: 24,
  },
  heroTitleGroup: { flexShrink: 1, alignItems: 'center', gap: 2 },
  heroSubtitle: { color: '#D9DBE7', textAlign: 'center' },
  heroIdentity: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 12 },
  heroMetrics: {
    flexDirection: 'row',
    alignSelf: 'stretch',
    justifyContent: 'center',
    gap: 12,
    marginTop: 0,
    paddingHorizontal: 16,
    paddingBottom: 4,
  },
  heroMetric: {
    flex: 1,
    maxWidth: 140,
    alignItems: 'center',
    gap: 2,
    paddingVertical: 3,
  },
  metricValue: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 5 },
  metricIcon: { width: 17, height: 17 },
  numeric: { fontVariant: ['tabular-nums'] },
  sectionHeading: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
  },
  coverage: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    padding: 14,
    borderWidth: 0,
  },
  performanceRow: { flexDirection: 'row', gap: 12 },
  metric: { flex: 1, gap: 4, alignItems: 'center' },
  smallAction: { minWidth: 44, minHeight: 44, alignItems: 'center', justifyContent: 'center' },
  playerSummary: { flexDirection: 'row', flexWrap: 'wrap', gap: 16, paddingLeft: 32 },
  roundResults: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  roundResult: {
    minWidth: 64,
    flexBasis: '22%',
    flexGrow: 1,
    alignItems: 'center',
    padding: 8,
    borderRadius: 12,
    gap: 4,
  },
  compactMatch: { flexDirection: 'row', gap: 10, alignItems: 'center' },
  remainingBadge: { padding: 6, borderRadius: 12, alignItems: 'center', minWidth: 56 },
  actions: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: ckSpacing.sm },
  identity: {
    alignItems: 'center',
    paddingHorizontal: ckSpacing.lg,
    paddingBottom: 6,
    paddingTop: 0,
    gap: 4,
  },
  heroBadge: { width: 72, height: 72 },
  league: {
    flexDirection: 'row',
    gap: ckSpacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    flexWrap: 'wrap',
  },
  leagueImage: { width: 22, height: 22 },
  loading: { padding: ckSpacing.xl, alignItems: 'center', gap: ckSpacing.lg },
  section: { padding: ckSpacing.lg, gap: 8, borderWidth: 0 },
  inline: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    flexWrap: 'wrap',
    gap: ckSpacing.sm,
  },
  roundNavigation: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm },
  arrow: {
    minWidth: 44,
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    gap: ckSpacing.sm,
  },
  matchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.sm,
    paddingVertical: ckSpacing.md,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  matchLine: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm, minHeight: 44 },
  smallBadge: { width: 28, height: 28 },
  clanBadge: { width: 40, height: 40 },
  percent: { width: 66, textAlign: 'right', fontVariant: ['tabular-nums'] },
  score: { width: 28, textAlign: 'right', fontVariant: ['tabular-nums'] },
  clanHeading: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm, minHeight: 52 },
  rank: { width: 24, textAlign: 'center' },
  playerRow: { padding: ckSpacing.md, borderRadius: 16 },
  playerDetails: { paddingTop: ckSpacing.lg, gap: ckSpacing.lg },
  starRow: { flexDirection: 'row', paddingVertical: ckSpacing.sm },
  starCell: { flex: 1, alignItems: 'center', gap: ckSpacing.xs },
  disclosure: { minHeight: 44, flexDirection: 'row', alignItems: 'center', gap: 4, flexShrink: 1 },
});
