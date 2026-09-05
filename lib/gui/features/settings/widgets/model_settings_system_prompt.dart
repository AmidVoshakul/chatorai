import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModelSettingsSystemPrompt extends ConsumerWidget {
  final TextEditingController controller;

  const ModelSettingsSystemPrompt({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.systemPrompt,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.base,
            fontWeight: FontWeight.w600,
            color: isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack,
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.xs),
        Text(
          localizations.systemPromptDescription,
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
          maxLines: 3,
          decoration: InputDecoration(
            hintText: localizations.systemPromptHint,
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
              vertical: ChatoraiSpacing.md,
            ),
          ),
          style: TextStyle(
            fontSize: ChatoraiFontSizes.base,
            color: isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack,
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.lg),
      ],
    );
  }
}
