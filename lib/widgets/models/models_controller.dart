import 'package:flutter/material.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/providers/model_provider.dart';
import 'package:chatorai/utils/logger.dart';

final _logger = LogTags.modelsScreen;

class ModelsController extends ChangeNotifier {
  final ModelProvider modelProvider;
  final void Function(String, OpenRouterModel?)? onModelSelected;
  final String? currentModelId;

  List<OpenRouterModel> _models = [];
  List<OpenRouterModel> _filteredModels = [];
  bool _isLoading = false;
  bool _showFavoritesOnly = false;
  String _searchQuery = '';

  late TextEditingController searchController;

  List<OpenRouterModel> get models => _models;
  List<OpenRouterModel> get filteredModels => _filteredModels;
  bool get isLoading => _isLoading;
  bool get showFavoritesOnly => _showFavoritesOnly;
  String get searchQuery => _searchQuery;

  ModelsController({
    required this.modelProvider,
    this.onModelSelected,
    this.currentModelId,
  }) {
    searchController = TextEditingController();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchQuery = searchController.text.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<OpenRouterModel> models = _showFavoritesOnly
        ? _models
              .where((model) => modelProvider.isFavoriteModel(model.id))
              .toList()
        : _models;

    if (_searchQuery.isEmpty) {
      _filteredModels = models;
    } else {
      _filteredModels = models.where((model) {
        return model.name.toLowerCase().contains(_searchQuery) ||
            model.id.toLowerCase().contains(_searchQuery) ||
            model.description.toLowerCase().contains(_searchQuery) ||
            (model.provider?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }

  void clearSearch() {
    searchController.clear();
    _applyFilters();
  }

  void toggleFavoritesFilter() {
    _showFavoritesOnly = !_showFavoritesOnly;
    _applyFilters();
    notifyListeners();
  }

  void toggleFavorite(String modelId) {
    modelProvider.toggleFavoriteModel(modelId);
    if (_showFavoritesOnly) {
      _applyFilters();
    }
    notifyListeners();
  }

  bool isFavorite(String modelId) {
    return modelProvider.isFavoriteModel(modelId);
  }

  void selectModel(BuildContext context, OpenRouterModel model) async {
    try {
      await modelProvider.setSelectedModelSilent(model.id);

      if (onModelSelected != null) {
        onModelSelected!(model.id, model);
      }

      if (context.mounted) {
        Navigator.of(context).pop(model);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        modelProvider.setSelectedModel(model.id);
      });
    } catch (e) {
      _logger.logError('[ModelsController] Failed to select model: $e');
    }
  }

  Future<void> loadModels() async {
    _isLoading = true;
    notifyListeners();

    try {
      await modelProvider.waitForModelsLoaded();
      _models = modelProvider.availableModels;
      _applyFilters();
      _logger.logInfo(
        '[ModelsController] Successfully loaded ${_models.length} models',
      );
    } catch (e) {
      _logger.logError('[ModelsController] Failed to load models: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
