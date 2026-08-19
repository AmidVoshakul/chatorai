import 'dart:io';

import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:mcp_dart/mcp_dart.dart';

/// Singleton service managing MCP client connections and tool discovery.
///
/// Mirrors  `MCP.Service` pattern:
/// - Config-driven server registry (`chatorai.json` → `mcp` section)
/// - Per-server client lifecycle (connect, disconnect, reconnect)
/// - Tool discovery + dynamic registration as `ToolDef`
/// - Status tracking per server
class McpClientService {
  static const _defaultTimeoutMs = 30000;

  McpClientService._();
  static final McpClientService instance = McpClientService._();

  final Map<String, McpClient> _clients = {};
  final Map<String, McpServerConfig> _configs = {};
  final Map<String, McpServerStatus> _statuses = {};
  final Map<String, List<McpToolInfo>> _discoveredTools = {};

  int _generation = 0;

  /// Initialize service from config — discovers tools for all enabled servers.
  ///
  /// Delegates to [reload], which diffs the desired [config] against the
  /// current connections, so repeated calls with an unchanged config are
  /// no-ops while changed configs are applied in place.
  Future<void> initialize(McpConfig config) => reload(config);

  /// Reconcile live connections with the latest [config] without a full
  /// re-initialization.
  ///
  /// Safe to call after a runtime config change (e.g. the GUI adds/removes an
  /// MCP server or the user switches workspace). It diffs the desired [config]
  /// against current connections:
  ///
  /// - New or enabled servers with no active client are connected.
  /// - Disabled servers with an active client are disconnected.
  /// - Enabled servers whose config drifted (same name, different settings)
  ///   are reconnected with the new settings.
  /// - Servers absent from [config] but still connected are disconnected.
  ///
  /// Each call bumps a generation counter; any connection work from an older
  /// call that is still in flight aborts its writes, so a config change never
  /// races with a previous connection pass and stale servers cannot leak into
  /// a newer config.
  Future<void> reload(McpConfig config) async {
    _generation++;

    final previousConfigs = Map<String, McpServerConfig>.of(_configs);
    for (final entry in config.servers.entries) {
      _configs[entry.key] = entry.value;
    }

    // Drop servers removed from the config entirely (not just disabled).
    final removed = previousConfigs.keys
        .where((n) => !config.servers.containsKey(n))
        .toList();
    for (final name in removed) {
      await disconnect(name);
      _statuses.remove(name);
      _configs.remove(name);
    }

    // Connect newly enabled servers, disconnect newly disabled ones, and
    // reconnect servers whose settings drifted.
    for (final entry in config.servers.entries) {
      final name = entry.key;
      final serverConfig = entry.value;
      final hasClient = _clients.containsKey(name);
      final drifted = hasClient && previousConfigs[name] != serverConfig;

      if (serverConfig.enabled && !hasClient) {
        await connect(name);
      } else if (!serverConfig.enabled && hasClient) {
        await disconnect(name);
      } else if (serverConfig.enabled && drifted) {
        await disconnect(name);
        await connect(name);
      } else {
        // Keep status in sync even when no connection change is needed.
        _statuses[name] = serverConfig.enabled
            ? (_statuses[name] ?? McpServerStatus.connected())
            : McpServerStatus.disabled();
      }
    }
  }

  /// Connect to a single MCP server by name.
  Future<McpServerStatus> connect(String name) async {
    final config = _configs[name];
    if (config == null) {
      return McpServerStatus.failed('MCP server "$name" not found in config');
    }

    // Disconnect existing client first
    await disconnect(name);

    return _connectServer(name, config, _generation);
  }

  /// Disconnect from a server by name.
  Future<void> disconnect(String name) async {
    final client = _clients.remove(name);
    if (client != null) {
      try {
        await client.close();
      } catch (e) {
        LogTags.mcp.logWarning('Error closing MCP client for $name', e);
      }
    }
    _discoveredTools.remove(name);
    _statuses[name] = McpServerStatus.disabled();
  }

  /// Get connection status for a server.
  McpServerStatus getStatus(String name) {
    return _statuses[name] ?? McpServerStatus.failed('Not configured');
  }

  /// Get all server statuses.
  Map<String, McpServerStatus> getAllStatuses() => Map.unmodifiable(_statuses);

  /// Get the list of tool names discovered from [name], or an empty list if
  /// the server is not connected or discovery has not run yet.
  List<String> getDiscoveredTools(String name) =>
      _discoveredTools[name]?.map((t) => t.name).toList() ?? const [];

  /// Discover tools from a connected server.
  ///
  /// Returns empty list if not connected or discovery fails. When
  /// [generation] is provided, a stale discovery (superseded by a newer
  /// config) does not write into the service.
  Future<List<McpToolInfo>> listTools(String name, {int? generation}) async {
    final client = _clients[name];
    if (client == null) return [];

    try {
      final result = await client.listTools();
      if (generation != null && generation != _generation) return [];
      final tools = result.tools
          .map(
            (t) => McpToolInfo(
              name: t.name,
              description: t.description,
              inputSchema: t.inputSchema.toJson(),
            ),
          )
          .toList();
      _discoveredTools[name] = tools;
      return tools;
    } catch (e, st) {
      LogTags.mcp.logError(
        'McpClientService.listTools failed for $name',
        e,
        st,
      );
      return [];
    }
  }

  /// Discover tools from ALL connected servers.
  Future<Map<String, List<McpToolInfo>>> listAllTools() async {
    final result = <String, List<McpToolInfo>>{};
    for (final name in _clients.keys) {
      final tools = await listTools(name);
      if (tools.isNotEmpty) {
        result[name] = tools;
      }
    }
    return result;
  }

  /// Call a tool on a specific MCP server.
  Future<McpCallResult> callTool({
    required String serverName,
    required String toolName,
    required Map<String, dynamic> arguments,
    Duration? timeout,
  }) async {
    final client = _clients[serverName];
    if (client == null) {
      return McpCallResult(
        isError: true,
        content: [
          McpContentPart(
            type: 'text',
            text: 'MCP server not connected: $serverName',
          ),
        ],
      );
    }

    try {
      final rawResult = await client.callTool(
        CallToolRequest(name: toolName, arguments: arguments),
      );

      final content = rawResult.content
          .map(
            (c) => McpContentPart(
              type: c.type,
              text: c is TextContent ? c.text : null,
              mimeType: null,
              data: null,
            ),
          )
          .toList();

      return McpCallResult(
        isError: rawResult.isError,
        content: content,
        structuredContent: rawResult.structuredContent,
      );
    } catch (e, st) {
      LogTags.mcp.logError(
        'McpClientService.callTool failed: $serverName/$toolName',
        e,
        st,
      );
      return McpCallResult(
        isError: true,
        content: [
          McpContentPart(type: 'text', text: 'Error calling $toolName: $e'),
        ],
      );
    }
  }

  /// Get all discovered tools across all connected servers, converted to `ToolDef`.
  ///
  /// Tool names are sanitized: `serverName_toolName` (non-alphanumeric chars → `_`).
  Future<List<ToolDef>> getToolDefs() async {
    final allTools = await listAllTools();
    final result = <ToolDef>[];

    for (final entry in allTools.entries) {
      final serverName = entry.key;
      for (final tool in entry.value) {
        result.add(_convertToToolDef(serverName, tool));
      }
    }

    return result;
  }

  /// Close all clients and reset state.
  Future<void> dispose() async {
    _generation++;
    for (final name in _clients.keys.toList()) {
      await disconnect(name);
    }
    _configs.clear();
    _statuses.clear();
    _discoveredTools.clear();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<McpServerStatus> _connectServer(
    String name,
    McpServerConfig config,
    int generation,
  ) async {
    try {
      late final McpClient client;

      if (config.isLocal) {
        client = await _connectLocal(name, config);
      } else {
        client = await _connectRemote(name, config);
      }

      if (generation != _generation) {
        await client.close();
        return McpServerStatus.failed('Connection superseded by newer config');
      }

      _clients[name] = client;
      _statuses[name] = McpServerStatus.connected();

      // Discover tools
      final tools = await listTools(name, generation: generation);
      LogTags.mcp.logInfo(
        'McpClientService: server $name connected, ${tools.length} tools discovered',
      );

      return McpServerStatus.connected();
    } catch (e) {
      // A misconfigured or unavailable MCP server (e.g. missing binary,
      // crashed on startup) must not abort app startup. Downgrade to a warning
      // so a single bad server in the user's chatorai.json doesn't read as a
      // hard application failure.
      LogTags.mcp.logWarning(
        'McpClientService: server "$name" failed to start — skipped. '
        'Check the command/args in chatorai.json. ($e)',
      );
      if (generation != _generation) {
        return McpServerStatus.failed('Connection superseded by newer config');
      }
      final errorMsg = e.toString();
      _statuses[name] = McpServerStatus.failed(errorMsg);
      return McpServerStatus.failed(errorMsg);
    }
  }

  Future<McpClient> _connectLocal(String name, McpServerConfig config) async {
    final transport = StdioClientTransport(
      StdioServerParameters(
        command: config.command,
        args: config.args,
        environment: {...Platform.environment, ...config.environment},
        workingDirectory: config.cwd,
        // Don't inherit the server's stderr: MCP servers often print startup
        // banners (FastMCP ASCII art, etc.) that would pollute the CLI/TUI
        // output. The MCP protocol travels over stdout, which is untouched.
        stderrMode: ProcessStartMode.normal,
      ),
    );

    final client = McpClient(
      Implementation(name: 'chatorai', version: '0.1.0'),
    );

    await client.connect(transport);
    return client;
  }

  Future<McpClient> _connectRemote(String name, McpServerConfig config) async {
    final uri = Uri.parse(config.url!);

    final transport = StreamableHttpClientTransport(
      uri,
      opts: StreamableHttpClientTransportOptions(
        requestInit: config.headers != null && config.headers!.isNotEmpty
            ? {'headers': config.headers}
            : null,
      ),
    );

    final client = McpClient(
      Implementation(name: 'chatorai', version: '0.1.0'),
    );

    await client.connect(transport);
    return client;
  }

  ToolDef _convertToToolDef(String serverName, McpToolInfo mcpTool) {
    final sanitizedServer = _sanitize(serverName);
    final sanitizedTool = _sanitize(mcpTool.name);
    final toolId = '${sanitizedServer}_$sanitizedTool';

    LogTags.mcp.logInfo('MCP tool $toolId inputSchema: ${mcpTool.inputSchema}');

    return ToolDef(
      id: toolId,
      description:
          mcpTool.description ?? 'MCP tool: $serverName/${mcpTool.name}',
      inputSchema: Map<String, dynamic>.from(mcpTool.inputSchema)
        ..['type'] = 'object',
      skipValidation: true,
      execute: (input, ctx) async {
        LogTags.mcp.logInfo('MCP tool $toolId called with input: $input');

        final timeout = _configs[serverName]?.timeout ?? _defaultTimeoutMs;
        final result = await callTool(
          serverName: serverName,
          toolName: mcpTool.name,
          arguments: input,
          timeout: Duration(milliseconds: timeout),
        );

        if (result.isError) {
          return ToolOutput(
            'MCP tool error (${mcpTool.name}): ${result.textContent}',
            metadata: {
              'error': true,
              'server': serverName,
              'tool': mcpTool.name,
            },
          );
        }

        LogTags.mcp.logInfo(
          'MCP tool $toolId returned ${result.content.length} content parts',
        );

        return ToolOutput(
          result.textContent,
          metadata: {
            'server': serverName,
            'tool': mcpTool.name,
            if (result.structuredContent != null)
              'structured': result.structuredContent,
          },
        );
      },
    );
  }

  static String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
