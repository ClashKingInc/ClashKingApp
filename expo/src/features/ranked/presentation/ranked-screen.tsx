import { useMemo, useRef, useState, type ReactNode } from 'react';
import {
  Modal,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { ImageBackground } from 'expo-image';
import {
  ArrowLeft,
  Bookmark,
  BookmarkCheck,
  ChartLine,
  CalendarDays,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ExternalLink,
  History,
  Info,
  List,
  LocateFixed,
  Trophy,
  UsersRound,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import Svg, { Defs, LinearGradient as SvgLinearGradient, Rect, Stop } from 'react-native-svg';

import { ImageAssets } from '../../../core/assets/image-assets';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import { canonicalTag } from '../../../core/domain/tags';
import {
  CKText,
  EmptyState,
  GlassSurface,
  HeaderIconButton,
  MobileWebImage,
  ProfileTabs,
  SelectionPickerModal,
  Skeleton,
  SkeletonLoadingDialog,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type {
  Player,
  RankedLeagueBattle,
  RankedLeagueData,
  RankedLeagueMember,
} from '../../player/models';
import {
  rankedBattleSummary,
  rankedHistoricalPeriods,
  rankedHistorySeries,
  rankedPeriods,
  rankedTierHighlights,
  type RankedPeriod,
} from '../data';
import { RankedLineChart } from './line-chart';

export interface RankedScreenProps {
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

export function RankedScreen(props: RankedScreenProps) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width, height } = useWindowDimensions();
  const desktop = Platform.OS === 'web' && width >= 900;
  const [tab, setTab] = useState<'period' | 'history'>('period');
  const [periodIndex, setPeriodIndex] = useState(0);
  const [mode, setMode] = useState<'details' | 'ranking'>('details');
  const [showHistoryTable, setShowHistoryTable] = useState(false);
  const [info, setInfo] = useState(false);
  const [accountPicker, setAccountPicker] = useState(false);
  const [openingPlayer, setOpeningPlayer] = useState(false);
  const scrollRef = useRef<ScrollView>(null);
  const [scrollOffsets, setScrollOffsets] = useState<Record<'period' | 'history', number>>({
    period: 0,
    history: 0,
  });
  const [activeScrollOffset, setActiveScrollOffset] = useState(0);
  const liveScrollOffset = useRef(0);
  const selectRankedTab = (next: 'period' | 'history') => {
    const nextOffsets = { ...scrollOffsets, [tab]: liveScrollOffset.current };
    setScrollOffsets(nextOffsets);
    liveScrollOffset.current = nextOffsets[next];
    setActiveScrollOffset(nextOffsets[next]);
    setTab(next);
  };
  const readScrollY = (
    event: NativeSyntheticEvent<NativeScrollEvent> | null | undefined,
  ): number | null => {
    const y = event?.nativeEvent?.contentOffset?.y;
    return typeof y === 'number' && Number.isFinite(y) ? y : null;
  };
  const rememberScrollOffset = (
    event: NativeSyntheticEvent<NativeScrollEvent> | null | undefined,
  ) => {
    const y = readScrollY(event);
    if (y === null) return;
    liveScrollOffset.current = y;
    setScrollOffsets((current) => ({ ...current, [tab]: y }));
  };
  const periods = useMemo(() => (props.data ? rankedPeriods(props.data) : []), [props.data]);
  const safePeriodIndex = Math.min(periodIndex, Math.max(0, periods.length - 1));
  const period = periods[safePeriodIndex] ?? null;
  const openPlayerTag = async (tag: string) => {
    setOpeningPlayer(true);
    try {
      await props.onOpenPlayerTag(tag);
    } finally {
      setOpeningPlayer(false);
    }
  };
  if (!props.data) {
    return (
      <SafeAreaView style={[styles.fill, { backgroundColor: theme.background }]}>
        <View style={styles.simpleAppBar}>
          <HeaderIconButton
            label={materialBackLabel(locale)}
            onPress={props.onBack}
            icon={<ArrowLeft color={theme.onSurface} />}
          />
          <CKText role="titleMedium" style={styles.simpleAppBarTitle} numberOfLines={1}>
            {t('rankedLeagueTitle')}
          </CKText>
          {props.accounts.length > 1 ? (
            <HeaderIconButton
              label={t('upgradeTrackerSwitchAccount', { account: props.player.name })}
              onPress={() => setAccountPicker(true)}
              icon={<List color={theme.onSurface} />}
            />
          ) : (
            <View style={styles.appBarSpacer} />
          )}
        </View>
        <View style={styles.emptyBody}>
          {props.loading ? (
            <RankedSkeleton />
          ) : (
            <EmptyState
              title={t('generalNoDataAvailable')}
              actionLabel={t('sideRefresh')}
              onAction={() => void props.onRefresh()}
            />
          )}
        </View>
        <AccountPicker
          visible={accountPicker}
          selected={props.player.tag}
          players={props.accounts}
          onClose={() => setAccountPicker(false)}
          onSelect={(player) => {
            setAccountPicker(false);
            props.onSwitchPlayer(player);
          }}
        />
      </SafeAreaView>
    );
  }
  const body = !period ? (
    <EmptyState
      title={t('generalNoDataAvailable')}
      actionLabel={t('sideRefresh')}
      onAction={() => void props.onRefresh()}
    />
  ) : tab === 'period' ? (
    <PeriodPanel
      data={props.data}
      period={period}
      index={safePeriodIndex}
      count={periods.length}
      mode={mode}
      locale={locale}
      onMode={setMode}
      onPrevious={() => setPeriodIndex((value) => Math.min(periods.length - 1, value + 1))}
      onNext={() => setPeriodIndex((value) => Math.max(0, value - 1))}
      onOpenPlayerTag={openPlayerTag}
      onJumpToPlayer={(target) => {
        target.measure((_x, _y, _width, _height, _pageX, pageY) => {
          scrollRef.current?.scrollTo({
            y: Math.max(0, liveScrollOffset.current + pageY - height / 2),
            animated: true,
          });
        });
      }}
    />
  ) : (
    <HistoryPanel
      periods={rankedHistoricalPeriods(periods)}
      showTable={showHistoryTable}
      locale={locale}
      onToggle={() => setShowHistoryTable((value) => !value)}
    />
  );

  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.fill, { backgroundColor: theme.background }]}
    >
      <ScrollView
        key={tab}
        testID={`ranked-scroll-${tab}`}
        ref={scrollRef}
        contentOffset={{ x: 0, y: activeScrollOffset }}
        onScroll={(event) => {
          const y = readScrollY(event);
          if (y !== null) liveScrollOffset.current = y;
        }}
        onMomentumScrollEnd={rememberScrollOffset}
        onScrollEndDrag={rememberScrollOffset}
        scrollEventThrottle={16}
        refreshControl={
          <RefreshControl
            refreshing={props.refreshing}
            onRefresh={() => void props.onRefresh()}
            tintColor={theme.primary}
          />
        }
        contentContainerStyle={{ paddingBottom: insets.bottom + 28 }}
      >
        <RankedHeader
          {...props}
          desktop={desktop}
          top={insets.top}
          onInfo={() => setInfo(true)}
          onAccounts={() => setAccountPicker(true)}
        />
        <View style={[styles.content, { paddingHorizontal: Math.max(16, (width - 1120) / 2) }]}>
          <ProfileTabs
            variant="underline"
            tabs={[
              {
                key: 'period',
                label: t('clanRankingsSeason'),
                icon: <CalendarDays size={18} color={theme.primary} />,
              },
              {
                key: 'history',
                label: t('generalHistory'),
                icon: <History size={18} color={theme.primary} />,
              },
            ]}
            selectedKey={tab}
            onSelect={(key) => selectRankedTab(key as 'period' | 'history')}
          />
          {body}
        </View>
      </ScrollView>
      <InfoModal visible={info} onClose={() => setInfo(false)} />
      <AccountPicker
        visible={accountPicker}
        selected={props.player.tag}
        players={props.accounts}
        onClose={() => setAccountPicker(false)}
        onSelect={(player) => {
          setAccountPicker(false);
          setPeriodIndex(0);
          setMode('details');
          setTab('period');
          props.onSwitchPlayer(player);
        }}
      />
      <SkeletonLoadingDialog visible={openingPlayer} />
    </SafeAreaView>
  );
}

function RankedHeader({
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
  onInfo,
  onAccounts,
}: RankedScreenProps & {
  desktop: boolean;
  top: number;
  onInfo: () => void;
  onAccounts: () => void;
}) {
  const { t, locale } = useI18n();
  const intlLocale = toIntlLocale(locale);
  const member = data?.currentMember;
  const attackCount = member ? member.attackWinCount + member.attackLoseCount : 0;
  const defenseCount = member ? member.defenseWinCount + member.defenseLoseCount : 0;
  const maxBattles = data?.currentMaxBattles;
  const clanIdentity = rankedClanIdentity(player);
  const canBookmark = !linked || bookmarked;
  const tile = (
    label: string,
    value: string | number,
    imageUrl: string,
    subtitleIconUrl?: string,
  ) => (
    <GlassSurface cornerRadius={ckRadius.tile} style={styles.headerMetric}>
      <MobileWebImage imageUrl={imageUrl} style={styles.headerMetricImage} />
      <View style={styles.grow}>
        <CKText role="labelSmall" style={styles.whiteSoft}>
          {label}
        </CKText>
        <View style={styles.headerMetricValue}>
          {subtitleIconUrl ? (
            <MobileWebImage imageUrl={subtitleIconUrl} style={styles.headerMetricSubtitleImage} />
          ) : null}
          <CKText role="labelSmall" style={styles.whiteSoft}>
            {value}
          </CKText>
        </View>
      </View>
    </GlassSurface>
  );
  const quick = (label: string, value: string | number, icon: ReactNode) => (
    <GlassSurface
      cornerRadius={ckRadius.pill}
      style={styles.headerQuick}
      accessibilityLabel={label}
    >
      {icon}
      <CKText role="labelLarge" style={styles.white}>
        {value}
      </CKText>
    </GlassSurface>
  );
  return (
    <View testID="ranked-player-header" style={styles.rankedHeader}>
      <ImageBackground
        testID="ranked-header-background"
        source={{ uri: ImageAssets.homeBaseBackground }}
        cachePolicy="disk"
        contentFit="cover"
        style={styles.headerBackground}
      >
        <View
          testID="ranked-header-scrim"
          style={[StyleSheet.absoluteFill, { backgroundColor: colorWithAlpha('#000000', 0.5) }]}
        />
        <Svg pointerEvents="none" style={StyleSheet.absoluteFill} width="100%" height="100%">
          <Defs>
            <SvgLinearGradient id="ranked-hero-scrim" x1="0%" y1="0%" x2="0%" y2="100%">
              <Stop offset="0" stopColor="#000" stopOpacity={0.34} />
              <Stop offset="0.6" stopColor="#000" stopOpacity={0.52} />
              <Stop offset="0.84" stopColor="#000" stopOpacity={0.76} />
              <Stop offset="1" stopColor="#000" stopOpacity={1} />
            </SvgLinearGradient>
          </Defs>
          <Rect width="100%" height="100%" fill="url(#ranked-hero-scrim)" />
        </Svg>
        <View
          testID="ranked-header-content"
          style={[
            styles.hero,
            desktop && styles.heroDesktop,
            { paddingTop: top, paddingHorizontal: desktop ? 20 : 12 },
          ]}
        >
          <View style={styles.headerRow}>
            <HeaderIconButton
              label={materialBackLabel(locale)}
              onPress={onBack}
              icon={<ArrowLeft color="#FFF" />}
            />
            <View style={styles.headerActions}>
              <HeaderIconButton
                label={t('playerOpenInGame')}
                onPress={onOpenInGame}
                icon={<ExternalLink color="#FFF" />}
              />
              {canBookmark ? (
                <HeaderIconButton
                  label={bookmarked ? t('generalRemoveBookmark') : t('generalBookmark')}
                  onPress={() => void onToggleBookmark()}
                  icon={bookmarked ? <BookmarkCheck color="#2F8CFF" /> : <Bookmark color="#FFF" />}
                />
              ) : null}
              <HeaderIconButton
                label={t('rankedLeagueAbout')}
                onPress={onInfo}
                icon={<Info color="#FFF" />}
              />
            </View>
          </View>
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
                imageUrl={player.townHallPic}
                style={{ width: 104, height: 104 }}
                contentFit="contain"
              />
              {data?.currentTier?.largeIconUrl ? (
                <View style={styles.tierBadgeShell}>
                  <MobileWebImage
                    imageUrl={data.currentTier.smallIconUrl || data.currentTier.largeIconUrl}
                    style={styles.tierBadge}
                    contentFit="contain"
                  />
                </View>
              ) : null}
            </View>
            <View style={styles.identityCopy}>
              <CKText
                role="screenTitle"
                numberOfLines={1}
                style={[styles.white, styles.identityName]}
              >
                {player.name}
              </CKText>
              <CKText style={styles.whiteSoft}>{player.tag}</CKText>
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
                  <CKText role="labelSmall" style={styles.white}>
                    {t('rankedLeagueAccountSelector')}
                  </CKText>
                  <ChevronDown size={18} color="#FFFFFFC7" />
                </GlassSurface>
              ) : null}
            </View>
          </Pressable>
          <View style={styles.headerStats}>
            {desktop
              ? tile(
                  t('rankedLeagueTrophies'),
                  (member?.leagueTrophies ?? data?.trophies ?? player.trophies).toLocaleString(
                    intlLocale,
                  ),
                  data?.currentTier?.largeIconUrl || ImageAssets.trophies,
                  ImageAssets.trophies,
                )
              : null}
            {desktop
              ? tile(
                  t('rankedLeagueGroupRank'),
                  data?.currentRank
                    ? `#${data.currentRank.toLocaleString(intlLocale)}`
                    : t('legendsNoRank'),
                  ImageAssets.trophies,
                )
              : null}
            {!desktop
              ? quick(
                  t('rankedLeagueGroupRank'),
                  data?.currentRank
                    ? `#${data.currentRank.toLocaleString(intlLocale)}`
                    : t('legendsNoRank'),
                  <ChartLine size={19} color="#FFF" />,
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
                  <UsersRound size={19} color="#FFF" />,
                )
              : null}
          </View>
          <View
            testID="ranked-header-fade-tail"
            pointerEvents="none"
            style={styles.headerFadeTail}
          />
        </View>
      </ImageBackground>
    </View>
  );
}

function PeriodPanel({
  data,
  period,
  index,
  count,
  mode,
  locale,
  onMode,
  onPrevious,
  onNext,
  onOpenPlayerTag,
  onJumpToPlayer,
}: {
  data: RankedLeagueData;
  period: RankedPeriod;
  index: number;
  count: number;
  mode: 'details' | 'ranking';
  locale: string;
  onMode: (value: 'details' | 'ranking') => void;
  onPrevious: () => void;
  onNext: () => void;
  onOpenPlayerTag: (tag: string) => Promise<void>;
  onJumpToPlayer: (target: View) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={styles.section}>
      <ProfileTabs
        variant="compact"
        tabs={[
          {
            key: 'details',
            label: t('generalDetails'),
            icon: <Info size={18} color={theme.onSurfaceVariant} />,
          },
          {
            key: 'ranking',
            label: t('sideRankingsTitle'),
            icon: <ChartLine size={18} color={theme.onSurfaceVariant} />,
          },
        ]}
        selectedKey={mode}
        onSelect={(value) => onMode(value as 'details' | 'ranking')}
      />
      <View style={styles.periodNav}>
        <Pressable disabled={index >= count - 1} onPress={onPrevious} style={styles.arrow}>
          <ChevronLeft color={index >= count - 1 ? theme.outlineVariant : theme.onSurface} />
        </Pressable>
        <View style={styles.center}>
          <CKText role="sectionTitle">
            {period.isCurrent ? t('rankedLeagueCurrentPeriod') : t('clanRankingsSeason')}
          </CKText>
          <CKText muted>{formatPeriodRange(period.startsAt, locale)}</CKText>
        </View>
        <Pressable disabled={index <= 0} onPress={onNext} style={styles.arrow}>
          <ChevronRight color={index <= 0 ? theme.outlineVariant : theme.onSurface} />
        </Pressable>
      </View>
      {mode === 'ranking' ? (
        <RankingTable
          period={period}
          playerTag={data.playerTag}
          onOpenPlayerTag={onOpenPlayerTag}
          onJumpToPlayer={onJumpToPlayer}
        />
      ) : (
        <PeriodDetails period={period} locale={locale} />
      )}
    </View>
  );
}

function PeriodDetails({ period, locale }: { period: RankedPeriod; locale: string }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const intlLocale = toIntlLocale(locale);
  return (
    <View style={styles.section}>
      <Surface style={styles.rankTrophiesCard}>
        <MiniStat
          label={t('rankedLeagueGroupRank')}
          value={period.placement > 0 ? `#${period.placement.toLocaleString(intlLocale)}` : '—'}
        />
        {period.tier?.largeIconUrl ? (
          <MobileWebImage imageUrl={period.tier.largeIconUrl} style={styles.periodTierIcon} />
        ) : (
          <Trophy size={54} color={theme.onSurfaceVariant} />
        )}
        <MiniStat
          label={t('rankedLeagueTrophies')}
          value={period.trophies.toLocaleString(intlLocale)}
        />
      </Surface>
      <View style={styles.battleGrid}>
        <BattleCard
          title={t('rankedLeagueAttacks')}
          imageUrl={ImageAssets.sword}
          battles={period.attacks}
          count={period.attackCount}
          max={period.maxBattles}
          attack
          locale={locale}
          hasDetails={period.hasDetails}
        />
        <BattleCard
          title={t('rankedLeagueDefenses')}
          imageUrl={ImageAssets.shieldWithArrow}
          battles={period.defenses}
          count={period.defenseCount}
          max={period.maxBattles}
          locale={locale}
          hasDetails={period.hasDetails}
        />
      </View>
      <Surface style={styles.notice}>
        <MobileWebImage imageUrl={ImageAssets.shieldWithArrow} style={styles.noticeImage} />
        <View style={styles.grow}>
          <CKText role="rowTitle">{t('gameHeroesEquipments')}</CKText>
          <CKText muted>{t('rankedLeagueEquipmentUnavailable')}</CKText>
        </View>
      </Surface>
    </View>
  );
}

function BattleCard({
  title,
  imageUrl,
  battles,
  count,
  max,
  attack = false,
  locale,
  hasDetails,
}: {
  title: string;
  imageUrl: string;
  battles: readonly RankedLeagueBattle[];
  count: number;
  max: number;
  attack?: boolean;
  locale: string;
  hasDetails: boolean;
}) {
  const { t } = useI18n();
  const {
    remaining,
    trophyTotal,
    trophyAverage: average,
  } = rankedBattleSummary(battles, count, max);
  const sign = attack ? '+' : '-';
  return (
    <Surface style={styles.battleCard}>
      <View style={styles.cardTitle}>
        <MobileWebImage imageUrl={imageUrl} style={styles.battleTitleImage} />
        <CKText role="labelLarge" numberOfLines={1}>
          {title}
        </CKText>
        {battles.length ? (
          <CKText
            role="labelSmall"
            style={[styles.growRight, { color: attack ? '#2E7D32' : '#C62828' }]}
          >
            ({sign}
            {Math.abs(trophyTotal)})
          </CKText>
        ) : null}
      </View>
      <View style={styles.averageRow}>
        <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.averageTrophy} />
        <MobileWebImage imageUrl={ImageAssets.builderBaseStar} style={styles.averageStar} />
        <CKText
          muted={average === null}
          style={average === null ? undefined : { color: attack ? '#2E7D32' : '#C62828' }}
        >
          {average === null ? '—' : `${sign}${Math.abs(average).toFixed(1)}`}
        </CKText>
      </View>
      {!hasDetails ? (
        <CKText style={styles.unavailableBattles}>
          {t('rankedLeagueBattleDetailsUnavailable')}
        </CKText>
      ) : (
        <View style={styles.battleList}>
          {battles.map((battle, index) => (
            <BattleRow
              key={`${battle.opponentPlayerTag}-${index}`}
              battle={battle}
              attack={attack}
              locale={locale}
            />
          ))}
          {Array.from({ length: remaining ?? 0 }, (_, index) => (
            <EmptyBattleRow key={`remaining-${index}`} attack={attack} />
          ))}
        </View>
      )}
      <View style={styles.footerStats}>
        <View style={styles.divider} />
        <StatLine label={t('rankedLeagueBattles')} value={max > 0 ? `${count} / ${max}` : count} />
        <StatLine label={t('rankedLeagueAverage')} value={average?.toFixed(1) ?? '-'} />
        <StatLine label={t('rankedLeagueRemaining')} value={remaining ?? '-'} />
      </View>
    </Surface>
  );
}

function EmptyBattleRow({ attack }: { attack: boolean }) {
  return (
    <View style={[styles.battleRow, styles.emptyBattleRow]}>
      <MobileWebImage
        imageUrl={attack ? ImageAssets.sword : ImageAssets.shieldWithArrow}
        style={styles.battleRowImage}
      />
      <View style={styles.grow}>
        <View style={styles.battleValues}>
          {[0, 1, 2].map((star) => (
            <MobileWebImage
              key={star}
              imageUrl={ImageAssets.builderBaseStar}
              style={styles.battleStar}
            />
          ))}
          <CKText role="labelLarge">-%</CKText>
          <CKText role="labelSmall">(-)</CKText>
        </View>
        <CKText muted role="labelSmall">
          -
        </CKText>
      </View>
    </View>
  );
}

function StatLine({ label, value }: { label: string; value: string | number }) {
  return (
    <View style={styles.statLine}>
      <CKText muted role="labelSmall">
        {label}
      </CKText>
      <CKText role="labelLarge">{value}</CKText>
    </View>
  );
}

function BattleRow({
  battle,
  attack,
  locale,
}: {
  battle: RankedLeagueBattle;
  attack: boolean;
  locale: string;
}) {
  const sign = attack ? '+' : '-';
  return (
    <View style={styles.battleRow}>
      <MobileWebImage
        imageUrl={attack ? ImageAssets.sword : ImageAssets.shieldWithArrow}
        style={styles.battleRowImage}
      />
      <View style={styles.grow}>
        <View style={styles.battleValues}>
          {[0, 1, 2].map((star) => (
            <MobileWebImage
              key={star}
              imageUrl={ImageAssets.builderBaseStar}
              style={[styles.battleStar, star >= battle.stars && styles.dimmed]}
            />
          ))}
          <CKText role="labelLarge">{Math.round(battle.destructionPercentage)}%</CKText>
          <CKText role="labelSmall" style={{ color: attack ? '#2E7D32' : '#C62828' }}>
            ({sign}
            {Math.abs(battle.trophies)})
          </CKText>
        </View>
        <CKText muted role="labelSmall">
          {battle.creationTime
            ? new Intl.DateTimeFormat(toIntlLocale(locale), {
                weekday: 'short',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false,
              }).format(battle.creationTime)
            : '—'}
        </CKText>
      </View>
    </View>
  );
}

function RankingTable({
  period,
  playerTag,
  onOpenPlayerTag,
  onJumpToPlayer,
}: {
  period: RankedPeriod;
  playerTag: string;
  onOpenPlayerTag: (tag: string) => Promise<void>;
  onJumpToPlayer: (target: View) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const ownRef = useRef<View>(null);
  if (!period.group || period.group.members.length === 0)
    return <EmptyState title={t('rankedLeagueGroupRanking')} body={t('rankedLeagueNoGroup')} />;
  const normalizedPlayerTag = canonicalTag(playerTag);
  const hasPlayer = period.group.members.some(
    (member) => canonicalTag(member.playerTag) === normalizedPlayerTag,
  );
  return (
    <View>
      {hasPlayer ? (
        <View style={styles.jumpButtonRow}>
          <Pressable
            onPress={() => {
              if (ownRef.current) onJumpToPlayer(ownRef.current);
            }}
            style={[
              styles.smallButton,
              {
                backgroundColor: colorWithAlpha(theme.primary, 0.12),
                borderColor: colorWithAlpha(theme.primary, 0.32),
              },
            ]}
          >
            <LocateFixed size={16} color={theme.primary} />
            <CKText role="labelLarge" style={{ color: theme.primary }}>
              {t('rankedLeagueJumpToMyRank')}
            </CKText>
          </Pressable>
        </View>
      ) : null}
      {period.group.members.map((member, index) => (
        <View
          ref={canonicalTag(member.playerTag) === normalizedPlayerTag ? ownRef : undefined}
          key={canonicalTag(member.playerTag)}
        >
          <RankingRow
            member={member}
            rank={index + 1}
            selected={canonicalTag(member.playerTag) === normalizedPlayerTag}
            onPress={() => void onOpenPlayerTag(member.playerTag)}
          />
        </View>
      ))}
    </View>
  );
}

function RankingRow({
  member,
  rank,
  selected,
  onPress,
}: {
  member: RankedLeagueMember;
  rank: number;
  selected: boolean;
  onPress: () => void;
}) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  const medal = rank === 1 ? '#FFD54F' : rank === 2 ? '#C7C9CC' : rank === 3 ? '#CE8946' : null;
  return (
    <Pressable
      accessibilityRole="button"
      testID={selected ? 'ranked-current-player-row' : undefined}
      onPress={onPress}
      style={[
        styles.rankRow,
        {
          borderColor: selected
            ? colorWithAlpha('#008000', 0.7)
            : colorWithAlpha(theme.outlineVariant, 0.3),
        },
        selected && { backgroundColor: colorWithAlpha('#008000', 0.14), borderWidth: 1.5 },
      ]}
    >
      <View style={styles.rankNumber}>
        {medal ? <Trophy size={22} color={medal} /> : <CKText role="labelMedium">#{rank}</CKText>}
      </View>
      <View style={styles.grow}>
        <CKText role="rowTitle">{member.playerName}</CKText>
        <CKText muted role="labelSmall">
          {member.clanName || member.playerTag}
        </CKText>
      </View>
      <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.miniImage} />
      <CKText role="titleMedium">
        {member.leagueTrophies.toLocaleString(toIntlLocale(locale))}
      </CKText>
    </Pressable>
  );
}

function HistoryPanel({
  periods,
  showTable,
  locale,
  onToggle,
}: {
  periods: readonly RankedPeriod[];
  showTable: boolean;
  locale: string;
  onToggle: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const highlights = rankedTierHighlights(periods);
  const [tierIndex, setTierIndex] = useState(0);
  const [pagerWidth, setPagerWidth] = useState(0);
  const pagerRef = useRef<ScrollView>(null);
  return (
    <View style={styles.section}>
      <Pressable
        accessibilityLabel={showTable ? t('tooltipShowChart') : t('tooltipShowTable')}
        onPress={onToggle}
        style={styles.historyToggle}
      >
        {showTable ? <ChartLine color={theme.onSurface} /> : <List color={theme.onSurface} />}
      </Pressable>
      {highlights.length ? (
        <View onLayout={(event) => setPagerWidth(event.nativeEvent.layout.width)}>
          <ScrollView
            ref={pagerRef}
            horizontal
            pagingEnabled
            showsHorizontalScrollIndicator={false}
            onMomentumScrollEnd={(event) => {
              if (pagerWidth > 0) {
                setTierIndex(Math.round(event.nativeEvent.contentOffset.x / pagerWidth));
              }
            }}
          >
            {highlights.map((highlight, index) => (
              <View
                key={highlight.tier?.id ?? highlight.lastPeriod.seasonId}
                style={{ width: pagerWidth || 1 }}
              >
                <TierHighlightCard highlight={highlight} locale={locale} overall={index === 0} />
              </View>
            ))}
          </ScrollView>
          {highlights.length > 1 ? (
            <View style={styles.pageDots}>
              {highlights.map((highlight, index) => (
                <Pressable
                  key={highlight.tier?.id ?? index}
                  onPress={() => {
                    setTierIndex(index);
                    pagerRef.current?.scrollTo({ x: index * pagerWidth, animated: true });
                  }}
                  style={[
                    styles.pageDot,
                    index === tierIndex && { backgroundColor: theme.primary },
                  ]}
                />
              ))}
            </View>
          ) : null}
        </View>
      ) : null}
      {!highlights.length ? <EmptyState title={t('generalNoDataAvailable')} /> : null}
      {periods.length ? (
        showTable ? (
          <HistoryList periods={periods} locale={locale} />
        ) : (
          <RankedLineChart
            title={t('legendsEosTrophies')}
            series={[rankedHistorySeries(periods)]}
            xLabel={(point) => formatShortDate(new Date(point.label), locale)}
            yLabel={(value) => Math.round(value).toLocaleString(toIntlLocale(locale))}
          />
        )
      ) : null}
    </View>
  );
}

function TierHighlightCard({
  highlight,
  locale,
  overall,
}: {
  highlight: ReturnType<typeof rankedTierHighlights>[number];
  locale: string;
  overall: boolean;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface style={[styles.highlightCard, overall && styles.highlightBest]}>
      <View style={styles.cardTitle}>
        {highlight.tier?.largeIconUrl ? (
          <MobileWebImage imageUrl={highlight.tier.largeIconUrl} style={styles.tierIcon} />
        ) : (
          <Trophy size={32} color={theme.onSurfaceVariant} />
        )}
        <CKText role="sectionTitle" style={styles.grow} numberOfLines={1}>
          {highlight.tier?.name ?? t('rankedLeagueNoGroup')}
        </CKText>
        {overall ? <Trophy size={18} color="#FFD75E" /> : null}
      </View>
      <View style={styles.highlightGrid}>
        <HighlightStat
          label={t('rankedLeagueLastPeriod')}
          period={highlight.lastPeriod}
          locale={locale}
        />
        <HighlightStat
          label={t('rankedLeagueBestGroupRank')}
          period={highlight.bestRankPeriod}
          locale={locale}
        />
        <HighlightStat
          label={t('legendsBestTrophies')}
          period={highlight.bestTrophiesPeriod}
          locale={locale}
        />
        <HighlightStat
          label={t('legendsMostAttacks')}
          period={highlight.mostAttacksPeriod}
          locale={locale}
        />
      </View>
    </Surface>
  );
}

function HighlightStat({
  label,
  period,
  locale,
}: {
  label: string;
  period: RankedPeriod | null;
  locale: string;
}) {
  const theme = useCKTheme();
  if (!period) return <View style={styles.highlightStat} />;
  return (
    <View style={styles.highlightStat}>
      <CKText muted role="labelSmall" numberOfLines={1}>
        {label}
      </CKText>
      <CKText muted role="labelSmall">
        {formatLongDate(period.startsAt, locale)}
      </CKText>
      <View style={styles.highlightValue}>
        <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.miniImage} />
        <CKText role="labelMedium">{period.trophies.toLocaleString(toIntlLocale(locale))}</CKText>
      </View>
      <View style={styles.highlightValue}>
        <ChartLine size={16} color={theme.onSurfaceVariant} />
        <CKText role="labelMedium">{period.placement > 0 ? `#${period.placement}` : '—'}</CKText>
      </View>
      <View style={styles.highlightValue}>
        <MobileWebImage imageUrl={ImageAssets.sword} style={styles.miniImage} />
        <CKText role="labelMedium">{period.attackCount}</CKText>
      </View>
    </View>
  );
}

function HistoryList({ periods, locale }: { periods: readonly RankedPeriod[]; locale: string }) {
  const theme = useCKTheme();
  return (
    <View style={styles.historyList}>
      {periods.map((period) => (
        <Surface key={period.seasonId} style={styles.historyRow}>
          {period.tier?.largeIconUrl ? (
            <MobileWebImage imageUrl={period.tier.largeIconUrl} style={styles.historyTierIcon} />
          ) : (
            <Trophy size={44} color={theme.onSurfaceVariant} />
          )}
          <View style={styles.grow}>
            <CKText role="rowTitle" numberOfLines={1}>
              {period.tier?.name ?? formatLongDate(period.startsAt, locale)}
            </CKText>
            {period.tier ? (
              <CKText muted role="labelMedium">
                {formatLongDate(period.startsAt, locale)}
              </CKText>
            ) : null}
            <View style={styles.historyChips}>
              <HistoryChip
                image={ImageAssets.trophies}
                value={period.trophies.toLocaleString(toIntlLocale(locale))}
              />
              <HistoryChip value={period.placement > 0 ? `#${period.placement}` : '—'} />
              <HistoryChip
                image={ImageAssets.sword}
                value={`${period.attackCount} (${period.attackStars}★)`}
              />
              <HistoryChip
                image={ImageAssets.shieldWithArrow}
                value={`${period.defenseCount} (${period.defenseStars}★)`}
              />
            </View>
          </View>
        </Surface>
      ))}
    </View>
  );
}

function HistoryChip({ image, value }: { image?: string; value: string }) {
  const theme = useCKTheme();
  return (
    <View style={styles.historyChip}>
      {image ? (
        <MobileWebImage imageUrl={image} style={styles.chipImage} />
      ) : (
        <ChartLine size={18} color={theme.onSurfaceVariant} />
      )}
      <CKText role="labelLarge">{value}</CKText>
    </View>
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

function InfoModal({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={styles.modalScrim}>
        <Surface style={[styles.infoDialog, { backgroundColor: theme.surface }]}>
          <CKText role="sectionTitle" style={[styles.infoDialogTitle, { color: theme.primary }]}>
            {t('rankedLeagueAbout')}
          </CKText>
          <ScrollView
            style={styles.infoDialogScroll}
            contentContainerStyle={styles.infoDialogContent}
          >
            <CKText>{t('rankedLeagueAboutBody')}</CKText>
          </ScrollView>
          <Pressable
            testID="ranked-info-action"
            accessibilityRole="button"
            onPress={onClose}
            style={styles.infoDialogAction}
          >
            <CKText role="labelLarge" style={{ color: theme.primary }}>
              {t('generalOk')}
            </CKText>
          </Pressable>
        </Surface>
      </View>
    </Modal>
  );
}

function MiniStat({ label, value }: { label: string; value: string | number }) {
  return (
    <View style={styles.miniStat}>
      <CKText role="titleMedium">{value}</CKText>
      <CKText role="labelSmall" muted>
        {label}
      </CKText>
    </View>
  );
}
function RankedSkeleton() {
  return (
    <View style={styles.section}>
      <Skeleton height={64} />
      <View style={styles.grid}>
        <Skeleton height={160} />
        <Skeleton height={160} />
      </View>
      <Skeleton height={360} />
    </View>
  );
}
function formatPeriodRange(date: Date, locale: string) {
  const end = new Date(date.getTime() + 7 * 86_400_000);
  const formatter = new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'short',
    day: 'numeric',
  });
  return `${formatter.format(date)} - ${formatter.format(end)}`;
}

function formatShortDate(date: Date, locale: string) {
  return new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'numeric',
    day: 'numeric',
  }).format(date);
}

function formatLongDate(date: Date, locale: string) {
  return new Intl.DateTimeFormat(toIntlLocale(locale), {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(date);
}

function rankedClanIdentity(player: Player) {
  const clan = player.clan;
  if (typeof clan === 'object' && clan !== null) {
    const record = clan as Record<string, unknown>;
    const name = typeof record.name === 'string' ? record.name : '';
    const badges = record.badgeUrls;
    const badgeUrl =
      typeof badges === 'object' &&
      badges !== null &&
      typeof (badges as Record<string, unknown>).small === 'string'
        ? ((badges as Record<string, unknown>).small as string)
        : '';
    if (name) return { name, badgeUrl };
  }
  return { name: player.clanOverview.name, badgeUrl: player.clanOverview.badgeUrls.small };
}

const styles = StyleSheet.create({
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
    right: -2,
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
    paddingHorizontal: 10,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  headerMetricImage: { width: 34, height: 34 },
  headerMetricValue: { flexDirection: 'row', alignItems: 'center', gap: 3, marginTop: 2 },
  headerMetricSubtitleImage: { width: 14, height: 14 },
  headerQuick: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
  },
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
    minHeight: 62,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 16,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: ckRadius.control,
    marginBottom: 6,
  },
  rankNumber: { width: 32, alignItems: 'center' },
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
