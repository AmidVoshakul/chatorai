import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/gui/features/models/widgets/model_features_widget.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ModelCardWidget extends StatefulWidget {
  final ModelConfig model;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onInfoTap;
  final EdgeInsetsGeometry? margin;

  const ModelCardWidget({
    super.key,
    required this.model,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onInfoTap,
    this.margin,
  });

  @override
  State<ModelCardWidget> createState() => _ModelCardWidgetState();
}

class _ModelCardWidgetState extends State<ModelCardWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin:
          widget.margin ??
          const EdgeInsets.symmetric(
            vertical: ChatoraiSpacing.sm,
            horizontal: ChatoraiSpacing.sm,
          ),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF222222)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        border: Border.all(
          color: _hovered
              ? ChatoraiColors.orange.withValues(alpha: 0.35)
              : widget.isSelected
              ? ChatoraiColors.orange
              : isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder,
          width: _hovered ? 1.4 : (widget.isSelected ? 1.6 : 1),
        ),
        boxShadow: isDark
            ? ChatoraiShadows.darkShadow
            : ChatoraiShadows.cardShadow,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(ChatoraiSpacing.lg),
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
                            widget.model.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: ChatoraiFontSizes.lg,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? ChatoraiColors.pureWhite
                                  : ChatoraiColors.pureBlack,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: ChatoraiSpacing.xs),
                          Text(
                            widget.model.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: ChatoraiFontSizes.xs,
                              color: isDark
                                  ? ChatoraiColors.darkSecondaryTextColor
                                  : ChatoraiColors.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        widget.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.isFavorite ? Colors.red : null,
                        size: ChatoraiIconSizes.md,
                      ),
                      onPressed: widget.onFavoriteToggle,
                      tooltip: widget.isFavorite
                          ? localizations.removeFromFavorites
                          : localizations.addToFavorites,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: ChatoraiSpacing.xs),
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.blueAccent,
                        size: ChatoraiIconSizes.md,
                      ),
                      onPressed: widget.onInfoTap,
                      tooltip: localizations.details,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (widget.model.description != null &&
                    widget.model.description!.isNotEmpty) ...[
                  const SizedBox(height: ChatoraiSpacing.sm),
                  Container(
                    height: ChatoraiBorderWidth.thin,
                    color: isDark
                        ? ChatoraiColors.darkInputBorder
                        : ChatoraiColors.inputBorder.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: ChatoraiSpacing.sm),
                  Text(
                    widget.model.description!,
                    style: TextStyle(
                      fontSize: ChatoraiFontSizes.sm,
                      color: isDark
                          ? ChatoraiColors.darkSecondaryTextColor
                          : ChatoraiColors.secondaryTextColor,
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: ChatoraiSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.data_usage_outlined,
                      size: ChatoraiIconSizes.xs,
                      color: ChatoraiColors.orange.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: ChatoraiSpacing.xs),
                    Text(
                      '${localizations.context}: ${widget.model.formattedContextLength}',
                      style: TextStyle(
                        fontSize: ChatoraiFontSizes.xs,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? ChatoraiColors.darkSecondaryTextColor
                            : ChatoraiColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ChatoraiSpacing.sm),
                ModelFeaturesWidget(model: widget.model),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
