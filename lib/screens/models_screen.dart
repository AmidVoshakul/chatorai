import 'package:flutter/material.dart';
import 'package:chatorai/themes/app_theme.dart' show UbuntuColors;
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:chatorai/providers/model_provider.dart';
import 'package:chatorai/services/openrouter_service.dart';

// Initialize logger for this screen
final _logger = LogTags.modelsScreen;

class ModelsScreen extends StatefulWidget {
  final Function(String, OpenRouterModel?)? onModelSelected;
  final String? currentModel;

  const ModelsScreen({super.key, this.onModelSelected, this.currentModel});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  late ModelProvider _modelProvider;
  List<OpenRouterModel> _models = [];
  List<OpenRouterModel> _filteredModels = [];
  bool _isLoading = false;
  bool _showFavoritesOnly = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _modelProvider = Provider.of<ModelProvider>(context, listen: false);
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);

    // Load models from ModelProvider or refresh if needed
    _loadModels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==============================================
  // Search functionality
  // ==============================================

  void _onSearchChanged() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      // Apply favorites filter first
      List<OpenRouterModel> models = _showFavoritesOnly
          ? _models
                .where((model) => _modelProvider.isFavoriteModel(model.id))
                .toList()
          : _models;

      // Then apply search filter
      if (searchQuery.isEmpty) {
        _filteredModels = models;
      } else {
        _filteredModels = models.where((model) {
          return model.name.toLowerCase().contains(searchQuery) ||
              model.id.toLowerCase().contains(searchQuery) ||
              model.description.toLowerCase().contains(searchQuery) ||
              (model.provider?.toLowerCase().contains(searchQuery) ?? false);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredModels = _showFavoritesOnly
          ? _models
                .where((model) => _modelProvider.isFavoriteModel(model.id))
                .toList()
          : _models;
    });
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
      _onSearchChanged(); // Reapply filters
    });
  }

  void _toggleFavorite(String modelId) {
    setState(() {
      _modelProvider.toggleFavoriteModel(modelId);
    });

    // Update filtered list if favorites filter is active
    if (_showFavoritesOnly) {
      _onSearchChanged();
    }
  }

  // ==============================================
  // Model selection
  // ==============================================

  void _selectModel(OpenRouterModel model) async {
    try {
      // Update model selection in ModelProvider (without notifyListeners yet)
      await _modelProvider.setSelectedModelSilent(model.id);

      // Call the callback with full model object for immediate use
      if (widget.onModelSelected != null) {
        // Pass both ID and full object
        widget.onModelSelected!(model.id, model);
      }

      // Navigate back first
      if (mounted) {
        Navigator.of(context).pop(model);
      }

      // Then notify listeners after navigation to update UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Use the regular setter to notify listeners
        _modelProvider.setSelectedModel(model.id);
      });
    } catch (e) {
      _logger.logError('[ModelsScreen] Failed to select model: $e');
    }
  }

  // ==============================================
  // Model loading
  // ==============================================

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Wait for models to be loaded in ModelProvider
      await _modelProvider.waitForModelsLoaded();

      // Get models from ModelProvider
      _models = _modelProvider.availableModels;

      // Preserve current filters and search state
      final searchQuery = _searchController.text.toLowerCase();
      List<OpenRouterModel> models = _showFavoritesOnly
          ? _models
                .where((model) => _modelProvider.isFavoriteModel(model.id))
                .toList()
          : _models;

      if (searchQuery.isEmpty) {
        _filteredModels = models;
      } else {
        _filteredModels = models.where((model) {
          return model.name.toLowerCase().contains(searchQuery) ||
              model.id.toLowerCase().contains(searchQuery) ||
              model.description.toLowerCase().contains(searchQuery) ||
              (model.provider?.toLowerCase().contains(searchQuery) ?? false);
        }).toList();
      }

      setState(() {
        _isLoading = false;
      });

      _logger.logInfo(
        '[ModelsScreen] Successfully loaded ${_models.length} models',
      );
    } catch (e) {
      _logger.logError('[ModelsScreen] Failed to load models: $e');
      setState(() {
        _isLoading = false;
      });

      // Log error instead of showing snackbar
      _logger.logError('[ModelsScreen] Failed to load models: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.models,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? Colors.red : null,
            ),
            onPressed: _toggleFavoritesFilter,
            tooltip: _showFavoritesOnly
                ? localizations.showAllModels
                : localizations.showFavoritesOnly,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar and filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _showFavoritesOnly
                        ? localizations.searchFavorites
                        : localizations.searchModels,
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showFavoritesOnly)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                            onPressed: _clearSearch,
                          ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[400]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[400]!,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).cardColor
                        : Colors.white,
                    isDense: true,
                  ),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: Theme.of(context).primaryColor,
                  textInputAction: TextInputAction.search,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredModels.isEmpty
                ? _buildEmptyState()
                : _buildModelsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadModels,
        tooltip: localizations.refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // ==============================================
  // UI Components
  // ==============================================

  Widget _buildModelsList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 1200; // Ширина для двух колонок

    if (isWideScreen) {
      // Двухколоночный режим для широких экранов
      return GridView.builder(
        padding: const EdgeInsets.all(12.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2, // Соотношение сторон карточки
        ),
        itemCount: _filteredModels.length,
        itemBuilder: (context, index) {
          final model = _filteredModels[index];
          return _buildModelCard(model);
        },
      );
    } else {
      // Одноколоночный режим для мобильных
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _filteredModels.length,
        itemBuilder: (context, index) {
          final model = _filteredModels[index];
          return _buildModelCard(model);
        },
      );
    }
  }

  Widget _buildModelCard(OpenRouterModel model) {
    final isSelected = widget.currentModel == model.id;
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 2,
      color: isSelected
          ? Theme.of(context).cardColor
          : Theme.of(context).cardColor,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.green, width: 2.0),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          _selectModel(model);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).textTheme.titleMedium!.color,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.id,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall!.color,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Favorite button
                  IconButton(
                    icon: Icon(
                      _modelProvider.isFavoriteModel(model.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _modelProvider.isFavoriteModel(model.id)
                          ? Colors.red
                          : null,
                      size: 24,
                    ),
                    onPressed: () {
                      _toggleFavorite(model.id);
                    },
                    tooltip: _modelProvider.isFavoriteModel(model.id)
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
                  // Info button
                  IconButton(
                    icon: const Icon(
                      Icons.info,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                    onPressed: () {
                      _showModelDetailsDialog(model);
                    },
                    tooltip: localizations.details,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? UbuntuColors.darkBorderColor
                    : UbuntuColors.lightBorderColor,
              ),
              const SizedBox(height: 12),
              Text(
                model.description,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${localizations.context}: ${model.formattedContextLength}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodySmall!.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildModelFeatures(model),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelFeatures(OpenRouterModel model) {
    final localizations = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // Free/Paid indicator
        Chip(
          label: Text(model.isFree ? localizations.free : localizations.paid),
          backgroundColor: model.isFree
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.orange.withValues(alpha: 0.15),
          side: BorderSide(
            color: model.isFree
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.orange.withValues(alpha: 0.3),
            width: 1.5,
          ),
          labelStyle: TextStyle(
            color: model.isFree ? Colors.green : Colors.orange,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: Icon(
            model.isFree ? Icons.attach_money : Icons.payment,
            size: 14,
            color: model.isFree ? Colors.green : Colors.orange,
          ),
        ),

        // Reasoning capability
        if (model.supportsReasoning)
          Chip(
            label: Text(localizations.reasoning),
            backgroundColor: Colors.blue.withValues(alpha: 0.15),
            side: BorderSide(
              color: Colors.blue.withValues(alpha: 0.3),
              width: 1.5,
            ),
            labelStyle: const TextStyle(
              color: Colors.blue,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: const Icon(Icons.psychology, size: 14, color: Colors.blue),
          ),

        // Multimodal capability
        if (model.supportsMultimodal)
          Chip(
            label: Text(localizations.multimodal),
            backgroundColor: Colors.purple.withValues(alpha: 0.15),
            side: BorderSide(
              color: Colors.purple.withValues(alpha: 0.3),
              width: 1.5,
            ),
            labelStyle: const TextStyle(
              color: Colors.purple,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: const Icon(
              Icons.view_in_ar,
              size: 14,
              color: Colors.purple,
            ),
          ),

        // Vision capability
        if (model.capabilities.vision)
          Chip(
            label: Text(localizations.vision),
            backgroundColor: Colors.deepOrange.withValues(alpha: 0.15),
            side: BorderSide(
              color: Colors.deepOrange.withValues(alpha: 0.3),
              width: 1.5,
            ),
            labelStyle: const TextStyle(
              color: Colors.deepOrange,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: const Icon(
              Icons.visibility,
              size: 14,
              color: Colors.deepOrange,
            ),
          ),

        // Tools capability
        if (model.capabilities.tools)
          Chip(
            label: Text(localizations.tools),
            backgroundColor: Colors.teal.withValues(alpha: 0.15),
            side: BorderSide(
              color: Colors.teal.withValues(alpha: 0.3),
              width: 1.5,
            ),
            labelStyle: const TextStyle(
              color: Colors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: const Icon(Icons.build, size: 14, color: Colors.teal),
          ),

        // Always show availability
        Chip(
          label: Text(localizations.available),
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          side: BorderSide(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1.5,
          ),
          labelStyle: const TextStyle(
            color: Colors.green,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
        ),
      ],
    );
  }

  void _showModelDetailsDialog(OpenRouterModel model) {
    // ==============================================
    // Show model details
    // ==============================================
    final localizations = AppLocalizations.of(context)!;

    /// Builds a detail row with icon, label, and value
    Widget buildDetailRow(String label, String value, IconData icon) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall!.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    /// Builds a feature chip with label, color, and icon
    Widget buildFeatureChip(
      String label,
      bool enabled,
      Color color,
      IconData icon,
    ) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Chip(
          label: Text(
            label,
            style: TextStyle(
              color: enabled ? color : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: enabled
              ? color.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          side: BorderSide(
            color: enabled
                ? color.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: Icon(
            icon,
            size: 14,
            color: enabled ? color : Colors.grey[600],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge!.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                model.id,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall!.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description section
              Text(
                localizations.description,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
              ),
              const SizedBox(height: 4),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? UbuntuColors.darkBorderColor
                    : UbuntuColors.lightBorderColor,
              ),
              const SizedBox(height: 8),
              Text(
                model.description,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Technical details
              Text(
                localizations.technicalDetails,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
              ),
              const SizedBox(height: 12),
              buildDetailRow(
                localizations.provider,
                model.provider!,
                Icons.account_circle,
              ),
              if (model.provider != null)
                buildDetailRow(
                  localizations.context,
                  model.formattedContextLength,
                  Icons.text_fields,
                ),

              buildDetailRow(
                localizations.inputTokens,
                model.pricingPrompt != null
                    ? '\$${model.pricingPrompt}/M'
                    : localizations.notAvailable,
                Icons.attach_money,
              ),
              buildDetailRow(
                localizations.outputTokens,
                model.pricingCompletion != null
                    ? '\$${model.pricingCompletion}/M'
                    : localizations.notAvailable,
                Icons.monetization_on,
              ),

              // Features section
              const SizedBox(height: 20),
              Text(
                localizations.features,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                localizations.featuresDisplayedBasedOnActualModelCapabilities,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall!.color,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  buildFeatureChip(
                    model.isFree ? localizations.free : localizations.paid,
                    true,
                    model.isFree ? Colors.green : Colors.orange,
                    model.isFree ? Icons.attach_money : Icons.payment,
                  ),
                  if (model.supportsReasoning)
                    buildFeatureChip(
                      localizations.reasoning,
                      true,
                      Colors.blue,
                      Icons.psychology,
                    ),
                  if (model.supportsMultimodal)
                    buildFeatureChip(
                      localizations.multimodal,
                      true,
                      Colors.purple,
                      Icons.view_in_ar,
                    ),
                  if (model.capabilities.vision)
                    buildFeatureChip(
                      localizations.vision,
                      true,
                      Colors.deepOrange,
                      Icons.visibility,
                    ),
                  if (model.capabilities.tools)
                    buildFeatureChip(
                      localizations.tools,
                      true,
                      Colors.teal,
                      Icons.build,
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(localizations.close),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isEmptySearch =
        _searchController.text.isNotEmpty && _filteredModels.isEmpty;
    final isEmptyFavorites = _showFavoritesOnly && _filteredModels.isEmpty;
    final localizations = AppLocalizations.of(context)!;

    String message;
    String submessage;
    IconData icon;

    if (isEmptyFavorites) {
      icon = Icons.favorite_border;
      message = localizations.noFavoriteModels;
      submessage = localizations.tapHeartToAddFavorites;
    } else if (isEmptySearch) {
      icon = Icons.search_off;
      message = localizations.noModelsFound;
      submessage = localizations.tryADifferentSearchQuery;
    } else {
      icon = Icons.model_training;
      message = localizations.noAvailableModels;
      submessage = localizations.tryRefreshingOrCheckYourInternetConnection;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge!.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            submessage,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium!.color,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
