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
  expect(
    defaultIsMaintenanceError(
      new ApiResponseError({ status: 503, body: { reason: 'maintenance' } }),
    ),
  ).toBe(true);
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
    pushState?: 'permissionRequired' | 'permissionDenied';
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
            : options.pushState === 'permissionDenied'
              ? ({ state: 'permissionDenied' } as const)
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
    let finishRegistration!: () => void;
    const registration = new Promise<void>((resolve) => {
      finishRegistration = resolve;
    });
    const registerCurrentDeviceToken = jest.fn(() => registration);

    let settled = false;
    const startup = initializeAuthenticatedPush({
      notificationsEnabled: true,
      push: {
        supportsPushNotifications: true,
        initialize,
        registerCurrentDeviceToken,
      },
    }).then((result) => {
      settled = true;
      return result;
    });
    await Promise.resolve();

    expect(initialize).toHaveBeenCalledTimes(1);
    expect(registerCurrentDeviceToken).toHaveBeenCalledWith({ token: 'fcm-token' });
    expect(settled).toBe(false);
    finishRegistration();
    await expect(startup).resolves.toBe(true);
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

  it('keeps a valid authenticated startup when optional push initialization fails', async () => {
    const test = harness();
    test.dependencies.push.initialize = async () => {
      throw new Error('push unavailable');
    };
    await expect(initializeApplication(test.dependencies)).resolves.toMatchObject({
      destination: 'home',
      authenticated: true,
    });
    expect(test.reportError).toHaveBeenCalledWith('startup.push', expect.any(Error));
  });

  it('keeps a valid authenticated startup when push permission is denied', async () => {
    const test = harness({ pushState: 'permissionDenied' });

    await expect(initializeApplication(test.dependencies)).resolves.toMatchObject({
      destination: 'home',
      authenticated: true,
      requestPushPermission: true,
    });
    expect(test.calls).not.toContain('register');
    expect(test.reportError).not.toHaveBeenCalledWith('startup.push', expect.anything());
  });

  it('bounds stalled push setup', async () => {
    await expect(
      initializeAuthenticatedPush({
        notificationsEnabled: true,
        timeoutMs: 1,
        push: {
          supportsPushNotifications: true,
          initialize: () => new Promise(() => undefined),
          registerCurrentDeviceToken: async () => undefined,
        },
      }),
    ).rejects.toThrow('timed out');
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

  it('allows login after a revoked session without waiting for remote config', async () => {
    const test = harness({ authenticated: false, initializeError: new Error('revoked') });
    let releaseConfig!: () => void;
    const config = new Promise<void>((resolve) => {
      releaseConfig = resolve;
    });
    test.dependencies.appState.setState({
      initialize: async () => {
        await config;
      },
    });
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
    expect(settledBeforeConfig).toBe(true);
    expect(result).toMatchObject({ destination: 'login' });
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
    const maintenanceTest = harness({
      initializeError: new ApiResponseError({ status: 503, body: { reason: 'maintenance' } }),
    });
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

test.each([500, 503])(
  'keeps backend HTTP %s failures out of the game maintenance screen',
  async (status) => {
    const error = new ApiResponseError({ status, body: { code: 'upstream_unavailable' } });
    expect(defaultIsMaintenanceError(error)).toBe(false);
    const result = await initializeApplication(harness({ initializeError: error }).dependencies);
    expect(result.destination).toBe('error');
  },
);
test('does not treat a number in an error message as game maintenance', () => {
  expect(defaultIsMaintenanceError(new Error('request 500123 failed'))).toBe(false);
});
