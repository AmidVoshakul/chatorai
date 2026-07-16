import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';
import 'package:chatorai/core/llm/providers/built_in_providers.dart';
import 'package:chatorai/features/models/widgets/provider_icon.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

/// A dialog that lets the user pick an AI provider, enter an API key,
/// and optionally override the base URL.
///
/// Supports all built-in providers plus a "Custom" entry at the bottom
/// of the dropdown for user-defined providers. When a built-in provider
/// is selected, the base URL auto-fills from the provider config.
class AddProviderDialog extends StatefulWidget {
  final String? initialProviderId;
  final String? initialBaseUrl;
  final String? initialApiKey;
  final void Function(
    String providerId,
    String baseUrl,
    String apiKey,
    ProviderConfig? customConfig,
  )
  onSave;

  const AddProviderDialog({
    super.key,
    this.initialProviderId,
    this.initialBaseUrl,
    this.initialApiKey,
    required this.onSave,
  });

  @override
  State<AddProviderDialog> createState() => _AddProviderDialogState();
}

class _AddProviderDialogState extends State<AddProviderDialog> {
  final List<_ProviderOption> _providers = [];
  _ProviderOption? _selectedOption;
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _customNameController;

  bool get _isCustom => _selectedOption?.id == '__custom__';
  bool get _isEditing => widget.initialProviderId != null;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.initialApiKey ?? '');
    _baseUrlController = TextEditingController(
      text: widget.initialBaseUrl ?? '',
    );
    _customNameController = TextEditingController();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  void _onProviderChanged(_ProviderOption? option) {
    if (option == null) return;
    setState(() {
      _selectedOption = option;
      if (option.id == '__custom__') {
        _customNameController.clear();
      } else {
        _baseUrlController.text = option.baseUrl;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    if (_providers.isEmpty) {
      _providers.addAll(
        _allBuiltInProviders().map(
          (p) => _ProviderOption(id: p.id, name: p.name, baseUrl: p.baseUrl),
        ),
      );
      _providers.add(
        _ProviderOption(
          id: '__custom__',
          name: localizations.addProviderCustomName,
          baseUrl: '',
        ),
      );
    }

    if (_selectedOption == null && _providers.isNotEmpty) {
      final initialId = widget.initialProviderId;
      if (initialId != null) {
        _selectedOption = _providers
            .where((p) => p.id == initialId)
            .firstOrNull;
      }
      _selectedOption ??= _providers.first;
      if (_selectedOption!.id != '__custom__' && !_isEditing) {
        _baseUrlController.text = _selectedOption!.baseUrl;
      }
    }

    final canSave =
        _selectedOption != null &&
        (!_isCustom || _customNameController.text.trim().isNotEmpty);

    final screenSize = MediaQuery.of(context).size;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width < 600 ? 16 : 40,
        vertical: 24,
      ),
      constraints: BoxConstraints(
        maxWidth: screenSize.width < 600 ? screenSize.width - 32 : 560,
      ),
      title: Text(
        _isEditing
            ? localizations.addProviderTitleEdit
            : localizations.addProviderTitleAdd,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedOption?.id,
              decoration: InputDecoration(
                labelText: localizations.addProviderLabelProvider,
                border: const OutlineInputBorder(),
              ),
              items: _providers.map((p) {
                return DropdownMenuItem(
                  value: p.id,
                  child: p.id == '__custom__'
                      ? Text(p.name)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ProviderIcon(providerId: p.id, size: 22),
                            const SizedBox(width: 10),
                            Text(p.name),
                          ],
                        ),
                );
              }).toList(),
              selectedItemBuilder: (context) {
                return _providers.map((p) {
                  return Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: p.id == '__custom__' ? Text(p.name) : Text(p.name),
                  );
                }).toList();
              },
              onChanged: (id) {
                if (id != null) {
                  _onProviderChanged(_providers.firstWhere((p) => p.id == id));
                }
              },
            ),
            const SizedBox(height: ChatoraiSpacing.md),

            // Custom provider name field
            if (_isCustom) ...[
              TextField(
                controller: _customNameController,
                decoration: InputDecoration(
                  labelText: localizations.addProviderFieldProviderName,
                  hintText: localizations.addProviderHintProviderName,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 1,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: ChatoraiSpacing.md),
            ],

            // API key (show for providers with apiKey auth)
            if (_selectedOption != null &&
                _selectedOption!.id != '__custom__' &&
                _builtInProviderAuthType(_selectedOption!.id) !=
                    AuthType.none) ...[
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: localizations.addProviderLabelApiKey,
                  hintText: localizations.addProviderHintApiKey,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                maxLines: 1,
              ),
              const SizedBox(height: ChatoraiSpacing.md),
            ],
            if (_isCustom) ...[
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: localizations.addProviderLabelApiKey,
                  hintText: localizations.addProviderHintCustomApiKey,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                maxLines: 1,
              ),
              const SizedBox(height: ChatoraiSpacing.md),
            ],

            // Base URL
            TextField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                labelText: localizations.addProviderLabelBaseUrl,
                hintText: localizations.addProviderHintBaseUrl,
                border: const OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            localizations.cancel,
            style: TextStyle(
              color: isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
            ),
          ),
        ),
        FilledButton(
          onPressed: canSave
              ? () {
                  final apiKey = _apiKeyController.text.trim();
                  final baseUrl = _baseUrlController.text.trim();
                  String providerId;

                  if (_isCustom) {
                    final rawName = _customNameController.text.trim();
                    providerId = rawName
                        .toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
                        .replaceAll(RegExp(r'_+'), '_')
                        .replaceAll(RegExp(r'^_|_$'), '');
                    if (providerId.isEmpty) {
                      providerId =
                          'custom_${DateTime.now().millisecondsSinceEpoch}';
                    }

                    final customConfig = ProviderConfig.basic(
                      id: providerId,
                      name: rawName,
                      baseUrl: baseUrl.isNotEmpty
                          ? baseUrl
                          : 'http://localhost:11434',
                      auth: apiKey.isNotEmpty
                          ? AuthConfig.apiKey(apiKey: apiKey)
                          : const AuthConfig.none(),
                    );
                    widget.onSave(
                      providerId,
                      customConfig.baseUrl,
                      apiKey,
                      customConfig,
                    );

                    return;
                  }

                  if (_selectedOption != null &&
                      _selectedOption!.id != '__custom__' &&
                      _builtInProviderAuthType(_selectedOption!.id) !=
                          AuthType.none &&
                      apiKey.isEmpty) {
                    SnackbarUtils.showErrorSnackBar(
                      context: context,
                      message: localizations.addProviderErrorApiKeyRequired,
                      duration: const Duration(seconds: 2),
                    );
                    return;
                  }
                  widget.onSave(
                    _selectedOption?.id ?? '',
                    baseUrl,
                    apiKey,
                    null,
                  );
                }
              : null,
          child: Text(localizations.addProviderActionSave),
        ),
      ],
    );
  }

  /// Lookup auth type for a built-in provider by ID.
  AuthType _builtInProviderAuthType(String id) {
    for (final p in _allBuiltInProviders()) {
      if (p.id == id) return p.auth.type;
    }
    return AuthType.apiKey;
  }

  /// Returns a simple list of provider configs for the dialog's dropdown.
  List<ProviderConfig> _allBuiltInProviders() => builtInProviders();
}

class _ProviderOption {
  final String id;
  final String name;
  final String baseUrl;

  const _ProviderOption({
    required this.id,
    required this.name,
    required this.baseUrl,
  });
}
