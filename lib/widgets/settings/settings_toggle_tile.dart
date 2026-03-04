import 'package:flutter/material.dart';
import 'package:chatorai/themes/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? UbuntuColors.darkCard : UbuntuColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark
              ? UbuntuColors.darkInputBorder
              : UbuntuColors.inputBorder,
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
                            ? UbuntuColors.darkTextColor
                            : UbuntuColors.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? UbuntuColors.darkSecondaryTextColor
                            : UbuntuColors.secondaryTextColor,
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
                  activeThumbColor: UbuntuColors.orange,
                  activeTrackColor: UbuntuColors.orange.withAlpha(150),
                  inactiveThumbColor: isDark
                      ? UbuntuColors.toggleInactiveThumbDark
                      : UbuntuColors.toggleInactiveThumbLight,
                  inactiveTrackColor: isDark
                      ? UbuntuColors.toggleInactiveTrackDark
                      : UbuntuColors.toggleInactiveTrackLight,
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
