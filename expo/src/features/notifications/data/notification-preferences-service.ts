import {
  NotificationAccountPutEndpoint,
  NotificationClansGetEndpoint,
  NotificationClanPutEndpoint,
  type NotificationClansResponse,
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
export type ClanNotificationSettings = typeof NotificationClansResponse.Type;

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
  clans: ClanNotificationSettings | undefined;
  private readonly clanListeners = new Set<() => void>();
  private clanGeneration = 0;
  constructor(private readonly options: NotificationPreferencesServiceOptions) {}

  subscribeClans(listener: () => void): () => void {
    this.clanListeners.add(listener);
    return () => {
      this.clanListeners.delete(listener);
    };
  }

  clearClans(): void {
    ++this.clanGeneration;
    this.clans = undefined;
    this.clanListeners.forEach((listener) => listener());
  }

  async loadClans(): Promise<ClanNotificationSettings> {
    const generation = ++this.clanGeneration;
    const saved = await Effect.runPromise(
      this.options.api.execute(
        NotificationClansGetEndpoint,
        { path: {}, query: {}, body: {} },
        this.executeOptions(),
      ),
    );
    if (generation === this.clanGeneration) this.acceptClans(saved);
    return saved;
  }

  async setClanEnabled(tag: string, type: 'war' | 'raid', enabled: boolean): Promise<void> {
    const current = this.clans?.clans.find((clan) => clan.tag === tag);
    const generation = ++this.clanGeneration;
    const saved = await Effect.runPromise(
      this.options.api.execute(
        NotificationClanPutEndpoint,
        {
          path: { tag },
          query: {},
          body: {
            warEnabled: type === 'war' ? enabled : (current?.warEnabled ?? false),
            raidEnabled: type === 'raid' ? enabled : (current?.raidEnabled ?? false),
          },
        },
        this.executeOptions(),
      ),
    );
    if (generation === this.clanGeneration) this.acceptClans(saved);
  }

  async removeClanBookmark(tag: string): Promise<void> {
    const generation = ++this.clanGeneration;
    const saved = await Effect.runPromise(
      this.options.api.execute(
        NotificationClanPutEndpoint,
        {
          path: { tag },
          query: {},
          body: { warEnabled: false, raidEnabled: false, removeBookmark: true },
        },
        this.executeOptions(),
      ),
    );
    if (generation === this.clanGeneration) this.acceptClans(saved);
  }

  private acceptClans(saved: ClanNotificationSettings): void {
    this.clans = saved;
    this.clanListeners.forEach((listener) => listener());
  }

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
