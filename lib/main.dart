import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/core/my_app.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Your background task goes here
    print('Background task executed');
    final myAppState = MyAppState();
    print('Updating widget at ${DateTime.now()}');
    await myAppState.updateWarWidget();
    return Future.value(true);
  });
}

Future main() async {
  await dotenv.load(); // Charge le fichier .env
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => MyAppState()),
      ],
      child: MyApp(),
    ),
  );
}
