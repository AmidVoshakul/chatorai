// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/utils/logger.dart';

// Initialize logger for this provider
final _logger = LogTags.settings;

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'selected_language';

  // List of RTL languages
  static const List<String> _rtlLanguages = ['ar', 'he', 'fa', 'ur'];

  // Supported languages
  static const List<String> supportedLanguages = [
    'en', // English
    'ru', // Russian
    'uk', // Ukrainian
    'zh', // Chinese
    'ja', // Japanese
    'ar', // Arabic
  ];

  String _selectedLanguage = 'en';
  bool _isRTL = false;

  String get selectedLanguage => _selectedLanguage;
  bool get isRTL => _isRTL;

  LanguageProvider() {
    loadSettings();
  }

  set selectedLanguage(String value) {
    if (_selectedLanguage != value) {
      _selectedLanguage = value;
      // Update RTL based on language
      _isRTL = _rtlLanguages.contains(value);
      saveSettings();
      notifyListeners();
    }
  }

  /// Load language setting from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedLanguage = prefs.getString(_languageKey) ?? 'en';
      _isRTL = _rtlLanguages.contains(_selectedLanguage);

      _logger.logInfo(
        '[LanguageProvider] Language loaded: $_selectedLanguage, RTL: $_isRTL',
      );
      notifyListeners();
    } catch (e) {
      _logger.logError('[LanguageProvider] Error loading language: $e');
    }
  }

  /// Save language setting to SharedPreferences
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _selectedLanguage);
      _logger.logVerbose(
        '[LanguageProvider] Language saved: $_selectedLanguage',
      );
    } catch (e) {
      _logger.logError('[LanguageProvider] Error saving language: $e');
    }
  }

  /// Reset language to default (English)
  Future<void> resetSettings() async {
    _selectedLanguage = 'en';
    _isRTL = false;
    await saveSettings();
    notifyListeners();

    _logger.logInfo('[LanguageProvider] Language reset to default (en)');
  }

  /// Check if a language is RTL
  static bool isRTLanguage(String languageCode) {
    return _rtlLanguages.contains(languageCode);
  }

  /// Get display name for language code
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

  // ==================== TEST HELPER METHODS ====================
  // These methods are only for unit testing and should not be used in production

  @visibleForTesting
  void resetForTesting() {
    _selectedLanguage = 'en';
    _isRTL = false;
  }
}
