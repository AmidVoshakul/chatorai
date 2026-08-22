import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Inline help / explanation section for the Auto-Approve screen.
///
/// Currently the screen's subtitle and scope hint are rendered directly in
/// [_AutoApproveContent] — this widget exists as a dedicated extraction point
/// should a richer help card be added later. For now it renders the subtitle
/// text unchanged.
class AutoApproveHelpSection extends StatelessWidget {
  const AutoApproveHelpSection({
    super.key,
    required this.localizations,
    required this.isDark,
  });

  final AppLocalizations localizations;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      localizations.autoApproveSubtitle,
      style: TextStyle(
        fontSize: ChatoraiFontSizes.base,
        color: isDark
            ? ChatoraiColors.darkSecondaryTextColor
            : ChatoraiColors.secondaryTextColor,
      ),
    );
  }
}
