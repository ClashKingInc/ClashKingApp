import * as Clipboard from 'expo-clipboard';
import { useCallback, useEffect, useRef, useState, useSyncExternalStore } from 'react';
import { Platform, StyleSheet, View } from 'react-native';
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
import { NavigationShell, type PrimaryRouteId } from '../../shell';
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
import {
  DeepLinkHandler,
  ExpoDeepLinkRuntime,
  startDeepLinkHandling,
  type DeepLinkFeedback,
} from '../deep-links';
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
import { supportCreatorUrl } from './runtime-effects';

type PushedScene =
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
    };

/** Production shell composition for the retained four-tab Flutter navigation model. */
export function AuthenticatedRoot() {
  const runtime = useAppRuntime();
  const state = useAppState();
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
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
  const [pushedScenes, setPushedScenes] = useState<readonly PushedScene[]>([]);
  const [snackbar, setSnackbar] = useState<string>();
  const [handoffUrl, setHandoffUrl] = useState<string>();
  const [deepLinkLoading, setDeepLinkLoading] = useState(false);
  const routeCurrent = useRef(true);
  const navigationGeneration = useRef(0);
  const {
    openHomeAnnouncement: presentHomeAnnouncement,
    openPreparedStory: presentPreparedStory,
    presentation: announcementPresentation,
  } = useAnnouncementPresentation();
  const user = authState.currentUser;
  const featureState: FeatureState = { ...state.features };
  const pushedScene = pushedScenes.at(-1);
  const selectPrimary = (route: PrimaryRouteId) => {
    navigationGeneration.current += 1;
    setPushedScenes([]);
    setUtility(undefined);
    setPrimary(route);
  };
  const showUtility = useCallback((route: AppRouteDefinition, playerTag?: string) => {
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
    navigationGeneration.current += 1;
    setPushedScenes([]);
    setUtilityPostId(postId);
    setUtility('posts');
  };
  const closeSecondary = useCallback(() => {
    navigationGeneration.current += 1;
    if (pushedScenes.length) setPushedScenes((current) => current.slice(0, -1));
    else setUtility(undefined);
  }, [pushedScenes.length]);

  useEffect(() => {
    const subscription = subscribeSecondaryBackHandler(
      pushedScenes.length > 0 || utility !== undefined,
      closeSecondary,
    );
    return () => subscription?.remove();
  }, [closeSecondary, pushedScenes.length, utility]);
  const pushPlayer = (player: Player) => {
    navigationGeneration.current += 1;
    setPushedScenes((current) => [...current, { kind: 'player', player }]);
  };
  const pushClan = (clan: Clan) => {
    navigationGeneration.current += 1;
    setPushedScenes((current) => [...current, { kind: 'clan', clan }]);
  };
  const pushCapital = (clan: Clan) => {
    navigationGeneration.current += 1;
    setPushedScenes((current) => [...current, { kind: 'capital', clan }]);
  };
  const pushCwl = (cwl: PlayerCurrentCwl) => {
    navigationGeneration.current += 1;
    setPushedScenes((current) => [...current, { kind: 'cwl', ...cwl }]);
  };
  const pushWar = (war: WarInfo, roundNumber: number | null = null, cwl?: PlayerCurrentCwl) => {
    navigationGeneration.current += 1;
    setPushedScenes((current) => [
      ...current,
      { kind: 'war', war, roundNumber, ...(cwl ? { cwl } : {}) },
    ]);
  };
  const pushUtility = (route: AppRouteId, playerTag?: string) => {
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
      showLoading: (loading) => {
        if (active) setDeepLinkLoading(loading);
      },
      showFeedback: (feedback) => {
        if (active) setSnackbar(deepLinkFeedbackMessage(feedback, t));
      },
      reportError: (operation, error) => reportException(error, operation),
    });
    void startDeepLinkHandling(new ExpoDeepLinkRuntime(), handler, (operation, error) =>
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
            await runtime.accountBootstrap.initialize(user?.userId ?? null);
            if (runtime.accounts.hasVerifiedAccounts) closeSecondary();
          }}
          onContinue={async () => {
            await runtime.accountBootstrap.initialize(user?.userId ?? null);
            if (runtime.accounts.hasVerifiedAccounts) closeSecondary();
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
          verified.has(canonicalTag(player.tag)) &&
          runtime.playerCardPreferences.isRankedShownOnHome(player.tag),
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
            key: `utility:${utility}:${utilityPlayerTag ?? ''}`,
            content: renderUtilityContent(utility),
          },
        ]
      : []),
    ...pushedScenes.map((scene, index) => ({
      key: `pushed:${index}:${scene.kind}`,
      content: renderPushedScene(scene),
    })),
  ];
  const secondaryContent = secondaryLayers.at(-1)?.content;

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
        features={featureState}
        followerCount={authState.followerCount}
        hasUser={user !== null}
        isRtl={isRtl}
        onAccounts={() => openUtility(routeById('accounts'))}
        onAchievements={() => openUtility(routeById('achievements'))}
        onAddAccount={() => openUtility(routeById('accounts'))}
        onPrimarySelect={selectPrimary}
        onResetDesktopContent={closeSecondary}
        onSecondaryBack={closeSecondary}
        onSearch={() => openUtility(routeById('search'))}
        onUtilityNavigate={openUtility}
        primaryScreens={screens}
        productLabel={t('navigationClashKingWeb')}
        profileMenuLabel={t('navigationOpenProfileMenu')}
        secondaryContent={secondaryContent}
        secondaryLayers={secondaryLayers}
        secondaryFullScreen={
          (pushedScene?.kind === 'utility' ? pushedScene.route : utility) === 'search'
        }
        secondaryRouteId={
          pushedScene?.kind === 'player'
            ? 'players'
            : pushedScene?.kind === 'clan' || pushedScene?.kind === 'capital'
              ? 'clans'
              : pushedScene?.kind === 'war' || pushedScene?.kind === 'cwl'
                ? 'war'
                : pushedScene?.kind === 'utility'
                  ? pushedScene.route
                  : undefined
        }
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
