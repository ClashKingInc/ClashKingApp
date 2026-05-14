import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/constants/global_keys.dart';
import 'package:clashkingapp/features/auth/presentation/startup_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'dart:async';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/services/war_widget_sync_service.dart';
import 'package:clashkingapp/core/theme/theme_notifier.dart';

@pragma("vm:entry-point")
FutureOr<void> backgroundCallback(Uri? data) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (data != null) {
    await const WarWidgetSyncService().initializeFromBackground(data);
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  static final ThemeData darkTheme = ThemeData(
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
    cardTheme: CardThemeData(
      surfaceTintColor: Colors.transparent,
      color: Color.fromARGB(255, 31, 31, 31).withValues(alpha: 1.0),
      elevation: 2.0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Color.fromARGB(255, 31, 31, 31),
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
    ),
    canvasColor: Colors.transparent,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFD90709),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 5,
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Color.fromARGB(255, 2, 108, 194),
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.all(8),
      labelStyle: TextStyle(
        fontSize: 16,
        color: Color(0xFFFFFFFF),
        decorationColor: Color(0xFFD90709),
      ),
      hintStyle: TextStyle(
        backgroundColor: Colors.transparent,
        fontSize: 16,
        color: Colors.grey,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color.fromARGB(255, 31, 31, 31),
      primary: Color(0xFFD90709),
      secondary: Color.fromARGB(255, 2, 108, 194),
      tertiary: Colors.grey,
      surface: Color.fromARGB(255, 31, 31, 31),
      error: Color.fromARGB(255, 255, 0, 0),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFFFFFFFF),
      onError: Color(0xFFFFFFFF),
      brightness: Brightness.dark,
    ),
    brightness: Brightness.dark,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      bodySmall: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      titleLarge: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      labelLarge: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: Colors.white, fontSize: 8, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
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
    cardTheme: CardThemeData(
      surfaceTintColor: Colors.transparent,
      color: Color(0xFFFFFFFF).withAlpha(255),
      elevation: 2.0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFBF0000),
        foregroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 5,
        textStyle: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Color.fromARGB(255, 3, 82, 147),
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.all(8),
      labelStyle: TextStyle(
        fontSize: 16,
        color: Color(0xFF000000),
        decorationColor: Color.fromARGB(255, 3, 82, 147),
      ),
      hintStyle: TextStyle(
        backgroundColor: Colors.transparent,
        fontSize: 16,
        color: Color(0xFF757575),
        overflow: TextOverflow.ellipsis,
      ),
    ),
    canvasColor: Colors.transparent,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFFFFFFFF),
      primary: Color(0xFFBF0000),
      secondary: Color.fromARGB(255, 3, 82, 147),
      tertiary: Color(0xFF757575),
      surface: Color(0xFFFFFFFF),
      error: Color(0xFFB00020),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
      brightness: Brightness.light,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      bodySmall: TextStyle(color: Colors.black, fontSize: 12, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      titleLarge: TextStyle(color: Colors.black, fontSize: 24, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      labelLarge: TextStyle(color: Colors.black, fontSize: 12, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: Colors.black, fontSize: 10, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: Colors.black, fontSize: 8, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState>(
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
          darkTheme: darkTheme,
          theme: lightTheme,
          home: StartupWidget(),
        );
      },
    );
  }
}
