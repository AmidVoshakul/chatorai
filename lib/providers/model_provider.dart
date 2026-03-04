// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/utils/logger.dart';

// Initialize logger for this provider
final _logger = LogTags.settings;

/// Provider responsible for AI model management:
/// - Loading available models from OpenRouter
/// - Selecting current model
/// - Managing favorite models
/// - Checking model capabilities (image support, etc.)
/// - Model-specific settings integration
class ModelProvider with ChangeNotifier {
  static const String _selectedModelKey = 'selected_model_id';
  static const String _favoriteModelsKey = 'favorite_models';

  // OpenRouterService dependency (injected via setter)
  OpenRouterService? _openRouterService;

  // Model data
  List<OpenRouterModel> _availableModels = [];
  String _selectedModelId = '';
  OpenRouterModel? _selectedModelObject;
  List<String> _favoriteModelIds = [];
  bool _modelsLoaded = false;
  bool _isLoadingModels = false;
  bool _settingsLoaded = false;

  // Getters
  List<OpenRouterModel> get availableModels => _availableModels;
  String get selectedModelId => _selectedModelId;
  OpenRouterModel? get selectedModelObject => _selectedModelObject;
  List<String> get favoriteModelIds => _favoriteModelIds;
  bool get modelsLoaded => _modelsLoaded;
  bool get isLoadingModels => _isLoadingModels;

  // Computed getters
  List<OpenRouterModel> get favoriteModels => _availableModels
      .where((model) => _favoriteModelIds.contains(model.id))
      .toList();

  ModelProvider() {
    loadSettings();
  }

  /// Setter for dependency injection of OpenRouterService
  set openRouterService(OpenRouterService service) {
    if (_openRouterService != service) {
      _openRouterService = service;
      // Trigger model loading if settings are loaded and models not yet loaded
      if (_settingsLoaded && !_modelsLoaded && !_isLoadingModels) {
        _loadModelsAsync();
      }
    }
  }

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _selectedModelId = prefs.getString(_selectedModelKey) ?? '';
      final favoriteModelsString =
          prefs.getStringList(_favoriteModelsKey) ?? [];
      _favoriteModelIds = favoriteModelsString;

      _settingsLoaded = true;
      _logger.logInfo('[ModelProvider] Settings loaded');
      notifyListeners();

      // Trigger model loading if OpenRouterService is available and models not yet loaded
      if (_openRouterService != null && !_modelsLoaded && !_isLoadingModels) {
        _loadModelsAsync();
      }
    } catch (e) {
      _logger.logError('[ModelProvider] Error loading settings: $e');
    }
  }

  /// Save current settings to SharedPreferences
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_selectedModelKey, _selectedModelId);
      await prefs.setStringList(_favoriteModelsKey, _favoriteModelIds);

      _logger.logVerbose('[ModelProvider] Settings saved');
    } catch (e) {
      _logger.logError('[ModelProvider] Error saving settings: $e');
    }
  }

  /// Load models asynchronously from OpenRouter
  Future<void> _loadModelsAsync() async {
    // Use fallback for backward compatibility
    final openRouterService = _openRouterService ?? OpenRouterService();

    if (_modelsLoaded || _isLoadingModels) return;

    _isLoadingModels = true;
    notifyListeners();

    try {
      _logger.logInfo('[ModelProvider] Loading models from OpenRouter...');

      // Wait for OpenRouterService to be fully initialized
      int retryCount = 0;
      const maxRetries = 20; // Wait up to 10 seconds (20 * 500ms)

      while (retryCount < maxRetries) {
        if (openRouterService.isReady()) {
          _logger.logInfo('[ModelProvider] OpenRouterService is ready');
          break;
        }

        await Future<void>.delayed(const Duration(milliseconds: 500));
        retryCount++;
      }

      if (retryCount >= maxRetries) {
        _logger.logWarning(
          '[ModelProvider] OpenRouterService initialization timeout, proceeding anyway...',
        );
      }

      final models = await openRouterService.getAvailableModels();

      // Remove duplicates using more robust deduplication method
      _availableModels = _deduplicateModels(models);
      _modelsLoaded = true;

      // Set the selected model object from saved ID
      if (_selectedModelObject == null) {
        if (_selectedModelId.isEmpty) {
          // No saved ID, use first available model
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
        notifyListeners();
      } else if (!_availableModels.any((m) => m.id == _selectedModelId)) {
        // Current selection is not available, find a replacement
        final defaultModel = _availableModels.first;
        await setSelectedModel(defaultModel.id);
      }

      _logger.logInfo(
        '[ModelProvider] Successfully loaded ${models.length} models',
      );
    } catch (e) {
      _logger.logError('[ModelProvider] Failed to load models: $e');
      _logger.logWarning(
        '[ModelProvider] Retrying model loading in 2 seconds...',
      );

      // Retry after a short delay
      await Future<void>.delayed(const Duration(seconds: 2));

      try {
        _logger.logInfo('[ModelProvider] Retrying model loading...');
        final retryService = _openRouterService ?? OpenRouterService();
        final retryModels = await retryService.getAvailableModels();

        _availableModels = _deduplicateModels(retryModels);
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

        _logger.logInfo(
          '[ModelProvider] Successfully loaded ${retryModels.length} models on retry',
        );
      } catch (retryError) {
        _logger.logError(
          '[ModelProvider] Failed to load models on retry: $retryError',
        );
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

  /// Set selected model by ID
  Future<void> setSelectedModel(String modelId) async {
    if (_selectedModelId != modelId) {
      _selectedModelId = modelId;

      // Find the model object
      final modelObject = _availableModels.firstWhere(
        (model) => model.id == modelId,
        orElse: () => _availableModels.first,
      );
      _selectedModelObject = modelObject;

      await saveSettings();
      notifyListeners();
    }
  }

  /// Set selected model without notifying listeners immediately
  /// Useful for navigation scenarios to avoid race conditions
  Future<void> setSelectedModelSilent(String modelId) async {
    if (_selectedModelId != modelId) {
      _selectedModelId = modelId;

      final modelObject = _availableModels.firstWhere(
        (model) => model.id == modelId,
        orElse: () => _availableModels.first,
      );
      _selectedModelObject = modelObject;

      await saveSettings();
    }
  }

  /// Get model by ID
  OpenRouterModel? getModelById(String modelId) {
    try {
      return _availableModels.firstWhere((model) => model.id == modelId);
    } catch (e) {
      return null;
    }
  }

  /// Get favorite models
  List<OpenRouterModel> getFavoriteModels() {
    return favoriteModels;
  }

  /// Check if a model is in favorites
  bool isFavoriteModel(String modelId) {
    return _favoriteModelIds.contains(modelId);
  }

  /// Toggle favorite status for a model
  Future<void> toggleFavoriteModel(String modelId) async {
    if (_favoriteModelIds.contains(modelId)) {
      _favoriteModelIds.remove(modelId);
      _logger.logInfo('[ModelProvider] Removed model from favorites: $modelId');
    } else {
      _favoriteModelIds.add(modelId);
      _logger.logInfo('[ModelProvider] Added model to favorites: $modelId');
    }

    await saveSettings();
    notifyListeners();
  }

  /// Check if a model supports images using API data
  /// Returns true if model supports images, false otherwise
  /// Uses API data from architecture.input_modalities
  bool modelSupportsImages(String modelId) {
    final model = getModelById(modelId);

    if (model == null) {
      _logger.logWarning(
        '[ModelProvider] Model $modelId not found in available models, returning false',
      );
      return false;
    }

    final supportsMultimodal = model.capabilities.multimodal;
    final supportsVision = model.capabilities.vision;

    if (supportsMultimodal || supportsVision) {
      _logger.logInfo(
        '[ModelProvider] Model $modelId supports images (API: multimodal=$supportsMultimodal, vision=$supportsVision)',
      );
      return true;
    }

    _logger.logInfo(
      '[ModelProvider] Model $modelId does not support images (API data)',
    );
    return false;
  }

  /// Check if the currently selected model supports images
  bool modelSupportsImagesSelected() {
    if (_selectedModelId.isEmpty) {
      _logger.logWarning('[ModelProvider] No selected model ID');
      return false;
    }
    return modelSupportsImages(_selectedModelId);
  }

  /// Check if a model supports images with fallback
  bool checkModelSupportsImages(String modelId) {
    final apiSupport = modelSupportsImages(modelId);
    if (apiSupport) return true;

    if (!_modelsLoaded) {
      _logger.logWarning(
        '[ModelProvider] Models not loaded yet, returning false for $modelId',
      );
      return false;
    }

    return false;
  }

  /// Remove duplicate models using a more robust approach
  List<OpenRouterModel> _deduplicateModels(List<OpenRouterModel> models) {
    final Map<String, OpenRouterModel> uniqueModels = {};

    for (final model in models) {
      uniqueModels[model.id] = model;
    }

    return uniqueModels.values.toList();
  }

  /// Wait for models to be loaded with timeout
  Future<void> waitForModelsLoaded({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_modelsLoaded) return;

    final stopwatch = Stopwatch()..start();
    while (!_modelsLoaded && stopwatch.elapsed < timeout) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    stopwatch.stop();
  }

  /// Reset settings for testing
  @visibleForTesting
  void resetForTesting() {
    _selectedModelId = '';
    _selectedModelObject = null;
    _availableModels.clear();
    _modelsLoaded = false;
    _isLoadingModels = false;
    _favoriteModelIds.clear();
  }
}
