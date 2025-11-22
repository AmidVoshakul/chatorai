import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:gen_ui_chat_ai/utils/ui_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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

    final String currentLanguage = _themeProvider.selectedLanguage;
    
    // Simple localization function
    String t(String key) {
      if (currentLanguage == 'en') {
        return {
          'settings': 'Settings',
          'openRouterConfiguration': 'OpenRouter Configuration',
          'apiKey': 'API Key',
          'enterApiKey': 'Enter your OpenRouter API key',
          'baseUrl': 'Base URL',
          'appearance': 'Appearance',
          'theme': 'Theme',
          'system': 'System',
          'useSystemTheme': 'Use system theme',
          'light': 'Light',
          'useLightTheme': 'Use light theme',
          'dark': 'Dark',
          'useDarkTheme': 'Use dark theme',
          'fontSize': 'Font Size',
          'currentSize': 'Current size: {percentage}%',
          'accessibility': 'Accessibility',
          'reduceMotion': 'Reduce Motion',
          'disableAnimation': 'Disable or reduce animation effects',
          'highContrast': 'High Contrast',
          'increaseContrast': 'Increase contrast for better readability',
          'language': 'Language',
          'english': 'English',
          'russian': 'Russian',
          'arabic': 'Arabic (RTL)',
          'chinese': 'Chinese',
          'japanese': 'Japanese',
          'resetSettings': 'Reset Settings',
          'resetAllSettings': 'Reset all settings to default values',
          'save': 'Save',
          'copy': 'Copy',
          'apiKeyCopied': 'API key copied',
          'settingsSaved': 'Settings saved!',
          'settingsReset': 'Settings reset to default values',
        }[key] ?? key;
      } else {
        return {
          'settings': 'Настройки',
          'openRouterConfiguration': 'OpenRouter Конфигурация',
          'apiKey': 'API Ключ',
          'enterApiKey': 'Введите ваш OpenRouter API ключ',
          'baseUrl': 'Base URL',
          'appearance': 'Внешний вид',
          'theme': 'Тема',
          'system': 'Системная',
          'useSystemTheme': 'Использовать тему системы',
          'light': 'Светлая',
          'useLightTheme': 'Использовать светлую тему',
          'dark': 'Темная',
          'useDarkTheme': 'Использовать темную тему',
          'fontSize': 'Размер шрифта',
          'currentSize': 'Текущий размер: {percentage}%',
          'accessibility': 'Доступность',
          'reduceMotion': 'Уменьшить анимацию',
          'disableAnimation': 'Отключить или уменьшить анимационные эффекты',
          'highContrast': 'Высокая контрастность',
          'increaseContrast': 'Увеличить контрастность для лучшей читаемости',
          'language': 'Язык',
          'english': 'Английский',
          'russian': 'Русский',
          'arabic': 'Арабский (RTL)',
          'chinese': 'Китайский',
          'japanese': 'Японский',
          'resetSettings': 'Сброс настроек',
          'resetAllSettings': 'Сбросить все настройки к значениям по умолчанию',
          'save': 'Сохранить',
          'copy': 'Скопировать',
          'apiKeyCopied': 'API ключ скопирован',
          'settingsSaved': 'Настройки сохранены!',
          'settingsReset': 'Настройки сброшены к значениям по умолчанию',
        }[key] ?? key;
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t('settings')),
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
              t('openRouterConfiguration'),
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
                labelText: t('apiKey'),
                hintText: t('enterApiKey'),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () {
                    // Copy to clipboard functionality
                    UIHelper.showCopySnackBar(context, t('apiKeyCopied'));
                  },
                  tooltip: t('copy'),
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
              t('appearance'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Theme Selection
            Text(
              t('theme'),
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
                      t('system'),
                      _themeProvider.themeMode == AppThemeMode.system,
                      t('useSystemTheme'),
                      AppThemeMode.system,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildThemeOption(
                      Icons.wb_sunny,
                      t('light'),
                      _themeProvider.themeMode == AppThemeMode.light,
                      t('useLightTheme'),
                      AppThemeMode.light,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildThemeOption(
                      Icons.nightlight,
                      t('dark'),
                      _themeProvider.themeMode == AppThemeMode.dark,
                      t('useDarkTheme'),
                      AppThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Font Size
            Text(
              t('fontSize'),
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
                      t('currentSize').replaceFirst('{percentage}', '${(_themeProvider.fontSize * 100).toInt()}'),
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
              t('accessibility'),
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
                      title: Text(t('reduceMotion')),
                      subtitle: Text(t('disableAnimation')),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    const Divider(height: 1, thickness: 1),
                    SwitchListTile(
                      value: _themeProvider.highContrast,
                      onChanged: (value) {
                        _themeProvider.highContrast = value;
                      },
                      title: Text(t('highContrast')),
                      subtitle: Text(t('increaseContrast')),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Language Section
            Text(
              t('language'),
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
                      t('english'),
                      'en',
                      t('english'),
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildLanguageOption(
                      t('russian'),
                      'ru',
                      t('russian'),
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildLanguageOption(
                      'العربية',
                      'ar',
                      t('arabic'),
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildLanguageOption(
                      '中文',
                      'zh',
                      t('chinese'),
                    ),
                    const Divider(height: 1, thickness: 1),
                    _buildLanguageOption(
                      '日本語',
                      'ja',
                      t('japanese'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Reset Settings
            Text(
              t('resetSettings'),
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
                      t('resetAllSettings'),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await _themeProvider.resetSettings();
                          if (mounted) {
                            UIHelper.showInfoSnackBar(
                              context, 
                              t('settingsReset')
                            );
                          }
                        },
                        child: Text(t('resetSettings')),
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
                    UIHelper.showSuccessSnackBar(
                      context, 
                      t('settingsSaved')
                    );
                  }
                  Navigator.of(context).pop();
                },
                child: Text(t('save')),
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