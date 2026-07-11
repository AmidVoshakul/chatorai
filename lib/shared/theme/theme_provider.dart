import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/logger.dart';

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
  final bool autoScrollDuringStreaming;
  final bool showContinuationSuggestions;
  final bool expandReasoningByDefault;
  final bool isLoading;

  const ThemeState({
    this.themeMode = AppThemeMode.system,
    this.fontSize = 1.0,
    this.wideScreenMode = false,
    this.autoScrollDuringStreaming = false,
    this.showContinuationSuggestions = true,
    this.expandReasoningByDefault = true,
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
    bool? autoScrollDuringStreaming,
    bool? showContinuationSuggestions,
    bool? expandReasoningByDefault,
    bool? isLoading,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      wideScreenMode: wideScreenMode ?? this.wideScreenMode,
      autoScrollDuringStreaming:
          autoScrollDuringStreaming ?? this.autoScrollDuringStreaming,
      showContinuationSuggestions:
          showContinuationSuggestions ?? this.showContinuationSuggestions,
      expandReasoningByDefault:
          expandReasoningByDefault ?? this.expandReasoningByDefault,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  static TextStyle? _scaled(TextStyle? style, double scale) {
    if (style?.fontSize == null) return style;
    return style!.copyWith(fontSize: style.fontSize! * scale);
  }

  static TextTheme _scaleTextTheme(TextTheme textTheme, double scale) {
    return textTheme.copyWith(
      displayLarge: _scaled(textTheme.displayLarge, scale),
      displayMedium: _scaled(textTheme.displayMedium, scale),
      displaySmall: _scaled(textTheme.displaySmall, scale),
      headlineLarge: _scaled(textTheme.headlineLarge, scale),
      headlineMedium: _scaled(textTheme.headlineMedium, scale),
      headlineSmall: _scaled(textTheme.headlineSmall, scale),
      titleLarge: _scaled(textTheme.titleLarge, scale),
      titleMedium: _scaled(textTheme.titleMedium, scale),
      titleSmall: _scaled(textTheme.titleSmall, scale),
      bodyLarge: _scaled(textTheme.bodyLarge, scale),
      bodyMedium: _scaled(textTheme.bodyMedium, scale),
      bodySmall: _scaled(textTheme.bodySmall, scale),
      labelLarge: _scaled(textTheme.labelLarge, scale),
      labelMedium: _scaled(textTheme.labelMedium, scale),
      labelSmall: _scaled(textTheme.labelSmall, scale),
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
  static const String _autoScrollDuringStreamingKey =
      'auto_scroll_during_streaming';
  static const String _showContinuationSuggestionsKey =
      'show_continuation_suggestions';
  static const String _expandReasoningByDefaultKey =
      'expand_reasoning_by_default';

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
      final autoScrollDuringStreaming =
          prefs.getBool(_autoScrollDuringStreamingKey) ?? false;
      final showContinuationSuggestions =
          prefs.getBool(_showContinuationSuggestionsKey) ?? true;
      final expandReasoningByDefault =
          prefs.getBool(_expandReasoningByDefaultKey) ?? true;

      state = ThemeState(
        themeMode: themeMode,
        fontSize: fontSize,
        wideScreenMode: wideScreenMode,
        autoScrollDuringStreaming: autoScrollDuringStreaming,
        showContinuationSuggestions: showContinuationSuggestions,
        expandReasoningByDefault: expandReasoningByDefault,
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
      await prefs.setBool(
        _autoScrollDuringStreamingKey,
        state.autoScrollDuringStreaming,
      );
      await prefs.setBool(
        _showContinuationSuggestionsKey,
        state.showContinuationSuggestions,
      );
      await prefs.setBool(
        _expandReasoningByDefaultKey,
        state.expandReasoningByDefault,
      );
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

  void setAutoScrollDuringStreaming(bool value) {
    if (state.autoScrollDuringStreaming != value) {
      state = state.copyWith(autoScrollDuringStreaming: value);
      _saveSettings();
    }
  }

  void setShowContinuationSuggestions(bool value) {
    if (state.showContinuationSuggestions != value) {
      state = state.copyWith(showContinuationSuggestions: value);
      _saveSettings();
    }
  }

  void setExpandReasoningByDefault(bool value) {
    if (state.expandReasoningByDefault != value) {
      state = state.copyWith(expandReasoningByDefault: value);
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
