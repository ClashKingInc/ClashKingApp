import 'dart:async';
import 'package:clashkingapp/classes/data/gears_data_manager.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/auth/data/user_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/core/app/my_app.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/theme/theme_notifier.dart';
import 'package:clashkingapp/classes/data/game_data_manager.dart';
import 'package:clashkingapp/classes/data/league_data_manager.dart';
import 'package:clashkingapp/classes/data/player_league_data_manager.dart';
import 'package:clashkingapp/classes/data/troops_data_manager.dart';
import 'package:clashkingapp/classes/data/pets_data_manager.dart';
import 'package:clashkingapp/classes/data/heroes_data_manager.dart';
import 'package:clashkingapp/classes/data/spells_data_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/foundation.dart';

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

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      options.tracesSampleRate = 1.0;
    },
    appRunner: () async {

      WidgetsFlutterBinding.ensureInitialized();

      await dotenv.load(fileName: ".env");

      if (!kIsWeb) {
        Workmanager().initialize(callbackDispatcher);
      }

      await Future.wait([
        GameDataManager().loadGameData().then((_) => print("✅ GameDataManager OK")),
        LeagueDataManager().loadLeagueData().then((_) => print("✅ LeagueDataManager OK")),
        TroopDataManager().loadTroopsData().then((_) => print("✅ TroopDataManager OK")),
        PlayerLeagueDataManager().loadLeagueData().then((_) => print("✅ PlayerLeagueDataManager OK")),
        GearDataManager().loadGearsData().then((_) => print("✅ GearDataManager OK")),
        HeroesDataManager().loadHeroesData().then((_) => print("✅ HeroesDataManager OK")),
        SpellsDataManager().loadSpellsData().then((_) => print("✅ SpellsDataManager OK")),
        PetsDataManager().loadPetsData().then((_) => print("✅ PetsDataManager OK")),
        GameDataService.loadGameData().then((_) => print("✅ GameDataService OK")),
      ]);

      FlutterNativeSplash.remove();
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeNotifier()),
            ChangeNotifierProvider(create: (_) => MyAppState()),
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => CocAccountService()),
            ChangeNotifierProvider(create: (_) => PlayerService()),
            ChangeNotifierProvider(create: (_) => ClanService()),
            ChangeNotifierProvider(create: (_) => WarCwlService()),
            Provider(create: (_) => ApiService()),
            Provider(create: (_) => UserService()),
            Provider(create: (_) => TokenService()),
          ],
          child: MyApp(),
        ),
      );
    },
  );
}

