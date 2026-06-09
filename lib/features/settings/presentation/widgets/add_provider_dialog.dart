import 'package:flutter/material.dart';
import 'package:chatorai/features/chat/data/models/ai_provider.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

/// A dialog that lets the user pick an AI provider, enter an API key,
/// and optionally override the base URL.
class AddProviderDialog extends StatefulWidget {
  final AiProvider? initialProvider;
  final String? initialBaseUrl;
  final String? initialApiKey;
  final void Function(AiProvider provider, String baseUrl, String apiKey)
  onSave;

  const AddProviderDialog({
    super.key,
    this.initialProvider,
    this.initialBaseUrl,
    this.initialApiKey,
    required this.onSave,
  });

  @override
  State<AddProviderDialog> createState() => _AddProviderDialogState();
}

class _AddProviderDialogState extends State<AddProviderDialog> {
  late AiProvider _selectedProvider;
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;

  @override
  void initState() {
    super.initState();
    // If editing an existing provider, pre-fill; otherwise default to first.
    _selectedProvider = widget.initialProvider ?? AiProviders.all.first;
    _apiKeyController = TextEditingController(text: widget.initialApiKey ?? '');
    _baseUrlController = TextEditingController(
      text: widget.initialBaseUrl ?? _selectedProvider.baseUrl,
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  void _onProviderChanged(AiProvider? provider) {
    if (provider == null) return;
    setState(() {
      _selectedProvider = provider;
      // Auto-fill base URL if it hasn't been manually changed, or if editing
      // an existing provider and the user picks a different provider.
      _baseUrlController.text = provider.baseUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        widget.initialProvider != null ? 'Edit Provider' : 'Add Provider',
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider dropdown
              DropdownButtonFormField<AiProvider>(
                initialValue: _selectedProvider,
                decoration: const InputDecoration(
                  labelText: 'Provider',
                  border: OutlineInputBorder(),
                ),
                items: AiProviders.all.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p.name));
                }).toList(),
                onChanged: _onProviderChanged,
              ),
              const SizedBox(height: ChatoraiSpacing.md),

              // API key (only if provider requires it)
              if (_selectedProvider.requiresApiKey) ...[
                TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    hintText: 'Enter your API key',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  maxLines: 1,
                ),
                const SizedBox(height: ChatoraiSpacing.md),
              ],

              // Base URL
              TextField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.example.com/v1',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            final apiKey = _apiKeyController.text.trim();
            final baseUrl = _baseUrlController.text.trim();

            // If provider requires API key, validate it's not empty.
            if (_selectedProvider.requiresApiKey && apiKey.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API key is required')),
              );
              return;
            }

            widget.onSave(_selectedProvider, baseUrl, apiKey);
          },
          style: FilledButton.styleFrom(
            backgroundColor: ChatoraiColors.orange,
            foregroundColor: ChatoraiColors.pureWhite,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
