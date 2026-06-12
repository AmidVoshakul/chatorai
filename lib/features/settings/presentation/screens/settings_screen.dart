import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:chatorai/features/settings/presentation/widgets/settings_selection_card.dart';
import 'package:chatorai/features/settings/presentation/widgets/settings_toggle_tile.dart';
import 'package:chatorai/features/settings/presentation/widgets/settings_slider_card.dart';
import 'package:chatorai/features/settings/presentation/widgets/theme_selection_dialog.dart';
import 'package:chatorai/features/settings/presentation/widgets/language_selection_dialog.dart';
import 'package:chatorai/features/settings/presentation/widgets/about_dialog.dart';
import 'package:chatorai/features/settings/presentation/screens/provider_settings_screen.dart';

// ===========================================================================
// SETTINGS SCREEN
// ===========================================================================

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final theme = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        centerTitle: true,
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ChatoraiSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(title: localizations.providerConfiguration),
            const SizedBox(height: ChatoraiSpacing.lg),
            SettingsSelectionCard(
              context: context,
              icon: Icons.api,
              title: localizations.providers,
              subtitle: localizations.manageProviders,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProviderSettingsScreen(),
                ),
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.xl),
            _buildAppearanceSection(
              context,
              ref,
              localizations,
              theme,
              language,
            ),
            const SizedBox(height: ChatoraiSpacing.xl),
            _buildAccessibilitySection(context, ref, localizations, theme),
            const SizedBox(height: ChatoraiSpacing.xl),
            SettingsSelectionCard(
              context: context,
              icon: Icons.info,
              title: localizations.appInfo,
              subtitle: '',
              onTap: () async =>
                  showSettingsAboutDialog(context, localizations),
            ),
            const SizedBox(height: ChatoraiSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION BUILDERS
  // ===========================================================================

  Widget _buildAppearanceSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localizations,
    ThemeState theme,
    LanguageState language,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: localizations.appearance),
        const SizedBox(height: ChatoraiSpacing.lg),
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

  Widget _buildAccessibilitySection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localizations,
    ThemeState theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: localizations.accessibility),
        const SizedBox(height: ChatoraiSpacing.lg),
        SettingsToggleTile(
          context: context,
          title: localizations.wideScreenMode,
          subtitle: localizations.useFullScreenWidth,
          value: theme.wideScreenMode,
          onChanged: (value) =>
              ref.read(themeProvider.notifier).setWideScreenMode(value),
        ),
        const SizedBox(height: ChatoraiSpacing.lg),
        SettingsToggleTile(
          context: context,
          title: localizations.autoScrollDuringStreaming,
          subtitle: localizations.autoScrollDuringStreamingDesc,
          value: theme.autoScrollDuringStreaming,
          onChanged: (value) => ref
              .read(themeProvider.notifier)
              .setAutoScrollDuringStreaming(value),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

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
