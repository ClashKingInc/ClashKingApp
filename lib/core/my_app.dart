import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/global_keys.dart';
import 'package:clashkingapp/api/player_accounts_list.dart';
import 'package:clashkingapp/core/startup_widget.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => MyAppState(),
        child: Consumer<MyAppState>(builder: (context, appState, child) {
          return MaterialApp(
            locale: appState.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorKey: globalNavigatorKey,
            title: 'ClashKing',
            theme: ThemeData(
              useMaterial3: true,
              cardTheme: CardTheme(
                surfaceTintColor: Colors.transparent,
                color: Color(0xFFFFFFFF)
                    .withOpacity(1.0), // 1.0 means 100% opacity
                elevation: 2.0,
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: Color(0xFFFFFFFF), // primary color as the seed
                primary: Color(0xFFC98910),
                secondary: Color(0xFF9B1F28),
                tertiary: Color(0xFFFFF8E1),
                background: Color(0xFFFFFFFF),
                surface: Color(0xFFFFFFFF),
                error: Color(0xFFB00020),
                onPrimary:
                    Color(0xFFFFFFFF), // Text color on top of primary color
                onSecondary:
                    Color(0xFFFFFFFF), // Text color on top of secondary color
                onBackground:
                    Color(0xFF000000), // Typically black text for readibility
                onSurface:
                    Color(0xFF000000), // Typically black text for readibility
                onError: Color(0xFFFFFFFF), // White text on top of error color
              ),
              textTheme: TextTheme(
                bodyLarge: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                bodyMedium: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                bodySmall: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                titleLarge: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                titleMedium: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                titleSmall: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                labelLarge: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                labelMedium: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                labelSmall: TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
              ),
            ),
            home: StartupWidget(),
          );
        }));
  }
}

class MyAppState extends ChangeNotifier {
  PlayerAccounts? playerAccounts;
  PlayerAccountInfo? playerStats;
  ClanInfo? clanInfo;
  CurrentWarInfo? currentWarInfo;
  DiscordUser? user;
  Future<void>? initializeUserFuture;
  ValueNotifier<String?> selectedTag = ValueNotifier<String?>(null);

  MyAppState() {
    if (selectedTag.value != null) {
      print("playerAccounts: $playerAccounts");
      selectedTag.value = user!.tags.first;
      selectedTag.addListener(reloadData);
    }
  }

  Locale _locale = Locale('en');

  Locale get locale => _locale;

  void changeLanguage(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners();
  }

  void reloadData() async {
  if (selectedTag.value != null) {
    playerStats = playerAccounts?.playerAccountInfo.firstWhere((element) => element.tag == selectedTag.value);
    clanInfo = playerAccounts?.clanInfo.firstWhere((element) => element.tag == playerStats?.clan?.tag);

    final response = await http.get(
      Uri.parse('https://api.clashofclans.com/v1/clans/${playerStats?.tag.replaceAll('#', '%23')}/currentwar'),
      headers: {'Authorization': 'Bearer ${dotenv.env['API_KEY']}'},
    );

    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(response.body);
      if (decodedResponse["state"] != "notInWar") { // Correctly check the "state" field as a string
        currentWarInfo = playerAccounts?.warInfo?.firstWhere((element) => element.clan?.tag == playerStats?.clan?.tag);
      }
    }
    notifyListeners();
  }
}


  // Assume this method exists and fetches player stats correctly
  Future<void> fetchPlayerAccounts(DiscordUser user) async {
    try {
      playerAccounts = await PlayerService().fetchPlayerAccounts(user);
      reloadData();
      notifyListeners(); // Notify listeners to rebuild widgets that depend on playerStats.
    } catch (e, s) {
      // Handle the error, maybe log it or show a user-friendly message
      print("Error fetching player stats: $e");
      print("Stack trace: $s");
    }
  }

  // Assume this method exists and fetches clan correctly
  Future<void> fetchClanInfo(String tag) async {
    try {
      clanInfo = await ClanService().fetchClanInfo(tag);
      notifyListeners(); // Notify listeners to rebuild widgets that depend on clanInfo.
    } catch (e, s) {
      // Handle the error, maybe log it or show a user-friendly message
      print("Error fetching clan info: $e");
      print("Stack trace: $s");
    }
  }

  // Assume this method exists and fetches current war correctly
  Future<void> fetchCurrentWarInfo(String tag) async {
    try {
      currentWarInfo = await CurrentWarService().fetchCurrentWarInfo(tag);
      notifyListeners(); // Notify listeners to rebuild widgets that depend on currentWarInfo.
    } catch (e, s) {
      // Handle the error, maybe log it or show a user-friendly message
      print("Error fetching current war info: $e");
      print("Stack trace: $s");
    }
  }

  Future<void> initializeUser() async {
    bool validToken = await isTokenValid();
    if (validToken) {
      print("Token valide.");
      final accessToken = await getAccessToken();
      if (accessToken != null) {
        print("Access token : $accessToken");
        user = await fetchDiscordUser(accessToken);
        print("User: $user");
        notifyListeners();
      }
    } else {
      print("Token non valide ou absent.");
    }
  }
}
