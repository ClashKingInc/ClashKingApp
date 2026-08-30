import type { ApiEnvironment, ApiRequestOptions } from '../../../core/api/client';
import { STORAGE_KEYS } from '../../../core/storage/storage';
import type {
  PushAuthorizationStatus,
  PushData,
  PushMessage,
  PushNotificationServiceOptions,
  PushNotificationSetupResult,
  PushPlatform,
  PushUnsubscribe,
  SupportedPushRoute,
} from './contracts';

export const PUSH_DEVICE_ENDPOINT = '/notifications/devices';
const ALL_HTTP_STATUSES = Array.from({ length: 500 }, (_, index) => index + 100);
const SUPPORTED_ROUTES = new Set<SupportedPushRoute>([
  '/support-creator',
  '/settings/support',
  '/posts',
  '/search',
  '/upgrade-tracker',
]);

export interface NotificationDeviceRegistrationPayload {
  readonly token: string;
  readonly device_id: string;
  readonly provider: 'fcm';
  readonly platform: 'ios' | 'android';
  readonly environment: 'sandbox' | 'production';
  readonly app_version: string;
  readonly locale: string;
  readonly authorization_status: NotificationDeviceAuthorizationStatus;
}

export type NotificationDeviceAuthorizationStatus =
  'authorized' | 'provisional' | 'denied' | 'not_determined';

export function apiAuthorizationStatus(
  status: PushAuthorizationStatus,
): NotificationDeviceAuthorizationStatus {
  if (status === 'notDetermined') return 'not_determined';
  // The current API has no App Clip-specific ephemeral value. An ephemeral
  // grant can display notifications, so register it as authorized.
  if (status === 'ephemeral') return 'authorized';
  return status;
}

export function pushEnvironment(
  environment: ApiEnvironment,
  pushApiV2BaseUrlOverride?: string,
): 'sandbox' | 'production' {
  return pushApiV2BaseUrlOverride?.trim()
    ? 'sandbox'
    : environment === 'production'
      ? 'production'
      : 'sandbox';
}

export function buildNotificationDeviceRegistrationPayload(input: {
  token: string;
  deviceId: string;
  platform: 'ios' | 'android';
  environment: 'sandbox' | 'production';
  appVersion: string;
  locale: string;
  authorizationStatus: PushAuthorizationStatus;
}): NotificationDeviceRegistrationPayload {
  return {
    token: input.token,
    device_id: input.deviceId,
    provider: 'fcm',
    platform: input.platform,
    environment: input.environment,
    app_version: input.appVersion,
    locale: input.locale,
    authorization_status: apiAuthorizationStatus(input.authorizationStatus),
  };
}

export function canReceivePush(result: PushNotificationSetupResult): boolean {
  return result.state === 'ready' && result.token !== undefined;
}

export function tokenPreview(token: string | null): string | null {
  if (token === null || token.length <= 16) return token;
  return `${token.slice(0, 8)}…${token.slice(-8)}`;
}

function hasDisplayPermission(status: PushAuthorizationStatus): boolean {
  return status === 'authorized' || status === 'provisional';
}

function permissionState(status: PushAuthorizationStatus) {
  return status === 'denied' ? 'permissionDenied' : 'permissionRequired';
}

function supportsPush(platform: PushPlatform): platform is 'ios' | 'android' {
  return platform === 'ios' || platform === 'android';
}

export class PushNotificationService {
  private initializing = false;
  private initialized = false;
  private localNotificationsReady = false;
  private subscriptions: PushUnsubscribe[] = [];
  private streamsBound = false;
  private lastSetupResult: PushNotificationSetupResult = {
    state: 'notConfigured',
  };

  constructor(private readonly options: PushNotificationServiceOptions) {}

  get lastResult(): PushNotificationSetupResult {
    return this.lastSetupResult;
  }

  get supportsPushNotifications(): boolean {
    return supportsPush(this.options.platform);
  }

  get environment(): 'sandbox' | 'production' {
    return pushEnvironment(this.options.apiEnvironment, this.options.pushApiV2BaseUrlOverride);
  }

  async initialize(register = false): Promise<PushNotificationSetupResult> {
    if (!this.supportsPushNotifications || this.options.runtime === undefined) {
      return this.setResult({
        state: this.supportsPushNotifications ? 'notConfigured' : 'unsupported',
      });
    }
    if (this.initializing) return this.lastSetupResult;

    this.initializing = true;
    this.setResult({ state: 'initializing' });
    try {
      if (!this.localNotificationsReady) {
        const unsubscribe = await this.options.runtime.initializeLocalNotifications((data) =>
          this.handleDataNavigation(data),
        );
        if (unsubscribe !== undefined) this.subscriptions.push(unsubscribe);
        this.localNotificationsReady = true;
      }
      this.bindMessageStreams();
      this.initialized = true;

      const authorizationStatus = await this.options.runtime.getAuthorizationStatus();
      if (!hasDisplayPermission(authorizationStatus)) {
        return this.setResult({
          state: permissionState(authorizationStatus),
          authorizationStatus,
        });
      }

      const token = await this.options.runtime.getToken();
      if (!token) {
        return this.setResult({ state: 'tokenUnavailable' });
      }

      await this.cacheToken(token);
      if (register) void this.registerCurrentDeviceToken({ token });
      return this.setResult({ state: 'ready', token });
    } catch (error) {
      await this.report('initialize', error);
      return this.setResult({ state: 'notConfigured', message: String(error) });
    } finally {
      this.initializing = false;
    }
  }

  async requestPermissionAndRegister(): Promise<PushNotificationSetupResult> {
    const initialized = this.initialized ? this.lastSetupResult : await this.initialize(false);
    if (initialized.state === 'notConfigured' || initialized.state === 'unsupported') {
      return initialized;
    }
    const runtime = this.options.runtime;
    if (runtime === undefined) return initialized;

    try {
      const authorizationStatus = await runtime.requestAuthorization();
      if (!hasDisplayPermission(authorizationStatus)) {
        return this.setResult({
          state: permissionState(authorizationStatus),
          authorizationStatus,
        });
      }
      const token = await runtime.getToken();
      if (!token) {
        return this.setResult({
          state: 'tokenUnavailable',
          authorizationStatus,
        });
      }
      await this.cacheToken(token);
      await this.registerCurrentDeviceToken({ token, allowDisabled: true });
      return this.setResult({ state: 'ready', authorizationStatus, token });
    } catch (error) {
      await this.report('permission', error);
      return this.setResult({ state: 'notConfigured', message: String(error) });
    }
  }

  async showPermissionPrimerOnce(onPermissionAccepted?: () => void | Promise<void>): Promise<void> {
    if (!this.supportsPushNotifications) return;
    const prompted = await this.options.preferences.getItem(
      STORAGE_KEYS.notificationPermissionPrimerShown,
    );
    if (prompted === 'true' || this.options.showPermissionPrimer === undefined) {
      return;
    }

    const shouldEnable = await this.options.showPermissionPrimer();
    await this.options.preferences.setItem(STORAGE_KEYS.notificationPermissionPrimerShown, 'true');
    if (!shouldEnable) return;

    const result = await this.requestPermissionAndRegister();
    if (canReceivePush(result) && onPermissionAccepted !== undefined) {
      try {
        await onPermissionAccepted();
      } catch (error) {
        await this.report('primer-callback', error);
      }
    }
  }

  async registerCurrentDeviceToken(
    options: {
      token?: string;
      allowDisabled?: boolean;
    } = {},
  ): Promise<void> {
    if (!supportsPush(this.options.platform) || this.options.runtime === undefined) {
      return;
    }
    if (!options.allowDisabled && !(await this.areNotificationsEnabled())) {
      this.options.log?.('Push registration skipped: notifications disabled.');
      return;
    }
    const token = options.token ?? (await this.cachedToken());
    if (!token) {
      this.options.log?.('Push registration skipped: no FCM token.');
      return;
    }

    try {
      const payload = buildNotificationDeviceRegistrationPayload({
        token,
        deviceId: await this.options.tokenService.getDeviceId(),
        platform: this.options.platform,
        environment: this.environment,
        appVersion: this.options.appVersion(),
        locale: this.options.locale(),
        authorizationStatus: await this.options.runtime.getAuthorizationStatus(),
      });
      const response = await this.request('POST', payload);
      if (response.status >= 200 && response.status < 300) {
        await this.options.preferences.setItem(STORAGE_KEYS.pushLastRegistrationToken, token);
        this.options.log?.('Push device token registered.');
      } else {
        this.options.log?.(`Push token registration failed: ${response.status}`);
      }
    } catch (error) {
      // Registration remains non-fatal while the API endpoint is unavailable.
      await this.report('register', error);
    }
  }

  async unregisterCurrentDeviceToken(): Promise<boolean> {
    if (!supportsPush(this.options.platform) || this.options.runtime === undefined) {
      return false;
    }

    let unregistered = false;
    try {
      const query = new URLSearchParams({
        device_id: await this.options.tokenService.getDeviceId(),
      });
      const response = await this.request(
        'DELETE',
        undefined,
        `${PUSH_DEVICE_ENDPOINT}?${query.toString()}`,
      );
      unregistered = response.status >= 200 && response.status < 300;
    } catch (error) {
      await this.report('unregister', error);
    } finally {
      await this.clearCurrentDeviceToken();
    }
    return unregistered;
  }

  cachedToken(): Promise<string | null> {
    return this.options.preferences.getItem(STORAGE_KEYS.pushFcmToken);
  }

  async areNotificationsEnabled(): Promise<boolean> {
    return (await this.options.preferences.getItem(STORAGE_KEYS.notificationsEnabled)) === 'true';
  }

  async tokenPreview(): Promise<string | null> {
    return tokenPreview(await this.cachedToken());
  }

  async showForegroundMessage(message: PushMessage): Promise<void> {
    if (!this.localNotificationsReady || this.options.runtime === undefined) return;
    await this.options.runtime.showLocalNotification(message);
  }

  dispose(): void {
    for (const unsubscribe of this.subscriptions.splice(0)) unsubscribe();
    this.streamsBound = false;
    this.localNotificationsReady = false;
    this.initialized = false;
  }

  private bindMessageStreams(): void {
    if (this.streamsBound || this.options.runtime === undefined) return;
    const runtime = this.options.runtime;
    this.streamsBound = true;
    this.subscriptions.push(
      runtime.onForegroundMessage((message) => {
        this.options.log?.(`Push foreground message: ${message.messageId ?? ''}`);
        void this.showForegroundMessage(message).catch((error) =>
          this.report('foreground-message', error),
        );
      }),
      runtime.onNotificationOpened((message) => this.handleDataNavigation(message.data ?? {})),
      runtime.onTokenRefresh((token) => {
        void this.handleTokenRefresh(token).catch((error) => this.report('register', error));
      }),
    );
    void runtime
      .getInitialMessage()
      .then((message) => {
        if (message !== null) this.handleDataNavigation(message.data ?? {});
      })
      .catch((error) => this.report('navigation', error));
    void runtime
      .getInitialLocalResponse()
      .then((data) => {
        if (data !== null) this.handleDataNavigation(data);
      })
      .catch((error) => this.report('navigation', error));
  }

  private async handleTokenRefresh(token: string): Promise<void> {
    if (!(await this.areNotificationsEnabled())) {
      this.options.log?.('Push token refresh ignored: notifications disabled.');
      return;
    }
    await this.cacheToken(token);
    await this.registerCurrentDeviceToken({ token });
  }

  private handleDataNavigation(data: PushData): void {
    if (String(data.type ?? '') === 'admin_post') {
      if (!this.options.isFeatureEnabled('posts')) return;
      const postId = String(data.post_id ?? '');
      if (postId) {
        void Promise.resolve(this.options.openAdminPost(postId)).catch((error) =>
          this.report('navigation', error),
        );
        return;
      }
    }

    const route = String(data.route ?? '');
    if (!SUPPORTED_ROUTES.has(route as SupportedPushRoute)) return;
    const supportedRoute = route as SupportedPushRoute;
    if (
      (supportedRoute === '/posts' && !this.options.isFeatureEnabled('posts')) ||
      (supportedRoute === '/upgrade-tracker' && !this.options.isFeatureEnabled('upgradeTracker'))
    ) {
      return;
    }
    void Promise.resolve(this.options.openRoute(supportedRoute)).catch((error) =>
      this.report('navigation', error),
    );
  }

  private async clearCurrentDeviceToken(): Promise<void> {
    const cleanupErrors: unknown[] = [];
    const removals = await Promise.allSettled([
      this.options.preferences.removeItem(STORAGE_KEYS.pushFcmToken),
      this.options.preferences.removeItem(STORAGE_KEYS.pushLastRegistrationToken),
    ]);
    for (const removal of removals) {
      if (removal.status === 'rejected') cleanupErrors.push(removal.reason);
    }
    this.setResult({ state: 'tokenUnavailable' });
    try {
      await this.options.runtime?.deleteToken();
    } catch (error) {
      cleanupErrors.push(error);
    }
    for (const error of cleanupErrors) await this.report('cleanup', error);
  }

  private cacheToken(token: string): Promise<void> {
    return this.options.preferences.setItem(STORAGE_KEYS.pushFcmToken, token);
  }

  private request(method: 'POST' | 'DELETE', body?: unknown, endpoint = PUSH_DEVICE_ENDPOINT) {
    const override = this.options.pushApiV2BaseUrlOverride?.replace(/\/$/, '');
    const requestOptions: ApiRequestOptions = {
      method,
      ...(body === undefined ? undefined : { body }),
      requiresAuth: true,
      acceptedStatuses: ALL_HTTP_STATUSES,
      ...(override ? { url: `${override}${endpoint}` } : undefined),
    };
    return this.options.api.request(endpoint, requestOptions);
  }

  private setResult(result: PushNotificationSetupResult) {
    this.lastSetupResult = result;
    return result;
  }

  private async report(
    operation: Parameters<NonNullable<typeof this.options.reportError>>[0]['operation'],
    error: unknown,
  ): Promise<void> {
    try {
      await this.options.reportError?.({ operation, error });
    } catch {
      // Reporting must never change notification or logout behavior.
    }
  }
}
