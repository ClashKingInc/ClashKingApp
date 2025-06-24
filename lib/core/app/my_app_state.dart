
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/widgets/widgets_functions.dart';
import 'package:clashkingapp/widgets/war_widget.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:clashkingapp/l10n/locale.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MyAppState extends ChangeNotifier with WidgetsBindingObserver {
  Future<void>? initializeUserFuture;
  String? clanTag;
  ValueNotifier<String?> selectedTagNotifier = ValueNotifier<String?>(null);

  Locale _locale = Locale('en'); // Default language is English
  Locale get locale => _locale; // Getter for the locale
  bool isLoading = false; // Loading state of the app

  MyAppState() {
    // Initialize the default page to first tag
    WidgetsBinding.instance.addObserver(this);

    _loadLanguage(); // Load the language from the shared preferences
    if (!kIsWeb && Platform.isAndroid) {
      // Initialize the refresh of the war widget every 15 minutes
      Workmanager().registerPeriodicTask(
        '1',
        'simplePeriodicTask',
        frequency: Duration(minutes: 15),
      );
    }
  }

  // This method is called when the app is resumed
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove the observer
    selectedTagNotifier.dispose(); // Dispose the ValueNotifier
    super.dispose();
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
  void _loadLanguage() async {
    String? languageCode = await getPrefs('languageCode');

    if (languageCode != null) {
      Locale userLocale = Locale(languageCode);
      _locale = _getLocaleFallback(userLocale);
    } else {
      Locale systemLocale = Locale(WidgetsBinding
          .instance.platformDispatcher.locales.first.languageCode);
      _locale = _getLocaleFallback(systemLocale);
    }

    notifyListeners();
  }

  // Change the language of the app
  void changeLanguage(Locale locale) async {
    _locale = locale;
    await storePrefs('languageCode', locale.languageCode);
    if (locale.countryCode != null) {
      await storePrefs('countryCode', locale.countryCode!);
    }
    if (locale.scriptCode != null) {
      await storePrefs('scriptCode', locale.scriptCode!);
    }
    notifyListeners();
  }

  /* Widgets management */

  // Initialize the app from the background
  Future<void> initializeFromBackground(Uri data) async {
    updateWidgets();
  }

  // Update the war widget
  Future<void> updateWarWidget() async {
    try {
      await dotenv.load(fileName: ".env");
      
      // Get clan tag from the currently selected player
      clanTag = await getCurrentPlayerClanTag();
      
      // Fetch war data using the new API
      final warInfo = await fetchWarSummary(clanTag);
      
      // Save the war info to SharedPreferences for the widget
      await HomeWidget.saveWidgetData<String>('warInfo', warInfo);
      
      // Update the widget
      await HomeWidget.updateWidget(
        name: 'WarAppWidgetProvider',
        androidName: 'WarAppWidgetProvider',
      );
      
      print("✅ War widget updated successfully");
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      print("❌ Error updating war widget: $exception");
    }
  }

  // Get the clan tag from the currently selected player
  Future<String?> getCurrentPlayerClanTag() async {
    // Use the implementation from WarWidgetService
    return await WarWidgetService.getCurrentPlayerClanTag();
  }

  // Update the widgets
  void updateWidgets() async {
    if (!kIsWeb && Platform.isAndroid) {
      await updateWarWidget();
    }
  }

}
