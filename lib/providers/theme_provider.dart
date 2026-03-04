// ignore_for_file: avoid_print

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/utils/logger.dart';

// Initialize logger for this provider
final _logger = LogTags.settings;

enum AppThemeMode { light, dark, system }

/// Provider responsible for theme-related settings only:
/// - Theme mode (light/dark/system)
/// - Font size scaling
/// - Reduced motion
/// - High contrast mode
/// - Wide screen mode
class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _reduceMotionKey = 'reduce_motion';
  static const String _highContrastKey = 'high_contrast';
  static const String _wideScreenModeKey = 'wide_screen_mode';

  AppThemeMode _themeMode = AppThemeMode.system;
  double _fontSize = 1.0;
  bool _reduceMotion = false;
  bool _highContrast = false;
  bool _wideScreenMode = false;

  // Computed property for dark mode based on theme mode
  bool get isDarkMode =>
      _themeMode == AppThemeMode.dark ||
      (_themeMode == AppThemeMode.system &&
          PlatformDispatcher.instance.platformBrightness == Brightness.dark);

  AppThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  bool get reduceMotion => _reduceMotion;
  bool get highContrast => _highContrast;
  bool get wideScreenMode => _wideScreenMode;

  ThemeProvider() {
    loadSettings();
  }

  set themeMode(AppThemeMode value) {
    if (_themeMode != value) {
      _themeMode = value;
      saveSettings();
      notifyListeners();
    }
  }

  set fontSize(double value) {
    if (_fontSize != value) {
      _fontSize = value;
      saveSettings();
      notifyListeners();
    }
  }

  set reduceMotion(bool value) {
    if (_reduceMotion != value) {
      _reduceMotion = value;
      saveSettings();
      notifyListeners();
    }
  }

  set highContrast(bool value) {
    if (_highContrast != value) {
      _highContrast = value;
      saveSettings();
      notifyListeners();
    }
  }

  set wideScreenMode(bool value) {
    if (_wideScreenMode != value) {
      _wideScreenMode = value;
      saveSettings();
      notifyListeners();
    }
  }

  /// Load theme settings from SharedPreferences
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
      _wideScreenMode = prefs.getBool(_wideScreenModeKey) ?? false;

      _logger.logInfo('[ThemeProvider] Settings loaded');
      notifyListeners();
    } catch (e) {
      _logger.logError('[ThemeProvider] Error loading settings: $e');
    }
  }

  /// Save theme settings to SharedPreferences
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _themeModeKey,
        _themeMode.toString().split('.').last,
      );
      await prefs.setDouble(_fontSizeKey, _fontSize);
      await prefs.setBool(_reduceMotionKey, _reduceMotion);
      await prefs.setBool(_highContrastKey, _highContrast);
      await prefs.setBool(_wideScreenModeKey, _wideScreenMode);

      _logger.logVerbose('[ThemeProvider] Settings saved');
    } catch (e) {
      _logger.logError('[ThemeProvider] Error saving settings: $e');
    }
  }

  /// Reset theme settings to default values
  Future<void> resetSettings() async {
    _themeMode = AppThemeMode.system;
    _fontSize = 1.0;
    _reduceMotion = false;
    _highContrast = false;
    _wideScreenMode = false;

    await saveSettings();
    notifyListeners();

    _logger.logInfo('[ThemeProvider] Settings reset to defaults');
  }

  /// Get theme based on current settings
  ThemeData getTheme() {
    final bool isDark = isDarkMode;
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

  // ==================== TEST HELPER METHODS ====================
  // These methods are only for unit testing and should not be used in production

  @visibleForTesting
  void resetForTesting() {
    _themeMode = AppThemeMode.system;
    _fontSize = 1.0;
    _reduceMotion = false;
    _highContrast = false;
    _wideScreenMode = false;
  }
}
