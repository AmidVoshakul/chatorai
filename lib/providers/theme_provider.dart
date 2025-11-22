import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _reduceMotionKey = 'reduce_motion';
  static const String _highContrastKey = 'high_contrast';
  static const String _languageKey = 'selected_language';

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

  ThemeProvider() {
    loadSettings();
  }

  set isDarkMode(bool value) {
    _isDarkMode = value;
    saveSettings();
    notifyListeners();
  }

  set fontSize(double value) {
    _fontSize = value;
    saveSettings();
    notifyListeners();
  }

  set reduceMotion(bool value) {
    _reduceMotion = value;
    saveSettings();
    notifyListeners();
  }

  set highContrast(bool value) {
    _highContrast = value;
    saveSettings();
    notifyListeners();
  }

  set isRTL(bool value) {
    _isRTL = value;
    saveSettings();
    notifyListeners();
  }

  set selectedLanguage(String value) {
    _selectedLanguage = value;
    // Update RTL based on language
    _isRTL = ['ar', 'he', 'fa', 'ur'].contains(value);
    saveSettings();
    notifyListeners();
  }

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      _fontSize = prefs.getDouble(_fontSizeKey) ?? 1.0;
      _reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
      _highContrast = prefs.getBool(_highContrastKey) ?? false;
      _selectedLanguage = prefs.getString(_languageKey) ?? 'en';
      
      // Update RTL based on loaded language
      _isRTL = ['ar', 'he', 'fa', 'ur'].contains(_selectedLanguage);
      
      notifyListeners();
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  /// Save current settings to SharedPreferences
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_darkModeKey, _isDarkMode);
      await prefs.setDouble(_fontSizeKey, _fontSize);
      await prefs.setBool(_reduceMotionKey, _reduceMotion);
      await prefs.setBool(_highContrastKey, _highContrast);
      await prefs.setString(_languageKey, _selectedLanguage);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  /// Reset all settings to default values
  Future<void> resetSettings() async {
    _isDarkMode = false;
    _fontSize = 1.0;
    _reduceMotion = false;
    _highContrast = false;
    _selectedLanguage = 'en';
    _isRTL = false;
    
    await saveSettings();
    notifyListeners();
  }

  /// Get theme based on current settings
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
}