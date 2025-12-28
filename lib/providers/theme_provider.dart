// ignore_for_file: avoid_print

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/services/openrouter_service.dart';

// Initialize logger for this provider
final _logger = LogTags.settings;

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
  static const String _wideScreenModeKey = 'wide_screen_mode';
  static const String _languageKey = 'selected_language';
  static const String _selectedModelKey = 'selected_model_id';
  static const String _favoriteModelsKey = 'favorite_models';

  AppThemeMode _themeMode = AppThemeMode.system;
  double _fontSize = 1.0;
  bool _reduceMotion = false;
  bool _highContrast = false;
  bool _wideScreenMode = false; // New setting for wide screen mode
  bool _isRTL = false;
  String _selectedLanguage = 'en';
  String _selectedModelId = ''; // Will be set after settings load
  OpenRouterModel? _selectedModelObject;
  List<OpenRouterModel> _availableModels = [];
  List<String> _favoriteModelIds = [];
  bool _modelsLoaded = false;
  bool _isLoadingModels = false;
  bool _settingsLoaded = false;

  // Computed property for dark mode based on theme mode
  bool get isDarkMode => _themeMode == AppThemeMode.dark || 
                       (_themeMode == AppThemeMode.system && 
                        PlatformDispatcher.instance.platformBrightness == Brightness.dark);

  AppThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  bool get reduceMotion => _reduceMotion;
  bool get highContrast => _highContrast;
  bool get wideScreenMode => _wideScreenMode; // Getter for wide screen mode
  bool get isRTL => _isRTL;
  String get selectedLanguage => _selectedLanguage;
  String get selectedModelId => _selectedModelId;
  OpenRouterModel? get selectedModelObject => _selectedModelObject;
  List<OpenRouterModel> get availableModels => _availableModels;
  List<String> get favoriteModelIds => _favoriteModelIds;
  bool get modelsLoaded => _modelsLoaded;
  bool get isLoadingModels => _isLoadingModels;
  bool get settingsLoaded => _settingsLoaded;

  ThemeProvider() {
    loadSettings();
    // Load models asynchronously after initialization
    _loadModelsAsync();
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

  set wideScreenMode(bool value) {
    _wideScreenMode = value;
    saveSettings();
    notifyListeners();
  }

  set isRTL(bool value) {
    _isRTL = value;
    saveSettings();
    notifyListeners();
  }

  set selectedLanguage(String value) {
    if (_selectedLanguage != value) {
      _selectedLanguage = value;
      // Update RTL based on language
      _isRTL = ['ar', 'he', 'fa', 'ur'].contains(value);
      saveSettings();
      notifyListeners();
    }
  }

  /// Set selected model by ID
  Future<void> setSelectedModel(String modelId) async {
    if (_selectedModelId != modelId) {
      _selectedModelId = modelId;

      // Find the model object
      _selectedModelObject = _availableModels.firstWhere(
        (model) => model.id == modelId,
        orElse: () => _availableModels.first, // Return first model if not found
      );


      saveSettings();
      notifyListeners();
    }
  }

  /// Set selected model without notifying listeners immediately
  /// Useful for navigation scenarios to avoid race conditions
  Future<void> setSelectedModelSilent(String modelId) async {
    if (_selectedModelId != modelId) {
      _selectedModelId = modelId;

      // Find the model object
      _selectedModelObject = _availableModels.firstWhere(
        (model) => model.id == modelId,
        orElse: () => _availableModels.first, // Return first model if not found
      );


      await saveSettings();
    }
  }

  /// Check if a model is in favorites
  bool isFavoriteModel(String modelId) {
    return _favoriteModelIds.contains(modelId);
  }

  /// Toggle favorite status for a model
  Future<void> toggleFavoriteModel(String modelId) async {
    if (_favoriteModelIds.contains(modelId)) {
      _favoriteModelIds.remove(modelId);
      _logger.logInfo('[ThemeProvider] Removed model from favorites: $modelId');
    } else {
      _favoriteModelIds.add(modelId);
      _logger.logInfo('[ThemeProvider] Added model to favorites: $modelId');
    }

    await saveSettings();
    notifyListeners();
  }

  /// Get favorite models
  List<OpenRouterModel> getFavoriteModels() {
    return _availableModels.where((model) => _favoriteModelIds.contains(model.id)).toList();
  }

  /// Load models asynchronously
  Future<void> _loadModelsAsync() async {
    if (_modelsLoaded || _isLoadingModels) return;

    _isLoadingModels = true;
    notifyListeners();

    try {
      _logger.logInfo('[ThemeProvider] Loading models from OpenRouter...');
      final openRouterService = OpenRouterService();

      // Wait for OpenRouterService to be fully initialized
      _logger.logInfo('[ThemeProvider] Waiting for OpenRouterService initialization...');
      int retryCount = 0;
      const maxRetries = 20; // Wait up to 10 seconds (20 * 500ms)

      while (retryCount < maxRetries) {
        if (openRouterService.isReady()) {
          _logger.logInfo('[ThemeProvider] OpenRouterService is ready');
          break;
        }

        await Future<void>.delayed(const Duration(milliseconds: 500));
        retryCount++;
      }

      if (retryCount >= maxRetries) {
        _logger.logWarning('[ThemeProvider] OpenRouterService initialization timeout, proceeding anyway...');
      }

      final models = await openRouterService.getAvailableModels();

      // Remove duplicates using more robust deduplication method
      _availableModels = _deduplicateModels(models);
      _modelsLoaded = true;


      // Set the selected model object from saved ID
      if (_selectedModelObject == null) {
        // If no model ID is saved, use the first available model
        if (_selectedModelId.isEmpty) {
          _selectedModelId = _availableModels.first.id;
          _selectedModelObject = _availableModels.first;
          await saveSettings();
       } else {
          // Find the model object for the saved ID
          final modelObject = _availableModels.firstWhere(
            (model) => model.id == _selectedModelId,
            orElse: () => _availableModels.first,
          );
          _selectedModelObject = modelObject;
          // Update ID if we fell back to first available
          if (modelObject.id != _selectedModelId) {
            _selectedModelId = modelObject.id;
            await saveSettings();
          }
        }
        // Notify listeners about the model change
        notifyListeners();
      } else if (!_availableModels.any((m) => m.id == _selectedModelId)) {
        // Current selection is not available, find a replacement
        final defaultModel = _availableModels.first;
        await setSelectedModel(defaultModel.id);
      }

      _logger.logInfo('[ThemeProvider] Successfully loaded ${models.length} models');
    } catch (e) {
      _logger.logError('[ThemeProvider] Failed to load models: $e');
      _logger.logWarning('[ThemeProvider] Retrying model loading in 2 seconds...');

      // Retry after a short delay
      await Future<void>.delayed(const Duration(seconds: 2));

      try {
        _logger.logInfo('[ThemeProvider] Retrying model loading...');
        final openRouterService = OpenRouterService();
        final models = await openRouterService.getAvailableModels();

        _availableModels = _deduplicateModels(models);
        _modelsLoaded = true;

        if (_selectedModelObject == null) {
          final modelObject = _availableModels.firstWhere(
            (model) => model.id == _selectedModelId,
            orElse: () => _availableModels.first,
          );
          _selectedModelObject = modelObject;
          if (modelObject.id != _selectedModelId) {
            _selectedModelId = modelObject.id;
            await saveSettings();
          }
          notifyListeners();
        } else if (!_availableModels.any((m) => m.id == _selectedModelId)) {
          final defaultModel = _availableModels.first;
          await setSelectedModel(defaultModel.id);
        }

        _logger.logInfo('[ThemeProvider] Successfully loaded ${models.length} models on retry');
      } catch (retryError) {
        _logger.logError('[ThemeProvider] Failed to load models on retry: $retryError');
        _modelsLoaded = true; // Mark as loaded to prevent infinite retries
      }
    } finally {
      _isLoadingModels = false;
      notifyListeners();
    }
  }

  /// Reload models (for refresh functionality)
  Future<void> reloadModels() async {
    _modelsLoaded = false;
    _availableModels.clear();
    _selectedModelObject = null;
    await _loadModelsAsync();
  }

  /// Get model by ID
  OpenRouterModel? getModelById(String modelId) {
    try {
      return _availableModels.firstWhere(
        (model) => model.id == modelId,
      );
    } catch (e) {
      return null;
    }
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
      _wideScreenMode = prefs.getBool(_wideScreenModeKey) ?? false;
      _selectedLanguage = prefs.getString(_languageKey) ?? 'en';
      _selectedModelId = prefs.getString(_selectedModelKey) ?? '';

      
      // Load favorite models
      final favoriteModelsString = prefs.getStringList(_favoriteModelsKey) ?? [];
      _favoriteModelIds = favoriteModelsString;

      // Update RTL based on loaded language
      _isRTL = ['ar', 'he', 'fa', 'ur'].contains(_selectedLanguage);
      
      // Initialize selected model object if models are already loaded
      if (_modelsLoaded && _availableModels.isNotEmpty) {
        if (_selectedModelId.isEmpty) {
          _selectedModelId = _availableModels.first.id;
          _selectedModelObject = _availableModels.first;
        } else {
          _selectedModelObject = _availableModels.firstWhere(
            (model) => model.id == _selectedModelId,
            orElse: () => _availableModels.first,
          );
          // Update ID if we fell back to first available
          if (_selectedModelObject!.id != _selectedModelId) {
            _selectedModelId = _selectedModelObject!.id;
          }
        }
      }

      _settingsLoaded = true;
      notifyListeners();
    } catch (e) {
      _logger.logError('[Settings] Error loading settings: $e');
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
      await prefs.setBool(_wideScreenModeKey, _wideScreenMode);
      await prefs.setString(_languageKey, _selectedLanguage);
      await prefs.setString(_selectedModelKey, _selectedModelId);
      await prefs.setStringList(_favoriteModelsKey, _favoriteModelIds);
    } catch (e) {
      _logger.logError('[Settings] Error saving settings: $e');
    }
  }

  /// Reset all settings to default values
  Future<void> resetSettings() async {
    _themeMode = AppThemeMode.system;
    _fontSize = 1.0;
    _reduceMotion = false;
    _highContrast = false;
    _wideScreenMode = false;
    _selectedLanguage = 'en';
    _selectedModelId = '';
    _isRTL = false;
    _selectedModelObject = null;
    _availableModels.clear();
    _favoriteModelIds.clear();
    _modelsLoaded = false;

    await saveSettings();
    notifyListeners();

    // Reload models
    _loadModelsAsync();
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

  /// Remove duplicate models using a more robust approach
  List<OpenRouterModel> _deduplicateModels(List<OpenRouterModel> models) {
    final Map<String, OpenRouterModel> uniqueModels = {};

    for (final model in models) {
      // Use model ID as the primary key for deduplication
      uniqueModels[model.id] = model;
    }

    return uniqueModels.values.toList();
  }

  /// Wait for models to be loaded with timeout
  Future<void> waitForModelsLoaded({Duration timeout = const Duration(seconds: 10)}) async {
    if (_modelsLoaded) return;

    final stopwatch = Stopwatch()..start();
    while (!_modelsLoaded && stopwatch.elapsed < timeout) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    stopwatch.stop();
  }
}