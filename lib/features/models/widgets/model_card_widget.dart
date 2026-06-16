import 'package:chatorai/features/chat/data/models/chat_model.dart';
import 'package:chatorai/features/models/widgets/model_features_widget.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart' show ChatoraiColors;
import 'package:flutter/material.dart';

// ===========================================================================
// MODEL CARD WIDGET
// ===========================================================================

class ModelCardWidget extends StatelessWidget {
  final ChatModel model;
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

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin:
          margin ?? const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.green, width: 2.0),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                      size: 24,
                    ),
                    onPressed: onFavoriteToggle,
                    tooltip: isFavorite
                        ? localizations.removeFromFavorites
                        : localizations.addToFavorites,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.info,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                    onPressed: onInfoTap,
                    tooltip: localizations.details,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? ChatoraiColors.darkBorderColor
                    : ChatoraiColors.lightBorderColor,
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
              ModelFeaturesWidget(model: model),
            ],
          ),
        ),
      ),
    );
  }
}
