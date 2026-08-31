import { ApiClient } from '../../../core/api/client';
import { parseNotificationPreferences } from '../../../core/dto/notification-preferences';
import { STORAGE_KEYS } from '../../../core/storage/storage';
import type { StringStore } from '../../../services/storage/auth-storage';
import {
  NOTIFICATION_PREFERENCES_ENDPOINT,
  NotificationPreferencesService,
} from './notification-preferences-service';

const responseBody = {
  deviceId: 'device-1',
  environment: 'sandbox',
  notificationsEnabled: true,
  legendAttacksEnabled: true,
  legendDefensesEnabled: false,
  warAttacksEnabled: false,
  warStateEnabled: true,
  warRemindersEnabled: true,
  raidRemindersEnabled: true,
  eventsEnabled: true,
  announcementsEnabled: false,
  monthlySupportEnabled: false,
  reminderTimings: [15, 30, 60],
  raidReminderTimings: [60, 180],
  accounts: [{ playerTag: '#VERIFIED', source: 'verified', active: true }],
};

class MemoryStore implements StringStore {
  readonly values = new Map<string, string>();
  failWrites = false;

  async getItem(key: string) {
    return this.values.get(key) ?? null;
  }

  async setItem(key: string, value: string) {
    if (this.failWrites) throw new Error('cache unavailable');
    this.values.set(key, value);
  }

  async removeItem(key: string) {
    this.values.delete(key);
  }
}

function serviceWith(
  fetchImplementation: typeof fetch,
  preferences = new MemoryStore(),
  pushApiV2BaseUrlOverride?: string,
): NotificationPreferencesService {
  return new NotificationPreferencesService({
    api: new ApiClient({
      baseUrl: 'https://push.example/v2',
      environment: 'production',
      platform: 'native',
      tokenProvider: { getAccessToken: async () => 'token' },
      fetchImplementation,
    }),
    deviceIdProvider: async () => 'device-1',
    environmentProvider: () => 'sandbox',
    preferences,
    pushApiV2BaseUrlOverride,
  });
}

describe('NotificationPreferencesService', () => {
  it('uses the configured push API base for preference requests', async () => {
    const requested: string[] = [];
    const service = serviceWith(
      async (input) => {
        requested.push(String(input));
        return new Response(JSON.stringify(responseBody));
      },
      new MemoryStore(),
      'https://override.example/v2/',
    );

    await service.load();

    expect(requested).toEqual([
      'https://override.example/v2/notifications/preferences?device_id=device-1&environment=sandbox',
    ]);
  });

  it('GET parses the exact camelCase response and persists V2 state', async () => {
    const requested: string[] = [];
    const preferences = new MemoryStore();
    const service = serviceWith(async (input) => {
      requested.push(String(input));
      return new Response(JSON.stringify(responseBody));
    }, preferences);

    const settings = await service.load();

    expect(requested).toEqual([
      'https://push.example/v2/notifications/preferences?device_id=device-1&environment=sandbox',
    ]);
    expect(settings.reminderTimings).toEqual([15, 30, 60]);
    expect(settings.accounts.map((account) => account.source)).toEqual(['verified']);
    expect(preferences.values.get(STORAGE_KEYS.notificationsEnabled)).toBe('true');
  });

  it('PUT sends categories without rewriting account selection', async () => {
    let body: unknown;
    const service = serviceWith(async (_input, init) => {
      body = JSON.parse(String(init?.body)) as unknown;
      return new Response(JSON.stringify(responseBody));
    });

    await service.save(parseNotificationPreferences(responseBody));

    expect(body).toEqual({
      deviceId: 'device-1',
      environment: 'sandbox',
      notificationsEnabled: true,
      legendAttacksEnabled: true,
      legendDefensesEnabled: false,
      warAttacksEnabled: false,
      warStateEnabled: true,
      warRemindersEnabled: true,
      raidRemindersEnabled: true,
      eventsEnabled: true,
      announcementsEnabled: false,
      monthlySupportEnabled: false,
      reminderTimings: [15, 30, 60],
      raidReminderTimings: [60, 180],
    });
  });

  it('keeps a successful API write successful when local caching fails', async () => {
    const preferences = new MemoryStore();
    preferences.failWrites = true;
    const service = serviceWith(
      async () => new Response(JSON.stringify(responseBody)),
      preferences,
    );

    await expect(service.save(parseNotificationPreferences(responseBody))).resolves.toMatchObject({
      notificationsEnabled: true,
    });
  });

  it('uses the dedicated encoded per-player endpoint', async () => {
    let request = '';
    let body = '';
    const service = serviceWith(async (input, init) => {
      request = String(input);
      body = String(init?.body);
      return new Response(
        JSON.stringify({ playerTag: '#VERIFIED', source: 'verified', active: true }),
      );
    });

    const account = await service.setAccountEnabled('#VERIFIED', true);

    expect(request).toBe('https://push.example/v2/notifications/accounts/%23VERIFIED');
    expect(JSON.parse(body)).toEqual({ enabled: true });
    expect(account.active).toBe(true);
  });

  it('loads disabled defaults and migrates retired bookmarked accounts locally', async () => {
    const preferences = new MemoryStore();
    const service = serviceWith(async () => new Response('{}'), preferences);
    const defaults = await service.loadLocal();
    expect(defaults.notificationsEnabled).toBe(false);
    expect(defaults.accounts).toEqual([]);

    const legacy: Record<string, unknown> = {
      ...responseBody,
      accounts: [
        { playerTag: '#VERIFIED', source: 'verified', active: true },
        { playerTag: '#BOOKMARK', source: 'bookmarked', active: true },
      ],
    };
    delete legacy.raidRemindersEnabled;
    delete legacy.raidReminderTimings;
    await preferences.setItem(STORAGE_KEYS.notificationSettings, JSON.stringify(legacy));

    const migrated = await service.loadLocal();
    expect(migrated.raidReminders).toBe(false);
    expect(migrated.raidReminderTimings).toEqual([]);
    expect(migrated.accounts.map((account) => account.playerTag)).toEqual(['#VERIFIED']);
  });

  it('never exposes the removed verified-player tracking route', () => {
    expect('refreshVerifiedPlayerTracking' in NotificationPreferencesService.prototype).toBe(false);
    expect(NOTIFICATION_PREFERENCES_ENDPOINT).toBe('/notifications/preferences');
  });
});
