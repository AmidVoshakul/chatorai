import 'package:chatorai/gui/features/settings/widgets/settings_section_header.dart';
import 'package:chatorai/gui/features/settings/widgets/settings_toggle_tile.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// ACCESSIBILITY SETTINGS SECTION
// ===========================================================================
class SettingsAccessibilitySection extends ConsumerWidget {
  const SettingsAccessibilitySection({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final theme = ref.watch(themeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          SettingsSectionHeader(title: localizations.accessibility),
          const SizedBox(height: ChatoraiSpacing.lg),
        ],
        SettingsToggleTile(
          title: localizations.wideScreenMode,
          subtitle: localizations.useFullScreenWidth,
          value: theme.wideScreenMode,
          onChanged: (value) =>
              ref.read(themeProvider.notifier).setWideScreenMode(value),
        ),
        const SizedBox(height: ChatoraiSpacing.lg),
        SettingsToggleTile(
          title: localizations.autoScrollDuringStreaming,
          subtitle: localizations.autoScrollDuringStreamingDesc,
          value: theme.autoScrollDuringStreaming,
          onChanged: (value) => ref
              .read(themeProvider.notifier)
              .setAutoScrollDuringStreaming(value),
        ),
        const SizedBox(height: ChatoraiSpacing.lg),
        SettingsToggleTile(
          title: localizations.showContinuationSuggestions,
          subtitle: localizations.showContinuationSuggestionsDesc,
          value: theme.showContinuationSuggestions,
          onChanged: (value) => ref
              .read(themeProvider.notifier)
              .setShowContinuationSuggestions(value),
        ),
        const SizedBox(height: ChatoraiSpacing.lg),
        SettingsToggleTile(
          title: localizations.expandReasoningByDefault,
          subtitle: localizations.expandReasoningByDefaultDesc,
          value: theme.expandReasoningByDefault,
          onChanged: (value) => ref
              .read(themeProvider.notifier)
              .setExpandReasoningByDefault(value),
        ),
      ],
    );
  }
}
