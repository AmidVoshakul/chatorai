import 'package:chatorai/features/settings/widgets/language_selection_dialog.dart';
import 'package:chatorai/features/settings/widgets/settings_section_header.dart';
import 'package:chatorai/features/settings/widgets/settings_selection_card.dart';
import 'package:chatorai/features/settings/widgets/settings_slider_card.dart';
import 'package:chatorai/features/settings/widgets/theme_selection_dialog.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// APPEARANCE SETTINGS SECTION
// ===========================================================================
/// Reusable appearance settings block (theme, language, font size).
/// Rendered both in the narrow `SettingsScreen` page and in the desktop
/// settings window content pane.
class SettingsAppearanceSection extends ConsumerWidget {
  const SettingsAppearanceSection({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final theme = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          SettingsSectionHeader(title: localizations.appearance),
          const SizedBox(height: ChatoraiSpacing.lg),
        ],
        SettingsSelectionCard(
          context: context,
          icon: Icons.palette,
          title: _getThemeModeName(theme.themeMode, localizations),
          subtitle: localizations.theme,
          onTap: () => showThemeSelectionDialog(context, localizations),
        ),
        const SizedBox(height: ChatoraiSpacing.xl),
        SettingsSelectionCard(
          context: context,
          icon: Icons.language,
          title: _getLanguageName(language.selectedLanguage, localizations),
          subtitle: localizations.language,
          onTap: () => showLanguageSelectionDialog(context, localizations),
        ),
        const SizedBox(height: ChatoraiSpacing.xl),
        SettingsSectionHeader(title: localizations.fontSize),
        const SizedBox(height: ChatoraiSpacing.lg),
        SettingsSliderCard(
          context: context,
          value: theme.fontSize,
          min: 0.8,
          max: 1.5,
          divisions: 7,
          label: '${(theme.fontSize * 100).toInt()}%',
          onChanged: (value) =>
              ref.read(themeProvider.notifier).setFontSize(value),
        ),
      ],
    );
  }

  String _getThemeModeName(AppThemeMode mode, AppLocalizations localizations) {
    switch (mode) {
      case AppThemeMode.system:
        return localizations.system;
      case AppThemeMode.light:
        return localizations.light;
      case AppThemeMode.dark:
        return localizations.dark;
    }
  }

  String _getLanguageName(String code, AppLocalizations localizations) {
    final languages = <String, String>{
      'en': localizations.english,
      'ru': localizations.russian,
      'uk': localizations.ukrainian,
      'ar': localizations.arabic,
      'zh': localizations.chinese,
      'ja': localizations.japanese,
    };
    return languages[code] ?? code.toUpperCase();
  }
}
