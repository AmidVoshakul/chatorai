import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/features/chat/data/models/model_settings.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:chatorai/features/chat/presentation/widgets/model_settings_header.dart';
import 'package:chatorai/features/chat/presentation/widgets/model_settings_parameter_field.dart';
import 'package:chatorai/features/chat/presentation/widgets/model_settings_system_prompt.dart';
import 'package:chatorai/features/chat/presentation/widgets/model_settings_actions.dart';

class ModelSettingsSheet extends ConsumerStatefulWidget {
  const ModelSettingsSheet({super.key});

  @override
  ConsumerState<ModelSettingsSheet> createState() => _ModelSettingsSheetState();
}

class _ModelSettingsSheetState extends ConsumerState<ModelSettingsSheet> {
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  void _initializeControllers() {
    final settingsState = ref.read(modelSettingsProvider);
    final modelState = ref.read(modelProvider);
    final settingsNotifier = ref.read(modelSettingsProvider.notifier);

    if (settingsState.activeSettings == null &&
        modelState.selectedModelId.isNotEmpty) {
      settingsNotifier.setActiveModel(modelState.selectedModelId);
    }

    if (settingsState.activeSettings != null) {
      final settings = settingsState.activeSettings!;
      _temperatureController.text = settings.temperature.toString();
      _systemPromptController.text = settings.systemPrompt ?? '';
      _isInitialized = true;
    } else if (modelState.selectedModelObject != null) {
      final defaultSettings = ModelSettings.defaultForModel(
        modelState.selectedModelObject!.id,
      );
      _temperatureController.text = defaultSettings.temperature.toString();
      _systemPromptController.text = defaultSettings.systemPrompt ?? '';
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          settingsNotifier.updateActiveSettings(defaultSettings);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeControllers();
    }
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  bool get isMobile => MediaQuery.of(context).size.width < 600;

  void _applySettings() {
    final settingsState = ref.read(modelSettingsProvider);
    final settingsNotifier = ref.read(modelSettingsProvider.notifier);
    final localizations = AppLocalizations.of(context);

    if (settingsState.activeSettings == null) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.noModelSelected,
        icon: Icons.error,
      );
      return;
    }

    try {
      final current = settingsState.activeSettings!;
      final updatedSettings = ModelSettings(
        modelId: current.modelId,
        temperature:
            double.tryParse(_temperatureController.text) ?? current.temperature,
        systemPrompt: _systemPromptController.text.isNotEmpty
            ? _systemPromptController.text
            : null,
        stream: current.stream,
        reasoningEnabled: current.reasoningEnabled,
      );
      settingsNotifier.updateActiveSettings(updatedSettings);
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: localizations.settingsApplied,
        icon: Icons.check_circle,
        duration: const Duration(seconds: 2),
      );
      Navigator.of(context).pop();
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'Error applying settings: $e',
        icon: Icons.error,
      );
    }
  }

  void _resetToDefaults() {
    final settingsState = ref.read(modelSettingsProvider);
    final settingsNotifier = ref.read(modelSettingsProvider.notifier);
    final localizations = AppLocalizations.of(context);

    if (settingsState.activeSettings == null) return;

    final defaultSettings = ModelSettings.defaultForModel(
      settingsState.activeSettings!.modelId,
    );
    _temperatureController.text = defaultSettings.temperature.toString();
    _systemPromptController.text = defaultSettings.systemPrompt ?? '';
    settingsNotifier.updateActiveSettings(defaultSettings);
    SnackbarUtils.showInfoSnackBar(
      context: context,
      message: localizations.settingsReset,
      icon: Icons.refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);
    final modelState = ref.watch(modelProvider);
    final settingsState = ref.watch(modelSettingsProvider);

    String modelName = localizations.noModelSelected;
    if (modelState.selectedModelObject != null) {
      modelName = modelState.selectedModelObject!.name;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ChatoraiColors.darkCard : ChatoraiColors.lightCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(ChatoraiBorderRadius.xl),
          topRight: Radius.circular(ChatoraiBorderRadius.xl),
        ),
        boxShadow: ChatoraiShadows.popupShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModelSettingsHeader(
            modelName: modelName,
            onClose: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ChatoraiSpacing.lg),
              child: settingsState.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ChatoraiColors.orange,
                            ),
                          ),
                          const SizedBox(height: ChatoraiSpacing.lg),
                          Text(
                            'Loading settings...',
                            style: TextStyle(
                              fontSize: ChatoraiFontSizes.lg,
                              color: isDark
                                  ? ChatoraiColors.darkSecondaryTextColor
                                  : ChatoraiColors.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : settingsState.activeSettings == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.settings_suggest,
                            size: ChatoraiIconSizes.xxxl,
                            color: isDark
                                ? ChatoraiColors.darkSecondaryTextColor
                                : ChatoraiColors.secondaryTextColor,
                          ),
                          const SizedBox(height: ChatoraiSpacing.lg),
                          Text(
                            localizations.noModelSelected,
                            style: TextStyle(
                              fontSize: ChatoraiFontSizes.lg,
                              color: isDark
                                  ? ChatoraiColors.darkSecondaryTextColor
                                  : ChatoraiColors.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.modelParameters,
                          style: TextStyle(
                            fontSize: ChatoraiFontSizes.lg,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? ChatoraiColors.pureWhite
                                : ChatoraiColors.pureBlack,
                          ),
                        ),
                        const SizedBox(height: ChatoraiSpacing.lg),
                        ModelSettingsParameterField(
                          label: localizations.temperature,
                          description: localizations.temperatureDescription,
                          controller: _temperatureController,
                          hintText: '0.0 - 2.0',
                          isDecimal: true,
                          min: 0.0,
                          max: 2.0,
                        ),
                        ModelSettingsSystemPrompt(
                          controller: _systemPromptController,
                        ),
                        const SizedBox(height: ChatoraiSpacing.xxl),
                        ModelSettingsActions(
                          isMobile: isMobile,
                          onReset: _resetToDefaults,
                          onApply: _applySettings,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
