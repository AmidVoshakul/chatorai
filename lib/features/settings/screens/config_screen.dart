import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:chatorai/shared/workspace/workspace_runtime.dart';
import 'package:path/path.dart' as p;

/// Read-only viewer for `chatorai.json`, split into a Global tab
/// (`<xdg-config>/chatorai.json`) and, on desktop, a Project tab
/// (`<cwd>/.chatorai/chatorai.json`). Project settings override global ones.
class ConfigScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const ConfigScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScopeData {
  final String path;
  final bool exists;
  final String? content;

  const _ConfigScopeData({
    required this.path,
    required this.exists,
    this.content,
  });
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  _ConfigScopeData? _global;
  _ConfigScopeData? _project;
  bool _loading = true;

  bool get _supportsProjectScope =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await XdgPaths.init();
    final configDir = await XdgPaths.configHomeAsync;
    final global = await _read(p.join(configDir, 'chatorai.json'));

    _ConfigScopeData? project;
    if (_supportsProjectScope) {
      final projectPath = p.join(
        workspaceRuntimeCurrent.path,
        '.chatorai',
        'chatorai.json',
      );
      project = await _read(projectPath);
    }

    if (mounted) {
      setState(() {
        _global = global;
        _project = project;
        _loading = false;
      });
    }
  }

  Future<_ConfigScopeData> _read(String path) async {
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
    return _ConfigScopeData(path: path, exists: exists, content: content);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content;
    TabBar? tabBar;

    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (!_supportsProjectScope) {
      content = _ScopeConfigView(data: _global, isDark: isDark);
    } else {
      tabBar = unifiedTabBar(
        isDark: isDark,
        tabs: [
          Tab(text: l10n.configScopeGlobal),
          Tab(text: l10n.configScopeProject),
        ],
      );
      content = DefaultTabController(
        length: 2,
        child: TabBarView(
          children: [
            _ScopeConfigView(data: _global, isDark: isDark),
            _ScopeConfigView(
              data: _project,
              isDark: isDark,
              footnote: l10n.configProjectOverrides,
            ),
          ],
        ),
      );
    }

    if (widget.embedded) {
      if (tabBar == null) return content;
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _tabBarContainer(tabBar: tabBar, isDark: isDark),
            Expanded(child: content),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: _supportsProjectScope ? 2 : 1,
      child: Scaffold(
        appBar: _appBar(context, l10n, isDark, bottom: tabBar),
        body: content,
      ),
    );
  }

  Widget _tabBarContainer({required TabBar tabBar, required bool isDark}) {
    return unifiedTabContainer(tabBar: tabBar, isDark: isDark);
  }

  PreferredSizeWidget _appBar(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark, {
    required PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      title: Text(l10n.configuration),
      centerTitle: true,
      backgroundColor: Theme.of(context).canvasColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: bottom == null
          ? null
          : PreferredSize(
              preferredSize: bottom.preferredSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? ChatoraiColors.darkInputBorder
                          : ChatoraiColors.inputBorder,
                    ),
                  ),
                ),
                child: bottom,
              ),
            ),
    );
  }
}

class _ScopeConfigView extends StatelessWidget {
  final _ConfigScopeData? data;
  final bool isDark;
  final String? footnote;

  const _ScopeConfigView({
    required this.data,
    required this.isDark,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = isDark
        ? ChatoraiColors.pureWhite
        : ChatoraiColors.pureBlack;
    final secondaryTextColor = isDark
        ? ChatoraiColors.darkSecondaryTextColor
        : ChatoraiColors.secondaryTextColor;

    final scope = data;
    if (scope == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.folder_open,
            l10n.configPathLabel,
            scope.path,
            textColor,
            secondaryTextColor,
          ),
          const SizedBox(height: ChatoraiSpacing.md),
          _buildInfoRow(
            Icons.check_circle,
            l10n.configStatusLabel,
            scope.exists ? l10n.configExists : l10n.configNotFound,
            textColor,
            secondaryTextColor,
          ),
          const SizedBox(height: ChatoraiSpacing.lg),
          Divider(
            color: isDark
                ? ChatoraiColors.darkInputBorder
                : ChatoraiColors.inputBorder,
          ),
          const SizedBox(height: ChatoraiSpacing.lg),
          Text(
            scope.exists ? l10n.configContentsTitle : l10n.configNotFound,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.lg,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: ChatoraiSpacing.md),
          if (scope.content != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ChatoraiSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? ChatoraiColors.darkSurface
                    : ChatoraiColors.lightSurface,
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
              ),
              child: SelectableText(
                scope.content!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ChatoraiFontSizes.sm,
                  color: textColor,
                ),
              ),
            ),
          if (!scope.exists)
            Padding(
              padding: const EdgeInsets.only(top: ChatoraiSpacing.lg),
              child: Text(
                l10n.configWillBeCreated,
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
          if (footnote != null)
            Padding(
              padding: const EdgeInsets.only(top: ChatoraiSpacing.lg),
              child: Text(
                footnote!,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.caption,
                  color: secondaryTextColor,
                ),
              ),
            ),
        ],
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
