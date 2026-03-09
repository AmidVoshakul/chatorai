import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/utils/logger.dart';

final _logger = LogTags.settings;

// ===========================================================================
// LANGUAGE STATE
// ===========================================================================

class LanguageState {
  final String selectedLanguage;
  final bool isRTL;
  final bool isLoading;

  const LanguageState({
    this.selectedLanguage = 'en',
    this.isRTL = false,
    this.isLoading = true,
  });

  LanguageState copyWith({
    String? selectedLanguage,
    bool? isRTL,
    bool? isLoading,
  }) {
    return LanguageState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isRTL: isRTL ?? this.isRTL,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  static const List<String> supportedLanguages = [
    'en',
    'ru',
    'uk',
    'zh',
    'ja',
    'ar',
  ];

  static const List<String> rtlLanguages = ['ar', 'he', 'fa', 'ur'];

  static bool isRTLanguage(String languageCode) {
    return rtlLanguages.contains(languageCode);
  }

  static String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      case 'uk':
        return 'Українська';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ar':
        return 'العربية';
      default:
        return languageCode.toUpperCase();
    }
  }
}

// ===========================================================================
// LANGUAGE NOTIFIER
// ===========================================================================

class LanguageNotifier extends Notifier<LanguageState> {
  static const String _languageKey = 'selected_language';

  bool _settingsLoaded = false;

  @override
  LanguageState build() {
    if (!_settingsLoaded) {
      _settingsLoaded = true;
      _loadSettings();
    }
    return const LanguageState();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedLanguage = prefs.getString(_languageKey) ?? 'en';
      final isRTL = LanguageState.isRTLanguage(selectedLanguage);

      state = LanguageState(
        selectedLanguage: selectedLanguage,
        isRTL: isRTL,
        isLoading: false,
      );
      _logger.logInfo(
        '[LanguageNotifier] Language loaded: ${state.selectedLanguage}, RTL: ${state.isRTL}',
      );
    } catch (e) {
      _logger.logError('[LanguageNotifier] Error loading language: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, state.selectedLanguage);
      _logger.logVerbose(
        '[LanguageNotifier] Language saved: ${state.selectedLanguage}',
      );
    } catch (e) {
      _logger.logError('[LanguageNotifier] Error saving language: $e');
    }
  }

  void setSelectedLanguage(String language) {
    if (state.selectedLanguage != language) {
      state = state.copyWith(
        selectedLanguage: language,
        isRTL: LanguageState.isRTLanguage(language),
      );
      _saveSettings();
    }
  }

  Future<void> resetSettings() async {
    state = const LanguageState(
      selectedLanguage: 'en',
      isRTL: false,
      isLoading: false,
    );
    await _saveSettings();
    _logger.logInfo('[LanguageNotifier] Language reset to default (en)');
  }
}

// ===========================================================================
// PROVIDER
// ===========================================================================

final languageProvider = NotifierProvider<LanguageNotifier, LanguageState>(
  LanguageNotifier.new,
);
