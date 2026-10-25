import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
  type ReactElement,
} from 'react';
import {
  Animated,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  Linking,
  type NativeSyntheticEvent,
  type NativeScrollEvent,
} from 'react-native';
import { ArrowDown, ArrowUp, ChevronRight, ExternalLink, Trophy } from 'lucide-react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAppRuntime } from '../../core/app/runtime-context';
import { queueAppLink } from '../../core/deep-links/link-inbox';
import { ImageAssets } from '../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../i18n';
import {
  CKText,
  SkeletonContent,
  useSkeletonContent,
  MobileWebImage,
  PressableSurface,
  SelectionPicker,
  colorWithAlpha,
  useCKTheme,
} from '../../ui';
import { ProfileTabs } from '../../ui/profile-tabs';
import { PagerView, type PagerViewHandle } from '../../ui/pager';
import { usePrimarySwipeGuard } from '../../ui/primary-swipe-guard';
import { useCKAccessibility } from '../../ui/accessibility';
import { SlidingSegmentControl } from '../../ui/sliding-segment-control';
import { prefetchMobileImage } from '../../ui/mobile-web-image';
import { competitiveService } from './competitive-service';
import { COMPETITIVE_ESPORTS_COVER } from './competitive-artwork';

type Response<T> = { source: string; fetchedAt: string; data: T | null };
type Team = {
  name: string;
  logo_url: string | null;
  elo: number | null;
  players: { tag: string; name: string }[];
  clans: { tag: string; name: string }[];
  stats?: { wins: number; ties: number; losses: number; offense: Stats; defense: Stats } | null;
};
type Stats = {
  attacks: number | null;
  triples: number | null;
  avg_stars: number | null;
  avg_perc: number | null;
  avg_duration: number | null;
  doubles?: number | null;
  singles?: number | null;
  zeros?: number | null;
};
type Player = {
  name: string;
  picture_url: string | null;
  accounts: { tag: string; name: string }[];
  stats_offense: Stats | null;
  stats_defense: Stats | null;
};
type Party = {
  team_id?: string | number | null;
  clantag: string;
  team_name: string | null;
  logo_url: string | null;
  source_team: { name: string };
  result: {
    stars: number | null;
    percentage: number | null;
    duration?: number | null;
    win?: boolean | null;
    final?: boolean | null;
  } | null;
  attacks: {
    attacker: { name: string; tag: string };
    defender: { name: string; tag: string };
    stars: number;
    percentage: number;
    duration: number;
    attack_order: number;
  }[];
};
type Match = {
  match_id: string | null;
  event?: { name: string; logo_url?: string | null } | null;
  week?: { name: string } | null;
  preparation_start: string;
  team1: Party | null;
  team2: Party | null;
};
type UpcomingParty = {
  ccn_team_id: number | null;
  ccn_team_logo_url: string | null;
  ccn_team_name: string | null;
  source_team_name: string;
  source_team_logo_url: string | null;
};
type Upcoming = {
  upcoming_matches: {
    upcoming_match_id: number;
    match_date: string;
    team1: UpcomingParty;
    team2: UpcomingParty;
    streams?: {
      stream_id: number;
      streamer_name: string;
      streamer_language: string | null;
      platform: string;
      link: string;
      start: string;
    }[];
  }[];
};
type Scene =
  { kind: 'ccnTeam'; id: string } | { kind: 'ccnPlayer'; tag: string } | { kind: 'tournaments' };

function useCcn<T>(path: string | null) {
  const contentLoading = useSkeletonContent();
  const runtime = useAppRuntime();
  const service = useMemo(() => competitiveService(runtime), [runtime]);
  const [revision, setRevision] = useState(0);
  const [state, setState] = useState<{
    path: string | null;
    data?: T | null;
    loading: boolean;
    error?: string;
  }>({ path, loading: !!path });
  useEffect(() => {
    if (!path || contentLoading) return;
    let active = true;
    const controller = new AbortController();
    void service
      .request<Response<T>>(`/esports/ccn/${path}`, 'GET', undefined, true, {
        signal: controller.signal,
        force: revision > 0,
      })
      .then((response) => {
        if (active) setState({ path, data: response.data, loading: false });
      })
      .catch((error: Error) => {
        if (active)
          setState((old) => ({
            path,
            data: old.path === path ? old.data : undefined,
            loading: false,
            error: error.message,
          }));
      });
    return () => {
      active = false;
      controller.abort();
    };
  }, [path, service, revision, contentLoading]);
  const refresh = useCallback(() => {
    setState((old) => ({ ...old, loading: true, error: undefined }));
    setRevision((value) => value + 1);
  }, []);
  return {
    data: state.path === path ? state.data : undefined,
    loading: !!path && (state.path !== path || state.loading),
    error: state.path === path ? state.error : undefined,
    refresh,
  };
}

function Frame({
  children,
  refresh,
  refreshing = false,
  scrollY,
  onEndReached,
  rows,
}: {
  children: ReactNode;
  refresh?: () => void;
  refreshing?: boolean;
  scrollY?: Animated.Value;
  onEndReached?: () => void;
  rows?: ReactElement[];
}) {
  const theme = useCKTheme();
  const onScroll = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const { contentOffset, contentSize, layoutMeasurement } = event.nativeEvent;
    if (contentOffset.y + layoutMeasurement.height >= contentSize.height - 500) onEndReached?.();
  };
  const scrollProps = {
    onScroll: scrollY
      ? Animated.event([{ nativeEvent: { contentOffset: { y: scrollY } } }], {
          useNativeDriver: Platform.OS !== 'web',
          ...(onEndReached ? { listener: onScroll } : {}),
        })
      : onEndReached
        ? onScroll
        : undefined,
    scrollEventThrottle: 16,
    style: { backgroundColor: theme.background === '#030304' ? '#170D2A' : '#F4F0FC' },
    contentContainerStyle: styles.page,
    refreshControl: refresh ? (
      <RefreshControl onRefresh={refresh} refreshing={refreshing} tintColor={theme.primary} />
    ) : undefined,
  };
  if (rows)
    return (
      <Animated.FlatList
        {...scrollProps}
        data={rows}
        ListHeaderComponent={<>{children}</>}
        keyExtractor={(item, index) => String(item.key ?? index)}
        renderItem={({ item }) => <View style={styles.virtualRow}>{item}</View>}
        initialNumToRender={6}
        maxToRenderPerBatch={4}
        windowSize={7}
        // Cards can expand to show attacks. Keep clipping off so dynamically
        // resized rows do not disappear on iOS; virtualization still bounds mounts.
        removeClippedSubviews={false}
      />
    );
  return <Animated.ScrollView {...scrollProps}>{children}</Animated.ScrollView>;
}
function Feedback({
  query,
  empty,
}: {
  query: { loading: boolean; error?: string; data?: unknown; refresh: () => void };
  empty?: boolean;
  kind?: 'list' | 'profile' | 'war' | 'stats';
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  if (query.error)
    return (
      <Pressable
        onPress={query.refresh}
        accessibilityRole="button"
        style={[styles.feedback, { backgroundColor: colorWithAlpha(theme.onSurface, 0.05) }]}
      >
        <CKText>{t('competitiveUnavailable')}</CKText>
        <CKText style={{ color: theme.primary }}>{t('generalRetry')}</CKText>
      </Pressable>
    );
  return empty && !query.loading ? (
    <View style={styles.feedback}>
      <CKText muted>{t('generalNoDataAvailable')}</CKText>
    </View>
  ) : null;
}
function IdentityArt({
  url,
  size = 42,
  name,
  portrait = false,
  inverse = false,
}: {
  url?: string | null;
  size?: number;
  name: string;
  portrait?: boolean;
  inverse?: boolean;
}) {
  const theme = useCKTheme();
  const [loadedUrl, setLoadedUrl] = useState<string>();
  const monogram = (
    <CKText
      style={{
        fontSize: size * 0.35,
        fontWeight: '800',
        color: inverse ? '#fff' : theme.onSurfaceVariant,
      }}
    >
      {name
        .trim()
        .split(/\s+/)
        .slice(0, 2)
        .map((word) => word[0])
        .join('')}
    </CKText>
  );
  return (
    <View
      style={{
        width: size,
        height: size,
        borderRadius: portrait ? size / 2 : size * 0.24,
        backgroundColor: colorWithAlpha(inverse ? '#ffffff' : theme.onSurface, 0.07),
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
      }}
    >
      {!url || loadedUrl !== url ? monogram : null}
      {url ? (
        <MobileWebImage
          imageUrl={url}
          contentFit={portrait ? 'cover' : 'contain'}
          contentPosition={portrait ? 'top center' : 'center'}
          errorFallback={monogram}
          transition={180}
          cachePolicy="memory-disk"
          onLoad={() => setLoadedUrl(url)}
          style={{ position: 'absolute', width: size, height: size }}
        />
      ) : null}
    </View>
  );
}
function Row({
  name,
  subtitle,
  logo,
  onPress,
  trailing,
}: {
  name: string;
  subtitle?: string;
  logo?: string | null;
  onPress?: () => void;
  trailing?: ReactNode;
}) {
  const theme = useCKTheme();
  return (
    <PressableSurface
      onPress={onPress}
      disabled={!onPress}
      accessibilityRole={onPress ? 'button' : undefined}
      style={[styles.row, { backgroundColor: theme.card, borderWidth: 0 }]}
    >
      <IdentityArt url={logo} name={name} />
      <View style={styles.grow}>
        <CKText role="rowTitle">{name}</CKText>
        {subtitle ? (
          <CKText muted role="metadata">
            {subtitle}
          </CKText>
        ) : null}
      </View>
      {trailing}
      {onPress ? <ChevronRight size={16} color={theme.onSurfaceVariant} /> : null}
    </PressableSurface>
  );
}

type EloTeam = {
  rank: number;
  team_id: number;
  team: string;
  logo_url: string | null;
  elo: number;
  rankMovement30d?: number | null;
  newToRanking30d?: boolean;
};
type EloRanking = {
  timestamp: string;
  total: number;
  offset: number;
  limit: number;
  teams: EloTeam[];
};
type EloFeed = {
  teams: EloTeam[];
  recent: Match[];
  upcoming: Upcoming['upcoming_matches'];
  failures: { teamId: number; kind: string }[];
};
const loadingStats: Stats = {
  attacks: 100,
  triples: 50,
  avg_stars: 2.5,
  avg_perc: 95,
  avg_duration: 150,
  doubles: 20,
  singles: 20,
  zeros: 10,
};
const loadingParty: Party = {
  clantag: '',
  team_name: 'Esports team',
  logo_url: 'loading',
  source_team: { name: 'Esports team' },
  result: { stars: 15, percentage: 100 },
  attacks: [],
};
const loadingMatches: Match[] = [0, 1, 2].map((index) => ({
  match_id: `loading-${index}`,
  preparation_start: '2000-01-01T00:00:00Z',
  event: { name: 'Tournament match' },
  team1: loadingParty,
  team2: loadingParty,
}));
const loadingUpcoming: Upcoming['upcoming_matches'] = [0, 1].map((index) => ({
  upcoming_match_id: index,
  match_date: '2000-01-01T00:00:00Z',
  team1: {
    ccn_team_id: null,
    ccn_team_logo_url: 'loading',
    ccn_team_name: 'Esports team',
    source_team_name: 'Esports team',
    source_team_logo_url: null,
  },
  team2: {
    ccn_team_id: null,
    ccn_team_logo_url: 'loading',
    ccn_team_name: 'Esports team',
    source_team_name: 'Esports team',
    source_team_logo_url: null,
  },
}));
function ccnDate(value: string) {
  return new Date(/(?:Z|[+-]\d\d:\d\d)$/.test(value) ? value : `${value}Z`);
}

export function EsportsLanding({ push }: { push: (scene: Scene) => void }) {
  const insets = useSafeAreaInsets();
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const [scrollY] = useState(() => new Animated.Value(0));
  const [month, setMonth] = useState('current');
  const [page, setPage] = useState(0);
  const [loaded, setLoaded] = useState<{
    month: string;
    page: number;
    teams: EloTeam[];
    timestamp?: string;
    response?: EloRanking;
  }>({ month: 'current', page: -1, teams: [] });
  const loadingNext = useRef(false);
  const [feedTab, setFeedTab] = useState('recent');
  const [viewTab, setViewTab] = useState('rankings');
  const [heroSize, setHeroSize] = useState({ width: 0, height: 0 });
  const months = useMemo(() => {
    const now = new Date();
    return Array.from({ length: 12 }, (_, index) => {
      const date = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - index - 1, 1));
      return {
        key: date.toISOString().slice(0, 7),
        date,
        timestamp: new Date(
          Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 1) - 1,
        ).toISOString(),
      };
    });
  }, []);
  const selectedMonth = months.find((item) => item.key === month);
  const ranking = useCcn<EloRanking>(
    `elo?offset=${page * 50}${selectedMonth || (page > 0 && loaded.month === month && loaded.timestamp) ? `&timestamp=${encodeURIComponent(selectedMonth?.timestamp ?? loaded.timestamp!)}` : ''}`,
  );
  const movement = useCcn<EloRanking>(
    month === 'current' && ranking.data
      ? `elo?movement=1&offset=${page * 50}&timestamp=${encodeURIComponent(ccnDate(ranking.data.timestamp).toISOString())}`
      : null,
  );
  const [rankChanges, setRankChanges] = useState<{
    response?: EloRanking;
    teams: Map<number, EloTeam>;
  }>({ teams: new Map() });
  if (movement.data && movement.data !== rankChanges.response) {
    setRankChanges({
      response: movement.data,
      teams: new Map([
        ...rankChanges.teams,
        ...movement.data.teams.map((team) => [team.team_id, team] as const),
      ]),
    });
  }
  if (ranking.data && !ranking.loading && ranking.data !== loaded.response) {
    const data = ranking.data;
    setLoaded((old) => {
      const previous = page === 0 || old.month !== month ? [] : old.teams;
      const teams = new Map(previous.map((team) => [team.team_id, team]));
      data.teams.forEach((team) => teams.set(team.team_id, team));
      return {
        month,
        page,
        teams: [...teams.values()],
        timestamp: ccnDate(data.timestamp).toISOString(),
        response: data,
      };
    });
  }
  useEffect(() => {
    if (ranking.loading) return;
    loadingNext.current = false;
  }, [ranking.loading]);
  const loadNext = () => {
    // Gate repeated near-bottom scroll events until this page is appended.
    // Keep one timestamp across pages so live rank changes cannot skip teams.
    if (
      viewTab !== 'rankings' ||
      loadingNext.current ||
      ranking.loading ||
      ranking.error ||
      !ranking.data ||
      loaded.month !== month ||
      loaded.page !== page ||
      (page + 1) * 50 >= ranking.data.total
    )
      return;
    loadingNext.current = true;
    setPage((value) => value + 1);
  };
  // This feed deliberately stays current when browsing a historical ranking.
  // The server owns the bounded top-50 fan-out and shared five-minute cache.
  const feed = useCcn<EloFeed>('elo-matches');
  const openTeam = (team: EloTeam) => {
    teamPreviews.set(String(team.team_id), { name: team.team, logo_url: team.logo_url });
    push({ kind: 'ccnTeam', id: String(team.team_id) });
  };
  return (
    <Frame
      scrollY={reduceMotion ? undefined : scrollY}
      onEndReached={viewTab === 'rankings' ? loadNext : undefined}
      rows={
        viewTab === 'matches'
          ? feedTab === 'recent'
            ? (feed.data?.recent ?? (feed.loading ? loadingMatches : [])).map((match) => (
                <SkeletonContent key={match.match_id!} loading={feed.loading && !feed.data}>
                  <TeamMatch match={match} push={push} />
                </SkeletonContent>
              ))
            : (feed.data?.upcoming ?? (feed.loading ? loadingUpcoming : [])).map((match) => (
                <SkeletonContent key={match.upcoming_match_id} loading={feed.loading && !feed.data}>
                  <UpcomingMatch match={match} push={push} />
                </SkeletonContent>
              ))
          : undefined
      }
      refresh={() => {
        setPage(0);
        loadingNext.current = false;
        ranking.refresh();
        feed.refresh();
      }}
      refreshing={page === 0 && ranking.loading && !!ranking.data}
    >
      <View
        style={[styles.hero, { minHeight: 330 + insets.top, paddingTop: 100 + insets.top }]}
        onLayout={({ nativeEvent }) => {
          const { width, height } = nativeEvent.layout;
          setHeroSize((old) =>
            old.width === width && old.height === height ? old : { width, height },
          );
        }}
      >
        <Animated.View
          style={[
            StyleSheet.absoluteFill,
            !reduceMotion && {
              transform: [
                {
                  translateY: scrollY.interpolate({
                    inputRange: [0, 400],
                    outputRange: [0, 75],
                    extrapolate: 'clamp',
                  }),
                },
              ],
            },
          ]}
        >
          <MobileWebImage
            imageUrl={COMPETITIVE_ESPORTS_COVER}
            contentFit="cover"
            contentPosition={{ left: '50%', top: '30%' }}
            style={StyleSheet.absoluteFill}
          />
        </Animated.View>
        {heroSize.width > 0 ? (
          <Svg
            pointerEvents="none"
            width={heroSize.width}
            height={heroSize.height + 2}
            viewBox={`0 0 ${heroSize.width} ${heroSize.height}`}
            style={StyleSheet.absoluteFill}
          >
            <Defs>
              <LinearGradient id="esports-hero-fade" x1="0%" y1="0%" x2="0%" y2="100%">
                <Stop offset="0" stopColor="#170D2A" stopOpacity={0.08} />
                <Stop offset="0.45" stopColor="#170D2A" stopOpacity={0.08} />
                <Stop offset="0.78" stopColor="#170D2A" stopOpacity={0.72} />
                <Stop
                  offset="0.99"
                  stopColor={theme.background === '#030304' ? '#170D2A' : '#F4F0FC'}
                />
                <Stop
                  offset="1"
                  stopColor={theme.background === '#030304' ? '#170D2A' : '#F4F0FC'}
                />
              </LinearGradient>
            </Defs>
            <Rect
              width={heroSize.width}
              height={heroSize.height + 2}
              fill="url(#esports-hero-fade)"
            />
          </Svg>
        ) : null}
        {/* Cover subpixel rounding at the image/SVG crop boundary on Android. */}
        <View
          pointerEvents="none"
          style={{
            position: 'absolute',
            left: 0,
            right: 0,
            bottom: -1,
            height: 3,
            backgroundColor: theme.background === '#030304' ? '#170D2A' : '#F4F0FC',
          }}
        />
        <View style={styles.heroCopy}>
          <CKText style={[styles.heroTitle, styles.white]}>{t('clanRankingsTab')} · Elo</CKText>
          <View style={styles.sourceAttribution}>
            <CKText style={styles.heroSubtitle}>{t('esportsEloSubtitle')}</CKText>
            <MobileWebImage
              imageUrl="https://competitiveclash.network/img/logo.png"
              contentFit="contain"
              style={{ width: 20, height: 20 }}
            />
            <CKText style={styles.heroSubtitle}>CCN</CKText>
          </View>
        </View>
      </View>
      <View style={[styles.content, { paddingTop: 4 }]}>
        <ProfileTabs
          variant="underline"
          selectedKey={viewTab}
          onSelect={setViewTab}
          tabs={[
            { key: 'rankings', label: t('clanRankingsTab') },
            { key: 'matches', label: t('esportsMatches') },
          ]}
        />
        {viewTab === 'rankings' ? (
          <>
            <SelectionPicker
              fillWidth
              title={t('filtersMonth')}
              selectedKey={month}
              onSelect={(key) => {
                setMonth(key);
                setPage(0);
                loadingNext.current = false;
              }}
              options={[
                { key: 'current', label: t('rankingsCurrent') },
                ...months.map((item) => ({
                  key: item.key,
                  label: item.date.toLocaleDateString(toIntlLocale(locale), {
                    month: 'long',
                    year: 'numeric',
                    timeZone: 'UTC',
                  }),
                })),
              ]}
            />
            <View style={styles.sectionHeading}>
              <CKText role="sectionTitle">{t('esportsTeamRatings')}</CKText>
              <CKText muted role="metadata">
                {ranking.data?.total.toLocaleString(toIntlLocale(locale)) ?? '—'}{' '}
                {t('competitiveTeams')}
              </CKText>
            </View>
            {page === 0 ? (
              <Feedback query={ranking} empty={!!ranking.data && !ranking.data.teams.length} />
            ) : null}
            <SkeletonContent
              loading={ranking.loading && (loaded.month !== month || !loaded.teams.length)}
              style={styles.standings}
            >
              {(loaded.month === month && loaded.teams.length
                ? loaded.teams
                : ranking.loading
                  ? [0, 1, 2, 3].map((index) => ({
                      rank: index + 1,
                      team_id: index,
                      team: 'Esports team',
                      logo_url: 'loading',
                      elo: 1200,
                    }))
                  : []
              ).map((team) => {
                const medal =
                  team.rank <= 3 ? ['#E8AF3B', '#A4B4D1', '#C78A65'][team.rank - 1] : null;
                return (
                  <PressableSurface
                    key={team.team_id}
                    accessibilityRole="button"
                    onPress={() => openTeam(team)}
                    style={[
                      styles.standingRow,
                      {
                        backgroundColor: medal ? colorWithAlpha(medal, 0.13) : theme.card,
                        borderWidth: 0,
                      },
                    ]}
                  >
                    <View
                      style={[
                        styles.rank,
                        {
                          backgroundColor: colorWithAlpha(
                            medal ?? theme.onSurface,
                            medal ? 0.2 : 0.05,
                          ),
                        },
                      ]}
                    >
                      <CKText role="titleSmall" style={medal ? { color: medal } : undefined}>
                        {team.rank}
                      </CKText>
                    </View>
                    <IdentityArt url={team.logo_url} name={team.team} size={48} />
                    <CKText role="rowTitle" style={styles.grow}>
                      {team.team}
                    </CKText>
                    <View style={styles.score}>
                      <CKText role="titleSmall">
                        {team.elo.toLocaleString(toIntlLocale(locale))}
                      </CKText>
                      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
                        {month === 'current' &&
                        rankChanges.teams.get(team.team_id)?.rankMovement30d != null ? (
                          <RankMovement
                            value={rankChanges.teams.get(team.team_id)!.rankMovement30d!}
                          />
                        ) : null}
                        <CKText muted role="metadata">
                          Elo
                        </CKText>
                      </View>
                    </View>
                    <ChevronRight size={17} color={theme.onSurfaceVariant} />
                  </PressableSurface>
                );
              })}
            </SkeletonContent>
            {page > 0 ? <Feedback query={ranking} /> : null}
          </>
        ) : (
          <>
            <View style={{ gap: 8 }}>
              <CKText role="sectionTitle">{t('esportsMatches')}</CKText>
              <CKText muted role="metadata">
                {t('esportsTopTeamsMatches')}
              </CKText>
            </View>
            <SlidingSegmentControl
              isRtl={isRtl}
              value={feedTab}
              onChange={setFeedTab}
              options={[
                { value: 'recent', label: t('esportsRecentMatches') },
                { value: 'upcoming', label: t('homeUpcomingTitle') },
              ]}
            />
            <Feedback
              query={feed}
              kind="war"
              empty={
                !!feed.data &&
                !(feedTab === 'recent' ? feed.data.recent.length : feed.data.upcoming.length)
              }
            />
            {feed.data?.failures.length ? (
              <CKText muted role="metadata">
                {t('esportsPartialMatches')}
              </CKText>
            ) : null}
          </>
        )}
      </View>
    </Frame>
  );
}
function UpcomingMatch({
  match,
  push,
}: {
  match: Upcoming['upcoming_matches'][number];
  push: (scene: Scene) => void;
}) {
  const theme = useCKTheme();
  const { locale } = useI18n();
  return (
    <View style={[styles.match, { backgroundColor: theme.card }]}>
      <CKText muted role="metadata">
        {ccnDate(match.match_date).toLocaleString(toIntlLocale(locale), {
          dateStyle: 'medium',
          timeStyle: 'short',
        })}
      </CKText>
      {[match.team1, match.team2].map((party, index) => (
        <Row
          key={index}
          name={party.ccn_team_name ?? party.source_team_name}
          logo={party.ccn_team_logo_url ?? party.source_team_logo_url}
          onPress={
            party.ccn_team_id == null
              ? undefined
              : () => push({ kind: 'ccnTeam', id: String(party.ccn_team_id) })
          }
        />
      ))}
      <MatchStreams streams={match.streams} />
    </View>
  );
}

function RankMovement({ value }: { value: number }) {
  const theme = useCKTheme();
  // Unchanged placement has no movement badge; zero adds noise beside Elo.
  if (value === 0) return null;
  const color = value > 0 ? '#14A37F' : value < 0 ? theme.error : theme.onSurfaceVariant;
  const Icon = value < 0 ? ArrowDown : ArrowUp;
  return (
    <View
      style={{ flexDirection: 'row', alignItems: 'center', gap: 3 }}
      accessible
      accessibilityLabel={`${value > 0 ? '+' : ''}${value}`}
    >
      {value ? <Icon size={12} color={color} /> : null}
      <CKText role="labelMedium" style={{ color }}>
        {Math.abs(value)}
      </CKText>
    </View>
  );
}

function PerformanceStats({ stats, label }: { stats: Stats; label: string }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const duration = stats.avg_duration == null ? null : Math.round(stats.avg_duration);
  return (
    <View style={[styles.performance, { backgroundColor: theme.card }]}>
      <CKText role="sectionTitle">{label}</CKText>
      <View style={styles.metricRow}>
        <Metric label={t('esportsBattles')} value={stats.attacks ?? '—'} />
        <Metric
          label={t('legendsHitrate')}
          value={
            stats.attacks && stats.triples != null
              ? `${((100 * stats.triples) / stats.attacks).toFixed(1)}%`
              : '—'
          }
        />
        <Metric label={t('esportsAverageStars')} value={stats.avg_stars?.toFixed(2) ?? '—'} />
        <Metric
          label={t('esportsDestruction')}
          value={stats.avg_perc == null ? '—' : `${stats.avg_perc.toFixed(1)}%`}
        />
        <Metric
          label={t('warAttacksDetailsDuration')}
          value={
            duration == null
              ? '—'
              : `${Math.floor(duration / 60)}:${String(duration % 60).padStart(2, '0')}`
          }
        />
      </View>
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', gap: 8 }}>
        {[stats.zeros, stats.singles, stats.doubles, stats.triples].map((count, stars) => (
          <View
            key={stars}
            style={{ alignItems: 'center', gap: 5 }}
            accessible
            accessibilityLabel={`${stars} ${t('warStarsTitle')}: ${count ?? '—'}`}
          >
            <View style={{ flexDirection: 'row', gap: 1 }}>
              {[0, 1, 2].map((index) => (
                <MobileWebImage
                  key={index}
                  imageUrl={index < stars ? ImageAssets.attackStar : ImageAssets.emptyStar}
                  style={{ width: 14, height: 14 }}
                />
              ))}
            </View>
            <CKText role="rowTitle">{count ?? '—'}</CKText>
          </View>
        ))}
      </View>
    </View>
  );
}

function MatchStreams({ streams }: { streams: Upcoming['upcoming_matches'][number]['streams'] }) {
  const theme = useCKTheme();
  const { t, locale } = useI18n();
  const [failed, setFailed] = useState(false);
  // Provider URLs are external data, not app deep links or executable schemes.
  const available = (streams ?? []).filter((stream) => {
    try {
      const url = new URL(stream.link);
      return url.protocol === 'https:' && !url.username && !url.password;
    } catch {
      return false;
    }
  });
  if (!available.length) return null;
  return (
    <View style={{ gap: 8, marginTop: 8 }}>
      {available.map((stream) => (
        <PressableSurface
          key={`${stream.stream_id}:${stream.platform}`}
          accessibilityRole="link"
          accessibilityLabel={`${stream.streamer_name} · ${stream.platform}`}
          onPress={() => {
            setFailed(false);
            void Linking.openURL(stream.link).catch(() => setFailed(true));
          }}
          style={{
            flexDirection: 'row',
            alignItems: 'center',
            gap: 10,
            padding: 12,
            borderRadius: 16,
            backgroundColor: colorWithAlpha(theme.secondary, 0.1),
          }}
        >
          <View style={styles.grow}>
            <CKText role="rowTitle">{stream.streamer_name}</CKText>
            <CKText muted role="metadata">
              {[
                stream.platform,
                stream.streamer_language,
                Number.isFinite(ccnDate(stream.start).getTime())
                  ? ccnDate(stream.start).toLocaleString(toIntlLocale(locale), {
                      dateStyle: 'short',
                      timeStyle: 'short',
                    })
                  : null,
              ]
                .filter(Boolean)
                .join(' · ')}
            </CKText>
          </View>
          <ExternalLink size={18} color={theme.secondary} />
        </PressableSurface>
      ))}
      {failed ? (
        <CKText role="metadata" accessibilityLiveRegion="polite">
          {t('generalError')}
        </CKText>
      ) : null}
    </View>
  );
}

function MatchSide({
  name,
  logo,
  score,
  percentage,
  winner,
  onPress,
}: {
  name: string;
  logo?: string | null;
  score: number | null;
  percentage: number | null;
  winner?: boolean | null;
  onPress?: () => void;
}) {
  const content = (
    <>
      <IdentityArt url={logo} name={name} size={40} />
      {winner ? <Trophy color="#E8AF3B" size={16} /> : null}
      <CKText role="rowTitle" style={styles.grow}>
        {name}
      </CKText>
      <View style={styles.score}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
          <CKText role="rowTitle">{score ?? '—'}</CKText>
          <MobileWebImage imageUrl={ImageAssets.attackStar} style={{ width: 18, height: 18 }} />
        </View>
        <CKText muted role="metadata">
          {percentage == null
            ? '—'
            : `${percentage.toLocaleString(undefined, { maximumFractionDigits: 2 })}%`}
        </CKText>
      </View>
    </>
  );
  return onPress ? (
    <Pressable onPress={onPress} accessibilityRole="button" style={styles.matchSide}>
      {content}
    </Pressable>
  ) : (
    <View style={styles.matchSide}>{content}</View>
  );
}

const teamPreviews = new Map<string, { name: string; logo_url: string | null }>();
function PlayerPortrait({ tag, name, size = 52 }: { tag: string; name: string; size?: number }) {
  // Team and battle payloads contain identity only. Fetch the actual profile portrait;
  // a monogram represents missing photography without inventing a Town Hall level.
  const profile = useCcn<Player>(`player?playerTag=${encodeURIComponent(tag)}`);
  return <IdentityArt url={profile.data?.picture_url} name={name} size={size} portrait />;
}

function useRosterPortraitWarmup(players: Team['players'] | undefined) {
  const runtime = useAppRuntime();
  const service = useMemo(() => competitiveService(runtime), [runtime]);
  const tags = (players ?? []).map((player) => player.tag).join(',');
  useEffect(() => {
    let active = true;
    const queue = tags.split(',').filter(Boolean);
    const worker = async () => {
      for (let tag = queue.shift(); active && tag; tag = queue.shift()) {
        try {
          const profile = await service.request<Response<Player>>(
            `/esports/ccn/player?playerTag=${encodeURIComponent(tag)}`,
            'GET',
            undefined,
            true,
          );
          if (active && profile.data?.picture_url) {
            await prefetchMobileImage(profile.data.picture_url, 80, 80);
          }
        } catch {
          // Optional image warming must not delay or fail a roster or navigation.
        }
      }
    };
    void Promise.all(Array.from({ length: Math.min(3, queue.length) }, worker));
    return () => {
      active = false;
    };
  }, [tags, service]);
}
function GameAccount({ tag, name }: { tag: string; name: string }) {
  const runtime = useAppRuntime();
  const contentLoading = useSkeletonContent();
  const [townHall, setTownHall] = useState<number>();
  useEffect(() => {
    if (contentLoading) return;
    let active = true;
    // Current account artwork comes from the existing player service. It must
    // not be reused as a historical Town Hall claim for an older match.
    void runtime.players
      .getPlayerAndClanData(tag)
      .then((player) => {
        if (active && player) setTownHall(player.townHallLevel);
      })
      .catch(() => undefined);
    return () => {
      active = false;
    };
  }, [runtime.players, tag, contentLoading]);
  return (
    <Row
      name={name}
      logo={townHall ? ImageAssets.townHall(townHall) : undefined}
      onPress={() => queueAppLink(`/player/${encodeURIComponent(tag)}`)}
    />
  );
}
function Metric({
  value,
  label,
  accent,
  compact = false,
}: {
  value: string | number;
  label: string;
  accent?: string;
  compact?: boolean;
}) {
  return (
    <View
      style={[
        styles.metric,
        compact && { flexBasis: 'auto', paddingRight: 0, alignItems: 'center' },
      ]}
    >
      <CKText
        style={[
          styles.metricValue,
          compact && { textAlign: 'center' },
          accent ? { color: accent } : undefined,
        ]}
      >
        {value}
      </CKText>
      <CKText muted role="metadata" style={compact ? { textAlign: 'center' } : undefined}>
        {label}
      </CKText>
    </View>
  );
}
const TEAM_TABS = ['matches', 'roster', 'stats'] as const;
type TeamTab = (typeof TEAM_TABS)[number];

export function EsportsTeam({ id, push }: { id: string; push: (scene: Scene) => void }) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const [tab, setTab] = useState<TeamTab>('matches');
  const [settledTab, setSettledTab] = useState<TeamTab>('matches');
  const [tabPosition] = useState(() => new Animated.Value(0));
  const [pageHeights, setPageHeights] = useState<Partial<Record<TeamTab, number>>>({});
  const pager = useRef<PagerViewHandle>(null);
  const { reduceMotion } = useCKAccessibility();
  const blockPrimarySwipe = usePrimarySwipeGuard();
  useEffect(() => () => blockPrimarySwipe(false), [blockPrimarySwipe]);
  const selectTab = (next: TeamTab) => {
    setTab(next);
    const index = TEAM_TABS.indexOf(next);
    if (reduceMotion) {
      pager.current?.setPageWithoutAnimation(index);
      tabPosition.setValue(index);
      setSettledTab(next);
    } else pager.current?.setPage(index);
  };
  const query = useCcn<Team>(`team?teamId=${encodeURIComponent(id)}`);
  const placement = useCcn<{ team: { rank: number; elo: number } | null }>(
    `elo-team?teamId=${encodeURIComponent(id)}`,
  );
  const matches = useCcn<Match[]>(`team-matches?teamId=${encodeURIComponent(id)}`);
  const upcoming = useCcn<Upcoming>(`team-upcoming?teamId=${encodeURIComponent(id)}`);
  const preview = teamPreviews.get(id);
  const contentLoading = query.loading && !query.data;
  const team: Team | undefined =
    query.data ??
    (contentLoading
      ? {
          name: 'Esports team',
          logo_url: 'loading',
          elo: 1200,
          players: [0, 1, 2, 3, 4].map((index) => ({
            tag: `loading-${index}`,
            name: 'Player name',
          })),
          clans: [],
          stats: { wins: 100, ties: 10, losses: 20, offense: loadingStats, defense: loadingStats },
        }
      : undefined);
  useRosterPortraitWarmup(query.data?.players);
  // Match parties carry the canonical team ID even when basicinfo is unavailable.
  // Do not use source_team.team_name: the provider can put the opponent there.
  const matchIdentity = matches.data
    ?.flatMap((match) => [match.team1, match.team2])
    .find((party) => party && String(party.team_id) === id);
  const name = team?.name ?? preview?.name ?? matchIdentity?.team_name;
  return (
    <Frame
      refresh={() => {
        query.refresh();
        placement.refresh();
        matches.refresh();
        upcoming.refresh();
      }}
      refreshing={query.loading && !!team}
    >
      <SkeletonContent loading={contentLoading}>
        <View style={styles.detailHero}>
          <View style={styles.identity}>
            <IdentityArt
              url={team?.logo_url ?? preview?.logo_url ?? matchIdentity?.logo_url}
              size={112}
              name={name ?? ''}
              inverse
            />
            <View style={styles.grow}>
              <CKText style={[styles.detailTitle, styles.white]}>
                {name ?? t('competitiveTeams')}
              </CKText>
            </View>
          </View>
          <View style={styles.heroMetrics}>
            {placement.data?.team ? (
              <View style={styles.heroMetric}>
                <CKText style={[styles.metricValue, styles.white]}>
                  #{placement.data.team.rank.toLocaleString(toIntlLocale(locale))}
                </CKText>
                <CKText style={styles.heroSubtitle}>{t('legendsGlobalRankTitle')}</CKText>
              </View>
            ) : null}
            {team?.elo != null ? (
              <View style={styles.heroMetric}>
                <CKText style={[styles.metricValue, styles.white]}>
                  {placement.data?.team?.elo ?? team.elo}
                </CKText>
                <CKText style={styles.heroSubtitle}>Elo</CKText>
              </View>
            ) : null}
            {team ? (
              <View style={styles.heroMetric}>
                <CKText style={[styles.metricValue, styles.white]}>{team.players.length}</CKText>
                <CKText style={styles.heroSubtitle}>{t('esportsRoster')}</CKText>
              </View>
            ) : null}
          </View>
          {team?.players.length ? (
            <View style={{ width: '100%', maxWidth: 950, alignSelf: 'center', gap: 12 }}>
              <Pressable
                onPress={() => selectTab('roster')}
                accessibilityRole="button"
                style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}
              >
                <CKText style={styles.heroSubtitle}>{t('esportsRoster')}</CKText>
                <ChevronRight color="#E8DCF9" size={16} />
              </Pressable>
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                style={{ marginHorizontal: -8 }}
                contentContainerStyle={{ gap: 16, paddingHorizontal: 8, paddingVertical: 4 }}
              >
                {team.players.slice(0, 5).map((player) => (
                  <Pressable
                    key={player.tag}
                    accessibilityRole="button"
                    accessibilityLabel={player.name}
                    onPress={() => push({ kind: 'ccnPlayer', tag: player.tag })}
                    style={{ width: 62, alignItems: 'center', gap: 6 }}
                  >
                    <PlayerPortrait tag={player.tag} name={player.name} size={52} />
                    <CKText role="metadata" numberOfLines={1} style={styles.heroSubtitle}>
                      {player.name}
                    </CKText>
                  </Pressable>
                ))}
              </ScrollView>
            </View>
          ) : null}
        </View>
        <View style={styles.content}>
          <ProfileTabs
            variant="underline"
            overflow="fit"
            selectedKey={tab}
            animatedPosition={tabPosition}
            indicatorRtl={isRtl}
            onSelect={(key) => selectTab(key as TeamTab)}
            tabs={[
              { key: 'matches', label: t('esportsMatches') },
              { key: 'roster', label: t('esportsRoster') },
              { key: 'stats', label: t('navigationStatistics') },
            ]}
          />
          <View
            onTouchStart={() => blockPrimarySwipe(true)}
            onTouchEnd={() => blockPrimarySwipe(false)}
            onTouchCancel={() => blockPrimarySwipe(false)}
          >
            <PagerView
              ref={pager}
              initialPage={0}
              layoutDirection={isRtl ? 'rtl' : 'ltr'}
              testID="esports-team-pager"
              style={{ height: Math.max(pageHeights[tab] ?? 400, pageHeights[settledTab] ?? 400) }}
              onPageScroll={(event) =>
                tabPosition.setValue(event.nativeEvent.position + event.nativeEvent.offset)
              }
              onPageSelected={(event) => {
                const next = TEAM_TABS[event.nativeEvent.position];
                if (next) {
                  setTab(next);
                  setSettledTab(next);
                }
              }}
            >
              {TEAM_TABS.map((page) => (
                <View
                  key={page}
                  collapsable={false}
                  style={{ flex: 1 }}
                  accessibilityElementsHidden={page !== tab}
                  importantForAccessibility={page !== tab ? 'no-hide-descendants' : 'auto'}
                >
                  <View
                    style={{ gap: 20 }}
                    onLayout={(event) => {
                      const height = Math.ceil(event.nativeEvent.layout.height);
                      if (height > 0)
                        setPageHeights((old) =>
                          old[page] === height ? old : { ...old, [page]: height },
                        );
                    }}
                  >
                    {page === 'stats' ? (
                      <>
                        {team?.stats ? (
                          <>
                            <View style={styles.recordRow}>
                              <View style={styles.recordCell}>
                                <Metric
                                  compact
                                  label={t('warWinsTitle')}
                                  value={team.stats.wins}
                                  accent="#14A37F"
                                />
                              </View>
                              <View style={styles.recordCell}>
                                <Metric
                                  compact
                                  label={t('warDrawsTitle')}
                                  value={team.stats.ties}
                                />
                              </View>
                              <View style={styles.recordCell}>
                                <Metric
                                  compact
                                  label={t('warLossesTitle')}
                                  value={team.stats.losses}
                                  accent={theme.error}
                                />
                              </View>
                            </View>
                            <PerformanceStats
                              stats={team.stats.offense}
                              label={t('warAttacksTitle')}
                            />
                            <PerformanceStats
                              stats={team.stats.defense}
                              label={t('warDefensesTitle')}
                            />
                          </>
                        ) : (
                          <Feedback query={query} empty={!query.loading} />
                        )}
                      </>
                    ) : page === 'roster' ? (
                      <>
                        <Feedback query={query} empty={!team?.players.length} />
                        <View style={styles.rosterGrid}>
                          {team?.players.map((player) => (
                            <PressableSurface
                              key={player.tag}
                              accessibilityRole="button"
                              onPress={() => push({ kind: 'ccnPlayer', tag: player.tag })}
                              style={[styles.rosterCard, { backgroundColor: theme.card }]}
                            >
                              <PlayerPortrait tag={player.tag} name={player.name} size={80} />
                              <CKText role="titleSmall" numberOfLines={2}>
                                {player.name}
                              </CKText>
                              <View style={styles.inline}>
                                <CKText muted role="metadata">
                                  {t('esportsViewPlayer')}
                                </CKText>
                                <ChevronRight size={16} color={theme.onSurfaceVariant} />
                              </View>
                            </PressableSurface>
                          ))}
                        </View>
                        {team?.clans.length ? (
                          <CKText role="sectionTitle">{t('searchTabClans')}</CKText>
                        ) : null}
                        {team?.clans.map((clan) => (
                          <Row
                            key={clan.tag}
                            name={clan.name}
                            logo={ImageAssets.clanBadgeForTag(clan.tag, clan)}
                            onPress={() => queueAppLink(`/clan/${encodeURIComponent(clan.tag)}`)}
                          />
                        ))}
                      </>
                    ) : (
                      <>
                        <Feedback query={upcoming} />
                        {upcoming.data?.upcoming_matches.length ? (
                          <CKText role="sectionTitle">{t('homeUpcomingTitle')}</CKText>
                        ) : null}
                        <SkeletonContent loading={upcoming.loading && !upcoming.data}>
                          {(
                            upcoming.data?.upcoming_matches ??
                            (upcoming.loading ? loadingUpcoming : [])
                          ).map((match) => (
                            <View
                              key={match.upcoming_match_id}
                              style={[styles.match, { backgroundColor: theme.card }]}
                            >
                              <CKText muted role="metadata">
                                {ccnDate(match.match_date).toLocaleString(toIntlLocale(locale), {
                                  dateStyle: 'medium',
                                  timeStyle: 'short',
                                })}
                              </CKText>
                              {[match.team1, match.team2].map((party, index) => (
                                <View style={styles.matchSide} key={index}>
                                  <IdentityArt
                                    name={party.ccn_team_name ?? party.source_team_name}
                                    url={party.ccn_team_logo_url ?? party.source_team_logo_url}
                                    size={44}
                                  />
                                  <CKText role="rowTitle">
                                    {party.ccn_team_name ?? party.source_team_name}
                                  </CKText>
                                </View>
                              ))}
                              <MatchStreams streams={match.streams} />
                            </View>
                          ))}
                        </SkeletonContent>
                        <CKText role="sectionTitle">{t('esportsRecentMatches')}</CKText>
                        <Feedback query={matches} empty={matches.data?.length === 0} />
                        <SkeletonContent loading={matches.loading && !matches.data}>
                          {(matches.data ?? (matches.loading ? loadingMatches : [])).map(
                            (match, index) => (
                              <TeamMatch key={match.match_id ?? index} match={match} push={push} />
                            ),
                          )}
                        </SkeletonContent>
                      </>
                    )}
                  </View>
                </View>
              ))}
            </PagerView>
          </View>
        </View>
      </SkeletonContent>
    </Frame>
  );
}
function TeamMatch({ match, push }: { match: Match; push: (scene: Scene) => void }) {
  const [open, setOpen] = useState(false);
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={[styles.match, { backgroundColor: theme.card }]}>
      <View>
        <Pressable
          accessibilityRole="button"
          accessibilityState={{ expanded: open }}
          accessibilityLabel={t(open ? 'esportsHideAttacks' : 'esportsViewAttacks')}
          onPress={() => setOpen((value) => !value)}
          style={styles.sectionHeading}
        >
          <View style={[styles.grow, { gap: 4 }]}>
            {match.event?.name ? <CKText role="rowTitle">{match.event.name}</CKText> : null}
            {match.week?.name ? (
              <CKText muted role="metadata">
                {match.week.name}
              </CKText>
            ) : null}
            {match.team1?.result?.final === false || match.team2?.result?.final === false ? (
              <CKText role="metadata" style={{ color: theme.secondary }}>
                {t('upgradeTrackerInProgress')}
              </CKText>
            ) : null}
            <CKText muted role="metadata">
              {ccnDate(match.preparation_start).toLocaleString(toIntlLocale(locale), {
                dateStyle: 'medium',
                timeStyle: 'short',
              })}
            </CKText>
          </View>
          <ChevronRight
            size={20}
            color={theme.onSurfaceVariant}
            style={{ transform: [{ rotate: open ? '90deg' : '0deg' }] }}
          />
        </Pressable>
        {[match.team1, match.team2].map((party, index) => (
          <MatchSide
            key={index}
            name={party?.team_name ?? party?.source_team?.name ?? '—'}
            logo={party?.logo_url}
            score={party?.result?.stars ?? null}
            percentage={party?.result?.percentage ?? null}
            winner={party?.result?.win}
            onPress={
              party?.team_id == null
                ? undefined
                : () => {
                    const id = String(party.team_id);
                    // Only canonical CCN IDs navigate; source-team IDs can identify
                    // an unrelated provider and must not be substituted here.
                    teamPreviews.set(id, {
                      name: party.team_name ?? party.source_team?.name ?? '—',
                      logo_url: party.logo_url,
                    });
                    push({ kind: 'ccnTeam', id });
                  }
            }
          />
        ))}
        <Pressable
          accessibilityRole="button"
          accessibilityState={{ expanded: open }}
          onPress={() => setOpen((value) => !value)}
          style={{ paddingVertical: 8 }}
        >
          <CKText role="metadata" style={{ color: theme.secondary }}>
            {t(open ? 'esportsHideAttacks' : 'esportsViewAttacks')}
          </CKText>
        </Pressable>
      </View>
      {open ? (
        <View style={styles.attacks}>
          {[match.team1, match.team2]
            .flatMap((party) => party?.attacks ?? [])
            .sort((a, b) => a.attack_order - b.attack_order)
            .map((attack) => (
              <View
                key={`${attack.attacker.tag}:${attack.attack_order}`}
                style={[styles.attack, { backgroundColor: colorWithAlpha(theme.onSurface, 0.045) }]}
              >
                <View style={styles.attackIdentities}>
                  <Pressable
                    accessibilityRole="button"
                    onPress={() => push({ kind: 'ccnPlayer', tag: attack.attacker.tag })}
                    style={styles.attackPlayer}
                  >
                    <CKText muted role="metadata">
                      {t('esportsAttack')}
                    </CKText>
                    <PlayerPortrait
                      name={attack.attacker.name}
                      tag={attack.attacker.tag}
                      size={44}
                    />
                    <CKText role="rowTitle" numberOfLines={2}>
                      {attack.attacker.name}
                    </CKText>
                  </Pressable>
                  <View style={styles.attackResult}>
                    <View
                      style={{ flexDirection: 'row', alignItems: 'center', gap: 2 }}
                      accessible
                      accessibilityLabel={`${attack.stars}/3 ${t('warStarsTitle')}`}
                    >
                      {[0, 1, 2].map((index) => (
                        <MobileWebImage
                          key={index}
                          imageUrl={
                            index < attack.stars ? ImageAssets.attackStar : ImageAssets.emptyStar
                          }
                          style={{ width: 20, height: 20 }}
                        />
                      ))}
                    </View>
                    <CKText role="titleSmall">{attack.percentage}%</CKText>
                    <CKText muted role="metadata">
                      {Math.floor(attack.duration / 60)}:
                      {String(attack.duration % 60).padStart(2, '0')}
                    </CKText>
                  </View>
                  <Pressable
                    accessibilityRole="button"
                    onPress={() => push({ kind: 'ccnPlayer', tag: attack.defender.tag })}
                    style={styles.attackPlayer}
                  >
                    <CKText muted role="metadata">
                      {t('esportsDefense')}
                    </CKText>
                    <PlayerPortrait
                      name={attack.defender.name}
                      tag={attack.defender.tag}
                      size={44}
                    />
                    <CKText role="rowTitle" numberOfLines={2}>
                      {attack.defender.name}
                    </CKText>
                  </Pressable>
                </View>
              </View>
            ))}
        </View>
      ) : null}
    </View>
  );
}
export function EsportsPlayer({ tag }: { tag: string }) {
  const { t } = useI18n();
  const query = useCcn<Player>(`player?playerTag=${encodeURIComponent(tag)}`);
  const contentLoading = query.loading && !query.data;
  const player: Player | undefined | null =
    query.data ??
    (contentLoading
      ? {
          name: 'Esports player',
          picture_url: 'loading',
          accounts: [0, 1, 2].map((index) => ({ tag: `loading-${index}`, name: 'Linked player' })),
          stats_offense: loadingStats,
          stats_defense: loadingStats,
        }
      : undefined);
  return (
    <Frame refresh={query.refresh} refreshing={query.loading && !!player}>
      <SkeletonContent loading={contentLoading}>
        <View style={styles.detailHero}>
          <View style={styles.identity}>
            <IdentityArt
              url={player?.picture_url}
              size={112}
              name={player?.name ?? ''}
              portrait
              inverse
            />
            <View style={styles.grow}>
              <CKText style={[styles.detailTitle, styles.white]}>{player?.name ?? '—'}</CKText>
            </View>
          </View>
        </View>
        <View style={styles.content}>
          <Feedback query={query} empty={query.data === null} kind="profile" />
          {player ? (
            <>
              {(
                [
                  ['warAttacksTitle', player.stats_offense],
                  ['warDefensesTitle', player.stats_defense],
                ] as const
              ).map(([label, stats]) =>
                stats ? <PerformanceStats key={label} stats={stats} label={t(label)} /> : null,
              )}
              <CKText role="sectionTitle">{t('esportsAccounts')}</CKText>
              {player.accounts.map((account) => (
                <GameAccount key={account.tag} name={account.name} tag={account.tag} />
              ))}
            </>
          ) : null}
        </View>
      </SkeletonContent>
    </Frame>
  );
}

const styles = StyleSheet.create({
  page: { width: '100%', alignSelf: 'center', paddingBottom: 40 },
  virtualRow: {
    width: '100%',
    maxWidth: 1000,
    alignSelf: 'center',
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  content: { width: '100%', maxWidth: 1000, alignSelf: 'center', padding: 20, gap: 20 },
  hero: {
    minHeight: 330,
    overflow: 'hidden',
    paddingHorizontal: 28,
    paddingTop: 100,
    paddingBottom: 16,
    justifyContent: 'flex-end',
    backgroundColor: '#472478',
  },
  heroCopy: { width: '100%', maxWidth: 944, alignSelf: 'center', gap: 12 },
  sourceAttribution: { flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 4 },
  heroTitle: { fontSize: 40, lineHeight: 43, fontWeight: '800', maxWidth: 650 },
  heroSubtitle: { color: '#E8DCF9' },
  white: { color: '#fff' },
  grow: { flex: 1, minWidth: 0 },
  inline: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  sectionHeading: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
  },
  eventRail: { gap: 12, paddingVertical: 5, paddingRight: 20 },
  eventCard: {
    width: 232,
    minHeight: 190,
    padding: 20,
    borderRadius: 24,
    gap: 15,
    justifyContent: 'space-between',
  },
  railArrow: {
    width: 44,
    height: 44,
    borderWidth: 0,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 22,
  },
  standings: { gap: 9 },
  standingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 15,
    borderRadius: 20,
  },
  rank: { width: 36, height: 40, borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  row: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 16, borderRadius: 20 },
  feedback: {
    minHeight: 85,
    borderRadius: 20,
    padding: 20,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
  },
  match: { borderRadius: 24, padding: 20, gap: 12 },
  matchSide: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingVertical: 8 },
  score: { alignItems: 'flex-end', gap: 2 },
  detailHero: {
    backgroundColor: '#392058',
    paddingHorizontal: 24,
    // Root owns the device safe inset. This clearance is only for its
    // overlaid Back control, and must not add the safe inset a second time.
    paddingTop: 86,
    paddingBottom: 32,
    gap: 24,
  },
  identity: {
    width: '100%',
    maxWidth: 950,
    alignSelf: 'center',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 22,
  },
  detailTitle: { fontSize: 32, lineHeight: 36, fontWeight: '800', marginTop: 8 },
  heroMetrics: {
    maxWidth: 950,
    width: '100%',
    alignSelf: 'center',
    flexDirection: 'row',
    gap: 40,
    paddingLeft: 4,
  },
  heroMetric: { gap: 4 },
  rosterGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  rosterCard: {
    flexBasis: '46%',
    flexGrow: 1,
    minWidth: 140,
    borderWidth: 0,
    padding: 22,
    borderRadius: 24,
    gap: 16,
    alignItems: 'center',
  },
  performance: { borderRadius: 24, padding: 22, gap: 24 },
  metricRow: { flexDirection: 'row', flexWrap: 'wrap', rowGap: 22 },
  recordRow: { flexDirection: 'row', gap: 8 },
  recordCell: { flex: 1, minWidth: 0 },
  metric: { flexBasis: '50%', gap: 6, paddingRight: 12 },
  metricValue: { fontSize: 28, lineHeight: 32, fontWeight: '800' },
  attacks: { gap: 10, paddingTop: 12 },
  attack: { borderRadius: 18, padding: 14 },
  attackIdentities: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  attackPlayer: { flex: 1, alignItems: 'center', gap: 8 },
  attackResult: { alignItems: 'center', gap: 5, minWidth: 64 },
});
