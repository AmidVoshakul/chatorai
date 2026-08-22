import 'package:chatorai/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

// ===========================================================================
// SETTINGS SELECTION CARD WIDGET
// ===========================================================================

class SettingsSelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsSelectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: premiumCard(isDark),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: ChatoraiColors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? ChatoraiColors.darkTextColor
                              : ChatoraiColors.lightTextColor,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? ChatoraiColors.darkSecondaryTextColor
                                : ChatoraiColors.secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark
                      ? ChatoraiColors.darkSecondaryTextColor
                      : ChatoraiColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
