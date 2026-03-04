import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chatorai/providers/model_settings_provider.dart';
import 'package:chatorai/providers/model_provider.dart';
import 'package:chatorai/models/model_settings.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/utils/snackbar_utils.dart';

class ModelSettingsSheet extends StatefulWidget {
  const ModelSettingsSheet({super.key});

  @override
  State<ModelSettingsSheet> createState() => _ModelSettingsSheetState();
}

class _ModelSettingsSheetState extends State<ModelSettingsSheet> {
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _maxTokensController = TextEditingController();
  final TextEditingController _topPController = TextEditingController();
  final TextEditingController _frequencyPenaltyController =
      TextEditingController();
  final TextEditingController _presencePenaltyController =
      TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();

  bool _streamResponse = true;
  bool _isInitialized = false;

  // Validation state
  bool _maxTokensExceeded = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final settingsProvider = context.read<ModelSettingsProvider>();
    final modelProvider = context.read<ModelProvider>();

    // Set active model if not already set, passing context for API info
    if (settingsProvider.activeSettings == null &&
        modelProvider.selectedModelId.isNotEmpty) {
      settingsProvider.setActiveModel(modelProvider.selectedModelId, context);
    }

    // Initialize controllers with current settings
    if (settingsProvider.activeSettings != null) {
      final settings = settingsProvider.activeSettings!;

      _temperatureController.text = settings.temperature.toString();
      _maxTokensController.text = settings.maxTokens.toString();
      _topPController.text = settings.topP.toString();
      _frequencyPenaltyController.text = settings.frequencyPenalty.toString();
      _presencePenaltyController.text = settings.presencePenalty.toString();
      _systemPromptController.text = settings.systemPrompt ?? '';
      _streamResponse = settings.stream;
      _isInitialized = true;
    } else if (modelProvider.selectedModelObject != null) {
      // If no saved settings but we have model info, create settings from API
      final model = modelProvider.selectedModelObject!;
      final apiSettings = ModelSettings.fromApiModel(
        model.id,
        model.contextLength,
        model.contextLength, // Use context length as maxTokens
      );

      _temperatureController.text = apiSettings.temperature.toString();
      _maxTokensController.text = apiSettings.maxTokens.toString();
      _topPController.text = apiSettings.topP.toString();
      _frequencyPenaltyController.text = apiSettings.frequencyPenalty
          .toString();
      _presencePenaltyController.text = apiSettings.presencePenalty.toString();
      _systemPromptController.text = apiSettings.systemPrompt ?? '';
      _streamResponse = apiSettings.stream;
      _isInitialized = true;

      // Set these as active settings
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          settingsProvider.updateActiveSettings(apiSettings);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-initialize if settings change
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

  // Helper to check if device is mobile
  bool get isMobile {
    return MediaQuery.of(context).size.width < 600;
  }

  // Validate maxTokens against API limits
  void _validateMaxTokens(String value) {
    final settingsProvider = context.read<ModelSettingsProvider>();
    final settings = settingsProvider.activeSettings;

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
    final settingsProvider = context.read<ModelSettingsProvider>();
    final localizations = AppLocalizations.of(context)!;

    if (settingsProvider.activeSettings == null) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.noModelSelected,
        icon: Icons.error,
      );
      return;
    }

    try {
      // Get current settings to preserve API fields
      final current = settingsProvider.activeSettings!;

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
        stream: _streamResponse,
        maxContextLength: current.maxContextLength,
        reasoningEnabled:
            settingsProvider.activeSettings?.reasoningEnabled ?? true,
        apiMaxTokens: current.apiMaxTokens,
        apiMaxTemperature: current.apiMaxTemperature,
        apiMinTemperature: current.apiMinTemperature,
        apiContextLength: current.apiContextLength,
      );

      settingsProvider.updateActiveSettings(updatedSettings);

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
    final settingsProvider = context.read<ModelSettingsProvider>();
    final modelProvider = context.read<ModelProvider>();
    final localizations = AppLocalizations.of(context)!;

    if (settingsProvider.activeSettings == null) return;

    // Get model info from theme provider to create proper defaults
    final model = modelProvider.selectedModelObject;
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
        settingsProvider.activeSettings!.modelId,
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
    _streamResponse = defaultSettings.stream;

    // Apply to provider
    settingsProvider.updateActiveSettings(defaultSettings);

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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Show current value
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: UbuntuColors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                controller.text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: UbuntuColors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Description and API info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (apiValue != null || apiLimit != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${apiValue ?? ''}${apiLimit != null ? ' | Limit: $apiLimit' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: isDark
                ? UbuntuColors.darkInputFill
                : UbuntuColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? UbuntuColors.darkInputBorder
                    : UbuntuColors.inputBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _maxTokensExceeded && label.contains('Max Tokens')
                    ? Colors.red
                    : (isDark
                          ? UbuntuColors.darkInputBorder
                          : UbuntuColors.inputBorder),
                width: _maxTokensExceeded && label.contains('Max Tokens')
                    ? 2
                    : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _maxTokensExceeded && label.contains('Max Tokens')
                    ? Colors.red
                    : UbuntuColors.orange,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            suffixIcon: _maxTokensExceeded && label.contains('Max Tokens')
                ? const Icon(Icons.error_outline, color: Colors.red)
                : null,
          ),
          style: TextStyle(
            fontSize: 14,
            color: _maxTokensExceeded && label.contains('Max Tokens')
                ? Colors.red
                : (isDark ? Colors.white : Colors.black87),
          ),
          inputFormatters: [
            // Allow decimal numbers for temperature and topP
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
          const SizedBox(height: 4),
          Text(
            _validationMessage!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 16),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          localizations.systemPromptDescription,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _systemPromptController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'You are a helpful assistant...',
            filled: true,
            fillColor: isDark
                ? UbuntuColors.darkInputFill
                : UbuntuColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? UbuntuColors.darkInputBorder
                    : UbuntuColors.inputBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? UbuntuColors.darkInputBorder
                    : UbuntuColors.inputBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: UbuntuColors.orange, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildToggleSwitch({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
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
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
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
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final modelProvider = context.watch<ModelProvider>();
    final settingsProvider = context.watch<ModelSettingsProvider>();

    // Get current model name
    String modelName = localizations.noModelSelected;
    if (modelProvider.selectedModelObject != null) {
      modelName = modelProvider.selectedModelObject!.name;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? UbuntuColors.darkCard : UbuntuColors.lightCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? UbuntuColors.darkBorderColor
                      : UbuntuColors.lightBorderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings_input_component_outlined,
                  color: UbuntuColors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.modelSettings,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              modelName,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (settingsProvider
                                  .activeSettings
                                  ?.apiContextLength !=
                              null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: UbuntuColors.orange.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${settingsProvider.activeSettings!.apiContextLength} tokens',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: UbuntuColors.orange,
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
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: settingsProvider.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              UbuntuColors.orange,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading settings...',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : settingsProvider.activeSettings == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.settings_suggest,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.noModelSelected,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Model Parameters Section
                        Text(
                          localizations.modelParameters,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Temperature
                        _buildParameterField(
                          label: localizations.temperature,
                          description: localizations.temperatureDescription,
                          controller: _temperatureController,
                          hintText: '0.0 - 2.0',
                          isDecimal: true,
                          min:
                              settingsProvider
                                  .activeSettings!
                                  .apiMinTemperature ??
                              0.0,
                          max:
                              settingsProvider
                                  .activeSettings!
                                  .apiMaxTemperature ??
                              2.0,
                          apiValue:
                              'Current: ${settingsProvider.activeSettings!.temperature}',
                          apiLimit:
                              settingsProvider
                                      .activeSettings!
                                      .apiMaxTemperature !=
                                  null
                              ? 'Max: ${settingsProvider.activeSettings!.apiMaxTemperature}'
                              : null,
                        ),

                        // Max Tokens
                        _buildParameterField(
                          label: localizations.maxTokens,
                          description: localizations.maxTokensDescription,
                          controller: _maxTokensController,
                          hintText:
                              '1 - ${(settingsProvider.activeSettings!.apiMaxTokens ?? settingsProvider.activeSettings!.apiContextLength ?? 8192).toDouble()}',
                          isDecimal: false,
                          min: 1,
                          max:
                              (settingsProvider.activeSettings!.apiMaxTokens ??
                                      settingsProvider
                                          .activeSettings!
                                          .apiContextLength ??
                                      8192)
                                  .toDouble(),
                          apiValue:
                              'Current: ${settingsProvider.activeSettings!.maxTokens}',
                          apiLimit:
                              settingsProvider.activeSettings!.apiMaxTokens !=
                                  null
                              ? 'Max: ${settingsProvider.activeSettings!.apiMaxTokens}'
                              : (settingsProvider
                                            .activeSettings!
                                            .apiContextLength !=
                                        null
                                    ? 'Context: ${settingsProvider.activeSettings!.apiContextLength}'
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
                              'Current: ${settingsProvider.activeSettings!.topP}',
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
                              'Current: ${settingsProvider.activeSettings!.frequencyPenalty}',
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
                              'Current: ${settingsProvider.activeSettings!.presencePenalty}',
                        ),

                        // System Prompt
                        _buildSystemPromptField(),

                        // Stream Response Toggle
                        _buildToggleSwitch(
                          title: localizations.streamResponse,
                          description: localizations.streamResponseDescription,
                          value: _streamResponse,
                          onChanged: (value) {
                            setState(() {
                              _streamResponse = value;
                            });
                          },
                        ),

                        // Reasoning Toggle (new)
                        _buildToggleSwitch(
                          title: localizations.enableReasoning,
                          description: localizations.enableReasoningDescription,
                          value:
                              settingsProvider
                                  .activeSettings
                                  ?.reasoningEnabled ??
                              true,
                          onChanged: (value) {
                            setState(() {
                              // Update through provider
                              settingsProvider.updateActiveParameter(
                                reasoningEnabled: value,
                              );
                            });
                          },
                        ),

                        const SizedBox(height: 24),

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
                                            ? Colors.white
                                            : Colors.black87,
                                        side: BorderSide(
                                          color: isDark
                                              ? Colors.grey[600]!
                                              : Colors.grey[400]!,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _applySettings,
                                      icon: const Icon(Icons.check),
                                      label: Text(localizations.applySettings),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: UbuntuColors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
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
                                            ? Colors.white
                                            : Colors.black87,
                                        side: BorderSide(
                                          color: isDark
                                              ? Colors.grey[600]!
                                              : Colors.grey[400]!,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _applySettings,
                                      icon: const Icon(Icons.check),
                                      label: Text(localizations.applySettings),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: UbuntuColors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
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
