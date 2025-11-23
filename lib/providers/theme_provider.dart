// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';

enum AppThemeMode {
  light,
  dark,
  system
}

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _reduceMotionKey = 'reduce_motion';
  static const String _highContrastKey = 'high_contrast';
  static const String _languageKey = 'selected_language';

  AppThemeMode _themeMode = AppThemeMode.system;
  double _fontSize = 1.0;
  bool _reduceMotion = false;
  bool _highContrast = false;
  bool _isRTL = false;
  String _selectedLanguage = 'en';

  // Computed property for dark mode based on theme mode
  bool get isDarkMode => _themeMode == AppThemeMode.dark || 
                       (_themeMode == AppThemeMode.system && 
                        WidgetsBinding.instance.window.platformBrightness == Brightness.dark);

  AppThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  bool get reduceMotion => _reduceMotion;
  bool get highContrast => _highContrast;
  bool get isRTL => _isRTL;
  String get selectedLanguage => _selectedLanguage;

  ThemeProvider() {
    loadSettings();
  }

  set themeMode(AppThemeMode value) {
    _themeMode = value;
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
      
      final String themeModeString = prefs.getString(_themeModeKey) ?? 'system';
      _themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.toString() == 'AppThemeMode.$themeModeString',
        orElse: () => AppThemeMode.system,
      );
      
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
      
      await prefs.setString(_themeModeKey, _themeMode.toString().split('.').last);
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
    _themeMode = AppThemeMode.system;
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
    final bool isDark = isDarkMode; // Use computed property
    var theme = AppTheme.getTheme(isDark ? Brightness.dark : Brightness.light);
    
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