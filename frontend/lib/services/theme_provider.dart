import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';

  AppTheme _currentTheme = AppTheme.catppuccinMocha;
  bool _isLoaded = false;

  AppTheme get currentTheme => _currentTheme;
  ThemeData get themeData => AppThemes.getTheme(_currentTheme);
  bool get isLoaded => _isLoaded;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      if (themeIndex != null && themeIndex < AppTheme.values.length) {
        _currentTheme = AppTheme.values[themeIndex];
      }
    } catch (e) {
      // Use default theme on error
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, theme.index);
    } catch (e) {
      // Theme change still works even if persistence fails
    }
  }
}
