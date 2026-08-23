import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/features/models/providers/model_provider.dart';
import 'package:chatorai/features/models/providers/models_provider.dart';
import 'package:chatorai/features/models/widgets/model_card_widget.dart';
import 'package:chatorai/features/models/widgets/model_details_dialog_widget.dart';
import 'package:chatorai/features/models/widgets/models_empty_state_widget.dart';
import 'package:chatorai/features/models/widgets/provider_icon.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModelsScreen extends ConsumerStatefulWidget {
  final Function(String, ModelConfig?)? onModelSelected;
  final String? currentModel;

  const ModelsScreen({super.key, this.onModelSelected, this.currentModel});

  @override
  ConsumerState<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends ConsumerState<ModelsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(modelsScreenProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: Text(
          localizations.models,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack,
          ),
        ),
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              state.showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: state.showFavoritesOnly ? Colors.red : null,
              size: ChatoraiIconSizes.md,
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
          const SizedBox(height: ChatoraiSpacing.lg),
          _PremiumSearchBar(
            isDark: isDark,
            localizations: localizations,
            state: state,
            controller: _searchController,
            onChanged: (value) {
              ref.read(modelsScreenProvider.notifier).setSearchQuery(value);
            },
            onClear: () {
              ref.read(modelsScreenProvider.notifier).clearSearch();
            },
          ),
          const SizedBox(height: ChatoraiSpacing.md),
          Expanded(child: _buildContent(context, localizations, state, isDark)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF5A623), ChatoraiColors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ChatoraiColors.orange.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: ChatoraiColors.pureBlack.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            ref
                .read(modelsScreenProvider.notifier)
                .loadModels(forceRefresh: true);
          },
          tooltip: localizations.refresh,
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(
            Icons.refresh,
            color: ChatoraiColors.pureWhite,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations localizations,
    ModelsScreenState state,
    bool isDark,
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

    final modelState = ref.watch(modelProvider);
    final recent = modelState.recentModels;

    return Column(
      children: [
        if (recent.isNotEmpty &&
            !state.showFavoritesOnly &&
            state.searchQuery.isEmpty)
          _RecentModelsSection(
            models: recent,
            currentModel: widget.currentModel,
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
            localizations: localizations,
            isDark: isDark,
          ),
        Expanded(child: _buildGroupedList(context, state, isDark)),
      ],
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    ModelsScreenState state,
    bool isDark,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final grouped = <String, List<ModelConfig>>{};
    for (final m in state.filteredModels) {
      (grouped[m.providerId] ??= []).add(m);
    }
    final sorted = grouped.entries.toList()
      ..sort((a, b) => _providerName(a.key).compareTo(_providerName(b.key)));

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: ChatoraiSpacing.md,
        vertical: ChatoraiSpacing.sm,
      ),
      children: [
        for (final entry in sorted)
          _DeferredModelTile(
            providerKey: entry.key,
            providerName: _providerName(entry.key),
            models: entry.value,
            currentModel: widget.currentModel,
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
            localizations: localizations,
            isDark: isDark,
          ),
      ],
    );
  }

  String _providerName(String? id) {
    if (id == null) return 'Unknown';
    final catalog = ref.read(catalogServiceProvider);
    final provider = catalog.getProvider(id);
    return provider?.name ?? id;
  }
}

class _PremiumSearchBar extends StatelessWidget {
  final bool isDark;
  final AppLocalizations localizations;
  final ModelsScreenState state;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _PremiumSearchBar({
    required this.isDark,
    required this.localizations,
    required this.state,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.lg),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack,
          fontSize: ChatoraiFontSizes.base,
        ),
        cursorColor: ChatoraiColors.orange,
        decoration: InputDecoration(
          hintText: state.showFavoritesOnly
              ? localizations.searchFavorites
              : localizations.searchModels,
          hintStyle: TextStyle(
            color: isDark
                ? ChatoraiColors.darkSecondaryTextColor
                : ChatoraiColors.secondaryTextColor,
            fontSize: ChatoraiFontSizes.base,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark
                ? ChatoraiColors.darkSecondaryTextColor
                : ChatoraiColors.secondaryTextColor,
            size: ChatoraiIconSizes.md,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.showFavoritesOnly)
                Padding(
                  padding: const EdgeInsets.only(right: ChatoraiSpacing.xs),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: ChatoraiIconSizes.sm,
                  ),
                ),
              if (state.searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark
                        ? ChatoraiColors.darkSecondaryTextColor
                        : ChatoraiColors.secondaryTextColor,
                    size: ChatoraiIconSizes.sm,
                  ),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          filled: true,
          fillColor: isDark
              ? ChatoraiColors.premiumSurfaceRaised
              : ChatoraiColors.lightCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
            borderSide: BorderSide(
              color: isDark
                  ? ChatoraiColors.premiumBorderSoft
                  : ChatoraiColors.inputBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
            borderSide: BorderSide(
              color: isDark
                  ? ChatoraiColors.premiumBorderSoft
                  : ChatoraiColors.inputBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
            borderSide: BorderSide(color: ChatoraiColors.orange, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ChatoraiSpacing.md,
            vertical: ChatoraiSpacing.sm,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class _DeferredModelTile extends StatefulWidget {
  final String providerKey;
  final String providerName;
  final List<ModelConfig> models;
  final String? currentModel;
  final Future<void> Function(ModelConfig) onSelect;
  final bool Function(String) isFavorite;
  final void Function(String) onToggleFavorite;
  final void Function(ModelConfig) onInfo;
  final AppLocalizations localizations;
  final bool isDark;

  const _DeferredModelTile({
    required this.providerKey,
    required this.providerName,
    required this.models,
    required this.currentModel,
    required this.onSelect,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onInfo,
    required this.localizations,
    required this.isDark,
  });

  @override
  State<_DeferredModelTile> createState() => _DeferredModelTileState();
}

class _DeferredModelTileState extends State<_DeferredModelTile> {
  bool _hasBuiltGrid = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ChatoraiSpacing.md),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF1A1A1A)
            : ChatoraiColors.lightCard,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        border: Border.all(
          color: widget.isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            key: ValueKey('grp_${widget.providerKey}'),
            initiallyExpanded: false,
            leading: ProviderIcon(providerId: widget.providerKey),
            title: Text(
              widget.localizations.modelsProviderCountFormat(
                widget.models.length,
                widget.providerName,
              ),
              style: TextStyle(
                fontSize: ChatoraiFontSizes.base,
                fontWeight: FontWeight.w600,
                color: widget.isDark
                    ? ChatoraiColors.pureWhite
                    : ChatoraiColors.pureBlack,
              ),
            ),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: ChatoraiSpacing.md,
              vertical: ChatoraiSpacing.xs,
            ),
            childrenPadding: const EdgeInsets.only(
              left: ChatoraiSpacing.md,
              right: ChatoraiSpacing.md,
              bottom: ChatoraiSpacing.md,
            ),
            onExpansionChanged: (expanded) {
              if (expanded && !_hasBuiltGrid) {
                setState(() => _hasBuiltGrid = true);
              }
            },
            children: _hasBuiltGrid
                ? [
                    _ModelGrid(
                      models: widget.models,
                      currentModel: widget.currentModel,
                      onSelect: widget.onSelect,
                      isFavorite: widget.isFavorite,
                      onToggleFavorite: widget.onToggleFavorite,
                      onInfo: widget.onInfo,
                      isDark: widget.isDark,
                    ),
                  ]
                : [const SizedBox.shrink()],
          ),
        ),
      ),
    );
  }
}

class _ModelGrid extends StatelessWidget {
  final List<ModelConfig> models;
  final String? currentModel;
  final Future<void> Function(ModelConfig) onSelect;
  final bool Function(String) isFavorite;
  final void Function(String) onToggleFavorite;
  final void Function(ModelConfig) onInfo;
  final bool isDark;

  const _ModelGrid({
    required this.models,
    required this.currentModel,
    required this.onSelect,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onInfo,
    required this.isDark,
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
                    padding: const EdgeInsets.only(bottom: ChatoraiSpacing.sm),
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

        final cardWidth = (constraints.maxWidth - ChatoraiSpacing.md) / 2;
        return Wrap(
          spacing: ChatoraiSpacing.md,
          runSpacing: ChatoraiSpacing.sm,
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

class _RecentModelsSection extends StatelessWidget {
  final List<ModelConfig> models;
  final String? currentModel;
  final Future<void> Function(ModelConfig) onSelect;
  final bool Function(String) isFavorite;
  final void Function(String) onToggleFavorite;
  final void Function(ModelConfig) onInfo;
  final AppLocalizations localizations;
  final bool isDark;

  const _RecentModelsSection({
    required this.models,
    required this.currentModel,
    required this.onSelect,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onInfo,
    required this.localizations,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: ChatoraiSpacing.lg,
            right: ChatoraiSpacing.md,
            bottom: ChatoraiSpacing.sm,
            top: ChatoraiSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: ChatoraiColors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              Text(
                localizations.recentModels,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.base,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? ChatoraiColors.pureWhite
                      : ChatoraiColors.pureBlack,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 84,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.md),
            itemCount: models.length,
            itemBuilder: (context, index) {
              final m = models[index];
              final selected = currentModel == m.id;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < models.length - 1 ? ChatoraiSpacing.md : 0,
                ),
                child: _RecentCard(
                  model: m,
                  selected: selected,
                  onSelect: onSelect,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.md),
      ],
    );
  }
}

class _RecentCard extends StatefulWidget {
  final ModelConfig model;
  final bool selected;
  final Future<void> Function(ModelConfig) onSelect;
  final bool isDark;

  const _RecentCard({
    required this.model,
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  @override
  State<_RecentCard> createState() => _RecentCardState();
}

class _RecentCardState extends State<_RecentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          gradient: widget.selected
              ? const LinearGradient(
                  colors: [Color(0x33FDEEDB), Color(0x22FDEEDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : _hovered
              ? (widget.isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF252525), Color(0xFF2A2A2A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFF5F5F5), Color(0xFFEFEFEF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ))
              : widget.isDark
              ? const LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF252525)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFAFAFA), Color(0xFFF0F0F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
          border: Border.all(
            color: widget.selected
                ? ChatoraiColors.orange
                : _hovered
                ? ChatoraiColors.orange.withValues(alpha: 0.35)
                : widget.isDark
                ? ChatoraiColors.darkInputBorder
                : ChatoraiColors.inputBorder,
            width: widget.selected ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
          onTap: () => widget.onSelect(widget.model),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChatoraiSpacing.md,
              vertical: ChatoraiSpacing.sm,
            ),
            child: Row(
              children: [
                ProviderIcon(providerId: widget.model.provider, size: 28),
                const SizedBox(width: ChatoraiSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.model.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ChatoraiFontSizes.sm,
                          fontWeight: FontWeight.w600,
                          color: widget.selected
                              ? ChatoraiColors.orange
                              : widget.isDark
                              ? ChatoraiColors.pureWhite
                              : ChatoraiColors.pureBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.model.provider,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ChatoraiFontSizes.xs,
                          color: widget.isDark
                              ? ChatoraiColors.darkSecondaryTextColor
                              : ChatoraiColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.selected)
                  Icon(
                    Icons.check_circle,
                    color: ChatoraiColors.orange,
                    size: ChatoraiIconSizes.sm,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
