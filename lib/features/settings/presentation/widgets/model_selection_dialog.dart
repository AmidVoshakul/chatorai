import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

/// Minimal model info returned from provider /models endpoint.
class _ProviderModel {
  final String id;
  final String name;
  _ProviderModel({required this.id, required this.name});

  factory _ProviderModel.fromJson(Map<String, dynamic> json) {
    return _ProviderModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['id'] as String? ?? '',
    );
  }
}

/// A dialog that fetches available models from a provider API and lets the
/// user select which ones to enable.
class ModelSelectionDialog extends StatefulWidget {
  final String providerId;
  final String baseUrl;
  final String? apiKey;
  final List<String> initialSelectedIds;
  final void Function(List<String> selectedIds) onSave;

  const ModelSelectionDialog({
    super.key,
    required this.providerId,
    required this.baseUrl,
    this.apiKey,
    required this.initialSelectedIds,
    required this.onSave,
  });

  @override
  State<ModelSelectionDialog> createState() => _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends State<ModelSelectionDialog> {
  List<_ProviderModel> _models = [];
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

  Future<void> _fetchModels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = <String, dynamic>{'Content-Type': 'application/json'};
      if (widget.apiKey != null && widget.apiKey!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${widget.apiKey}';
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: widget.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: headers,
        ),
      );

      final response = await dio.get('/models');
      final data = response.data;

      List<_ProviderModel> models;
      if (data is Map && data.containsKey('data')) {
        final modelsData = data['data'] is List
            ? data['data'] as List
            : <dynamic>[];
        models = modelsData
            .map((m) => _ProviderModel.fromJson(m as Map<String, dynamic>))
            .toList();
      } else if (data is List) {
        models = data
            .map((m) => _ProviderModel.fromJson(m as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Unexpected API response format');
      }

      setState(() {
        _models = models;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load models: $e';
      });
    }
  }

  List<_ProviderModel> get _filteredModels {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _models;

    return _models.where((m) {
      return m.id.toLowerCase().contains(query) ||
          m.name.toLowerCase().contains(query);
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

    return AlertDialog(
      title: const Text('Select Models'),
      content: SizedBox(
        width: 450,
        height: 500,
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search models...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: ChatoraiSpacing.md),

            // Content area
            Expanded(
              child: _buildContent(isDark, textColor, secondaryTextColor),
            ),

            const SizedBox(height: ChatoraiSpacing.md),

            // Count chip
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
          onPressed: () {
            widget.onSave(_selectedIds.toList());
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
                onPressed: _fetchModels,
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
            model.name.isNotEmpty ? model.name : model.id,
            style: TextStyle(
              color: textColor,
              fontSize: ChatoraiFontSizes.base,
            ),
          ),
          subtitle: Text(
            model.id,
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
