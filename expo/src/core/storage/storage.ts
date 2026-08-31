export interface StringStorage {
  getString(key: string): Promise<string | null>;
  setString(key: string, value: string): Promise<void>;
  remove(key: string): Promise<void>;
}

export interface KeyValueStorage extends StringStorage {
  getBoolean(key: string): Promise<boolean | null>;
  setBoolean(key: string, value: boolean): Promise<void>;
  getNumber(key: string): Promise<number | null>;
  setNumber(key: string, value: number): Promise<void>;
  clear(): Promise<void>;
}

export type SecureSessionStorage = StringStorage;

export const SECURE_STORAGE_KEYS = {
  sharedAuthSession: 'shared_auth_session_v1',
  flutterAuthMigration: 'flutter_auth_migration_v1',
  flutterPreferenceMigration: 'flutter_preferences_migration_v1',
  legacyAccessToken: 'access_token',
  legacyRefreshToken: 'refresh_token',
} as const;

export const STORAGE_KEYS = {
  appPreferencesMigration: 'app_preferences_secure_migration_v1',
  deviceIdFallback: 'device_id_fallback',
  selectedTag: 'selectedTag',
  remoteFeatureFlagSeed: 'remoteFeatureFlagSeed',
  playerCardOptions: 'player_card_options_v1',
  warStatsFilterPresets: 'war_stats_filter_presets',
  notificationSettings: 'notification_settings_v2',
  notificationsEnabled: 'notif_settings_notifications_enabled',
  pushFcmToken: 'push_fcm_token',
  pushLastRegistrationToken: 'push_last_registration_token',
  notificationPermissionPrimerShown: 'notif_permission_primer_shown',
  gameDataStaticLastModified: 'game_data_static_last_modified',
  gameDataStaticCachedAt: 'game_data_static_cached_at',
  gameDataTranslationsLastModified: 'game_data_translations_last_modified',
  gameDataTranslationsCachedAt: 'game_data_translations_cached_at',
  gameAssetManifest: 'game_asset_manifest_v1',
  gameAssetManifestFetchedAt: 'game_asset_manifest_v1_fetched_at',
  upgradeTrackerSnapshotIndex: 'upgrade_tracker_snapshot_index_v1',
} as const;

export const LEGACY_APP_PREFERENCE_KEYS = [
  'auth_local_mode',
  'clanTag',
  'countryCode',
  'languageCode',
  'scriptCode',
  'selectedTag',
  'selected_player_tag',
  'selectedPlayerTag',
  'themeMode',
] as const;

export const LEGACY_NOTIFICATION_PREFERENCE_KEYS = [
  'notif_settings_enabled_types',
  'notif_settings_war_attack_modes',
  'notif_settings_event_types',
  'notif_settings_reminder_timings',
  'notif_settings_war_state_types',
  'notif_settings_account_scope',
  'notif_settings_selected_accounts',
  'notif_settings_selected_town_halls',
  'notif_settings_selected_clan_tags',
  'notif_settings_limited_account_types',
  'notif_settings_accounts_by_type',
] as const;

export const WIDGET_STORAGE_KEYS = {
  warClans: 'warWidgetClans',
  warSelectedClan: 'warWidgetSelectedClan',
  warDefaultInfo: 'warInfo',
  warProxyUrl: 'warWidgetProxyUrl',
  warApiV2Url: 'warWidgetApiV2Url',
  legacyWarAuthToken: 'warWidgetAuthToken',
  upgradeAccounts: 'upgradeWidgetAccounts',
  upgradeAndroidData: 'upgradeWidgetData',
  upgradeAndroidSelectedTag: 'upgradeWidgetSelectedTag',
} as const;

export function playerClanTagStorageKey(normalizedTag: string): string {
  return `player_${normalizedTag}_clan_tag`;
}

export function announcementDismissalStorageKey(presentationKey: string): string {
  return `announcement_dismissed_${presentationKey}`;
}

export function upgradeTrackerSnapshotStorageKey(normalizedTag: string): string {
  return `upgrade_tracker_snapshot_v1_${normalizedTag}`;
}

export function upgradeTrackerPreferencesStorageKey(normalizedTag: string): string {
  return `upgrade_tracker_preferences_v2_${normalizedTag}`;
}

export function warWidgetInfoStorageKey(normalizedTag: string): string {
  return `warInfo_${normalizedTag}`;
}

export function upgradeWidgetStorageKey(normalizedTag: string): string {
  return `upgradeWidget_${normalizedTag}`;
}
