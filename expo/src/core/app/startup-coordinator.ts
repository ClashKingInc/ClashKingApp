import type { StoreApi } from 'zustand/vanilla';
import { ApiResponseError, TransportError } from '@clashking/api-client';

import type { AuthService } from '../../features/auth/auth-service';
import type { CocAccountService } from '../../features/auth/account-service';
import { initializeAccountsForCurrentAuth, type StartupResult } from '../../features/auth/startup';
import type { PushNotificationService } from '../../features/notifications/push';
import type { FlutterPreferenceMigration } from '../../services/storage/auth-storage';
import { APP_FEATURE_FLAGS } from '../feature-flags/feature-flags';
import type { RequiredAppUpdate } from '../feature-flags/feature-flags';
import type { RemoteFeatureFlagService } from '../feature-flags/remote-feature-flag-service';
import type { GameDataService } from '../game-data';
import type { AppStateSnapshot } from './app-state';

export type AppStartupResult =
  | (StartupResult & {
      readonly failure: null;
      readonly requestPushPermission: boolean;
    })
  | {
      readonly destination: 'update';
      readonly authenticated: boolean;
      readonly hasVerifiedAccount: false;
      readonly failure: null;
      readonly networkError: false;
      readonly requestPushPermission: false;
      readonly update: RequiredAppUpdate;
    }
  | {
      readonly destination: 'maintenance' | 'error';
      readonly authenticated: boolean;
      readonly hasVerifiedAccount: boolean;
      readonly failure: unknown;
      readonly networkError: boolean;
      readonly requestPushPermission: false;
    };

export interface StartupCoordinatorDependencies {
  readonly preferenceMigration: Pick<FlutterPreferenceMigration, 'run'>;
  readonly appState: StoreApi<AppStateSnapshot>;
  readonly auth: AuthService;
  readonly accounts: CocAccountService;
  readonly gameData: Pick<GameDataService, 'loadFreshGameData'>;
  readonly featureFlags: Pick<RemoteFeatureFlagService, 'requiredUpdate'>;
  readonly push: Pick<
    PushNotificationService,
    'supportsPushNotifications' | 'initialize' | 'registerCurrentDeviceToken'
  >;
  readonly initializeAuthenticatedData?: () => Promise<void>;
  readonly reportError?: (operation: string, error: unknown) => void;
  readonly isNetworkError?: (error: unknown) => boolean;
  readonly isMaintenanceError?: (error: unknown) => boolean;
}

export async function initializeApplication(
  dependencies: StartupCoordinatorDependencies,
): Promise<AppStartupResult> {
  try {
    await dependencies.preferenceMigration.run();
  } catch (error) {
    // Flutter's AppPreferences reports and suppresses migration failures so a
    // storage bridge problem cannot prevent login or an existing session.
    dependencies.reportError?.('startup.preferenceMigration', error);
  }
  let bootstrapFailure: unknown;
  try {
    // A rejected auth/game-data bootstrap must not outrun the minimum-version
    // policy loaded by app state and route an old binary into Login or Home.
    const bootstrap = await Promise.allSettled([
      dependencies.auth.initializeAuth(),
      dependencies.gameData.loadFreshGameData(),
      dependencies.appState.getState().initialize(),
    ]);
    const failed = bootstrap.find((result) => result.status === 'rejected');
    if (failed?.status === 'rejected') throw failed.reason;
  } catch (error) {
    bootstrapFailure = error;
  }

  const update = dependencies.featureFlags.requiredUpdate();
  if (update !== null) {
    return {
      destination: 'update',
      authenticated: dependencies.auth.canUseApp,
      hasVerifiedAccount: false,
      failure: null,
      networkError: false,
      requestPushPermission: false,
      update,
    };
  }

  // A known mandatory update wins over recoverable error screens, whose
  // logout action otherwise permits returning to Login on an outdated binary.
  if (bootstrapFailure !== undefined) {
    const isNetworkError = dependencies.isNetworkError ?? defaultIsNetworkError;
    const isMaintenanceError = dependencies.isMaintenanceError ?? defaultIsMaintenanceError;
    if (isNetworkError(bootstrapFailure) || isMaintenanceError(bootstrapFailure)) {
      dependencies.reportError?.('startup.bootstrap', bootstrapFailure);
      return failureResult(bootstrapFailure, dependencies.auth.canUseApp, {
        network: isNetworkError(bootstrapFailure),
        maintenance: isMaintenanceError(bootstrapFailure),
      });
    }
    // AuthService clears an expired/revoked session before rethrowing. Flutter
    // deliberately continues to Login instead of trapping the user on Error.
  }

  let accountResult: StartupResult;
  try {
    accountResult = await initializeAccountsForCurrentAuth(
      dependencies.auth,
      dependencies.accounts,
    );
    if (accountResult.authenticated) {
      await dependencies.initializeAuthenticatedData?.();
      await initializeAuthenticatedPush({
        notificationsEnabled: dependencies.appState
          .getState()
          .isFeatureEnabled(APP_FEATURE_FLAGS.notifications),
        push: dependencies.push,
      });
    }
  } catch (error) {
    dependencies.reportError?.('startup.bootstrap', error);
    const isNetworkError = dependencies.isNetworkError ?? defaultIsNetworkError;
    const isMaintenanceError = dependencies.isMaintenanceError ?? defaultIsMaintenanceError;
    return failureResult(error, dependencies.auth.canUseApp, {
      network: isNetworkError(error),
      maintenance: isMaintenanceError(error),
    });
  }

  const notificationsEnabled = dependencies.appState
    .getState()
    .isFeatureEnabled(APP_FEATURE_FLAGS.notifications);
  return {
    ...accountResult,
    failure: null,
    requestPushPermission:
      accountResult.authenticated &&
      notificationsEnabled &&
      dependencies.push.supportsPushNotifications,
  };
}

export async function initializeAuthenticatedPush({
  notificationsEnabled,
  push,
}: {
  notificationsEnabled: boolean;
  push: Pick<
    PushNotificationService,
    'supportsPushNotifications' | 'initialize' | 'registerCurrentDeviceToken'
  >;
}): Promise<boolean> {
  if (!push.supportsPushNotifications || !notificationsEnabled) return false;
  const result = await push.initialize();
  if (result.token !== undefined) {
    void push.registerCurrentDeviceToken({ token: result.token });
  }
  return true;
}

function failureResult(
  failure: unknown,
  authenticated: boolean,
  classification: { network: boolean; maintenance: boolean },
): AppStartupResult {
  return {
    destination: classification.maintenance ? 'maintenance' : 'error',
    authenticated,
    hasVerifiedAccount: false,
    failure,
    networkError: classification.network,
    requestPushPermission: false,
  };
}

export function defaultIsNetworkError(error: unknown): boolean {
  if (error instanceof TransportError) return true;
  const text = String(error).toLowerCase();
  return (
    text.includes('network') ||
    text.includes('connection') ||
    text.includes('hostname') ||
    text.includes('socket') ||
    text.includes('timeout') ||
    text.includes('no address') ||
    text.includes('xmlhttprequest') ||
    text.includes('failed to fetch')
  );
}

export function defaultIsMaintenanceError(error: unknown): boolean {
  if (error instanceof ApiResponseError) return error.status === 503 || error.status === 500;
  const text = String(error);
  return text.includes('503') || text.includes('500');
}
