import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chatorai/providers/theme_provider.dart';
import 'package:chatorai/providers/language_provider.dart';
import 'package:chatorai/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/widgets/settings/settings_section_header.dart';
import 'package:chatorai/widgets/settings/settings_selection_card.dart';
import 'package:chatorai/widgets/settings/settings_toggle_tile.dart';
import 'package:chatorai/widgets/settings/settings_slider_card.dart';
import 'package:chatorai/widgets/settings/settings_text_field.dart';
import 'package:chatorai/widgets/settings/theme_selection_dialog.dart';
import 'package:chatorai/widgets/settings/language_selection_dialog.dart';
import 'package:chatorai/widgets/settings/about_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController(
      themeProvider: Provider.of<ThemeProvider>(context, listen: false),
      languageProvider: Provider.of<LanguageProvider>(context, listen: false),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.validateApiKey(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(title: localizations.providerConfiguration),
            const SizedBox(height: 16),
            SettingsTextField(
              controller: _controller.apiKeyController,
              labelText: localizations.apiKey,
              hintText: localizations.enterApiKey,
              obscureText: true,
              onCopy: () => _controller.onApiKeyCopy(context, localizations),
            ),
            const SizedBox(height: 12),
            SettingsTextField(
              controller: _controller.baseUrlController,
              labelText: 'Base URL',
              hintText: 'https://openrouter.ai/api/v1',
            ),
            const SizedBox(height: 20),
            _buildAppearanceSection(context, localizations),
            const SizedBox(height: 20),
            _buildAccessibilitySection(context, localizations),
            const SizedBox(height: 20),
            SettingsSelectionCard(
              context: context,
              icon: Icons.info,
              title: localizations.appInfo,
              subtitle: '',
              onTap: () => showSettingsAboutDialog(context, localizations),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(title: localizations.appearance),
            const SizedBox(height: 16),
            SettingsSelectionCard(
              context: context,
              icon: Icons.palette,
              title: _controller.getThemeModeName(
                themeProvider.themeMode,
                localizations,
              ),
              subtitle: localizations.theme,
              onTap: () =>
                  showThemeSelectionDialog(context, localizations, _controller),
            ),
            const SizedBox(height: 20),
            SettingsSelectionCard(
              context: context,
              icon: Icons.language,
              title: _controller.getLanguageName(
                languageProvider.selectedLanguage,
                localizations,
              ),
              subtitle: localizations.language,
              onTap: () => showLanguageSelectionDialog(
                context,
                localizations,
                _controller,
              ),
            ),
            const SizedBox(height: 20),
            SettingsSectionHeader(title: localizations.fontSize),
            const SizedBox(height: 16),
            SettingsSliderCard(
              context: context,
              value: themeProvider.fontSize,
              min: 0.8,
              max: 1.5,
              divisions: 7,
              label: '${(themeProvider.fontSize * 100).toInt()}%',
              onChanged: (value) => themeProvider.fontSize = value,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccessibilitySection(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(title: localizations.accessibility),
            const SizedBox(height: 16),
            SettingsToggleTile(
              context: context,
              title: localizations.wideScreenMode,
              subtitle: localizations.useFullScreenWidth,
              value: themeProvider.wideScreenMode,
              onChanged: (value) => themeProvider.wideScreenMode = value,
            ),
          ],
        );
      },
    );
  }
}

class SettingsController {
  final ThemeProvider themeProvider;
  final LanguageProvider languageProvider;

  late TextEditingController apiKeyController;
  late TextEditingController baseUrlController;

  static const List<String> validApiKeyPrefixes = ['sk-', 'sk-or-'];
  static const int minApiKeyLength = 10;

  SettingsController({
    required this.themeProvider,
    required this.languageProvider,
  }) {
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
