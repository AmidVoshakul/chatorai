import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/widgets/settings/settings_section_header.dart';
import 'package:chatorai/widgets/settings/settings_selection_card.dart';
import 'package:chatorai/widgets/settings/settings_toggle_tile.dart';
import 'package:chatorai/widgets/settings/settings_slider_card.dart';
import 'package:chatorai/widgets/settings/settings_text_field.dart';
import 'package:chatorai/widgets/settings/theme_selection_dialog.dart';
import 'package:chatorai/widgets/settings/language_selection_dialog.dart';
import 'package:chatorai/widgets/settings/about_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SettingsController? _controller;

  SettingsController get controller {
    _controller ??= SettingsController();
    return _controller!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.validateApiKey(context);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

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
            SettingsTextField(
              controller: controller.apiKeyController,
              labelText: localizations.apiKey,
              hintText: localizations.enterApiKey,
              obscureText: true,
              onCopy: () => controller.onApiKeyCopy(context, localizations),
            ),
            const SizedBox(height: ChatoraiSpacing.md),
            SettingsTextField(
              controller: controller.baseUrlController,
              labelText: 'Base URL',
              hintText: 'https://openrouter.ai/api/v1',
            ),
            const SizedBox(height: ChatoraiSpacing.xl),
            _buildAppearanceSection(context, localizations),
            const SizedBox(height: ChatoraiSpacing.xl),
            _buildAccessibilitySection(context, localizations),
            const SizedBox(height: ChatoraiSpacing.xl),
            SettingsSelectionCard(
              context: context,
              icon: Icons.info,
              title: localizations.appInfo,
              subtitle: '',
              onTap: () => showSettingsAboutDialog(context, localizations),
            ),
            const SizedBox(height: ChatoraiSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final themeProviderRead = ref.watch(themeProvider);
    final languageProviderRead = ref.watch(languageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: localizations.appearance),
        const SizedBox(height: ChatoraiSpacing.lg),
        SettingsSelectionCard(
          context: context,
          icon: Icons.palette,
          title: controller.getThemeModeName(
            themeProviderRead.themeMode,
            localizations,
          ),
          subtitle: localizations.theme,
          onTap: () => showThemeSelectionDialog(context, localizations),
        ),
        const SizedBox(height: ChatoraiSpacing.xl),
        SettingsSelectionCard(
          context: context,
          icon: Icons.language,
          title: controller.getLanguageName(
            languageProviderRead.selectedLanguage,
            localizations,
          ),
          subtitle: localizations.language,
          onTap: () => showLanguageSelectionDialog(context, localizations),
        ),
        const SizedBox(height: ChatoraiSpacing.xl),
        SettingsSectionHeader(title: localizations.fontSize),
        const SizedBox(height: ChatoraiSpacing.lg),
        SettingsSliderCard(
          context: context,
          value: themeProviderRead.fontSize,
          min: 0.8,
          max: 1.5,
          divisions: 7,
          label: '${(themeProviderRead.fontSize * 100).toInt()}%',
          onChanged: (value) =>
              ref.read(themeProvider.notifier).setFontSize(value),
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final themeProviderRead = ref.watch(themeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: localizations.accessibility),
        const SizedBox(height: ChatoraiSpacing.lg),
        SettingsToggleTile(
          context: context,
          title: localizations.wideScreenMode,
          subtitle: localizations.useFullScreenWidth,
          value: themeProviderRead.wideScreenMode,
          onChanged: (value) =>
              ref.read(themeProvider.notifier).setWideScreenMode(value),
        ),
      ],
    );
  }
}

class SettingsController {
  late TextEditingController apiKeyController;
  late TextEditingController baseUrlController;

  static const List<String> validApiKeyPrefixes = ['sk-', 'sk-or-'];
  static const int minApiKeyLength = 10;

  SettingsController() {
    apiKeyController = TextEditingController(
      text: dotenv.env['OPENROUTER_API_KEY'] ?? '',
    );
    baseUrlController = TextEditingController(
      text: dotenv.env['OPENROUTER_BASE_URL'] ?? 'https://openrouter.ai/api/v1',
    );
  }

  void dispose() {
    apiKeyController.dispose();
    baseUrlController.dispose();
  }

  void validateApiKey(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final apiKey = apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      return;
    }

    final isValid = isValidApiKey(apiKey);

    if (!isValid) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.apiKeyInvalid,
        icon: Icons.error,
      );
    }
  }

  bool isValidApiKey(String apiKey) {
    if (apiKey.isEmpty) return false;

    return validApiKeyPrefixes.any((prefix) => apiKey.startsWith(prefix)) &&
        apiKey.length > minApiKeyLength;
  }

  void onApiKeyCopy(BuildContext context, AppLocalizations localizations) {
    SnackbarUtils.showCopySnackBar(
      context: context,
      message: localizations.apiKeyCopied,
    );
  }

  String getThemeModeName(AppThemeMode mode, AppLocalizations localizations) {
    switch (mode) {
      case AppThemeMode.system:
        return localizations.system;
      case AppThemeMode.light:
        return localizations.light;
      case AppThemeMode.dark:
        return localizations.dark;
    }
  }

  String getLanguageName(String code, AppLocalizations localizations) {
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
