// ignore_for_file: avoid_print

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
/// - Wide screen mode
class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _wideScreenModeKey = 'wide_screen_mode';

  AppThemeMode _themeMode = AppThemeMode.system;
  double _fontSize = 1.0;
  bool _wideScreenMode = false;

  // Computed property for dark mode based on theme mode
  bool get isDarkMode =>
      _themeMode == AppThemeMode.dark ||
      (_themeMode == AppThemeMode.system &&
          PlatformDispatcher.instance.platformBrightness == Brightness.dark);

  AppThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
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
    _wideScreenMode = false;

    await saveSettings();
    notifyListeners();

    _logger.logInfo('[ThemeProvider] Settings reset to defaults');
  }

  /// Get theme based on current settings
  ThemeData getTheme() {
    final bool isDark = isDarkMode;
    var theme = AppTheme.getTheme(isDark ? Brightness.dark : Brightness.light);

    // Apply font size scaling to text theme
    theme = theme.copyWith(
      textTheme: _scaleTextTheme(theme.textTheme, _fontSize),
    );

    return theme;
  }

  /// Scale all text styles by the given factor
  TextTheme _scaleTextTheme(TextTheme textTheme, double scale) {
    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.fontSize != null
          ? textTheme.displayLarge?.copyWith(
              fontSize: textTheme.displayLarge!.fontSize! * scale,
            )
          : textTheme.displayLarge,
      displayMedium: textTheme.displayMedium?.fontSize != null
          ? textTheme.displayMedium?.copyWith(
              fontSize: textTheme.displayMedium!.fontSize! * scale,
            )
          : textTheme.displayMedium,
      displaySmall: textTheme.displaySmall?.fontSize != null
          ? textTheme.displaySmall?.copyWith(
              fontSize: textTheme.displaySmall!.fontSize! * scale,
            )
          : textTheme.displaySmall,
      headlineLarge: textTheme.headlineLarge?.fontSize != null
          ? textTheme.headlineLarge?.copyWith(
              fontSize: textTheme.headlineLarge!.fontSize! * scale,
            )
          : textTheme.headlineLarge,
      headlineMedium: textTheme.headlineMedium?.fontSize != null
          ? textTheme.headlineMedium?.copyWith(
              fontSize: textTheme.headlineMedium!.fontSize! * scale,
            )
          : textTheme.headlineMedium,
      headlineSmall: textTheme.headlineSmall?.fontSize != null
          ? textTheme.headlineSmall?.copyWith(
              fontSize: textTheme.headlineSmall!.fontSize! * scale,
            )
          : textTheme.headlineSmall,
      titleLarge: textTheme.titleLarge?.fontSize != null
          ? textTheme.titleLarge?.copyWith(
              fontSize: textTheme.titleLarge!.fontSize! * scale,
            )
          : textTheme.titleLarge,
      titleMedium: textTheme.titleMedium?.fontSize != null
          ? textTheme.titleMedium?.copyWith(
              fontSize: textTheme.titleMedium!.fontSize! * scale,
            )
          : textTheme.titleMedium,
      titleSmall: textTheme.titleSmall?.fontSize != null
          ? textTheme.titleSmall?.copyWith(
              fontSize: textTheme.titleSmall!.fontSize! * scale,
            )
          : textTheme.titleSmall,
      bodyLarge: textTheme.bodyLarge?.fontSize != null
          ? textTheme.bodyLarge?.copyWith(
              fontSize: textTheme.bodyLarge!.fontSize! * scale,
            )
          : textTheme.bodyLarge,
      bodyMedium: textTheme.bodyMedium?.fontSize != null
          ? textTheme.bodyMedium?.copyWith(
              fontSize: textTheme.bodyMedium!.fontSize! * scale,
            )
          : textTheme.bodyMedium,
      bodySmall: textTheme.bodySmall?.fontSize != null
          ? textTheme.bodySmall?.copyWith(
              fontSize: textTheme.bodySmall!.fontSize! * scale,
            )
          : textTheme.bodySmall,
      labelLarge: textTheme.labelLarge?.fontSize != null
          ? textTheme.labelLarge?.copyWith(
              fontSize: textTheme.labelLarge!.fontSize! * scale,
            )
          : textTheme.labelLarge,
      labelMedium: textTheme.labelMedium?.fontSize != null
          ? textTheme.labelMedium?.copyWith(
              fontSize: textTheme.labelMedium!.fontSize! * scale,
            )
          : textTheme.labelMedium,
      labelSmall: textTheme.labelSmall?.fontSize != null
          ? textTheme.labelSmall?.copyWith(
              fontSize: textTheme.labelSmall!.fontSize! * scale,
            )
          : textTheme.labelSmall,
    );
  }

  // ==================== TEST HELPER METHODS ====================
  // These methods are only for unit testing and should not be used in production

  @visibleForTesting
  void resetForTesting() {
    _themeMode = AppThemeMode.system;
    _fontSize = 1.0;
    _wideScreenMode = false;
  }
}
