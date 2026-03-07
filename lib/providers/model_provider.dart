import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/services/network_service.dart';
import 'package:chatorai/utils/logger.dart';

final _logger = LogTags.settings;

class ModelState {
  final List<OpenRouterModel> availableModels;
  final String selectedModelId;
  final OpenRouterModel? selectedModelObject;
  final List<String> favoriteModelIds;
  final bool modelsLoaded;
  final bool isLoadingModels;
  final bool isLoading;

  const ModelState({
    this.availableModels = const [],
    this.selectedModelId = '',
    this.selectedModelObject,
    this.favoriteModelIds = const [],
    this.modelsLoaded = false,
    this.isLoadingModels = false,
    this.isLoading = true,
  });

  List<OpenRouterModel> get favoriteModels => availableModels
      .where((model) => favoriteModelIds.contains(model.id))
      .toList();

  ModelState copyWith({
    List<OpenRouterModel>? availableModels,
    String? selectedModelId,
    OpenRouterModel? selectedModelObject,
    List<String>? favoriteModelIds,
    bool? modelsLoaded,
    bool? isLoadingModels,
    bool? isLoading,
  }) {
    return ModelState(
      availableModels: availableModels ?? this.availableModels,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      selectedModelObject: selectedModelObject ?? this.selectedModelObject,
      favoriteModelIds: favoriteModelIds ?? this.favoriteModelIds,
      modelsLoaded: modelsLoaded ?? this.modelsLoaded,
      isLoadingModels: isLoadingModels ?? this.isLoadingModels,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ModelNotifier extends Notifier<ModelState> {
  static const String _selectedModelKey = 'selected_model_id';
  static const String _favoriteModelsKey = 'favorite_models';

  @override
  ModelState build() {
    _loadSettingsAsync();
    return const ModelState();
  }

  OpenRouterService get _openRouterService =>
      ref.read(openRouterServiceProvider);

  Future<void> _loadSettingsAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedModelId = prefs.getString(_selectedModelKey) ?? '';
      final favoriteModelIds = prefs.getStringList(_favoriteModelsKey) ?? [];

      state = state.copyWith(
        selectedModelId: selectedModelId,
        favoriteModelIds: favoriteModelIds,
        isLoading: false,
      );
      _logger.logInfo('[ModelNotifier] Settings loaded');

      _loadModelsAsync();
    } catch (e) {
      _logger.logError('[ModelNotifier] Error loading settings: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedModelKey, state.selectedModelId);
      await prefs.setStringList(_favoriteModelsKey, state.favoriteModelIds);
      _logger.logVerbose('[ModelNotifier] Settings saved');
    } catch (e) {
      _logger.logError('[ModelNotifier] Error saving settings: $e');
    }
  }

  Future<void> _loadModelsAsync() async {
    if (state.modelsLoaded || state.isLoadingModels) return;

    state = state.copyWith(isLoadingModels: true);

    try {
      _logger.logInfo('[ModelNotifier] Loading models from OpenRouter...');

      final openRouterService = _openRouterService;

      // Wait for service to be ready (includes waiting for async initialization)
      int retryCount = 0;
      const maxRetries = 30; // 15 seconds max wait

      while (retryCount < maxRetries) {
        if (openRouterService.isReady()) {
          _logger.logInfo(
            '[ModelNotifier] Service is ready, loading models...',
          );
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
        retryCount++;
      }

      if (!openRouterService.isReady()) {
        _logger.logError('[ModelNotifier] Service not ready after max retries');
        state = state.copyWith(modelsLoaded: true, isLoadingModels: false);
        return;
      }

      final models = await openRouterService.getAvailableModels();
      final availableModels = _deduplicateModels(models);

      String selectedModelId = state.selectedModelId;
      OpenRouterModel? selectedModelObject;

      if (selectedModelId.isEmpty && availableModels.isNotEmpty) {
        selectedModelId = availableModels.first.id;
        selectedModelObject = availableModels.first;
        await _saveSettings();
      } else if (availableModels.isNotEmpty) {
        try {
          selectedModelObject = availableModels.firstWhere(
            (model) => model.id == selectedModelId,
          );
        } catch (_) {
          selectedModelObject = availableModels.first;
          selectedModelId = selectedModelObject.id;
          await _saveSettings();
        }
      }

      state = state.copyWith(
        availableModels: availableModels,
        selectedModelId: selectedModelId,
        selectedModelObject: selectedModelObject,
        modelsLoaded: true,
        isLoadingModels: false,
      );

      _logger.logInfo(
        '[ModelNotifier] Successfully loaded ${models.length} models',
      );
    } catch (e) {
      _logger.logError('[ModelNotifier] Failed to load models: $e');

      await Future<void>.delayed(const Duration(seconds: 2));

      try {
        final retryModels = await _openRouterService.getAvailableModels();
        final availableModels = _deduplicateModels(retryModels);

        OpenRouterModel? selectedModelObject;
        if (availableModels.isNotEmpty) {
          try {
            selectedModelObject = availableModels.firstWhere(
              (model) => model.id == state.selectedModelId,
            );
          } catch (_) {
            selectedModelObject = availableModels.first;
          }
        }

        state = state.copyWith(
          availableModels: availableModels,
          selectedModelObject: selectedModelObject,
          modelsLoaded: true,
          isLoadingModels: false,
        );
      } catch (retryError) {
        _logger.logError(
          '[ModelNotifier] Failed to load models on retry: $retryError',
        );
        state = state.copyWith(modelsLoaded: true, isLoadingModels: false);
      }
    }
  }

  List<OpenRouterModel> _deduplicateModels(List<OpenRouterModel> models) {
    final Map<String, OpenRouterModel> uniqueModels = {};
    for (final model in models) {
      uniqueModels[model.id] = model;
    }
    return uniqueModels.values.toList();
  }

  Future<void> reloadModels() async {
    state = state.copyWith(
      modelsLoaded: false,
      availableModels: [],
      selectedModelObject: null,
    );
    await _loadModelsAsync();
  }

  Future<void> setSelectedModel(String modelId) async {
    if (state.selectedModelId != modelId) {
      final modelObject = state.availableModels.firstWhere(
        (model) => model.id == modelId,
        orElse: () => state.availableModels.first,
      );

      state = state.copyWith(
        selectedModelId: modelId,
        selectedModelObject: modelObject,
      );
      await _saveSettings();
    }
  }

  OpenRouterModel? getModelById(String modelId) {
    try {
      return state.availableModels.firstWhere((model) => model.id == modelId);
    } catch (e) {
      return null;
    }
  }

  bool isFavoriteModel(String modelId) {
    return state.favoriteModelIds.contains(modelId);
  }

  Future<void> toggleFavoriteModel(String modelId) async {
    final favoriteModelIds = List<String>.from(state.favoriteModelIds);
    if (favoriteModelIds.contains(modelId)) {
      favoriteModelIds.remove(modelId);
      _logger.logInfo('[ModelNotifier] Removed model from favorites: $modelId');
    } else {
      favoriteModelIds.add(modelId);
      _logger.logInfo('[ModelNotifier] Added model to favorites: $modelId');
    }

    state = state.copyWith(favoriteModelIds: favoriteModelIds);
    await _saveSettings();
  }

  bool modelSupportsImages(String modelId) {
    final model = getModelById(modelId);
    if (model == null) {
      return false;
    }
    return model.capabilities.multimodal || model.capabilities.vision;
  }

  bool modelSupportsImagesSelected() {
    if (state.selectedModelId.isEmpty) {
      return false;
    }
    return modelSupportsImages(state.selectedModelId);
  }

  Future<void> waitForModelsLoaded({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (state.modelsLoaded) return;

    final stopwatch = Stopwatch()..start();
    while (!state.modelsLoaded && stopwatch.elapsed < timeout) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    stopwatch.stop();
  }
}

final openRouterServiceProvider = Provider<OpenRouterService>((ref) {
  final networkState = ref.watch(networkServiceProvider);
  final service = OpenRouterService(isConnected: networkState.isConnected);

  // Listen to network changes and update service
  ref.listen(networkServiceProvider, (previous, next) {
    service.setConnectivityStatus(next.isConnected);
  });

  return service;
});

final modelProvider = NotifierProvider<ModelNotifier, ModelState>(
  ModelNotifier.new,
);
