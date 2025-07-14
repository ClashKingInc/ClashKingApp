import 'package:flutter/material.dart';
import 'package:clashkingapp/core/functions/functions.dart';

class ThemeNotifier with ChangeNotifier {
  late ThemeMode _themeMode;

  ThemeNotifier() {
    _themeMode = ThemeMode.system;
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    String? themeModeString = await getPrefs('themeMode');
    if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await storePrefs('themeMode', 'light');
    } else {
      _themeMode = ThemeMode.dark;
      await storePrefs('themeMode', 'dark');
    }
    notifyListeners();
  }
}
