import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter/material.dart';

/// A dialog that fetches available models from a provider and lets the
/// user select which ones to enable. Uses [ProviderCatalogService] as
/// the single source of truth — never calls the API directly.
class ModelSelectionDialog extends StatefulWidget {
  final String providerId;
  final String baseUrl;
  final String? apiKey;
  final List<String> initialSelectedIds;
  final void Function(List<String> selectedIds) onSave;
  final ProviderCatalogService? catalog;

  const ModelSelectionDialog({
    super.key,
    required this.providerId,
    required this.baseUrl,
    this.apiKey,
    required this.initialSelectedIds,
    required this.onSave,
    this.catalog,
  });

  @override
  State<ModelSelectionDialog> createState() => _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends State<ModelSelectionDialog> {
  List<ModelConfig> _models = [];
  Set<String> _selectedIds = {};
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelectedIds.toSet();
    _fetchModels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchModels({bool forceRefresh = false}) async {
    if (widget.catalog == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wasCached =
          widget.catalog!.getProvider(widget.providerId) != null &&
          widget.catalog!.getProvider(widget.providerId)!.models.isNotEmpty &&
          !forceRefresh;

      final configs = await widget.catalog!.discoverModels(
        widget.providerId,
        forceRefresh: forceRefresh,
      );
      LogTags.settings.logInfo(
        '[ModelSelection] _fetchModels: providerId=${widget.providerId}, '
        'found=${configs.length} models',
      );
      LogTags.settings.logInfo(
        '[ModelSelection] model IDs: [${configs.take(10).map((m) => '${m.modelName}=>${m.id}').join(', ')}]',
      );
      setState(() {
        _models = configs;
        if (wasCached && _selectedIds.isNotEmpty) {
          final valid = _selectedIds
              .where((id) => widget.catalog!.getModel(id) != null)
              .toSet();
          _selectedIds = valid.isNotEmpty
              ? valid
              : widget.initialSelectedIds.toSet();
        } else {
          _selectedIds = widget.initialSelectedIds.toSet();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load models: $e';
      });
    }
  }

  List<ModelConfig> get _filteredModels {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _models;

    return _models.where((m) {
      return m.modelName.toLowerCase().contains(query) ||
          m.displayName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? ChatoraiColors.pureWhite
        : ChatoraiColors.pureBlack;
    final secondaryTextColor = isDark
        ? ChatoraiColors.darkSecondaryTextColor
        : ChatoraiColors.secondaryTextColor;

    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width < 520 ? screenSize.width - 48 : 450.0;
    final dialogHeight = screenSize.height < 560
        ? screenSize.height - 120
        : 500.0;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width < 600 ? 16 : 40,
        vertical: 24,
      ),
      constraints: BoxConstraints(
        maxWidth: screenSize.width < 600 ? screenSize.width - 32 : 560,
      ),
      title: const Text('Select Models'),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search models...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: ChatoraiSpacing.sm),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _selectedIds.clear()),
                  child: const Text('Deselect All'),
                ),
                TextButton(
                  onPressed: () => setState(
                    () => _selectedIds = _models.map((m) => m.id).toSet(),
                  ),
                  child: const Text('Select All'),
                ),
              ],
            ),
            const SizedBox(height: ChatoraiSpacing.sm),
            Expanded(
              child: _buildContent(isDark, textColor, secondaryTextColor),
            ),
            const SizedBox(height: ChatoraiSpacing.sm),
            Text(
              '${_selectedIds.length} of ${_models.length} selected',
              style: TextStyle(color: secondaryTextColor, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
        ),
        FilledButton(
          onPressed: () async {
            if (widget.catalog != null) {
              final models = _models.map((m) {
                return m.copyWith(
                  id: m.id,
                  enabled: _selectedIds.contains(m.id),
                );
              }).toList();
              await widget.catalog!.updateProviderModels(
                widget.providerId,
                models,
                overwriteEnabled: true,
              );
            }

            final selected = _selectedIds.toList();
            LogTags.settings.logInfo(
              '[ModelSelection] Save button pressed: providerId=${widget.providerId}, '
              'selected=${_selectedIds.length}/${_models.length}, '
              'prefixed=[${selected.join(', ')}]',
            );
            widget.onSave(selected);
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

  Widget _buildContent(bool isDark, Color textColor, Color secondaryTextColor) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ChatoraiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: ChatoraiSpacing.md),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryTextColor),
              ),
              const SizedBox(height: ChatoraiSpacing.md),
              FilledButton.tonalIcon(
                onPressed: () => _fetchModels(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredModels;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.trim().isEmpty
              ? 'No models available'
              : 'No models match your search',
          style: TextStyle(color: secondaryTextColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final model = filtered[index];
        final isSelected = _selectedIds.contains(model.id);
        return CheckboxListTile(
          title: Text(
            model.displayName.isNotEmpty ? model.displayName : model.modelName,
            style: TextStyle(
              color: textColor,
              fontSize: ChatoraiFontSizes.base,
            ),
          ),
          subtitle: Text(
            model.modelName,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: ChatoraiFontSizes.caption,
            ),
          ),
          value: isSelected,
          dense: true,
          activeColor: ChatoraiColors.orange,
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                _selectedIds.add(model.id);
              } else {
                _selectedIds.remove(model.id);
              }
            });
          },
        );
      },
    );
  }
}
