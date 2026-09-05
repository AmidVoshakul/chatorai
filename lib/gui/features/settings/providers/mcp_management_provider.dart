import 'dart:io';

import 'package:chatorai/core/config/config_loader.dart';
import 'package:chatorai/core/config/config_manager.dart';
import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/core/mcp/mcp_status_provider.dart';
import 'package:chatorai/gui/features/chat/data/providers/tool_registry_provider.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = LogTags.mcp;

/// Which scope an MCP server mutation targets.
///
/// - [global]: user-level servers in `<XDG_CONFIG_HOME>/chatorai.json`, available
///   everywhere (including mobile).
/// - [project]: servers under the current working directory's project config
///   path (`.chatorai/chatorai.json`). Desktop only.
enum McpScope { global, project }

/// UI-facing state for the MCP servers management screen.
///
/// Both scope maps are loaded independently so the Installed tab can show
/// per-scope badges (Global / Project / Global + Project) and the merged
/// [servers] view preserves project-override-global semantics identical to
/// [ConfigLoader]'s deep-merge.
class McpManagementState {
  final Map<String, McpServerConfig> globalServers;
  final Map<String, McpServerConfig> projectServers;
  final bool supportsProjectScope;

  const McpManagementState({
    this.globalServers = const {},
    this.projectServers = const {},
    this.supportsProjectScope = false,
  });

  /// Deep-merged view: project keys override global ones.
  Map<String, McpServerConfig> get servers => {
    ...globalServers,
    ...projectServers,
  };

  McpManagementState copyWith({
    Map<String, McpServerConfig>? globalServers,
    Map<String, McpServerConfig>? projectServers,
    bool? supportsProjectScope,
  }) {
    return McpManagementState(
      globalServers: globalServers ?? this.globalServers,
      projectServers: projectServers ?? this.projectServers,
      supportsProjectScope: supportsProjectScope ?? this.supportsProjectScope,
    );
  }

  /// Returns the scopes where [name] is installed.
  Set<McpScope> serverScopes(String name) {
    final scopes = <McpScope>{};
    if (globalServers.containsKey(name)) scopes.add(McpScope.global);
    if (projectServers.containsKey(name)) scopes.add(McpScope.project);
    return scopes;
  }

  /// Human-readable scope label for display on installed-server cards.
  String scopeLabel(String name) {
    final scopes = serverScopes(name);
    if (scopes.length == 2) return 'Global + Project';
    if (scopes.contains(McpScope.project)) return 'Project';
    return 'Global';
  }
}

/// Loads, mutates, and persists MCP server declarations in `chatorai.json`.
///
/// Reads/writes the same file the CLI and TUI use, so a change made in the GUI
/// is immediately visible to `chatorai mcp list` and vice versa.
///
/// Backed by [AsyncNotifier] so Riverpod owns the async lifecycle: the initial
/// [build] returns the loaded config as a [Future], and every mutation
/// re-runs [_reload] and returns the fresh state. This avoids the
/// fire-and-forget `state =` pattern that left the screen stuck on a spinner.
class McpManagementNotifier extends AsyncNotifier<McpManagementState> {
  String? _overridePath;
  bool _serviceSyncEnabled = true;

  /// Test hook: point the notifier at an isolated config file.
  void setConfigPathForTest(String path) => _overridePath = path;

  /// Test hook: disable live [McpClientService] reconciliation so unit tests
  /// don't spawn real MCP subprocesses. Mirrors [setConfigPathForTest].
  void setServiceSyncEnabledForTest(bool enabled) =>
      _serviceSyncEnabled = enabled;

  bool get _supportsProjectScope =>
      _overridePath == null &&
      (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  @override
  Future<McpManagementState> build() => _reload();

  Future<McpManagementState> _reload() async {
    try {
      final config = await ConfigManager.loadConfig(path: _overridePath);
      final mcp = config.mcp ?? const McpConfig();
      final globalServers = await _loadScopeServers(McpScope.global);
      final projectServers = _supportsProjectScope
          ? await _loadScopeServers(McpScope.project)
          : const <String, McpServerConfig>{};

      _logger.logInfo(
        'McpManagementNotifier: loaded ${mcp.servers.length} MCP server(s) '
        '(global: ${globalServers.length}, project: ${projectServers.length})',
      );
      return McpManagementState(
        globalServers: globalServers,
        projectServers: projectServers,
        supportsProjectScope: _supportsProjectScope,
      );
    } catch (e, st) {
      _logger.logError('McpManagementNotifier: failed to load config', e, st);
      rethrow;
    }
  }

  /// Loads servers from a single scope's config file.
  Future<Map<String, McpServerConfig>> _loadScopeServers(McpScope scope) async {
    try {
      final path =
          _overridePath ??
          await ConfigLoader.resolveConfigPath(
            global: scope == McpScope.global,
          );
      final raw = await ConfigWriter.readRawConfig(path);
      final mcp = raw['mcp'];
      if (mcp == null || mcp is! Map<String, dynamic>) {
        return const {};
      }
      return McpConfig.fromJson(mcp).servers;
    } catch (_) {
      return const {};
    }
  }

  Future<String> _configPath(McpScope scope) async =>
      _overridePath ??
      await ConfigLoader.resolveConfigPath(global: scope == McpScope.global);

  /// Reconcile the live [McpClientService] and dependent providers with the
  /// current on-disk config, so MCP connections and the chat status bar update
  /// immediately — without requiring an app restart.
  Future<void> _syncService() async {
    if (!_serviceSyncEnabled) return;
    final config = await ConfigManager.loadConfig(path: _overridePath);
    final mcp = config.mcp ?? const McpConfig();
    await McpClientService.instance.reload(mcp);
    ref.invalidate(mcpStatusesProvider);
    ref.invalidate(toolRegistryProvider);
  }

  Future<void> addServer(
    String name,
    McpServerConfig config, {
    McpScope scope = McpScope.global,
  }) async {
    final path = await _configPath(scope);
    await ConfigWriter.upsertMcpServer(name, config, configPath: path);
    state = AsyncValue.data(await _reload());
    await _syncService();
  }

  Future<void> removeServer(String name, {McpScope? scope}) async {
    // When scope is null, remove from all scopes.
    if (scope != null) {
      final path = await _configPath(scope);
      await ConfigWriter.removeMcpServer(name, configPath: path);
    } else {
      final stateData = state.value;
      if (stateData != null) {
        if (stateData.globalServers.containsKey(name)) {
          final path = await _configPath(McpScope.global);
          await ConfigWriter.removeMcpServer(name, configPath: path);
        }
        if (stateData.projectServers.containsKey(name)) {
          final path = await _configPath(McpScope.project);
          await ConfigWriter.removeMcpServer(name, configPath: path);
        }
      }
    }
    state = AsyncValue.data(await _reload());
    await _syncService();
  }

  /// Updates an existing server's configuration in place (e.g. editing a token
  /// for an auth-gated remote server). Persists through [ConfigWriter] and
  /// re-syncs the live MCP client.
  Future<void> updateServer(
    String name,
    McpServerConfig config, {
    McpScope scope = McpScope.global,
  }) async {
    final path = await _configPath(scope);
    await ConfigWriter.upsertMcpServer(name, config, configPath: path);
    state = AsyncValue.data(await _reload());
    await _syncService();
  }

  Future<void> setEnabled(String name, bool enabled, {McpScope? scope}) async {
    // When scope is null, toggle all scopes where this server exists.
    if (scope != null) {
      final path = await _configPath(scope);
      await ConfigWriter.setMcpEnabled(name, enabled, configPath: path);
    } else {
      final stateData = state.value;
      if (stateData != null) {
        if (stateData.globalServers.containsKey(name)) {
          final path = await _configPath(McpScope.global);
          await ConfigWriter.setMcpEnabled(name, enabled, configPath: path);
        }
        if (stateData.projectServers.containsKey(name)) {
          final path = await _configPath(McpScope.project);
          await ConfigWriter.setMcpEnabled(name, enabled, configPath: path);
        }
      }
    }
    state = AsyncValue.data(await _reload());
    await _syncService();
  }

  Future<void> refresh() async {
    state = AsyncValue.data(await _reload());
    await _syncService();
  }
}

final mcpManagementProvider =
    AsyncNotifierProvider<McpManagementNotifier, McpManagementState>(
      McpManagementNotifier.new,
    );
