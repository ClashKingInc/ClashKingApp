import { HeroHeaderScrim } from '../../../ui/hero-header-scrim';
import { HeaderArtwork } from '../../../ui/header-artwork';
import { modalOrientations } from '../../../ui/modal-orientations';
import {
  type ViewInstance,
  Animated,
  Alert,
  Modal,
  Platform,
  Pressable,
  RefreshControl,
  FlatList,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  useEffect,
  useMemo,
  useRef,
  useState,
  useSyncExternalStore,
  type RefObject,
  type ReactNode,
} from 'react';
import { useLinkParameters } from '../../../core/deep-links/link-parameters';
import {
  ArrowLeft,
  Bookmark,
  BookmarkCheck,
  ChartLine,
  CalendarDays,
  ChevronDown,
  ChevronRight,
  ExternalLink,
  History,
  X,
  LocateFixed,
  Share2,
  UsersRound,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { sharePageLink } from '../../../core/deep-links/share-page-link';
import { materialBackLabel, materialCloseLabel, toIntlLocale, useI18n } from '../../../i18n';
import { canonicalTag } from '../../../core/domain/tags';
import {
  CKText,
  CalendarPicker,
  DateNavigator,
  statColors,
  EmptyState,
  GlassSurface,
  MobileWebImage,
  ProfileHeaderAction,
  ProfileStatChip,
  ProfileTabs,
  SelectionPickerModal,
  SkeletonContent,
  PillSurface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { RankedLeagueMember, RankedLeagueBattle } from '../../player/models';
import type { Player, RankedLeagueData, RankedLeagueBattlelog } from '../../player/models';
import { rankedHistoricalPeriods, rankedPeriods, type RankedPeriod } from '../data';
import { RankedLeagueHistory, rankedCutoffs, rankedTierColor } from './ranked-league-history';
import { PagerView, type PagerViewHandle } from '../../../ui/pager';
import { useCKAccessibility } from '../../../ui/accessibility';
import { usePrimarySwipeGuard } from '../../../ui/primary-swipe-guard';
import {
  gameDataState,
  subscribeToGameDataRevision,
} from '../../../core/game-data/game-data-state';
import { RankedShareModal } from './ranked-share';
import { RankedBattles } from './ranked-battles';
import { playerProfileClanIdentity } from '../../player/presentation/player-clan-identity';

export interface RankedScreenProps {
  readonly identityLoading?: boolean;
  readonly seasonLogs?: ReadonlyMap<number, RankedLeagueBattlelog>;
  readonly loadingSeason?: number;
  readonly settledSeasons?: ReadonlySet<number>;
  readonly seasonError?: string;
  readonly onLoadSeason?: (season: number) => Promise<void>;
  readonly player: Player;
  readonly data: RankedLeagueData | null;
  readonly loading: boolean;
  readonly refreshing: boolean;
  readonly error: string | null;
  readonly accounts: readonly Player[];
  readonly bookmarked: boolean;
  readonly linked: boolean;
  readonly onBack: () => void;
  readonly onRefresh: () => Promise<void>;
  readonly onSwitchPlayer: (player: Player) => void;
  readonly onToggleBookmark: () => Promise<void>;
  readonly onOpenInGame: () => void;
  readonly onOpenPlayerTag: (tag: string) => Promise<void>;
}

const RANKED_PAGES = ['season', 'rankings', 'history'] as const;
const RANKED_CONTENT = [0];
type RankedPage = (typeof RANKED_PAGES)[number];

export function RankedScreen(props: RankedScreenProps) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width, height } = useWindowDimensions();
  const desktop = Platform.OS === 'web' && width >= 900;
  const link = useLinkParameters();
  const initialPage: RankedPage =
    link.tab === 'history'
      ? 'history'
      : link.tab === 'rankings' || link.mode === 'ranking'
        ? 'rankings'
        : 'season';
  const [tab, setTab] = useState<RankedPage>(initialPage);
  const [visitedPages, setVisitedPages] = useState<ReadonlySet<RankedPage>>(
    () => new Set([initialPage]),
  );
  const [settledTab, setSettledTab] = useState<RankedPage>(initialPage);
  const [tabPosition] = useState(() => new Animated.Value(RANKED_PAGES.indexOf(initialPage)));
  const [pageHeights, setPageHeights] = useState<Partial<Record<RankedPage, number>>>({});
  const pager = useRef<PagerViewHandle>(null);
  const scrollRef = useRef<FlatList<number>>(null);
  const viewportTop = useRef(0);
  const rankingBounds = useRef({ top: 0, height: 0 });
  const jumpPending = useRef(false);
  const ownRankRef = useRef<ViewInstance>(null);
  const headerHeight = useRef(0);
  const scrollY = useRef(0);
  const { reduceMotion } = useCKAccessibility();
  const blockPrimarySwipe = usePrimarySwipeGuard();
  useEffect(() => () => blockPrimarySwipe(false), [blockPrimarySwipe]);
  useSyncExternalStore(subscribeToGameDataRevision, () => gameDataState.revision);
  const [periodIndex, setPeriodIndex] = useState<number | undefined>();
  const [dateOpen, setDateOpen] = useState(false);
  const [accountPicker, setAccountPicker] = useState(false);
  const [posterOpen, setPosterOpen] = useState(false);
  const [openingPlayer, setOpeningPlayer] = useState(false);
  const periods = useMemo(
    () => (props.data ? rankedPeriods(props.data, new Date(), props.seasonLogs) : []),
    [props.data, props.seasonLogs],
  );
  const linkedPeriodIndex = periods.findIndex((period) =>
    link.day
      ? period.startsAt.toISOString().slice(0, 10) === link.day
      : Boolean(link.season && period.startsAt.toISOString().startsWith(link.season)),
  );
  const safePeriodIndex = Math.min(
    periodIndex ?? Math.max(0, linkedPeriodIndex),
    Math.max(0, periods.length - 1),
  );
  const period = periods[safePeriodIndex] ?? null;
  const selectedSeason = period?.seasonId;
  const { onLoadSeason } = props;
  useEffect(() => {
    if (selectedSeason !== undefined && tab === 'season') void onLoadSeason?.(selectedSeason);
  }, [selectedSeason, tab, onLoadSeason]);
  const selectPage = (next: RankedPage) => {
    setTab(next);
    setVisitedPages((pages) => (pages.has(next) ? pages : new Set(pages).add(next)));
    // Match Legends: preserve the collapsed header, not a deep scroll position
    // from a longer section that would hide the destination's content.
    const offset = Math.min(scrollY.current, headerHeight.current);
    requestAnimationFrame(() => scrollRef.current?.scrollToOffset({ offset, animated: false }));
  };
  const goToPage = (next: RankedPage) => {
    selectPage(next);
    const index = RANKED_PAGES.indexOf(next);
    if (reduceMotion) {
      pager.current?.setPageWithoutAnimation(index);
      tabPosition.setValue(index);
      setSettledTab(next);
    } else pager.current?.setPage(index);
  };
  const alignToOwnRank = () => {
    ownRankRef.current?.measure((_x, _y, _w, _h, _px, pageY) => {
      scrollRef.current?.scrollToOffset({
        offset: Math.max(0, scrollY.current + pageY - viewportTop.current - height * 0.42),
        animated: !reduceMotion,
      });
    });
  };
  const jumpToPlayer = () => {
    if (ownRankRef.current) {
      jumpPending.current = false;
      alignToOwnRank();
      return;
    }
    const members = period?.group?.members ?? [];
    const index = members.findIndex(
      (member) => canonicalTag(member.playerTag) === canonicalTag(props.player.tag),
    );
    if (index < 0) return;
    // The target may be outside the render window. Move near its estimated
    // position first, then align its real measured row after it mounts.
    jumpPending.current = true;
    scrollRef.current?.scrollToOffset({
      offset: Math.max(
        0,
        rankingBounds.current.top +
          (rankingBounds.current.height * index) / members.length -
          height * 0.42,
      ),
      animated: false,
    });
  };
  const ownRankDidLayout = () => {
    if (!jumpPending.current) return;
    jumpPending.current = false;
    alignToOwnRank();
  };
  useEffect(() => {
    jumpPending.current = false;
  }, [period?.seasonId, props.player.tag]);
  const openPlayerTag = async (tag: string) => {
    if (openingPlayer) return;
    setOpeningPlayer(true);
    try {
      await props.onOpenPlayerTag(tag);
    } finally {
      setOpeningPlayer(false);
    }
  };
  const hasOwnRank = period?.group?.members.some(
    (member) => canonicalTag(member.playerTag) === canonicalTag(props.player.tag),
  );
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.fill, { backgroundColor: theme.background }]}
    >
      {/* Keep the pager in a list cell: React Native then forwards this scroll
          viewport to its nested ranking list so it can actually virtualize. */}
      <FlatList
        ref={scrollRef}
        data={RANKED_CONTENT}
        keyExtractor={() => 'ranked-content'}
        removeClippedSubviews={false}
        onLayout={() =>
          scrollRef.current?.getNativeScrollRef()?.measure((_x, _y, _w, _h, _px, pageY) => {
            viewportTop.current = pageY;
          })
        }
        testID={`ranked-scroll-${tab}`}
        scrollEventThrottle={16}
        onScroll={(event) => {
          scrollY.current = event.nativeEvent.contentOffset.y;
        }}
        refreshControl={
          <RefreshControl
            refreshing={props.refreshing}
            onRefresh={() => void props.onRefresh()}
            tintColor={theme.primary}
          />
        }
        contentContainerStyle={{ paddingBottom: insets.bottom + (tab === 'rankings' ? 88 : 28) }}
        ListHeaderComponent={
          <View
            onLayout={(event) => {
              headerHeight.current = event.nativeEvent.layout.height;
            }}
          >
            <RankedHeader
              {...props}
              displayPeriod={tab === 'history' ? periods[0] : period}
              desktop={desktop}
              top={insets.top}
              onAccounts={() => setAccountPicker(true)}
              onShare={() => {
                if (period) setPosterOpen(true);
                else
                  void sharePageLink(
                    {
                      kind: 'page',
                      page: 'ranked',
                      params: {
                        player: props.player.tag,
                        tab,
                        mode: tab === 'rankings' ? 'ranking' : 'details',
                      },
                    },
                    props.player.name,
                  ).catch(() => Alert.alert(t('generalError'), t('generalTryAgain')));
              }}
            />
          </View>
        }
        renderItem={() => (
          <View style={[styles.content, { paddingHorizontal: Math.max(16, (width - 1120) / 2) }]}>
            <ProfileTabs
              variant="underline"
              selectedKey={tab}
              animatedPosition={tabPosition}
              indicatorRtl={isRtl}
              onSelect={(key) => goToPage(key as RankedPage)}
              tabs={[
                { key: 'season', label: t('clanRankingsSeason'), icon: <CalendarDays size={20} /> },
                { key: 'rankings', label: t('sideRankingsTitle'), icon: <UsersRound size={20} /> },
                { key: 'history', label: t('generalHistory'), icon: <History size={20} /> },
              ]}
            />
            {period && tab !== 'history' ? (
              <DateNavigator
                label={formatPeriodRange(period.startsAt, locale)}
                onPrevious={() => setPeriodIndex(Math.min(periods.length - 1, safePeriodIndex + 1))}
                onNext={() => setPeriodIndex(Math.max(0, safePeriodIndex - 1))}
                previousDisabled={safePeriodIndex >= periods.length - 1}
                nextDisabled={safePeriodIndex === 0}
                onPressLabel={() => setDateOpen(true)}
                accessibilityLabel={t('rankingsSnapshotDate')}
              />
            ) : null}
            <View
              onTouchStart={() => blockPrimarySwipe(true)}
              onTouchEnd={() => blockPrimarySwipe(false)}
              onTouchCancel={() => blockPrimarySwipe(false)}
            >
              <PagerView
                ref={pager}
                initialPage={RANKED_PAGES.indexOf(initialPage)}
                layoutDirection={isRtl ? 'rtl' : 'ltr'}
                testID="ranked-section-pager"
                style={{
                  height: Math.max(pageHeights[tab] ?? 500, pageHeights[settledTab] ?? 500),
                }}
                onPageScroll={(event) => {
                  const { position, offset } = event.nativeEvent;
                  tabPosition.setValue(position + offset);
                  // Mount the incoming tab during the swipe, not after it lands.
                  // Unvisited tabs still stay out of ordinary week-change renders.
                  if (offset > 0) {
                    const visible = RANKED_PAGES.slice(position, position + 2);
                    if (visible.some((page) => !visitedPages.has(page)))
                      setVisitedPages((pages) => new Set([...pages, ...visible]));
                  }
                }}
                onPageSelected={(event) => {
                  const next = RANKED_PAGES[event.nativeEvent.position];
                  if (next) {
                    selectPage(next);
                    setSettledTab(next);
                  }
                }}
              >
                {RANKED_PAGES.map((page) => (
                  <View
                    key={page}
                    collapsable={false}
                    style={styles.fill}
                    aria-hidden={page !== tab}
                    accessibilityElementsHidden={page !== tab}
                    importantForAccessibility={page !== tab ? 'no-hide-descendants' : 'auto'}
                  >
                    <View
                      style={{ paddingTop: 8 }}
                      onLayout={(event) => {
                        const value = Math.ceil(event.nativeEvent.layout.height);
                        if (value > 0)
                          setPageHeights((old) =>
                            old[page] === value ? old : { ...old, [page]: value },
                          );
                      }}
                    >
                      {!visitedPages.has(page) ? null : props.loading && !props.data ? (
                        <RankedSkeleton page={page} player={props.player} />
                      ) : !period || !props.data ? (
                        <EmptyState
                          title={props.error ?? t('generalNoDataAvailable')}
                          actionLabel={t('sideRefresh')}
                          onAction={() => void props.onRefresh()}
                        />
                      ) : page === 'season' ? (
                        <RankedBattles
                          key={props.player.tag}
                          period={period}
                          onOpenOpponent={openPlayerTag}
                          loading={
                            props.loadingSeason === period.seasonId ||
                            (!period.hasDetails &&
                              !props.settledSeasons?.has(period.seasonId) &&
                              !props.seasonError)
                          }
                          error={props.seasonError}
                          onRetry={() => void onLoadSeason?.(period.seasonId)}
                        />
                      ) : page === 'rankings' ? (
                        <RankingTable
                          period={period}
                          playerTag={props.player.tag}
                          onOpenPlayerTag={openPlayerTag}
                          ownRef={ownRankRef}
                          onOwnRowLayout={ownRankDidLayout}
                          onBounds={(pageY, contentHeight) => {
                            rankingBounds.current = {
                              top: scrollY.current + pageY - viewportTop.current,
                              height: contentHeight,
                            };
                            // A jump can be requested before the first list measurement.
                            if (jumpPending.current) jumpToPlayer();
                          }}
                        />
                      ) : (
                        <HistoryPanel
                          periods={periods}
                          locale={locale}
                          onSelect={(selected) => {
                            setPeriodIndex(
                              periods.findIndex((item) => item.seasonId === selected.seasonId),
                            );
                            goToPage('season');
                          }}
                        />
                      )}
                    </View>
                  </View>
                ))}
              </PagerView>
            </View>
          </View>
        )}
      />
      {tab === 'rankings' && hasOwnRank ? (
        <View
          pointerEvents="box-none"
          style={[styles.floatingRankWrap, { bottom: insets.bottom + 14 }]}
        >
          <Pressable
            testID="ranked-jump-to-my-rank"
            accessibilityRole="button"
            accessibilityLabel={t('rankedLeagueJumpToMyRank')}
            onPress={jumpToPlayer}
            style={({ pressed }) => [
              styles.floatingRank,
              { backgroundColor: theme.primary, opacity: pressed ? 0.8 : 1 },
            ]}
          >
            <LocateFixed size={19} color={theme.onPrimary} />
            <CKText role="bodyMedium" style={{ color: theme.onPrimary }}>
              {t('rankedLeagueJumpToMyRank')}
            </CKText>
            <CKText role="bodyMedium" style={{ color: theme.onPrimary }}>
              #{period?.placement}
            </CKText>
          </Pressable>
        </View>
      ) : null}
      {dateOpen && period ? (
        <RankedPeriodPicker
          periods={periods}
          selected={period}
          onClose={() => setDateOpen(false)}
          onSelect={(index) => {
            setPeriodIndex(index);
            setDateOpen(false);
          }}
        />
      ) : null}
      {period && posterOpen ? (
        <RankedShareModal
          visible
          player={props.player}
          period={period}
          onClose={() => setPosterOpen(false)}
        />
      ) : null}
      <AccountPicker
        visible={accountPicker}
        selected={props.player.tag}
        players={props.accounts}
        onClose={() => setAccountPicker(false)}
        onSelect={(player) => {
          setAccountPicker(false);
          setPeriodIndex(0);
          goToPage('season');
          props.onSwitchPlayer(player);
        }}
      />
    </SafeAreaView>
  );
}

function RankedHeader({
  identityLoading = false,
  player,
  data,
  accounts,
  bookmarked,
  linked,
  desktop,
  top,
  onBack,
  onToggleBookmark,
  onOpenInGame,
  onShare,
  onAccounts,
  displayPeriod,
}: RankedScreenProps & {
  desktop: boolean;
  displayPeriod?: RankedPeriod | null;
  top: number;
  onShare: () => void;
  onAccounts: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const intlLocale = toIntlLocale(locale);
  const member = data?.currentMember;
  const attackCount =
    displayPeriod?.attackCount ?? (member ? member.attackWinCount + member.attackLoseCount : 0);
  const defenseCount =
    displayPeriod?.defenseCount ?? (member ? member.defenseWinCount + member.defenseLoseCount : 0);
  const maxBattles = displayPeriod?.maxBattles || data?.currentMaxBattles;
  const clanIdentity = playerProfileClanIdentity(player);
  const canBookmark = !linked || bookmarked;
  const tile = (
    label: string,
    value: string | number,
    imageUrl: string,
    subtitleIconUrl?: string,
  ) => (
    <PillSurface style={styles.headerMetric}>
      <MobileWebImage imageUrl={imageUrl} style={styles.headerMetricImage} />
      <View style={styles.grow}>
        <CKText role="labelSmall" muted>
          {label}
        </CKText>
        <View style={styles.headerMetricValue}>
          {subtitleIconUrl ? (
            <MobileWebImage imageUrl={subtitleIconUrl} style={styles.headerMetricSubtitleImage} />
          ) : null}
          <CKText role="labelSmall" muted>
            {value}
          </CKText>
        </View>
      </View>
    </PillSurface>
  );
  const quick = (label: string, value: string | number, icon: ReactNode) => (
    <ProfileStatChip label={label} value={value} iconElement={icon} />
  );
  return (
    <View testID="ranked-player-header" style={styles.rankedHeader}>
      <View style={styles.headerBackground}>
        <HeaderArtwork
          testID="ranked-header-background"
          source={require('../../../../assets/clashking/backgrounds/ranked-cloud-trophy-v1.webp')}
          cachePolicy="disk"
          contentFit="cover"
          contentPosition="center"
          transition={0}
          style={StyleSheet.absoluteFill}
        />
        <HeroHeaderScrim variant="ranked" />
        <View
          testID="ranked-header-content"
          style={[
            styles.hero,
            desktop && styles.heroDesktop,
            { paddingTop: top, paddingHorizontal: desktop ? 20 : 12 },
          ]}
        >
          <View style={styles.headerRow}>
            <ProfileHeaderAction
              label={materialBackLabel(locale)}
              onPress={onBack}
              icon={<ArrowLeft color="#FFF" />}
            />
            <View
              style={[styles.headerActions, identityLoading && { opacity: 0 }]}
              pointerEvents={identityLoading ? 'none' : 'auto'}
              accessibilityElementsHidden={identityLoading}
              importantForAccessibility={identityLoading ? 'no-hide-descendants' : 'auto'}
            >
              <ProfileHeaderAction
                label={t('gameAssetsShare')}
                onPress={onShare}
                icon={<Share2 color="#FFF" />}
              />
              <ProfileHeaderAction
                label={t('playerOpenInGame')}
                onPress={onOpenInGame}
                icon={<ExternalLink color="#FFF" />}
              />
              {canBookmark ? (
                <ProfileHeaderAction
                  label={bookmarked ? t('generalRemoveBookmark') : t('generalBookmark')}
                  onPress={() => void onToggleBookmark()}
                  icon={bookmarked ? <BookmarkCheck color="#2F8CFF" /> : <Bookmark color="#FFF" />}
                />
              ) : null}
            </View>
          </View>
          <SkeletonContent loading={identityLoading} style={{ display: 'contents' }}>
            <Pressable
              accessibilityRole={accounts.length > 1 ? 'button' : undefined}
              accessibilityLabel={
                accounts.length > 1
                  ? t('upgradeTrackerSwitchAccount', { account: player.name })
                  : undefined
              }
              disabled={accounts.length < 2}
              onPress={onAccounts}
              style={[styles.identity, desktop && styles.identityDesktop]}
            >
              <View>
                <MobileWebImage
                  // The resolved icon includes the numbered tier plaque; the
                  // API's large icon can be the generic unnumbered league crest.
                  imageUrl={
                    displayPeriod?.tier?.iconUrl ||
                    data?.currentTier?.iconUrl ||
                    player.leagueUrl ||
                    ImageAssets.trophies
                  }
                  style={{ width: 104, height: 104 }}
                  contentFit="contain"
                />
                <View style={styles.tierBadgeShell}>
                  <MobileWebImage
                    imageUrl={player.townHallPic}
                    style={styles.tierBadge}
                    contentFit="contain"
                  />
                </View>
              </View>
              <View style={styles.identityCopy}>
                <CKText
                  role="screenTitle"
                  numberOfLines={1}
                  style={[styles.white, styles.identityName]}
                >
                  {player.name}
                </CKText>
                {clanIdentity.name ? (
                  <View style={styles.clanLine}>
                    {clanIdentity.badgeUrl ? (
                      <MobileWebImage imageUrl={clanIdentity.badgeUrl} style={styles.clanBadge} />
                    ) : null}
                    <CKText role="labelLarge" style={styles.white}>
                      {clanIdentity.name}
                    </CKText>
                  </View>
                ) : null}
                {accounts.length > 1 ? (
                  <GlassSurface cornerRadius={ckRadius.pill} style={styles.accountPill}>
                    <UsersRound size={17} color="#FFFFFFD1" />
                    <CKText skeleton={false} role="labelSmall" style={styles.white}>
                      {t('rankedLeagueAccountSelector')}
                    </CKText>
                    <ChevronDown size={18} color="#FFFFFFC7" />
                  </GlassSurface>
                ) : null}
              </View>
            </Pressable>
            <View style={styles.headerStats}>
              {!desktop
                ? quick(
                    t('rankedLeagueTrophies'),
                    (
                      displayPeriod?.trophies ??
                      member?.leagueTrophies ??
                      data?.trophies ??
                      player.trophies
                    ).toLocaleString(intlLocale),
                    <MobileWebImage
                      imageUrl={ImageAssets.trophies}
                      style={styles.headerQuickImage}
                    />,
                  )
                : null}
              {desktop
                ? tile(
                    t('rankedLeagueTrophies'),
                    (
                      displayPeriod?.trophies ??
                      member?.leagueTrophies ??
                      data?.trophies ??
                      player.trophies
                    ).toLocaleString(intlLocale),
                    displayPeriod?.tier?.iconUrl ||
                      data?.currentTier?.iconUrl ||
                      player.leagueUrl ||
                      ImageAssets.trophies,
                    ImageAssets.trophies,
                  )
                : null}
              {desktop
                ? tile(
                    t('rankedLeagueGroupRank'),
                    (displayPeriod?.placement ?? data?.currentRank)
                      ? `#${(displayPeriod?.placement ?? data?.currentRank ?? 0).toLocaleString(intlLocale)}`
                      : t('legendsNoRank'),
                    ImageAssets.trophies,
                  )
                : null}
              {!desktop
                ? quick(
                    t('rankedLeagueGroupRank'),
                    (displayPeriod?.placement ?? data?.currentRank)
                      ? `#${(displayPeriod?.placement ?? data?.currentRank ?? 0).toLocaleString(intlLocale)}`
                      : t('legendsNoRank'),
                    <ChartLine size={19} color={theme.onSurface} />,
                  )
                : null}
              {desktop
                ? quick(
                    t('playerBestTrophies'),
                    data?.bestTrophies ?? player.bestTrophies,
                    <MobileWebImage
                      imageUrl={ImageAssets.bestTrophies}
                      style={styles.headerQuickImage}
                    />,
                  )
                : null}
              {quick(
                t('rankedLeagueAttacks'),
                maxBattles === null || maxBattles === undefined
                  ? attackCount
                  : `${attackCount}/${maxBattles}`,
                <MobileWebImage imageUrl={ImageAssets.sword} style={styles.headerQuickImage} />,
              )}
              {quick(
                t('rankedLeagueDefenses'),
                maxBattles === null || maxBattles === undefined
                  ? defenseCount
                  : `${defenseCount}/${maxBattles}`,
                <MobileWebImage
                  imageUrl={ImageAssets.shieldWithArrow}
                  style={styles.headerQuickImage}
                />,
              )}
              {desktop && (data?.currentGroup?.members.length ?? 0) > 0
                ? quick(
                    t('rankedLeagueGroupRanking'),
                    t('rankedLeaguePlayers', { count: data!.currentGroup!.members.length }),
                    <UsersRound size={19} color={theme.onSurface} />,
                  )
                : null}
            </View>
            <View
              testID="ranked-header-fade-tail"
              pointerEvents="none"
              style={styles.headerFadeTail}
            />
          </SkeletonContent>
        </View>
      </View>
    </View>
  );
}

function RankingTable({
  period,
  playerTag,
  onOpenPlayerTag,
  ownRef,
  onOwnRowLayout,
  onBounds,
}: {
  period: RankedPeriod;
  playerTag: string;
  onOpenPlayerTag: (tag: string) => Promise<void>;
  ownRef: RefObject<ViewInstance | null>;
  onOwnRowLayout: () => void;
  onBounds: (pageY: number, height: number) => void;
}) {
  const { t } = useI18n();
  const tableRef = useRef<ViewInstance>(null);
  if (!period.group?.members.length)
    return <EmptyState title={t('rankedLeagueGroupRanking')} body={t('rankedLeagueNoGroup')} />;
  const cutoffs = rankedCutoffs(period);
  const divider = (label: string, color: string) => (
    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 10 }}>
      <View style={{ flex: 1, height: 2, backgroundColor: colorWithAlpha(color, 0.45) }} />
      <CKText role="metadata" style={{ color }}>
        {label}
      </CKText>
      <View style={{ flex: 1, height: 2, backgroundColor: colorWithAlpha(color, 0.45) }} />
    </View>
  );
  return (
    <View
      ref={tableRef}
      collapsable={false}
      onLayout={() => {
        tableRef.current?.measure((_x, _y, _w, contentHeight, _px, pageY) =>
          onBounds(pageY, contentHeight),
        );
      }}
    >
      <FlatList
        testID="ranked-group-list"
        data={period.group.members}
        keyExtractor={(member) => canonicalTag(member.playerTag)}
        scrollEnabled={false}
        removeClippedSubviews={false}
        initialNumToRender={8}
        maxToRenderPerBatch={8}
        windowSize={5}
        ListHeaderComponent={
          <CKText role="metadata" muted style={{ marginBottom: 8 }}>
            {t('rankedLeaguePlayers', { count: period.group.members.length })}
          </CKText>
        }
        ItemSeparatorComponent={RankingSeparator}
        renderItem={({ item: member, index }) => {
          const selected = canonicalTag(member.playerTag) === canonicalTag(playerTag);
          return (
            <View
              collapsable={false}
              ref={selected ? ownRef : undefined}
              onLayout={selected ? onOwnRowLayout : undefined}
            >
              {cutoffs && cutoffs.promotion > 0 && index === cutoffs.promotion
                ? divider(t('rankedLeaguePromotionCutoff'), statColors.win)
                : null}
              {cutoffs && cutoffs.demotion > 0 && index === cutoffs.demotionStart
                ? divider(t('rankedLeagueDemotionCutoff'), statColors.loss)
                : null}
              <RankingRow
                member={member}
                rank={index + 1}
                maximum={period.maxBattles}
                selected={selected}
                onPress={() => void onOpenPlayerTag(member.playerTag)}
              />
            </View>
          );
        }}
        ListFooterComponent={
          !cutoffs ? (
            <CKText role="metadata" muted style={{ marginTop: 8 }}>
              {t('rankedLeagueCutoffsUnavailable')}
            </CKText>
          ) : undefined
        }
      />
    </View>
  );
}

function RankingSeparator() {
  return <View style={{ height: 8 }} />;
}

function RankingRow({
  member,
  rank,
  maximum,
  selected,
  onPress,
}: {
  member: RankedLeagueMember;
  rank: number;
  maximum: number;
  selected: boolean;
  onPress: () => void;
}) {
  const { locale, t } = useI18n();
  const theme = useCKTheme();
  const count = (value: number) => (maximum > 0 ? `${value}/${maximum}` : String(value));
  return (
    <Pressable
      accessibilityRole="button"
      testID={selected ? 'ranked-current-player-row' : undefined}
      onPress={onPress}
      style={({ pressed }) => [
        styles.rankRow,
        {
          backgroundColor: selected ? colorWithAlpha(theme.primary, 0.12) : theme.card,
          opacity: pressed ? 0.75 : 1,
        },
      ]}
    >
      <CKText
        skeleton={false}
        role="rowTitle"
        style={[styles.rankNumber, selected && { color: theme.primary }]}
      >
        #{rank}
      </CKText>
      <View style={styles.grow}>
        <CKText role="rowTitle" numberOfLines={1}>
          {member.playerName}
        </CKText>
        {member.clanName || member.clanTag ? (
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 4 }}>
            {member.clanTag ? (
              <MobileWebImage
                imageUrl={ImageAssets.widgetClanBadgeForTag(member.clanTag)}
                style={{ width: 16, height: 18 }}
              />
            ) : null}
            <CKText muted role="metadata" numberOfLines={1} style={styles.grow}>
              {member.clanName || member.clanTag}
            </CKText>
          </View>
        ) : null}
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 12, marginTop: 8 }}>
          <View
            accessible
            accessibilityLabel={`${t('rankedLeagueAttacks')}: ${count(member.attackWinCount + member.attackLoseCount)}`}
            style={styles.inlineStat}
          >
            <MobileWebImage imageUrl={ImageAssets.sword} style={styles.miniImage} />
            <CKText role="metadata" muted>
              {count(member.attackWinCount + member.attackLoseCount)}
            </CKText>
          </View>
          <View
            accessible
            accessibilityLabel={`${t('rankedLeagueDefenses')}: ${count(member.defenseWinCount + member.defenseLoseCount)}`}
            style={styles.inlineStat}
          >
            <MobileWebImage imageUrl={ImageAssets.shieldWithArrow} style={styles.miniImage} />
            <CKText role="metadata" muted>
              {count(member.defenseWinCount + member.defenseLoseCount)}
            </CKText>
          </View>
        </View>
      </View>
      <View style={{ alignItems: 'flex-end', gap: 4 }}>
        <View style={styles.inlineStat}>
          <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.miniImage} />
          <CKText role="rowTitle">
            {member.leagueTrophies.toLocaleString(toIntlLocale(locale))}
          </CKText>
        </View>
        <ChevronRight size={17} color={theme.onSurfaceVariant} />
      </View>
    </Pressable>
  );
}

function HistoryPanel({
  periods,
  locale,
  onSelect,
}: {
  periods: readonly RankedPeriod[];
  locale: string;
  onSelect: (period: RankedPeriod) => void;
}) {
  const { t } = useI18n();
  const completed = rankedHistoricalPeriods(periods);
  return (
    <View style={styles.section}>
      <RankedLeagueHistory periods={periods} locale={locale} />
      <CKText skeleton={false} role="titleSmall">
        {t('generalHistory')}
      </CKText>
      {completed.length ? (
        completed.map((period) => (
          <HistoryPeriodRow
            key={period.seasonId}
            period={period}
            locale={locale}
            onPress={() => onSelect(period)}
          />
        ))
      ) : (
        <EmptyState showSticker={false} title={t('generalNoDataAvailable')} />
      )}
    </View>
  );
}

function HistoryPeriodRow({
  period,
  locale,
  onPress,
}: {
  period: RankedPeriod;
  locale: string;
  onPress: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const color = rankedTierColor(period.tier?.name ?? '');
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => ({
        padding: 14,
        borderRadius: ckRadius.tile,
        backgroundColor: theme.card,
        gap: 12,
        opacity: pressed ? 0.75 : 1,
      })}
    >
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
        <MobileWebImage
          imageUrl={period.tier?.iconUrl ?? ImageAssets.trophies}
          style={{ width: 44, height: 48 }}
        />
        <View style={styles.grow}>
          <CKText role="rowTitle" style={{ color }}>
            {period.tier?.name ?? t('rankedLeagueNoGroup')}
          </CKText>
          <CKText role="metadata" muted>
            {formatPeriodRange(period.startsAt, locale)}
          </CKText>
        </View>
        <View style={{ alignItems: 'flex-end', gap: 3 }}>
          <View style={styles.inlineStat}>
            <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.miniImage} />
            <CKText role="rowTitle">{period.trophies.toLocaleString(toIntlLocale(locale))}</CKText>
          </View>
          <CKText role="metadata" muted>
            {period.placement > 0 ? `#${period.placement}` : '—'}
          </CKText>
        </View>
        <ChevronRight size={17} color={theme.onSurfaceVariant} />
      </View>
      <View style={{ flexDirection: 'row', gap: 18 }}>
        <View style={styles.inlineStat}>
          <MobileWebImage imageUrl={ImageAssets.sword} style={styles.miniImage} />
          <CKText role="metadata" muted>
            {period.attackCount}
            {period.maxBattles > 0 ? `/${period.maxBattles}` : ''}
          </CKText>
        </View>
        <View style={styles.inlineStat}>
          <MobileWebImage imageUrl={ImageAssets.shieldWithArrow} style={styles.miniImage} />
          <CKText role="metadata" muted>
            {period.defenseCount}
            {period.maxBattles > 0 ? `/${period.maxBattles}` : ''}
          </CKText>
        </View>
      </View>
    </Pressable>
  );
}

function RankedPeriodPicker({
  periods,
  selected,
  onClose,
  onSelect,
}: {
  periods: readonly RankedPeriod[];
  selected: RankedPeriod;
  onClose: () => void;
  onSelect: (index: number) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  // CalendarPicker uses local dates. Preserve the API's UTC Monday as a
  // calendar date, rather than shifting it into Sunday in western time zones.
  const local = (value: Date) =>
    new Date(value.getUTCFullYear(), value.getUTCMonth(), value.getUTCDate());
  const key = (value: Date) => `${value.getFullYear()}-${value.getMonth()}-${value.getDate()}`;
  const dates = periods.map((period) => local(period.startsAt));
  const keys = new Set(dates.map(key));
  return (
    <Modal
      supportedOrientations={modalOrientations}
      visible
      transparent
      animationType="slide"
      onRequestClose={onClose}
    >
      <Pressable
        onPress={onClose}
        style={{ flex: 1, justifyContent: 'flex-end', backgroundColor: '#00000099' }}
      >
        <Pressable
          onPress={() => undefined}
          style={{
            width: '100%',
            maxWidth: 520,
            alignSelf: 'center',
            padding: 20,
            paddingBottom: insets.bottom + 20,
            borderTopLeftRadius: 28,
            borderTopRightRadius: 28,
            backgroundColor: theme.surface,
          }}
        >
          <View
            style={{
              flexDirection: 'row',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: 12,
            }}
          >
            <CKText skeleton={false} role="titleSmall">
              {t('clanRankingsSeason')}
            </CKText>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={materialCloseLabel(locale)}
              onPress={onClose}
              style={{ padding: 8 }}
            >
              <X size={22} color={theme.onSurface} />
            </Pressable>
          </View>
          <CalendarPicker
            start={local(selected.startsAt)}
            minimum={new Date(Math.min(...dates.map(Number)))}
            maximum={new Date(Math.max(...dates.map(Number)))}
            isDateSelectable={(date) => date.getDay() === 1 && keys.has(key(date))}
            onChange={(date) => {
              const index = dates.findIndex((value) => key(value) === key(date));
              if (index >= 0) onSelect(index);
            }}
          />
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function AccountPicker({
  visible,
  selected,
  players,
  onClose,
  onSelect,
}: {
  visible: boolean;
  selected: string;
  players: readonly Player[];
  onClose: () => void;
  onSelect: (player: Player) => void;
}) {
  const { t } = useI18n();
  const options = players.map((player) => ({
    key: player.tag,
    label: player.name,
    subtitle: `${player.tag} · ${t('gameTownHallShortLevel', { level: player.townHallLevel })}`,
    searchText: `${player.name} ${player.tag}`,
    icon: <MobileWebImage imageUrl={player.townHallPic} style={styles.accountPickerImage} />,
  }));
  return (
    <SelectionPickerModal
      visible={visible}
      title={t('upgradeTrackerChooseAccount')}
      options={options}
      selectedKey={selected}
      searchPlaceholder={t('upgradeTrackerChooseAccount')}
      onClose={onClose}
      onSelect={(tag) => {
        const player = players.find(
          (candidate) => canonicalTag(candidate.tag) === canonicalTag(tag),
        );
        if (player) onSelect(player);
      }}
    />
  );
}

function RankedSkeleton({ page, player }: { page: RankedPage; player: Player }) {
  const { locale } = useI18n();
  const period: RankedPeriod = {
    seasonId: 1,
    startsAt: new Date('2026-01-05T00:00:00Z'),
    trophies: 1000,
    placement: 1,
    attackWins: 10,
    attackLosses: 0,
    attackStars: 30,
    defenseWins: 10,
    defenseLosses: 0,
    defenseStars: 30,
    maxBattles: 24,
    tier: null,
    group: null,
    isCurrent: true,
    attacks: [0, 1, 2].map(
      () => new RankedLeagueBattle('', 'Opponent player', 3, 100, 40, new Date(0)),
    ),
    defenses: [],
    hasDetails: true,
    attacksComplete: true,
    defensesComplete: true,
    missingRealAttacks: 0,
    missingRealDefenses: 0,
    automaticDefensesDerived: false,
    attackCount: 10,
    defenseCount: 10,
    attackMaxBattles: 24,
    defenseMaxBattles: 24,
  };
  return (
    <SkeletonContent loading>
      {page === 'season' ? (
        <RankedBattles
          period={period}
          onOpenOpponent={async () => undefined}
          onRetry={() => undefined}
        />
      ) : page === 'rankings' ? (
        <View style={styles.section}>
          {[0, 1, 2, 3].map((index) => (
            <RankingRow
              key={index}
              member={
                new RankedLeagueMember(
                  player.tag,
                  'Player name',
                  '',
                  'Clan name',
                  1000,
                  10,
                  0,
                  10,
                  0,
                )
              }
              rank={index + 1}
              maximum={24}
              selected={false}
              onPress={() => undefined}
            />
          ))}
        </View>
      ) : (
        <HistoryPanel
          periods={[period, { ...period, seasonId: 2, isCurrent: false }]}
          locale={locale}
          onSelect={() => undefined}
        />
      )}
    </SkeletonContent>
  );
}
function formatPeriodRange(date: Date, locale: string) {
  const end = new Date(date.getTime() + 7 * 86_400_000);
  const formatter = new Intl.DateTimeFormat(toIntlLocale(locale), {
    timeZone: 'UTC',
    month: 'short',
    day: 'numeric',
  });
  return `${formatter.format(date)} - ${formatter.format(end)}`;
}

const styles = StyleSheet.create({
  floatingRankWrap: { position: 'absolute', left: 16, right: 16, alignItems: 'center' },
  floatingRank: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    minHeight: 46,
    paddingHorizontal: 20,
    borderRadius: ckRadius.pill,
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
  },
  inlineStat: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  fill: { flex: 1 },
  simpleAppBar: { minHeight: 56, flexDirection: 'row', alignItems: 'center' },
  simpleAppBarTitle: { flex: 1 },
  appBarSpacer: { width: 48, height: 48 },
  emptyBody: { flex: 1, paddingHorizontal: 16, paddingTop: 24 },
  grow: { flex: 1 },
  growRight: { flex: 1, textAlign: 'right' },
  white: { color: '#FFF' },
  whiteSoft: { color: 'rgba(255,255,255,.78)' },
  center: { alignItems: 'center' },
  centerText: { textAlign: 'center', padding: 20 },
  rankedHeader: { overflow: 'hidden', marginBottom: -44 },
  headerBackground: { width: '100%' },
  headerFadeTail: { height: 44 },
  hero: {
    paddingBottom: 12,
    gap: 6,
  },
  heroDesktop: { paddingBottom: 16 },
  headerRow: { flexDirection: 'row', justifyContent: 'space-between' },
  headerActions: { flexDirection: 'row', gap: 8 },
  identity: { alignItems: 'center', gap: 8 },
  identityDesktop: { flexDirection: 'row', alignSelf: 'center' },
  identityCopy: { alignItems: 'center' },
  identityName: { maxWidth: 280, fontSize: 26, lineHeight: 27, fontWeight: '700' },
  tierBadgeShell: {
    position: 'absolute',
    left: -2,
    bottom: 0,
    width: 38,
    height: 38,
    borderRadius: 19,
    padding: 3,
    backgroundColor: 'rgba(24,24,24,.82)',
  },
  tierBadge: { width: 32, height: 32 },
  clanLine: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 4 },
  clanBadge: { width: 16, height: 16 },
  accountPill: {
    paddingHorizontal: 10,
    paddingVertical: 7,
    marginTop: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
  },
  headerStats: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 7,
    marginTop: 4,
  },
  headerMetric: {
    width: 220,
    height: 64,
    borderRadius: 16,
    paddingHorizontal: 10,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  headerMetricImage: { width: 34, height: 34 },
  headerMetricValue: { flexDirection: 'row', alignItems: 'center', gap: 3, marginTop: 2 },
  headerMetricSubtitleImage: { width: 14, height: 14 },
  headerQuickImage: { width: 19, height: 19 },
  content: { gap: 12, paddingTop: 12 },
  infoDialogTitle: { textAlign: 'center' },
  infoDialogScroll: { maxHeight: 360 },
  infoDialogContent: { paddingVertical: 4 },
  infoDialogAction: {
    minHeight: 44,
    alignSelf: 'flex-end',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 12,
  },
  section: { gap: 16 },
  periodNav: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  arrow: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  battleGrid: { flexDirection: 'row', gap: 8, alignItems: 'stretch' },
  rankTrophiesCard: { padding: 16, flexDirection: 'row', alignItems: 'center' },
  periodTierIcon: { width: 82, height: 82 },
  cardTitle: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'center', gap: 6 },
  battleCard: { flex: 1, minWidth: 0, paddingVertical: 16, paddingHorizontal: 10, gap: 8 },
  battleTitleImage: { width: 22, height: 22 },
  noticeImage: { width: 20, height: 20 },
  averageRow: { alignSelf: 'center', flexDirection: 'row', alignItems: 'center', gap: 4 },
  averageTrophy: { width: 16, height: 16 },
  averageStar: { width: 8, height: 8, marginLeft: -12, marginTop: -8 },
  battleList: { gap: 6 },
  battleRow: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 9,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(128,128,128,.2)',
  },
  battleRowImage: { width: 20, height: 20 },
  battleValues: { flexDirection: 'row', alignItems: 'center', gap: 3 },
  battleStar: { width: 14, height: 14 },
  dimmed: { opacity: 0.28 },
  emptyBattleRow: { opacity: 0.5 },
  unavailableBattles: { paddingVertical: 18, textAlign: 'center' },
  footerStats: { marginTop: 'auto', gap: 2 },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: 'rgba(128,128,128,.35)',
    marginBottom: 6,
  },
  statLine: {
    minHeight: 22,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  miniStat: { minWidth: 74, flexGrow: 1, alignItems: 'center', padding: 8 },
  notice: { padding: 16, flexDirection: 'row', gap: 12, alignItems: 'flex-start' },
  jumpButtonRow: { alignItems: 'flex-end', marginBottom: 8 },
  smallButton: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    justifyContent: 'center',
    paddingHorizontal: 14,
    borderRadius: ckRadius.pill,
    borderWidth: 1,
  },
  rankRow: {
    minHeight: 94,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    padding: 14,
    borderWidth: 0,
    borderRadius: ckRadius.tile,
  },
  rankNumber: { width: 34, textAlign: 'center' },
  highlightCard: { padding: 16, gap: 14 },
  highlightBest: {
    borderColor: 'rgba(255,215,94,.7)',
    borderWidth: 1.5,
    backgroundColor: 'rgba(255,215,94,.12)',
  },
  tierIcon: { width: 58, height: 58 },
  pageDots: { flexDirection: 'row', justifyContent: 'center', gap: 8, marginTop: 10 },
  pageDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: 'rgba(128,128,128,.35)' },
  highlightGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 14 },
  highlightStat: { flexBasis: '46%', flexGrow: 1, alignItems: 'center', gap: 2 },
  highlightValue: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  miniImage: { width: 18, height: 18 },
  historyToggle: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  historyList: { gap: 6 },
  historyRow: {
    paddingHorizontal: 10,
    paddingVertical: 10,
    flexDirection: 'row',
    gap: 10,
    alignItems: 'center',
  },
  historyTierIcon: { width: 44, height: 44 },
  historyChips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 8 },
  historyChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    paddingVertical: 6,
    borderRadius: 999,
  },
  chipImage: { width: 18, height: 18 },
  modalScrim: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,.62)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  accountPickerImage: { width: 36, height: 36 },
  infoDialog: { margin: 24, maxWidth: 520, padding: 22, gap: 16 },
});
