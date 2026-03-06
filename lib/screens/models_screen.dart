import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers/chat/models_provider.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/widgets/models/model_card_widget.dart';
import 'package:chatorai/widgets/models/model_details_dialog_widget.dart';
import 'package:chatorai/widgets/models/models_empty_state_widget.dart';

class ModelsScreen extends ConsumerWidget {
  final Function(String, OpenRouterModel?)? onModelSelected;
  final String? currentModel;

  const ModelsScreen({super.key, this.onModelSelected, this.currentModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final state = ref.watch(modelsScreenProvider);

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
              state.showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: state.showFavoritesOnly ? Colors.red : null,
            ),
            onPressed: () {
              ref.read(modelsScreenProvider.notifier).toggleFavoritesFilter();
            },
            tooltip: state.showFavoritesOnly
                ? localizations.showAllModels
                : localizations.showFavoritesOnly,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context, ref, localizations, state),
          const SizedBox(height: 8),
          Expanded(child: _buildContent(context, ref, localizations, state)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(modelsScreenProvider.notifier).loadModels();
        },
        tooltip: localizations.refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localizations,
    ModelsScreenState state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) {
          ref.read(modelsScreenProvider.notifier).setSearchQuery(value);
        },
        decoration: InputDecoration(
          hintText: state.showFavoritesOnly
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
              if (state.showFavoritesOnly)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.favorite, color: Colors.red, size: 20),
                ),
              if (state.searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  onPressed: () {
                    ref.read(modelsScreenProvider.notifier).clearSearch();
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
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localizations,
    ModelsScreenState state,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.filteredModels.isEmpty) {
      return ModelsEmptyStateWidget(
        isSearchEmpty: state.searchQuery.isNotEmpty,
        isFavoritesEmpty: state.showFavoritesOnly,
      );
    }

    return _buildModelsList(context, ref, state);
  }

  Widget _buildModelsList(
    BuildContext context,
    WidgetRef ref,
    ModelsScreenState state,
  ) {
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
        itemCount: state.filteredModels.length,
        itemBuilder: (context, index) {
          final model = state.filteredModels[index];
          return ModelCardWidget(
            key: ValueKey(model.id),
            model: model,
            isSelected: currentModel == model.id,
            isFavorite: ref
                .read(modelsScreenProvider.notifier)
                .isFavorite(model.id),
            onTap: () async {
              await ref
                  .read(modelsScreenProvider.notifier)
                  .selectModel(model.id);
              if (context.mounted) {
                Navigator.of(context).pop(model);
              }
            },
            onFavoriteToggle: () {
              ref.read(modelsScreenProvider.notifier).toggleFavorite(model.id);
            },
            onInfoTap: () => showModelDetailsDialog(context, model),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: state.filteredModels.length,
        itemBuilder: (context, index) {
          final model = state.filteredModels[index];
          return ModelCardWidget(
            key: ValueKey(model.id),
            model: model,
            isSelected: currentModel == model.id,
            isFavorite: ref
                .read(modelsScreenProvider.notifier)
                .isFavorite(model.id),
            onTap: () async {
              await ref
                  .read(modelsScreenProvider.notifier)
                  .selectModel(model.id);
              if (context.mounted) {
                Navigator.of(context).pop(model);
              }
            },
            onFavoriteToggle: () {
              ref.read(modelsScreenProvider.notifier).toggleFavorite(model.id);
            },
            onInfoTap: () => showModelDetailsDialog(context, model),
          );
        },
      );
    }
  }
}
