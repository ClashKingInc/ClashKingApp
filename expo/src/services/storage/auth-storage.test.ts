import {
  AuthSessionRepository,
  FlutterPreferenceMigration,
  type LegacyFlutterStorageBridge,
  type LegacyMigrationCapabilities,
  type StringStore,
} from './auth-storage';

class MemoryStore implements StringStore {
  readonly values = new Map<string, string>();

  async getItem(key: string): Promise<string | null> {
    return this.values.get(key) ?? null;
  }

  async setItem(key: string, value: string): Promise<void> {
    this.values.set(key, value);
  }

  async removeItem(key: string): Promise<void> {
    this.values.delete(key);
  }
}

function bridge(
  capabilities: LegacyMigrationCapabilities,
  secure: Record<string, string | null> = {},
  preferences: Record<string, string | number | boolean | null> = {},
): LegacyFlutterStorageBridge {
  return {
    getCapabilities: () => capabilities,
    readSecureValue: async (key) => secure[key] ?? null,
    readAllSecureValues: async () =>
      Object.fromEntries(
        Object.entries(secure).filter((entry): entry is [string, string] => entry[1] !== null),
      ),
    readPreferences: async (keys) =>
      Object.fromEntries(
        keys.flatMap((key) => (key in preferences ? [[key, preferences[key]!]] : [])),
      ),
    readAllPreferences: async () => preferences,
  };
}

describe('Flutter auth storage migration', () => {
  it('migrates readable iOS legacy tokens into the shared session contract', async () => {
    const secure = new MemoryStore();
    const preferences = new MemoryStore();
    const repository = new AuthSessionRepository(
      secure,
      preferences,
      'ios',
      async () => 'ios-device',
      bridge(
        {
          platform: 'ios',
          secureStorageReadable: true,
          sharedPreferencesReadable: true,
          destructiveReads: false,
          note: 'test',
        },
        { access_token: 'access', refresh_token: 'refresh' },
      ),
    );

    await expect(repository.read()).resolves.toEqual({
      accessToken: 'access',
      refreshToken: 'refresh',
      deviceId: 'ios-device',
    });
    expect(secure.values.get('shared_auth_session_v1')).toBe(
      '{"access_token":"access","refresh_token":"refresh","device_id":"ios-device"}',
    );
    expect(secure.values.get('flutter_auth_migration_v1')).toBe('true');
  });

  it('does not resurrect migrated Flutter credentials after logout', async () => {
    const secure = new MemoryStore();
    const preferences = new MemoryStore();
    const repository = new AuthSessionRepository(
      secure,
      preferences,
      'android',
      async () => 'android-device',
      bridge(
        {
          platform: 'android',
          secureStorageReadable: true,
          sharedPreferencesReadable: true,
          destructiveReads: false,
          note: 'read-only legacy credentials',
        },
        { access_token: 'legacy-access', refresh_token: 'legacy-refresh' },
      ),
    );

    await expect(repository.read()).resolves.toMatchObject({
      accessToken: 'legacy-access',
      refreshToken: 'legacy-refresh',
    });
    await repository.clear();
    await expect(repository.read()).resolves.toEqual({
      accessToken: null,
      refreshToken: null,
      deviceId: null,
    });
  });

  it('reports a platform bridge without secure-storage support as blocked', async () => {
    const repository = new AuthSessionRepository(
      new MemoryStore(),
      new MemoryStore(),
      'android',
      async () => 'android-device',
      bridge({
        platform: 'android',
        secureStorageReadable: false,
        sharedPreferencesReadable: true,
        destructiveReads: false,
        note: 'ciphertext unavailable',
      }),
    );
    await expect(repository.migrateLegacySession()).resolves.toMatchObject({
      migrated: false,
      legacySecureStorageBlocked: true,
    });
  });

  it('copies non-secret Flutter preferences without overwriting Expo values', async () => {
    const preferences = new MemoryStore();
    await preferences.setItem('themeMode', 'dark');
    const migration = new FlutterPreferenceMigration(
      preferences,
      bridge(
        {
          platform: 'ios',
          secureStorageReadable: true,
          sharedPreferencesReadable: true,
          destructiveReads: false,
          note: 'test',
        },
        {},
        { themeMode: 'light', languageCode: 'fr' },
      ),
    );
    await expect(migration.run()).resolves.toMatchObject({
      migratedKeys: ['languageCode'],
      legacyValuesRetained: true,
    });
    expect(preferences.values.get('themeMode')).toBe('dark');
    expect(preferences.values.get('languageCode')).toBe('fr');
  });

  it('migrates dynamic player clan tags from both Flutter storage generations', async () => {
    const preferences = new MemoryStore();
    const migration = new FlutterPreferenceMigration(
      preferences,
      bridge(
        {
          platform: 'android',
          secureStorageReadable: true,
          sharedPreferencesReadable: true,
          destructiveReads: false,
          note: 'exact Flutter storage bridge',
        },
        {
          'player_#SECURE_clan_tag': '#OLDCLAN',
          access_token: 'must-not-be-copied-as-a-preference',
        },
        {
          'player_#PREFS_clan_tag': '#NEWCLAN',
          themeMode: 'dark',
          unrelated: 'ignored',
        },
      ),
    );

    await expect(migration.run()).resolves.toMatchObject({
      migratedKeys: ['player_#SECURE_clan_tag', 'player_#PREFS_clan_tag', 'themeMode'],
      legacyValuesRetained: true,
    });
    expect(preferences.values.get('player_#SECURE_clan_tag')).toBe('#OLDCLAN');
    expect(preferences.values.get('player_#PREFS_clan_tag')).toBe('#NEWCLAN');
    expect(preferences.values.has('access_token')).toBe(false);
    expect(preferences.values.has('unrelated')).toBe(false);
  });

  it('preserves exact Flutter player-card options and war-filter preset payloads', async () => {
    const preferences = new MemoryStore();
    const playerOptions =
      '{"ABC":{"warTab":false,"todoPage":true,"upgradeTrackerHome":false,"rankedHome":true}}';
    const filterPresets =
      '[{"id":"1","name":"CWL","filter":{"type":["cwl"],"stars":[3]},"createdAt":"2026-08-30T12:00:00.000Z"}]';
    const migration = new FlutterPreferenceMigration(
      preferences,
      bridge(
        {
          platform: 'ios',
          secureStorageReadable: false,
          sharedPreferencesReadable: true,
          destructiveReads: false,
          note: 'exact Flutter player preferences',
        },
        {},
        {
          player_card_options_v1: playerOptions,
          war_stats_filter_presets: filterPresets,
        },
      ),
    );

    await expect(migration.run()).resolves.toMatchObject({
      migratedKeys: ['player_card_options_v1', 'war_stats_filter_presets'],
      legacyValuesRetained: true,
    });
    expect(preferences.values.get('player_card_options_v1')).toBe(playerOptions);
    expect(preferences.values.get('war_stats_filter_presets')).toBe(filterPresets);
  });

  it('preserves user-owned notification, announcement, rollout, and upgrade settings once', async () => {
    const preferences = new MemoryStore();
    await preferences.setItem('announcement_dismissed_keep-expo', 'true');
    const notificationSettings = '{"notificationsEnabled":true,"reminderTimings":[60,15]}';
    const snapshotIndex = '["#AAA","#BBB"]';
    const snapshot = '{"playerTag":"#AAA","updatedAt":"2026-08-30T12:00:00.000Z"}';
    const upgradePreferences = '{"includeWalls":false,"preferredOrder":"time"}';
    const migration = new FlutterPreferenceMigration(
      preferences,
      bridge(
        {
          platform: 'android',
          secureStorageReadable: false,
          sharedPreferencesReadable: true,
          destructiveReads: false,
          note: 'exact Flutter replacement preferences',
        },
        {},
        {
          remoteFeatureFlagSeed: 417,
          notification_settings_v2: notificationSettings,
          notif_settings_notifications_enabled: true,
          notif_permission_primer_shown: true,
          notif_settings_enabled_types: '["legendAttacks","warReminders"]',
          'announcement_dismissed_keep-expo': false,
          'announcement_dismissed_welcome-1': true,
          upgrade_tracker_snapshot_index_v1: snapshotIndex,
          'upgrade_tracker_snapshot_v1_#AAA': snapshot,
          'upgrade_tracker_preferences_v2_#AAA': upgradePreferences,
          game_data_static_cached_at: 123,
        },
      ),
    );

    const first = await migration.run();

    expect(first.migratedKeys).toEqual([
      'remoteFeatureFlagSeed',
      'notification_settings_v2',
      'notif_settings_notifications_enabled',
      'notif_permission_primer_shown',
      'notif_settings_enabled_types',
      'announcement_dismissed_welcome-1',
      'upgrade_tracker_snapshot_index_v1',
      'upgrade_tracker_snapshot_v1_#AAA',
      'upgrade_tracker_preferences_v2_#AAA',
    ]);
    expect(preferences.values.get('notification_settings_v2')).toBe(notificationSettings);
    expect(preferences.values.get('announcement_dismissed_keep-expo')).toBe('true');
    expect(preferences.values.get('announcement_dismissed_welcome-1')).toBe('true');
    expect(preferences.values.get('upgrade_tracker_snapshot_index_v1')).toBe(snapshotIndex);
    expect(preferences.values.get('upgrade_tracker_snapshot_v1_#AAA')).toBe(snapshot);
    expect(preferences.values.get('upgrade_tracker_preferences_v2_#AAA')).toBe(upgradePreferences);
    expect(preferences.values.has('game_data_static_cached_at')).toBe(false);
    await expect(migration.run()).resolves.toEqual({
      migratedKeys: [],
      legacyValuesRetained: true,
    });
  });

  it('keeps the one-way preference migration closed after logout clears app preferences', async () => {
    const preferences = new MemoryStore();
    const markerStore = new MemoryStore();
    const migration = new FlutterPreferenceMigration(
      preferences,
      bridge(
        {
          platform: 'android',
          secureStorageReadable: true,
          sharedPreferencesReadable: true,
          destructiveReads: false,
          note: 'read-only legacy preferences',
        },
        {},
        { themeMode: 'dark', languageCode: 'fr' },
      ),
      markerStore,
    );

    await expect(migration.run()).resolves.toMatchObject({
      migratedKeys: ['themeMode', 'languageCode'],
    });
    preferences.values.clear();
    await expect(migration.run()).resolves.toEqual({
      migratedKeys: [],
      legacyValuesRetained: true,
    });
    expect(preferences.values.size).toBe(0);
    expect(markerStore.values.get('flutter_preferences_migration_v1')).toBe('true');
  });
});
