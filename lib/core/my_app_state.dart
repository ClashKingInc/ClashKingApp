import 'package:clashkingapp/classes/account/user.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/widgets/widgets_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:clashkingapp/l10n/locale.dart';
import 'package:clashkingapp/main_pages/login_page/login_page.dart';
import 'package:clashkingapp/classes/account/accounts.dart';

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('languageCode');

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _locale = Locale(languageCode);
    await prefs.setString('languageCode', languageCode);
    notifyListeners();
  }

  /* Widgets management */

  // Initialize the app from the background
  Future<void> initializeFromBackground(Uri data) async {
    updateWidgets();
  }

  // Update the war widget
  Future<void> updateWarWidget() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    clanTag = prefs.getString('clanTag');
    final warInfo = await checkCurrentWar(clanTag);
    try {
      // Send data to the widget
      await HomeWidget.saveWidgetData<String>('warInfo', warInfo);
      // Request the Home Widget to update
      await HomeWidget.updateWidget(
        name: 'WarAppWidgetProvider',
        androidName: 'WarAppWidgetProvider',
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  // Update the widgets
  void updateWidgets() async {
    await updateWarWidget();
  }

  /* User management */

  // Reload the user accounts
  Future<void> reloadUsersAccounts(context) async {
    isLoading = true; // Set the loading state to true

    notifyListeners();

    if (user!.isDiscordUser) {
      await initializeDiscordUser(context);
    }
    if (user != null) {
      if (user!.isDiscordUser) {
        await fetchDiscordUserTags(user!);
      }
      accounts!.selectedTag = ValueNotifier<String?>(user!.tags.first);
      accounts = await AccountsService().fetchAccounts(user!);
      initializeData();
    }

    await Future.delayed(Duration(seconds: 1));
    isLoading = false;
    notifyListeners();
  }

  void refreshData() async {
    await AccountsService().fetchAccounts(user!);
    notifyListeners();
  }

  Future<bool> initializeData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      accounts = await AccountsService().fetchAccounts(user!);

      // Check if the selected tag is still valid after fetching new data
      if (!user!.tags.contains(accounts!.selectedTag.value)) {
        accounts!.selectedTag = ValueNotifier<String?>(user!.tags.first);
      }
      account = accounts!.findAccountBySelectedTag();
      if (account != null && account!.profileInfo.clan != null) {
        await prefs.setString('clanTag', account!.profileInfo.clan!.tag);
      } else {
        await prefs.setString('clanTag', '');
      }
      updateWidgets();
      notifyListeners();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /* User initialization at the opening of the app : Guest or Discord User */

  Future<void> initializeDiscordUser(BuildContext context) async {
    NavigatorState navigator = Navigator.of(context);
    final accessToken = await getAccessToken();
    bool tokenValid = await isTokenValid();
    if (accessToken != null && tokenValid) {
      user = await fetchDiscordUser(accessToken);
      if (user != null) {
        notifyListeners();
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.clear();
        navigator
            .pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.clear();
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
    }
  }

  // Initialize the user as a guest user
  Future<void> initializeGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    user = User(
      id: '0',
      avatar: 'https://clashkingfiles.b-cdn.net/logos/ClashKing-crown-logo.png',
      globalName: username ?? 'ILoveClashKing',
    );

    user = await fetchGuestUserTags(user!);

    notifyListeners();
  }
}
