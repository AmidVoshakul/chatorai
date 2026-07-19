import 'package:chatorai/core/config/config_manager.dart';
import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/core/mcp/mcp_status_provider.dart';
import 'package:chatorai/core/tools/tool_registry_provider.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = LogTags.mcp;

/// UI-facing state for the MCP servers management screen.
class McpManagementState {
  final Map<String, McpServerConfig> servers;

  const McpManagementState({this.servers = const {}});

  McpManagementState copyWith({Map<String, McpServerConfig>? servers}) {
    return McpManagementState(servers: servers ?? this.servers);
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

  @override
  Future<McpManagementState> build() => _reload();

  Future<McpManagementState> _reload() async {
    try {
      final config = await ConfigManager.loadConfig(path: _overridePath);
      final servers = config.mcp?.servers ?? const <String, McpServerConfig>{};
      _logger.logInfo(
        'McpManagementNotifier: loaded ${servers.length} MCP server(s)',
      );
      return McpManagementState(servers: servers);
    } catch (e, st) {
      _logger.logError('McpManagementNotifier: failed to load config', e, st);
      rethrow;
    }
  }

  Future<String> _configPath() async =>
      _overridePath ?? await ConfigWriter.resolveConfigPath(global: true);

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

  Future<void> addServer(String name, McpServerConfig config) async {
    final path = await _configPath();
    await ConfigWriter.upsertMcpServer(name, config, configPath: path);
    state = AsyncValue.data(await _reload());
    await _syncService();
  }

  Future<void> removeServer(String name) async {
    final path = await _configPath();
    await ConfigWriter.removeMcpServer(name, configPath: path);
    state = AsyncValue.data(await _reload());
    await _syncService();
  }

  /// Updates an existing server's configuration in place (e.g. editing a token
  /// for an auth-gated remote server). Persists through [ConfigWriter] and
  /// re-syncs the live MCP client.
  Future<void> updateServer(String name, McpServerConfig config) async {
    final path = await _configPath();
    await ConfigWriter.upsertMcpServer(name, config, configPath: path);
    state = AsyncValue.data(await _reload());
    await _syncService();
  }

  Future<void> setEnabled(String name, bool enabled) async {
    final path = await _configPath();
    await ConfigWriter.setMcpEnabled(name, enabled, configPath: path);
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
