import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chatorai/providers/theme_provider.dart';
import 'package:chatorai/providers/language_provider.dart';
import 'package:chatorai/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/themes/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeProvider _themeProvider;
  late LanguageProvider _languageProvider;
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;

  @override
  void initState() {
    super.initState();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    _apiKeyController = TextEditingController(
      text: dotenv.env['OPENROUTER_API_KEY'] ?? '',
    );
    _baseUrlController = TextEditingController(
      text: dotenv.env['OPENROUTER_BASE_URL'] ?? 'https://openrouter.ai/api/v1',
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
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
              localizations.providerConfiguration,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  borderSide: BorderSide(color: UbuntuColors.orange, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () {
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
                  borderSide: BorderSide(color: UbuntuColors.orange, width: 2),
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 20),

            Text(
              localizations.appearance,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Theme Selection
            Text(
              localizations.theme,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildSelectionCard(
              context: context,
              icon: Icons.palette,
              title: _getThemeModeName(themeProvider.themeMode, localizations),
              subtitle: localizations.theme,
              onTap: () => _showThemeDialog(context, localizations),
            ),

            const SizedBox(height: 20),

            // Language Section
            Text(
              localizations.language,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildSelectionCard(
              context: context,
              icon: Icons.language,
              title: _getLanguageName(
                languageProvider.selectedLanguage,
                localizations,
              ),
              subtitle: localizations.language,
              onTap: () => _showLanguageDialog(context, localizations),
            ),

            const SizedBox(height: 20),

            // Font Size
            Text(
              localizations.fontSize,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).brightness == Brightness.dark
                  ? UbuntuColors.darkCard
                  : UbuntuColors.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? UbuntuColors.darkInputBorder
                      : UbuntuColors.inputBorder,
                  width: 1,
                ),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      localizations.currentSize(
                        (themeProvider.fontSize * 100).toInt(),
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? UbuntuColors.darkTextColor
                            : UbuntuColors.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 18,
                          color: UbuntuColors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: UbuntuColors.orange,
                              inactiveTrackColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? UbuntuColors.darkInputBorder
                                  : UbuntuColors.inputBorder,
                              thumbColor: UbuntuColors.orange,
                              overlayColor: UbuntuColors.orange.withAlpha(30),
                              valueIndicatorColor: UbuntuColors.orange,
                              valueIndicatorTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: Slider(
                              value: themeProvider.fontSize,
                              min: 0.8,
                              max: 1.5,
                              divisions: 7,
                              label:
                                  '${(themeProvider.fontSize * 100).toInt()}%',
                              onChanged: (value) {
                                themeProvider.fontSize = value;
                              },
                            ),
                          ),
                        ),
                        Icon(
                          Icons.text_fields,
                          size: 26,
                          color: UbuntuColors.orange,
                        ),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).brightness == Brightness.dark
                  ? UbuntuColors.darkCard
                  : UbuntuColors.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? UbuntuColors.darkInputBorder
                      : UbuntuColors.inputBorder,
                  width: 1,
                ),
              ),
              elevation: 0,
              child: _buildToggleTile(
                title: localizations.wideScreenMode,
                subtitle: localizations.useFullScreenWidth,
                value: themeProvider.wideScreenMode,
                onChanged: (value) => themeProvider.wideScreenMode = value,
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
          backgroundColor: isDark
              ? UbuntuColors.darkCard
              : UbuntuColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark
                  ? UbuntuColors.darkInputBorder
                  : UbuntuColors.inputBorder,
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
                        color: isDark
                            ? UbuntuColors.darkSecondaryTextColor
                            : UbuntuColors.secondaryTextColor,
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
                  color: isDark
                      ? UbuntuColors.darkSecondaryTextColor
                      : UbuntuColors.secondaryTextColor,
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
          color: isDark
              ? UbuntuColors.darkInputBorder
              : UbuntuColors.inputBorder,
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
              Icon(icon, color: UbuntuColors.orange, size: 20),
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
                        color: isDark
                            ? UbuntuColors.darkTextColor
                            : UbuntuColors.lightTextColor,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? UbuntuColors.darkSecondaryTextColor
                              : UbuntuColors.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark
                    ? UbuntuColors.darkSecondaryTextColor
                    : UbuntuColors.secondaryTextColor,
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
          backgroundColor: isDark
              ? UbuntuColors.darkCard
              : UbuntuColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark
                  ? UbuntuColors.darkInputBorder
                  : UbuntuColors.inputBorder,
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
                      isSelected:
                          _themeProvider.themeMode == AppThemeMode.system,
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
                      isSelected:
                          _themeProvider.themeMode == AppThemeMode.light,
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
                  color: isDark
                      ? UbuntuColors.darkSecondaryTextColor
                      : UbuntuColors.secondaryTextColor,
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
  void _showLanguageDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) {
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
          backgroundColor: isDark
              ? UbuntuColors.darkCard
              : UbuntuColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark
                  ? UbuntuColors.darkInputBorder
                  : UbuntuColors.inputBorder,
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
                          color: isDark
                              ? UbuntuColors.darkInputBorder
                              : UbuntuColors.inputBorder,
                        ),
                        itemBuilder: (context, index) {
                          final entry = languages.entries.elementAt(index);
                          final isSelected =
                              _languageProvider.selectedLanguage == entry.key;

                          return _buildDialogOption(
                            context: context,
                            icon: Icons.language,
                            title: entry.key.toUpperCase(),
                            subtitle: entry.value,
                            isSelected: isSelected,
                            onTap: () {
                              _languageProvider.selectedLanguage = entry.key;
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
                  color: isDark
                      ? UbuntuColors.darkSecondaryTextColor
                      : UbuntuColors.secondaryTextColor,
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
                ? (isDark
                      ? UbuntuColors.darkSurface
                      : UbuntuColors.lightSurface)
                : Colors.transparent,
            border: isSelected
                ? Border.all(color: UbuntuColors.orange, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? UbuntuColors.orange
                    : (isDark
                          ? UbuntuColors.darkSecondaryTextColor
                          : UbuntuColors.secondaryTextColor),
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
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? UbuntuColors.orange
                            : (isDark
                                  ? UbuntuColors.darkTextColor
                                  : UbuntuColors.lightTextColor),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? UbuntuColors.darkSecondaryTextColor
                            : UbuntuColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: UbuntuColors.orange, size: 20),
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

  // Build modern Google-style toggle tile
  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? UbuntuColors.darkTextColor
                          : UbuntuColors.lightTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? UbuntuColors.darkSecondaryTextColor
                          : UbuntuColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: UbuntuColors.orange,
                activeTrackColor: UbuntuColors.orange.withAlpha(150),
                inactiveThumbColor: isDark
                    ? UbuntuColors.toggleInactiveThumbDark
                    : UbuntuColors.toggleInactiveThumbLight,
                inactiveTrackColor: isDark
                    ? UbuntuColors.toggleInactiveTrackDark
                    : UbuntuColors.toggleInactiveTrackLight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
