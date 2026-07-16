import 'package:flutter/material.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/core/services/war_widget_sync_service.dart';
import 'package:clashkingapp/core/services/remote_feature_flag_service.dart';
import 'package:clashkingapp/core/config/app_feature_flags.dart';
import 'package:clashkingapp/l10n/locale.dart';

class MyAppState extends ChangeNotifier {
  MyAppState({
    WarWidgetSyncService? warWidgetSyncService,
    RemoteFeatureFlagService? featureFlagService,
  }) : _warWidgetSyncService =
           warWidgetSyncService ?? const WarWidgetSyncService(),
       _featureFlagService = featureFlagService ?? RemoteFeatureFlagService() {
    _loadLanguage();
    featureFlagsReady = _loadFeatureFlags();
  }

  final WarWidgetSyncService _warWidgetSyncService;
  final RemoteFeatureFlagService _featureFlagService;
  late final Future<void> featureFlagsReady;
  Locale _locale = Locale('en'); // Default language is English
  Locale get locale => _locale; // Getter for the locale
  bool isLoading = false; // Loading state of the app

  bool isFeatureEnabled(String key, {bool? fallback}) => _featureFlagService
      .isEnabled(key, fallback: fallback ?? AppFeatureFlags.defaultValue(key));

  bool get _warWidgetsEnabled => isFeatureEnabled(AppFeatureFlags.warWidgets);

  void registerWarWidgetRefreshIfEnabled() {
    if (_warWidgetsEnabled) {
      _warWidgetSyncService.registerPeriodicRefresh();
    }
  }

  Future<void> _loadFeatureFlags() async {
    try {
      await _featureFlagService.refresh();
    } catch (_) {
      // Remote configuration is fail-open for existing features. A temporary
      // backend issue must never remove an established app surface.
    }

    notifyListeners();
  }

  /* Language management */

  // This method checks if the locale is supported, if not, it falls back to English
  Locale _getLocaleFallback(Locale locale) {
    for (LocaleInfo supportedLocaleInfo in supportedLocales) {
      if (supportedLocaleInfo.languageCode == locale.languageCode &&
          (supportedLocaleInfo.scriptCode == locale.scriptCode ||
              supportedLocaleInfo.scriptCode == null) &&
          (supportedLocaleInfo.countryCode == locale.countryCode ||
              supportedLocaleInfo.countryCode == null)) {
        return Locale.fromSubtags(
          languageCode: supportedLocaleInfo.languageCode,
          scriptCode: supportedLocaleInfo.scriptCode,
          countryCode: supportedLocaleInfo.countryCode,
        ); // Return if supported
      }
    }

    // If no exact match, try matching only by language code
    for (LocaleInfo supportedLocaleInfo in supportedLocales) {
      if (supportedLocaleInfo.languageCode == locale.languageCode) {
        return Locale.fromSubtags(
          languageCode: supportedLocaleInfo.languageCode,
          scriptCode: supportedLocaleInfo.scriptCode,
          countryCode: supportedLocaleInfo.countryCode,
        );
      }
    }

    return Locale('en'); // Fallback to English
  }

  // Load the language from the shared preferences or set to the system locale
  Future<void> _loadLanguage() async {
    String? languageCode = await getPrefs('languageCode');

    if (languageCode != null) {
      Locale userLocale = Locale(languageCode);
      _locale = _getLocaleFallback(userLocale);
    } else {
      Locale systemLocale = Locale(
        WidgetsBinding.instance.platformDispatcher.locales.first.languageCode,
      );
      _locale = _getLocaleFallback(systemLocale);
    }

    await GameDataService.loadTranslationsForLocale(_locale);
    notifyListeners();
  }

  // Change the language of the app
  Future<void> changeLanguage(Locale locale) async {
    _locale = locale;
    await storePrefs('languageCode', locale.languageCode);
    if (locale.countryCode != null) {
      await storePrefs('countryCode', locale.countryCode!);
    }
    if (locale.scriptCode != null) {
      await storePrefs('scriptCode', locale.scriptCode!);
    }
    await GameDataService.loadTranslationsForLocale(_locale);
    notifyListeners();
  }

  /* Widgets management */

  // Initialize the app from the background
  Future<void> initializeFromBackground(Uri data) async {
    if (!_warWidgetsEnabled) return;
    await _warWidgetSyncService.initializeFromBackground(data);
  }

  // Update the war widget
  Future<void> updateWarWidget() async {
    if (!_warWidgetsEnabled) return;
    await _warWidgetSyncService.updateWarWidget();
  }

  // Update the widgets
  Future<void> updateWidgets() async {
    if (!_warWidgetsEnabled) return;
    await _warWidgetSyncService.updateWidgets();
  }
}
