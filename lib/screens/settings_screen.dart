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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : null,
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : null,
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : null,
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
                    const Divider(height: 1, thickness: 1),
                    SwitchListTile(
                      value: _themeProvider.wideScreenMode,
                      onChanged: (value) {
                        _themeProvider.wideScreenMode = value;
                      },
                      title: Text(localizations.wideScreenMode),
                      subtitle: Text(localizations.useFullScreenWidth),
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.selectLanguage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]!
                              : Colors.grey[400]!,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _themeProvider.selectedLanguage,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          dropdownColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[850]
                              : Colors.white,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _themeProvider.selectedLanguage = newValue;
                            }
                          },
                          items: <String, String>{
                            'en': localizations.english,
                            'ru': localizations.russian,
                            'uk': localizations.ukrainian,
                            'ar': localizations.arabic,
                            'zh': localizations.chinese,
                            'ja': localizations.japanese,
                          }.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Row(
                                children: [
                                  Text(
                                    entry.key.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    entry.value,
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      localizations.resetAllSettings,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final local = AppLocalizations.of(context)!;
                          await _themeProvider.resetSettings();
                          if (mounted && context.mounted) {
                            SnackbarUtils.showInfoSnackBar(
                              context: context,
                              message: local.settingsReset
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
                  final local = AppLocalizations.of(context)!;
                  if (mounted && context.mounted) {
                    SnackbarUtils.showSuccessSnackBar(
                      context: context,
                      message: local.settingsSaved
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

}
