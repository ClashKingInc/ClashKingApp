import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/core/my_app.dart';
import 'package:provider/provider.dart';

Future main() async {
  await dotenv.load(); // Charge le fichier .env
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => MyAppState()),
      ],
      child: MyApp(),
    ),);
}



