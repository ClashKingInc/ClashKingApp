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
    selectedTag.addListener(updateWidgets);

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

  // Load the language from the shared preferences
  void _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('languageCode');
    _locale = languageCode != null
        ? Locale(languageCode)
        : Locale('en'); // Default language is English
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
    if (clanTag == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      clanTag = prefs.getString('clanTag');
    }
    if (clanTag != null) {
      final warInfo = await checkCurrentWar(clanTag!);
      print("War info: $warInfo");
      // Send data to the widget
      await HomeWidget.saveWidgetData<String>('warInfo', warInfo);
      // Request the Home Widget to update
      await HomeWidget.updateWidget(
        name: 'WarAppWidgetProvider',
        androidName: 'WarAppWidgetProvider',
      );
    }
  }

  // Update the widgets
  void updateWidgets() async {
    if (clanTag != null) {
      await updateWarWidget();
    }
  }

  /* User management */

  // Reload the user accounts
  Future<void> reloadUsersAccounts() async {
    isLoading = true; // Set the loading state to true

    notifyListeners();

    if (user!.isDiscordUser) {
      await initializeDiscordUser();
    }
    if (user != null) {
      if (user!.isDiscordUser) {
        await fetchDiscordUserTags(user!);
      }
      selectedTag.value = user!.tags.first;
      await fetchPlayerAccounts(user!);
      reloadData();
    } else {
      print("User is null");
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
    print("Reloading data");

    // Check if the selected tag is still valid after fetching new data
    if (!user!.tags.contains(selectedTag.value)) {
      selectedTag.value = user!.tags.first;
    }

    // Fetch the new data for playerStats, clanInfo and currentWarInfo
    if (selectedTag.value != null) {
      print("Selected tag: ${selectedTag.value}");

      playerStats = playerAccounts?.playerAccountInfo
          .firstWhere((element) => element.tag == selectedTag.value);

      if (playerStats?.clan != null) {

        // Fetch the clan info from the clan tag
        clanInfo = playerAccounts?.clanInfo!
            .firstWhere((element) => element.tag == playerStats?.clan!.tag);
          
        // Save the clan tag in the shared preferences for the widget
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('clanTag', playerStats?.clan!.tag ?? '');

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
      notifyListeners(); // Notify listeners to rebuild widgets that depend on playerStats.
    } catch (e, s) {
      print("Error fetching player stats: $e");
      print("Stack trace: $s");
    }
  }

  // Fetch the clan info from clan tag
  Future<void> fetchClanInfo(String tag) async {
    try {
      clanInfo = await ClanService().fetchClanInfo(tag);
      notifyListeners(); // Notify listeners to rebuild widgets that depend on clanInfo.
    } catch (e, s) {
      print("Error fetching clan info: $e");
      print("Stack trace: $s");
    }
  }

  // Fetch the current war info from clan tag
  Future<void> fetchCurrentWarInfo(String tag) async {
    try {
      currentWarInfo =
          await CurrentWarService().fetchCurrentWarInfo(tag, "war");
      notifyListeners(); // Notify listeners to rebuild widgets that depend on currentWarInfo.
    } catch (e, s) {
      print("Error fetching current war info: $e");
      print("Stack trace: $s");
    }
  }

  /* User initialization at the opening of the app : Guest or Discord User */

  // Initialize the user as a Discord user
  Future<void> initializeDiscordUser() async {
    bool validToken = await isTokenValid(); // Check if the token is valid
    if (validToken) {
      final accessToken = await getAccessToken();
      if (accessToken != null) {
        user = await fetchDiscordUser(accessToken);
        notifyListeners();
      }
    } else {
      print("Token non valide ou absent.");
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
