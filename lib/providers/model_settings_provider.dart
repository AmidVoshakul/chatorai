// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/models/model_settings.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/providers/theme_provider.dart';

// Initialize logger for this provider
final _logger = LogTags.settings;

class ModelSettingsProvider with ChangeNotifier {
  static const String _settingsPrefix = 'model_settings_';
  
  // Cache for model settings
  final Map<String, ModelSettings> _settingsCache = {};
  
  // Currently active model settings
  ModelSettings? _activeSettings;
  
  // Loading state
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;
  ModelSettings? get activeSettings => _activeSettings;

  ModelSettingsProvider() {
    _logger.logInfo('[ModelSettingsProvider] Initialized');
  }

  /// Load settings for a specific model
  /// Pass BuildContext to access ThemeProvider for model info
  Future<ModelSettings> loadSettings(String modelId, [BuildContext? context]) async {
    if (_settingsCache.containsKey(modelId)) {
      return _settingsCache[modelId]!;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix$modelId';
      final jsonString = prefs.getString(key);

      ModelSettings settings;
      if (jsonString != null && jsonString.isNotEmpty) {
        // Parse from stored JSON
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
          settings = ModelSettings.fromJson(jsonMap);
          
          // Check if settings have API info, if not refresh from API
          if (settings.apiContextLength == null || settings.apiMaxTokens == null) {
            final freshSettings = await _createSettingsFromModelInfo(modelId, context);
            
            // Merge: keep user preferences, update API info
            settings = settings.copyWith(
              maxContextLength: freshSettings.maxContextLength,
              apiMaxTokens: freshSettings.apiMaxTokens,
              apiContextLength: freshSettings.apiContextLength,
              apiMaxTemperature: freshSettings.apiMaxTemperature,
              apiMinTemperature: freshSettings.apiMinTemperature,
            );
            
            // Save updated settings
            await saveSettings(settings);
          }
        } catch (e) {
          // Fallback to defaults
          settings = ModelSettings.defaultForModel(modelId);
        }
      } else {
        // No stored settings, try to get model info from theme provider or API
        settings = await _createSettingsFromModelInfo(modelId, context);
      }

      _settingsCache[modelId] = settings;
      _logger.logInfo('[ModelSettingsProvider] Loaded settings for $modelId: $settings');
      
      return settings;
    } catch (e) {
      _logger.logError('[ModelSettingsProvider] Error loading settings for $modelId: $e');
      final defaultSettings = ModelSettings.defaultForModel(modelId);
      _settingsCache[modelId] = defaultSettings;
      return defaultSettings;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create settings from model information (from theme provider or API)
  Future<ModelSettings> _createSettingsFromModelInfo(String modelId, [BuildContext? context]) async {
    try {
      // First try to get from ThemeProvider if context is available
      if (context != null && context.mounted) {
        try {
          final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
          final model = themeProvider.getModelById(modelId);
          
          if (model != null) {
            _logger.logInfo('[ModelSettingsProvider] Got model info from ThemeProvider: ${model.name}, context: ${model.contextLength}');
            
            // Use the model's context length for maxTokens
            final maxTokens = model.contextLength != null 
                ? model.contextLength! 
                : 4096;
            
            return ModelSettings.fromApiModel(
              modelId,
              model.contextLength,
              maxTokens, // Use model's context as maxTokens
            );
          }
        } catch (e) {
          _logger.logWarning('[ModelSettingsProvider] Could not get model from ThemeProvider: $e');
        }
      }

      // Fallback to API call
      final openRouterService = OpenRouterService();
      final models = await openRouterService.getAvailableModels();
      final model = models.firstWhere(
        (m) => m.id == modelId,
        orElse: () => throw Exception('Model not found'),
      );

      _logger.logInfo('[ModelSettingsProvider] Got model info from API: ${model.name}, context: ${model.contextLength}');
      
      // Use the model's context length for maxTokens
      final maxTokens = model.contextLength != null 
          ? model.contextLength! 
          : 4096;
      
      return ModelSettings.fromApiModel(
        modelId,
        model.contextLength,
        maxTokens, // Use model's context as maxTokens
      );
    } catch (e) {
      _logger.logWarning('[ModelSettingsProvider] Could not get model info: $e');
      return ModelSettings.defaultForModel(modelId);
    }
  }

  /// Save settings for a specific model
  Future<void> saveSettings(ModelSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix${settings.modelId}';
      
      // Convert to JSON string
      final jsonString = jsonEncode(settings.toJson());
      
      await prefs.setString(key, jsonString);
      
      // Update cache
      _settingsCache[settings.modelId] = settings;
      
      // If this is the active model, update active settings
      if (_activeSettings?.modelId == settings.modelId) {
        _activeSettings = settings;
      }
      
      _logger.logInfo('[ModelSettingsProvider] Saved settings for ${settings.modelId}');
      notifyListeners();
    } catch (e) {
      _logger.logError('[ModelSettingsProvider] Error saving settings: $e');
      rethrow;
    }
  }

  /// Set active model and load its settings
  Future<void> setActiveModel(String modelId, [BuildContext? context]) async {
    if (_activeSettings?.modelId == modelId) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // First check if we have stored settings
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix$modelId';
      final jsonString = prefs.getString(key);
      
      ModelSettings settings;
      if (jsonString != null && jsonString.isNotEmpty) {
        // Use stored settings
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        settings = ModelSettings.fromJson(jsonMap);
        
        // Check if settings have API info, if not refresh from API
        if (settings.apiContextLength == null || settings.apiMaxTokens == null) {
          final freshSettings = await _createSettingsFromModelInfo(modelId, context);
          
          // Merge: keep user preferences, update API info
          settings = settings.copyWith(
            maxContextLength: freshSettings.maxContextLength,
            apiMaxTokens: freshSettings.apiMaxTokens,
            apiContextLength: freshSettings.apiContextLength,
            apiMaxTemperature: freshSettings.apiMaxTemperature,
            apiMinTemperature: freshSettings.apiMinTemperature,
          );
          
          // Save updated settings
          await saveSettings(settings);
        }
      } else {
        // No stored settings - create from API model info
        settings = await _createSettingsFromModelInfo(modelId, context);
        
        // Save the initial settings
        await saveSettings(settings);
      }

      _activeSettings = settings;
      _settingsCache[modelId] = settings;
      _logger.logInfo('[ModelSettingsProvider] Active model set to $modelId with settings: $settings');
      notifyListeners();
    } catch (e) {
      _logger.logError('[ModelSettingsProvider] Error setting active model: $e');
      // Fallback to defaults
      final defaultSettings = ModelSettings.defaultForModel(modelId);
      _activeSettings = defaultSettings;
      _settingsCache[modelId] = defaultSettings;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update active model settings
  Future<void> updateActiveSettings(ModelSettings settings) async {
    _activeSettings = settings;
    await saveSettings(settings);
  }

  /// Update a specific parameter for the active model
  Future<void> updateActiveParameter({
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    String? systemPrompt,
    bool? stream,
    int? maxContextLength,
    bool? reasoningEnabled,
  }) async {
    if (_activeSettings == null) {
      _logger.logWarning('[ModelSettingsProvider] No active model to update');
      return;
    }

    final updated = _activeSettings!.copyWith(
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      systemPrompt: systemPrompt,
      stream: stream,
      maxContextLength: maxContextLength,
      reasoningEnabled: reasoningEnabled,
    );

    await updateActiveSettings(updated);
  }

  /// Get settings for any model (without setting as active)
  /// Pass BuildContext to access ThemeProvider for model info
  Future<ModelSettings> getSettings(String modelId, [BuildContext? context]) async {
    return await loadSettings(modelId, context);
  }

  /// Delete settings for a model
  Future<void> deleteSettings(String modelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix$modelId';
      await prefs.remove(key);
      
      _settingsCache.remove(modelId);
      
      // If this was the active model, clear active settings
      if (_activeSettings?.modelId == modelId) {
        _activeSettings = null;
      }
      
      _logger.logInfo('[ModelSettingsProvider] Deleted settings for $modelId');
      notifyListeners();
    } catch (e) {
      _logger.logError('[ModelSettingsProvider] Error deleting settings: $e');
    }
  }

  /// Reset settings for a model to defaults
  Future<void> resetSettings(String modelId) async {
    final defaultSettings = ModelSettings.defaultForModel(modelId);
    await saveSettings(defaultSettings);
    
    // If this is the active model, update active settings
    if (_activeSettings?.modelId == modelId) {
      _activeSettings = defaultSettings;
    }
    
    _logger.logInfo('[ModelSettingsProvider] Reset settings for $modelId to defaults');
    notifyListeners();
  }

  /// Reset active model settings to defaults
  Future<void> resetActiveSettings() async {
    if (_activeSettings == null) return;
    
    await resetSettings(_activeSettings!.modelId);
  }

  /// Get all stored model IDs
  Future<List<String>> getAllStoredModelIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      return keys
          .where((key) => key.startsWith(_settingsPrefix))
          .map((key) => key.substring(_settingsPrefix.length))
          .toList();
    } catch (e) {
      _logger.logError('[ModelSettingsProvider] Error getting stored model IDs: $e');
      return [];
    }
  }

  /// Clear all cached settings (useful for logout/reset)
  Future<void> clearAll() async {
    _settingsCache.clear();
    _activeSettings = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_settingsPrefix)) {
          await prefs.remove(key);
        }
      }
      _logger.logInfo('[ModelSettingsProvider] Cleared all model settings');
      notifyListeners();
    } catch (e) {
      _logger.logError('[ModelSettingsProvider] Error clearing all settings: $e');
    }
  }
}
