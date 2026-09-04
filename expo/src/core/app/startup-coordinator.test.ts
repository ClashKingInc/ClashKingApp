import { createStore } from 'zustand/vanilla';
import { ApiResponseError, TransportError } from '@clashking/api-client';

import type { AuthService } from '../../features/auth/auth-service';
import type { CocAccountService } from '../../features/auth/account-service';
import type { AppStateSnapshot } from './app-state';
import {
  defaultIsMaintenanceError,
  defaultIsNetworkError,
  initializeApplication,
  initializeAuthenticatedPush,
} from './startup-coordinator';

test('classifies shared client failures without depending on an error message', () => {
  expect(
    defaultIsNetworkError(
      new TransportError({
        cause: new Error('offline'),
        message: 'ClashKing API transport failed',
      }),
    ),
  ).toBe(true);
  expect(defaultIsMaintenanceError(new ApiResponseError({ status: 503, body: {} }))).toBe(true);
  expect(defaultIsMaintenanceError(new ApiResponseError({ status: 403, body: {} }))).toBe(false);
});

function harness(
  options: {
    authenticated?: boolean;
    verified?: boolean;
    initializeError?: unknown;
    migrationError?: unknown;
    accountError?: unknown;
    pushToken?: string;
    requiredUpdate?: {
      minimumVersion: string;
      storeUrl: string;
      message: string;
    };
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
      featureFlags: {
        requiredUpdate: () => options.requiredUpdate ?? null,
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

  it('stops startup before account bootstrap when a native update is required', async () => {
    const update = {
      minimumVersion: '0.4.0',
      storeUrl: 'https://apps.apple.com/app/id123',
      message: 'A newer ClashKing build is required.',
    };
    const test = harness({ requiredUpdate: update });

    const result = await initializeApplication(test.dependencies);

    expect(result).toMatchObject({ destination: 'update', update });
    expect(test.calls).not.toContain('accounts');
    expect(test.calls).not.toContain('data');
    expect(test.calls).not.toContain('push');
  });

  it.each([new Error('failed to fetch'), new Error('HTTP 503')])(
    'prioritizes a loaded mandatory update over bootstrap failure %s',
    async (initializeError) => {
      const update = {
        minimumVersion: '0.4.0',
        storeUrl: 'https://apps.apple.com/app/id123',
        message: 'A newer ClashKing build is required.',
      };
      const test = harness({ requiredUpdate: update, initializeError });
      expect(await initializeApplication(test.dependencies)).toMatchObject({
        destination: 'update',
        update,
      });
      expect(test.calls).not.toContain('accounts');
      expect(test.calls).not.toContain('data');
      expect(test.calls).not.toContain('push');
    },
  );

  it('reports preference migration failures and continues startup like Flutter', async () => {
    const test = harness({ migrationError: new Error('legacy store unavailable') });

    const result = await initializeApplication(test.dependencies);

    expect(result.destination).toBe('home');
    expect(test.reportError).toHaveBeenCalledWith('startup.preferenceMigration', expect.any(Error));
    expect(test.calls).toEqual(expect.arrayContaining(['auth', 'game', 'state', 'data']));
  });

  it('waits for the update policy when authentication rejects before config resolves', async () => {
    const test = harness({ authenticated: false, initializeError: new Error('revoked') });
    const update = {
      minimumVersion: '0.4.0',
      storeUrl: 'https://apps.apple.com/app/id123',
      message: 'A newer ClashKing build is required.',
    };
    let releaseConfig!: () => void;
    const config = new Promise<void>((resolve) => {
      releaseConfig = resolve;
    });
    let loaded = false;
    test.dependencies.appState.setState({
      initialize: async () => {
        await config;
        loaded = true;
      },
    });
    test.dependencies.featureFlags.requiredUpdate = () => (loaded ? update : null);
    let settled = false;
    const startup = initializeApplication(test.dependencies).then((result) => {
      settled = true;
      return result;
    });
    // Drain promise continuations while config is deliberately still pending.
    for (let turn = 0; turn < 10; turn += 1) await Promise.resolve();
    const settledBeforeConfig = settled;
    releaseConfig();
    const result = await startup;
    expect(settledBeforeConfig).toBe(false);
    expect(result).toMatchObject({ destination: 'update', update });
    expect(test.calls).not.toContain('accounts');
    expect(test.calls).not.toContain('push');
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
