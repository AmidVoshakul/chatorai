import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/gui/features/settings/data/models/model_settings.dart';
import 'package:chatorai/gui/features/settings/widgets/model_settings_actions.dart';
import 'package:chatorai/gui/features/settings/widgets/model_settings_header.dart';
import 'package:chatorai/gui/features/settings/widgets/model_settings_parameter_field.dart';
import 'package:chatorai/gui/features/settings/widgets/model_settings_system_prompt.dart';
import 'package:chatorai/gui/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/gui/shared/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModelSettingsSheet extends ConsumerStatefulWidget {
  const ModelSettingsSheet({super.key});

  @override
  ConsumerState<ModelSettingsSheet> createState() => _ModelSettingsSheetState();
}

class _ModelSettingsSheetState extends ConsumerState<ModelSettingsSheet> {
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final modelState = ref.read(modelProvider);
      if (modelState.selectedModelId.isNotEmpty) {
        ref
            .read(modelSettingsProvider.notifier)
            .setActiveModel(modelState.selectedModelId);
      }
    });
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
    final localizations = AppLocalizations.of(context)!;

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
        message: localizations.errorApplyingSettings(e.toString()),
        icon: Icons.error,
      );
    }
  }

  void _resetToDefaults() {
    final settingsState = ref.read(modelSettingsProvider);
    final settingsNotifier = ref.read(modelSettingsProvider.notifier);
    final localizations = AppLocalizations.of(context)!;

    if (settingsState.activeSettings == null) return;

    final modelId = settingsState.activeSettings!.modelId;

    double? catalogDefault;
    try {
      final catalog = ref.read(providerCatalogServiceProvider);
      catalogDefault = catalog.getModel(modelId)?.defaultTemperature;
    } catch (_) {}

    final agent = ref.read(currentAgentProvider);
    final effectiveDefault = agent.temperature ?? catalogDefault ?? 1.0;

    final defaultSettings = ModelSettings(
      modelId: modelId,
      temperature: effectiveDefault,
    );
    _temperatureController.text = effectiveDefault.toStringAsFixed(1);
    _systemPromptController.text = '';
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
    final localizations = AppLocalizations.of(context)!;
    final modelState = ref.watch(modelProvider);
    final settingsState = ref.watch(modelSettingsProvider);

    if (!_populated &&
        settingsState.activeSettings != null &&
        !settingsState.isLoading) {
      _populated = true;
      final agent = ref.read(currentAgentProvider);
      final displayTemp =
          agent.temperature ?? settingsState.activeSettings!.temperature;
      _temperatureController.text = displayTemp.toStringAsFixed(1);
      _systemPromptController.text =
          settingsState.activeSettings!.systemPrompt ?? '';
    }

    String modelName = localizations.noModelSelected;
    if (modelState.selectedModelObject != null) {
      modelName = modelState.selectedModelObject!.name;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF222222)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFAFAFA), Color(0xFFF7F7F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(ChatoraiBorderRadius.xl),
          topRight: Radius.circular(ChatoraiBorderRadius.xl),
        ),
        border: Border(
          top: BorderSide(
            color: isDark
                ? ChatoraiColors.darkBorderColor
                : ChatoraiColors.lightBorderColor,
            width: ChatoraiBorderWidth.thinBold,
          ),
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
          _HairlineDivider(
            color: isDark
                ? ChatoraiColors.darkInputBorder
                : ChatoraiColors.inputBorder,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ChatoraiSpacing.lg),
              child: settingsState.isLoading
                  ? _LoadingState(isDark: isDark, localizations: localizations)
                  : settingsState.activeSettings == null
                  ? _EmptyState(isDark: isDark, localizations: localizations)
                  : _SettingsForm(
                      isDark: isDark,
                      localizations: localizations,
                      temperatureController: _temperatureController,
                      systemPromptController: _systemPromptController,
                      isMobile: isMobile,
                      onReset: _resetToDefaults,
                      onApply: _applySettings,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HairlineDivider extends StatelessWidget {
  final Color color;
  const _HairlineDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(height: ChatoraiBorderWidth.thin, color: color);
  }
}

class _LoadingState extends StatelessWidget {
  final bool isDark;
  final AppLocalizations localizations;

  const _LoadingState({required this.isDark, required this.localizations});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ChatoraiColors.orange),
          ),
          const SizedBox(height: ChatoraiSpacing.lg),
          Text(
            localizations.loadingSettings,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.lg,
              color: isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final AppLocalizations localizations;

  const _EmptyState({required this.isDark, required this.localizations});

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

class _SettingsForm extends StatelessWidget {
  final bool isDark;
  final AppLocalizations localizations;
  final TextEditingController temperatureController;
  final TextEditingController systemPromptController;
  final bool isMobile;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const _SettingsForm({
    required this.isDark,
    required this.localizations,
    required this.temperatureController,
    required this.systemPromptController,
    required this.isMobile,
    required this.onReset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: localizations.modelParameters,
          helper: localizations.temperatureDescription,
          isDark: isDark,
        ),
        const SizedBox(height: ChatoraiSpacing.lg),
        ModelSettingsParameterField(
          label: localizations.temperature,
          description: localizations.temperatureDescription,
          controller: temperatureController,
          hintText: localizations.temperatureHint,
          isDecimal: true,
          min: 0.0,
          max: 2.0,
        ),
        const SizedBox(height: ChatoraiSpacing.xl),
        ModelSettingsSystemPrompt(controller: systemPromptController),
        const SizedBox(height: ChatoraiSpacing.xxl),
        ModelSettingsActions(
          isMobile: isMobile,
          onReset: onReset,
          onApply: onApply,
        ),
      ],
    );
  }
}
