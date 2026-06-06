import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/models/chat_model.dart';
import 'package:chatorai/providers/provider_settings_provider.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/utils/model_utils.dart';

final _logger = LogTags.settings;

const _defaultBaseUrl = 'https://openrouter.ai/api/v1';
const _prefBaseUrl = 'openrouter_base_url';

class ModelState {
  final List<ChatModel> availableModels;
  final String selectedModelId;
  final ChatModel? selectedModelObject;
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

  List<ChatModel> get favoriteModels => availableModels
      .where((model) => favoriteModelIds.contains(model.id))
      .toList();

  ModelState copyWith({
    List<ChatModel>? availableModels,
    String? selectedModelId,
    ChatModel? selectedModelObject,
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
  static const String _apiKeyPref = 'openrouter_api_key';

  bool _settingsLoaded = false;

  @override
  ModelState build() {
    if (!_settingsLoaded) {
      _settingsLoaded = true;
      _loadSettingsAsync();
    }
    return const ModelState();
  }

  Future<String?> _getApiKey() async {
    // Try provider settings first (new system)
    try {
      final providerSettings = ref.read(providerSettingsProvider);
      final openRouter = providerSettings.getSettings('openrouter');
      if (openRouter.apiKey != null && openRouter.apiKey!.isNotEmpty) {
        return openRouter.apiKey;
      }
    } catch (_) {}
    // Fallback to legacy SharedPreferences key
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

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

  Future<List<ChatModel>> _fetchModels() async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('OpenRouter API key not configured');
    }

    String? effectiveBaseUrl;
    // Try provider settings first (new system)
    try {
      final providerSettings = ref.read(providerSettingsProvider);
      final openRouter = providerSettings.getSettings('openrouter');
      if (openRouter.baseUrl != null && openRouter.baseUrl!.isNotEmpty) {
        effectiveBaseUrl = openRouter.baseUrl!.trim();
      }
    } catch (_) {}
    if (effectiveBaseUrl == null || effectiveBaseUrl.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString(_prefBaseUrl)?.trim();
      effectiveBaseUrl = (baseUrl == null || baseUrl.isEmpty)
          ? _defaultBaseUrl
          : baseUrl;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://chatorai.app',
          'X-Title': 'ChatORAI',
        },
      ),
    );

    final response = await dio.get('/models');
    final data = response.data;

    List<ChatModel> models;
    if (data is Map && data.containsKey('data')) {
      final modelsData = data['data'] is List
          ? data['data'] as List
          : [data['data']];
      models = modelsData
          .map((m) => ChatModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } else if (data is List) {
      models = data
          .map((m) => ChatModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Unexpected API response format');
    }

    return models;
  }

  Future<void> _loadModelsAsync() async {
    if (state.modelsLoaded || state.isLoadingModels) return;

    state = state.copyWith(isLoadingModels: true);

    try {
      _logger.logInfo('[ModelNotifier] Loading models from OpenRouter...');

      final models = await _fetchModels();
      var availableModels = ModelUtils.deduplicateModels(models);
      availableModels = _filterByProviderSettings(availableModels);

      String selectedModelId = state.selectedModelId;
      ChatModel? selectedModelObject;

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
        final retryModels = await _fetchModels();
        var availableModels = ModelUtils.deduplicateModels(retryModels);
        availableModels = _filterByProviderSettings(availableModels);

        ChatModel? selectedModelObject;
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

  List<ChatModel> _filterByProviderSettings(List<ChatModel> models) {
    try {
      final providerSettings = ref.read(providerSettingsProvider);
      final selectedIds = <String>{};
      for (final entry in providerSettings.providers.entries) {
        if (!entry.value.enabled) continue;
        selectedIds.addAll(entry.value.selectedModelIds);
      }
      if (selectedIds.isEmpty) return models;
      return models.where((m) => selectedIds.contains(m.id)).toList();
    } catch (_) {
      return models;
    }
  }

  /// Reset all model state and force a fresh reload.
  Future<void> resetAndReloadModels() async {
    state = state.copyWith(
      modelsLoaded: false,
      availableModels: [],
      selectedModelObject: null,
    );
    await _loadModelsAsync();
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

  ChatModel? getModelById(String modelId) {
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
    } else {
      favoriteModelIds.add(modelId);
    }

    state = state.copyWith(favoriteModelIds: favoriteModelIds);
    await _saveSettings();
  }

  bool modelSupportsImages(String modelId) {
    final model = getModelById(modelId);
    if (model == null) return false;
    return model.capabilities.multimodal || model.capabilities.vision;
  }

  bool modelSupportsImagesSelected() {
    if (state.selectedModelId.isEmpty) return false;
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

final modelProvider = NotifierProvider<ModelNotifier, ModelState>(
  ModelNotifier.new,
);
