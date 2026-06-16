import 'package:flutter/material.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

// ===========================================================================
// SETTINGS TOGGLE TILE WIDGET
// ===========================================================================

class SettingsToggleTile extends StatelessWidget {
  final BuildContext context;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleTile({
    super.key,
    required this.context,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? ChatoraiColors.darkCard : ChatoraiColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder,
          width: 1,
        ),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? ChatoraiColors.darkTextColor
                            : ChatoraiColors.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: ChatoraiColors.orange,
                  activeTrackColor: ChatoraiColors.orange.withAlpha(150),
                  inactiveThumbColor: isDark
                      ? ChatoraiColors.toggleInactiveThumbDark
                      : ChatoraiColors.toggleInactiveThumbLight,
                  inactiveTrackColor: isDark
                      ? ChatoraiColors.toggleInactiveTrackDark
                      : ChatoraiColors.toggleInactiveTrackLight,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
