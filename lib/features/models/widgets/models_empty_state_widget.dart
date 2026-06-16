import 'package:flutter/material.dart';
import 'package:chatorai/l10n/app_localizations.dart';

class ModelsEmptyStateWidget extends StatelessWidget {
  final bool isSearchEmpty;
  final bool isFavoritesEmpty;

  const ModelsEmptyStateWidget({
    super.key,
    required this.isSearchEmpty,
    required this.isFavoritesEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    String message;
    String submessage;
    IconData icon;

    if (isFavoritesEmpty) {
      icon = Icons.favorite_border;
      message = localizations.noFavoriteModels;
      submessage = localizations.tapHeartToAddFavorites;
    } else if (isSearchEmpty) {
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
