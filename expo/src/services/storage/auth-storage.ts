import {
  EMPTY_AUTH_SESSION,
  serializeStoredAuthSession,
  tryParseStoredAuthSession,
  type StoredAuthSession,
} from '../../core/dto/auth-session';
import {
  LEGACY_APP_PREFERENCE_KEYS,
  LEGACY_NOTIFICATION_PREFERENCE_KEYS,
  SECURE_STORAGE_KEYS,
  STORAGE_KEYS,
} from '../../core/storage/storage';

export type RuntimePlatform = 'ios' | 'android' | 'web';

export interface StringStore {
  getItem(key: string): Promise<string | null>;
  setItem(key: string, value: string): Promise<void>;
  removeItem(key: string): Promise<void>;
  clear?(): Promise<void>;
}

export interface LegacyMigrationCapabilities {
  readonly platform: 'ios' | 'android';
  readonly secureStorageReadable: boolean;
  readonly sharedPreferencesReadable: boolean;
  readonly destructiveReads: false;
  readonly note: string;
}

export interface LegacyFlutterStorageBridge {
  getCapabilities(): LegacyMigrationCapabilities;
  readSecureValue(key: string, sharedAccessGroup?: boolean): Promise<string | null>;
  readAllSecureValues(sharedAccessGroup?: boolean): Promise<Record<string, string>>;
  readPreferences(
    keys: readonly string[],
  ): Promise<Record<string, string | number | boolean | null>>;
  readAllPreferences(): Promise<Record<string, string | number | boolean | null>>;
}

export interface SessionMigrationResult {
  readonly migrated: boolean;
  readonly source: 'shared-session' | 'legacy-secure' | 'legacy-preferences' | 'none';
  readonly legacySecureStorageBlocked: boolean;
}

export class AuthSessionRepository {
  constructor(
    private readonly secureStore: StringStore,
    private readonly preferences: StringStore,
    private readonly platform: RuntimePlatform,
    private readonly getDeviceId: () => Promise<string>,
    private readonly legacyBridge?: LegacyFlutterStorageBridge,
  ) {}

  async read(): Promise<StoredAuthSession> {
    if (this.platform === 'web') return EMPTY_AUTH_SESSION;
    const encoded = await this.secureStore.getItem(SECURE_STORAGE_KEYS.sharedAuthSession);
    let session = tryParseStoredAuthSession(encoded);
    if (session.accessToken !== null && session.refreshToken !== null) {
      if (this.platform === 'ios' && session.deviceId === null) {
        session = { ...session, deviceId: await this.getDeviceId() };
        await this.write(session);
      }
      return session;
    }
    const migration = await this.migrateLegacySession();
    return migration.migrated
      ? tryParseStoredAuthSession(
          await this.secureStore.getItem(SECURE_STORAGE_KEYS.sharedAuthSession),
        )
      : EMPTY_AUTH_SESSION;
  }

  async write(session: StoredAuthSession): Promise<void> {
    if (this.platform === 'web') return;
    await this.secureStore.setItem(
      SECURE_STORAGE_KEYS.sharedAuthSession,
      serializeStoredAuthSession(session),
    );
    await this.secureStore.setItem(SECURE_STORAGE_KEYS.flutterAuthMigration, 'true');
    await this.removeCurrentLegacyTokenCopies();
  }

  async clear(): Promise<void> {
    await Promise.all([
      this.secureStore.removeItem(SECURE_STORAGE_KEYS.sharedAuthSession),
      this.secureStore.removeItem(SECURE_STORAGE_KEYS.legacyAccessToken),
      this.secureStore.removeItem(SECURE_STORAGE_KEYS.legacyRefreshToken),
      this.preferences.removeItem(SECURE_STORAGE_KEYS.legacyAccessToken),
      this.preferences.removeItem(SECURE_STORAGE_KEYS.legacyRefreshToken),
    ]);
  }

  async clearWebLegacyTokens(): Promise<void> {
    await Promise.all([
      this.secureStore.removeItem(SECURE_STORAGE_KEYS.legacyAccessToken),
      this.secureStore.removeItem(SECURE_STORAGE_KEYS.legacyRefreshToken),
      this.preferences.removeItem(SECURE_STORAGE_KEYS.legacyAccessToken),
      this.preferences.removeItem(SECURE_STORAGE_KEYS.legacyRefreshToken),
    ]);
  }

  async migrateLegacySession(): Promise<SessionMigrationResult> {
    if (this.platform === 'web') {
      await this.clearWebLegacyTokens();
      return {
        migrated: false,
        source: 'none',
        legacySecureStorageBlocked: false,
      };
    }

    const existing = tryParseStoredAuthSession(
      await this.secureStore.getItem(SECURE_STORAGE_KEYS.sharedAuthSession),
    );
    if (existing.accessToken !== null && existing.refreshToken !== null) {
      await this.secureStore.setItem(SECURE_STORAGE_KEYS.flutterAuthMigration, 'true');
      return {
        migrated: false,
        source: 'shared-session',
        legacySecureStorageBlocked: false,
      };
    }

    if ((await this.secureStore.getItem(SECURE_STORAGE_KEYS.flutterAuthMigration)) === 'true') {
      return {
        migrated: false,
        source: 'none',
        legacySecureStorageBlocked: false,
      };
    }

    const capabilities = this.legacyBridge?.getCapabilities();
    const secureReadable = capabilities?.secureStorageReadable === true;
    const secureTokens = secureReadable
      ? await Promise.all([
          this.legacyBridge!.readSecureValue(SECURE_STORAGE_KEYS.legacyAccessToken),
          this.legacyBridge!.readSecureValue(SECURE_STORAGE_KEYS.legacyRefreshToken),
        ])
      : ([null, null] as const);

    const bridgedPreferences =
      capabilities?.sharedPreferencesReadable === true
        ? await this.legacyBridge!.readPreferences([
            SECURE_STORAGE_KEYS.legacyAccessToken,
            SECURE_STORAGE_KEYS.legacyRefreshToken,
          ])
        : {};
    const preferenceAccess =
      (await this.preferences.getItem(SECURE_STORAGE_KEYS.legacyAccessToken)) ??
      stringOrNull(bridgedPreferences[SECURE_STORAGE_KEYS.legacyAccessToken]);
    const preferenceRefresh =
      (await this.preferences.getItem(SECURE_STORAGE_KEYS.legacyRefreshToken)) ??
      stringOrNull(bridgedPreferences[SECURE_STORAGE_KEYS.legacyRefreshToken]);
    const accessToken = secureTokens[0] ?? preferenceAccess;
    const refreshToken = secureTokens[1] ?? preferenceRefresh;

    if (accessToken === null || refreshToken === null) {
      if (secureReadable) {
        await this.secureStore.setItem(SECURE_STORAGE_KEYS.flutterAuthMigration, 'true');
      }
      return {
        migrated: false,
        source: 'none',
        legacySecureStorageBlocked: this.platform === 'android' && secureReadable === false,
      };
    }

    await this.write({
      accessToken,
      refreshToken,
      deviceId: this.platform === 'ios' ? await this.getDeviceId() : null,
    });
    return {
      migrated: true,
      source:
        secureTokens[0] !== null && secureTokens[1] !== null
          ? 'legacy-secure'
          : 'legacy-preferences',
      legacySecureStorageBlocked: false,
    };
  }

  private async removeCurrentLegacyTokenCopies(): Promise<void> {
    await Promise.all([
      this.secureStore.removeItem(SECURE_STORAGE_KEYS.legacyAccessToken),
      this.secureStore.removeItem(SECURE_STORAGE_KEYS.legacyRefreshToken),
      this.preferences.removeItem(SECURE_STORAGE_KEYS.legacyAccessToken),
      this.preferences.removeItem(SECURE_STORAGE_KEYS.legacyRefreshToken),
    ]);
  }
}

export interface PreferenceMigrationResult {
  readonly migratedKeys: readonly string[];
  readonly legacyValuesRetained: boolean;
}

export class FlutterPreferenceMigration {
  constructor(
    private readonly preferences: StringStore,
    private readonly legacyBridge?: LegacyFlutterStorageBridge,
    private readonly markerStore: StringStore = preferences,
  ) {}

  async run(): Promise<PreferenceMigrationResult> {
    if (
      (await this.markerStore.getItem(SECURE_STORAGE_KEYS.flutterPreferenceMigration)) === 'true' ||
      (await this.preferences.getItem(STORAGE_KEYS.appPreferencesMigration)) === 'true'
    ) {
      return { migratedKeys: [], legacyValuesRetained: true };
    }
    const capabilities = this.legacyBridge?.getCapabilities();
    if (
      capabilities?.sharedPreferencesReadable !== true &&
      capabilities?.secureStorageReadable !== true
    ) {
      return { migratedKeys: [], legacyValuesRetained: false };
    }

    const [secureValues, preferenceValues] = await Promise.all([
      capabilities.secureStorageReadable
        ? this.legacyBridge!.readAllSecureValues(false)
        : Promise.resolve({}),
      capabilities.sharedPreferencesReadable
        ? this.legacyBridge!.readAllPreferences()
        : Promise.resolve({}),
    ]);
    const legacy: Record<string, string | number | boolean | null> = {
      ...secureValues,
      ...preferenceValues,
    };
    const keys = Object.keys(legacy).filter(isLegacyAppPreference);
    const migratedKeys: string[] = [];
    for (const key of keys) {
      if ((await this.preferences.getItem(key)) !== null) continue;
      const value = legacy[key];
      if (value === undefined || value === null) continue;
      await this.preferences.setItem(key, String(value));
      migratedKeys.push(key);
    }
    await this.preferences.setItem(STORAGE_KEYS.appPreferencesMigration, 'true');
    await this.markerStore.setItem(SECURE_STORAGE_KEYS.flutterPreferenceMigration, 'true');
    return { migratedKeys, legacyValuesRetained: true };
  }
}

function isLegacyAppPreference(key: string): boolean {
  return (
    LEGACY_APP_PREFERENCE_KEYS.includes(key as (typeof LEGACY_APP_PREFERENCE_KEYS)[number]) ||
    LEGACY_NOTIFICATION_PREFERENCE_KEYS.includes(
      key as (typeof LEGACY_NOTIFICATION_PREFERENCE_KEYS)[number],
    ) ||
    key === STORAGE_KEYS.remoteFeatureFlagSeed ||
    key === STORAGE_KEYS.playerCardOptions ||
    key === STORAGE_KEYS.warStatsFilterPresets ||
    key === STORAGE_KEYS.notificationSettings ||
    key === STORAGE_KEYS.notificationsEnabled ||
    key === STORAGE_KEYS.notificationPermissionPrimerShown ||
    key === STORAGE_KEYS.upgradeTrackerSnapshotIndex ||
    key.startsWith('announcement_dismissed_') ||
    key.startsWith('upgrade_tracker_snapshot_v1_') ||
    key.startsWith('upgrade_tracker_preferences_v2_') ||
    (key.startsWith('player_') && key.endsWith('_clan_tag'))
  );
}

function stringOrNull(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}
