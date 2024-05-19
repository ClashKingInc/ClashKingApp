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
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';
import 'package:clashkingapp/api/current_league_info.dart';

@pragma("vm:entry-point")
FutureOr<void> backgroundCallback(Uri? data) async {
  // Assuming MyAppState is available and correctly managing state
  WidgetsFlutterBinding.ensureInitialized();
  final myAppState = MyAppState();
  if (data != null) {
    await myAppState.initializeFromBackground(data);
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    HomeWidget.registerInteractivityCallback(backgroundCallback);
    return ChangeNotifierProvider(
        create: (context) => MyAppState(),
        child: Consumer<MyAppState>(builder: (context, appState, child) {
          return MaterialApp(
            darkTheme: ThemeData(
              cardTheme: CardTheme(
                surfaceTintColor: Colors.transparent,
                color: Color.fromARGB(255, 31, 31, 31)
                    .withOpacity(1.0), // 1.0 means 100% opacity
                elevation: 2.0,
              ),
              canvasColor: Colors.transparent,
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  surfaceTintColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 5,
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.all(8),
                labelStyle: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
                  color: Color(0xFFFFFFFF),
                  decorationColor: Color(0xFFC98910),
                ),
                hintStyle: TextStyle(
                    backgroundColor: Colors.transparent,
                    fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
                    color: Colors.grey,
                    overflow: TextOverflow.ellipsis),
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: Color.fromARGB(
                    255, 31, 31, 31), // primary color as the seed
                primary: Color(0xFFC98910),
                secondary: Color(0xFF9B1F28),
                tertiary: Colors.grey,
                background: Color.fromARGB(255, 61, 60, 60),
                surface: Color.fromARGB(255, 31, 31, 31),
                error: Color.fromARGB(255, 255, 0, 0),
                onPrimary:
                    Color(0xFFFFFFFF), // Text color on top of primary color
                onSecondary:
                    Color(0xFFFFFFFF), // Text color on top of secondary color
                onBackground:
                    Color(0xFFFFFFFF), // Typically white text for readibility
                onSurface:
                    Color(0xFFFFFFFF), // Typically white text for readibility
                onError: Color(0xFFFFFFFF), // White text on top of error color
              ),
              textTheme: TextTheme(
                bodyLarge: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                bodyMedium: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                bodySmall: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                titleLarge: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                titleMedium: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                titleSmall: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                labelLarge: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                labelMedium: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                labelSmall: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
              ),
            ),
            themeMode: Provider.of<ThemeNotifier>(context).themeMode,
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
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  surfaceTintColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 5,
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.all(8),
                labelStyle: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
                  color: Theme.of(context).colorScheme.onBackground,
                  decorationColor: Theme.of(context).colorScheme.secondary,
                ),
                hintStyle: TextStyle(
                    backgroundColor: Colors.transparent,
                    fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
                    color: Theme.of(context).colorScheme.tertiary,
                    overflow: TextOverflow.ellipsis),
              ),
              canvasColor: Colors.transparent,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Color(0xFFFFFFFF), // primary color as the seed
                primary: Color(0xFFC98910),
                secondary: Color(0xFF9B1F28),
                tertiary: Colors.grey[600],
                background: Color(0xFFFFF8E1),
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
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500),
                labelMedium: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
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

class ThemeNotifier with ChangeNotifier {
  late ThemeMode _themeMode;

  ThemeNotifier() {
    _themeMode = ThemeMode.system;
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? themeModeString = prefs.getString('themeMode');
    if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await prefs.setString('themeMode', 'light');
    } else {
      _themeMode = ThemeMode.dark;
      await prefs.setString('themeMode', 'dark');
    }
    notifyListeners();
  }
}

class MyAppState extends ChangeNotifier with WidgetsBindingObserver {
  PlayerAccounts? playerAccounts;
  PlayerAccountInfo? playerStats;
  ClanInfo? clanInfo;
  CurrentWarInfo? currentWarInfo;
  DiscordUser? user;
  Future<void>? initializeUserFuture;
  ValueNotifier<String?> selectedTag = ValueNotifier<String?>(null);
  String? clanTag;

  MyAppState() {
    WidgetsBinding.instance.addObserver(this);
    if (selectedTag.value != null) {
      selectedTag.value = user!.tags.first;
      selectedTag.addListener(reloadData);
      selectedTag.addListener(updateWidgets);
    }
    _loadLanguage();
    Workmanager().registerPeriodicTask(
      '1',
      'simplePeriodicTask',
      frequency: Duration(minutes: 15),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Locale _locale = Locale('en');

  void _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('languageCode');
    _locale = languageCode != null ? Locale(languageCode) : Locale('en');
    notifyListeners();
  }

  void changeLanguage(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _locale = Locale(languageCode);
    await prefs.setString('languageCode', languageCode);
    notifyListeners();
  }

  Locale get locale => _locale;

  Future<void> initializeFromBackground(Uri data) async {
    // Process the data or update the widget
    updateWidgets();
  }

  Future<void> updateWarWidget() async {
    if (clanTag == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      clanTag = prefs.getString('clanTag');
    }
    if (clanTag != null) {
      final warInfo = await checkCurrentWar(clanTag!);
      // Send data to the widget
      await HomeWidget.saveWidgetData<String>('warInfo', warInfo);
      // Request the Home Widget to update
      await HomeWidget.updateWidget(
        name: 'WarAppWidgetProvider',
        androidName: 'WarAppWidgetProvider',
      );
    }
  }

  void updateWidgets() async {
    await updateWarWidget();
  }

  Future<String> checkCurrentWar(String clanTag) async {
    CurrentWarInfo? currentWarInfo;
    String time = "";
    print("Checking current war for $clanTag");

    final responseWar = await http.get(
      Uri.parse(
          'https://api.clashking.xyz/v1/clans/${clanTag.replaceAll('#', '%23')}/currentwar'),
    );

    final responseCwl = await http.get(
      Uri.parse(
          'https://api.clashking.xyz/v1/clans/${clanTag.replaceAll('#', '%23')}/currentwar/leaguegroup'),
    );

    if (responseWar.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(responseWar.bodyBytes));
      if (decodedResponse["state"] != "notInWar" &&
          decodedResponse["reason"] != "accessDenied") {
        currentWarInfo = CurrentWarInfo.fromJson(
            jsonDecode(utf8.decode(responseWar.bodyBytes)), "war");
      } else if (decodedResponse["state"] == "notInWar") {
        print("Not in war");
        DateTime now = DateTime.now();
        if (now.day >= 1 && now.day <= 10) {
          print("Checking CWL");
          if (responseCwl.statusCode == 200) {
            print("CWL response 200");
            var decodedResponseCwl =
                jsonDecode(utf8.decode(responseCwl.bodyBytes));
            if (decodedResponseCwl.containsKey("state")) {
              print("CWL state found");
              CurrentLeagueInfo currentLeagueInfo =
                  CurrentLeagueInfo.fromJson(decodedResponseCwl);
              CurrentWarInfo? inWar;
              CurrentWarInfo? inPreparation;
              CurrentWarInfo? lastMatchedWarInfo;

              for (var round in currentLeagueInfo.rounds) {
                List<CurrentWarInfo> warLeagueInfos =
                    await round.warLeagueInfos;

                for (var warInfo in warLeagueInfos) {
                  if (warInfo.clan.tag == clanTag ||
                      warInfo.opponent.tag == clanTag) {
                    lastMatchedWarInfo =
                        warInfo; // Store the last matched warInfo

                    if (warInfo.state == 'inWar') {
                      print("state : ${warInfo.state}");
                      inWar = warInfo;
                    } else if (warInfo.state == 'preparation') {
                      inPreparation = warInfo;
                    }
                  }
                }
              }

              currentWarInfo = inWar ?? inPreparation ?? lastMatchedWarInfo;
            } else {
              var result = {
                "updatedAt":
                    "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
                "timeState": time,
                "state": "error"
              };
              return jsonEncode(result);
            }
          } else {
            var result = {
              "updatedAt":
                  "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
              "timeState": time,
              "state": "error"
            };
            return jsonEncode(result);
          }
        } else {
          var result = {
            "updatedAt":
                "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
            "timeState": time,
            "state": "notInWar"
          };
          return jsonEncode(result);
        }
      } else {
        var result = {
          "updatedAt":
              "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
          "timeState": time,
          "state": "notInWar"
        };
        return jsonEncode(result);
      }

      print("Current war info: ${currentWarInfo?.state}");
      // Accessing time details
      if (currentWarInfo?.state == "preparation") {
        String formattedTime =
            DateFormat('HH:mm').format(currentWarInfo!.startTime.toLocal());
        time = "Starts at $formattedTime";
      } else if (currentWarInfo?.state == "inWar") {
        String formattedTime =
            DateFormat('HH:mm').format(currentWarInfo!.endTime.toLocal());
        time = "Ends at $formattedTime";
      } else if (currentWarInfo?.state == "warEnded") {
        time = "War Ended";
      }

      var result = {
        "updatedAt": "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
        "timeState": time,
        "score": currentWarInfo?.state == "preparation"
            ? "-"
            : "${currentWarInfo?.clan.stars} - ${currentWarInfo?.opponent.stars}",
        "clan": {
          "name": currentWarInfo?.clan.name,
          "badgeUrlMedium": currentWarInfo?.clan.badgeUrls.medium,
          "percent":
              "${currentWarInfo?.clan.destructionPercentage.toStringAsFixed(2)}%",
          "attacks":
              "${currentWarInfo?.clan.attacks}/${currentWarInfo?.teamSize}"
        },
        "opponent": {
          "name": currentWarInfo?.opponent.name,
          "badgeUrlMedium": currentWarInfo?.opponent.badgeUrls.medium,
          "percent":
              "${currentWarInfo?.opponent.destructionPercentage.toStringAsFixed(2)}%",
          "attacks":
              "${currentWarInfo?.opponent.attacks}/${currentWarInfo?.teamSize}"
        }
      };
      // Convert the Map object to a JSON string
      var jsonString = jsonEncode(result);

      // Return the JSON string
      return jsonString;
    } else {
      var result = {
        "updatedAt": "Updated at ${DateFormat('HH:mm').format(DateTime.now())}",
        "timeState": time,
        "state": "error"
      };
      return jsonEncode(result);
    }
  }

  bool isLoading = false;

  Future<void> reloadUsersAccounts() async {
    isLoading = true;
    notifyListeners();
    if (user!.isDiscordUser) {
      await initializeUser();
    }
    if (user != null) {
      if (user!.isDiscordUser) {
        await fetchUserTags(user!);
      }
      print("userTag : ${user!.tags}");
      await fetchPlayerAccounts(user!);
      reloadData();
      selectedTag.value = user!.tags.first;
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
    selectedTag.value ??= user!.tags.first;
    if (selectedTag.value != null) {
      print("Selected tag: ${selectedTag.value}");
      playerStats = playerAccounts?.playerAccountInfo
          .firstWhere((element) => element.tag == selectedTag.value);
      clanTag = playerStats?.clan.tag;
      clanInfo = playerAccounts?.clanInfo
          .firstWhere((element) => element.tag == playerStats?.clan.tag);

      final response = await http.get(
        Uri.parse(
            'https://api.clashofclans.com/v1/clans/${playerStats?.tag.replaceAll('#', '%23')}/currentwar'),
      );

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        if (decodedResponse["state"] != "notInWar") {
          // Correctly check the "state" field as a string
          currentWarInfo = playerAccounts?.warInfo.firstWhere(
              (element) => element.clan.tag == playerStats?.clan.tag);
        }
      }

      // After fetching new data, check if the selectedTag.value still exists in the new items
      if (playerAccounts?.playerAccountInfo
              .any((element) => element.tag == selectedTag.value) !=
          true) {
        // The current value is not in the new items list
        if (playerAccounts?.playerAccountInfo.isNotEmpty == true) {
          print("Selected tag not found in new items");
          // Safely setting the first available tag as the new value
          selectedTag.value = playerAccounts!.playerAccountInfo.first.tag;
        } else {
          print("No valid items found");
          // Handle the case where there are no valid items
          selectedTag.value = null;
        }
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('clanTag', clanTag!);
    }
    notifyListeners();
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
      currentWarInfo =
          await CurrentWarService().fetchCurrentWarInfo(tag, "war");
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
      final accessToken = await getAccessToken();
      print("Access token: $accessToken");
      if (accessToken != null) {
        user = await fetchDiscordUser(accessToken);
        notifyListeners();
      }
    } else {
      print("Token non valide ou absent.");
    }
  }
}
