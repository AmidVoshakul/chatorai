import 'package:chatorai/features/chat/data/models/chat_model.dart';
import 'package:chatorai/features/chat/data/providers/models_provider.dart';
import 'package:chatorai/features/models/widgets/model_card_widget.dart';
import 'package:chatorai/features/models/widgets/model_details_dialog_widget.dart';
import 'package:chatorai/features/models/widgets/models_empty_state_widget.dart';
import 'package:chatorai/features/models/widgets/provider_icon.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// MODELS SCREEN WIDGET
// ===========================================================================

class ModelsScreen extends ConsumerWidget {
  final Function(String, ChatModel?)? onModelSelected;
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

    return _buildGroupedList(context, ref, state);
  }

  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    ModelsScreenState state,
  ) {
    final grouped = <String, List<ChatModel>>{};
    for (final m in state.filteredModels) {
      (grouped[m.provider ?? ''] ??= []).add(m);
    }
    final sorted = grouped.entries.toList()
      ..sort((a, b) => _providerName(a.key).compareTo(_providerName(b.key)));

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final entry in sorted)
          ExpansionTile(
            key: ValueKey('grp_${entry.key}'),
            initiallyExpanded: false,
            leading: ProviderIcon(providerId: entry.key),
            title: Text('${_providerName(entry.key)} · ${entry.value.length}'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: const EdgeInsets.only(left: 8, bottom: 4),
            children: [
              _ModelGrid(
                models: entry.value,
                currentModel: currentModel,
                onSelect: (model) async {
                  await ref
                      .read(modelsScreenProvider.notifier)
                      .selectModel(model.id);
                  if (context.mounted) Navigator.of(context).pop(model);
                },
                isFavorite: (id) =>
                    ref.read(modelsScreenProvider.notifier).isFavorite(id),
                onToggleFavorite: (id) =>
                    ref.read(modelsScreenProvider.notifier).toggleFavorite(id),
                onInfo: (model) => showModelDetailsDialog(context, model),
              ),
            ],
          ),
      ],
    );
  }

  static const _providerNames = {
    'openai': 'OpenAI',
    'anthropic': 'Anthropic',
    'google': 'Google',
    'deepseek': 'DeepSeek',
    'openrouter': 'OpenRouter',
    'ollama': 'Ollama',
    'groq': 'Groq',
    'mistral': 'Mistral',
    'xai': 'xAI',
    'perplexity': 'Perplexity',
    'cohere': 'Cohere',
    'kilo': 'Kilo',
    'github': 'GitHub',
    'lmstudio': 'LM Studio',
    'vllm': 'vLLM',
  };

  String _providerName(String? id) => _providerNames[id] ?? (id ?? 'Unknown');
}

// ===========================================================================
// MODEL GRID — 2-column on wide screens, single column on narrow
// ===========================================================================

class _ModelGrid extends StatelessWidget {
  final List<ChatModel> models;
  final String? currentModel;
  final Future<void> Function(ChatModel) onSelect;
  final bool Function(String) isFavorite;
  final void Function(String) onToggleFavorite;
  final void Function(ChatModel) onInfo;

  const _ModelGrid({
    required this.models,
    required this.currentModel,
    required this.onSelect,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (!isWide) {
          return Column(
            children: models
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ModelCardWidget(
                      model: m,
                      isSelected: currentModel == m.id,
                      isFavorite: isFavorite(m.id),
                      onTap: () => onSelect(m),
                      onFavoriteToggle: () => onToggleFavorite(m.id),
                      onInfoTap: () => onInfo(m),
                    ),
                  ),
                )
                .toList(),
          );
        }

        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 8,
          children: models
              .map(
                (m) => SizedBox(
                  width: cardWidth,
                  child: ModelCardWidget(
                    model: m,
                    isSelected: currentModel == m.id,
                    isFavorite: isFavorite(m.id),
                    onTap: () => onSelect(m),
                    onFavoriteToggle: () => onToggleFavorite(m.id),
                    onInfoTap: () => onInfo(m),
                    margin: EdgeInsets.zero,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
