import 'package:clashkingapp/api/user_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/api/player_accounts_list.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/widgets/widgets_functions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:clashkingapp/l10n/locale.dart';
import 'package:clashkingapp/main_pages/login_page/login_page.dart';

class MyAppState extends ChangeNotifier with WidgetsBindingObserver {
  PlayerAccounts? playerAccounts;
  PlayerAccountInfo? playerStats;
  ClanInfo? clanInfo;
  CurrentWarInfo? currentWarInfo;
  User? user;
  Future<void>? initializeUserFuture;
  ValueNotifier<String?> selectedTag = ValueNotifier<String?>(null);
  String? clanTag;

  Locale _locale = Locale('en'); // Default language is English
  Locale get locale => _locale; // Getter for the locale
  bool isLoading = false; // Loading state of the app

  MyAppState() {
    // Initialize the default page to first tag
    WidgetsBinding.instance.addObserver(this);

    // Set initial tag to the first tag of the user
    if (user != null) {
      selectedTag.value ??= user!.tags.first;
    }
    selectedTag.addListener(reloadData);
    //selectedTag.addListener(updateWidgets);

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
      selectedTag.value = user!.tags.first;
      await fetchPlayerAccounts(user!);
      reloadData();
    }

    await Future.delayed(Duration(seconds: 1));
    isLoading = false;
    notifyListeners();
  }

  void refreshData() async {
    await fetchPlayerAccounts(user!);
    notifyListeners();
  }

  void reloadData() async {
    // Check if the selected tag is still valid after fetching new data
    if (!user!.tags.contains(selectedTag.value)) {
      selectedTag.value = user!.tags.first;
    }

    // Fetch the new data for playerStats, clanInfo and currentWarInfo
    if (selectedTag.value != null) {
      playerStats = playerAccounts?.playerAccountInfo
          .firstWhere((element) => element.tag == selectedTag.value);

      // Save the clan tag in the shared preferences for the widget
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (playerStats != null && playerStats?.clan != null) {
        await prefs.setString('clanTag', playerStats!.clan!.tag);
      } else {
        await prefs.setString('clanTag', '');
      }
      updateWidgets();

      if (playerStats?.clan != null) {
        // Fetch the clan info from the clan tag
        clanInfo = playerAccounts?.clanInfo!
            .firstWhere((element) => element.tag == playerStats?.clan!.tag);

        // Fetch the current war info if the player is in war
        final response = await http.get(
          Uri.parse(
              'https://api.clashofclans.com/v1/clans/${playerStats?.tag.replaceAll('#', '%23')}/currentwar'),
        );

        if (response.statusCode == 200) {
          var decodedResponse = jsonDecode(response.body);
          if (decodedResponse["state"] != "notInWar") {
            currentWarInfo = playerAccounts?.warInfo.firstWhere(
                (element) => element.clan.tag == playerStats?.clan!.tag);
          }
        }
      } else {
        clanInfo = null;
      }
    }
    notifyListeners();
  }

  /* Fetch data from the API to initialize User accounts data*/

  // Fetch the player accounts from the user tags
  Future<void> fetchPlayerAccounts(User user) async {
    try {
      playerAccounts = await PlayerService().fetchPlayerAccounts(user);
      reloadData();
    } catch (e) {
      throw Exception('Failed to load player accounts: $e');
    }
  }

  // Fetch the clan info from clan tag
  Future<void> fetchClanInfo(String tag) async {
    try {
      clanInfo = await ClanService().fetchClanInfo(tag);
      notifyListeners(); // Notify listeners to rebuild widgets that depend on clanInfo.
    } catch (e) {
      throw Exception('Failed to load clan info: $e');
    }
  }

  // Fetch the current war info from clan tag
  Future<void> fetchCurrentWarInfo(String tag) async {
    try {
      currentWarInfo =
          await CurrentWarService().fetchCurrentWarInfo(tag, "war");
      notifyListeners(); // Notify listeners to rebuild widgets that depend on currentWarInfo.
    } catch (e) {
      throw Exception('Failed to load current war info: $e');
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
