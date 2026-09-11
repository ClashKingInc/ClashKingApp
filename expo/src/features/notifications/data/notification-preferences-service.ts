import {
  NotificationAccountPutEndpoint,
  NotificationPreferencesGetEndpoint,
  NotificationPreferencesPutEndpoint,
} from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../../core/api/contract-api';
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
  readonly api: ContractApiService;
  readonly preferences: StringStore;
  readonly pushApiV2BaseUrlOverride?: string;
}

export class NotificationPreferencesService {
  constructor(private readonly options: NotificationPreferencesServiceOptions) {}

  async load(): Promise<NotificationPreferences> {
    const response = await Effect.runPromise(
      this.options.api.execute(
        NotificationPreferencesGetEndpoint,
        { path: {}, query: {}, body: {} },
        this.executeOptions(),
      ),
    );
    const settings = parseNotificationPreferences(response);
    await this.persistBestEffort(settings);
    return settings;
  }

  async save(settings: NotificationPreferences): Promise<NotificationPreferences> {
    const response = await Effect.runPromise(
      this.options.api.execute(
        NotificationPreferencesPutEndpoint,
        { path: {}, query: {}, body: serializeNotificationPreferencesForPut(settings) },
        this.executeOptions(),
      ),
    );
    const saved = parseNotificationPreferences(response);
    await this.persistBestEffort(saved);
    return saved;
  }

  async setAccountEnabled(tag: string, enabled: boolean): Promise<NotificationAccount> {
    const response = await Effect.runPromise(
      this.options.api.execute(
        NotificationAccountPutEndpoint,
        { path: { tag }, query: {}, body: { enabled } },
        this.executeOptions(),
      ),
    );
    return parseNotificationAccount(response);
  }

  async loadLocal(): Promise<NotificationPreferences> {
    const raw = await this.options.preferences.getItem(STORAGE_KEYS.notificationSettings);
    if (raw === null) return createDefaultNotificationPreferences();
    return parseLocalNotificationPreferences(JSON.parse(raw) as unknown);
  }

  private async persist(settings: NotificationPreferences): Promise<void> {
    await this.options.preferences.setItem(
      STORAGE_KEYS.notificationSettings,
      JSON.stringify(serializeNotificationPreferencesForLocalStorage(settings)),
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

  private executeOptions() {
    const override = this.options.pushApiV2BaseUrlOverride?.replace(/\/$/, '');
    return override ? { baseUrl: override.replace(/\/v2\/?$/, '') } : undefined;
  }
}
