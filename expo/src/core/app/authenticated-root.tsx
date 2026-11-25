import { wikiSectionForUpgradeCategory } from '../../features/game-assets/wiki-catalogue';
import { WikiNavigationContext } from '../../features/game-assets/wiki-navigation';
import type { WikiNavigation } from '../../features/game-assets/wiki-navigation';
import { UpgradeItemDetailContent } from '../../features/upgrade-tracker/presentation/upgrade-tracker-breakdowns';
import type {
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
} from '../../features/upgrade-tracker/models';
import { ProfileAvatar } from '../../features/avatars/clash-avatar';
import * as Clipboard from 'expo-clipboard';
import { router, useNavigationContainerRef, type Href } from 'expo-router';
import { WikiCatalogueContext, type WikiEntry } from '../../features/game-assets/wiki-catalogue';
import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  useSyncExternalStore,
  type ReactNode,
} from 'react';
import { Alert, Platform, StyleSheet, View, useWindowDimensions } from 'react-native';
import { Trophy } from '@/ui/icons';

import { ServersRoot } from '../../features/servers/servers-root';
import { EsportsRoot } from '../../features/competitive/esports-root';
import { ServerDashboardScreen } from '../../features/servers/server-dashboard-screen';
import {
  managesDiscordServer,
  useDiscordServers,
  type DashboardServer,
} from '../../features/servers/use-discord-servers';
import { accountPresentationItem } from '../../features/accounts/presentation/contracts';
import { ManageLinkedAccountsScreen } from '../../features/accounts/presentation/manage-linked-accounts-screen';
import { materialContinueLabel, useI18n } from '../../i18n';
import {
  appRoutes,
  type AppRouteDefinition,
  type AppRouteId,
  type FeatureState,
} from '../../navigation';
import { NavigationShell, resolveShellLayout, type PrimaryRouteId } from '../../shell';
import { SettingsRoot } from '../../features/settings/presentation/settings-root';
import {
  AnnouncementOpeningController,
  sharedAnnouncementStoryCache,
} from '../../features/home/data';
import { useAnnouncementPresentation } from '../../features/home/presentation/announcement-presenter';
import { HomeDashboardRoot } from '../../features/home/presentation/home-dashboard-root';
import { PostsRoot } from '../../features/home/presentation/posts-root';
import { AchievementsRoot } from '../../features/achievements/presentation/achievements-root';
import type { PlayerCurrentCwl } from '../../features/player/presentation/player-detail-contracts';
import { PlayerDetailRoot } from '../../features/player/presentation/player-detail-root';
import { PlayersRoot } from '../../features/player/presentation/players-root';
import { Player, currentLegendDay } from '../../features/player/models';
import { ClanCapitalRoot } from '../../features/clan/presentation/clan-capital-root';
import {
  ClanInfoRoot,
  ClanRoot,
  type ClanNavigationActions,
} from '../../features/clan/presentation/clan-root';
import { Clan } from '../../features/clan/models';
import { ClanCapitalScreen } from '../../features/clan/presentation/clan-capital-screen';
import { RankedScreen } from '../../features/ranked/presentation/ranked-screen';
import { loadingCwl, loadingWar } from '../../features/war/presentation/war-loading-model';
import { DeferredDestination } from './deferred-destination';
import {
  CwlInfoRoot,
  HistoricalCwlRoot,
  WarCwlRoot,
  WarInfoRoot,
} from '../../features/war/presentation/war-cwl-root';
import type { WarCwl, WarInfo } from '../../features/war/models';
import { SearchRoot } from '../../features/search/search-root';
import { RankedRoot } from '../../features/ranked/presentation/ranked-root';
import { LegendsRoot, LegendsScreen } from '../../features/legends/presentation/legends-root';
import { RankingsRoot } from '../../features/rankings/presentation/rankings-root';
import { BasesArmiesRoot } from '../../features/bases-armies/bases-armies-root';
import { TodoRoot } from '../../features/todo/presentation/todo-root';
import { GameAssetsRoot } from '../../features/game-assets/game-assets-root';
import { CalculatorsRoot } from '../../features/calculators/calculators-root';
import { UpgradeTrackerRoot } from '../../features/upgrade-tracker/presentation/upgrade-tracker-root';
import { APP_FEATURE_FLAGS } from '../feature-flags/feature-flags';
import { canonicalTag } from '../domain/tags';
import { reportException } from '../observability/observability';
import { refreshLinkedAccountsForCurrentAuth } from '../../features/auth/startup';
import { DeepLinkHandler, startDeepLinkHandling, type DeepLinkFeedback } from '../deep-links';
import {
  ClashHandoffDialog,
  EmptyState,
  PageLoadingOverlay,
  PageLoadingHost,
  usePageLoadingRequest,
  Snackbar,
  useCKTheme,
} from '../../ui';
import { useAppRuntime, useAppState } from './runtime-context';
import { subscribeSecondaryBackHandler } from './secondary-back-handler';
import {
  applyNativeSecondaryRouteTransition,
  nativeSecondaryRouteTransition,
  notifyNativeSecondaryPopped,
  retainedNativeWikiRouteKeys,
  publishNativeSecondaryLayer,
  removeNativeSecondaryLayers,
} from './native-secondary-navigation';
import { supportCreatorUrl } from './runtime-effects';
import { playerGameUrl } from './player-game-link';
import { appLinkInbox, pendingAppLink } from '../deep-links/link-inbox';
import { appLinkPath, type AppLink, type AppLinkParams } from '../deep-links/app-link';
import { LinkParametersContext, EMPTY_LINK_PARAMS } from '../deep-links/link-parameters';
import { WarCwlService } from '../../features/war/data';
import { apiDate } from '../../features/war/models';
import { isRouteEnabled } from '../../navigation/route-manifest';
import { recordBrowserPath, backThroughBrowserHistory } from '../deep-links/browser-history';
import { selectLegendsPlayer } from './legends-player-selection';
import { UserProfileScreen } from '../../features/accounts/presentation/user-profile-screen';
import { onboarding } from '../../features/onboarding/onboarding-service';
import { useStartupCovered } from './startup-loading';
import type { HomeStartupPreview } from '../../features/home/data/home-startup-snapshot';

type ResolvedScene = {
  readonly nativeKey?: string;
  readonly wikiCatalogue?: readonly WikiEntry[];
  readonly linkParams?: AppLinkParams;
  readonly linkKey?: number;
  readonly clanSpring?: import('../../features/clan/presentation/clan-spring-transition').ClanSpringOrigin;
} & (
  | {
      readonly kind: 'wiki';
      readonly item: UpgradeTrackerItem;
      readonly snapshot?: UpgradeTrackerSnapshot;
    }
  | { readonly kind: 'player'; readonly player: Player }
  | { readonly kind: 'clan'; readonly clan: Clan }
  | { readonly kind: 'capital'; readonly clan: Clan }
  | {
      readonly kind: 'war';
      readonly war: WarInfo;
      readonly roundNumber: number | null;
      readonly cwl?: PlayerCurrentCwl;
    }
  | ({ readonly kind: 'cwl' } & PlayerCurrentCwl)
  | {
      readonly kind: 'historicalCwl';
      readonly clanTag: string;
      readonly season: string;
      readonly warLeagueName?: string;
    }
  | { readonly kind: 'serverDashboard'; readonly server: DashboardServer }
  | {
      readonly kind: 'utility';
      readonly route: AppRouteId;
      readonly playerTag?: string;
    }
);

type PushedScene =
  | ResolvedScene
  | {
      readonly kind: 'deferred';
      readonly nativeKey?: string;
      readonly preview: ResolvedScene;
      readonly initial?: ResolvedScene;
      readonly load: () => Promise<ResolvedScene>;
      readonly linkParams?: AppLinkParams;
      readonly linkKey?: number;
      readonly clanSpring?: undefined;
    };

/** Production shell composition for the retained four-tab Flutter navigation model. */
export function AuthenticatedRoot({
  onHomeReady,
  suppressAnnouncements = false,
  homeStartupPreview,
}: {
  onHomeReady?: () => void;
  suppressAnnouncements?: boolean;
  homeStartupPreview?: HomeStartupPreview;
} = {}) {
  const [startupPlayerLink, setStartupPlayerLink] = useState(
    () => pendingAppLink()?.kind === 'player',
  );
  const runtime = useAppRuntime();
  const state = useAppState();
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
  const viewportWidth = useWindowDimensions().width;
  // Both mobile platforms use a real native stack. Plain retained overlays
  // appear instantly and cannot animate Back or interactive pop correctly.
  const usesNativeSecondaryNavigation =
    Platform.OS !== 'web' && resolveShellLayout(Platform.OS, viewportWidth) === 'mobile';
  const subscribeAuth = useCallback(
    (listener: () => void) => runtime.auth.subscribe(listener),
    [runtime.auth],
  );
  const getAuthSnapshot = useCallback(() => runtime.auth.state, [runtime.auth]);
  const authState = useSyncExternalStore(subscribeAuth, getAuthSnapshot, getAuthSnapshot);
  const [{ primary, visitedPrimary }, setPrimaryNavigation] = useState<{
    primary: PrimaryRouteId;
    visitedPrimary: ReadonlySet<PrimaryRouteId>;
  }>(() => ({ primary: 'home', visitedPrimary: new Set(['home']) }));
  const setPrimary = useCallback((route: PrimaryRouteId) => {
    setPrimaryNavigation((current) => {
      if (current.primary === route) return current;
      return {
        primary: route,
        visitedPrimary: current.visitedPrimary.has(route)
          ? current.visitedPrimary
          : new Set([...current.visitedPrimary, route]),
      };
    });
  }, []);
  const [utility, setUtility] = useState<AppRouteId>();
  const [utilityPlayerTag, setUtilityPlayerTag] = useState<string>();
  const [utilityPostId, setUtilityPostId] = useState<string>();
  const [primaryLinks, setPrimaryLinks] = useState<
    Partial<Record<PrimaryRouteId, { key: number; params: AppLinkParams }>>
  >({});
  const [linkState, setLinkState] = useState<{ key: number; params: AppLinkParams }>({
    key: 0,
    params: {},
  });
  const hasDiscordAccount = authState.currentUser?.authMethods.includes('discord') === true;
  const featureState: FeatureState = {
    ...state.features,
    // Saved bases and armies belong to Discord identities. Apply the same
    // visibility rule to menu entries, direct links, and retained page layers.
    bases_armies: state.features.bases_armies === true && hasDiscordAccount,
  };
  const featureStateRef = useRef(featureState);
  useEffect(() => {
    featureStateRef.current = {
      ...state.features,
      bases_armies: state.features.bases_armies === true && hasDiscordAccount,
    };
  }, [state.features, hasDiscordAccount]);
  const [pushedScenes, setPushedScenes] = useState<readonly PushedScene[]>([]);
  useEffect(() => {
    if (pushedScenes.length > 0) onHomeReady?.();
  }, [onHomeReady, pushedScenes.length]);
  const [snackbar, setSnackbar] = useState<string>();
  const [supportCreatorHandoffUrl, setSupportCreatorHandoffUrl] = useState<string>();
  const [deepLinkLoading, setDeepLinkLoading] = useState(false);
  const pageLoading = usePageLoadingRequest();
  const openPlayerInGame = (tag: string) => {
    void openExternal(playerGameUrl(tag, locale)).then((opened) => {
      if (opened) return;
      const message = t('deepLinkFailedToOpenPlayer');
      if (Platform.OS === 'web') setSnackbar(message);
      else Alert.alert(t('generalError'), message);
    });
  };
  const routeCurrent = useRef(true);
  const navigationGeneration = useRef(0);
  const nativeNavigation = useNavigationContainerRef();
  const nativeRouteKeys = useRef<readonly string[]>([]);
  const expectedNativeRouteKeys = useRef<readonly string[]>([]);
  useEffect(() => {
    if (!usesNativeSecondaryNavigation) return;
    let observed = nativeDetailLayers(nativeNavigation.getRootState());
    // Listen above the pages being removed. A popped page can unsubscribe before
    // its own state callback fires, leaving the shell convinced it is still open.
    // Only remove routes actually observed in the navigator: a just-published
    // destination is pending until its push appears and must not be discarded.
    return nativeNavigation.addListener('state', () => {
      const actual = nativeDetailLayers(nativeNavigation.getRootState());
      const removed = observed.filter((key) => !actual.includes(key));
      observed = actual;
      for (const key of removed.reverse()) notifyNativeSecondaryPopped(key);
    });
  }, [nativeNavigation, usesNativeSecondaryNavigation]);
  const {
    openHomeAnnouncement: presentHomeAnnouncement,
    openPreparedStory: presentPreparedStory,
    presentation: announcementPresentation,
  } = useAnnouncementPresentation();
  const user = authState.currentUser;
  const startupCovered = useStartupCovered();
  const onboardingState = useSyncExternalStore(
    onboarding.subscribe,
    onboarding.getSnapshot,
    onboarding.getSnapshot,
  );
  const canAutoAnnounce =
    !suppressAnnouncements &&
    !startupCovered &&
    onboardingState.ready &&
    onboardingState.returningUser &&
    onboardingState.userId === (user?.userId ?? null) &&
    !onboardingState.visible;
  const canAutoAnnounceRef = useRef(canAutoAnnounce);
  useEffect(() => {
    canAutoAnnounceRef.current = canAutoAnnounce;
  }, [canAutoAnnounce]);
  const handleHomeReady = useCallback(() => {
    onHomeReady?.();
  }, [onHomeReady]);
  const discordServers = useDiscordServers(user);
  const pushedScene = pushedScenes.at(-1);
  const selectPrimary = (route: PrimaryRouteId) => {
    recordBrowserPath(routeById(route).href);
    setLinkState({ key: 0, params: {} });
    navigationGeneration.current += 1;
    setPushedScenes([]);
    setUtility(undefined);
    setPrimary(route);
    if (Platform.OS === 'ios') selectNativePrimary(route);
  };
  const showUtility = useCallback(
    (route: AppRouteDefinition, playerTag?: string, initialParams: AppLinkParams = {}) => {
      if (!isRouteEnabled(route, featureStateRef.current)) return;
      recordBrowserPath(
        appLinkPath({
          kind: 'page',
          page: route.id,
          params: { ...initialParams, ...(playerTag ? { player: playerTag } : {}) },
        }),
      );
      const generation = ++navigationGeneration.current;
      // A fresh user intent must navigate even if a previous native pop missed
      // its cleanup. Re-read the real stack instead of trusting its old mirror.
      nativeRouteKeys.current = nativeDetailLayers(nativeNavigation.getRootState());
      // Invalidate outgoing cleanup synchronously, before React commits the new
      // route, so a delayed old pop cannot clear this freshly requested page.
      if (usesNativeSecondaryNavigation)
        expectedNativeRouteKeys.current = [`utility:${route.id}:${playerTag ?? ''}:${generation}`];
      setLinkState({ key: generation, params: initialParams });
      setPushedScenes([]);
      setUtilityPostId(undefined);
      setUtilityPlayerTag(playerTag);
      setUtility(route.id);
    },
    [nativeNavigation, usesNativeSecondaryNavigation],
  );
  const openUtility = useCallback((route: AppRouteDefinition) => showUtility(route), [showUtility]);
  const openPlayerUtility = (route: AppRouteDefinition, playerTag: string) => {
    if (route.id === 'ranked' || route.id === 'legends') loadPlayerUtility(route.id, playerTag);
    else showUtility(route, playerTag);
  };
  const openPost = (postId?: string) => {
    setLinkState({ key: 0, params: {} });
    recordBrowserPath(
      appLinkPath({ kind: 'page', page: 'posts', params: postId ? { postId } : {} }),
    );
    navigationGeneration.current += 1;
    setPushedScenes([]);
    setUtilityPostId(postId);
    setUtility('posts');
  };
  const closeSecondary = useCallback(() => {
    navigationGeneration.current += 1;
    if (backThroughBrowserHistory()) return;
    if (
      usesNativeSecondaryNavigation &&
      (pushedScenes.length || (utility !== undefined && utility !== 'search'))
    ) {
      router.back();
      return;
    }
    if (pushedScenes.length) setPushedScenes((current) => current.slice(0, -1));
    else setUtility(undefined);
  }, [pushedScenes, usesNativeSecondaryNavigation, utility]);

  useEffect(() => {
    const subscription = subscribeSecondaryBackHandler(
      !usesNativeSecondaryNavigation && (pushedScenes.length > 0 || utility !== undefined),
      closeSecondary,
    );
    return () => subscription?.remove();
  }, [closeSecondary, pushedScenes.length, usesNativeSecondaryNavigation, utility]);
  const pushPlayer = (player: Player) => {
    recordBrowserPath(appLinkPath({ kind: 'player', tag: player.tag, params: {} }));
    navigationGeneration.current += 1;
    setPushedScenes((current) => [...current, { kind: 'player', player }]);
  };
  const pushClan = (
    clan: Clan,
    clanSpring?: import('../../features/clan/presentation/clan-spring-transition').ClanSpringOrigin,
  ) => {
    recordBrowserPath(appLinkPath({ kind: 'clan', tag: clan.tag, params: {} }));
    navigationGeneration.current += 1;
    setPushedScenes((current) => [...current, { kind: 'clan', clan, clanSpring }]);
  };
  const pushCapital = (clan: Clan) => {
    recordBrowserPath(appLinkPath({ kind: 'capital', tag: clan.tag, params: {} }));
    navigationGeneration.current += 1;
    setPushedScenes((current) => [...current, { kind: 'capital', clan }]);
  };
  const pushCwl = (cwl: PlayerCurrentCwl) => {
    recordBrowserPath(
      appLinkPath({
        kind: 'cwl',
        tag: cwl.clanTag,
        params: cwl.summary.leagueInfo?.season
          ? { season: cwl.summary.leagueInfo.season.slice(0, 7) }
          : {},
      }),
    );
    navigationGeneration.current += 1;
    setPushedScenes((current) => [...current, { kind: 'cwl', ...cwl }]);
  };
  const pushWar = (war: WarInfo, roundNumber: number | null = null, cwl?: PlayerCurrentCwl) => {
    if (war.clan)
      recordBrowserPath(
        appLinkPath({
          kind: 'war',
          tag: war.clan.tag,
          ...(war.state === 'warEnded' && war.endTime
            ? { warId: war.endTime.toISOString().replaceAll('-', '').replaceAll(':', '') }
            : {}),
          params: {},
        }),
      );
    const generation = ++navigationGeneration.current;
    const preview: ResolvedScene = { kind: 'war', war, roundNumber, ...(cwl ? { cwl } : {}) };
    // Player history contains scores and personal hits, not either full roster.
    // Push immediately, then resolve this exact archived war instead of displaying
    // an empty player list or accidentally substituting the clan's current war.
    if (
      war.state === 'warEnded' &&
      war.clan &&
      war.endTime &&
      !war.clan.members.length &&
      !war.opponent?.members.length
    ) {
      const clanTag = war.clan.tag,
        endTime = war.endTime;
      setPushedScenes((current) => [
        ...current,
        {
          kind: 'deferred',
          preview,
          linkKey: generation,
          load: async (): Promise<ResolvedScene> => {
            const full = await WarCwlService.fetchWarDataFromTime(
              runtime.contractApi,
              clanTag,
              endTime,
              war,
            );
            if (
              !full ||
              full.endTime?.getTime() !== endTime.getTime() ||
              ![full.clan?.tag, full.opponent?.tag].includes(clanTag) ||
              (!full.clan?.members.length && !full.opponent?.members.length)
            ) {
              throw new Error('Requested historical war roster unavailable');
            }
            return { ...preview, war: full.reorderForClan(clanTag) };
          },
        },
      ]);
      return;
    }
    setPushedScenes((current) => [...current, preview]);
  };
  const pushUtility = (route: AppRouteId, playerTag?: string) => {
    recordBrowserPath(
      appLinkPath({ kind: 'page', page: route, params: playerTag ? { player: playerTag } : {} }),
    );
    navigationGeneration.current += 1;
    setPushedScenes((current) => [
      ...current,
      { kind: 'utility', route, ...(playerTag ? { playerTag } : {}) },
    ]);
  };
  const previewPlayer = (tag: string, seed: Record<string, unknown> = {}) =>
    Player.fromJson({
      tag,
      name: 'Player name',
      townHallLevel: 16,
      expLevel: 100,
      troops: [{ name: 'Barbarian', level: 1, maxLevel: 12, village: 'home' }],
      heroes: [{ name: 'Barbarian King', level: 1, maxLevel: 100, village: 'home' }],
      ...seed,
    });
  const previewClan = (tag: string, seed: Record<string, unknown> = {}) =>
    Clan.fromJson({
      tag,
      name: 'Clan name',
      clanLevel: 10,
      members: 3,
      memberList: [0, 1, 2].map((index) => ({
        tag: `#PENDING${index}`,
        name: 'Player name',
        townHallLevel: 16,
        role: 'member',
      })),
      ...seed,
    });
  const pushDeferred = (
    preview: ResolvedScene,
    load: () => Promise<ResolvedScene>,
    link: AppLink,
    initial?: ResolvedScene,
  ) => {
    const key = ++navigationGeneration.current;
    recordBrowserPath(appLinkPath(link));
    setPushedScenes((current) => [
      ...current,
      {
        kind: 'deferred',
        preview,
        initial,
        load,
        linkKey: key,
        linkParams: link.params,
      },
    ]);
  };
  const loadPlayer = (tag: string) => {
    const cached = runtime.players.profiles.find(
      (player) => canonicalTag(player.tag) === canonicalTag(tag),
    );
    pushDeferred(
      { kind: 'player', player: previewPlayer(tag) },
      async () => ({ kind: 'player', player: await runtime.players.getPlayerAndClanData(tag) }),
      { kind: 'player', tag, params: {} },
      cached ? { kind: 'player', player: cached } : undefined,
    );
  };
  const loadClan = (tag: string) => {
    const cached = runtime.clans.getClanByTag(tag);
    pushDeferred(
      { kind: 'clan', clan: previewClan(tag) },
      async () => ({ kind: 'clan', clan: await runtime.clans.getClanAndWarData(tag) }),
      { kind: 'clan', tag, params: {} },
      cached ? { kind: 'clan', clan: cached } : undefined,
    );
  };
  const loadPlayerUtility = (route: 'legends' | 'ranked', tag: string) => {
    if (runtime.players.profiles.some((player) => canonicalTag(player.tag) === canonicalTag(tag)))
      return pushUtility(route, tag);
    pushDeferred(
      { kind: 'utility', route, playerTag: tag },
      async () => {
        await runtime.players.getPlayerAndClanData(tag);
        return { kind: 'utility', route, playerTag: tag };
      },
      { kind: 'page', page: route, params: { player: tag } },
    );
  };
  const clanNavigation: ClanNavigationActions = {
    openPlayer: pushPlayer,
    openPlayerTag: loadPlayer,
    openClanTag: loadClan,
    openWar: (clan, war) =>
      pushWar(war.warInfo, null, currentCwlRoute(war, clan.tag, clan.warLeague?.name)),
    openHistoricalWar: (war) => pushWar(war, null),
    openHistoricalCwl: (clan, season, warLeagueName) => {
      recordBrowserPath(appLinkPath({ kind: 'cwl', tag: clan.tag, params: { season } }));
      navigationGeneration.current += 1;
      setPushedScenes((current) => [
        ...current,
        { kind: 'historicalCwl', clanTag: clan.tag, season, warLeagueName },
      ]);
    },
    openCwl: (clan, war) =>
      pushCwl({
        summary: war,
        clanTag: clan.tag,
        ...(clan.warLeague?.name ? { warLeagueName: clan.warLeague.name } : {}),
      }),
    openCapital: pushCapital,
    openNetworkError: () => setSnackbar(t('errorNetworkTitle')),
  };
  const playerCurrentCwl = (player: Player): PlayerCurrentCwl | undefined => {
    const clan = runtime.clans.getClanByTag(player.clanTag);
    const summary = runtime.wars.getWarCwlByTag(player.clanTag);
    return summary ? currentCwlRoute(summary, player.clanTag, clan?.warLeague?.name) : undefined;
  };
  const screens = {
    home: (
      <HomeDashboardRoot
        startupPreview={homeStartupPreview}
        active={
          primary === 'home' && !utility && pushedScenes.length === 0 && !announcementPresentation
        }
        onReady={startupPlayerLink ? undefined : handleHomeReady}
        openManageAccounts={() => openUtility(routeById('accounts'))}
        openAnnouncement={(item) => {
          void presentHomeAnnouncement(item)
            .then((opened) => {
              if (opened) return runtime.announcementPresentation.markRead(item);
            })
            .catch(() => {});
        }}
        openTodo={() => openUtility(routeById('todo'))}
        openRanked={(playerTag) => openPlayerUtility(routeById('ranked'), playerTag)}
        openLegends={(playerTag) => openPlayerUtility(routeById('legends'), playerTag)}
        openUpgradeTracker={(playerTag) =>
          openPlayerUtility(routeById('upgradeTracker'), playerTag)
        }
      />
    ),
    // The pager keeps a slot for each tab. Create its screen on first visit,
    // then keep it mounted so returning to the tab restores its local state.
    players: visitedPrimary.has('players') ? (
      <PlayersRoot
        openManageAccounts={() => openUtility(routeById('accounts'))}
        openPlayer={pushPlayer}
        openPlayerTag={loadPlayer}
        openGameSettings={() =>
          void openExternal('https://link.clashofclans.com/?action=OpenMoreSettings')
        }
      />
    ) : null,
    clans: visitedPrimary.has('clans') ? (
      <ClanRoot navigation={clanNavigation} onOpenClan={pushClan} />
    ) : null,
    war: visitedPrimary.has('war') ? (
      <WarCwlRoot
        openClan={loadClan}
        openPlayer={loadPlayer}
        onOpenWar={pushWar}
        onOpenCwl={(summary, clanTag, warLeagueName) =>
          pushCwl({
            summary,
            clanTag,
            ...(warLeagueName ? { warLeagueName } : {}),
          })
        }
      />
    ) : null,
  } as const;

  const isHomeRouteCurrent = primary === 'home' && utility === undefined && !pushedScenes.length;

  useEffect(() => {
    routeCurrent.current = isHomeRouteCurrent;
  }, [isHomeRouteCurrent]);

  useEffect(() => {
    if (!canAutoAnnounce) return;
    let active = true;
    const canPresent = () => active && canAutoAnnounceRef.current && routeCurrent.current;
    const timer = setTimeout(() => {
      const controller = new AnnouncementOpeningController({
        platform: Platform.OS,
        featureEnabled: () => state.features[APP_FEATURE_FLAGS.homeAnnouncements] === true,
        routeCurrent: canPresent,
        openingAnnouncement: runtime.announcements.getActiveAnnouncement(),
        shouldPresent: (item) => runtime.announcementPresentation.shouldPresent(item),
        prepareStory: (item) => sharedAnnouncementStoryCache.prepare(item),
        presentStory: (item, preparedUri) => presentPreparedStory(item, preparedUri, canPresent),
        markDismissed: async (item) => {
          await runtime.announcementPresentation.markRead(item);
          await runtime.announcementPresentation.markDismissed(item);
        },
      });
      void controller.tryPresent();
    }, 0);
    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [canAutoAnnounce, presentPreparedStory, runtime, state.features]);

  useEffect(
    () =>
      runtime.effects.bindRouteHandler(async (route) => {
        if (route === '/support-creator' || route === '/settings/support') {
          setSupportCreatorHandoffUrl(supportCreatorUrl(locale));
          return;
        }
        if (route === '/search') openUtility(routeById('search'));
        else if (route === '/upgrade-tracker') openUtility(routeById('upgradeTracker'));
        else if (route === '/posts') openPost();
        else if (route.startsWith('/posts/')) {
          const encodedId = route.slice('/posts/'.length).split('/', 1)[0];
          openPost(encodedId ? safeDecodeURIComponent(encodedId) : undefined);
        }
      }),
    [locale, openUtility, runtime],
  );

  useEffect(() => {
    let active = true;
    let unsubscribe: (() => void) | undefined;
    const handler = new DeepLinkHandler<Player, Clan>({
      isReady: () => active,
      isAuthenticated: () => runtime.auth.state.isAuthenticated,
      loadPlayer: (tag) => runtime.players.getPlayerAndClanData(tag),
      loadClan: (tag) => runtime.clans.getClanAndWarData(tag),
      openPlayer: pushPlayer,
      openClan: pushClan,
      openDestination: async (link: AppLink) => {
        const generation = ++navigationGeneration.current;
        if (
          link.kind === 'page' &&
          !isRouteEnabled(routeById(link.page), featureStateRef.current)
        ) {
          if (active) setSnackbar(t('generalNoDataAvailable'));
          return;
        }
        const waitsForData =
          link.kind !== 'page' ||
          ((link.page === 'ranked' || link.page === 'legends') && !!link.params.player) ||
          (link.page === 'war' && !!link.params.clan);
        if (waitsForData) {
          const tag =
            link.kind === 'page' ? (link.params.clan ?? link.params.player ?? '') : link.tag;
          const preview: ResolvedScene =
            link.kind === 'player'
              ? link.params.tab === 'legends'
                ? { kind: 'utility', route: 'legends', playerTag: tag }
                : { kind: 'player', player: previewPlayer(tag) }
              : link.kind === 'clan' || link.kind === 'capital'
                ? { kind: link.kind, clan: previewClan(tag) }
                : link.kind === 'cwl'
                  ? { kind: 'cwl', summary: loadingCwl(tag, link.params.season), clanTag: tag }
                  : link.kind === 'war' || (link.kind === 'page' && link.page === 'war')
                    ? { kind: 'war', war: loadingWar(tag), roundNumber: null }
                    : {
                        kind: 'utility',
                        route: link.kind === 'page' ? link.page : 'ranked',
                        playerTag: tag,
                      };
          const load = async (): Promise<ResolvedScene> => {
            let scene: ResolvedScene | undefined;
            if (link.kind === 'page') {
              if ((link.page === 'ranked' || link.page === 'legends') && link.params.player)
                await runtime.players.getPlayerAndClanData(link.params.player);
              if (link.page === 'war' && link.params.clan) {
                await runtime.wars.loadAllWarData([link.params.clan], { throwOnError: true });
                const summary = runtime.wars.getWarCwlByTag(link.params.clan);
                const war = summary?.isInCwl
                  ? summary.getActiveWarByTag(link.params.clan)
                  : summary?.warInfo;
                if (war?.clan) scene = { kind: 'war', war, roundNumber: null };
                else throw new Error('No war available for requested clan');
              }
            } else if (link.kind === 'player') {
              const player = await runtime.players.getPlayerAndClanData(link.tag);
              if (!player) throw new Error('Player unavailable');
              scene =
                link.params.tab === 'legends'
                  ? { kind: 'utility', route: 'legends', playerTag: player.tag }
                  : { kind: 'player', player };
            } else if (link.kind === 'clan' || link.kind === 'capital') {
              const clan = await runtime.clans.getClanAndWarData(link.tag);
              if (!clan) throw new Error('Clan unavailable');
              scene = { kind: link.kind, clan };
            } else if (link.kind === 'cwl') {
              const cwl = await runtime.wars.loadLinkedCwl(link.tag, link.params.season);
              scene = { kind: 'cwl', ...cwl, clanTag: link.tag };
            } else if (link.kind === 'war') {
              if (link.warId) {
                const end = apiDate(link.warId);
                if (!end) throw new Error('Invalid historical war end time');
                const war = await WarCwlService.fetchWarDataFromTime(
                  runtime.contractApi,
                  link.tag,
                  end,
                );
                if (!war?.clan || war.endTime?.getTime() !== end.getTime())
                  throw new Error('Requested historical war unavailable');
                scene = { kind: 'war', war: war.reorderForClan(link.tag), roundNumber: null };
              } else {
                await runtime.wars.loadAllWarData([link.tag], { throwOnError: true });
                const summary = runtime.wars.getWarCwlByTag(link.tag);
                const war = summary?.isInCwl
                  ? summary.getActiveWarByTag(link.tag)
                  : summary?.warInfo;
                if (!war?.clan) throw new Error('No current war available');
                scene = {
                  kind: 'war',
                  war: war.reorderForClan(link.tag),
                  roundNumber: null,
                  ...(summary?.isInCwl ? { cwl: { summary, clanTag: link.tag } } : {}),
                };
              }
            }

            if (scene) return scene;
            if (link.kind === 'page')
              return { kind: 'utility', route: link.page, playerTag: link.params.player };
            throw new Error('Destination unavailable');
          };
          setPushedScenes((current) => [
            ...current,
            { kind: 'deferred', preview, load, linkParams: link.params, linkKey: generation },
          ]);
          recordBrowserPath(appLinkPath(link));
          return;
        }
        if (!active || generation !== navigationGeneration.current) return;
        setLinkState({ key: generation, params: link.params });
        setUtility(undefined);
        setPushedScenes([]);
        if (link.kind === 'page') {
          if (routeById(link.page).primaryTab) {
            setPrimary(link.page as PrimaryRouteId);
            if (Platform.OS === 'ios') selectNativePrimary(link.page as PrimaryRouteId);
            setPrimaryLinks((current) => ({
              ...current,
              [link.page]: { key: generation, params: link.params },
            }));
          } else {
            setUtilityPlayerTag(link.params.player);
            setUtilityPostId(link.params.postId);
            setUtility(link.page);
          }
        }
        if (Platform.OS === 'web' && typeof window !== 'undefined')
          window.history.replaceState(window.history.state, '', appLinkPath(link));
      },
      showLoading: (loading) => {
        if (active) {
          setDeepLinkLoading(loading);
          if (!loading) {
            setStartupPlayerLink(false);
          }
        }
      },
      showFeedback: (feedback) => {
        if (active) setSnackbar(deepLinkFeedbackMessage(feedback, t));
      },
      reportError: (operation, error) => reportException(error, operation),
    });
    void startDeepLinkHandling(appLinkInbox, handler, (operation, error) =>
      reportException(error, operation),
    ).then((stop) => {
      if (active) unsubscribe = stop;
      else stop();
    });
    return () => {
      active = false;
      unsubscribe?.();
    };
  }, [locale, onHomeReady, runtime, setPrimary, t]);

  const renderUtilityContent = (
    route: AppRouteId,
    playerTag: string | undefined = utilityPlayerTag,
  ) => {
    if (route === 'settings')
      return (
        <SettingsRoot
          onClose={closeSecondary}
          onManageClans={() => selectPrimary('clans')}
          onManagePlayers={() => {
            selectPrimary('players');
            const key = ++navigationGeneration.current;
            setPrimaryLinks((current) => ({
              ...current,
              players: { key, params: { tab: 'linked' } },
            }));
          }}
        />
      );
    if (route === 'profile')
      return (
        <UserProfileScreen
          user={user}
          accounts={runtime.accounts.accounts.map((account) =>
            accountPresentationItem(
              account,
              runtime.players.profiles.find(
                (profile) => canonicalTag(profile.tag) === canonicalTag(account.playerTag),
              ),
            ),
          )}
          onBack={closeSecondary}
          onAddAccount={() => openUtility(routeById('accounts'))}
          onOpenPlayer={loadPlayer}
        />
      );
    if (route === 'accounts')
      return (
        <ManageLinkedAccountsScreen
          continueLabel={materialContinueLabel(locale)}
          firstConnection={false}
          initialAccounts={runtime.accounts.accounts.map((account) =>
            accountPresentationItem(
              account,
              runtime.players.profiles.find(
                (profile) => canonicalTag(profile.tag) === canonicalTag(account.playerTag),
              ),
            ),
          )}
          lookupPlayer={(tag) => runtime.players.lookupPlayerIdentity(tag)}
          playerProfiles={runtime.players.profiles}
          onBack={closeSecondary}
          onContinue={async () => {
            const result = await refreshLinkedAccountsForCurrentAuth(
              runtime.auth,
              runtime.accounts,
            );
            if (!result.authenticated) throw new Error(t('authErrorUserNotAuthenticated'));
            if (!result.hasVerifiedAccount) throw new Error(t('homeVerifiedAccountRequiredBody'));
            await runtime.accountBootstrap
              .initialize(user?.userId ?? null, {
                links: runtime.accounts.accounts,
                selectedTagLoaded: true,
              })
              .catch((error) => reportException(error, 'accounts.bootstrap'));
            closeSecondary();
          }}
          onOpenGameSettings={() =>
            openExternal('https://link.clashofclans.com/?action=OpenMoreSettings')
          }
          onRefresh={() => runtime.accountBootstrap.initialize(user?.userId ?? null)}
          service={runtime.accounts}
          user={user}
        />
      );
    if (route === 'posts')
      return <PostsRoot initialPostId={utilityPostId} onBack={closeSecondary} />;
    if (route === 'achievements') return <AchievementsRoot onBack={closeSecondary} />;
    if (route === 'esports') return <EsportsRoot onBack={closeSecondary} />;
    if (route === 'search')
      return (
        <SearchRoot
          autofocus
          overlay
          onCancel={closeSecondary}
          onOpenPlayer={pushPlayer}
          onOpenClan={pushClan}
          onOpenDestination={({ kind, seed, load }) => {
            const tag = String(seed.tag ?? '');
            pushDeferred(
              kind === 'player'
                ? { kind, player: previewPlayer(tag, seed) }
                : { kind, clan: previewClan(tag, seed) },
              load,
              { kind, tag, params: {} },
            );
          }}
        />
      );
    if (route === 'servers')
      return Platform.OS === 'ios' || Platform.OS === 'android' ? (
        <ServersRoot
          directory={discordServers}
          onBack={closeSecondary}
          onOpenServer={(server) => {
            // Push above the retained list so native back gestures return to Servers, not Home.
            navigationGeneration.current++;
            setPushedScenes((current) => [...current, { kind: 'serverDashboard', server }]);
          }}
        />
      ) : null;
    if (route === 'rankings')
      return (
        <RankingsRoot
          onBack={closeSecondary}
          openPlayer={pushPlayer}
          openClan={pushClan}
          openPlayerTag={loadPlayer}
          openClanTag={loadClan}
        />
      );
    if (route === 'stats')
      return (
        <RankingsRoot
          onBack={closeSecondary}
          openPlayer={pushPlayer}
          openClan={pushClan}
          openPlayerTag={loadPlayer}
          openClanTag={loadClan}
        />
      );
    if (route === 'basesArmies')
      return hasDiscordAccount ? <BasesArmiesRoot onBack={closeSecondary} /> : null;
    if (route === 'todo') return <TodoRoot onBack={closeSecondary} openPlayer={pushPlayer} />;
    if (route === 'gameAssets') return <GameAssetsRoot onBack={closeSecondary} />;
    if (route === 'ranked') {
      const verified = new Set(
        runtime.accounts.verifiedAccounts.map((account) => canonicalTag(account.playerTag)),
      );
      const available = runtime.players.profiles.filter(
        (player) =>
          playerTag !== undefined ||
          (verified.has(canonicalTag(player.tag)) &&
            runtime.playerCardPreferences.isRankedShownOnHome(player.tag)),
      );
      const player = playerTag
        ? available.find((candidate) => canonicalTag(candidate.tag) === canonicalTag(playerTag))
        : available[0];
      if (!player)
        return (
          <View style={styles.boundary}>
            <EmptyState
              title={t('generalNoDataAvailable')}
              body={t('dashboardRankedNoData')}
              icon={<Trophy color={theme.onSurfaceVariant} size={28} />}
            />
          </View>
        );
      return (
        <RankedRoot
          key={`ranked:${player.tag}:${playerTag === undefined ? 'accounts' : 'player'}`}
          player={player}
          allowAccountSwitch={playerTag === undefined}
          onBack={closeSecondary}
          openPlayer={pushPlayer}
          openPlayerTag={loadPlayer}
          openInGame={openPlayerInGame}
        />
      );
    }
    if (route === 'legends') {
      const player = selectLegendsPlayer(
        runtime.players.profiles,
        runtime.accounts.verifiedAccounts.map((account) => account.playerTag),
        playerTag,
      );
      if (!player)
        return (
          <View style={styles.boundary}>
            <EmptyState
              title={t('generalNoDataAvailable')}
              body={t('legendsNoDataToday')}
              icon={<Trophy color={theme.onSurfaceVariant} size={28} />}
            />
          </View>
        );
      return (
        <LegendsRoot
          key={`legends:${player.tag}`}
          player={player}
          onBack={closeSecondary}
          onOpenClan={loadClan}
          onOpenOpponent={(tag) => loadPlayerUtility('legends', tag)}
        />
      );
    }
    if (route === 'calculators')
      return (
        <CalculatorsRoot
          onBack={closeSecondary}
          onOpenUpgradeTracker={(tag) => pushUtility('upgradeTracker', tag ?? undefined)}
        />
      );
    if (route === 'upgradeTracker')
      return (
        <UpgradeTrackerRoot
          initialTag={playerTag}
          onBack={closeSecondary}
          onOpenAccounts={() => pushUtility('accounts')}
        />
      );
    throw new Error(`Unsupported utility route: ${route}`);
  };

  const renderPushedScene = (scene: PushedScene, loading = false): ReactNode => {
    if (scene.kind === 'deferred')
      return (
        <DeferredDestination
          load={scene.load}
          initial={scene.initial}
          pending={
            <WikiNavigationContext.Provider value={wikiNavigation}>
              <LinkParametersContext.Provider value={EMPTY_LINK_PARAMS}>
                {renderPushedScene(scene.preview, true)}
              </LinkParametersContext.Provider>
            </WikiNavigationContext.Provider>
          }
          onBack={closeSecondary}
        >
          {(resolved) => renderPushedScene(resolved)}
        </DeferredDestination>
      );
    if (scene.kind === 'historicalCwl')
      return (
        <HistoricalCwlRoot
          clanTag={scene.clanTag}
          season={scene.season}
          warLeagueName={scene.warLeagueName}
          onBack={closeSecondary}
          onOpenWar={(war, round) => pushWar(war, round)}
          openClan={loadClan}
          openPlayer={loadPlayer}
        />
      );
    if (scene.kind === 'serverDashboard')
      return <ServerDashboardScreen server={scene.server} onBack={closeSecondary} />;
    if (scene.kind === 'wiki')
      return (
        <UpgradeItemDetailContent
          item={scene.item}
          snapshot={scene.snapshot}
          page
          embedded
          wikiSection={wikiSectionForUpgradeCategory(scene.item.category)}
          onClose={closeSecondary}
        />
      );
    if (scene.kind === 'player')
      return (
        <PlayerDetailRoot
          loading={loading}
          player={scene.player}
          service={runtime.players}
          bookmarked={runtime.bookmarks.isPlayerBookmarked(scene.player.tag)}
          linkedAccount={runtime.accounts.accounts.some(
            (account) => canonicalTag(account.playerTag) === canonicalTag(scene.player.tag),
          )}
          verifiedTracking={runtime.accounts.verifiedAccounts.some(
            (account) => canonicalTag(account.playerTag) === canonicalTag(scene.player.tag),
          )}
          currentWar={scene.player.warData}
          currentCwl={playerCurrentCwl(scene.player)}
          actions={{
            goBack: closeSecondary,
            toggleBookmark: (player) => runtime.bookmarks.togglePlayer(player),
            openInGame: openPlayerInGame,
            copyTag: async (tag) => {
              await Clipboard.setStringAsync(tag);
            },
            openClan: loadClan,
            openWar: (war) =>
              pushWar(
                war,
                null,
                war.state === 'warEnded' ? undefined : playerCurrentCwl(scene.player),
              ),
            openCwl: pushCwl,
            openPlayer: loadPlayer,
            openRanked: (player) => pushUtility('ranked', player.tag),
            openLegends: (player) => pushUtility('legends', player.tag),
            openAchievements: () => pushUtility('achievements'),
            showMessage: setSnackbar,
          }}
        />
      );
    if (scene.kind === 'clan')
      return (
        <ClanInfoRoot
          loading={loading}
          clan={scene.clan}
          goBack={closeSecondary}
          navigation={clanNavigation}
        />
      );
    if (scene.kind === 'capital' && loading)
      return <ClanCapitalScreen clan={scene.clan} goBack={closeSecondary} loading />;
    if (scene.kind === 'capital')
      return <ClanCapitalRoot clan={scene.clan} goBack={closeSecondary} />;
    if (scene.kind === 'war')
      return (
        <WarInfoRoot
          loading={loading}
          war={scene.war}
          roundNumber={scene.roundNumber}
          onBack={closeSecondary}
          openClan={loadClan}
          openPlayer={loadPlayer}
          onOpenCwl={scene.cwl ? () => pushCwl(scene.cwl!) : undefined}
        />
      );
    if (scene.kind === 'cwl')
      return (
        <CwlInfoRoot
          placeholder={loading}
          summary={scene.summary}
          clanTag={scene.clanTag}
          warLeagueName={scene.warLeagueName}
          onBack={closeSecondary}
          onOpenWar={(war, roundNumber) => pushWar(war, roundNumber)}
          openClan={loadClan}
          openPlayer={loadPlayer}
        />
      );
    if (loading && scene.route === 'ranked')
      return (
        <RankedScreen
          identityLoading
          player={previewPlayer(scene.playerTag ?? '')}
          data={null}
          loading
          refreshing={false}
          error={null}
          accounts={[]}
          bookmarked={false}
          linked={false}
          onBack={closeSecondary}
          onRefresh={async () => {}}
          onSwitchPlayer={() => {}}
          onToggleBookmark={async () => {}}
          onOpenInGame={() => {}}
          onOpenPlayerTag={async () => {}}
        />
      );
    if (loading && scene.route === 'legends')
      return (
        <LegendsScreen
          data={null}
          error={null}
          loading
          refreshing={false}
          selectedDay={currentLegendDay()}
          onBack={closeSecondary}
          onRefresh={async () => {}}
          onSelectDay={() => {}}
          onExport={() => {}}
        />
      );
    return renderUtilityContent(scene.route, scene.playerTag);
  };
  const prepareNativeWikiScene = (
    scene: ResolvedScene,
    layer: string,
    sourceRoutes: readonly string[],
    catalogue?: readonly WikiEntry[],
  ) => {
    // Publish the exact destination before the native push. Keep ownership
    // out of shell state so navigation cannot also rebuild retained pages.
    publishNativeSecondaryLayer(layer, {
      owner: 'wiki-link',
      content: (
        <PageLoadingHost value={true}>
          <WikiNavigationContext.Provider value={wikiNavigation}>
            <LinkParametersContext.Provider
              value={scene.linkParams ?? EMPTY_LINK_PARAMS}
              key={scene.linkKey}
            >
              <WikiCatalogueContext.Provider value={catalogue ?? null}>
                {renderPushedScene(scene)}
              </WikiCatalogueContext.Provider>
            </LinkParametersContext.Provider>
          </WikiNavigationContext.Provider>
          <PageLoadingOverlay visible={deepLinkLoading || pageLoading} />
        </PageLoadingHost>
      ),
      onRemove() {
        if (!expectedNativeRouteKeys.current.includes(layer)) return;
        navigationGeneration.current += 1;
        nativeRouteKeys.current = nativeRouteKeys.current.filter((key) => key !== layer);
        expectedNativeRouteKeys.current = expectedNativeRouteKeys.current.filter(
          (key) => key !== layer,
        );
      },
    });
    nativeRouteKeys.current = [...sourceRoutes, layer];
    expectedNativeRouteKeys.current = nativeRouteKeys.current;
    // No shell state update here: the native Link pushes the
    // published page directly, and its native pop releases it.
  };
  const wikiNavigation: WikiNavigation = {
    openSection(category: string, catalogue?: readonly WikiEntry[]) {
      const generation = ++navigationGeneration.current;
      if (usesNativeSecondaryNavigation) {
        const layer = `pushed:wiki:${generation}:utility:wiki:section`;
        prepareNativeWikiScene(
          { kind: 'utility', route: 'gameAssets', linkKey: generation, linkParams: { category } },
          layer,
          nativeDetailLayers(nativeNavigation.getRootState()),
          catalogue,
        );
        router.push({ pathname: '/detail', params: { layer } });
        return;
      }
      setPushedScenes((current) => [
        ...current,
        {
          kind: 'utility',
          route: 'gameAssets',
          linkKey: generation,
          linkParams: { category },
          wikiCatalogue: catalogue,
        },
      ]);
    },
    openItem(item: UpgradeTrackerItem, snapshot?: UpgradeTrackerSnapshot) {
      const generation = ++navigationGeneration.current;
      if (usesNativeSecondaryNavigation) {
        const layer = `pushed:wiki:${generation}:utility:wiki:item`;
        prepareNativeWikiScene(
          { kind: 'wiki', item, snapshot },
          layer,
          nativeDetailLayers(nativeNavigation.getRootState()),
        );
        router.push({ pathname: '/detail', params: { layer } });
        return;
      }
      setPushedScenes((current) => [...current, { kind: 'wiki', item, snapshot }]);
    },
    openEntry(key: string) {
      const generation = ++navigationGeneration.current;
      if (usesNativeSecondaryNavigation) {
        const layer = `pushed:wiki:${generation}:utility:wiki:entry`;
        prepareNativeWikiScene(
          { kind: 'utility', route: 'gameAssets', linkKey: generation, linkParams: { asset: key } },
          layer,
          nativeDetailLayers(nativeNavigation.getRootState()),
        );
        router.push({ pathname: '/detail', params: { layer } });
        return;
      }
      setPushedScenes((current) => [
        ...current,
        {
          kind: 'utility',
          route: 'gameAssets',
          linkKey: generation,
          linkParams: { asset: key },
        },
      ]);
    },
    ...(usesNativeSecondaryNavigation
      ? {
          entryLink(
            key: string,
            token: string,
            sourceLayer?: string,
            catalogue?: readonly WikiEntry[],
          ) {
            const layer = `pushed:wiki:${token}:utility:wiki:entry`;
            return {
              href: { pathname: '/detail' as const, params: { layer } },
              prepare() {
                // The pressed native route is authoritative. A frozen source
                // may still hold props published while its child was open.
                // Reconcile that removed tail now, rather than making the user
                // wait for the owner's next render after native Back.
                const state = nativeNavigation.getRootState();
                const sourceRoutes = nativeDetailLayers(state);
                // Read the native navigator at press time. The owner can still
                // contain popped scenes while UIKit is already on the source.
                // Focus in a retained child navigator is not authoritative.
                if (sourceLayer && sourceRoutes.at(-1) !== sourceLayer) return false;
                if (!sourceLayer && sourceRoutes.length > 0) return false;
                // Native Wiki links own their route lifetime. Adding this item
                // to the shell's React state also republishes every retained
                // page and renders the home cards during each push and pop.
                const scene: ResolvedScene = {
                  kind: 'utility',
                  route: 'gameAssets',
                  linkKey: ++navigationGeneration.current,
                  linkParams: { asset: key },
                  nativeKey: layer,
                  wikiCatalogue: catalogue,
                };
                prepareNativeWikiScene(scene, layer, sourceRoutes, catalogue);
                return true;
              },
            };
          },
        }
      : {}),
  };

  const secondaryLayers = [
    ...(utility
      ? [
          {
            key: `utility:${utility}:${utilityPlayerTag ?? ''}:${linkState.key}`,
            content: (
              <WikiNavigationContext.Provider value={wikiNavigation}>
                <LinkParametersContext.Provider value={linkState.params} key={linkState.key}>
                  {renderUtilityContent(utility)}
                </LinkParametersContext.Provider>
              </WikiNavigationContext.Provider>
            ),
          },
        ]
      : []),
    ...pushedScenes.map((scene, index) => ({
      clanSpring: scene.clanSpring,
      key:
        ('nativeKey' in scene ? scene.nativeKey : undefined) ??
        `pushed:${index}:${scene.kind}:${scene.linkKey ?? ''}`,
      content: (
        <WikiNavigationContext.Provider value={wikiNavigation}>
          <LinkParametersContext.Provider
            value={scene.linkParams ?? EMPTY_LINK_PARAMS}
            key={scene.linkKey}
          >
            <WikiCatalogueContext.Provider
              value={('wikiCatalogue' in scene ? scene.wikiCatalogue : null) ?? null}
            >
              {renderPushedScene(scene)}
            </WikiCatalogueContext.Provider>
          </LinkParametersContext.Provider>
        </WikiNavigationContext.Provider>
      ),
    })),
  ];
  const secondaryContent = secondaryLayers.at(-1)?.content;

  // Publish the route and dispatch its push before paint. A passive effect
  // leaves a visible beat between the press and the native transition.
  useLayoutEffect(() => {
    if (!usesNativeSecondaryNavigation) {
      removeNativeSecondaryLayers([...nativeRouteKeys.current, ...expectedNativeRouteKeys.current]);
      nativeRouteKeys.current = [];
      expectedNativeRouteKeys.current = [];
      return;
    }

    // Search stays over the retained tab tree. Only result details enter UIKit's
    // stack; pushing search itself replaces its source header mid-morph.
    const nativeLayers = secondaryLayers.filter(
      (layer) => !layer.key.startsWith('utility:search:'),
    );
    const expected = retainedNativeWikiRouteKeys(
      nativeLayers.map((layer) => layer.key),
      nativeDetailLayers(nativeNavigation.getRootState()),
    );
    expectedNativeRouteKeys.current = expected;
    nativeLayers.forEach((layer, layerIndex) => {
      publishNativeSecondaryLayer(layer.key, {
        clanSpring: 'clanSpring' in layer ? layer.clanSpring : undefined,
        // Only the top retained route shows navigation progress; keep its real
        // content visible and never present a second UIKit modal.
        content: (
          <PageLoadingHost value={true}>
            {layer.content}
            {layerIndex === nativeLayers.length - 1 ? (
              <PageLoadingOverlay visible={deepLinkLoading || pageLoading} />
            ) : null}
          </PageLoadingHost>
        ),
        onRemove: () => {
          if (!expectedNativeRouteKeys.current.includes(layer.key)) return;
          navigationGeneration.current += 1;
          nativeRouteKeys.current = nativeRouteKeys.current.filter((key) => key !== layer.key);
          // Root and page listeners can both observe the same pop. Claim it
          // once before updating React, so an older cleanup cannot clear a new open.
          expectedNativeRouteKeys.current = expectedNativeRouteKeys.current.filter(
            (key) => key !== layer.key,
          );
          if (layer.key.startsWith('utility:')) {
            setPushedScenes([]);
            setUtility(undefined);
            return;
          }
          setPushedScenes((current) => {
            const position = current.findIndex(
              (entry, index) =>
                (entry.nativeKey ?? `pushed:${index}:${entry.kind}:${entry.linkKey ?? ''}`) ===
                layer.key,
            );
            return position < 0 ? current : current.slice(0, position);
          });
        },
      });
    });

    const transition = nativeSecondaryRouteTransition(nativeRouteKeys.current, expected);
    nativeRouteKeys.current = transition.routeKeys;
    applyNativeSecondaryRouteTransition(
      transition,
      Platform.OS === 'ios'
        ? router
        : {
            ...router,
            // Non-iOS shells have no nested native tab route to preserve.
            dismissAll: () => router.dismissTo('/'),
          },
    );
  });

  useEffect(
    () => () => {
      removeNativeSecondaryLayers([...nativeRouteKeys.current, ...expectedNativeRouteKeys.current]);
      nativeRouteKeys.current = [];
      expectedNativeRouteKeys.current = [];
    },
    [],
  );

  return (
    <PageLoadingHost value={true}>
      <NavigationShell
        avatar={<ProfileAvatar size={40} />}
        sidebarAvatar={<ProfileAvatar size={88} interactive />}
        closeDrawerLabel={t('navigationCloseDrawer')}
        displayName={user?.username ?? 'ClashKing'}
        drawerHintStore={runtime.preferences}
        features={featureState}
        followerCount={authState.followerCount}
        hasUser={user !== null}
        hidePrimaryNavigation={suppressAnnouncements}
        isDiscordCommunityMember={user?.discordCommunityMember === true}
        hasManagedDiscordBot={discordServers.servers.some(
          (server) => server.has_bot && managesDiscordServer(server),
        )}
        isRtl={isRtl}
        onAccounts={() => openUtility(routeById('accounts'))}
        onAchievements={() => openUtility(routeById('achievements'))}
        onAddAccount={() => openUtility(routeById('accounts'))}
        onPrimarySelect={selectPrimary}
        onNativePrimaryFocus={setPrimary}
        onSearch={() => openUtility(routeById('search'))}
        onUtilityNavigate={openUtility}
        primaryScreens={
          Object.fromEntries(
            Object.entries(screens).map(([key, screen]) => {
              const entry = primaryLinks[key as PrimaryRouteId];
              return [
                key,
                <WikiNavigationContext.Provider key={key} value={wikiNavigation}>
                  <LinkParametersContext.Provider
                    key={entry?.key ?? 0}
                    value={entry?.params ?? EMPTY_LINK_PARAMS}
                  >
                    {screen}
                  </LinkParametersContext.Provider>
                </WikiNavigationContext.Provider>,
              ];
            }),
          ) as Record<PrimaryRouteId, React.ReactNode>
        }
        productLabel=""
        profileMenuLabel={t('navigationOpenProfileMenu')}
        searchOverlay={
          usesNativeSecondaryNavigation && utility === 'search'
            ? secondaryLayers[0]?.content
            : undefined
        }
        secondaryContent={usesNativeSecondaryNavigation ? undefined : secondaryContent}
        secondaryLayers={usesNativeSecondaryNavigation ? [] : secondaryLayers}
        secondaryFullScreen={
          // Search covers the desktop shell, but a detail opened from search
          // must restore the sidebar instead of inheriting that full-screen flag.
          pushedScene
            ? pushedScene.kind === 'utility' && pushedScene.route === 'search'
            : utility === 'search'
        }
        secondaryRouteId={secondaryRouteIdFor(pushedScene)}
        selectedPrimary={primary}
        selectedUtility={pushedScene ? undefined : utility}
        t={t}
      />
      {announcementPresentation}
      <Snackbar avoidBottomNavigation message={snackbar} onDismiss={() => setSnackbar(undefined)} />
      {!usesNativeSecondaryNavigation || secondaryLayers.length === 0 ? (
        <PageLoadingOverlay visible={deepLinkLoading || pageLoading} />
      ) : null}
      <ClashHandoffDialog
        visible={supportCreatorHandoffUrl !== undefined}
        onCancel={() => setSupportCreatorHandoffUrl(undefined)}
        onConfirm={() => {
          const url = supportCreatorHandoffUrl;
          setSupportCreatorHandoffUrl(undefined);
          if (url) void openExternal(url);
        }}
      />
    </PageLoadingHost>
  );
}

function secondaryRouteIdFor(scene: PushedScene | undefined): AppRouteId | undefined {
  if (!scene) return undefined;
  if (scene.kind === 'deferred') return secondaryRouteIdFor(scene.preview);
  if (scene.kind === 'utility') return scene.route;
  // Android renders secondary layers only when they have a shell route ID.
  // Keep this exhaustive: an omitted kind silently reveals the primary list
  // even when its pushed screen and API data are ready.
  const routes = {
    wiki: 'gameAssets',
    player: 'players',
    clan: 'clans',
    capital: 'clans',
    war: 'war',
    cwl: 'war',
    historicalCwl: 'war',
    serverDashboard: 'servers',
  } satisfies Record<Exclude<ResolvedScene['kind'], 'utility'>, AppRouteId>;
  return routes[scene.kind];
}

function currentCwlRoute(
  summary: WarCwl,
  clanTag: string,
  warLeagueName?: string,
): PlayerCurrentCwl | undefined {
  if (!summary.isInCwl || summary.leagueInfo?.getClanDetails(clanTag) == null) return undefined;
  return {
    summary,
    clanTag,
    ...(warLeagueName ? { warLeagueName } : {}),
  };
}

function deepLinkFeedbackMessage(
  feedback: DeepLinkFeedback,
  t: ReturnType<typeof useI18n>['t'],
): string {
  switch (feedback) {
    case 'comingSoon':
      return t('generalComingSoon');
    case 'invalidPlayer':
      return t('deepLinkInvalidPlayer');
    case 'invalidClan':
      return t('deepLinkInvalidClan');
    case 'failedPlayer':
      return t('deepLinkFailedToOpenPlayer');
    case 'failedClan':
      return t('deepLinkFailedToOpenClan');
    case 'unavailable':
      return t('generalNoDataAvailable');
    case 'unknown':
      return t('deepLinkUnknown');
  }
}

function safeDecodeURIComponent(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

function routeById(id: AppRouteId): AppRouteDefinition {
  const route = appRoutes.find((candidate) => candidate.id === id);
  if (!route) throw new Error(`Unknown application route: ${id}`);
  return route;
}

async function openExternal(url: string): Promise<boolean> {
  try {
    const { openURL } = await import('expo-linking');
    await openURL(url);
    return true;
  } catch {
    return false;
  }
}

const styles = StyleSheet.create({
  avatar: { width: 36, height: 36, borderRadius: 18 },
  boundary: { flex: 1, padding: 16 },
});

function selectNativePrimary(route: PrimaryRouteId) {
  // Dismiss the outer detail stack before targeting a nested tab. Dispatching
  // both in the same commit lets the detail dismissal undo the tab selection.
  // Primary-to-primary selection has no stack to pop. Dispatching dismissAll
  // there emits an unhandled POP_TO_TOP instead of changing only the tab.
  if (router.canDismiss()) router.dismissAll();
  // iPad uses the retained pager, not nested native tab routes. Its caller has
  // already selected the page in state; only dismiss any native detail stack.
  if (Platform.OS === 'ios' && Platform.isPad) return;
  requestAnimationFrame(() => router.navigate(routeById(route).href as Href));
}

/** Active native detail routes, read at the moment a Wiki card is pressed. */
function nativeDetailLayers(
  state:
    | { index?: number; routes: readonly { name: string; params?: unknown; state?: unknown }[] }
    | undefined,
): string[] {
  if (!state) return [];
  if (state.routes.some((route) => route.name === 'detail')) {
    return state.routes.slice(0, (state.index ?? state.routes.length - 1) + 1).flatMap((route) => {
      const params = route.params as { layer?: unknown } | undefined;
      return route.name === 'detail' && typeof params?.layer === 'string' ? [params.layer] : [];
    });
  }
  return nativeDetailLayers(
    state.routes[state.index ?? 0]?.state as Parameters<typeof nativeDetailLayers>[0],
  );
}
