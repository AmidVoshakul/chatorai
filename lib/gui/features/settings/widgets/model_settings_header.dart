import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ChatoraiColors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: ChatoraiColors.orange,
              size: ChatoraiIconSizes.xl,
            ),
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
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
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
          _HeaderIconButton(
            icon: Icons.close_rounded,
            tooltip: localizations.close,
            onPressed: onClose,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDark;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? ChatoraiColors.darkInputFill
                : ChatoraiColors.inputFill,
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
          ),
          child: Icon(
            icon,
            size: ChatoraiIconSizes.md,
            color: isDark
                ? ChatoraiColors.darkSecondaryTextColor
                : ChatoraiColors.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}
