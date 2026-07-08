// ignore_for_file: unused_import
import 'dart:async';
import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/features/chat/data/models/model_card_model.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = LogTags.settings;

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
  final Completer<void> _settingsLoaded = Completer<void>();
  bool _loadingModels = false;

  @override
  ModelState build() {
    ref.listen<AsyncValue<ProviderCatalogService>>(
      catalogInitializationProvider,
      (previous, next) {
        if (previous != next && next.hasValue) {
          _loadModelsAsync();
        }
      },
    );

    if (!_settingsLoaded.isCompleted) {
      _loadSettingsAsync();
    }
    return const ModelState();
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
      _settingsLoaded.complete();
    } catch (e) {
      _logger.logError('[ModelNotifier] Error loading settings: $e');
      state = state.copyWith(isLoading: false);
      _settingsLoaded.complete();
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

  /// Loads available models from the catalog.
  Future<void> _loadModelsAsync({bool forceRefresh = false}) async {
    if (_loadingModels) return;
    _loadingModels = true;
    state = state.copyWith(isLoadingModels: true);

    try {
      await _settingsLoaded.future;

      _logger.logInfo(
        '[ModelNotifier] Loading models from catalog… forceRefresh=$forceRefresh',
      );

      final catalog = await ref.read(catalogInitializationProvider.future);

      List<ModelConfig> visibleModels(ProviderCatalogService cat) {
        final allModels = cat.getAllModels();
        _logger.logInfo(
          '[ModelNotifier] visibleModels: getAllModels=${allModels.length}',
        );
        final visible = allModels.where((m) {
          final selectedIds = cat.getSelectedModelIds(m.providerId);
          return selectedIds.isEmpty || selectedIds.contains(m.id);
        }).toList();
        _logger.logInfo(
          '[ModelNotifier] visibleModels: visible=${visible.length}',
        );
        return visible;
      }

      var availableModels = visibleModels(
        catalog,
      ).map(ChatModel.fromModelConfig).toList();

      /// Only fetch from API if:
      /// 1. Cache is completely empty, OR
      /// 2. User explicitly requested refresh
      /// Note: NOT triggered by stale pricing (that would overwrite user selections)
      final hasAnyModels = availableModels.isNotEmpty;

      if (!hasAnyModels || forceRefresh) {
        final providers = catalog.getAllProviders();
        for (final prov in providers) {
          try {
            await catalog.discoverModels(prov.id, forceRefresh: forceRefresh);
          } catch (_) {}
        }
        availableModels = visibleModels(
          catalog,
        ).map(ChatModel.fromModelConfig).toList();
      }

      String selectedModelId = state.selectedModelId;
      ChatModel? selectedModelObject;

      if (selectedModelId.isEmpty) {
        String? catalogSelectedId;
        for (final prov in catalog.getAllProvidersRaw()) {
          final ids = catalog.getSelectedModelIds(prov.id);
          if (ids.isNotEmpty) {
            catalogSelectedId = ids.first;
            break;
          }
        }
        if (catalogSelectedId != null) {
          selectedModelId = catalogSelectedId;
        }
      }

      if (selectedModelId.isEmpty && availableModels.isNotEmpty) {
        selectedModelId = availableModels.first.id;
        selectedModelObject = availableModels.first;
        await _saveSettings();
      } else if (selectedModelId.isNotEmpty) {
        try {
          selectedModelObject = availableModels.firstWhere(
            (model) => model.id == selectedModelId,
          );
        } catch (_) {
          final allModels = catalog.getAllModelsRaw();
          try {
            selectedModelObject = allModels
                .map(ChatModel.fromModelConfig)
                .firstWhere((model) => model.id == selectedModelId);
          } catch (_) {
            selectedModelObject = null;
          }
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
        '[ModelNotifier] Loaded ${availableModels.length} models from catalog',
      );
    } catch (e) {
      _logger.logError('[ModelNotifier] Failed to load models: $e');
      state = state.copyWith(isLoadingModels: false);
    } finally {
      _loadingModels = false;
    }
  }

  Future<void> resetAndReloadModels({bool forceRefresh = false}) async {
    await reloadModels(forceRefresh: forceRefresh);
  }

  Future<void> reloadModels({bool forceRefresh = false}) async {
    await _loadModelsAsync(forceRefresh: forceRefresh);
  }

  Future<void> setSelectedModel(String modelId) async {
    if (state.selectedModelId == modelId) return;

    ChatModel? modelObject;
    var selectedId = modelId;

    if (state.availableModels.isEmpty) {
      modelObject = null;
    } else {
      try {
        modelObject = state.availableModels.firstWhere((m) => m.id == modelId);
      } catch (_) {
        modelObject = state.availableModels.first;
        selectedId = modelObject.id;
      }
    }

    state = state.copyWith(
      selectedModelId: selectedId,
      selectedModelObject: modelObject,
    );
    await _saveSettings();
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
