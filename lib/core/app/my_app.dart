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
import 'package:sentry_flutter/sentry_flutter.dart';

@pragma("vm:entry-point")
FutureOr<void> backgroundCallback(Uri? data) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (data != null) {
    await const WarWidgetSyncService().initializeFromBackground(data);
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0B0B0C),
    primary: const Color(0xFFD90709),
    secondary: const Color.fromARGB(255, 2, 108, 194),
    tertiary: Colors.grey,
    surface: const Color(0xFF0B0B0C),
    error: const Color.fromARGB(255, 255, 0, 0),
    onPrimary: const Color(0xFFFFFFFF),
    onSecondary: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFFFFFFFF),
    onError: const Color(0xFFFFFFFF),
    brightness: Brightness.dark,
  );

  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFFFFFF),
    primary: const Color(0xFFBF0000),
    secondary: const Color.fromARGB(255, 3, 82, 147),
    tertiary: const Color(0xFF757575),
    surface: const Color(0xFFFFFFFF),
    error: const Color(0xFFB00020),
    onPrimary: const Color(0xFFFFFFFF),
    onSecondary: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF000000),
    onError: const Color(0xFFFFFFFF),
    brightness: Brightness.light,
  );

  static final ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFF030304),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: const Color(0xFF0B0B0C),
      surfaceTintColor: Colors.transparent,
      headerForegroundColor: Colors.white,
      headerBackgroundColor: const Color(0xFFD90709),
      dayForegroundColor: WidgetStateProperty.all(Colors.white),
      yearForegroundColor: WidgetStateProperty.all(Colors.white),
      todayForegroundColor: WidgetStateProperty.all(Colors.white),
    ),
    cardTheme: CardThemeData(
      surfaceTintColor: Colors.transparent,
      // Exact same material as the home to-do panels: surface shade,
      // radius 28, hairline outlineVariant border, no shadow.
      color: const Color(0xFF0B0B0C),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: _darkColorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF151516),
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 16),
    ),
    canvasColor: Colors.transparent,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD90709),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 5,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 2, 108, 194),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.all(8),
      labelStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xFFFFFFFF),
        decorationColor: Color(0xFFD90709),
      ),
      hintStyle: const TextStyle(
        backgroundColor: Colors.transparent,
        fontSize: 16,
        color: Colors.grey,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    colorScheme: _darkColorScheme,
    brightness: Brightness.dark,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      bodySmall: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color.fromARGB(255, 244, 244, 244),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      headerForegroundColor: Colors.white,
      headerBackgroundColor: const Color(0xFFBF0000),
      dayForegroundColor: WidgetStateProperty.all(Colors.black),
      yearForegroundColor: WidgetStateProperty.all(Colors.black),
      todayForegroundColor: WidgetStateProperty.all(Colors.black),
    ),
    cardTheme: CardThemeData(
      surfaceTintColor: Colors.transparent,
      color: const Color(0xFFFFFFFF).withAlpha(255),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: _lightColorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: TextStyle(color: Colors.black, fontSize: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFBF0000),
        foregroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 5,
        textStyle: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 3, 82, 147),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.all(8),
      labelStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xFF000000),
        decorationColor: Color.fromARGB(255, 3, 82, 147),
      ),
      hintStyle: const TextStyle(
        backgroundColor: Colors.transparent,
        fontSize: 16,
        color: Color(0xFF757575),
        overflow: TextOverflow.ellipsis,
      ),
    ),
    canvasColor: Colors.transparent,
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      bodySmall: TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      titleLarge: TextStyle(
        color: Colors.black,
        fontSize: 24,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      labelLarge: TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: Colors.black,
        fontSize: 10,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: Colors.black,
        fontSize: 8,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
      ),
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
          navigatorObservers: [SentryNavigatorObserver()],
          title: 'ClashKing',
          darkTheme: darkTheme,
          theme: lightTheme,
          home: StartupWidget(),
        );
      },
    );
  }
}
