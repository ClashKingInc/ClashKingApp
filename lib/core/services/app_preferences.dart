import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

typedef PreferencesLoader = Future<SharedPreferences> Function();

/// Owns non-secret application preferences and migrates values that older app
/// versions stored in the keychain/keystore. Authentication tokens remain in
/// [FlutterSecureStorage] and are owned by TokenService.
class AppPreferences {
  AppPreferences({
    FlutterSecureStorage? legacyStorage,
    PreferencesLoader? preferencesLoader,
  }) : _legacyStorage = legacyStorage ?? const FlutterSecureStorage(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static final AppPreferences shared = AppPreferences();

  static const _migrationKey = 'app_preferences_secure_migration_v1';
  static const _legacyKeys = {
    'auth_local_mode',
    'clanTag',
    'countryCode',
    'languageCode',
    'scriptCode',
    'selectedTag',
    'selected_player_tag',
    'selectedPlayerTag',
    'themeMode',
  };

  final FlutterSecureStorage _legacyStorage;
  final PreferencesLoader _preferencesLoader;
  Future<void>? _migration;

  Future<String?> getString(String key) async {
    final prefs = await _readyPreferences();
    return prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final prefs = await _readyPreferences();
    await prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    final prefs = await _readyPreferences();
    await prefs.remove(key);
  }

  Future<void> clear() async {
    final prefs = await _readyPreferences();
    await prefs.clear();

    // A partially completed migration may still have non-secret values in
    // secure storage. Never delete token or stable device-identity keys here.
    final legacyValues = await _legacyStorage.readAll();
    await Future.wait(
      legacyValues.keys
          .where(_isLegacyAppPreference)
          .map((key) => _legacyStorage.delete(key: key)),
    );
  }

  Future<SharedPreferences> _readyPreferences() async {
    final prefs = await _preferencesLoader();
    if (prefs.getBool(_migrationKey) == true) return prefs;

    final existing = _migration;
    if (existing != null) {
      await existing;
      return prefs;
    }

    final migration = _migrateLegacyValues(prefs);
    _migration = migration;
    try {
      await migration;
    } catch (error, stackTrace) {
      Sentry.captureException(error, stackTrace: stackTrace);
    } finally {
      if (identical(_migration, migration)) _migration = null;
    }
    return prefs;
  }

  Future<void> _migrateLegacyValues(SharedPreferences prefs) async {
    final legacyValues = await _legacyStorage.readAll();
    final valuesToMove = legacyValues.entries
        .where((entry) => _isLegacyAppPreference(entry.key))
        .toList(growable: false);

    for (final entry in valuesToMove) {
      if (!prefs.containsKey(entry.key)) {
        await prefs.setString(entry.key, entry.value);
      }
    }
    await Future.wait(
      valuesToMove.map((entry) => _legacyStorage.delete(key: entry.key)),
    );
    await prefs.setBool(_migrationKey, true);
  }

  static bool _isLegacyAppPreference(String key) {
    return _legacyKeys.contains(key) ||
        (key.startsWith('player_') && key.endsWith('_clan_tag'));
  }
}
