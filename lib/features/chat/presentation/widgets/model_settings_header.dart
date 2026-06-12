import 'package:flutter/material.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

class ModelSettingsHeader extends StatelessWidget {
  final String modelName;
  final VoidCallback onClose;

  const ModelSettingsHeader({
    super.key,
    required this.modelName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? ChatoraiColors.darkBorderColor
                : ChatoraiColors.lightBorderColor,
            width: ChatoraiBorderWidth.thinBold,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            color: ChatoraiColors.orange,
            size: ChatoraiIconSizes.xxl,
          ),
          const SizedBox(width: ChatoraiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.modelSettings,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.xl,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? ChatoraiColors.pureWhite
                        : ChatoraiColors.pureBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  modelName,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.md,
                    color: isDark
                        ? ChatoraiColors.darkSecondaryTextColor
                        : ChatoraiColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDark
                  ? ChatoraiColors.white70
                  : ChatoraiColors.secondaryTextColor,
            ),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
