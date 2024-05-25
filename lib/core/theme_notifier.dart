import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  late ThemeMode _themeMode;

  ThemeNotifier() {
    _themeMode = ThemeMode.system;
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? themeModeString = prefs.getString('themeMode');
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await prefs.setString('themeMode', 'light');
    } else {
      _themeMode = ThemeMode.dark;
      await prefs.setString('themeMode', 'dark');
    }
    notifyListeners();
  }
}
