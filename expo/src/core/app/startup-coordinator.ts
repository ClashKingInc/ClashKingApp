import { classifyClashResponse } from '@clashking/clash-contract/outcomes';
import type { StoreApi } from 'zustand/vanilla';
import { ApiResponseError, TransportError } from '@clashking/api-client';

import type { AuthService } from '../../features/auth/auth-service';
import type { CocAccountService } from '../../features/auth/account-service';
import { initializeAccountsForCurrentAuth, type StartupResult } from '../../features/auth/startup';
import type { PushNotificationService } from '../../features/notifications/push';
import type { FlutterPreferenceMigration } from '../../services/storage/auth-storage';
import { UnauthorizedException } from '../api/contract-api';
import { APP_FEATURE_FLAGS } from '../feature-flags/feature-flags';
import type { GameDataService } from '../game-data';
import type { AppStateSnapshot } from './app-state';

export type AppStartupResult =
  | (StartupResult & {
      readonly failure: null;
      readonly requestPushPermission: boolean;
    })
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
  readonly gameData: Pick<GameDataService, 'loadGameData'>;
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
  let accountResult: StartupResult;
  try {
    const gameData = dependencies.gameData.loadGameData().catch((error) => {
      dependencies.reportError?.('startup.gameData', error);
    });
    const accounts = dependencies.auth
      .initializeAuth()
      .catch((error: unknown) => {
        // A failed profile request only permits Login after a definitive rejection.
        if (
          !(error instanceof UnauthorizedException) &&
          !(error instanceof ApiResponseError && error.status === 401)
        ) {
          throw error;
        }
      })
      .then(() => initializeAccountsForCurrentAuth(dependencies.auth, dependencies.accounts));
    const appState = dependencies.appState.getState();
    const appStateReady = appState.initialize();
    void appStateReady.catch((error) => dependencies.reportError?.('startup.appState', error));
    [accountResult] = await Promise.all([accounts, appState.initializePreferences()]);
    if (accountResult.authenticated) {
      // Home uses remote flags and static game data. Sign-in only needs local preferences.
      await Promise.all([gameData, appStateReady]);
      void dependencies
        .initializeAuthenticatedData?.()
        .catch((error) => dependencies.reportError?.('startup.authenticatedData', error));
      void initializeAuthenticatedPush({
        notificationsEnabled: dependencies.appState
          .getState()
          .isFeatureEnabled(APP_FEATURE_FLAGS.notifications),
        push: dependencies.push,
      }).catch((error) => dependencies.reportError?.('startup.push', error));
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
  timeoutMs = 10_000,
}: {
  notificationsEnabled: boolean;
  push: Pick<
    PushNotificationService,
    'supportsPushNotifications' | 'initialize' | 'registerCurrentDeviceToken'
  >;
  timeoutMs?: number;
}): Promise<boolean> {
  if (!push.supportsPushNotifications || !notificationsEnabled) return false;
  return withTimeout(
    (async () => {
      const result = await push.initialize();
      if (result.token !== undefined) {
        await push.registerCurrentDeviceToken({ token: result.token });
      }
      return true;
    })(),
    timeoutMs,
  );
}

function withTimeout<T>(operation: Promise<T>, timeoutMs: number): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Push initialization timed out')), timeoutMs);
    void operation.then(
      (value) => {
        clearTimeout(timer);
        resolve(value);
      },
      (error) => {
        clearTimeout(timer);
        reject(error);
      },
    );
  });
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
  if (!(error instanceof ApiResponseError) || error.status !== 503) return false;
  const body = error.body;
  if (!body || typeof body !== 'object') return false;
  // HTTP 500/503 also cover our backend and database failures, not just game maintenance.
  return classifyClashResponse({ path: '/', status: error.status, body }).kind === 'maintenance';
}
