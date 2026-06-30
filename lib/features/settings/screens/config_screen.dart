import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:path/path.dart' as p;

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  String? _configPath;
  bool? _exists;
  String? _content;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await XdgPaths.init();
    final configDir = await XdgPaths.configHomeAsync;
    final path = p.join(configDir, 'chatorai.json');
    final file = File(path);
    final exists = await file.exists();

    String? content;
    if (exists) {
      try {
        content = await file.readAsString();
      } catch (e) {
        content = 'Error reading: $e';
      }
    }

    if (mounted) {
      setState(() {
        _configPath = path;
        _exists = exists;
        _content = content;
        _loading = false;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? ChatoraiColors.pureWhite
        : ChatoraiColors.pureBlack;
    final secondaryTextColor = isDark
        ? ChatoraiColors.darkSecondaryTextColor
        : ChatoraiColors.secondaryTextColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.configuration),
        centerTitle: true,
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(ChatoraiSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.folder_open,
                    'Path',
                    _configPath ?? 'Unknown',
                    textColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: ChatoraiSpacing.md),
                  _buildInfoRow(
                    Icons.check_circle,
                    'Status',
                    _exists == true ? 'Exists' : 'Not found',
                    textColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: ChatoraiSpacing.lg),
                  const Divider(),
                  const SizedBox(height: ChatoraiSpacing.lg),
                  Text(
                    _exists == true ? 'File contents' : 'No config file found',
                    style: TextStyle(
                      fontSize: ChatoraiFontSizes.lg,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: ChatoraiSpacing.md),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: ChatoraiColors.error),
                    ),
                  if (_content != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(ChatoraiSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? ChatoraiColors.darkSurface
                            : ChatoraiColors.lightSurface,
                        borderRadius: BorderRadius.circular(
                          ChatoraiBorderRadius.md,
                        ),
                      ),
                      child: SelectableText(
                        _content!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: ChatoraiFontSizes.sm,
                          color: textColor,
                        ),
                      ),
                    ),
                  if (_exists == false)
                    Padding(
                      padding: const EdgeInsets.only(top: ChatoraiSpacing.lg),
                      child: Text(
                        'The config file will be created automatically on next restart.',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: ChatoraiIconSizes.md, color: secondaryTextColor),
        const SizedBox(width: ChatoraiSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.sm,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.md,
                  color: textColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
