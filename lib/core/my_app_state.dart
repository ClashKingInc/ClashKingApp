import 'package:clashkingapp/classes/account/user.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/widgets/widgets_functions.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:clashkingapp/l10n/locale.dart';
import 'package:clashkingapp/core/startup_widget.dart';
import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MyAppState extends ChangeNotifier with WidgetsBindingObserver {
  User? user;
  Future<void>? initializeUserFuture;
  String? clanTag;
  Account? account;
  Accounts? accounts;
  ValueNotifier<String?> selectedTagNotifier = ValueNotifier<String?>(null);

  Locale _locale = Locale('en'); // Default language is English
  Locale get locale => _locale; // Getter for the locale
  bool isLoading = false; // Loading state of the app

  MyAppState() {
    // Initialize the default page to first tag
    WidgetsBinding.instance.addObserver(this);

    _loadLanguage(); // Load the language from the shared preferences

    // Initialize the refresh of the war widget every 15 minutes
    Workmanager().registerPeriodicTask(
      '1',
      'simplePeriodicTask',
      frequency: Duration(minutes: 15),
    );
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
      if (supportedLocaleInfo.languageCode == locale.languageCode) {
        return Locale(supportedLocaleInfo.languageCode); // Return if supported
      }
    }
    return Locale('en'); // Fallback to English
  }

// Load the language from the shared preferences or set to the system locale
  void _loadLanguage() async {
    String? languageCode = await getPrefs('languageCode');

    if (languageCode != null) {
      // If there is a language code saved, use it if supported
      Locale userLocale = Locale(languageCode);
      _locale = _getLocaleFallback(userLocale);
    } else {
      // No saved language code, so use the system locale if supported
      Locale systemLocale = Locale(WidgetsBinding
          .instance.platformDispatcher.locales.first.languageCode);
      _locale = _getLocaleFallback(systemLocale);
    }

    notifyListeners();
  }

  // Change the language of the app
  void changeLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    await storePrefs('languageCode', languageCode);
    notifyListeners();
  }

  /* Widgets management */

  // Initialize the app from the background
  Future<void> initializeFromBackground(Uri data) async {
    updateWidgets();
  }

  // Update the war widget
  Future<void> updateWarWidget() async {
    await dotenv.load(fileName: ".env");
    clanTag = await getPrefs('clanTag');
    if (clanTag != "") {
      clanTag = clanTag?.replaceAll('#', '%23');
    }
    final warInfo = await checkCurrentWar(clanTag);
    try {
      // Send data to the widget
      await HomeWidget.saveWidgetData<String>('warInfo', warInfo);
      // Request the Home Widget to update
      await HomeWidget.updateWidget(
        name: 'WarAppWidgetProvider',
        androidName: 'WarAppWidgetProvider',
      );
    } catch (exception, stackTrace) {
      final hint = Hint.withMap({
        'clanTag': clanTag,
        'warInfo': warInfo,
      });
      Sentry.captureException(exception, stackTrace: stackTrace, hint: hint);
    }
  }

  // Update the widgets
  void updateWidgets() async {
    await updateWarWidget();
  }

  /* User management */

  // Reload the user accounts
  Future<void> reloadUsersAccounts(BuildContext context) async {
    if (user != null) {
      if (user!.isDiscordUser) {
        await initializeDiscordUser(context);
        await fetchDiscordUserTags(user!);
      }
      accounts = await AccountsService().fetchAccounts(user!);
      account = accounts!.findAccountBySelectedTag();

      if (account != null && account!.profileInfo.clan != null) {
        await storePrefs('clanTag', account!.profileInfo.clan!.tag);
      } else {
        await storePrefs('clanTag', '');
      }
      await Future.wait(accounts!.list.map((account) async {
        while (account.profileInfo.initialized != true) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      }));

      selectedTagNotifier.value = accounts?.selectedTag.value;
      updateWidgets();
    }
    notifyListeners();
  }

  Future<bool> initializeData() async {
    try {
      accounts = await AccountsService().fetchAccounts(user!);
      account = accounts!.findAccountBySelectedTag();

      if (account != null && account!.profileInfo.clan != null) {
        await storePrefs('clanTag', account!.profileInfo.clan!.tag);
      } else {
        await storePrefs('clanTag', '');
      }

      selectedTagNotifier.value = accounts?.selectedTag.value;
      updateWidgets();
      notifyListeners();
      return true;
    } catch (exception, stackTrace) {
      final hint = Hint.withMap({
        'custom_message': 'Error during initializeData execution',
        'user': user,
        'accounts': accounts,
        'selected_account': account,
      });
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: hint,
      );
      return false;
    }
  }

  /* User initialization at the opening of the app : Guest or Discord User */

  Future<void> initializeDiscordUser(BuildContext context) async {
    NavigatorState navigator = Navigator.of(context);
    final accessToken = await getPrefs("access_token");
    bool tokenValid = await isTokenValid();
    if (accessToken != null && tokenValid) {
      user = await fetchDiscordUser(accessToken);
      if (user != null) {
        notifyListeners();
      } else {
        clearPrefs();
        navigator.push(MaterialPageRoute(builder: (_) => StartupWidget()));
      }
    } else {
      clearPrefs();
      navigator.push(MaterialPageRoute(builder: (_) => StartupWidget()));
    }
  }

  // Initialize the user as a guest user
  Future<void> initializeGuestUser() async {
    final username = await getPrefs('username');
    user = User(
      id: '0',
      avatar: 'https://clashkingfiles.b-cdn.net/logos/crown-arrow-white-bg/ClashKing-2.png',
      globalName: username ?? 'ILoveClashKing',
    );

    user = await fetchGuestUserTags(user!);

    notifyListeners();
  }
}
