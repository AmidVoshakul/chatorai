import 'package:flutter/material.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';

class SettingsSliderCard extends StatelessWidget {
  final BuildContext context;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  const SettingsSliderCard({
    super.key,
    required this.context,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              localizations.currentSize((value * 100).toInt()),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark
                    ? UbuntuColors.darkTextColor
                    : UbuntuColors.lightTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.text_fields, size: 18, color: UbuntuColors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: UbuntuColors.orange,
                      inactiveTrackColor: isDark
                          ? UbuntuColors.darkInputBorder
                          : UbuntuColors.inputBorder,
                      thumbColor: UbuntuColors.orange,
                      overlayColor: UbuntuColors.orange.withAlpha(30),
                      valueIndicatorColor: UbuntuColors.orange,
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      min: min,
                      max: max,
                      divisions: divisions,
                      label: label,
                      onChanged: onChanged,
                    ),
                  ),
                ),
                Icon(Icons.text_fields, size: 26, color: UbuntuColors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
