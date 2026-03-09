import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/utils/logger.dart';

final _logger = LogTags.settings;

// ===========================================================================
// ENUMS
// ===========================================================================

enum AppThemeMode { light, dark, system }

// ===========================================================================
// THEME STATE
// ===========================================================================

class ThemeState {
  final AppThemeMode themeMode;
  final double fontSize;
  final bool wideScreenMode;
  final bool isLoading;

  const ThemeState({
    this.themeMode = AppThemeMode.system,
    this.fontSize = 1.0,
    this.wideScreenMode = false,
    this.isLoading = true,
  });

  bool get isDarkMode =>
      themeMode == AppThemeMode.dark ||
      (themeMode == AppThemeMode.system &&
          PlatformDispatcher.instance.platformBrightness == Brightness.dark);

  ThemeData getTheme() {
    final bool isDark = isDarkMode;
    var theme = AppTheme.getTheme(isDark ? Brightness.dark : Brightness.light);
    theme = theme.copyWith(
      textTheme: _scaleTextTheme(theme.textTheme, fontSize),
    );
    return theme;
  }

  ThemeState copyWith({
    AppThemeMode? themeMode,
    double? fontSize,
    bool? wideScreenMode,
    bool? isLoading,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      wideScreenMode: wideScreenMode ?? this.wideScreenMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  static TextTheme _scaleTextTheme(TextTheme textTheme, double scale) {
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
}

// ===========================================================================
// THEME NOTIFIER
// ===========================================================================

class ThemeNotifier extends Notifier<ThemeState> {
  static const String _themeModeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _wideScreenModeKey = 'wide_screen_mode';

  bool _settingsLoaded = false;

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  ThemeState build() {
    if (!_settingsLoaded) {
      _settingsLoaded = true;
      _loadSettings();
    }
    return const ThemeState();
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String themeModeString = prefs.getString(_themeModeKey) ?? 'system';
      final themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.toString() == 'AppThemeMode.$themeModeString',
        orElse: () => AppThemeMode.system,
      );
      final fontSize = prefs.getDouble(_fontSizeKey) ?? 1.0;
      final wideScreenMode = prefs.getBool(_wideScreenModeKey) ?? false;

      state = ThemeState(
        themeMode: themeMode,
        fontSize: fontSize,
        wideScreenMode: wideScreenMode,
        isLoading: false,
      );
      _logger.logInfo('[ThemeNotifier] Settings loaded');
    } catch (e) {
      _logger.logError('[ThemeNotifier] Error loading settings: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeModeKey,
        state.themeMode.toString().split('.').last,
      );
      await prefs.setDouble(_fontSizeKey, state.fontSize);
      await prefs.setBool(_wideScreenModeKey, state.wideScreenMode);
      _logger.logVerbose('[ThemeNotifier] Settings saved');
    } catch (e) {
      _logger.logError('[ThemeNotifier] Error saving settings: $e');
    }
  }

  // ===========================================================================
  // SETTER METHODS
  // ===========================================================================

  void setThemeMode(AppThemeMode mode) {
    if (state.themeMode != mode) {
      state = state.copyWith(themeMode: mode);
      _saveSettings();
    }
  }

  void setFontSize(double size) {
    if (state.fontSize != size) {
      state = state.copyWith(fontSize: size);
      _saveSettings();
    }
  }

  void setWideScreenMode(bool value) {
    if (state.wideScreenMode != value) {
      state = state.copyWith(wideScreenMode: value);
      _saveSettings();
    }
  }

  Future<void> resetSettings() async {
    state = const ThemeState(isLoading: false);
    await _saveSettings();
    _logger.logInfo('[ThemeNotifier] Settings reset to defaults');
  }

  ThemeData getTheme() => state.getTheme();
}

// ===========================================================================
// PROVIDER EXPORT
// ===========================================================================

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);
