import type { ViewInstance, ScrollViewInstance } from 'react-native';
import { ASSET_ORIGIN } from '../../core/assets/asset-origin';
import { useCallback, useEffect, useId, useMemo, useRef, useState, type ReactNode } from 'react';
import * as Linking from 'expo-linking';
import {
  Animated,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { ArrowLeft, ChevronLeft, ChevronRight } from 'lucide-react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { ImageAssets } from '../../core/assets/image-assets';
import { COMPETITIVE_TOURNAMENT_COVER } from './competitive-artwork';
import { EsportsLanding, EsportsTeam, EsportsPlayer } from './esports-screen';
import { CompetitiveProfileScreen } from './profile-screen';
import { queueAppLink } from '../../core/deep-links/link-inbox';
import { useLinkParameters } from '../../core/deep-links/link-parameters';
import { subscribeLocalBrowserNavigation } from '../../core/deep-links/expo-deep-link-runtime';
import { subscribeSecondaryBackHandler } from '../../core/app/secondary-back-handler';
import { useAppRuntime } from '../../core/app/runtime-context';
import { materialBackLabel, toIntlLocale, useI18n } from '../../i18n';
import { materialPreviousPageTooltip, materialNextPageTooltip } from '../../i18n/material-labels';
import {
  CKText,
  DestinationStack,
  SkeletonContent,
  MobileWebImage,
  PressableSurface,
  SelectionPicker,
  ckColors,
  colorWithAlpha,
  useCKAccessibility,
  useCKTheme,
} from '../../ui';
import {
  competitiveService,
  type CompetitiveProfile,
  type CompetitiveTeam,
  type Tournament,
  type TournamentDetail,
} from './competitive-service';

type Scene =
  | { kind: 'esports' | 'tournaments' | 'profile' }
  | { kind: 'tournament'; id: string }
  | { kind: 'team'; team: CompetitiveTeam }
  | { kind: 'person'; id: string }
  | { kind: 'ccnTeam'; id: string }
  | { kind: 'ccnPlayer'; tag: string };

export function CompetitiveRoot({
  initial = 'tournaments',
  onBack,
  onManageAccounts,
}: {
  initial?: 'esports' | 'tournaments' | 'profile';
  onBack: () => void;
  onManageAccounts: () => void;
}) {
  const params = useLinkParameters();
  const historyId = useId();
  const [navigation, setNavigation] = useState(() => {
    const scenes: Scene[] = [
      { kind: initial },
      ...(initial === 'tournaments' && params.tournamentId
        ? [{ kind: 'tournament' as const, id: params.tournamentId }]
        : []),
      ...(initial === 'profile' && params.userId
        ? [{ kind: 'person' as const, id: params.userId }]
        : []),
    ];
    return { scenes, depth: scenes.length - 1 };
  });
  const current = useRef(navigation);
  const pendingBrowserBack = useRef<number | undefined>(undefined);
  const host = useRef<ViewInstance>(null);
  const updateNavigation = useCallback((next: typeof navigation) => {
    current.current = next;
    setNavigation(next);
  }, []);
  useEffect(() => {
    if (Platform.OS !== 'web') return;
    // Consume only this mounted destination's browser entries. Other paths
    // still reach the app-link inbox and its existing authentication/router flow.
    const marker = (depth: number) => ({
      ...window.history.state,
      competitiveNavigation: { id: historyId, depth },
    });
    if (window.history.state?.competitiveNavigation?.id !== historyId) {
      window.history.replaceState(marker(0), '');
      for (let depth = 1; depth <= current.current.depth; depth += 1)
        window.history.pushState(marker(depth), '');
    }
    const onPop = (event: PopStateEvent) => {
      // A player opened above this retained utility owns Back until that
      // overlay closes. Only the visible competitive host may consume it.
      const element = host.current as unknown as HTMLElement | null;
      if (!element?.getClientRects().length || element.closest('[inert], [aria-hidden="true"]'))
        return false;
      const entry = event.state?.competitiveNavigation;
      const pendingDepth = pendingBrowserBack.current;
      if (pendingDepth === undefined && (entry?.id !== historyId || !Number.isInteger(entry.depth)))
        return false;
      pendingBrowserBack.current = undefined;
      const previous = current.current;
      const depth = pendingDepth ?? entry.depth;
      if (depth < 0 || depth >= previous.scenes.length) return false;
      updateNavigation({ ...previous, depth });
      return true;
    };
    return subscribeLocalBrowserNavigation(onPop);
  }, [historyId, updateNavigation]);
  const push = useCallback(
    (scene: Scene) => {
      const previous = current.current;
      const depth = previous.depth + 1;
      updateNavigation({ scenes: [...previous.scenes.slice(0, depth), scene], depth });
      if (Platform.OS === 'web')
        window.history.pushState(
          {
            ...window.history.state,
            competitiveNavigation: { id: historyId, depth },
          },
          '',
        );
    },
    [historyId, updateNavigation],
  );
  const back = useCallback(() => {
    const previous = current.current;
    if (previous.depth === 0) onBack();
    else if (Platform.OS === 'web') {
      // Restore the retained parent immediately. The runtime consumes the
      // ensuing history event before it can reopen this URL as a new utility.
      pendingBrowserBack.current = previous.depth - 1;
      updateNavigation({ ...previous, depth: previous.depth - 1 });
      window.history.back();
    } else updateNavigation({ ...previous, depth: previous.depth - 1 });
  }, [onBack, updateNavigation]);
  return (
    <View ref={host} style={{ flex: 1 }}>
      <CompetitiveSceneLevel
        scenes={navigation.scenes}
        depth={navigation.depth}
        level={0}
        push={push}
        back={back}
        onManageAccounts={onManageAccounts}
      />
    </View>
  );
}

function CompetitiveSceneLevel({
  scenes,
  depth,
  level,
  push,
  back,
  onManageAccounts,
}: {
  scenes: Scene[];
  depth: number;
  level: number;
  push: (scene: Scene) => void;
  back: () => void;
  onManageAccounts: () => void;
}) {
  const theme = useCKTheme();
  const scene = scenes[level]!;
  const child = scenes[level + 1];
  const page = (
    <CompetitiveScenePage
      scene={scene}
      push={push}
      back={back}
      onManageAccounts={onManageAccounts}
    />
  );
  const detail = child ? (
    <CompetitiveSceneLevel
      scenes={scenes}
      depth={depth}
      level={level + 1}
      push={push}
      back={back}
      onManageAccounts={onManageAccounts}
    />
  ) : null;
  if (Platform.OS === 'web') {
    return (
      <View style={{ flex: 1 }}>
        <View style={{ flex: 1, display: depth === level ? 'flex' : 'none' }}>{page}</View>
        {detail ? (
          <View style={{ flex: 1, display: depth > level ? 'flex' : 'none' }}>{detail}</View>
        ) : null}
      </View>
    );
  }
  // Each drill-down owns a native Detail route. Keeping forward scenes in
  // memory preserves the parent list, filters and scroll on swipe or Back.
  return (
    <DestinationStack
      focused={depth > level}
      onCloseDetail={back}
      grid={page}
      detail={detail}
      backgroundColor={theme.background}
    />
  );
}

function CompetitiveScenePage({
  scene,
  push,
  back,
  onManageAccounts,
}: {
  scene: Scene;
  push: (scene: Scene) => void;
  back: () => void;
  onManageAccounts: () => void;
}) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  return (
    <SafeAreaView
      style={{ flex: 1, backgroundColor: theme.background }}
      // Artwork-led pages own their top inset so the image reaches behind the
      // status bar. Text-only scenes retain the normal safe-area content inset.
      edges={
        ['esports', 'profile', 'person'].includes(scene.kind)
          ? ['left', 'right', 'bottom']
          : ['top', 'left', 'right', 'bottom']
      }
    >
      {/* Absolute children ignore SafeAreaView's content padding. Keep Back
          below the status bar while retaining the artwork beneath it. */}
      <View pointerEvents="box-none" style={[styles.header, { top: insets.top + 6 }]}>
        <Pressable
          onPress={back}
          accessibilityRole="button"
          accessibilityLabel={materialBackLabel(locale)}
          style={[
            styles.back,
            {
              backgroundColor:
                scene.kind === 'profile' || scene.kind === 'person'
                  ? colorWithAlpha(theme.onSurface, 0.06)
                  : '#100b14aa',
            },
          ]}
        >
          <ArrowLeft
            color={scene.kind === 'profile' || scene.kind === 'person' ? theme.onSurface : '#fff'}
          />
        </Pressable>
      </View>
      {scene.kind === 'esports' ? (
        <EsportsLanding push={push} />
      ) : scene.kind === 'ccnTeam' ? (
        <EsportsTeam id={scene.id} push={push} />
      ) : scene.kind === 'ccnPlayer' ? (
        <EsportsPlayer tag={scene.tag} />
      ) : scene.kind === 'tournaments' ? (
        <TournamentList push={push} />
      ) : scene.kind === 'tournament' ? (
        <TournamentScreen id={scene.id} push={push} />
      ) : scene.kind === 'team' ? (
        <TeamScreen team={scene.team} push={push} />
      ) : (
        <ProfileScreen
          userId={scene.kind === 'person' ? scene.id : undefined}
          push={push}
          onManageAccounts={onManageAccounts}
        />
      )}
    </SafeAreaView>
  );
}

function useCompetition<T>(path: string, publicRead = false) {
  const runtime = useAppRuntime();
  const service = useMemo(() => competitiveService(runtime), [runtime]);
  const [version, setVersion] = useState(0);
  const [state, setState] = useState<{ path: string; data?: T; error?: string; loading: boolean }>({
    path,
    loading: true,
  });
  useEffect(() => {
    let active = true;
    void service
      .request<T>(path, 'GET', undefined, publicRead)
      .then((data) => {
        if (active) setState({ path, data, loading: false });
      })
      .catch((error: Error) => {
        if (active)
          setState((old) => ({
            path,
            data: old.path === path ? old.data : undefined,
            error: error.message,
            loading: false,
          }));
      });
    return () => {
      active = false;
    };
  }, [path, publicRead, service, version]);
  const refresh = useCallback(() => {
    setState((old) => ({ ...old, loading: true, error: undefined }));
    setVersion((old) => old + 1);
  }, []);
  return {
    ...state,
    data: state.path === path ? state.data : undefined,
    loading: state.path !== path || state.loading,
    refresh,
    service,
  };
}

function Page({
  children,
  query,
}: {
  children: ReactNode;
  query?: { loading: boolean; data?: unknown; error?: string; refresh: () => void };
}) {
  const theme = useCKTheme();
  const { t } = useI18n();
  return (
    <ScrollView
      contentContainerStyle={styles.page}
      refreshControl={
        query ? (
          <RefreshControl
            refreshing={query.loading}
            onRefresh={query.refresh}
            tintColor={theme.primary}
          />
        ) : undefined
      }
    >
      {query?.error ? (
        <PressableSurface onPress={query.refresh} style={styles.card}>
          <CKText>{t('competitiveUnavailable')}</CKText>
          <CKText muted role="metadata">
            {query.error}
          </CKText>
          <CKText style={{ color: theme.primary }}>{t('generalRetry')}</CKText>
        </PressableSurface>
      ) : null}
      <SkeletonContent loading={!!query?.loading && !query.data}>{children}</SkeletonContent>
    </ScrollView>
  );
}
function Action({
  label,
  onPress,
  disabled = false,
  primary = false,
}: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  primary?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled }}
      disabled={disabled}
      onPress={onPress}
      style={[
        styles.action,
        {
          backgroundColor: primary ? theme.primary : colorWithAlpha(theme.secondary, 0.12),
          opacity: disabled ? 0.45 : 1,
        },
      ]}
    >
      <CKText style={{ color: primary ? theme.onPrimary : theme.onSurface }} role="rowTitle">
        {label}
      </CKText>
    </Pressable>
  );
}
function Identity({
  name,
  subtitle,
  image,
  onPress,
}: {
  name: string;
  subtitle?: string;
  image?: string;
  onPress?: () => void;
}) {
  const theme = useCKTheme();
  return (
    <PressableSurface disabled={!onPress} onPress={onPress} style={styles.identity}>
      {image ? <MobileWebImage imageUrl={image} style={styles.art} /> : null}
      <View style={{ flex: 1, gap: 4 }}>
        <CKText role="titleSmall">{name}</CKText>
        {subtitle ? (
          <CKText muted role="metadata">
            {subtitle}
          </CKText>
        ) : null}
      </View>
      {onPress ? <ChevronRight color={theme.onSurfaceVariant} size={20} /> : null}
    </PressableSurface>
  );
}
// View-only records keep the actual discovery cards mounted before the first response.
const loadingTournaments: readonly Tournament[] = [0, 1, 2].map((index) => ({
  id: `loading-${index}`,
  serverId: '',
  name: 'ClashKing tournament',
  format: 'single_elimination',
  teamSize: 5,
  startsAt: '2000-01-01',
  endsAt: '2000-01-02',
  status: 'upcoming',
  rules: 'Tournament rules',
}));

function TournamentList({ push }: { push: (scene: Scene) => void }) {
  const query = useCompetition<{ items: Tournament[] }>('/competitive/tournaments', true);
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const { width } = useWindowDimensions();
  const [heroWidth, setHeroWidth] = useState(Math.min(width, 1120));
  const heroHeight = width < 600 ? 310 : 370;
  const { reduceMotion } = useCKAccessibility();
  const [scroll] = useState(() => new Animated.Value(0));
  const rail = useRef<ScrollViewInstance>(null);
  const [active, setActive] = useState(0);
  const cardWidth = Math.min(width - 60, 330);
  const items = query.data?.items ?? (query.loading ? loadingTournaments : []);
  const move = (index: number) => {
    const next = Math.max(0, Math.min(index, items.length - 1));
    rail.current?.scrollTo({ x: next * (cardWidth + 14), animated: !reduceMotion });
    setActive(next);
  };
  return (
    <Animated.ScrollView
      testID="tournament-discovery"
      onScroll={Animated.event([{ nativeEvent: { contentOffset: { y: scroll } } }], {
        useNativeDriver: Platform.OS !== 'web',
      })}
      scrollEventThrottle={16}
      refreshControl={
        <RefreshControl
          refreshing={query.loading}
          onRefresh={query.refresh}
          tintColor={theme.primary}
        />
      }
      contentContainerStyle={{
        paddingBottom: 40,
        width: '100%',
        maxWidth: 1120,
        alignSelf: 'center',
      }}
    >
      <View
        onLayout={(event) => setHeroWidth(event.nativeEvent.layout.width)}
        style={{ height: heroHeight, overflow: 'hidden', backgroundColor: '#251513' }}
      >
        <Animated.View
          style={[
            StyleSheet.absoluteFill,
            !reduceMotion && {
              transform: [
                {
                  translateY: scroll.interpolate({
                    inputRange: [0, 400],
                    outputRange: [0, 85],
                    extrapolate: 'clamp',
                  }),
                },
              ],
            },
          ]}
        >
          <MobileWebImage
            imageUrl={COMPETITIVE_TOURNAMENT_COVER}
            style={StyleSheet.absoluteFill}
            contentFit="cover"
          />
        </Animated.View>
        {/* Numeric bounds keep the native SVG paint server aligned with the
            full hero; percentage dimensions can clip its fade to a rectangle. */}
        <Svg
          pointerEvents="none"
          style={StyleSheet.absoluteFill}
          width={heroWidth}
          height={heroHeight}
        >
          <Defs>
            <LinearGradient
              id="arena-fade"
              gradientUnits="userSpaceOnUse"
              x1={0}
              y1={0}
              x2={0}
              y2={heroHeight}
            >
              <Stop offset="0" stopColor="#110909" stopOpacity={0.25} />
              <Stop offset="0.5" stopColor="#110909" stopOpacity={0.08} />
              <Stop offset="1" stopColor={theme.background} />
            </LinearGradient>
          </Defs>
          <Rect width={heroWidth} height={heroHeight} fill="url(#arena-fade)" />
        </Svg>
        <View style={{ flex: 1, justifyContent: 'flex-end', padding: 24, paddingBottom: 34 }}>
          <CKText
            skeleton={false}
            style={{
              color: '#fff',
              fontSize: width < 600 ? 36 : 48,
              lineHeight: width < 600 ? 40 : 52,
              fontWeight: '800',
              maxWidth: 430,
            }}
          >
            {t('competitiveFindYourNextWar')}
          </CKText>
          <CKText skeleton={false} style={{ color: '#ead5c1', marginTop: 10, maxWidth: 420 }}>
            {t('competitiveArenaSubtitle')}
          </CKText>
        </View>
      </View>
      <View style={{ paddingHorizontal: 20, gap: 18 }}>
        <View
          style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}
        >
          <CKText skeleton={false} role="sectionTitle">
            {t('competitiveTournaments')}
          </CKText>
          <View style={{ flexDirection: 'row', gap: 8 }}>
            <PressableSurface
              accessibilityRole="button"
              accessibilityLabel={materialPreviousPageTooltip(locale)}
              disabled={active === 0}
              onPress={() => move(active - 1)}
              style={{ padding: 10, opacity: active === 0 ? 0.35 : 1, borderWidth: 0 }}
            >
              <ChevronLeft size={20} color={theme.onSurface} />
            </PressableSurface>
            <PressableSurface
              accessibilityRole="button"
              accessibilityLabel={materialNextPageTooltip(locale)}
              disabled={active >= items.length - 1}
              onPress={() => move(active + 1)}
              style={{
                padding: 10,
                opacity: active >= items.length - 1 ? 0.35 : 1,
                borderWidth: 0,
              }}
            >
              <ChevronRight size={20} color={theme.onSurface} />
            </PressableSurface>
          </View>
        </View>
        {query.error ? <Action label={t('generalRetry')} onPress={query.refresh} /> : null}
      </View>
      <SkeletonContent loading={query.loading && !query.data}>
        <ScrollView
          ref={rail}
          horizontal
          showsHorizontalScrollIndicator={false}
          decelerationRate="fast"
          snapToInterval={cardWidth + 14}
          scrollEventThrottle={16}
          onScroll={(event) =>
            setActive(Math.round(event.nativeEvent.contentOffset.x / (cardWidth + 14)))
          }
          contentContainerStyle={{ paddingHorizontal: 20, paddingVertical: 18, gap: 14 }}
          testID="tournament-event-rail"
        >
          {items.map((item, index) => {
            const accent = ['#BA8543', '#9362D1', '#C95F51'][index % 3]!;
            const sculpture = ['triumphant_trophy', 'crown_sword', 'war_chief_2026'][index % 3];
            return (
              <PressableSurface
                key={item.id}
                accessibilityRole="button"
                accessibilityLabel={item.name}
                onPress={() => push({ kind: 'tournament', id: item.id })}
                style={{
                  width: cardWidth,
                  minHeight: 320,
                  overflow: 'hidden',
                  borderWidth: 0,
                  borderRadius: 26,
                  backgroundColor: colorWithAlpha(accent, 0.14),
                }}
              >
                <View style={{ padding: 20, flex: 1, gap: 8 }}>
                  <View
                    style={{
                      flexDirection: 'row',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                    }}
                  >
                    <CKText role="metadata" style={{ color: theme.onSurfaceVariant }}>
                      {new Date(item.startsAt).toLocaleDateString(toIntlLocale(locale), {
                        month: 'short',
                        day: 'numeric',
                      })}
                    </CKText>
                    <View
                      style={{
                        backgroundColor: colorWithAlpha(accent, 0.2),
                        paddingHorizontal: 10,
                        paddingVertical: 5,
                        borderRadius: 20,
                      }}
                    >
                      <CKText role="metadata">
                        {item.teamSize}v{item.teamSize}
                      </CKText>
                    </View>
                  </View>
                  <View
                    style={{ flexDirection: 'row', alignItems: 'center', flex: 1, minHeight: 160 }}
                  >
                    <View style={{ flex: 1, gap: 8 }}>
                      <CKText style={{ fontSize: 27, lineHeight: 30, fontWeight: '800' }}>
                        {item.name}
                      </CKText>
                      <CKText muted role="metadata">
                        {item.format === 'elo' ? 'Elo' : item.format.replaceAll('_', ' ')}
                      </CKText>
                    </View>
                    <MobileWebImage
                      imageUrl={`${ASSET_ORIGIN}/decorations/home-village/${sculpture}.webp`}
                      contentFit="contain"
                      style={{ width: 110, height: 150 }}
                    />
                  </View>
                  <CKText role="metadata" style={{ color: ckColors.donationGreen }}>
                    {t('competitiveFreeEntry')}
                  </CKText>
                </View>
                <View
                  style={{
                    paddingHorizontal: 20,
                    paddingVertical: 16,
                    backgroundColor: colorWithAlpha(accent, 0.18),
                    flexDirection: 'row',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                  }}
                >
                  <CKText role="rowTitle">{t('competitiveViewTournament')}</CKText>
                  <ChevronRight size={19} color={theme.onSurface} />
                </View>
              </PressableSurface>
            );
          })}
        </ScrollView>
      </SkeletonContent>
      {!items.length && !query.loading ? (
        <View style={{ padding: 24, gap: 10 }}>
          <CKText role="titleMedium">{t('competitiveNoTournamentsYet')}</CKText>
          <CKText muted>{t('competitiveTournamentsCheckBack')}</CKText>
        </View>
      ) : null}
    </Animated.ScrollView>
  );
}
function Banner({ title, image }: { title: string; image: string }) {
  return (
    <View style={styles.banner}>
      <MobileWebImage imageUrl={image} style={StyleSheet.absoluteFill} contentFit="cover" />
      <View style={styles.scrim}>
        <CKText role="screenTitle" style={{ color: '#fff' }}>
          {title}
        </CKText>
      </View>
    </View>
  );
}
function TournamentScreen({ id, push }: { id: string; push: (scene: Scene) => void }) {
  const query = useCompetition<TournamentDetail>(
    `/competitive/tournaments/${encodeURIComponent(id)}`,
    true,
  );
  const profile = useCompetition<CompetitiveProfile>('/competitive/profile');
  const { t, locale } = useI18n();
  const [selected, setSelected] = useState('');
  const [round, setRound] = useState('');
  const [notice, setNotice] = useState('');
  const [saving, setSaving] = useState(false);
  const detail: TournamentDetail | undefined =
    query.data ??
    (query.loading
      ? {
          tournament: loadingTournaments[0]!,
          participants: [0, 1, 2].map((index) => ({
            teamId: `loading-${index}`,
            clanName: 'Tournament team',
            status: 'Registered',
          })),
          standings: [],
          matches: [0, 1].map((index) => ({
            id: `loading-match-${index}`,
            status: 'Pending',
            round: 1,
            homeTeamId: 'loading-0',
            awayTeamId: 'loading-1',
            homeScore: 15,
            awayScore: 12,
          })),
        }
      : undefined);
  const tournament = detail?.tournament;
  const rounds = [...new Set(detail?.matches.map((match) => match.round ?? 1) ?? [])].sort(
    (a, b) => a - b,
  );
  const selectedRound = rounds.includes(Number(round)) ? Number(round) : rounds.at(-1);
  const teams = [
    ...new Map(
      (profile.data?.teams ?? [])
        .filter((team) => !team.leftAt && team.acceptedAt && team.size === tournament?.teamSize)
        .map((team) => [team.id, team]),
    ).values(),
  ];
  const chosen = teams.find((team) => team.id === selected) ?? teams[0];
  const clanName = (teamId: string) =>
    detail?.participants.find((participant) => participant.teamId === teamId)?.clanName ?? '—';
  const register = async () => {
    if (!chosen) return;
    setSaving(true);
    setNotice('');
    try {
      await query.service.request(
        `/competitive/tournaments/${encodeURIComponent(id)}/register`,
        'POST',
        { teamId: chosen.id },
      );
      setNotice(t('competitiveRegistrationSaved'));
      query.refresh();
    } catch (error) {
      setNotice((error as Error).message);
    } finally {
      setSaving(false);
    }
  };
  return (
    <Page query={query}>
      {tournament ? (
        <>
          <Banner title={tournament.name} image={COMPETITIVE_TOURNAMENT_COVER} />
          <CKText role="body">
            {tournament.teamSize}v{tournament.teamSize} · {tournament.format.replaceAll('_', ' ')} ·{' '}
            {t('competitiveFreeEntry')}
          </CKText>
          <CKText muted role="metadata">
            {new Date(tournament.startsAt).toLocaleString(toIntlLocale(locale), {
              dateStyle: 'medium',
              timeStyle: 'short',
            })}{' '}
            →{' '}
            {new Date(tournament.endsAt).toLocaleString(toIntlLocale(locale), {
              dateStyle: 'medium',
              timeStyle: 'short',
            })}
          </CKText>
          <CKText skeleton={false} role="sectionTitle">
            {t('competitiveRules')}
          </CKText>
          <CKText>
            {(typeof tournament.rules === 'string'
              ? tournament.rules
              : tournament.rules.description) || '—'}
          </CKText>
          {typeof tournament.rules === 'object' ? (
            <View style={styles.group}>
              <CKText muted role="metadata">
                {t('filtersTownHall')}: {tournament.rules.minTownHall}–
                {tournament.rules.maxTownHall}
              </CKText>
              <CKText muted role="metadata">
                {t('cwlRegisteredRoster')}: {tournament.rules.maxRosterSize}
              </CKText>
              {tournament.rules.prizeDescription ? (
                <View style={styles.group}>
                  <CKText skeleton={false} role="titleSmall">
                    {t('capitalRaidRewards')}
                  </CKText>
                  <CKText>{tournament.rules.prizeDescription}</CKText>
                </View>
              ) : null}
              {tournament.rules.rulebookUrl?.startsWith('https://') ? (
                <Action
                  label={`${t('competitiveRules')} ↗`}
                  onPress={() => {
                    if (typeof tournament.rules === 'object' && tournament.rules.rulebookUrl)
                      void Linking.openURL(tournament.rules.rulebookUrl).catch(() =>
                        setNotice(t('generalError')),
                      );
                  }}
                />
              ) : null}
            </View>
          ) : null}
          {teams.length ? (
            <>
              <SelectionPicker
                title={t('competitiveTeams')}
                selectedKey={chosen?.id ?? ''}
                options={teams.map((team) => ({
                  key: team.id,
                  label: `${team.clanName} · ${team.size}v${team.size}`,
                }))}
                onSelect={setSelected}
              />
              <Action
                label={t('competitiveRegister')}
                primary
                disabled={saving || tournament.status !== 'registration'}
                onPress={() => void register()}
              />
              <Action
                label={t('competitiveCheckIn')}
                disabled={saving || tournament.status !== 'registration'}
                onPress={() => {
                  if (!chosen) return;
                  setSaving(true);
                  void query.service
                    .request(
                      `/competitive/tournaments/${encodeURIComponent(id)}/check-in`,
                      'POST',
                      { teamId: chosen.id },
                    )
                    .then(() => {
                      query.refresh();
                      setNotice(t('competitiveRegistrationSaved'));
                    })
                    .catch((error: Error) => setNotice(error.message))
                    .finally(() => setSaving(false));
                }}
              />
              {tournament.status !== 'registration' ? (
                <CKText muted role="metadata">
                  {t('competitiveRegister')} · {t('generalClosed')}
                  {tournament.status === 'active' ? ` · ${t('generalActive')}` : ''}
                </CKText>
              ) : null}
            </>
          ) : (
            <Action label={t('competitiveTeams')} onPress={() => push({ kind: 'profile' })} />
          )}
          {notice ? <CKText accessibilityLiveRegion="polite">{notice}</CKText> : null}
          {detail?.standings?.length ? (
            <CKText skeleton={false} role="sectionTitle">
              {t('clanRankingsTab')}
            </CKText>
          ) : null}
          {detail?.standings?.map((standing, index) => (
            <Identity
              key={standing.teamId}
              name={`${index + 1}. ${clanName(standing.teamId)}`}
              subtitle={`${tournament.format === 'elo' ? standing.elo : standing.points} · ${standing.wins}/${standing.losses}/${standing.draws}`}
              image={ImageAssets.trophies}
            />
          ))}
          <CKText skeleton={false} role="sectionTitle">
            {t('competitiveTeams')}
          </CKText>
          {!detail?.participants.length ? (
            <CKText muted>{t('competitiveRegisteredClansEmpty')}</CKText>
          ) : null}
          {detail?.participants.map((participant) => (
            <Identity
              key={participant.teamId}
              name={participant.clanName ?? participant.clanTag ?? '—'}
              subtitle={
                participant.rating === undefined ? participant.status : `${participant.rating}`
              }
              onPress={() =>
                push({
                  kind: 'team',
                  team: {
                    id: participant.teamId,
                    clanTag: participant.clanTag ?? '',
                    clanName: participant.clanName ?? 'Team name',
                    size: tournament.teamSize,
                    archived: false,
                    members: [],
                  },
                })
              }
            />
          ))}
          <CKText skeleton={false} role="sectionTitle">
            {t('cwlMatches')}
          </CKText>
          {!detail?.matches.length ? <CKText muted>{t('competitiveMatchupsEmpty')}</CKText> : null}
          {rounds.length ? (
            <SelectionPicker
              title={t('cwlRounds')}
              selectedKey={String(selectedRound)}
              onSelect={setRound}
              options={rounds.map((value) => ({
                key: String(value),
                label: t('cwlRoundNumber', { number: value }),
              }))}
            />
          ) : null}
          {detail?.matches
            .filter((match) => (match.round ?? 1) === selectedRound)
            .map((match) => (
              <TournamentMatchCard
                key={match.id}
                match={match}
                home={clanName(match.homeTeamId)}
                away={clanName(match.awayTeamId)}
              />
            ))}
        </>
      ) : null}
    </Page>
  );
}

function TournamentMatchCard({
  match,
  home,
  away,
}: {
  match: TournamentDetail['matches'][number];
  home: string;
  away: string;
}) {
  const [open, setOpen] = useState(false);
  const theme = useCKTheme();
  const { t } = useI18n();
  return (
    <View style={[styles.match, { backgroundColor: theme.card }]}>
      <Pressable
        accessibilityRole="button"
        accessibilityState={{ expanded: open }}
        onPress={() => setOpen((value) => !value)}
        style={styles.group}
      >
        <View style={styles.score}>
          <CKText role="titleSmall" style={{ flex: 1 }}>
            {home}
          </CKText>
          <CKText role="titleMedium" style={{ color: ckColors.warGold }}>
            {match.homeScore ?? '—'}
          </CKText>
        </View>
        <View style={styles.score}>
          <CKText role="titleSmall" style={{ flex: 1 }}>
            {away}
          </CKText>
          <CKText role="titleMedium" style={{ color: ckColors.warGold }}>
            {match.awayScore ?? '—'}
          </CKText>
        </View>
        <CKText muted role="metadata">
          {match.status} · {t('warAttacksTitle')}
        </CKText>
      </Pressable>
      {open ? <TournamentMatchAttacks id={match.id} /> : null}
    </View>
  );
}
function TournamentMatchAttacks({ id }: { id: string }) {
  const query = useCompetition<{
    items: {
      attackerTag: string;
      attackerName: string | null;
      defenderTag: string;
      defenderName: string | null;
      stars: number;
      destructionPercentage: number;
      duration: number;
      attackOrder: number;
    }[];
  }>(`/competitive/matches/${encodeURIComponent(id)}/attacks`, true);
  const { t } = useI18n();
  return (
    <View style={styles.group}>
      {query.loading && !query.data ? (
        <SkeletonContent loading>
          {[0, 1, 2].map((index) => (
            <Identity
              key={index}
              name="Attacker → Defender"
              subtitle="3 ★ · 100% · 2:30"
              onPress={() => {}}
            />
          ))}
        </SkeletonContent>
      ) : null}
      {query.error ? (
        <Pressable onPress={query.refresh}>
          <CKText muted>{t('competitiveUnavailable')}</CKText>
        </Pressable>
      ) : null}
      {query.data?.items.map((attack) => (
        <Identity
          key={`${attack.attackerTag}:${attack.attackOrder}`}
          name={`${attack.attackerName ?? attack.attackerTag} → ${attack.defenderName ?? attack.defenderTag}`}
          subtitle={`${attack.stars} ★ · ${attack.destructionPercentage}% · ${Math.floor(attack.duration / 60)}:${String(attack.duration % 60).padStart(2, '0')}`}
          onPress={() => queueAppLink(`/player/${encodeURIComponent(attack.attackerTag)}`)}
        />
      ))}
      {query.data && !query.data.items.length ? (
        <CKText muted>{t('generalNoDataAvailable')}</CKText>
      ) : null}
    </View>
  );
}

function ProfileScreen({
  userId,
  push,
  onManageAccounts,
}: {
  userId?: string;
  push: (scene: Scene) => void;
  onManageAccounts?: () => void;
}) {
  const query = useCompetition<CompetitiveProfile>(
    userId ? `/competitive/profiles/${encodeURIComponent(userId)}` : '/competitive/profile',
    Boolean(userId),
  );
  return (
    <CompetitiveProfileScreen
      key={userId ?? 'own'}
      query={query}
      ownProfile={!userId}
      onTeam={(team) => push({ kind: 'team', team })}
      onTournament={(id) => push({ kind: 'tournament', id })}
      onManageAccounts={onManageAccounts}
    />
  );
}

function TeamRow({ team, onPress }: { team: CompetitiveTeam; onPress: () => void }) {
  return (
    <Identity
      name={team.clanName}
      subtitle={`${team.size}v${team.size} · ${team.members.length}/${team.size}`}
      image={ImageAssets.warClan}
      onPress={onPress}
    />
  );
}
function TeamScreen({ team, push }: { team: CompetitiveTeam; push: (scene: Scene) => void }) {
  const query = useCompetition<{
    team: CompetitiveTeam;
    history: { playerTag: string; joinedAt: string; leftAt?: string | null }[];
  }>(`/competitive/teams/${encodeURIComponent(team.id)}`, true);
  const current =
    query.data?.team ??
    (query.loading && !team.members.length
      ? {
          ...team,
          members: [0, 1, 2].map((index) => ({
            playerTag: `loading-${index}`,
            name: 'Team member',
            profile: null,
          })),
        }
      : team);
  const profile = useCompetition<CompetitiveProfile>('/competitive/profile');
  const [notice, setNotice] = useState('');
  const [saving, setSaving] = useState(false);
  const ownMemberships =
    profile.data?.teams.filter(
      (membership) => membership.id === current.id && !membership.leftAt,
    ) ?? [];
  const membershipAction = async (playerTag: string, operation: 'join' | 'leave') => {
    setSaving(true);
    setNotice('');
    try {
      await query.service.request(
        `/competitive/teams/${encodeURIComponent(current.id)}/${operation}`,
        'POST',
        { playerTag },
      );
      query.refresh();
      profile.refresh();
    } catch (error) {
      setNotice((error as Error).message);
    } finally {
      setSaving(false);
    }
  };
  const { t, locale } = useI18n();
  return (
    <Page query={query}>
      <Banner title={current.clanName} image={COMPETITIVE_TOURNAMENT_COVER} />
      <CKText muted>
        {current.clanTag} · {current.size}v{current.size}
      </CKText>
      {ownMemberships.map((membership) => (
        <View key={membership.playerTag} style={styles.group}>
          <CKText muted>{membership.playerTag}</CKText>
          <Action
            label={t(membership.acceptedAt ? 'joinLeaveLeave' : 'joinLeaveJoin')}
            disabled={saving}
            onPress={() =>
              void membershipAction(membership.playerTag, membership.acceptedAt ? 'leave' : 'join')
            }
          />
        </View>
      ))}
      {notice ? <CKText accessibilityLiveRegion="polite">{notice}</CKText> : null}
      <CKText skeleton={false} role="sectionTitle">
        {t('clanMembers')}
      </CKText>
      {current.members.map((member) => (
        <View key={member.playerTag} style={styles.group}>
          <Identity
            name={member.name}
            subtitle={member.playerTag}
            onPress={() => queueAppLink(`/player/${encodeURIComponent(member.playerTag)}`)}
          />
          {member.profile ? (
            <Pressable onPress={() => push({ kind: 'person', id: member.profile!.userId })}>
              <CKText style={{ color: ckColors.secondaryBlue }}>
                {member.profile.displayName} · {t('competitiveViewProfile')}
              </CKText>
            </Pressable>
          ) : null}
        </View>
      ))}
      <CKText skeleton={false} role="sectionTitle">
        {t('competitiveTeamHistory')}
      </CKText>
      {query.data?.history?.map((entry, index) => (
        <Identity
          key={`${entry.playerTag}:${index}`}
          name={entry.playerTag}
          subtitle={`${new Date(entry.joinedAt).toLocaleDateString(toIntlLocale(locale))} → ${entry.leftAt ? new Date(entry.leftAt).toLocaleDateString(toIntlLocale(locale)) : t('rankingsCurrent')}`}
        />
      ))}
    </Page>
  );
}

export function ClanCompetitiveTeams({ clanTag }: { clanTag: string }) {
  const query = useCompetition<{ items: CompetitiveTeam[] }>(
    `/competitive/clans/${encodeURIComponent(clanTag)}/teams`,
    true,
  );
  const [selected, setSelected] = useState<CompetitiveTeam>();
  const [person, setPerson] = useState<string>();
  useEffect(() => {
    const subscription = subscribeSecondaryBackHandler(Boolean(person || selected), () => {
      if (person) setPerson(undefined);
      else setSelected(undefined);
    });
    return () => subscription?.remove();
  }, [person, selected]);
  const { t, locale } = useI18n();
  if (person)
    return (
      <View style={{ minHeight: 400 }}>
        <Action label={materialBackLabel(locale)} onPress={() => setPerson(undefined)} />
        <ProfileScreen userId={person} push={() => undefined} />
      </View>
    );
  if (selected)
    return (
      <View style={{ minHeight: 400 }}>
        <Action label={materialBackLabel(locale)} onPress={() => setSelected(undefined)} />
        <TeamScreen
          team={selected}
          push={(scene) => {
            if (scene.kind === 'person') setPerson(scene.id);
          }}
        />
      </View>
    );
  return (
    <View style={styles.page}>
      <CKText skeleton={false} role="sectionTitle">
        {t('competitiveTeams')}
      </CKText>
      {query.loading && !query.data ? (
        <SkeletonContent loading>
          {[0, 1, 2].map((index) => (
            <TeamRow
              key={index}
              team={{
                id: `loading-${index}`,
                clanTag: '',
                clanName: 'Tournament team',
                size: 5,
                archived: false,
                members: [],
              }}
              onPress={() => {}}
            />
          ))}
        </SkeletonContent>
      ) : null}
      {query.error ? (
        <Pressable onPress={query.refresh}>
          <CKText muted>{t('competitiveUnavailable')}</CKText>
        </Pressable>
      ) : null}
      {query.data?.items
        .filter((team) => !team.archived)
        .map((team) => (
          <TeamRow key={team.id} team={team} onPress={() => setSelected(team)} />
        ))}
      {query.data && !query.data.items.length ? (
        <CKText muted>{t('generalNoDataAvailable')}</CKText>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    position: 'absolute',
    top: 6,
    zIndex: 20,
    width: '100%',
    maxWidth: 1120,
    alignSelf: 'center',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  back: { padding: 10, borderRadius: 24 },
  page: {
    padding: 20,
    paddingTop: 0,
    gap: 16,
    paddingBottom: 40,
    width: '100%',
    maxWidth: 1120,
    alignSelf: 'center',
  },
  card: { padding: 20, borderRadius: 24, borderWidth: 0, gap: 10 },
  identity: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 18,
    gap: 14,
    borderRadius: 24,
    borderWidth: 0,
  },
  art: { width: 48, height: 48 },
  banner: { height: 270, marginHorizontal: -20, overflow: 'hidden' },
  scrim: {
    flex: 1,
    justifyContent: 'flex-end',
    padding: 22,
    backgroundColor: colorWithAlpha('#000000', 0.35),
  },
  action: {
    minHeight: 48,
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  field: { gap: 8 },
  input: { minHeight: 48, paddingHorizontal: 16, borderRadius: 14, fontSize: 16 },
  toggle: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  avatar: { width: 80, height: 80, borderRadius: 40 },
  group: { gap: 8 },
  actions: { flexDirection: 'row', gap: 10, alignItems: 'center' },
  match: { borderRadius: 24, padding: 18, gap: 16 },
  score: { flexDirection: 'row', alignItems: 'center', gap: 14 },
});
