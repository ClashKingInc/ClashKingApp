import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/core/my_app.dart';

Future main() async {
  await dotenv.load(); // Charge le fichier .env
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

