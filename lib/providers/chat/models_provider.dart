import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/providers.dart';

class ModelsScreenState {
  final List<OpenRouterModel> models;
  final List<OpenRouterModel> filteredModels;
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
    List<OpenRouterModel>? models,
    List<OpenRouterModel>? filteredModels,
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

class ModelsScreenNotifier extends Notifier<ModelsScreenState> {
  @override
  ModelsScreenState build() {
    Future.microtask(() => loadModels());
    return const ModelsScreenState();
  }

  Future<void> loadModels() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Watch the modelProvider to ensure it's initialized
      ref.watch(modelProvider);

      final modelNotifier = ref.read(modelProvider.notifier);
      await modelNotifier.waitForModelsLoaded();

      final modelState = ref.read(modelProvider);
      final models = modelState.availableModels;
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

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _updateFilteredModels();
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
    await modelNotifier.setSelectedModelSilent(modelId);
    modelNotifier.setSelectedModel(modelId);
  }

  void _updateFilteredModels() {
    final filtered = _applyFilters(state.models);
    state = state.copyWith(filteredModels: filtered);
  }

  List<OpenRouterModel> _applyFilters(List<OpenRouterModel> models) {
    final modelNotifier = ref.read(modelProvider.notifier);

    List<OpenRouterModel> filtered = state.showFavoritesOnly
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

final modelsScreenProvider =
    NotifierProvider<ModelsScreenNotifier, ModelsScreenState>(
      ModelsScreenNotifier.new,
    );
