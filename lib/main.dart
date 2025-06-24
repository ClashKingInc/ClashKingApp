import 'dart:async';
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
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/foundation.dart';
import 'package:clashkingapp/widgets/war_widget.dart';

// CallbackDispatcher for background execution (Android only)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env");
      
      // Handle different background tasks
      if (task == 'simplePeriodicTask') {
        // Regular periodic widget update
        final myAppState = MyAppState();
        await myAppState.updateWarWidget();
      } else if (task == 'refreshWarWidget') {
        // Manual refresh from widget button
        await WarWidgetService.handleWidgetRefresh();
      }
      
      return Future.value(true);
    } catch (e) {
      print("❌ Background task error: $e");
      return Future.value(false);
    }
  });
}

Future<void> main() async {

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      options.tracesSampleRate = 1.0;
      options.debug = false;
    },
    appRunner: () async {

      WidgetsFlutterBinding.ensureInitialized();

      await dotenv.load(fileName: ".env");

      if (!kIsWeb) {
        Workmanager().initialize(callbackDispatcher);
        // Initialize war widget service for background callbacks
        WarWidgetService.initialize();
      }

      await Future.wait([
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

