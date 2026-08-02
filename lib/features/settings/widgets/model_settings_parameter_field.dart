import 'package:flutter/material.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/features/settings/widgets/model_settings_formatters.dart';

class ModelSettingsParameterField extends StatelessWidget {
  final String label;
  final String description;
  final TextEditingController controller;
  final String hintText;
  final bool isDecimal;
  final double min;
  final double max;

  const ModelSettingsParameterField({
    super.key,
    required this.label,
    required this.description,
    required this.controller,
    required this.hintText,
    this.isDecimal = false,
    this.min = 0.0,
    this.max = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.base,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? ChatoraiColors.pureWhite
                      : ChatoraiColors.pureBlack,
                ),
              ),
            ),
            const SizedBox(width: ChatoraiSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatoraiSpacing.sm,
                vertical: ChatoraiSpacing.xs,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          ChatoraiColors.orange.withAlpha(30),
                          ChatoraiColors.orange.withAlpha(15),
                        ]
                      : [
                          ChatoraiColors.orange.withAlpha(20),
                          ChatoraiColors.orange.withAlpha(8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xs),
                border: Border.all(
                  color: ChatoraiColors.orange.withAlpha(isDark ? 60 : 40),
                  width: 1,
                ),
              ),
              child: Text(
                controller.text,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.md,
                  fontWeight: FontWeight.w700,
                  color: ChatoraiColors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ChatoraiSpacing.xs),
        Text(
          description,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.md,
            color: isDark
                ? ChatoraiColors.darkSecondaryTextColor
                : ChatoraiColors.secondaryTextColor,
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: isDark
                ? ChatoraiColors.darkInputFill
                : ChatoraiColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              borderSide: BorderSide(
                color: isDark
                    ? ChatoraiColors.darkInputBorder
                    : ChatoraiColors.inputBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              borderSide: BorderSide(
                color: isDark
                    ? ChatoraiColors.darkInputBorder
                    : ChatoraiColors.inputBorder,
                width: ChatoraiBorderWidth.thinBold,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              borderSide: const BorderSide(
                color: ChatoraiColors.orange,
                width: ChatoraiBorderWidth.medium,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ChatoraiSpacing.md,
              vertical: ChatoraiSpacing.sm,
            ),
          ),
          style: TextStyle(
            fontSize: ChatoraiFontSizes.base,
            color: isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack,
          ),
          inputFormatters: [
            if (isDecimal)
              DecimalTextInputFormatter(min: min, max: max)
            else
              IntegerTextInputFormatter(min: min.toInt(), max: max.toInt()),
          ],
        ),
        const SizedBox(height: ChatoraiSpacing.lg),
      ],
    );
  }
}
