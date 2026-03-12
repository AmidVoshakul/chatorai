import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/services/openrouter/openrouter_service.dart';
import 'package:chatorai/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/widgets/settings/settings_section_header.dart';
import 'package:chatorai/widgets/settings/settings_selection_card.dart';
import 'package:chatorai/widgets/settings/settings_toggle_tile.dart';
import 'package:chatorai/widgets/settings/settings_slider_card.dart';
import 'package:chatorai/widgets/settings/settings_text_field.dart';
import 'package:chatorai/widgets/settings/settings_password_field.dart';
import 'package:chatorai/widgets/settings/theme_selection_dialog.dart';
import 'package:chatorai/widgets/settings/language_selection_dialog.dart';
import 'package:chatorai/widgets/settings/about_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/utils/logger.dart';

// Initialize logger for this screen
final _logger = LogTags.settings;

// ===========================================================================
// SETTINGS SCREEN WIDGET
// ===========================================================================

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

// ===========================================================================
// STATE
// ===========================================================================

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SettingsController? _controller;

  SettingsController get controller {
    _controller ??= SettingsController();
    return _controller!;
  }

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.enableAutoSave();
      // Removed validateApiKey call - validation happens in real-time via listener

      // Set callback for when API key is saved
      controller.onApiKeySaved = () async {
        if (mounted) {
          try {
            // Reinitialize OpenRouterService with new API key
            final openRouterService = ref.read(openRouterServiceProvider);
            if (openRouterService is OpenRouterService) {
              await openRouterService.reinitialize();
            }

            // Reload models with new API key
            await ref.read(modelProvider.notifier).reloadModels();

            // Show success snackbar (check mounted again after async operations)
            if (mounted) {
              final localizations = AppLocalizations.of(context)!;
              SnackbarUtils.showSuccessSnackBar(
                context: context,
                message: localizations.apiKeySaved,
                icon: Icons.check_circle,
              );
            }
          } catch (e) {
            if (mounted) {
              _logger.logError('[Settings] Error after API key save: $e');
            }
          }
        }
      };
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

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
            ValueListenableBuilder<String?>(
              valueListenable: controller.apiKeyValidationErrorNotifier,
              builder: (context, validationError, child) {
                return SettingsPasswordField(
                  controller: controller.apiKeyController,
                  labelText: localizations.apiKey,
                  hintText: localizations.enterApiKey,
                  onCopy: () => controller.onApiKeyCopy(context, localizations),
                  validationError: validationError,
                );
              },
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

// ===========================================================================
// SETTINGS CONTROLLER
// ===========================================================================

class SettingsController {
  static final Logger _logger = LogTags.settings;

  late TextEditingController apiKeyController;
  late TextEditingController baseUrlController;

  // Validation state
  String? _apiKeyValidationError;
  final ValueNotifier<String?> apiKeyValidationErrorNotifier = ValueNotifier(
    null,
  );

  // Callback for when API key is saved (to trigger model reload)
  VoidCallback? onApiKeySaved;

  static const List<String> validApiKeyPrefixes = ['sk-', 'sk-or-'];
  static const int minApiKeyLength = 10;

  String? _lastSavedApiKey;

  SettingsController() {
    apiKeyController = TextEditingController();
    baseUrlController = TextEditingController(
      text: 'https://openrouter.ai/api/v1',
    );
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedApiKey = prefs.getString('openrouter_api_key');
      final savedBaseUrl = prefs.getString('openrouter_base_url');

      if (savedApiKey != null && savedApiKey.isNotEmpty) {
        _lastSavedApiKey = savedApiKey;
        apiKeyController.text = savedApiKey;
      } else {
        // Fallback to .env for development (only if dotenv is loaded)
        try {
          final envApiKey = dotenv.env['OPENROUTER_API_KEY'];
          if (envApiKey != null && envApiKey.isNotEmpty) {
            _lastSavedApiKey = envApiKey;
            apiKeyController.text = envApiKey;
          }
        } catch (e) {
          // dotenv not initialized or .env not found - ignore
          _logger.logDebug('[Settings] .env not available: $e');
        }
      }

      if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
        baseUrlController.text = savedBaseUrl;
      } else {
        // Fallback to .env for development (only if dotenv is loaded)
        try {
          final envBaseUrl = dotenv.env['OPENROUTER_BASE_URL'];
          if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
            baseUrlController.text = envBaseUrl;
          }
        } catch (e) {
          // dotenv not initialized or .env not found - ignore
          _logger.logDebug('[Settings] .env not available for baseUrl: $e');
        }
      }
    } catch (e) {
      _logger.logError('[Settings] Failed to load settings: $e');
      // Set defaults
      apiKeyController.text = '';
      baseUrlController.text = 'https://openrouter.ai/api/v1';
    }
  }

  void dispose() {
    apiKeyController.dispose();
    baseUrlController.dispose();
    apiKeyValidationErrorNotifier.dispose();
  }

  // ===========================================================================
  // AUTO-SAVE & VALIDATION LISTENERS
  // ===========================================================================

  /// Call this after creating controllers to enable auto-save and real-time validation
  void enableAutoSave() {
    apiKeyController.addListener(_debouncedSaveApiKey);
    apiKeyController.addListener(_validateApiKeyRealtime);
    baseUrlController.addListener(_debouncedSaveBaseUrl);
  }

  Timer? _apiKeySaveTimer;
  Timer? _baseUrlSaveTimer;

  void _debouncedSaveApiKey() {
    _apiKeySaveTimer?.cancel();
    final apiKey = apiKeyController.text.trim();
    // Сохраняем только если ключ валиден и отличается от последнего сохранённого
    if (_validateApiKey(apiKey) == null && apiKey != _lastSavedApiKey) {
      _apiKeySaveTimer = Timer(const Duration(seconds: 1), () {
        _saveApiKeyToPrefs(apiKey);
      });
    }
  }

  void _debouncedSaveBaseUrl() {
    _baseUrlSaveTimer?.cancel();
    _baseUrlSaveTimer = Timer(const Duration(seconds: 1), () {
      _saveBaseUrlToPrefs(baseUrlController.text);
    });
  }

  Future<void> _saveApiKeyToPrefs(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmedKey = apiKey.trim();
      if (trimmedKey.isEmpty) {
        await prefs.remove('openrouter_api_key');
      } else {
        await prefs.setString('openrouter_api_key', trimmedKey);
      }
      _logger.logInfo('[Settings] API key saved to SharedPreferences');

      // Показываем snackbar и вызываем callback только если ключ реально изменился и валиден
      if (_lastSavedApiKey != trimmedKey &&
          _validateApiKey(trimmedKey) == null) {
        _lastSavedApiKey = trimmedKey;
        // Не вызываем reinitialize здесь — это будет сделано в callback onApiKeySaved
        onApiKeySaved?.call();
      }
    } catch (e) {
      _logger.logError('[Settings] Failed to save API key: $e');
    }
  }

  Future<void> _saveBaseUrlToPrefs(String baseUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (baseUrl.trim().isEmpty) {
        await prefs.remove('openrouter_base_url');
      } else {
        await prefs.setString('openrouter_base_url', baseUrl.trim());
      }
      _logger.logInfo('[Settings] Base URL saved to SharedPreferences');
    } catch (e) {
      _logger.logError('[Settings] Failed to save base URL: $e');
    }
  }

  // ===========================================================================
  // REAL-TIME VALIDATION
  // ===========================================================================

  void _validateApiKeyRealtime() {
    final apiKey = apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      _apiKeyValidationError = null;
    } else if (!_isValidApiKeyFormat(apiKey)) {
      _apiKeyValidationError =
          'Invalid API key format. Should start with sk- or sk-or-';
    } else if (apiKey.length < minApiKeyLength) {
      _apiKeyValidationError =
          'API key too short (min $minApiKeyLength characters)';
    } else {
      _apiKeyValidationError = null;
    }

    apiKeyValidationErrorNotifier.value = _apiKeyValidationError;
  }

  bool _isValidApiKeyFormat(String apiKey) {
    return validApiKeyPrefixes.any((prefix) => apiKey.startsWith(prefix));
  }

  // ===========================================================================
  // CONTROLLER METHODS
  // ===========================================================================

  /// Validate API key and show snackbar if invalid (for manual validation)
  void validateApiKey(BuildContext context) {
    final error = _validateApiKey(apiKeyController.text.trim());

    if (error != null) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: error,
        icon: Icons.error,
      );
    }
  }

  /// Internal validation method that returns error message or null
  String? _validateApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      return 'API key cannot be empty'; // Empty is NOT valid
    }

    if (!_isValidApiKeyFormat(apiKey)) {
      return 'Invalid API key format. Should start with sk- or sk-or-';
    }

    if (apiKey.length < minApiKeyLength) {
      return 'API key too short (min $minApiKeyLength characters)';
    }

    return null; // Valid
  }

  /// Check if API key is currently valid (non-empty and correct format)
  bool get isApiKeyValid {
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) return false;
    return _isValidApiKeyFormat(apiKey) && apiKey.length >= minApiKeyLength;
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
