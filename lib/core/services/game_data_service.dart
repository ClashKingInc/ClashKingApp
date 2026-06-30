import 'dart:convert';
import 'dart:ui';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/utils/debug_utils.dart';

class GameDataService {
  static const String _bundleUrl = "${ApiService.apiUrlV2}/static/app-bundle";
  static const String _translationsUrl =
      "${ApiService.apiUrlV2}/static/app-translations";

  static Map<String, dynamic> _petsData = {};
  static Map<String, dynamic> _heroesData = {};
  static Map<String, dynamic> _troopsData = {};
  static Map<String, dynamic> _spellsData = {};
  static Map<String, dynamic> _gearsData = {};
  static Map<String, dynamic> _leagueData = {};
  static Map<String, dynamic> _warLeagueData = {};
  static Map<String, dynamic> _playerLeagueData = {};
  static Map<String, dynamic> _gameData = {};
  static final Map<String, dynamic> _bundleData = {};
  static final Map<String, String> _translationsData = {};
  static String _translationLocale = 'EN';

  static Future<void> loadGameData({Locale? locale}) async {
    final preferredLocale = locale ?? await resolvePreferredLocale();
    await Future.wait([
      _loadBundle(),
      loadTranslationsForLocale(preferredLocale),
    ]);
  }

  static Future<void> _loadBundle() async {
    const int maxRetries = 3;
    const Duration initialDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse(_bundleUrl),
              headers: {'User-Agent': 'ClashKing-App/1.0'},
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is! Map) {
            throw const FormatException(
              "Static app bundle is not a JSON object",
            );
          }
          _applyBundle(Map<String, dynamic>.from(decoded));
          DebugUtils.debugSuccess(
            "Loaded static app bundle (attempt $attempt)",
          );
          break;
        }

        DebugUtils.debugError(
          "HTTP ${response.statusCode} for static app bundle (attempt $attempt/$maxRetries)",
        );
      } catch (e) {
        DebugUtils.debugError(
          "Exception loading static app bundle (attempt $attempt/$maxRetries): ${e.toString()}",
        );
      }

      if (attempt == maxRetries) {
        DebugUtils.debugError(
          "Final failure for static app bundle after $maxRetries attempts",
        );
        break;
      }

      final delay = Duration(
        milliseconds: initialDelay.inMilliseconds * (1 << (attempt - 1)),
      );

      DebugUtils.debugInfo(
        "🔄 Retrying static app bundle in ${delay.inSeconds}s...",
      );
      await Future.delayed(delay);
    }
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

    const int maxRetries = 3;
    const Duration initialDelay = Duration(milliseconds: 500);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse("$_translationsUrl?locale=$clashyLocale"),
              headers: {'User-Agent': 'ClashKing-App/1.0'},
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is! Map) {
            throw const FormatException(
              "Static app translations are not a JSON object",
            );
          }
          _applyTranslations(Map<String, dynamic>.from(decoded), clashyLocale);
          DebugUtils.debugSuccess(
            "Loaded static app translations for $clashyLocale (attempt $attempt)",
          );
          return;
        }

        DebugUtils.debugError(
          "HTTP ${response.statusCode} for static app translations ($clashyLocale, attempt $attempt/$maxRetries)",
        );
      } catch (e) {
        DebugUtils.debugError(
          "Exception loading static app translations ($clashyLocale, attempt $attempt/$maxRetries): ${e.toString()}",
        );
      }

      if (attempt == maxRetries) {
        DebugUtils.debugError(
          "Final failure for static app translations ($clashyLocale)",
        );
        _translationsData.clear();
        _translationLocale = clashyLocale;
        return;
      }

      final delay = Duration(
        milliseconds: initialDelay.inMilliseconds * (1 << (attempt - 1)),
      );
      await Future.delayed(delay);
    }
  }

  static void _applyBundle(Map<String, dynamic> bundle) {
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
    final translations = response['translations'];
    if (translations is Map) {
      for (final entry in translations.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is String) {
          _translationsData[key] = value;
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
