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
  final TextEditingController _maxTokensController = TextEditingController();
  final TextEditingController _topPController = TextEditingController();
  final TextEditingController _frequencyPenaltyController =
      TextEditingController();
  final TextEditingController _presencePenaltyController =
      TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();

  bool _isInitialized = false;

  bool _maxTokensExceeded = false;
  String? _validationMessage;

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
      _maxTokensController.text = settings.maxTokens.toString();
      _topPController.text = settings.topP.toString();
      _frequencyPenaltyController.text = settings.frequencyPenalty.toString();
      _presencePenaltyController.text = settings.presencePenalty.toString();
      _systemPromptController.text = settings.systemPrompt ?? '';
      _isInitialized = true;
    } else if (modelState.selectedModelObject != null) {
      final model = modelState.selectedModelObject!;
      final apiSettings = ModelSettings.fromApiModel(
        model.id,
        model.contextLength,
        model.contextLength,
      );

      _temperatureController.text = apiSettings.temperature.toString();
      _maxTokensController.text = apiSettings.maxTokens.toString();
      _topPController.text = apiSettings.topP.toString();
      _frequencyPenaltyController.text = apiSettings.frequencyPenalty
          .toString();
      _presencePenaltyController.text = apiSettings.presencePenalty.toString();
      _systemPromptController.text = apiSettings.systemPrompt ?? '';
      _isInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          settingsNotifier.updateActiveSettings(apiSettings);
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
    _maxTokensController.dispose();
    _topPController.dispose();
    _frequencyPenaltyController.dispose();
    _presencePenaltyController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  bool get isMobile {
    return MediaQuery.of(context).size.width < 600;
  }

  // Validate maxTokens against API limits
  void _validateMaxTokens(String value) {
    final settingsState = ref.read(modelSettingsProvider);
    final settings = settingsState.activeSettings;

    if (settings == null || value.isEmpty) {
      setState(() {
        _maxTokensExceeded = false;
        _validationMessage = null;
      });
      return;
    }

    final parsedValue = int.tryParse(value);
    if (parsedValue == null) {
      setState(() {
        _maxTokensExceeded = false;
        _validationMessage = null;
      });
      return;
    }

    // Check against API limits
    final apiLimit = settings.apiContextLength ?? settings.apiMaxTokens;
    if (apiLimit != null && parsedValue > apiLimit) {
      final localizations = AppLocalizations.of(context)!;
      setState(() {
        _maxTokensExceeded = true;
        _validationMessage = localizations.apiLimitExceeded(apiLimit);
      });

      // Show snackbar warning
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          SnackbarUtils.showWarningSnackBar(
            context: context,
            message: localizations.valueExceedsApiLimit(apiLimit),
            icon: Icons.warning_amber,
          );
        }
      });
    } else {
      setState(() {
        _maxTokensExceeded = false;
        _validationMessage = null;
      });
    }
  }

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
      // Get current settings to preserve API fields
      final current = settingsState.activeSettings!;

      // Handle maxTokens validation - cap at API limit if exceeded
      int maxTokens = int.tryParse(_maxTokensController.text) ?? 4096;
      final apiLimit = current.apiContextLength ?? current.apiMaxTokens;
      if (apiLimit != null && maxTokens > apiLimit) {
        maxTokens = apiLimit;
      }

      final updatedSettings = ModelSettings(
        modelId: current.modelId,
        temperature: double.tryParse(_temperatureController.text) ?? 1.0,
        maxTokens: maxTokens,
        topP: double.tryParse(_topPController.text) ?? 1.0,
        frequencyPenalty:
            double.tryParse(_frequencyPenaltyController.text) ?? 0.0,
        presencePenalty:
            double.tryParse(_presencePenaltyController.text) ?? 0.0,
        systemPrompt: _systemPromptController.text.isNotEmpty
            ? _systemPromptController.text
            : null,
        stream: true,
        maxContextLength: current.maxContextLength,
        reasoningEnabled: true,
        apiMaxTokens: current.apiMaxTokens,
        apiMaxTemperature: current.apiMaxTemperature,
        apiMinTemperature: current.apiMinTemperature,
        apiContextLength: current.apiContextLength,
      );

      settingsNotifier.updateActiveSettings(updatedSettings);

      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: localizations.settingsApplied,
        icon: Icons.check_circle,
        duration: const Duration(seconds: 2),
      );

      // Close the sheet
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
    final modelState = ref.read(modelProvider);
    final settingsNotifier = ref.read(modelSettingsProvider.notifier);
    final localizations = AppLocalizations.of(context)!;

    if (settingsState.activeSettings == null) return;

    // Get model info from theme provider to create proper defaults
    final model = modelState.selectedModelObject;
    ModelSettings defaultSettings;

    if (model != null) {
      // Use API model info to create appropriate defaults
      defaultSettings = ModelSettings.fromApiModel(
        model.id,
        model.contextLength,
        null, // Use default maxTokens
      );
    } else {
      // Fallback to generic defaults
      defaultSettings = ModelSettings.defaultForModel(
        settingsState.activeSettings!.modelId,
      );
    }

    // Update controllers
    _temperatureController.text = defaultSettings.temperature.toString();
    _maxTokensController.text = defaultSettings.maxTokens.toString();
    _topPController.text = defaultSettings.topP.toString();
    _frequencyPenaltyController.text = defaultSettings.frequencyPenalty
        .toString();
    _presencePenaltyController.text = defaultSettings.presencePenalty
        .toString();
    _systemPromptController.text = defaultSettings.systemPrompt ?? '';

    // Apply to provider
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
    String? apiValue,
    String? apiLimit,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(
                fontSize: ChatoraiFontSizes.md,
                color: isDark
                    ? ChatoraiColors.darkSecondaryTextColor
                    : ChatoraiColors.secondaryTextColor,
              ),
            ),
            if (apiValue != null || apiLimit != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: ChatoraiIconSizes.xs,
                    color: isDark
                        ? ChatoraiColors.darkSecondaryTextColor
                        : ChatoraiColors.secondaryTextColor,
                  ),
                  const SizedBox(width: ChatoraiSpacing.xs),
                  Expanded(
                    child: Text(
                      '${apiValue ?? ''}${apiLimit != null ? ' | Limit: $apiLimit' : ''}',
                      style: TextStyle(
                        fontSize: ChatoraiFontSizes.sm,
                        color: isDark
                            ? ChatoraiColors.darkSecondaryTextColor
                            : ChatoraiColors.secondaryTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
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
                color: _maxTokensExceeded && label.contains('Max Tokens')
                    ? ChatoraiColors.error
                    : (isDark
                          ? ChatoraiColors.darkInputBorder
                          : ChatoraiColors.inputBorder),
                width: _maxTokensExceeded && label.contains('Max Tokens')
                    ? ChatoraiBorderWidth.medium
                    : ChatoraiBorderWidth.thinBold,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              borderSide: BorderSide(
                color: _maxTokensExceeded && label.contains('Max Tokens')
                    ? ChatoraiColors.error
                    : ChatoraiColors.orange,
                width: ChatoraiBorderWidth.medium,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ChatoraiSpacing.md,
              vertical: ChatoraiSpacing.sm,
            ),
            suffixIcon: _maxTokensExceeded && label.contains('Max Tokens')
                ? const Icon(Icons.error_outline, color: ChatoraiColors.error)
                : null,
          ),
          style: TextStyle(
            fontSize: ChatoraiFontSizes.base,
            color: _maxTokensExceeded && label.contains('Max Tokens')
                ? ChatoraiColors.error
                : (isDark
                      ? ChatoraiColors.pureWhite
                      : ChatoraiColors.pureBlack),
          ),
          inputFormatters: [
            if (isDecimal)
              _DecimalTextInputFormatter(min: min, max: max)
            else
              _IntegerTextInputFormatter(min: min.toInt(), max: max.toInt()),
          ],
          onChanged: (value) {
            if (label.contains('Max Tokens')) {
              _validateMaxTokens(value);
            }
          },
        ),
        if (_validationMessage != null && label.contains('Max Tokens')) ...[
          const SizedBox(height: ChatoraiSpacing.xs),
          Text(
            _validationMessage!,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.sm,
              color: ChatoraiColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
              borderSide: BorderSide(
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

    // Get current model name
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
                  Icons.settings_input_component_outlined,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
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
                          ),
                          if (settingsState.activeSettings?.apiContextLength !=
                              null) ...[
                            const SizedBox(width: ChatoraiSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ChatoraiSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ChatoraiColors.orange.withAlpha(30),
                                borderRadius: BorderRadius.circular(
                                  ChatoraiBorderRadius.xs,
                                ),
                              ),
                              child: Text(
                                '${settingsState.activeSettings!.apiContextLength} tokens',
                                style: TextStyle(
                                  fontSize: ChatoraiFontSizes.xs,
                                  color: ChatoraiColors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                          min:
                              settingsState.activeSettings!.apiMinTemperature ??
                              0.0,
                          max:
                              settingsState.activeSettings!.apiMaxTemperature ??
                              2.0,
                          apiValue:
                              'Current: ${settingsState.activeSettings!.temperature}',
                          apiLimit:
                              settingsState.activeSettings!.apiMaxTemperature !=
                                  null
                              ? 'Max: ${settingsState.activeSettings!.apiMaxTemperature}'
                              : null,
                        ),

                        // Max Tokens
                        _buildParameterField(
                          label: localizations.maxTokens,
                          description: localizations.maxTokensDescription,
                          controller: _maxTokensController,
                          hintText:
                              '1 - ${(settingsState.activeSettings!.apiMaxTokens ?? settingsState.activeSettings!.apiContextLength ?? 8192).toDouble()}',
                          isDecimal: false,
                          min: 1,
                          max:
                              (settingsState.activeSettings!.apiMaxTokens ??
                                      settingsState
                                          .activeSettings!
                                          .apiContextLength ??
                                      8192)
                                  .toDouble(),
                          apiValue:
                              'Current: ${settingsState.activeSettings!.maxTokens}',
                          apiLimit:
                              settingsState.activeSettings!.apiMaxTokens != null
                              ? 'Max: ${settingsState.activeSettings!.apiMaxTokens}'
                              : (settingsState
                                            .activeSettings!
                                            .apiContextLength !=
                                        null
                                    ? 'Context: ${settingsState.activeSettings!.apiContextLength}'
                                    : null),
                        ),

                        // Top P
                        _buildParameterField(
                          label: localizations.topP,
                          description: localizations.topPDescription,
                          controller: _topPController,
                          hintText: '0.0 - 1.0',
                          isDecimal: true,
                          min: 0.0,
                          max: 1.0,
                          apiValue:
                              'Current: ${settingsState.activeSettings!.topP}',
                        ),

                        // Frequency Penalty
                        _buildParameterField(
                          label: localizations.frequencyPenalty,
                          description:
                              localizations.frequencyPenaltyDescription,
                          controller: _frequencyPenaltyController,
                          hintText: '-2.0 - 2.0',
                          isDecimal: true,
                          min: -2.0,
                          max: 2.0,
                          apiValue:
                              'Current: ${settingsState.activeSettings!.frequencyPenalty}',
                        ),

                        // Presence Penalty
                        _buildParameterField(
                          label: localizations.presencePenalty,
                          description: localizations.presencePenaltyDescription,
                          controller: _presencePenaltyController,
                          hintText: '-2.0 - 2.0',
                          isDecimal: true,
                          min: -2.0,
                          max: 2.0,
                          apiValue:
                              'Current: ${settingsState.activeSettings!.presencePenalty}',
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

// Custom formatter for decimal numbers
class _DecimalTextInputFormatter extends TextInputFormatter {
  final double min;
  final double max;

  _DecimalTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Allow only numbers and decimal point
    final RegExp regex = RegExp(r'^[0-9]*\.?[0-9]*$');
    if (!regex.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Parse and clamp value
    final double? value = double.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }

    if (value < min || value > max) {
      return oldValue;
    }

    return newValue;
  }
}

// Custom formatter for integer numbers
class _IntegerTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _IntegerTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Allow only numbers
    final RegExp regex = RegExp(r'^[0-9]*$');
    if (!regex.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Parse and clamp value
    final int? value = int.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }

    if (value < min || value > max) {
      return oldValue;
    }

    return newValue;
  }
}
