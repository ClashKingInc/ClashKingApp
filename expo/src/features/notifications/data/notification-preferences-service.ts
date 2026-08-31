import { type ApiClient, type ApiResponse } from '../../../core/api/client';
import {
  createDefaultNotificationPreferences,
  parseLocalNotificationPreferences,
  parseNotificationAccount,
  parseNotificationPreferences,
  serializeNotificationPreferencesForLocalStorage,
  serializeNotificationPreferencesForPut,
  type NotificationAccount,
  type NotificationPreferences,
} from '../../../core/dto/notification-preferences';
import { LEGACY_NOTIFICATION_PREFERENCE_KEYS, STORAGE_KEYS } from '../../../core/storage/storage';
import type { StringStore } from '../../../services/storage/auth-storage';

const ALL_HTTP_STATUSES = Array.from({ length: 500 }, (_, index) => index + 100);

export const NOTIFICATION_PREFERENCES_ENDPOINT = '/notifications/preferences';

export class NotificationPreferencesHttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'NotificationPreferencesHttpError';
  }
}

export interface NotificationPreferencesServiceOptions {
  readonly api: ApiClient;
  readonly deviceIdProvider: () => Promise<string>;
  readonly environmentProvider: () => string;
  readonly preferences: StringStore;
  readonly pushApiV2BaseUrlOverride?: string;
}

export class NotificationPreferencesService {
  constructor(private readonly options: NotificationPreferencesServiceOptions) {}

  async load(): Promise<NotificationPreferences> {
    const [deviceId, environment] = await Promise.all([
      this.options.deviceIdProvider(),
      Promise.resolve(this.options.environmentProvider()),
    ]);
    const query = new URLSearchParams({ device_id: deviceId, environment });
    const response = await this.rawRequest(
      `${NOTIFICATION_PREFERENCES_ENDPOINT}?${query.toString()}`,
      'GET',
    );
    this.expectSuccess(response, 'load notification preferences');
    const settings = parseNotificationPreferences(parseResponseJson(response));
    await this.persistBestEffort(settings);
    return settings;
  }

  async save(settings: NotificationPreferences): Promise<NotificationPreferences> {
    const [deviceId, environment] = await Promise.all([
      this.options.deviceIdProvider(),
      Promise.resolve(this.options.environmentProvider()),
    ]);
    const response = await this.rawRequest(
      NOTIFICATION_PREFERENCES_ENDPOINT,
      'PUT',
      serializeNotificationPreferencesForPut(settings, deviceId, environment),
    );
    this.expectSuccess(response, 'save notification preferences');
    const saved = parseNotificationPreferences(parseResponseJson(response));
    await this.persistBestEffort(saved);
    return saved;
  }

  async setDeviceEnabled(enabled: boolean): Promise<NotificationPreferences> {
    const current = await this.load();
    return this.save({ ...current, notificationsEnabled: enabled });
  }

  async setAccountEnabled(playerTag: string, enabled: boolean): Promise<NotificationAccount> {
    const endpoint = `/notifications/accounts/${encodeURIComponent(playerTag)}`;
    const response = await this.rawRequest(endpoint, 'PUT', { enabled });
    this.expectSuccess(response, 'update account notifications');
    return parseNotificationAccount(parseResponseJson(response));
  }

  async loadLocal(): Promise<NotificationPreferences> {
    const raw = await this.options.preferences.getItem(STORAGE_KEYS.notificationSettings);
    if (raw === null) {
      return createDefaultNotificationPreferences(
        await this.options.deviceIdProvider(),
        this.options.environmentProvider(),
      );
    }
    return parseLocalNotificationPreferences(JSON.parse(raw) as unknown);
  }

  private async persist(settings: NotificationPreferences): Promise<void> {
    await this.options.preferences.setItem(
      STORAGE_KEYS.notificationSettings,
      JSON.stringify(serializeNotificationPreferencesForLocalStorage(settings)),
    );
    await this.options.preferences.setItem(
      STORAGE_KEYS.notificationsEnabled,
      String(settings.notificationsEnabled),
    );
    await Promise.all(
      LEGACY_NOTIFICATION_PREFERENCE_KEYS.map((key) => this.options.preferences.removeItem(key)),
    );
  }

  private async persistBestEffort(settings: NotificationPreferences): Promise<void> {
    try {
      await this.persist(settings);
    } catch {
      // The API is authoritative; a cache failure cannot roll back the server write.
    }
  }

  private rawRequest(
    endpoint: string,
    method: 'GET' | 'PUT',
    body?: unknown,
  ): Promise<ApiResponse> {
    const override = this.options.pushApiV2BaseUrlOverride?.replace(/\/$/, '');
    return this.options.api.request(endpoint, {
      method,
      body,
      requiresAuth: true,
      acceptedStatuses: ALL_HTTP_STATUSES,
      ...(override ? { url: `${override}${endpoint}` } : undefined),
    });
  }

  private expectSuccess(response: ApiResponse, operation: string): void {
    if (response.status < 200 || response.status >= 300) {
      throw new NotificationPreferencesHttpError(
        response.status,
        `Failed to ${operation} (${response.status})`,
      );
    }
  }
}

function parseResponseJson(response: ApiResponse): unknown {
  try {
    return JSON.parse(response.bodyText) as unknown;
  } catch (error) {
    throw new TypeError('Invalid notification preferences response', { cause: error });
  }
}
