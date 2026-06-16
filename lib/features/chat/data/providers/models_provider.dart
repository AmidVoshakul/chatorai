import 'dart:async';

import 'package:chatorai/features/chat/data/models/chat_model.dart';
import 'package:chatorai/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// STATE
// ===========================================================================

class ModelsScreenState {
  final List<ChatModel> models;
  final List<ChatModel> filteredModels;
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
    List<ChatModel>? models,
    List<ChatModel>? filteredModels,
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

  Future<void> loadModels() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final modelNotifier = ref.read(modelProvider.notifier);

      // Wait for models to be loaded (with timeout handling)
      await modelNotifier.waitForModelsLoaded(
        timeout: const Duration(seconds: 15),
      );

      final modelState = ref.read(modelProvider);

      // If still no models after waiting, try forcing a reload
      if (modelState.availableModels.isEmpty && !modelState.modelsLoaded) {
        await modelNotifier.reloadModels();
        await Future.delayed(const Duration(seconds: 2));
      }

      final modelState2 = ref.read(modelProvider);
      final models = modelState2.availableModels;
      final filtered = _applyFilters(models);

      state = state.copyWith(
        models: models,
        filteredModels: filtered,
        isLoading: false,
      );
    } catch (e) {
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

  List<ChatModel> _applyFilters(List<ChatModel> models) {
    final modelNotifier = ref.read(modelProvider.notifier);

    List<ChatModel> filtered = state.showFavoritesOnly
        ? models
              .where((model) => modelNotifier.isFavoriteModel(model.id))
              .toList()
        : models;

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((model) {
        return model.name.toLowerCase().contains(query) ||
            model.id.toLowerCase().contains(query) ||
            model.description.toLowerCase().contains(query) ||
            (model.provider?.toLowerCase().contains(query) ?? false);
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
