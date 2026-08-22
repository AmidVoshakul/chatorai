import 'package:chatorai/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

// ===========================================================================
// SETTINGS SLIDER CARD WIDGET
// ===========================================================================

class SettingsSliderCard extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  const SettingsSliderCard({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: premiumCard(isDark),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              localizations.currentSize((value * 100).toInt()),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark
                    ? ChatoraiColors.darkTextColor
                    : ChatoraiColors.lightTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.text_fields, size: 18, color: ChatoraiColors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: ChatoraiColors.orange,
                      inactiveTrackColor: isDark
                          ? ChatoraiColors.darkInputBorder
                          : ChatoraiColors.inputBorder,
                      thumbColor: ChatoraiColors.orange,
                      overlayColor: ChatoraiColors.orange.withAlpha(30),
                      valueIndicatorColor: ChatoraiColors.orange,
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
                Icon(Icons.text_fields, size: 26, color: ChatoraiColors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
