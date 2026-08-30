import * as Application from 'expo-application';
import Constants from 'expo-constants';
import * as Crypto from 'expo-crypto';
import { Platform } from 'react-native';
import ClashKingNative from '@clashking/native';

import { ApiClient } from '../api/client';
import { BookmarkService } from '../bookmarks';
import { resolveApiConfiguration } from '../config/api-config';
import { APP_FEATURE_FLAGS } from '../feature-flags/feature-flags';
import { RemoteFeatureFlagService } from '../feature-flags/remote-feature-flag-service';
import { createExpoGameDataService } from '../game-data';
import {
  addHttpBreadcrumb,
  clearUser,
  reportException,
  setAuthenticatedUser,
} from '../observability/observability';
import { createTranslator, systemLocale } from '../../i18n';
import { CocAccountService } from '../../features/auth/account-service';
import { AccountBootstrapService } from '../../features/auth/account-bootstrap-service';
import { AuthService } from '../../features/auth/auth-service';
import { AchievementsRepository } from '../../features/achievements/data';
import { ClanService } from '../../features/clan/data';
import { AnnouncementPresentationService, AnnouncementService } from '../../features/home/data';
import { NotificationPreferencesService } from '../../features/notifications/data/notification-preferences-service';
import {
  createNotificationSettingsDebugAdapter,
  NotificationDebugService,
  type NotificationSettingsDebugAdapter,
} from '../../features/notifications/debug/notification-debug-service';
import { PushNotificationService, type PushFeature } from '../../features/notifications/push';
import { PlayerCardPreferencesService, PlayerService } from '../../features/player/data';
import { RankingsProvider } from '../../features/rankings/data/rankings-provider';
import { RankingsService } from '../../features/rankings/data/rankings-service';
import { SubscriptionService } from '../../features/subscription/subscription-service';
import { UpgradeTrackerRepository } from '../../features/upgrade-tracker/data/upgrade-tracker-repository';
import { UpgradeWidgetSyncService } from '../../features/upgrade-tracker/data/upgrade-widget-sync-service';
import { AppIconService } from '../../features/settings/app-icons/app-icon-service';
import {
  configureWarWidgetBackgroundExecutor,
  configureWarWidgetBackgroundRuntimeInitializer,
  ExpoWidgetBackgroundScheduler,
} from '../../features/widgets/expo-background-runtime';
import { WarWidgetService } from '../../features/widgets';
import { fetchWarWidgetSummary } from '../../features/widgets/war-widget-api';
import { WarCwlService } from '../../features/war/data';
import { ExpoDeviceIdentity } from '../../services/auth/device-identity';
import { DiscordOAuthClient } from '../../services/auth/discord-oauth';
import { PlatformDiscordOAuthRuntime } from '../../services/auth/discord-runtime';
import { NativeAuthRefreshLock, NoopAuthRefreshLock } from '../../services/auth/refresh-lock';
import { TokenService } from '../../services/auth/token-service';
import {
  AuthSessionRepository,
  FlutterPreferenceMigration,
} from '../../services/storage/auth-storage';
import {
  ClashKingLegacyFlutterBridge,
  currentRuntimePlatform,
  ExpoPreferenceStore,
  ExpoSharedAuthSecureStore,
} from '../../services/storage/expo-auth-storage';
import { createAppStateStore } from './app-state';
import { createPlatformPushRuntime } from './platform-push';
import { RuntimeEffects } from './runtime-effects';

export interface AppRuntime {
  readonly configuration: ReturnType<typeof resolveApiConfiguration>;
  readonly preferences: ExpoPreferenceStore;
  readonly preferenceMigration: FlutterPreferenceMigration;
  readonly api: ApiClient;
  readonly tokens: TokenService;
  readonly auth: AuthService;
  readonly accounts: CocAccountService;
  readonly accountBootstrap: AccountBootstrapService;
  readonly achievements: AchievementsRepository;
  readonly bookmarks: BookmarkService;
  readonly players: PlayerService;
  readonly playerCardPreferences: PlayerCardPreferencesService;
  readonly rankings: RankingsService;
  readonly announcements: AnnouncementService;
  readonly announcementPresentation: AnnouncementPresentationService;
  createRankingsProvider(): RankingsProvider;
  readonly upgrades: UpgradeTrackerRepository;
  readonly subscription: SubscriptionService;
  readonly upgradeWidgets: UpgradeWidgetSyncService;
  readonly clans: ClanService;
  readonly wars: WarCwlService;
  readonly gameData: ReturnType<typeof createExpoGameDataService>;
  readonly featureFlags: RemoteFeatureFlagService;
  readonly appState: ReturnType<typeof createAppStateStore>;
  readonly push: PushNotificationService;
  readonly notificationPreferences: NotificationPreferencesService;
  readonly notificationSettingsDebug: NotificationSettingsDebugAdapter | null;
  readonly appIcons: AppIconService;
  readonly warWidgets: WarWidgetService;
  readonly effects: RuntimeEffects;
  readonly discordSignInEnabled: boolean;
}

let singleton: AppRuntime | null = null;

export function getAppRuntime(): AppRuntime {
  singleton ??= createAppRuntime();
  return singleton;
}

configureWarWidgetBackgroundRuntimeInitializer(() => getAppRuntime());

export function createAppRuntime(): AppRuntime {
  const runtimePlatform = currentRuntimePlatform();
  const nativePlatform = runtimePlatform === 'web' ? 'web' : 'native';
  const preferences = new ExpoPreferenceStore();
  const secureStore = new ExpoSharedAuthSecureStore();
  const legacyBridge = runtimePlatform === 'web' ? undefined : new ClashKingLegacyFlutterBridge();
  const identity = new ExpoDeviceIdentity(secureStore, legacyBridge);
  const configuration = resolveApiConfiguration({
    CK_API_ENV: process.env.EXPO_PUBLIC_CK_API_ENV,
    CK_API_BASE_URL: process.env.EXPO_PUBLIC_CK_API_BASE_URL,
    CK_API_V2_BASE_URL: process.env.EXPO_PUBLIC_CK_API_V2_BASE_URL,
    CK_PROXY_BASE_URL: process.env.EXPO_PUBLIC_CK_PROXY_BASE_URL,
  });
  const sessions = new AuthSessionRepository(
    secureStore,
    preferences,
    runtimePlatform,
    () => identity.getDeviceId(),
    legacyBridge,
  );
  const refreshLock =
    runtimePlatform === 'web'
      ? new NoopAuthRefreshLock()
      : new NativeAuthRefreshLock(runtimePlatform);
  const tokens = new TokenService({
    apiV2Url: configuration.apiV2Url,
    platform: runtimePlatform,
    sessions,
    refreshLock,
    deviceIdentity: identity,
  });
  const api = new ApiClient({
    baseUrl: configuration.apiV2Url,
    proxyUrl: configuration.proxyUrl,
    environment: configuration.environment,
    tokenProvider: tokens,
    platform: nativePlatform,
    observability: { addHttpBreadcrumb, reportException },
  });
  const gameData = createExpoGameDataService();
  const featureFlags = new RemoteFeatureFlagService({
    api,
    preferences,
    platform: runtimePlatform,
    appVersionProvider: async () => appVersion(),
    installationSeedProvider: installationSeed,
  });
  const appState = createAppStateStore({
    preferences,
    gameData,
    featureFlags,
    systemLocale,
  });
  const effects = new RuntimeEffects();
  const push = new PushNotificationService({
    platform: runtimePlatform,
    apiEnvironment: configuration.environment,
    api,
    preferences,
    tokenService: tokens,
    runtime: createPlatformPushRuntime(),
    pushApiV2BaseUrlOverride: process.env.EXPO_PUBLIC_CK_PUSH_API_V2_BASE_URL,
    appVersion,
    locale: () => appState.getState().locale,
    isFeatureEnabled: (feature) => isPushFeatureEnabled(appState, feature),
    openRoute: (route) => effects.openRoute(route),
    openAdminPost: (postId) => effects.openRoute(`/posts/${encodeURIComponent(postId)}`),
    showPermissionPrimer: () => effects.showPermissionPrimer(),
    reportError: ({ operation, error }) => reportException(error, operation),
  });
  const accounts = new CocAccountService(api, preferences, (operation, error) =>
    reportException(error, operation),
  );
  const achievements = new AchievementsRepository(api);
  const bookmarks = new BookmarkService(api);
  const players = new PlayerService(api, preferences, configuration.apiV2Url, (operation, error) =>
    reportException(error, operation),
  );
  const playerCardPreferences = new PlayerCardPreferencesService(preferences);
  const rankings = new RankingsService(api);
  const announcements = new AnnouncementService(
    api,
    runtimePlatform,
    () => appState.getState().locale,
  );
  const announcementPresentation = new AnnouncementPresentationService(preferences);
  const upgrades = new UpgradeTrackerRepository(api, preferences);
  const subscription = new SubscriptionService(api);
  const upgradeWidgets = new UpgradeWidgetSyncService({
    platform: runtimePlatform,
    native: ClashKingNative,
    mirror: preferences,
    translate: (key, values) => createTranslator(appState.getState().locale)(key, values),
  });
  const clans = new ClanService(api);
  const wars = new WarCwlService(api);
  const discordOAuth = new DiscordOAuthClient({
    platform: nativePlatform,
    runtime: new PlatformDiscordOAuthRuntime(),
    webOrigin: webOrigin(),
    webHost: webHost(),
    webRedirectOverride: process.env.EXPO_PUBLIC_CK_WEB_DISCORD_REDIRECT_URI,
  });
  const auth = new AuthService({
    api,
    tokens,
    preferences,
    environment: configuration.environment,
    platform: nativePlatform,
    discordOAuth,
    observability: { setAuthenticatedUser, clearUser },
    unregisterPushDevice: async () => {
      await push.unregisterCurrentDeviceToken();
    },
    clearAccountData: () => {
      effects.clearPendingRoutes();
      accounts.clearAccountData();
      achievements.bindSession(null);
      playerCardPreferences.clear();
      players.clearRankedLeagueCache();
      upgrades.clearCache();
      void upgradeWidgets.clear();
    },
  });
  const notificationPreferences = new NotificationPreferencesService({
    api,
    deviceIdProvider: () => tokens.getDeviceId(),
    environmentProvider: () => push.environment,
    preferences,
    pushApiV2BaseUrlOverride: process.env.EXPO_PUBLIC_CK_PUSH_API_V2_BASE_URL,
  });
  const notificationSettingsDebug = createNotificationSettingsDebugAdapter(
    new NotificationDebugService(runtimePlatform, ClashKingNative),
    __DEV__,
  );
  const appIcons = new AppIconService(runtimePlatform, ClashKingNative);
  const warWidgets = new WarWidgetService({
    platform: runtimePlatform,
    native: ClashKingNative,
    mirror: preferences,
    preferences,
    featureFlags,
    backgroundScheduler:
      runtimePlatform === 'android' ? new ExpoWidgetBackgroundScheduler() : undefined,
    proxyUrl: configuration.proxyUrl,
    apiV2Url: configuration.apiV2Url,
    loadWarSummary: (clanTag) => fetchWarWidgetSummary(api, clanTag),
    getFirstAvailableAccount: async () => {
      const current = accounts.accounts[0]?.playerTag;
      if (current !== undefined) return current;
      const userId = auth.state.currentUser?.userId;
      if (!userId) return null;
      accounts.setCurrentUserId(userId);
      const loaded = await accounts.fetchAccounts();
      return loaded[0]?.playerTag ?? null;
    },
    loadPlayerClanTag: async (playerTag) => {
      const player = await players.getPlayerAndClanData(playerTag);
      return player.clanOverview.tag || null;
    },
    reportError: ({ operation, error }) => reportException(error, operation),
  });
  configureWarWidgetBackgroundExecutor((taskName) => warWidgets.executeBackgroundTask(taskName));
  const accountBootstrap = new AccountBootstrapService({
    accounts,
    bookmarks,
    players,
    playerCardPreferences,
    upgrades,
    upgradeWidgets,
    clans,
    wars,
    storage: preferences,
    warWidgets,
    reportError: (operation, error) => reportException(error, operation),
  });
  accounts.setBootstrapCoordinator((userId) => accountBootstrap.initialize(userId));

  return {
    configuration,
    preferences,
    preferenceMigration: new FlutterPreferenceMigration(preferences, legacyBridge, secureStore),
    api,
    tokens,
    auth,
    accounts,
    accountBootstrap,
    achievements,
    bookmarks,
    players,
    playerCardPreferences,
    rankings,
    announcements,
    announcementPresentation,
    createRankingsProvider: () => new RankingsProvider(rankings),
    upgrades,
    subscription,
    upgradeWidgets,
    clans,
    wars,
    gameData,
    featureFlags,
    appState,
    push,
    notificationPreferences,
    notificationSettingsDebug,
    appIcons,
    warWidgets,
    effects,
    discordSignInEnabled: envBoolean(process.env.EXPO_PUBLIC_CK_DISCORD_SIGN_IN_ENABLED, true),
  };
}

function appVersion(): string {
  return Application.nativeApplicationVersion ?? Constants.expoConfig?.version ?? '0.3.5';
}

async function installationSeed(): Promise<number> {
  const range = 0x7fffffff;
  const unbiasedLimit = Math.floor(0x1_0000_0000 / range) * range;
  while (true) {
    const bytes = await Crypto.getRandomBytesAsync(4);
    const value =
      ((bytes[0] ?? 0) * 0x1000000 +
        (bytes[1] ?? 0) * 0x10000 +
        (bytes[2] ?? 0) * 0x100 +
        (bytes[3] ?? 0)) >>>
      0;
    if (value < unbiasedLimit) return value % range;
  }
}

function isPushFeatureEnabled(appState: AppRuntime['appState'], feature: PushFeature): boolean {
  const key = feature === 'posts' ? APP_FEATURE_FLAGS.posts : APP_FEATURE_FLAGS.upgradeTracker;
  return appState.getState().isFeatureEnabled(key);
}

function webOrigin(): string | undefined {
  return Platform.OS === 'web' ? globalThis.location?.origin : undefined;
}

function webHost(): string | undefined {
  return Platform.OS === 'web' ? globalThis.location?.hostname : undefined;
}

function envBoolean(value: string | undefined, fallback: boolean): boolean {
  if (value === undefined || value.length === 0) return fallback;
  return value.toLowerCase() === 'true';
}
