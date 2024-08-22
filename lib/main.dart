import 'dart:async';
import 'package:clashkingapp/classes/data/gears_data_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/core/my_app.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/core/theme_notifier.dart';
import 'package:clashkingapp/classes/data/league_data_manager.dart';
import 'package:clashkingapp/classes/data/player_league_data_manager.dart';
import 'package:clashkingapp/classes/data/troops_data_manager.dart';
import 'package:clashkingapp/classes/data/pets_data_manager.dart';
import 'package:clashkingapp/classes/data/heroes_data_manager.dart';
import 'package:clashkingapp/classes/data/spells_data_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// CallbackDispatcher for background execution (Android only)
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    final myAppState = MyAppState();
    await myAppState.updateWarWidget();
    return Future.value(true);
  });
}

Future<void> main() async {
  await dotenv.load(fileName: ".env"); // Load .env file
  WidgetsFlutterBinding
      .ensureInitialized(); // Required by Workmanager to ensure binding is initialized
  Workmanager().initialize(
      callbackDispatcher); // Required by Workmanager to initialize the callback dispatcher
  Future.wait([
    LeagueDataManager().loadLeagueData(),
    TroopDataManager().loadTroopsData(),
    PlayerLeagueDataManager().loadLeagueData(),
    GearDataManager().loadGearsData(),
    HeroesDataManager().loadHeroesData(),
    SpellsDataManager().loadSpellsData(),
    PetsDataManager().loadPetsData(),
  ]);
  FlutterNativeSplash.remove();

  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'];
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => ThemeNotifier()), // ThemeNotifier (Theme data)
          ChangeNotifierProvider(
              create: (_) => MyAppState()), // MyAppState (User data)
        ],
        child: MyApp(),
      ),
    ),
  );
}
