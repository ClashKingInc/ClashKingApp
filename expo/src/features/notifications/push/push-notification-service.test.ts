import {
  NotificationDeviceDeleteEndpoint,
  NotificationDeviceRegisterEndpoint,
} from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../../core/api/contract-api';
import { STORAGE_KEYS } from '../../../core/storage/storage';
import type { StringStore } from '../../../services/storage/auth-storage';
import type {
  PushData,
  PushMessage,
  PushNotificationServiceOptions,
  PushRuntime,
} from './contracts';
import {
  foregroundNotificationContent,
  isClashKingLocalNotification,
  mapPushAuthorizationStatus,
} from './expo-push-contract';
import {
  buildNotificationDeviceRegistrationPayload,
  apiAuthorizationStatus,
  canReceivePush,
  PushNotificationService,
  pushEnvironment,
  tokenPreview,
} from './push-notification-service';

type MockContractApi = ContractApiService & {
  readonly execute: jest.Mock;
  readonly executeStatus: jest.Mock;
};

function mockContractApi(
  implementation: () => Effect.Effect<unknown, unknown> = () =>
    Effect.succeed({
      device_id: 'device-1',
      provider: 'fcm',
      platform: 'ios',
      environment: 'sandbox',
      authorization_status: 'authorized',
      enabled: true,
      last_seen_at: '2026-09-11T00:00:00Z',
    }),
): MockContractApi {
  return {
    execute: jest.fn(implementation),
    executeStatus: jest.fn(),
  } as MockContractApi;
}

class MemoryStore implements StringStore {
  readonly values = new Map<string, string>();
  constructor(private readonly trace?: string[]) {}
  async getItem(key: string) {
    return this.values.get(key) ?? null;
  }
  async setItem(key: string, value: string) {
    this.trace?.push(`set:${key}`);
    this.values.set(key, value);
  }
  async removeItem(key: string) {
    this.trace?.push(`remove:${key}`);
    this.values.delete(key);
  }
}

function harness(overrides: Partial<PushNotificationServiceOptions> = {}) {
  const store = new MemoryStore();
  let foreground: ((message: PushMessage) => void) | undefined;
  let opened: ((message: PushMessage) => void) | undefined;
  let refreshed: ((token: string) => void) | undefined;
  let localResponse: ((data: PushData) => void) | undefined;
  const unsubscribes = [jest.fn(), jest.fn(), jest.fn(), jest.fn()];
  const runtime: jest.Mocked<PushRuntime> = {
    initializeLocalNotifications: jest.fn(async (listener) => {
      localResponse = listener;
      return unsubscribes[0];
    }),
    getAuthorizationStatus: jest.fn(async () => 'authorized'),
    requestAuthorization: jest.fn(async () => 'authorized'),
    getToken: jest.fn(async () => 'fcm-token'),
    deleteToken: jest.fn(async () => undefined),
    showLocalNotification: jest.fn(async (_message) => undefined),
    onForegroundMessage: jest.fn((listener) => {
      foreground = listener;
      return unsubscribes[1]!;
    }),
    onNotificationOpened: jest.fn((listener) => {
      opened = listener;
      return unsubscribes[2]!;
    }),
    onTokenRefresh: jest.fn((listener) => {
      refreshed = listener;
      return unsubscribes[3]!;
    }),
    getInitialMessage: jest.fn(async () => null),
    getInitialLocalResponse: jest.fn(async () => null),
  };
  const api = mockContractApi();
  const openRoute = jest.fn(async () => undefined);
  const openAdminPost = jest.fn(async () => undefined);
  const reportError = jest.fn(async () => undefined);
  const options: PushNotificationServiceOptions = {
    platform: 'ios',
    apiEnvironment: 'development',
    api,
    preferences: store,
    tokenService: { getDeviceId: jest.fn(async () => 'device-1') },
    runtime,
    appVersion: () => '0.3.5',
    locale: () => 'en-US',
    isFeatureEnabled: () => true,
    openRoute,
    openAdminPost,
    reportError,
    ...overrides,
  };
  return {
    service: new PushNotificationService(options),
    options,
    store,
    runtime,
    api,
    openRoute,
    openAdminPost,
    reportError,
    unsubscribes,
    foreground: () => foreground,
    opened: () => opened,
    refreshed: () => refreshed,
    localResponse: () => localResponse,
  };
}

async function flush(): Promise<void> {
  for (let index = 0; index < 10; index += 1) await Promise.resolve();
}

describe('push notification pure contracts', () => {
  test('builds the exact backend registration payload', () => {
    expect(
      buildNotificationDeviceRegistrationPayload({
        token: 'token',
        deviceId: 'device',
        platform: 'android',
        environment: 'sandbox',
        appVersion: '1.2.3',
        locale: 'fr-FR',
        authorizationStatus: 'provisional',
        enabled: false,
      }),
    ).toEqual({
      token: 'token',
      device_id: 'device',
      provider: 'fcm',
      platform: 'android',
      environment: 'sandbox',
      enabled: false,
      app_version: '1.2.3',
      locale: 'fr-FR',
      authorization_status: 'provisional',
    });
    expect(apiAuthorizationStatus('notDetermined')).toBe('not_determined');
    expect(apiAuthorizationStatus('ephemeral')).toBe('authorized');
  });

  test('maps environments and previews tokens exactly like Flutter', () => {
    expect(pushEnvironment('production')).toBe('production');
    expect(pushEnvironment('production', 'https://push.example')).toBe('sandbox');
    expect(pushEnvironment('local')).toBe('sandbox');
    expect(tokenPreview('1234567890123456')).toBe('1234567890123456');
    expect(tokenPreview('12345678middle87654321')).toBe('12345678…87654321');
    expect(tokenPreview(null)).toBeNull();
    expect(canReceivePush({ state: 'ready', token: 'token' })).toBe(true);
    expect(canReceivePush({ state: 'ready' })).toBe(false);
  });

  test('maps Expo permissions and foreground notification fallbacks deterministically', () => {
    expect(
      mapPushAuthorizationStatus({
        platform: 'ios',
        granted: false,
        permissionStatus: 'undetermined',
        iosStatus: 3,
      }),
    ).toBe('provisional');
    expect(
      mapPushAuthorizationStatus({
        platform: 'android',
        granted: false,
        permissionStatus: 'denied',
      }),
    ).toBe('denied');
    expect(foregroundNotificationContent({ data: { route: '/search' } })).toEqual({
      title: 'ClashKing',
      body: 'New ClashKing alert',
      data: { route: '/search' },
    });
    expect(isClashKingLocalNotification('clashking_foreground_123')).toBe(true);
    expect(isClashKingLocalNotification('google-fcm-id')).toBe(false);
  });
});

describe('PushNotificationService setup', () => {
  test('reports web as unsupported without touching native dependencies', async () => {
    const h = harness({ platform: 'web', runtime: undefined });
    await expect(h.service.initialize()).resolves.toEqual({ state: 'unsupported' });
    await expect(h.service.unregisterCurrentDeviceToken()).resolves.toBe(false);
    expect(h.api.execute).not.toHaveBeenCalled();
  });

  test.each([
    ['notDetermined', 'permissionRequired'],
    ['ephemeral', 'permissionRequired'],
    ['denied', 'permissionDenied'],
  ] as const)('maps %s permission to %s', async (status, state) => {
    const h = harness();
    h.runtime.getAuthorizationStatus.mockResolvedValue(status);
    await expect(h.service.initialize()).resolves.toEqual({
      state,
      authorizationStatus: status,
    });
    expect(h.runtime.getToken).not.toHaveBeenCalled();
  });

  test('initializes once, caches FCM, handles initial messages, and reaches ready', async () => {
    const h = harness();
    h.runtime.getInitialMessage.mockResolvedValue({ data: { route: '/search' } });
    const result = await h.service.initialize();
    await flush();
    expect(result).toEqual({
      state: 'ready',
      token: 'fcm-token',
    });
    expect(await h.store.getItem(STORAGE_KEYS.pushFcmToken)).toBe('fcm-token');
    expect(h.openRoute).toHaveBeenCalledWith('/search');
    await h.service.initialize();
    expect(h.runtime.onForegroundMessage).toHaveBeenCalledTimes(1);
    expect(h.runtime.initializeLocalNotifications).toHaveBeenCalledTimes(1);
  });

  test('returns tokenUnavailable and notConfigured at the same boundaries', async () => {
    const noToken = harness();
    noToken.runtime.getToken.mockResolvedValue(null);
    await expect(noToken.service.initialize()).resolves.toEqual({ state: 'tokenUnavailable' });

    const broken = harness();
    broken.runtime.initializeLocalNotifications.mockRejectedValue(new Error('missing Firebase'));
    const result = await broken.service.initialize();
    expect(result.state).toBe('notConfigured');
    expect(result.message).toContain('missing Firebase');
    expect(broken.reportError).toHaveBeenCalledWith(
      expect.objectContaining({ operation: 'initialize' }),
    );
  });

  test('requests permission, caches token, and registers even before settings are enabled', async () => {
    const h = harness();
    h.runtime.getAuthorizationStatus.mockResolvedValue('notDetermined');
    await h.service.initialize();
    h.runtime.requestAuthorization.mockResolvedValue('authorized');
    await expect(h.service.requestPermissionAndRegister()).resolves.toEqual({
      state: 'ready',
      authorizationStatus: 'authorized',
      token: 'fcm-token',
    });
    expect(h.api.execute).toHaveBeenCalledWith(
      NotificationDeviceRegisterEndpoint,
      expect.objectContaining({ body: expect.any(Object) }),
      undefined,
    );
    expect(await h.store.getItem(STORAGE_KEYS.notificationsEnabled)).toBe('true');
  });
});

describe('PushNotificationService registration lifecycle', () => {
  test('skips disabled registration and posts the exact authenticated payload when enabled', async () => {
    const h = harness();
    await h.service.registerCurrentDeviceToken({ token: 'new-token' });
    expect(h.api.execute).not.toHaveBeenCalled();

    await h.store.setItem(STORAGE_KEYS.notificationsEnabled, 'true');
    await h.service.registerCurrentDeviceToken({ token: 'new-token' });
    expect(h.api.execute).toHaveBeenCalledWith(
      NotificationDeviceRegisterEndpoint,
      expect.objectContaining({
        body: {
          token: 'new-token',
          device_id: 'device-1',
          provider: 'fcm',
          platform: 'ios',
          environment: 'sandbox',
          enabled: true,
          app_version: '0.3.5',
          locale: 'en-US',
          authorization_status: 'authorized',
        },
      }),
      undefined,
    );
    expect(await h.store.getItem(STORAGE_KEYS.pushLastRegistrationToken)).toBe('new-token');
  });

  test('uses an override URL and keeps registration failures non-fatal', async () => {
    const h = harness({ pushApiV2BaseUrlOverride: 'https://push.example/' });
    h.api.execute.mockReturnValue(Effect.fail(new Error('not deployed')));
    await expect(
      h.service.registerCurrentDeviceToken({ token: 'token', allowDisabled: true }),
    ).resolves.toBeUndefined();
    expect(h.api.execute).toHaveBeenCalledWith(
      NotificationDeviceRegisterEndpoint,
      expect.any(Object),
      { baseUrl: 'https://push.example' },
    );
    expect(h.reportError).toHaveBeenCalledWith(expect.objectContaining({ operation: 'register' }));
  });

  test('disables the current device with POST and preserves local state when the write fails', async () => {
    const h = harness();
    await h.store.setItem(STORAGE_KEYS.notificationsEnabled, 'true');
    await h.store.setItem(STORAGE_KEYS.pushFcmToken, 'token');
    h.api.execute.mockReturnValueOnce(
      Effect.succeed({
        device_id: 'device-1',
        provider: 'fcm',
        platform: 'ios',
        environment: 'sandbox',
        authorization_status: 'authorized',
        enabled: false,
        last_seen_at: '2026-09-11T00:00:00Z',
      }),
    );

    await expect(h.service.setCurrentDeviceEnabled(false)).resolves.toEqual({
      state: 'ready',
      token: 'token',
    });
    expect(h.api.execute).toHaveBeenCalledWith(
      NotificationDeviceRegisterEndpoint,
      expect.objectContaining({ body: expect.objectContaining({ token: 'token', enabled: false }) }),
      undefined,
    );
    expect(await h.store.getItem(STORAGE_KEYS.notificationsEnabled)).toBe('false');

    h.api.execute.mockReturnValue(Effect.fail(new Error('offline')));
    await h.store.setItem(STORAGE_KEYS.notificationsEnabled, 'true');
    await expect(h.service.setCurrentDeviceEnabled(false)).rejects.toThrow('offline');
    expect(await h.store.getItem(STORAGE_KEYS.notificationsEnabled)).toBe('true');
  });

  test('handles foreground messages and only persists refreshed tokens when enabled', async () => {
    const h = harness();
    await h.service.initialize();
    h.foreground()?.({ messageId: 'm1', data: { title: 'War' } });
    await flush();
    expect(h.runtime.showLocalNotification).toHaveBeenCalledWith({
      messageId: 'm1',
      data: { title: 'War' },
    });

    h.refreshed()?.('disabled-token');
    await flush();
    expect(await h.store.getItem(STORAGE_KEYS.pushFcmToken)).toBe('fcm-token');
    await h.store.setItem(STORAGE_KEYS.notificationsEnabled, 'true');
    h.refreshed()?.('refreshed-token');
    await flush();
    expect(await h.store.getItem(STORAGE_KEYS.pushFcmToken)).toBe('refreshed-token');
    expect(h.api.execute).toHaveBeenCalled();
  });

  test('attempts authenticated DELETE before clearing and always deletes FCM on failure', async () => {
    const trace: string[] = [];
    const store = new MemoryStore(trace);
    store.values.set(STORAGE_KEYS.pushFcmToken, 'token');
    store.values.set(STORAGE_KEYS.pushLastRegistrationToken, 'token');
    const h = harness({
      preferences: store,
      api: mockContractApi(() => {
        trace.push('delete-request');
        return Effect.fail(new Error('offline'));
      }),
    });
    h.runtime.deleteToken.mockImplementation(async () => {
      trace.push('delete-fcm');
    });
    await expect(h.service.unregisterCurrentDeviceToken()).resolves.toBe(false);
    expect(trace[0]).toBe('delete-request');
    expect(trace).toEqual([
      'delete-request',
      `remove:${STORAGE_KEYS.pushFcmToken}`,
      `remove:${STORAGE_KEYS.pushLastRegistrationToken}`,
      'delete-fcm',
    ]);
    expect(h.service.lastResult).toEqual({ state: 'tokenUnavailable' });
  });

  test('returns true only for 2xx DELETE but clears local and FCM state for every status', async () => {
    const h = harness();
    await expect(h.service.unregisterCurrentDeviceToken()).resolves.toBe(true);
    expect(h.runtime.deleteToken).toHaveBeenCalledTimes(1);
    expect(h.api.execute).toHaveBeenCalledWith(
      NotificationDeviceDeleteEndpoint,
      { path: {}, query: { device_id: 'device-1', environment: h.service.environment }, body: {} },
      undefined,
    );
  });
});

describe('PushNotificationService navigation and primer', () => {
  test('routes supported targets and gates posts, upgrade tracker, and admin posts', async () => {
    let postsEnabled = false;
    let upgradesEnabled = false;
    const h = harness({
      isFeatureEnabled: (feature) => (feature === 'posts' ? postsEnabled : upgradesEnabled),
    });
    await h.service.initialize();
    h.opened()?.({ data: { route: '/search' } });
    h.opened()?.({ data: { route: '/unknown' } });
    h.opened()?.({ data: { route: '/posts' } });
    h.localResponse()?.({ route: '/upgrade-tracker' });
    h.opened()?.({ data: { type: 'admin_post', post_id: 'post-1' } });
    await flush();
    expect(h.openRoute).toHaveBeenCalledTimes(1);
    expect(h.openRoute).toHaveBeenCalledWith('/search');
    expect(h.openAdminPost).not.toHaveBeenCalled();

    postsEnabled = true;
    upgradesEnabled = true;
    h.opened()?.({ data: { route: '/posts' } });
    h.localResponse()?.({ route: '/upgrade-tracker' });
    h.opened()?.({ data: { type: 'admin_post', post_id: 'post-1' } });
    await flush();
    expect(h.openRoute).toHaveBeenCalledWith('/posts');
    expect(h.openRoute).toHaveBeenCalledWith('/upgrade-tracker');
    expect(h.openAdminPost).toHaveBeenCalledWith('post-1');
  });

  test('shows the injected primer once and enables the registered device after acceptance', async () => {
    const showPermissionPrimer = jest.fn(async () => true);
    const h = harness({ showPermissionPrimer });
    await h.service.showPermissionPrimerOnce();
    await h.service.showPermissionPrimerOnce();
    expect(showPermissionPrimer).toHaveBeenCalledTimes(1);
    expect(await h.store.getItem(STORAGE_KEYS.notificationsEnabled)).toBe('true');
    expect(await h.store.getItem(STORAGE_KEYS.notificationPermissionPrimerShown)).toBe('true');
  });

  test('dispose releases all native listeners', async () => {
    const h = harness();
    await h.service.initialize();
    h.service.dispose();
    for (const unsubscribe of h.unsubscribes) {
      expect(unsubscribe).toHaveBeenCalledTimes(1);
    }
  });
});
