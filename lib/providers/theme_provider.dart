import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 1.0;
  bool _reduceMotion = false;
  bool _highContrast = false;
  bool _isRTL = false;
  String _selectedLanguage = 'en';

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  bool get reduceMotion => _reduceMotion;
  bool get highContrast => _highContrast;
  bool get isRTL => _isRTL;
  String get selectedLanguage => _selectedLanguage;

  set isDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  set fontSize(double value) {
    _fontSize = value;
    notifyListeners();
  }

  set reduceMotion(bool value) {
    _reduceMotion = value;
    notifyListeners();
  }

  set highContrast(bool value) {
    _highContrast = value;
    notifyListeners();
  }

  set isRTL(bool value) {
    _isRTL = value;
    notifyListeners();
  }

  set selectedLanguage(String value) {
    _selectedLanguage = value;
    // Update RTL based on language
    _isRTL = ['ar', 'he', 'fa', 'ur'].contains(value);
    notifyListeners();
  }

  ThemeData getTheme() {
    var theme = AppTheme.getTheme(_isDarkMode ? Brightness.dark : Brightness.light);
    
    // Apply font size scaling
    theme = theme.copyWith(
      textTheme: theme.textTheme.apply(
        fontSizeFactor: 1.0 + (_fontSize - 1.0) * 0.2,
      ),
    );

    // Apply high contrast if enabled
    if (_highContrast) {
      theme = theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: Colors.yellow,
          secondary: Colors.white,
        ),
        textTheme: theme.textTheme.copyWith(
          bodyLarge: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return theme;
  }

  // Load theme settings from shared preferences
  Future<void> loadSettings() async {
    // TODO: Implement loading from SharedPreferences
    notifyListeners();
  }

  // Save theme settings to shared preferences
  Future<void> saveSettings() async {
    // TODO: Implement saving to SharedPreferences
  }
}