import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/global_keys.dart';
import 'package:clashkingapp/core/startup_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:async';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/core/theme_notifier.dart';

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
    // Register the background callback for the Home Widget
    HomeWidget.registerInteractivityCallback(backgroundCallback);
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer<MyAppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
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
            // Dark theme
            darkTheme: ThemeData(
              scaffoldBackgroundColor: Color.fromARGB(255, 61, 60, 60),
              datePickerTheme: DatePickerThemeData(
                backgroundColor: Color.fromARGB(255, 61, 60, 60),
                surfaceTintColor: Colors.transparent,
                headerForegroundColor: Colors.white,
                headerBackgroundColor: Color(0xFFD90709),
                dayForegroundColor: WidgetStateProperty.all(Colors.white),
                yearForegroundColor: WidgetStateProperty.all(Colors.white),
                todayForegroundColor: WidgetStateProperty.all(Colors.white),
              ),
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
                  decorationColor: Color(0xFFD90709),
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
                primary: Color(0xFFD90709),
                secondary: Color.fromARGB(255, 2, 108, 194),
                tertiary: Colors.grey,
                surface: Color.fromARGB(255, 31, 31, 31),
                error: Color.fromARGB(255, 255, 0, 0),
                onPrimary:
                    Color(0xFFFFFFFF), // Text color on top of primary color
                onSecondary:
                    Color(0xFFFFFFFF), // Text color on top of secondary color
                onSurface:
                    Color(0xFFFFFFFF), // Typically white text for readibility
                onError: Color(0xFFFFFFFF), // White text on top of error color
                brightness: Brightness.dark,
              ),
              brightness: Brightness.dark,
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
            // Light theme
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: Color.fromARGB(255, 244, 244, 244),
              datePickerTheme: DatePickerThemeData(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                headerForegroundColor: Colors.white,
                headerBackgroundColor: Color(0xFFBF0000),
                dayForegroundColor: WidgetStateProperty.all(Colors.black),
                yearForegroundColor: WidgetStateProperty.all(Colors.black),
                todayForegroundColor: WidgetStateProperty.all(Colors.black),
              ),
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
                  color: Theme.of(context).colorScheme.onSurface,
                  decorationColor: Theme.of(context).colorScheme.secondary,
                ),
                hintStyle: TextStyle(
                    backgroundColor: Colors.transparent,
                    fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
                    color: Theme.of(context).colorScheme.tertiary,
                    overflow: TextOverflow.ellipsis),
              ),
              canvasColor: Colors.transparent,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Color(0xFFFFFFFF), // primary color as the seed
                primary: Color(0xFFBF0000),
                secondary:Color.fromARGB(255, 3, 82, 147),
                tertiary: Colors.grey[600],
                surface: Color(0xFFFFFFFF),
                error: Color(0xFFB00020),
                onPrimary:
                    Color(0xFFFFFFFF), // Text color on top of primary color
                onSecondary:
                    Color(0xFFFFFFFF), // Text color on top of secondary color
                onSurface:
                    Color(0xFF000000), // Typically black text for readibility
                onError: Color(0xFFFFFFFF), // White text on top of error color
                brightness: Brightness.light,
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
        },
      ),
    );
  }
}
