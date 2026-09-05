import 'dart:async';

import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// STATE
// ===========================================================================

class ModelsScreenState {
  final List<ModelConfig> models;
  final List<ModelConfig> filteredModels;
  final bool isLoading;
  final bool showFavoritesOnly;
  final String searchQuery;
  final String? error;

  const ModelsScreenState({
    this.models = const [],
    this.filteredModels = const [],
    this.isLoading = false,
    this.showFavoritesOnly = false,
    this.searchQuery = '',
    this.error,
  });

  ModelsScreenState copyWith({
    List<ModelConfig>? models,
    List<ModelConfig>? filteredModels,
    bool? isLoading,
    bool? showFavoritesOnly,
    String? searchQuery,
    String? error,
  }) {
    return ModelsScreenState(
      models: models ?? this.models,
      filteredModels: filteredModels ?? this.filteredModels,
      isLoading: isLoading ?? this.isLoading,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

// ===========================================================================
// NOTIFIER
// ===========================================================================

class ModelsScreenNotifier extends Notifier<ModelsScreenState> {
  bool _modelsLoaded = false;
  Timer? _searchDebounce;

  @override
  ModelsScreenState build() {
    if (!_modelsLoaded) {
      _modelsLoaded = true;
      Future.microtask(() => loadModels());
    }
    return const ModelsScreenState();
  }

  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query);
      _updateFilteredModels();
    });
  }

  Future<void> loadModels({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final modelNotifier = ref.read(modelProvider.notifier);

      await modelNotifier.reloadModels(forceRefresh: forceRefresh);

      final modelState = ref.read(modelProvider);
      final models = modelState.availableModels;
      LogTags.settings.logInfo(
        '[ModelsScreen] loadModels: availableModels=${models.length}',
      );
      if (models.isNotEmpty) {
        LogTags.settings.logInfo(
          '[ModelsScreen] sample IDs: ${models.take(5).map((m) => m.id).join(', ')}',
        );
        LogTags.settings.logInfo(
          '[ModelsScreen] sample providers: ${models.take(5).map((m) => '${m.id}=>${m.provider}').join(', ')}',
        );
      }
      final filtered = _applyFilters(models);
      LogTags.settings.logInfo(
        '[ModelsScreen] loadModels: filteredModels=${filtered.length}',
      );

      state = state.copyWith(
        models: models,
        filteredModels: filtered,
        isLoading: false,
      );
    } catch (e) {
      LogTags.settings.logError('[ModelsScreen] loadModels failed: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    _updateFilteredModels();
  }

  void toggleFavoritesFilter() {
    state = state.copyWith(showFavoritesOnly: !state.showFavoritesOnly);
    _updateFilteredModels();
  }

  void toggleFavorite(String modelId) {
    final modelNotifier = ref.read(modelProvider.notifier);
    modelNotifier.toggleFavoriteModel(modelId);
    _updateFilteredModels();
  }

  bool isFavorite(String modelId) {
    final modelNotifier = ref.read(modelProvider.notifier);
    return modelNotifier.isFavoriteModel(modelId);
  }

  Future<void> selectModel(String modelId) async {
    final modelNotifier = ref.read(modelProvider.notifier);
    await modelNotifier.setSelectedModel(modelId);
  }

  void _updateFilteredModels() {
    final filtered = _applyFilters(state.models);
    state = state.copyWith(filteredModels: filtered);
  }

  List<ModelConfig> _applyFilters(List<ModelConfig> models) {
    final modelNotifier = ref.read(modelProvider.notifier);

    List<ModelConfig> filtered = state.showFavoritesOnly
        ? models
              .where((model) => modelNotifier.isFavoriteModel(model.id))
              .toList()
        : models;

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((model) {
        return model.displayName.toLowerCase().contains(query) ||
            model.id.toLowerCase().contains(query) ||
            (model.description?.toLowerCase().contains(query) ?? false) ||
            model.providerId.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }
}

// ===========================================================================
// PROVIDER
// ===========================================================================

final modelsScreenProvider =
    NotifierProvider<ModelsScreenNotifier, ModelsScreenState>(
      ModelsScreenNotifier.new,
    );
