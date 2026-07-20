import 'dart:convert';

import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/core/mcp/mcp_marketplace_catalog.dart';
import 'package:chatorai/features/settings/providers/mcp_management_provider.dart';
import 'package:chatorai/features/settings/screens/mcp_add_server_helpers.dart';
import 'package:chatorai/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/features/models/widgets/mcp_server_icon.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';

class McpServersScreen extends ConsumerStatefulWidget {
  const McpServersScreen({super.key});

  @override
  ConsumerState<McpServersScreen> createState() => _McpServersScreenState();
}

class _McpServersScreenState extends ConsumerState<McpServersScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _commandController = TextEditingController();
  final _urlController = TextEditingController();
  final _envController = TextEditingController();
  final _tokenController = TextEditingController();
  final _rawController = TextEditingController();
  final _searchController = TextEditingController();
  var _isRemote = false;
  AuthType _authType = AuthType.bearer;
  var _isRefreshing = false;

  late final TabController _tabController;
  late final TabController _screenTabController;
  static const int _tabForm = 0;
  static const int _tabRaw = 1;

  McpCategory? _activeCategory;
  String _query = '';
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _screenTabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      if (mounted) setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _urlController.dispose();
    _envController.dispose();
    _tokenController.dispose();
    _rawController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _screenTabController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required String helper,
    required bool isDark,
  }) {
    final helperColor = isDark
        ? ChatoraiColors.darkSecondaryTextColor.withAlpha(140)
        : ChatoraiColors.secondaryTextColor.withAlpha(140);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintMaxLines: 12,
      helperText: helper,
      helperStyle: TextStyle(fontSize: 11, color: helperColor),
      helperMaxLines: 2,
      contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 2),
    );
  }

  Future<void> _showAddDialog() async {
    _nameController.clear();
    _commandController.clear();
    _urlController.clear();
    _envController.clear();
    _tokenController.clear();
    _rawController.clear();
    _isRemote = false;
    _authType = AuthType.bearer;
    _tabController.index = _tabForm;

    Map<String, dynamic>? result;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final screenSize = MediaQuery.of(dialogContext).size;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: screenSize.width < 600 ? 16 : 40,
            ),
            title: Text(l10n.mcpAddServerTitle),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenSize.width < 600 ? screenSize.width - 32 : 560,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_tabController.index == _tabForm) ...[
                      TextField(
                        controller: _nameController,
                        decoration: _fieldDecoration(
                          label: l10n.mcpNameLabel,
                          hint: l10n.mcpNameHint,
                          helper: l10n.mcpNameHelper,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? ChatoraiColors.darkInputBorder
                                : ChatoraiColors.inputBorder,
                          ),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: TabBar(
                          controller: _tabController,
                          onTap: (_) => setLocal(() {}),
                          tabs: [
                            Tab(text: l10n.mcpFormTab),
                            Tab(text: l10n.mcpRawTab),
                          ],
                          labelColor: isDark
                              ? ChatoraiColors.pureWhite
                              : ChatoraiColors.pureBlack,
                          unselectedLabelColor: isDark
                              ? ChatoraiColors.darkSecondaryTextColor
                              : ChatoraiColors.secondaryTextColor,
                          indicatorColor: ChatoraiColors.orange,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final isRaw = _tabController.index == _tabRaw;
                        if (isRaw) {
                          return TextField(
                            controller: _rawController,
                            maxLines: 10,
                            minLines: 8,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                            decoration: _fieldDecoration(
                              label: l10n.mcpRawLabel,
                              hint: mcpRawExample,
                              helper: l10n.mcpRawHelper,
                              isDark: isDark,
                            ),
                          );
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TypeSegment(
                              isRemote: _isRemote,
                              onChanged: (v) => setLocal(() => _isRemote = v),
                            ),
                            const SizedBox(height: 8),
                            if (_isRemote)
                              TextField(
                                controller: _urlController,
                                decoration: _fieldDecoration(
                                  label: l10n.mcpUrlLabel,
                                  hint: l10n.mcpUrlHint,
                                  helper: l10n.mcpUrlHelper,
                                  isDark: isDark,
                                ),
                              )
                            else
                              TextField(
                                controller: _commandController,
                                decoration: _fieldDecoration(
                                  label: l10n.mcpCommandLabel,
                                  hint: l10n.mcpCommandHint,
                                  helper: l10n.mcpCommandHelper,
                                  isDark: isDark,
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (_isRemote) ...[
                              TextField(
                                controller: _tokenController,
                                decoration: _fieldDecoration(
                                  label: l10n.mcpTokenLabel,
                                  hint: l10n.mcpTokenHint,
                                  helper: l10n.mcpTokenHelper,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<AuthType>(
                                      initialValue: _authType,
                                      decoration: _fieldDecoration(
                                        label: l10n.mcpAuthTypeLabel,
                                        hint: '',
                                        helper: l10n.mcpAuthTypeHelper,
                                        isDark: isDark,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: AuthType.bearer,
                                          child: Text('Bearer'),
                                        ),
                                        DropdownMenuItem(
                                          value: AuthType.apiKey,
                                          child: Text('ApiKey'),
                                        ),
                                        DropdownMenuItem(
                                          value: AuthType.plain,
                                          child: Text('Token'),
                                        ),
                                      ],
                                      onChanged: (v) =>
                                          setLocal(() => _authType = v!),
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              TextField(
                                controller: _envController,
                                maxLines: 4,
                                minLines: 1,
                                keyboardType: TextInputType.multiline,
                                decoration: _fieldDecoration(
                                  label: l10n.mcpEnvLabel,
                                  hint: l10n.mcpEnvHint,
                                  helper: l10n.mcpEnvHelper,
                                  isDark: isDark,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.mcpCancelAction),
              ),
              FilledButton(
                onPressed: () {
                  final isRaw = _tabController.index == _tabRaw;
                  final name = _nameController.text.trim();
                  if (!isRaw && name.isEmpty) {
                    SnackbarUtils.showErrorSnackBar(
                      context: ctx,
                      message: l10n.mcpNameHelper,
                    );
                    return;
                  }

                  String resolvedName = name;
                  McpServerConfig? config;
                  try {
                    if (_tabController.index == _tabRaw) {
                      final (rawName, parsed) = parseRawServerJson(
                        _rawController.text,
                      );
                      resolvedName = rawName;
                      config = parsed;
                    } else if (_isRemote) {
                      final url = _urlController.text.trim();
                      if (url.isEmpty) return;
                      config = McpServerConfig.remote(
                        url: url,
                        headers: buildAuthHeaders(
                          _tokenController.text,
                          _authType,
                        ),
                      );
                    } else {
                      final raw = _commandController.text.trim();
                      if (raw.isEmpty) return;
                      final parts = raw.split(RegExp(r'\s+'));
                      config = McpServerConfig.local(
                        command: parts.first,
                        args: parts.skip(1).toList(),
                        environment: parseEnvJson(_envController.text),
                      );
                    }
                  } on McpDialogParseError catch (e) {
                    final field = e.message.contains('environment')
                        ? l10n.mcpEnvLabel
                        : e.message.contains('token')
                        ? l10n.mcpTokenLabel
                        : l10n.mcpRawLabel;
                    SnackbarUtils.showErrorSnackBar(
                      context: ctx,
                      message: l10n.mcpParseError(field, e.message),
                    );
                    return;
                  }

                  result = {'name': resolvedName, 'config': config};
                  Navigator.pop(ctx);
                },
                child: Text(l10n.mcpAddAction),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      await ref
          .read(mcpManagementProvider.notifier)
          .addServer(
            result!['name'] as String,
            result!['config'] as McpServerConfig,
          );
    }
  }

  /// Opens the edit dialog pre-filled with [config] for the server named [name].
  /// Persists changes via [McpManagementNotifier.updateServer], which keeps the
  /// server name and all other fields intact while applying edits (e.g. a new
  /// auth token for an auth-gated remote server).
  Future<void> _showEditDialog(String name, McpServerConfig config) async {
    _nameController.text = name;
    _commandController.text = config.isLocal
        ? '${config.command}${config.args.isNotEmpty ? ' ${config.args.join(' ')}' : ''}'
        : '';
    _urlController.text = config.url ?? '';
    _envController.text = config.isLocal
        ? const JsonEncoder()
              .convert(config.environment)
              .replaceAll('{"', '{\n  "')
              .replaceAll('": "', '": "')
              .replaceAll('", "', '",\n  "')
              .replaceAll('"}', '"\n}')
        : '';
    _isRemote = config.isRemote;

    // Recover the editable token + auth type from the stored headers.
    final headers = config.headers ?? const {};
    final tokenEntry = headers.entries.firstWhere(
      (e) => e.key == 'Authorization' || e.key == 'X-Api-Key',
      orElse: () => const MapEntry('', ''),
    );
    _tokenController.text = tokenEntry.value;
    _authType = tokenEntry.key == 'X-Api-Key'
        ? AuthType.apiKey
        : tokenEntry.value.startsWith('Bearer ')
        ? AuthType.bearer
        : AuthType.plain;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(l10n.mcpEditServerTitle),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      enabled: false,
                      decoration: _fieldDecoration(
                        label: l10n.mcpNameLabel,
                        hint: '',
                        helper: l10n.mcpNameHelper,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TypeSegment(
                      isRemote: _isRemote,
                      onChanged: (v) => setLocal(() => _isRemote = v),
                    ),
                    const SizedBox(height: 8),
                    if (_isRemote)
                      TextField(
                        controller: _urlController,
                        decoration: _fieldDecoration(
                          label: l10n.mcpUrlLabel,
                          hint: l10n.mcpUrlHint,
                          helper: l10n.mcpUrlHelper,
                          isDark: isDark,
                        ),
                      )
                    else
                      TextField(
                        controller: _commandController,
                        decoration: _fieldDecoration(
                          label: l10n.mcpCommandLabel,
                          hint: l10n.mcpCommandHint,
                          helper: l10n.mcpCommandHelper,
                          isDark: isDark,
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (_isRemote) ...[
                      TextField(
                        controller: _tokenController,
                        decoration: _fieldDecoration(
                          label: l10n.mcpTokenLabel,
                          hint: l10n.mcpTokenHint,
                          helper: l10n.mcpTokenHelper,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AuthType>(
                        initialValue: _authType,
                        decoration: _fieldDecoration(
                          label: l10n.mcpAuthTypeLabel,
                          hint: '',
                          helper: l10n.mcpAuthTypeHelper,
                          isDark: isDark,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: AuthType.bearer,
                            child: Text('Bearer'),
                          ),
                          DropdownMenuItem(
                            value: AuthType.apiKey,
                            child: Text('ApiKey'),
                          ),
                          DropdownMenuItem(
                            value: AuthType.plain,
                            child: Text('Token'),
                          ),
                        ],
                        onChanged: (v) => setLocal(() => _authType = v!),
                      ),
                    ] else
                      TextField(
                        controller: _envController,
                        maxLines: 4,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        decoration: _fieldDecoration(
                          label: l10n.mcpEnvLabel,
                          hint: l10n.mcpEnvHint,
                          helper: l10n.mcpEnvHelper,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.mcpCancelAction),
              ),
              FilledButton(
                onPressed: () {
                  final McpServerConfig updated;
                  if (_isRemote) {
                    final url = _urlController.text.trim();
                    if (url.isEmpty) return;
                    updated = config.copyWith(
                      url: url,
                      headers: buildAuthHeaders(
                        _tokenController.text,
                        _authType,
                      ),
                    );
                  } else {
                    final raw = _commandController.text.trim();
                    if (raw.isEmpty) return;
                    final parts = raw.split(RegExp(r'\s+'));
                    updated = config.copyWith(
                      command: parts.first,
                      args: parts.skip(1).toList(),
                      environment: parseEnvJson(_envController.text),
                    );
                  }
                  Navigator.pop(ctx, {'name': name, 'config': updated});
                },
                child: Text(l10n.mcpSaveAction),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      await ref
          .read(mcpManagementProvider.notifier)
          .updateServer(
            result['name'] as String,
            result['config'] as McpServerConfig,
          );
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ref.read(mcpManagementProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _confirmRemove(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10n.mcpRemoveTitle),
          content: Text(l10n.mcpRemoveContent(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.mcpCancelAction),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.mcpRemoveAction),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(mcpManagementProvider.notifier).removeServer(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final asyncState = ref.watch(mcpManagementProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mcpServers),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.mcpTooltipAdd,
            onPressed: _showAddDialog,
          ),
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SpinKitCircle(color: ChatoraiColors.orange, size: 22),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.mcpTooltipRefresh,
              onPressed: _onRefresh,
            ),
        ],
        bottom: TabBar(
          controller: _screenTabController,
          indicatorColor: ChatoraiColors.orange,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: isDark
              ? ChatoraiColors.darkBorderColor
              : ChatoraiColors.lightBorderColor,
          labelColor: isDark
              ? ChatoraiColors.pureWhite
              : ChatoraiColors.pureBlack,
          unselectedLabelColor: isDark
              ? ChatoraiColors.darkSecondaryTextColor
              : ChatoraiColors.secondaryTextColor,
          tabs: [
            Tab(text: l10n.mcpMarketplaceTab),
            Tab(text: l10n.mcpInstalledTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _screenTabController,
        children: [
          _buildMarketplace(isDark, l10n),
          asyncState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.statsError(error.toString())),
              ),
            ),
            data: (state) {
              final names = state.servers.keys.toList()..sort();
              if (names.isEmpty) {
                return _EmptyState(isDark: isDark, onAdd: _showAddDialog);
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(ChatoraiSpacing.lg),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 720
                        ? 3
                        : constraints.maxWidth >= 480
                        ? 2
                        : 1;
                    final spacing = ChatoraiSpacing.md;
                    final cardWidth =
                        (constraints.maxWidth -
                            spacing * (crossAxisCount - 1)) /
                        crossAxisCount;
                    final children = <Widget>[
                      for (final name in names)
                        SizedBox(
                          width: cardWidth,
                          child: _ServerCard(
                            name: name,
                            config: state.servers[name]!,
                            isDark: isDark,
                            onToggle: (enabled) => ref
                                .read(mcpManagementProvider.notifier)
                                .setEnabled(name, enabled),
                            onRemove: () => _confirmRemove(name),
                            onEdit: () =>
                                _showEditDialog(name, state.servers[name]!),
                          ),
                        ),
                    ];
                    final remainder = names.length % crossAxisCount;
                    if (remainder != 0) {
                      children.addAll(
                        List.generate(
                          crossAxisCount - remainder,
                          (_) => SizedBox(width: cardWidth),
                        ),
                      );
                    }
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: children,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplace(bool isDark, AppLocalizations l10n) {
    final installed =
        ref.watch(mcpManagementProvider).value?.servers ?? const {};
    final query = _query.trim().toLowerCase();
    final categories = marketplaceCategories();

    final visible = mcpMarketplaceCatalog.where((e) {
      if (_activeCategory != null && e.category != _activeCategory) {
        return false;
      }
      if (query.isEmpty) return true;
      final desc = e.description(l10n).toLowerCase();
      return e.displayName.toLowerCase().contains(query) ||
          e.id.toLowerCase().contains(query) ||
          desc.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ChatoraiSpacing.lg,
            ChatoraiSpacing.md,
            ChatoraiSpacing.lg,
            ChatoraiSpacing.sm,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.mcpMarketplaceSearchHint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
                borderSide: BorderSide(
                  color: isDark
                      ? ChatoraiColors.darkInputBorder
                      : ChatoraiColors.inputBorder,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.lg),
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return CategoryChip(
                  label: l10n.mcpMarketCategoryAll,
                  selected: _activeCategory == null,
                  isDark: isDark,
                  onTap: () => setState(() => _activeCategory = null),
                );
              }
              final cat = categories[index - 1];
              return CategoryChip(
                label: _categoryLabel(l10n, cat),
                selected: _activeCategory == cat,
                isDark: isDark,
                onTap: () => setState(
                  () => _activeCategory = _activeCategory == cat ? null : cat,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.sm),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.mcpMarketplaceEmpty,
                      style: TextStyle(
                        color: isDark
                            ? ChatoraiColors.darkSecondaryTextColor
                            : ChatoraiColors.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(ChatoraiSpacing.lg),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossCount = constraints.maxWidth >= 720
                          ? 3
                          : constraints.maxWidth >= 480
                          ? 2
                          : 1;
                      final spacing = ChatoraiSpacing.md;
                      final cardWidth =
                          (constraints.maxWidth - spacing * (crossCount - 1)) /
                          crossCount;
                      final children = <Widget>[
                        for (final entry in visible)
                          SizedBox(
                            width: cardWidth,
                            child: _MarketCard(
                              entry: entry,
                              isDark: isDark,
                              isInstalled: installed.containsKey(entry.id),
                              expanded: _expanded.contains(entry.id),
                              description: entry.description(l10n),
                              onToggleExpand: () => setState(() {
                                if (_expanded.contains(entry.id)) {
                                  _expanded.remove(entry.id);
                                } else {
                                  _expanded.add(entry.id);
                                }
                              }),
                              onInstall: installed.containsKey(entry.id)
                                  ? null
                                  : () => _installFromMarketplace(entry),
                            ),
                          ),
                      ];
                      final remainder = visible.length % crossCount;
                      if (remainder != 0) {
                        children.addAll(
                          List.generate(
                            crossCount - remainder,
                            (_) => SizedBox(width: cardWidth),
                          ),
                        );
                      }
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: children,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  String _categoryLabel(AppLocalizations l10n, McpCategory cat) =>
      switch (cat) {
        McpCategory.search => l10n.mcpMarketCategorySearch,
        McpCategory.docs => l10n.mcpMarketCategoryDocs,
        McpCategory.design => l10n.mcpMarketCategoryDesign,
        McpCategory.dev => l10n.mcpMarketCategoryDev,
        McpCategory.finance => l10n.mcpMarketCategoryFinance,
        McpCategory.travel => l10n.mcpMarketCategoryTravel,
        McpCategory.jobs => l10n.mcpMarketCategoryJobs,
        McpCategory.productivity => l10n.mcpMarketCategoryProductivity,
        McpCategory.social => l10n.mcpMarketCategorySocial,
        McpCategory.other => l10n.mcpMarketCategoryOther,
      };

  Future<void> _installFromMarketplace(McpMarketplaceEntry entry) async {
    await ref
        .read(mcpManagementProvider.notifier)
        .addServer(entry.id, entry.toConfig());
    if (mounted) {
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message:
            '${entry.displayName} · ${AppLocalizations.of(context)!.mcpInstalled}',
      );
    }
  }
}

class _ServerCard extends StatelessWidget {
  final String name;
  final McpServerConfig config;
  final bool isDark;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const _ServerCard({
    required this.name,
    required this.config,
    required this.isDark,
    required this.onToggle,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = config.isLocal
        ? '${config.command}${config.args.isNotEmpty ? ' ${config.args.join(' ')}' : ''}'
        : config.url ?? '';
    final typeLabel = config.isLocal ? 'local' : 'remote';

    return Container(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? ChatoraiColors.darkCard : ChatoraiColors.lightCard,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        border: Border.all(
          color: isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: icon + name.
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: ChatoraiSpacing.sm),
                child: Tooltip(
                  message: _buildTooltip(name),
                  preferBelow: false,
                  child: McpServerIcon(serverId: name, size: 24),
                ),
              ),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.lg,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ChatoraiColors.pureWhite
                        : ChatoraiColors.pureBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: ChatoraiSpacing.sm),
          // Row 2: command / url.
          Text(
            subtitle,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.caption,
              color: isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ChatoraiSpacing.md),
          // Row 3: toggle + type label + edit / remove.
          Row(
            children: [
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: config.enabled,
                  onChanged: onToggle,
                  activeThumbColor: ChatoraiColors.orange,
                  activeTrackColor: ChatoraiColors.orange.withAlpha(150),
                  inactiveThumbColor: isDark
                      ? ChatoraiColors.toggleInactiveThumbDark
                      : ChatoraiColors.toggleInactiveThumbLight,
                  inactiveTrackColor: isDark
                      ? ChatoraiColors.toggleInactiveTrackDark
                      : ChatoraiColors.toggleInactiveTrackLight,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatoraiSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? ChatoraiColors.darkInputFill
                      : ChatoraiColors.inputFill,
                  borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xs),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.caption,
                    color: isDark
                        ? ChatoraiColors.darkSecondaryTextColor
                        : ChatoraiColors.secondaryTextColor,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                iconSize: ChatoraiIconSizes.lg,
                color: isDark
                    ? ChatoraiColors.darkSecondaryTextColor
                    : ChatoraiColors.secondaryTextColor,
                tooltip: AppLocalizations.of(context)!.mcpEditAction,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                iconSize: ChatoraiIconSizes.lg,
                color: ChatoraiColors.error,
                tooltip: AppLocalizations.of(context)!.mcpRemoveAction,
                onPressed: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildTooltip(String serverName) {
    final tools = McpClientService.instance.getDiscoveredTools(serverName);
    if (tools.isEmpty) {
      return serverName;
    }
    const maxShown = 8;
    final shown = tools.take(maxShown).join('\n• ');
    final overflow = tools.length > maxShown
        ? '\n• … (+${tools.length - maxShown} more)'
        : '';
    return '$serverName\n\nTools (${tools.length}):\n• $shown$overflow';
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;

  const _EmptyState({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(ChatoraiSpacing.lg),
        padding: const EdgeInsets.all(ChatoraiSpacing.xxl),
        decoration: BoxDecoration(
          color: isDark ? ChatoraiColors.darkCard : ChatoraiColors.lightCard,
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
          border: Border.all(
            color: isDark
                ? ChatoraiColors.darkInputBorder
                : ChatoraiColors.inputBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension_outlined,
              size: 48,
              color: isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
            ),
            const SizedBox(height: ChatoraiSpacing.md),
            Text(
              l10n.mcpNoServers,
              style: TextStyle(
                fontSize: ChatoraiFontSizes.lg,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? ChatoraiColors.darkTextColor
                    : ChatoraiColors.lightTextColor,
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.xs),
            Text(
              l10n.mcpNoServersHint,
              style: TextStyle(
                fontSize: ChatoraiFontSizes.base,
                color: isDark
                    ? ChatoraiColors.darkSecondaryTextColor
                    : ChatoraiColors.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ChatoraiSpacing.lg),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.mcpAddServer),
              style: FilledButton.styleFrom(
                backgroundColor: ChatoraiColors.orange,
                foregroundColor: ChatoraiColors.pureWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a marketplace server icon: brand SVG when available, otherwise a
/// colored circle with the first letter of the display name.
Widget _marketIcon(bool isDark, McpMarketplaceEntry entry, double size) {
  if (entry.iconAsset != null) {
    return SvgPicture.asset(entry.iconAsset!, width: size, height: size);
  }
  final color = Color(
    int.parse(entry.brandColor.replaceFirst('#', 'FF'), radix: 16),
  );
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withAlpha(28),
      borderRadius: BorderRadius.circular(size * 0.28),
    ),
    child: Center(
      child: Text(
        entry.displayName.characters.first.toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.46,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ),
  );
}

class _MarketCard extends StatelessWidget {
  final McpMarketplaceEntry entry;
  final bool isDark;
  final bool isInstalled;
  final bool expanded;
  final String description;
  final VoidCallback onToggleExpand;
  final VoidCallback? onInstall;

  const _MarketCard({
    required this.entry,
    required this.isDark,
    required this.isInstalled,
    required this.expanded,
    required this.description,
    required this.onToggleExpand,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ChatoraiColors.darkCard : ChatoraiColors.lightCard,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        border: Border.all(
          color: isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
          onTap: onToggleExpand,
          child: Padding(
            padding: const EdgeInsets.all(ChatoraiSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _marketIcon(isDark, entry, 36),
                    const SizedBox(width: ChatoraiSpacing.sm),
                    Expanded(
                      child: Text(
                        entry.displayName,
                        style: TextStyle(
                          fontSize: ChatoraiFontSizes.lg,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? ChatoraiColors.pureWhite
                              : ChatoraiColors.pureBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ChatoraiSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? ChatoraiColors.darkInputFill
                            : ChatoraiColors.inputFill,
                        borderRadius: BorderRadius.circular(
                          ChatoraiBorderRadius.xs,
                        ),
                      ),
                      child: Text(
                        _categoryLabelStatic(entry.category),
                        style: TextStyle(
                          fontSize: ChatoraiFontSizes.caption,
                          color: isDark
                              ? ChatoraiColors.darkSecondaryTextColor
                              : ChatoraiColors.secondaryTextColor,
                        ),
                      ),
                    ),
                    if (entry.requiresToken)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ChatoraiColors.warning.withAlpha(25),
                          borderRadius: BorderRadius.circular(
                            ChatoraiBorderRadius.xs,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.key_rounded,
                              size: 12,
                              color: ChatoraiColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.mcpMarketNeedsToken,
                              style: TextStyle(
                                fontSize: ChatoraiFontSizes.caption,
                                fontWeight: FontWeight.w600,
                                color: ChatoraiColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: ChatoraiSpacing.sm),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.base,
                    color: isDark
                        ? ChatoraiColors.darkSecondaryTextColor
                        : ChatoraiColors.secondaryTextColor,
                    height: 1.35,
                  ),
                  maxLines: expanded ? null : 3,
                  overflow: expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
                const SizedBox(height: ChatoraiSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: isInstalled
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(l10n.mcpInstalled),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ChatoraiColors.success,
                            side: BorderSide(
                              color: ChatoraiColors.success.withAlpha(120),
                            ),
                          ),
                        )
                      : FilledButton(
                          onPressed: onInstall,
                          style: FilledButton.styleFrom(
                            backgroundColor: ChatoraiColors.orange,
                            foregroundColor: ChatoraiColors.pureWhite,
                          ),
                          child: Text(l10n.mcpInstall),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _categoryLabelStatic(McpCategory cat) => switch (cat) {
    McpCategory.search => 'Search',
    McpCategory.docs => 'Docs',
    McpCategory.design => 'Design',
    McpCategory.dev => 'Dev',
    McpCategory.finance => 'Finance',
    McpCategory.travel => 'Travel',
    McpCategory.jobs => 'Jobs',
    McpCategory.productivity => 'Productivity',
    McpCategory.social => 'Social',
    McpCategory.other => 'Other',
  };
}

/// Segmented Local / Remote selector used inside the add-server dialog.
class _TypeSegment extends StatelessWidget {
  final bool isRemote;
  final ValueChanged<bool> onChanged;

  const _TypeSegment({required this.isRemote, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? ChatoraiColors.darkInputFill : ChatoraiColors.inputFill,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
      ),
      child: Row(
        children: [
          _SegmentButton(
            icon: Icons.computer_outlined,
            label: AppLocalizations.of(context)!.mcpTypeLocal,
            tooltip: AppLocalizations.of(context)!.mcpTypeLocalTooltip,
            selected: !isRemote,
            isDark: isDark,
            onTap: () => onChanged(false),
          ),
          _SegmentButton(
            icon: Icons.cloud_outlined,
            label: AppLocalizations.of(context)!.mcpTypeRemote,
            tooltip: AppLocalizations.of(context)!.mcpTypeRemoteTooltip,
            selected: isRemote,
            isDark: isDark,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = ChatoraiColors.orange;
    final bg = selected
        ? (isDark ? selectedColor.withAlpha(40) : selectedColor.withAlpha(25))
        : Colors.transparent;
    final fg = selected
        ? selectedColor
        : (isDark
              ? ChatoraiColors.darkSecondaryTextColor
              : ChatoraiColors.secondaryTextColor);

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: ChatoraiSpacing.sm),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xs),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: ChatoraiIconSizes.lg, color: fg),
                const SizedBox(width: ChatoraiSpacing.xs),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.base,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
