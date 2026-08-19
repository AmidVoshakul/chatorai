import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single owner of the [McpClientService] lifecycle.
///
/// Re-runs whenever the config changes (including workspace switches) and
/// reconciles live connections via [McpClientService.reload], which connects
/// new servers, disconnects removed/disabled ones and reconnects servers whose
/// config drifted. When MCP is not configured (or all servers were removed),
/// reload tears down whatever is left, so stale connections never leak from
/// one workspace into the next.
///
/// Shared by [toolRegistryProvider] and [mcpStatusesProvider] so both wait on
/// the SAME connection work.
final mcpInitializationProvider = FutureProvider<void>((ref) async {
  final config = await ref.watch(configProvider.future);
  final mcp = config.mcp ?? const McpConfig();
  await McpClientService.instance.reload(mcp);
});

/// Snapshot of every MCP server status.
///
/// Resolves only AFTER [mcpInitializationProvider] finished, so the chat
/// status bar shows a spinner for the whole connection window and then the
/// real `connected/total` count — and, when the config has no MCP servers,
/// after the previous connections have been torn down.
final mcpStatusesProvider = FutureProvider<Map<String, McpServerStatus>>((
  ref,
) async {
  await ref.watch(mcpInitializationProvider.future);
  return McpClientService.instance.getAllStatuses();
});
