import { createStore } from 'zustand/vanilla';

import type { AuthService } from '../../features/auth/auth-service';
import type { CocAccountService } from '../../features/auth/account-service';
import type { AppStateSnapshot } from './app-state';
import { initializeApplication, initializeAuthenticatedPush } from './startup-coordinator';

function harness(
  options: {
    authenticated?: boolean;
    verified?: boolean;
    initializeError?: unknown;
    migrationError?: unknown;
    accountError?: unknown;
    pushToken?: string;
  } = {},
) {
  const calls: string[] = [];
  const reportError = jest.fn();
  const authenticated = options.authenticated ?? true;
  const auth = {
    canUseApp: authenticated,
    state: {
      currentUser: authenticated ? { userId: 'user-1' } : null,
    },
    initializeAuth: async () => {
      calls.push('auth');
      if (options.initializeError !== undefined) throw options.initializeError;
    },
  } as unknown as AuthService;
  const accounts = {
    hasVerifiedAccounts: options.verified ?? true,
    initializeForCurrentUser: async () => {
      calls.push('user');
      calls.push('selected');
      calls.push('accounts');
      if (options.accountError !== undefined) throw options.accountError;
      calls.push('selection');
    },
    setCurrentUserId: () => calls.push('user'),
    loadSelectedTag: async () => {
      calls.push('selected');
    },
    fetchAccounts: async () => {
      calls.push('accounts');
      if (options.accountError !== undefined) throw options.accountError;
      return [];
    },
    initializeSelectedTag: async () => {
      calls.push('selection');
      return null;
    },
  } as unknown as CocAccountService;
  const appState = createStore<AppStateSnapshot>(() => ({
    locale: 'en',
    themePreference: 'system',
    features: {
      notifications: true,
      posts: true,
      home_announcements: true,
      leaderboards: true,
      global_stats: true,
      calculators: true,
      subscription_support: true,
      upgrade_tracker: true,
      bases_armies: false,
      game_assets: true,
      war_widgets: true,
    },
    initialized: true,
    initialize: async () => {
      calls.push('state');
    },
    changeLanguage: async () => undefined,
    setThemePreference: async () => undefined,
    toggleTheme: async () => undefined,
    isFeatureEnabled: () => true,
  }));
  return {
    calls,
    dependencies: {
      preferenceMigration: {
        run: async () => {
          calls.push('migration');
          if (options.migrationError !== undefined) throw options.migrationError;
          return { migratedKeys: [], legacyValuesRetained: true };
        },
      },
      appState,
      auth,
      accounts,
      gameData: {
        loadFreshGameData: async () => {
          calls.push('game');
        },
      },
      push: {
        supportsPushNotifications: true,
        initialize: async () => {
          calls.push('push');
          return options.pushToken
            ? ({ state: 'ready', token: options.pushToken } as const)
            : ({ state: 'permissionRequired' } as const);
        },
        registerCurrentDeviceToken: async () => {
          calls.push('register');
        },
      },
      initializeAuthenticatedData: async () => {
        calls.push('data');
      },
      reportError,
    },
    reportError,
  };
}

describe('startup coordinator parity', () => {
  it('initializes and registers push on an authenticated path', async () => {
    const initialize = jest.fn(async () => ({ state: 'ready', token: 'fcm-token' }) as const);
    const registerCurrentDeviceToken = jest.fn(async () => undefined);

    await expect(
      initializeAuthenticatedPush({
        notificationsEnabled: true,
        push: {
          supportsPushNotifications: true,
          initialize,
          registerCurrentDeviceToken,
        },
      }),
    ).resolves.toBe(true);
    await Promise.resolve();

    expect(initialize).toHaveBeenCalledTimes(1);
    expect(registerCurrentDeviceToken).toHaveBeenCalledWith({ token: 'fcm-token' });
  });

  it('migrates first, boots authenticated data, and requires a verified account for Home', async () => {
    const test = harness({ pushToken: 'fcm-token' });
    const result = await initializeApplication(test.dependencies);
    await Promise.resolve();

    expect(test.calls[0]).toBe('migration');
    expect(result).toMatchObject({
      destination: 'home',
      authenticated: true,
      hasVerifiedAccount: true,
      requestPushPermission: true,
    });
    expect(test.calls).toEqual(
      expect.arrayContaining(['auth', 'game', 'state', 'data', 'push', 'register']),
    );
  });

  it('routes an authenticated user without a verified account to account setup', async () => {
    const result = await initializeApplication(harness({ verified: false }).dependencies);
    expect(result.destination).toBe('account-setup');
  });

  it('reports preference migration failures and continues startup like Flutter', async () => {
    const test = harness({ migrationError: new Error('legacy store unavailable') });

    const result = await initializeApplication(test.dependencies);

    expect(result.destination).toBe('home');
    expect(test.reportError).toHaveBeenCalledWith('startup.preferenceMigration', expect.any(Error));
    expect(test.calls).toEqual(expect.arrayContaining(['auth', 'game', 'state', 'data']));
  });

  it('falls through revoked-session errors to Login like Flutter', async () => {
    const test = harness({ authenticated: false, initializeError: new Error('revoked') });
    const result = await initializeApplication(test.dependencies);
    expect(result.destination).toBe('login');
    expect(test.reportError).not.toHaveBeenCalled();
  });

  it('separates maintenance and network initialization failures', async () => {
    const maintenanceTest = harness({ initializeError: new Error('HTTP 503') });
    const maintenance = await initializeApplication(maintenanceTest.dependencies);
    expect(maintenance).toMatchObject({ destination: 'maintenance' });
    expect(maintenanceTest.reportError).toHaveBeenCalledWith(
      'startup.bootstrap',
      expect.any(Error),
    );

    const networkTest = harness({ accountError: new Error('failed to fetch') });
    const network = await initializeApplication(networkTest.dependencies);
    expect(network).toMatchObject({ destination: 'error', networkError: true });
    expect(networkTest.reportError).toHaveBeenCalledWith('startup.bootstrap', expect.any(Error));
  });
});
