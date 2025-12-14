import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeProvider _themeProvider;
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;

  @override
  void initState() {
    super.initState();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // Initialize controllers with current values
    _apiKeyController = TextEditingController(text: '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');
    _baseUrlController = TextEditingController(text: 'https://openrouter.ai/api/v1');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
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
            Text(
              localizations.openRouterConfiguration,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // API Key Field
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: localizations.apiKey,
                hintText: localizations.enterApiKey,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () {
                    // Copy to clipboard functionality
                    SnackbarUtils.showCopySnackBar(
                    context: context,
                    message: localizations.apiKeyCopied,
                  );
                  },
                  tooltip: localizations.copy,
                ),
              ),
              maxLines: 1,
              obscureText: true,
            ),
            const SizedBox(height: 12),

            // Base URL Field
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://openrouter.ai/api/v1',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 20),

            Text(
              localizations.appearance,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Theme Selection
            Text(
              localizations.theme,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildThemeOption(
                      Icons.brightness_6,
                      localizations.system,
                      _themeProvider.themeMode == AppThemeMode.system,
                      localizations.useSystemTheme,
                      AppThemeMode.system,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildThemeOption(
                      Icons.wb_sunny,
                      localizations.light,
                      _themeProvider.themeMode == AppThemeMode.light,
                      localizations.useLightTheme,
                      AppThemeMode.light,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildThemeOption(
                      Icons.nightlight,
                      localizations.dark,
                      _themeProvider.themeMode == AppThemeMode.dark,
                      localizations.useDarkTheme,
                      AppThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Font Size
            Text(
              localizations.fontSize,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      localizations.currentSize((_themeProvider.fontSize * 100).toInt()),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.text_fields, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _themeProvider.fontSize,
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            label: '${(_themeProvider.fontSize * 100).toInt()}%',
                            onChanged: (value) {
                              _themeProvider.fontSize = value;
                            },
                          ),
                        ),
                        const Icon(Icons.text_fields, size: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Accessibility Options
            Text(
              localizations.accessibility,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _themeProvider.reduceMotion,
                      onChanged: (value) {
                        _themeProvider.reduceMotion = value;
                      },
                      title: Text(localizations.reduceMotion),
                      subtitle: Text(localizations.disableAnimation),
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                    const Divider(height: 1, thickness: 1),
                    SwitchListTile(
                      value: _themeProvider.highContrast,
                      onChanged: (value) {
                        _themeProvider.highContrast = value;
                      },
                      title: Text(localizations.highContrast),
                      subtitle: Text(localizations.increaseContrast),
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Language Section
            Text(
              localizations.language,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildLanguageOption(
                      localizations.english,
                      'en',
                      localizations.english,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildLanguageOption(
                      localizations.russian,
                      'ru',
                      localizations.russian,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildLanguageOption(
                      'العربية',
                      'ar',
                      localizations.arabic,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildLanguageOption(
                      '中文',
                      'zh',
                      localizations.chinese,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildLanguageOption(
                      '日本語',
                      'ja',
                      localizations.japanese,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Reset Settings
            Text(
              localizations.resetSettings,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      localizations.resetAllSettings,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await _themeProvider.resetSettings();
                          if (mounted) {
                            SnackbarUtils.showInfoSnackBar(
                              context: context,
                              message: localizations.settingsReset
                            );
                          }
                        },
                        child: Text(localizations.resetSettings),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    SnackbarUtils.showSuccessSnackBar(
                      context: context,
                      message: localizations.settingsSaved
                    );
                  }
                  Navigator.of(context).pop();
                },
                child: Text(localizations.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    IconData icon,
    String title,
    bool isSelected,
    String description,
    AppThemeMode appThemeMode,
  ) {
    return InkWell(
      onTap: () {
        _themeProvider.themeMode = appThemeMode;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String title,
    String languageCode,
    String description,
  ) {
    final isSelected = _themeProvider.selectedLanguage == languageCode;

    return InkWell(
      onTap: () {
        _themeProvider.selectedLanguage = languageCode;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Text(
              languageCode.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
