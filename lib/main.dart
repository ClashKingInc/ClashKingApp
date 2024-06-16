import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/core/my_app.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/core/theme_notifier.dart';
import 'package:clashkingapp/api/league_data_manager.dart';
import 'package:clashkingapp/api/troop_data_manager.dart';

// CallbackDispatcher for background execution (Android only)
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final myAppState = MyAppState();
    await myAppState.updateWarWidget();
    return Future.value(true);
  });
}

Future main() async {
  await dotenv.load(); // Load .env file
  WidgetsFlutterBinding
      .ensureInitialized(); // Required by Workmanager to ensure binding is initialized
  Workmanager().initialize(
      callbackDispatcher); // Required by Workmanager to initialize the callback dispatcher

  await LeagueDataManager().loadLeagueData();
  await TroopDataManager().loadTroopData();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ThemeNotifier()), // ThemeNotifier (Theme data)
        ChangeNotifierProvider(
            create: (_) => MyAppState()), // MyAppState (User data)
      ],
      child: MyApp(),
    ),
  );
}
