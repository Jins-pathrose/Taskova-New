import 'package:flutter/cupertino.dart';

class ThemeProvider extends ChangeNotifier {
  bool _followSystemTheme = true;
  bool _isDarkMode = false;

  bool get followSystemTheme => _followSystemTheme;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _initializeSystemTheme();
    // Add listener for system theme changes
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (_followSystemTheme) {
        _updateThemeFromSystem();
      }
    };
  }

  void _initializeSystemTheme() {
    _updateThemeFromSystem();
  }

  void _updateThemeFromSystem() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final newDarkMode = brightness == Brightness.dark;
    if (_isDarkMode != newDarkMode) {
      _isDarkMode = newDarkMode;
      notifyListeners();
    }
  }

  void setFollowSystemTheme(bool follow) {
    _followSystemTheme = follow;
    if (follow) {
      _updateThemeFromSystem();
    }
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    _followSystemTheme = false;
    _isDarkMode = isDark;
    notifyListeners();
  }
}