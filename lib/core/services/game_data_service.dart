import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameDataService {
  static Uri get _staticDataUri =>
      Uri.parse("${ApiService.assetUrl}/static_data.json");
  static Uri get _translationsUri =>
      Uri.parse("${ApiService.assetUrl}/translations.json");
  static const _userAgent = 'ClashKing-App/1.0';
  static const _cacheDirName = 'game_data';
  static const _cacheRefreshInterval = Duration(hours: 6);
  static const _staticDataCache = _CachedJsonAsset(
    label: 'static_data',
    fileName: 'static_data.json',
    lastModifiedKey: 'game_data_static_last_modified',
    cachedAtKey: 'game_data_static_cached_at',
  );
  static const _translationsCache = _CachedJsonAsset(
    label: 'translations_data',
    fileName: 'translations.json',
    lastModifiedKey: 'game_data_translations_last_modified',
    cachedAtKey: 'game_data_translations_cached_at',
  );

  static final Map<String, dynamic> _petsData = {};
  static final Map<String, dynamic> _heroesData = {};
  static final Map<String, dynamic> _troopsData = {};
  static final Map<String, dynamic> _spellsData = {};
  static final Map<String, dynamic> _gearsData = {};
  static final Map<String, dynamic> _leagueData = {};
  static final Map<String, dynamic> _warLeagueData = {};
  static final Map<String, dynamic> _playerLeagueData = {};
  static final Map<String, dynamic> _gameData = {};
  static final Map<String, dynamic> _bundleData = {};
  static final Map<String, String> _translationsData = {};
  static String _translationLocale = 'EN';
  static Future<void>? _bundleLoad;
  static final Map<String, Future<void>> _translationLoads = {};

  static Future<void> loadGameData({Locale? locale}) async {
    final preferredLocale = locale ?? await resolvePreferredLocale();
    await Future.wait([
      _loadBundle(),
      loadTranslationsForLocale(preferredLocale),
    ]);
  }

  static Future<void> _loadBundle() async {
    final existing = _bundleLoad;
    if (existing != null) return existing;

    final load = _loadBundleOnce();
    _bundleLoad = load;
    try {
      await load;
    } finally {
      if (identical(_bundleLoad, load)) _bundleLoad = null;
    }
  }

  static Future<void> _loadBundleOnce() async {
    try {
      final decoded = await _loadCachedJsonAsset(
        _staticDataCache,
        _staticDataUri,
      );
      _applyBundle(decoded);
      DebugUtils.debugSuccess("Loaded static data asset");
    } catch (e) {
      DebugUtils.debugError("Failed to load static data asset: $e");
    }
  }

  static Future<Map<String, dynamic>> _loadCachedJsonAsset(
    _CachedJsonAsset asset,
    Uri uri,
  ) async {
    final file = await _cacheFile(asset.fileName);
    final prefs = await SharedPreferences.getInstance();
    final cacheExists = await file.exists();
    final cachedLastModified = prefs.getString(asset.lastModifiedKey);

    if (cacheExists) {
      try {
        final cached = await _decodeJsonFile(file, asset.label);
        if (_cacheNeedsRefresh(prefs.getString(asset.cachedAtKey))) {
          unawaited(
            _refreshCachedJsonAsset(
              asset,
              uri,
              file,
              prefs,
              cachedLastModified,
            ),
          );
        }
        return cached;
      } catch (e) {
        DebugUtils.debugError(
          "Cached ${asset.label} is invalid; downloading a replacement: $e",
        );
      }
    }

    return _downloadJsonAsset(asset, uri, file, prefs, null, maxRetries: 1);
  }

  static bool _cacheNeedsRefresh(String? cachedAt) {
    final timestamp = cachedAt == null ? null : DateTime.tryParse(cachedAt);
    if (timestamp == null) return true;
    return DateTime.now().toUtc().difference(timestamp.toUtc()) >=
        _cacheRefreshInterval;
  }

  static Future<void> _refreshCachedJsonAsset(
    _CachedJsonAsset asset,
    Uri uri,
    File file,
    SharedPreferences prefs,
    String? cachedLastModified,
  ) async {
    final remoteLastModified = await _fetchLastModified(uri, asset.label);
    if (remoteLastModified == null) return;

    if (cachedLastModified != null &&
        remoteLastModified == cachedLastModified) {
      await prefs.setString(
        asset.cachedAtKey,
        DateTime.now().toUtc().toIso8601String(),
      );
      return;
    }

    try {
      final updated = await _downloadJsonAsset(
        asset,
        uri,
        file,
        prefs,
        remoteLastModified,
        maxRetries: 2,
      );
      if (asset.fileName == _staticDataCache.fileName) {
        _applyBundle(updated);
      } else if (_translationLocale != 'EN') {
        _applyTranslations(updated, _translationLocale);
      }
    } catch (e) {
      DebugUtils.debugError(
        "Keeping cached ${asset.label} after refresh failed: $e",
      );
    }
  }

  static Future<String?> _fetchLastModified(Uri uri, String label) async {
    try {
      final response = await http
          .head(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.headers['last-modified'];
      }
      DebugUtils.debugError(
        "HTTP ${response.statusCode} checking $label Last-Modified",
      );
    } catch (e) {
      DebugUtils.debugError("Exception checking $label Last-Modified: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>> _downloadJsonAsset(
    _CachedJsonAsset asset,
    Uri uri,
    File file,
    SharedPreferences prefs,
    String? remoteLastModified, {
    int maxRetries = 3,
  }) async {
    const Duration initialDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .get(uri, headers: {'User-Agent': _userAgent})
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = utf8.decode(response.bodyBytes, allowMalformed: true);
          final decoded = jsonDecode(body);
          if (decoded is! Map) {
            throw FormatException("${asset.label} is not a JSON object");
          }
          await file.parent.create(recursive: true);
          await file.writeAsString(body);
          final lastModified =
              response.headers['last-modified'] ?? remoteLastModified;
          if (lastModified != null && lastModified.isNotEmpty) {
            await prefs.setString(asset.lastModifiedKey, lastModified);
          }
          await prefs.setString(
            asset.cachedAtKey,
            DateTime.now().toUtc().toIso8601String(),
          );
          DebugUtils.debugSuccess("Downloaded ${asset.label}");
          return Map<String, dynamic>.from(decoded);
        }

        DebugUtils.debugError(
          "HTTP ${response.statusCode} for ${asset.label} (attempt $attempt/$maxRetries)",
        );
      } catch (e) {
        DebugUtils.debugError(
          "Exception loading ${asset.label} (attempt $attempt/$maxRetries): $e",
        );
      }

      if (attempt == maxRetries) {
        throw StateError("Final failure for ${asset.label}");
      }

      final delay = Duration(
        milliseconds: initialDelay.inMilliseconds * (1 << (attempt - 1)),
      );

      DebugUtils.debugInfo(
        "🔄 Retrying ${asset.label} in ${delay.inSeconds}s...",
      );
      await Future.delayed(delay);
    }

    throw StateError("Unable to load ${asset.label}");
  }

  static Future<File> _cacheFile(String fileName) async {
    final supportDir = await getApplicationSupportDirectory();
    return File('${supportDir.path}/$_cacheDirName/$fileName');
  }

  static Future<Map<String, dynamic>> _decodeJsonFile(
    File file,
    String label,
  ) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw FormatException("Cached $label is not a JSON object");
    }
    return Map<String, dynamic>.from(decoded);
  }

  static Future<Locale> resolvePreferredLocale() async {
    final languageCode = await getPrefs('languageCode');
    final countryCode = await getPrefs('countryCode');
    final scriptCode = await getPrefs('scriptCode');

    if (languageCode != null && languageCode.isNotEmpty) {
      return Locale.fromSubtags(
        languageCode: languageCode,
        countryCode: (countryCode?.isNotEmpty ?? false) ? countryCode : null,
        scriptCode: (scriptCode?.isNotEmpty ?? false) ? scriptCode : null,
      );
    }

    final systemLocales = PlatformDispatcher.instance.locales;
    if (systemLocales.isNotEmpty) {
      return systemLocales.first;
    }

    return const Locale('en');
  }

  static String clashyLocaleCodeForAppLocale(Locale locale) {
    switch (locale.languageCode.toLowerCase()) {
      case 'ar':
        return 'AR';
      case 'de':
        return 'DE';
      case 'es':
        return 'ES';
      case 'fi':
        return 'FI';
      case 'fr':
        return 'FR';
      case 'it':
        return 'IT';
      case 'ja':
        return 'JP';
      case 'ko':
        return 'KR';
      case 'nl':
        return 'NL';
      case 'no':
        return 'NO';
      case 'pl':
        return 'PL';
      case 'pt':
        return 'PT';
      case 'ru':
        return 'RU';
      case 'tr':
        return 'TR';
      case 'vi':
        return 'VI';
      case 'zh':
        return 'CN';
      default:
        return 'EN';
    }
  }

  static Future<void> loadTranslationsForLocale(Locale locale) async {
    final clashyLocale = clashyLocaleCodeForAppLocale(locale);
    if (_translationLocale == clashyLocale && _translationsData.isNotEmpty) {
      return;
    }
    if (clashyLocale == 'EN') {
      _translationsData.clear();
      _translationLocale = clashyLocale;
      return;
    }

    final existing = _translationLoads[clashyLocale];
    if (existing != null) return existing;

    final load = _loadTranslationsOnce(clashyLocale);
    _translationLoads[clashyLocale] = load;
    try {
      await load;
    } finally {
      if (identical(_translationLoads[clashyLocale], load)) {
        _translationLoads.remove(clashyLocale);
      }
    }
  }

  static Future<void> _loadTranslationsOnce(String clashyLocale) async {
    try {
      final decoded = await _loadCachedJsonAsset(
        _translationsCache,
        _translationsUri,
      );
      _applyTranslations(decoded, clashyLocale);
      DebugUtils.debugSuccess("Loaded static translations for $clashyLocale");
    } catch (e) {
      DebugUtils.debugError(
        "Failed to load translations for $clashyLocale: $e",
      );
      _translationsData.clear();
      _translationLocale = clashyLocale;
    }
  }

  static void _applyBundle(Map<String, dynamic> rawBundle) {
    final bundle = _normalizeBundle(rawBundle);
    _bundleData
      ..clear()
      ..addAll(bundle);
    _replaceSection(_petsData, bundle['pets_data']);
    _replaceSection(_heroesData, bundle['heroes_data']);
    _replaceSection(_troopsData, bundle['troops_data']);
    _replaceSection(_spellsData, bundle['spells_data']);
    _replaceSection(_gearsData, bundle['gears_data']);
    _replaceSection(_leagueData, bundle['league_data']);
    _replaceSection(_warLeagueData, bundle['war_leagues_data']);
    _replaceSection(_playerLeagueData, bundle['player_league_data']);
    _replaceSection(_gameData, bundle['game_data']);
  }

  @visibleForTesting
  static void loadFromBundleForTesting(Map<String, dynamic> rawBundle) {
    _applyBundle(rawBundle);
  }

  static Map<String, dynamic> _normalizeBundle(Map<String, dynamic> rawBundle) {
    if (rawBundle.containsKey('pets_data') ||
        rawBundle.containsKey('heroes_data') ||
        rawBundle.containsKey('troops_data')) {
      return rawBundle;
    }

    return {
      'pets_data': {
        'pets': _itemsByName(
          rawBundle['pets'],
          urlResolver: (name, _) =>
              _assetUrl(['pets', _assetSlug(name), 'icon.webp']),
        ),
      },
      'heroes_data': {
        'heroes': _itemsByName(
          rawBundle['heroes'],
          typeResolver: (item) =>
              item['village'] == 'builderBase' ? 'bb-hero' : 'hero',
          urlResolver: (name, _) =>
              _assetUrl(['heroes', _assetSlug(name), 'icon.webp']),
        ),
      },
      'troops_data': {
        'troops': _itemsByName(
          rawBundle['troops'],
          typeResolver: _troopType,
          urlResolver: (name, _) =>
              _assetUrl(['troops', _assetSlug(name), 'icon.webp']),
        ),
      },
      'spells_data': {
        'spells': _itemsByName(
          rawBundle['spells'],
          urlResolver: (name, _) =>
              _assetUrl(['spells', '${_assetSlug(name)}.webp']),
        ),
      },
      'gears_data': {
        'gears': _itemsByName(
          rawBundle['equipment'],
          urlResolver: (name, _) =>
              _assetUrl(['equipment', '${_assetSlug(name)}.webp']),
        ),
      },
      'league_data': {'leagues': _itemsByName(rawBundle['league_tiers'])},
      'war_leagues_data': {'leagues': _itemsByName(rawBundle['war_leagues'])},
      'player_league_data': {
        'leagues': _itemsByName(rawBundle['league_tiers']),
      },
      'game_data': _deriveGameData(rawBundle),
    };
  }

  static Map<String, dynamic> _itemsByName(
    dynamic section, {
    String? Function(Map<String, dynamic> item)? typeResolver,
    String Function(String name, Map<String, dynamic> item)? urlResolver,
  }) {
    if (section is Map) {
      return Map<String, dynamic>.from(section);
    }
    if (section is! List) {
      return {};
    }

    final items = <String, dynamic>{};
    final nameCounts = <String, int>{};
    for (final rawItem in section) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final rawName = item['name'];
      if (rawName == null) continue;
      final name = rawName.toString();
      if (name.trim().isEmpty) continue;

      final maxLevel = _maxLevel(item['levels']);
      if (maxLevel > 0) {
        item['maxLevel'] = maxLevel;
      }

      final type = typeResolver?.call(item);
      if (type != null) {
        item['type'] = type;
      }

      final url = urlResolver?.call(name, item);
      if (url != null && url.isNotEmpty) {
        item['url'] = url;
      }

      final existingBaseItem = items[name];
      final isSeasonal = item['is_seasonal'] == true;
      if (existingBaseItem is Map &&
          existingBaseItem['is_seasonal'] == true &&
          !isSeasonal) {
        final duplicateKey = _nextDuplicateKey(name, nameCounts);
        items[duplicateKey] = existingBaseItem;
        items[name] = item;
        continue;
      }

      final key = items.containsKey(name)
          ? _nextDuplicateKey(name, nameCounts)
          : name;
      nameCounts[name] = nameCounts[name] ?? 1;
      items[key] = item;
    }
    return items;
  }

  static String _nextDuplicateKey(String name, Map<String, int> nameCounts) {
    final count = (nameCounts[name] ?? 1) + 1;
    nameCounts[name] = count;
    return '$name $count';
  }

  static int _maxLevel(dynamic levels) {
    if (levels is! List) {
      return 0;
    }
    var maxLevel = 0;
    for (final level in levels) {
      if (level is Map && level['level'] is num) {
        final value = (level['level'] as num).toInt();
        if (value > maxLevel) {
          maxLevel = value;
        }
      }
    }
    return maxLevel;
  }

  static String? _troopType(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? '';
    if (item['production_building'] == 'Workshop') {
      return 'siege-machine';
    }
    if (item['village'] == 'builderBase') {
      return 'bb-troop';
    }
    if (_superTroopNames.contains(name) || name.startsWith('Super ')) {
      return 'super-troop';
    }
    return 'troop';
  }

  static const Set<String> _superTroopNames = {
    'Sneaky Goblin',
    'Rocket Balloon',
    'Inferno Dragon',
    'Super Valkyrie',
    'Ice Hound',
    'Super Witch',
    'Super Bowler',
    'Super Dragon',
    'Super Wizard',
    'Super Minion',
    'Super Hog Rider',
    'Super Yeti',
  };

  static Map<String, dynamic> _deriveGameData(Map<String, dynamic> rawBundle) {
    return {
      'max_TownHall': _maxTownHallLevel(rawBundle['buildings']),
      'categories': rawBundle.keys.toList(),
    };
  }

  static int _maxTownHallLevel(dynamic buildings) {
    if (buildings is! List) {
      return 0;
    }
    for (final rawBuilding in buildings) {
      if (rawBuilding is Map && rawBuilding['name'] == 'Town Hall') {
        return _maxLevel(rawBuilding['levels']);
      }
    }
    return 0;
  }

  static String _assetSlug(String name) {
    return name.trim().toLowerCase().replaceAll(' ', '_').replaceAll('.', '');
  }

  static String _assetUrl(List<String> segments) {
    final encodedSegments = segments
        .map(Uri.encodeComponent)
        .join('/')
        .replaceAll('%2F', '/');
    return '${ApiService.assetUrl}/$encodedSegments';
  }

  static void _replaceSection(Map<String, dynamic> storage, dynamic section) {
    storage.clear();
    if (section is Map) {
      storage.addAll(Map<String, dynamic>.from(section));
    }
  }

  static void _applyTranslations(
    Map<String, dynamic> response,
    String clashyLocale,
  ) {
    _translationsData.clear();
    final translations = response['translations'] ?? response;
    if (translations is Map) {
      for (final entry in translations.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is String) {
          _translationsData[key] = value;
        } else if (value is Map) {
          final translated =
              value[clashyLocale] ?? value[clashyLocale.toLowerCase()];
          if (translated is String) {
            _translationsData[key] = translated;
          }
        }
      }
    }
    _translationLocale = clashyLocale;
  }

  static bool isSuperTroop(String name) {
    return troopsData["troops"]?[name]?["type"] == "super-troop";
  }

  static bool isSiegeMachine(String name) {
    return troopsData["troops"]?[name]?["type"] == "siege-machine";
  }

  static bool isPet(String name) {
    return petsData["pets"]?.containsKey(name) ?? false;
  }

  static int getMaxTownHallLevel() {
    return gameData["max_TownHall"] ?? 0;
  }

  static String? translationForTid(String? tid) {
    if (tid == null || tid.isEmpty) {
      return null;
    }
    return _translationsData[tid];
  }

  static String localizedNameForItem(Map<String, dynamic>? item) {
    final tid = item?['TID'];
    if (tid is Map && tid['name'] is String) {
      return translationForTid(tid['name'] as String) ??
          (item?['name']?.toString() ?? '');
    }
    return item?['name']?.toString() ?? '';
  }

  static String localizedInfoForItem(Map<String, dynamic>? item) {
    final tid = item?['TID'];
    if (tid is Map && tid['info'] is String) {
      return translationForTid(tid['info'] as String) ??
          (item?['info']?.toString() ?? '');
    }
    return item?['info']?.toString() ?? '';
  }

  static Map<String, dynamic> get petsData => _petsData;
  static Map<String, dynamic> get heroesData => _heroesData;
  static Map<String, dynamic> get troopsData => _troopsData;
  static Map<String, dynamic> get spellsData => _spellsData;
  static Map<String, dynamic> get gearsData => _gearsData;
  static Map<String, dynamic> get leagueData => _leagueData;
  static Map<String, dynamic> get warLeagueData => _warLeagueData;
  static Map<String, dynamic> get playerLeagueData => _playerLeagueData;
  static Map<String, dynamic> get gameData => _gameData;
  static Map<String, dynamic> get bundleData => _bundleData;
  static Map<String, String> get translationsData => _translationsData;
  static String get translationLocale => _translationLocale;
}

class _CachedJsonAsset {
  const _CachedJsonAsset({
    required this.label,
    required this.fileName,
    required this.lastModifiedKey,
    required this.cachedAtKey,
  });

  final String label;
  final String fileName;
  final String lastModifiedKey;
  final String cachedAtKey;
}
