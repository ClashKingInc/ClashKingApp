import * as Clipboard from 'expo-clipboard';
import { router } from 'expo-router';
import { useCallback, useEffect, useRef, useState, useSyncExternalStore } from 'react';
import { Platform, StyleSheet, View, useWindowDimensions } from 'react-native';
import { Trophy, UserRound } from 'lucide-react-native';

import {
  accountPresentationItem,
  ManageLinkedAccountsScreen,
} from '../../features/accounts/presentation';
import { materialContinueLabel, useI18n } from '../../i18n';
import {
  appRoutes,
  type AppRouteDefinition,
  type AppRouteId,
  type FeatureState,
} from '../../navigation';
import { NavigationShell, resolveShellLayout, type PrimaryRouteId } from '../../shell';
import { SettingsRoot } from '../../features/settings/presentation';
import {
  AnnouncementOpeningController,
  sharedAnnouncementStoryCache,
} from '../../features/home/data';
import {
  HomeDashboardRoot,
  PostsRoot,
  useAnnouncementPresentation,
} from '../../features/home/presentation';
import { AchievementsRoot } from '../../features/achievements/presentation';
import {
  PlayersRoot,
  PlayerDetailRoot,
  type PlayerCurrentCwl,
} from '../../features/player/presentation';
import type { Player } from '../../features/player/models';
import {
  ClanCapitalRoot,
  ClanInfoRoot,
  ClanRoot,
  type ClanNavigationActions,
} from '../../features/clan/presentation';
import type { Clan } from '../../features/clan/models';
import { CwlInfoRoot, WarCwlRoot, WarInfoRoot } from '../../features/war/presentation';
import type { WarCwl, WarInfo } from '../../features/war/models';
import { SubscriptionRoot } from '../../features/subscription';
import { SearchRoot } from '../../features/search';
import { RankedRoot } from '../../features/ranked';
import { RankingsRoot } from '../../features/rankings';
import { StatsRoot } from '../../features/stats';
import { BasesArmiesRoot } from '../../features/bases-armies';
import { TodoRoot } from '../../features/todo';
import { GameAssetsRoot } from '../../features/game-assets';
import { CalculatorsRoot } from '../../features/calculators';
import { UpgradeTrackerRoot } from '../../features/upgrade-tracker';
import { APP_FEATURE_FLAGS } from '../feature-flags/feature-flags';
import { canonicalTag } from '../domain/tags';
import { reportException } from '../observability/observability';
import { refreshLinkedAccountsForCurrentAuth } from '../../features/auth/startup';
import { DeepLinkHandler, startDeepLinkHandling, type DeepLinkFeedback } from '../deep-links';
import {
  ClashHandoffDialog,
  EmptyState,
  MobileWebImage,
  SkeletonLoadingDialog,
  Snackbar,
  useCKTheme,
} from '../../ui';
import { useAppRuntime, useAppState } from './runtime-context';
import { subscribeSecondaryBackHandler } from './secondary-back-handler';
import {
  nativeSecondaryRouteTransition,
  publishNativeSecondaryLayer,
  removeNativeSecondaryLayer,
  removeNativeSecondaryLayers,
} from './native-secondary-navigation';
import { supportCreatorUrl } from './runtime-effects';
import { appLinkInbox } from '../deep-links/link-inbox';
import { appLinkPath, type AppLink, type AppLinkParams } from '../deep-links/app-link';
import { LinkParametersContext, EMPTY_LINK_PARAMS } from '../deep-links/link-parameters';
import { WarCwlService } from '../../features/war/data';
import { apiDate } from '../../features/war/models';
import { isRouteEnabled } from '../../navigation/route-manifest';
import { recordBrowserPath, backThroughBrowserHistory } from '../deep-links/browser-history';

type PushedScene = { readonly linkParams?: AppLinkParams; readonly linkKey?: number } & (
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
      readonly kind: 'utility';
      readonly route: AppRouteId;
      readonly playerTag?: string;
    }
);

/** Production shell composition for the retained four-tab Flutter navigation model. */
export function AuthenticatedRoot() {
  const runtime = useAppRuntime();
  const state = useAppState();
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
  const viewportWidth = useWindowDimensions().width;
  const usesNativeSecondaryNavigation =
    Platform.OS === 'ios' && resolveShellLayout(Platform.OS, viewportWidth) === 'mobile';
  const subscribeAuth = useCallback(
    (listener: () => void) => runtime.auth.subscribe(listener),
    [runtime.auth],
  );
  const getAuthSnapshot = useCallback(() => runtime.auth.state, [runtime.auth]);
  const authState = useSyncExternalStore(subscribeAuth, getAuthSnapshot, getAuthSnapshot);
  const [primary, setPrimary] = useState<PrimaryRouteId>('home');
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
  const featureStateRef = useRef(state.features);
  useEffect(() => {
    featureStateRef.current = state.features;
  }, [state.features]);
  const [pushedScenes, setPushedScenes] = useState<readonly PushedScene[]>([]);
  const [snackbar, setSnackbar] = useState<string>();
  const [handoffUrl, setHandoffUrl] = useState<string>();
  const [deepLinkLoading, setDeepLinkLoading] = useState(false);
  const routeCurrent = useRef(true);
  const navigationGeneration = useRef(0);
  const nativeRouteKeys = useRef<readonly string[]>([]);
  const expectedNativeRouteKeys = useRef<readonly string[]>([]);
  const {
    openHomeAnnouncement: presentHomeAnnouncement,
    openPreparedStory: presentPreparedStory,
    presentation: announcementPresentation,
  } = useAnnouncementPresentation();
  const user = authState.currentUser;
  const featureState: FeatureState = { ...state.features };
  const pushedScene = pushedScenes.at(-1);
  const selectPrimary = (route: PrimaryRouteId) => {
    recordBrowserPath(routeById(route).href);
    setLinkState({ key: 0, params: {} });
    navigationGeneration.current += 1;
    setPushedScenes([]);
    setUtility(undefined);
    setPrimary(route);
  };
  const showUtility = useCallback((route: AppRouteDefinition, playerTag?: string) => {
    recordBrowserPath(
      appLinkPath({ kind: 'page', page: route.id, params: playerTag ? { player: playerTag } : {} }),
    );
    setLinkState({ key: 0, params: {} });
    navigationGeneration.current += 1;
    setPushedScenes([]);
    setUtilityPostId(undefined);
    setUtilityPlayerTag(playerTag);
    setUtility(route.id);
  }, []);
  const openUtility = useCallback((route: AppRouteDefinition) => showUtility(route), [showUtility]);
  const openPlayerUtility = useCallback(
    (route: AppRouteDefinition, playerTag: string) => showUtility(route, playerTag),
    [showUtility],
  );
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
    if (usesNativeSecondaryNavigation && (pushedScenes.length || utility !== undefined)) {
      router.back();
      return;
    }
    if (pushedScenes.length) setPushedScenes((current) => current.slice(0, -1));
    else setUtility(undefined);
  }, [pushedScenes.length, usesNativeSecondaryNavigation, utility]);

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
  const pushClan = (clan: Clan) => {
    recordBrowserPath(appLinkPath({ kind: 'clan', tag: clan.tag, params: {} }));
    navigationGeneration.current += 1;
    setPushedScenes((current) => [...current, { kind: 'clan', clan }]);
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
    navigationGeneration.current += 1;
    setPushedScenes((current) => [
      ...current,
      { kind: 'war', war, roundNumber, ...(cwl ? { cwl } : {}) },
    ]);
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
  const loadPlayer = (tag: string) => {
    const generation = ++navigationGeneration.current;
    void runtime.players
      .getPlayerAndClanData(tag)
      .then((player) => {
        if (generation === navigationGeneration.current) pushPlayer(player);
      })
      .catch((error) => setSnackbar(String(error)));
  };
  const loadClan = (tag: string) => {
    const generation = ++navigationGeneration.current;
    void runtime.clans
      .getClanAndWarData(tag)
      .then((clan) => {
        if (generation === navigationGeneration.current) pushClan(clan);
      })
      .catch((error) => setSnackbar(String(error)));
  };
  const clanNavigation: ClanNavigationActions = {
    openPlayer: pushPlayer,
    openWar: (clan, war) =>
      pushWar(war.warInfo, null, currentCwlRoute(war, clan.tag, clan.warLeague?.name)),
    openHistoricalWar: (war) => pushWar(war, null),
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
        openManageAccounts={() => openUtility(routeById('accounts'))}
        openAnnouncement={(item) => void presentHomeAnnouncement(item)}
        openTodo={() => openUtility(routeById('todo'))}
        openRanked={(playerTag) => openPlayerUtility(routeById('ranked'), playerTag)}
        openUpgradeTracker={(playerTag) =>
          openPlayerUtility(routeById('upgradeTracker'), playerTag)
        }
      />
    ),
    players: (
      <PlayersRoot
        openManageAccounts={() => openUtility(routeById('accounts'))}
        openPlayer={pushPlayer}
        openGameSettings={() =>
          void openExternal('https://link.clashofclans.com/?action=OpenMoreSettings')
        }
      />
    ),
    clans: <ClanRoot navigation={clanNavigation} onOpenClan={pushClan} />,
    war: (
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
    ),
  } as const;

  const isHomeRouteCurrent = primary === 'home' && utility === undefined && !pushedScenes.length;

  useEffect(() => {
    routeCurrent.current = isHomeRouteCurrent;
  }, [isHomeRouteCurrent]);

  useEffect(() => {
    const timer = setTimeout(() => {
      const controller = new AnnouncementOpeningController({
        platform: Platform.OS,
        featureEnabled: () => state.features[APP_FEATURE_FLAGS.homeAnnouncements] === true,
        routeCurrent: () => routeCurrent.current,
        openingAnnouncement: runtime.announcements.getActiveAnnouncement(),
        shouldPresent: (item) => runtime.announcementPresentation.shouldPresent(item),
        prepareStory: (item) => sharedAnnouncementStoryCache.prepare(item),
        presentStory: (item, preparedUri) =>
          presentPreparedStory(item, preparedUri, () => routeCurrent.current),
        markDismissed: (item) => runtime.announcementPresentation.markDismissed(item),
      });
      void controller.tryPresent();
    }, 0);
    return () => clearTimeout(timer);
  }, [presentPreparedStory, runtime, state.features]);

  useEffect(
    () =>
      runtime.effects.bindRouteHandler(async (route) => {
        if (route === '/support-creator' || route === '/settings/support') {
          setHandoffUrl(supportCreatorUrl(locale));
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
        let scene: PushedScene | undefined;
        if (link.kind === 'page') {
          if (!isRouteEnabled(routeById(link.page), featureStateRef.current)) {
            if (active) setSnackbar(t('generalNoDataAvailable'));
            return;
          }
          if (link.page === 'ranked' && link.params.player)
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
          scene = { kind: 'player', player };
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
            const war = summary?.isInCwl ? summary.getActiveWarByTag(link.tag) : summary?.warInfo;
            if (!war?.clan) throw new Error('No current war available');
            scene = {
              kind: 'war',
              war: war.reorderForClan(link.tag),
              roundNumber: null,
              ...(summary?.isInCwl ? { cwl: { summary, clanTag: link.tag } } : {}),
            };
          }
        }
        if (!active || generation !== navigationGeneration.current) return;
        setLinkState({ key: generation, params: link.params });
        setUtility(undefined);
        setPushedScenes(scene ? [{ ...scene, linkParams: link.params, linkKey: generation }] : []);
        if (!scene && link.kind === 'page') {
          if (routeById(link.page).primaryTab) {
            setPrimary(link.page as PrimaryRouteId);
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
        if (Platform.OS === 'web' && typeof window !== 'undefined') {
          window.history.replaceState(window.history.state, '', appLinkPath(link));
        }
      },
      showLoading: (loading) => {
        if (active) setDeepLinkLoading(loading);
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
  }, [locale, runtime, t]);

  const renderUtilityContent = (
    route: AppRouteId,
    playerTag: string | undefined = utilityPlayerTag,
  ) => {
    if (route === 'settings') return <SettingsRoot onClose={closeSecondary} />;
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
          playerProfiles={runtime.players.profiles}
          onBack={async () => {
            const result = await refreshLinkedAccountsForCurrentAuth(
              runtime.auth,
              runtime.accounts,
            );
            if (!result.authenticated) throw new Error(t('authErrorUserNotAuthenticated'));
            if (!result.hasVerifiedAccount) throw new Error(t('homeVerifiedAccountRequiredBody'));
            closeSecondary();
            void runtime.accountBootstrap
              .initialize(user?.userId ?? null)
              .catch((error: unknown) => reportException(error, 'accountSetup.hydration'));
          }}
          onContinue={async () => {
            const result = await refreshLinkedAccountsForCurrentAuth(
              runtime.auth,
              runtime.accounts,
            );
            if (!result.authenticated) throw new Error(t('authErrorUserNotAuthenticated'));
            if (!result.hasVerifiedAccount) throw new Error(t('homeVerifiedAccountRequiredBody'));
            closeSecondary();
            void runtime.accountBootstrap
              .initialize(user?.userId ?? null)
              .catch((error: unknown) => reportException(error, 'accountSetup.hydration'));
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
    if (route === 'subscription') return <SubscriptionRoot onBack={closeSecondary} />;
    if (route === 'search')
      return (
        <SearchRoot
          autofocus
          overlay
          onCancel={closeSecondary}
          onOpenPlayer={pushPlayer}
          onOpenClan={pushClan}
        />
      );
    if (route === 'rankings')
      return <RankingsRoot onBack={closeSecondary} openPlayer={pushPlayer} openClan={pushClan} />;
    if (route === 'stats') return <StatsRoot onBack={closeSecondary} />;
    if (route === 'basesArmies') return <BasesArmiesRoot onBack={closeSecondary} />;
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
          openInGame={(tag) => setHandoffUrl(playerGameUrl(tag, locale))}
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
      return <UpgradeTrackerRoot initialTag={playerTag} onBack={closeSecondary} />;
    throw new Error(`Unsupported utility route: ${route}`);
  };

  const renderPushedScene = (scene: PushedScene) => {
    if (scene.kind === 'player')
      return (
        <PlayerDetailRoot
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
            openInGame: (tag) => setHandoffUrl(playerGameUrl(tag, locale)),
            copyTag: async (tag) => {
              await Clipboard.setStringAsync(tag);
            },
            openClan: loadClan,
            openWar: (war) => pushWar(war, null, playerCurrentCwl(scene.player)),
            openCwl: pushCwl,
            openPlayer: loadPlayer,
            openRanked: (player) => pushUtility('ranked', player.tag),
            openAchievements: () => pushUtility('achievements'),
            showMessage: setSnackbar,
          }}
        />
      );
    if (scene.kind === 'clan')
      return <ClanInfoRoot clan={scene.clan} goBack={closeSecondary} navigation={clanNavigation} />;
    if (scene.kind === 'capital')
      return <ClanCapitalRoot clan={scene.clan} goBack={closeSecondary} />;
    if (scene.kind === 'war')
      return (
        <WarInfoRoot
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
          summary={scene.summary}
          clanTag={scene.clanTag}
          warLeagueName={scene.warLeagueName}
          onBack={closeSecondary}
          onOpenWar={(war, roundNumber) => pushWar(war, roundNumber)}
          openClan={loadClan}
          openPlayer={loadPlayer}
        />
      );
    return renderUtilityContent(scene.route, scene.playerTag);
  };
  const secondaryLayers = [
    ...(utility
      ? [
          {
            key: `utility:${utility}:${utilityPlayerTag ?? ''}:${linkState.key}`,
            content: (
              <LinkParametersContext.Provider value={linkState.params} key={linkState.key}>
                {renderUtilityContent(utility)}
              </LinkParametersContext.Provider>
            ),
          },
        ]
      : []),
    ...pushedScenes.map((scene, index) => ({
      key: `pushed:${index}:${scene.kind}:${scene.linkKey ?? ''}`,
      content: (
        <LinkParametersContext.Provider
          value={scene.linkParams ?? EMPTY_LINK_PARAMS}
          key={scene.linkKey}
        >
          {renderPushedScene(scene)}
        </LinkParametersContext.Provider>
      ),
    })),
  ];
  const secondaryContent = secondaryLayers.at(-1)?.content;

  useEffect(() => {
    if (!usesNativeSecondaryNavigation) {
      removeNativeSecondaryLayers([...nativeRouteKeys.current, ...expectedNativeRouteKeys.current]);
      nativeRouteKeys.current = [];
      expectedNativeRouteKeys.current = [];
      return;
    }

    const expected = secondaryLayers.map((layer) => layer.key);
    expectedNativeRouteKeys.current = expected;
    secondaryLayers.forEach((layer) => {
      publishNativeSecondaryLayer(layer.key, {
        content: layer.content,
        onRemove: () => {
          if (!expectedNativeRouteKeys.current.includes(layer.key)) return;
          navigationGeneration.current += 1;
          nativeRouteKeys.current = nativeRouteKeys.current.filter((key) => key !== layer.key);
          if (layer.key.startsWith('utility:')) {
            setPushedScenes([]);
            setUtility(undefined);
            return;
          }
          const pushedIndex = Number(layer.key.split(':')[1]);
          if (Number.isInteger(pushedIndex)) {
            setPushedScenes((current) => current.slice(0, pushedIndex));
          }
        },
      });
    });

    const transition = nativeSecondaryRouteTransition(nativeRouteKeys.current, expected);
    transition.staleKeys.forEach(removeNativeSecondaryLayer);
    nativeRouteKeys.current = transition.routeKeys;
    if (transition.type === 'push') {
      const nextKey = transition.key;
      router.push({ pathname: '/detail' as never, params: { layer: nextKey } });
    } else if (transition.type === 'replace') {
      router.replace({ pathname: '/detail' as never, params: { layer: transition.key } });
    }
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
    <>
      <NavigationShell
        avatar={
          user?.avatarUrl ? (
            <MobileWebImage
              imageUrl={user.avatarUrl}
              style={styles.avatar}
              errorFallback={<UserRound color={theme.onSurfaceVariant} size={28} />}
            />
          ) : (
            <UserRound color={theme.onSurfaceVariant} size={28} />
          )
        }
        closeDrawerLabel={t('navigationCloseDrawer')}
        displayName={user?.username ?? 'ClashKing'}
        drawerHintStore={runtime.preferences}
        features={featureState}
        followerCount={authState.followerCount}
        hasUser={user !== null}
        isRtl={isRtl}
        onAccounts={() => openUtility(routeById('accounts'))}
        onAchievements={() => openUtility(routeById('achievements'))}
        onAddAccount={() => openUtility(routeById('accounts'))}
        onPrimarySelect={selectPrimary}
        onResetDesktopContent={closeSecondary}
        onSearch={() => openUtility(routeById('search'))}
        onUtilityNavigate={openUtility}
        primaryScreens={
          Object.fromEntries(
            Object.entries(screens).map(([key, screen]) => {
              const entry = primaryLinks[key as PrimaryRouteId];
              return [
                key,
                <LinkParametersContext.Provider
                  key={entry?.key ?? 0}
                  value={entry?.params ?? EMPTY_LINK_PARAMS}
                >
                  {screen}
                </LinkParametersContext.Provider>,
              ];
            }),
          ) as Record<PrimaryRouteId, React.ReactNode>
        }
        productLabel={t('navigationClashKingWeb')}
        profileMenuLabel={t('navigationOpenProfileMenu')}
        secondaryContent={usesNativeSecondaryNavigation ? undefined : secondaryContent}
        secondaryLayers={usesNativeSecondaryNavigation ? [] : secondaryLayers}
        secondaryFullScreen={
          (pushedScene?.kind === 'utility' ? pushedScene.route : utility) === 'search'
        }
        secondaryRouteId={secondaryRouteIdFor(pushedScene)}
        selectedPrimary={primary}
        selectedUtility={pushedScene ? undefined : utility}
        t={t}
      />
      {announcementPresentation}
      <Snackbar avoidBottomNavigation message={snackbar} onDismiss={() => setSnackbar(undefined)} />
      <SkeletonLoadingDialog visible={deepLinkLoading} />
      <ClashHandoffDialog
        visible={handoffUrl !== undefined}
        onCancel={() => setHandoffUrl(undefined)}
        onConfirm={() => {
          const url = handoffUrl;
          setHandoffUrl(undefined);
          if (url) void openExternal(url);
        }}
      />
    </>
  );
}

function secondaryRouteIdFor(scene: PushedScene | undefined): AppRouteId | undefined {
  if (scene?.kind === 'player') return 'players';
  if (scene?.kind === 'clan' || scene?.kind === 'capital') return 'clans';
  if (scene?.kind === 'war' || scene?.kind === 'cwl') return 'war';
  return scene?.kind === 'utility' ? scene.route : undefined;
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

function playerGameUrl(playerTag: string, locale: string): string {
  const language = locale.split('_', 1)[0]!.toLowerCase();
  const query = new URLSearchParams({ action: 'OpenPlayerProfile', tag: playerTag });
  return `https://link.clashofclans.com/${language}?${query.toString()}`;
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
  const { openURL } = await import('expo-linking');
  try {
    await openURL(url);
    return true;
  } catch {
    // Flutter treats the game handoff as best-effort navigation.
    return false;
  }
}

const styles = StyleSheet.create({
  avatar: { width: 36, height: 36, borderRadius: 18 },
  boundary: { flex: 1, padding: 16 },
});
