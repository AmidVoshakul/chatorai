import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';

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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? UbuntuColors.darkInputBorder
                        : UbuntuColors.inputBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: UbuntuColors.orange,
                    width: 2,
                  ),
                ),
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
              decoration: InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://openrouter.ai/api/v1',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? UbuntuColors.darkInputBorder
                        : UbuntuColors.inputBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: UbuntuColors.orange,
                    width: 2,
                  ),
                ),
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
            _buildSelectionCard(
              context: context,
              icon: Icons.palette,
              title: _getThemeModeName(_themeProvider.themeMode, localizations),
              subtitle: localizations.theme,
              onTap: () => _showThemeDialog(context, localizations),
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
            _buildSelectionCard(
              context: context,
              icon: Icons.language,
              title: _getLanguageName(_themeProvider.selectedLanguage, localizations),
              subtitle: localizations.language,
              onTap: () => _showLanguageDialog(context, localizations),
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
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? UbuntuColors.darkInputBorder
                          : UbuntuColors.inputBorder,
                    ),
                    SwitchListTile(
                      value: _themeProvider.highContrast,
                      onChanged: (value) {
                        _themeProvider.highContrast = value;
                      },
                      title: Text(localizations.highContrast),
                      subtitle: Text(localizations.increaseContrast),
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? UbuntuColors.darkInputBorder
                          : UbuntuColors.inputBorder,
                    ),
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
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? UbuntuColors.darkInputBorder
                                : UbuntuColors.inputBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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

            const SizedBox(height: 20),

            // About Section

            const SizedBox(height: 8),
            _buildSelectionCard(
              context: context,
              icon: Icons.info,
              title: localizations.appInfo,
              subtitle: '',
              onTap: () => _showAboutDialog(context, localizations),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Show About dialog
  void _showAboutDialog(BuildContext context, AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: isDark ? UbuntuColors.darkCard : UbuntuColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? UbuntuColors.darkInputBorder : UbuntuColors.inputBorder,
              width: 1,
            ),
          ),
          elevation: 0,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      localizations.appTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? UbuntuColors.light : UbuntuColors.dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      localizations.appDescription,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? UbuntuColors.darkSecondaryTextColor : UbuntuColors.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Close icon in top-right corner
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: isDark ? UbuntuColors.darkSecondaryTextColor : UbuntuColors.secondaryTextColor,
                  onPressed: () => Navigator.pop(context),
                  tooltip: localizations.close,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build unified selection card
  Widget _buildSelectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      color: isDark ? UbuntuColors.darkCard : UbuntuColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark ? UbuntuColors.darkInputBorder : UbuntuColors.inputBorder,
          width: 1,
        ),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: UbuntuColors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? UbuntuColors.darkTextColor : UbuntuColors.lightTextColor,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? UbuntuColors.darkSecondaryTextColor : UbuntuColors.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? UbuntuColors.darkSecondaryTextColor : UbuntuColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show theme selection dialog
  void _showThemeDialog(BuildContext context, AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: isDark ? UbuntuColors.darkCard : UbuntuColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? UbuntuColors.darkInputBorder : UbuntuColors.inputBorder,
              width: 1,
            ),
          ),
          elevation: 0,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.theme,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? UbuntuColors.light : UbuntuColors.dark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogOption(
                      context: context,
                      icon: Icons.brightness_6,
                      title: localizations.system,
                      subtitle: localizations.useSystemTheme,
                      isSelected: _themeProvider.themeMode == AppThemeMode.system,
                      onTap: () {
                        _themeProvider.themeMode = AppThemeMode.system;
                        Navigator.pop(context);
                        SnackbarUtils.showSuccessSnackBar(
                          context: context,
                          message: localizations.settingsSaved,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDialogOption(
                      context: context,
                      icon: Icons.wb_sunny,
                      title: localizations.light,
                      subtitle: localizations.useLightTheme,
                      isSelected: _themeProvider.themeMode == AppThemeMode.light,
                      onTap: () {
                        _themeProvider.themeMode = AppThemeMode.light;
                        Navigator.pop(context);
                        SnackbarUtils.showSuccessSnackBar(
                          context: context,
                          message: localizations.settingsSaved,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDialogOption(
                      context: context,
                      icon: Icons.nightlight,
                      title: localizations.dark,
                      subtitle: localizations.useDarkTheme,
                      isSelected: _themeProvider.themeMode == AppThemeMode.dark,
                      onTap: () {
                        _themeProvider.themeMode = AppThemeMode.dark;
                        Navigator.pop(context);
                        SnackbarUtils.showSuccessSnackBar(
                          context: context,
                          message: localizations.settingsSaved,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Close icon in top-right corner
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: isDark ? UbuntuColors.darkSecondaryTextColor : UbuntuColors.secondaryTextColor,
                  onPressed: () => Navigator.pop(context),
                  tooltip: localizations.close,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show language selection dialog
  void _showLanguageDialog(BuildContext context, AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languages = <String, String>{
      'en': localizations.english,
      'ru': localizations.russian,
      'uk': localizations.ukrainian,
      'ar': localizations.arabic,
      'zh': localizations.chinese,
      'ja': localizations.japanese,
    };
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: isDark ? UbuntuColors.darkCard : UbuntuColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? UbuntuColors.darkInputBorder : UbuntuColors.inputBorder,
              width: 1,
            ),
          ),
          elevation: 0,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.language,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? UbuntuColors.light : UbuntuColors.dark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.maxFinite,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: languages.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: isDark ? UbuntuColors.darkInputBorder : UbuntuColors.inputBorder,
                        ),
                        itemBuilder: (context, index) {
                          final entry = languages.entries.elementAt(index);
                          final isSelected = _themeProvider.selectedLanguage == entry.key;
                          
                          return _buildDialogOption(
                            context: context,
                            icon: Icons.language,
                            title: entry.key.toUpperCase(),
                            subtitle: entry.value,
                            isSelected: isSelected,
                            onTap: () {
                              _themeProvider.selectedLanguage = entry.key;
                              Navigator.pop(context);
                              SnackbarUtils.showSuccessSnackBar(
                                context: context,
                                message: localizations.settingsSaved,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Close icon in top-right corner
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: isDark ? UbuntuColors.darkSecondaryTextColor : UbuntuColors.secondaryTextColor,
                  onPressed: () => Navigator.pop(context),
                  tooltip: localizations.close,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build dialog option item
  Widget _buildDialogOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected 
              ? (isDark ? UbuntuColors.darkSurface : UbuntuColors.lightSurface)
              : Colors.transparent,
            border: isSelected
              ? Border.all(color: UbuntuColors.orange, width: 1)
              : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? UbuntuColors.orange : (isDark ? UbuntuColors.darkSecondaryTextColor : UbuntuColors.secondaryTextColor),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected 
                          ? UbuntuColors.orange
                          : (isDark ? UbuntuColors.darkTextColor : UbuntuColors.lightTextColor),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? UbuntuColors.darkSecondaryTextColor : UbuntuColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: UbuntuColors.orange,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Get theme mode display name
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

  // Get language display name
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
