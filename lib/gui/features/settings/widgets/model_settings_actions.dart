import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ModelSettingsActions extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const ModelSettingsActions({
    super.key,
    required this.isMobile,
    required this.onReset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    final resetButton = OutlinedButton.icon(
      onPressed: onReset,
      label: Text(localizations.resetToDefaults),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark
            ? ChatoraiColors.pureWhite
            : ChatoraiColors.pureBlack,
        side: BorderSide(
          color: isDark ? ChatoraiColors.darkGray : ChatoraiColors.mediumGray,
        ),
        padding: const EdgeInsets.symmetric(vertical: ChatoraiSpacing.md),
      ),
    );

    final applyButton = ElevatedButton.icon(
      onPressed: onApply,
      label: Text(localizations.applySettings),
      style: ElevatedButton.styleFrom(
        backgroundColor: ChatoraiColors.orange,
        foregroundColor: ChatoraiColors.pureWhite,
        padding: const EdgeInsets.symmetric(vertical: ChatoraiSpacing.md),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: resetButton),
          const SizedBox(height: ChatoraiSpacing.md),
          SizedBox(width: double.infinity, child: applyButton),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: resetButton),
        const SizedBox(width: ChatoraiSpacing.md),
        Expanded(child: applyButton),
      ],
    );
  }
}
