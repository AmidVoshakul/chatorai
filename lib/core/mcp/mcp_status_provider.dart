import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves once all configured MCP servers have finished connecting.
///
/// Shared by [toolRegistryProvider] and [mcpStatusesProvider] so the status bar
/// keeps showing a spinner until servers actually connect. initialize() is
/// idempotent (McpClientService guards with an internal completer), so both
/// consumers wait on the SAME connection work.
final mcpInitializationProvider = FutureProvider<void>((ref) async {
  final config = await ref.watch(configProvider.future);
  if (config.mcp == null || config.mcp!.servers.isEmpty) return;
  await McpClientService.instance.initialize(config.mcp!);
});

/// Snapshot of every MCP server status.
///
/// When MCP is not configured, returns an empty map immediately without waiting
/// for any init. When MCP is configured, resolves only AFTER the servers have
/// finished connecting, so the chat status bar shows a spinner for the whole
/// connection window and then the real `connected/total` count.
final mcpStatusesProvider = FutureProvider<Map<String, McpServerStatus>>((
  ref,
) async {
  final config = await ref.watch(configProvider.future);

  if (config.mcp == null || config.mcp!.servers.isEmpty) {
    return const {};
  }

  await ref.watch(mcpInitializationProvider.future);
  return McpClientService.instance.getAllStatuses();
});
