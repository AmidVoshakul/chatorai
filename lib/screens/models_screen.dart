import 'package:flutter/material.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:chatorai/providers/model_provider.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/widgets/models/models_controller.dart';
import 'package:chatorai/widgets/models/model_card_widget.dart';
import 'package:chatorai/widgets/models/model_details_dialog_widget.dart';
import 'package:chatorai/widgets/models/models_empty_state_widget.dart';

class ModelsScreen extends StatefulWidget {
  final Function(String, OpenRouterModel?)? onModelSelected;
  final String? currentModel;

  const ModelsScreen({super.key, this.onModelSelected, this.currentModel});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  late ModelsController _controller;

  @override
  void initState() {
    super.initState();
    final modelProvider = Provider.of<ModelProvider>(context, listen: false);
    _controller = ModelsController(
      modelProvider: modelProvider,
      onModelSelected: widget.onModelSelected,
      currentModelId: widget.currentModel,
    );
    _controller.loadModels();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return IconButton(
                icon: Icon(
                  _controller.showFavoritesOnly
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: _controller.showFavoritesOnly ? Colors.red : null,
                ),
                onPressed: () {
                  setState(() {
                    _controller.toggleFavoritesFilter();
                  });
                },
                tooltip: _controller.showFavoritesOnly
                    ? localizations.showAllModels
                    : localizations.showFavoritesOnly,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(localizations),
          const SizedBox(height: 8),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.filteredModels.isEmpty) {
                  return ModelsEmptyStateWidget(
                    isSearchEmpty: _controller.searchQuery.isNotEmpty,
                    isFavoritesEmpty: _controller.showFavoritesOnly,
                  );
                }

                return _buildModelsList();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.loadModels();
          });
        },
        tooltip: localizations.refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _controller.searchController,
            decoration: InputDecoration(
              hintText: _controller.showFavoritesOnly
                  ? localizations.searchFavorites
                  : localizations.searchModels,
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controller.showFavoritesOnly)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.favorite, color: Colors.red, size: 20),
                    ),
                  if (_controller.searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.clearSearch();
                        });
                      },
                    ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
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
              fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
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
        );
      },
    );
  }

  Widget _buildModelsList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 1200;

    if (isWideScreen) {
      return GridView.builder(
        padding: const EdgeInsets.all(12.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        itemCount: _controller.filteredModels.length,
        itemBuilder: (context, index) {
          final model = _controller.filteredModels[index];
          return _buildCompactModelCard(model);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _controller.filteredModels.length,
        itemBuilder: (context, index) {
          final model = _controller.filteredModels[index];
          return _buildModelCard(model);
        },
      );
    }
  }

  Widget _buildModelCard(OpenRouterModel model) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return ModelCardWidget(
          model: model,
          isSelected: widget.currentModel == model.id,
          isFavorite: _controller.isFavorite(model.id),
          onTap: () => _controller.selectModel(context, model),
          onFavoriteToggle: () {
            setState(() {
              _controller.toggleFavorite(model.id);
            });
          },
          onInfoTap: () => showModelDetailsDialog(context, model),
        );
      },
    );
  }

  Widget _buildCompactModelCard(OpenRouterModel model) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _controller.selectModel(context, model),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                model.id,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall!.color,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                model.description,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
