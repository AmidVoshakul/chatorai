import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/models/model_settings.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/utils/snackbar_utils.dart';

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
        message: 'Error applying settings: $e',
        icon: Icons.error,
      );
    }
  }

  void _resetToDefaults() {
    final settingsState = ref.read(modelSettingsProvider);
    final settingsNotifier = ref.read(modelSettingsProvider.notifier);
    final localizations = AppLocalizations.of(context)!;

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

  Widget _buildParameterField({
    required String label,
    required String description,
    required TextEditingController controller,
    required String hintText,
    bool isDecimal = false,
    double min = 0.0,
    double max = 2.0,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.base,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? ChatoraiColors.pureWhite
                      : ChatoraiColors.pureBlack,
                ),
              ),
            ),
            const SizedBox(width: ChatoraiSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatoraiSpacing.sm,
                vertical: ChatoraiSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: ChatoraiColors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xs),
              ),
              child: Text(
                controller.text,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.md,
                  fontWeight: FontWeight.bold,
                  color: ChatoraiColors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ChatoraiSpacing.xs),
        Text(
          description,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.md,
            color: isDark
                ? ChatoraiColors.darkSecondaryTextColor
                : ChatoraiColors.secondaryTextColor,
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: isDark
                ? ChatoraiColors.darkInputFill
                : ChatoraiColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              borderSide: BorderSide(
                color: isDark
                    ? ChatoraiColors.darkInputBorder
                    : ChatoraiColors.inputBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              borderSide: BorderSide(
                color: isDark
                    ? ChatoraiColors.darkInputBorder
                    : ChatoraiColors.inputBorder,
                width: ChatoraiBorderWidth.thinBold,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              borderSide: const BorderSide(
                color: ChatoraiColors.orange,
                width: ChatoraiBorderWidth.medium,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ChatoraiSpacing.md,
              vertical: ChatoraiSpacing.sm,
            ),
          ),
          style: TextStyle(
            fontSize: ChatoraiFontSizes.base,
            color: isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack,
          ),
          inputFormatters: [
            if (isDecimal)
              _DecimalTextInputFormatter(min: min, max: max)
            else
              _IntegerTextInputFormatter(min: min.toInt(), max: max.toInt()),
          ],
        ),
        const SizedBox(height: ChatoraiSpacing.lg),
      ],
    );
  }

  Widget _buildSystemPromptField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.systemPrompt,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.base,
            fontWeight: FontWeight.w600,
            color: isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack,
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.xs),
        Text(
          localizations.systemPromptDescription,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.md,
            color: isDark
                ? ChatoraiColors.darkSecondaryTextColor
                : ChatoraiColors.secondaryTextColor,
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.sm),
        TextField(
          controller: _systemPromptController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'You are a helpful assistant...',
            filled: true,
            fillColor: isDark
                ? ChatoraiColors.darkInputFill
                : ChatoraiColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              borderSide: BorderSide(
                color: isDark
                    ? ChatoraiColors.darkInputBorder
                    : ChatoraiColors.inputBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              borderSide: BorderSide(
                color: isDark
                    ? ChatoraiColors.darkInputBorder
                    : ChatoraiColors.inputBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              borderSide: const BorderSide(
                color: ChatoraiColors.orange,
                width: ChatoraiBorderWidth.medium,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ChatoraiSpacing.md,
              vertical: ChatoraiSpacing.md,
            ),
          ),
          style: TextStyle(
            fontSize: ChatoraiFontSizes.base,
            color: isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack,
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.lg),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
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
          Container(
            padding: const EdgeInsets.all(ChatoraiSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? ChatoraiColors.darkBorderColor
                      : ChatoraiColors.lightBorderColor,
                  width: ChatoraiBorderWidth.thinBold,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  color: ChatoraiColors.orange,
                  size: ChatoraiIconSizes.xxl,
                ),
                const SizedBox(width: ChatoraiSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.modelSettings,
                        style: TextStyle(
                          fontSize: ChatoraiFontSizes.xl,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? ChatoraiColors.pureWhite
                              : ChatoraiColors.pureBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        modelName,
                        style: TextStyle(
                          fontSize: ChatoraiFontSizes.md,
                          color: isDark
                              ? ChatoraiColors.darkSecondaryTextColor
                              : ChatoraiColors.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark
                        ? ChatoraiColors.white70
                        : ChatoraiColors.secondaryTextColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
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
                        // Temperature
                        _buildParameterField(
                          label: localizations.temperature,
                          description: localizations.temperatureDescription,
                          controller: _temperatureController,
                          hintText: '0.0 - 2.0',
                          isDecimal: true,
                          min: 0.0,
                          max: 2.0,
                        ),
                        // System Prompt
                        _buildSystemPromptField(),
                        const SizedBox(height: ChatoraiSpacing.xxl),
                        // Action Buttons
                        isMobile
                            ? Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _resetToDefaults,
                                      icon: const Icon(Icons.refresh),
                                      label: Text(
                                        localizations.resetToDefaults,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark
                                            ? ChatoraiColors.pureWhite
                                            : ChatoraiColors.pureBlack,
                                        side: BorderSide(
                                          color: isDark
                                              ? ChatoraiColors.darkGray
                                              : ChatoraiColors.mediumGray,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: ChatoraiSpacing.md,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: ChatoraiSpacing.md),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _applySettings,
                                      icon: const Icon(Icons.check),
                                      label: Text(localizations.applySettings),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ChatoraiColors.orange,
                                        foregroundColor:
                                            ChatoraiColors.pureWhite,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: ChatoraiSpacing.md,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _resetToDefaults,
                                      icon: const Icon(Icons.refresh),
                                      label: Text(
                                        localizations.resetToDefaults,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark
                                            ? ChatoraiColors.pureWhite
                                            : ChatoraiColors.pureBlack,
                                        side: BorderSide(
                                          color: isDark
                                              ? ChatoraiColors.darkGray
                                              : ChatoraiColors.mediumGray,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: ChatoraiSpacing.md,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: ChatoraiSpacing.md),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _applySettings,
                                      icon: const Icon(Icons.check),
                                      label: Text(localizations.applySettings),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ChatoraiColors.orange,
                                        foregroundColor:
                                            ChatoraiColors.pureWhite,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: ChatoraiSpacing.md,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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

class _DecimalTextInputFormatter extends TextInputFormatter {
  final double min;
  final double max;

  _DecimalTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final RegExp regex = RegExp(r'^[0-9]*\.?[0-9]*$');
    if (!regex.hasMatch(newValue.text)) return oldValue;
    final double? value = double.tryParse(newValue.text);
    if (value == null) return oldValue;
    if (value < min || value > max) return oldValue;
    return newValue;
  }
}

class _IntegerTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _IntegerTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final RegExp regex = RegExp(r'^[0-9]*$');
    if (!regex.hasMatch(newValue.text)) return oldValue;
    final int? value = int.tryParse(newValue.text);
    if (value == null) return oldValue;
    if (value < min || value > max) return oldValue;
    return newValue;
  }
}
