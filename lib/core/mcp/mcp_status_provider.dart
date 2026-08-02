import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/core/tools/tool_registry_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Snapshot of every MCP server status.
///
/// When MCP is not configured, returns an empty map immediately without waiting
/// for [toolRegistryProvider]. When MCP is configured, waits for MCP
/// initialization only, not for the full tool registry setup.
final mcpStatusesProvider = FutureProvider<Map<String, McpServerStatus>>((
  ref,
) async {
  final config = await ref.watch(configProvider.future);

  if (config.mcp == null || config.mcp!.servers.isEmpty) {
    return const {};
  }

  await ref.watch(toolRegistryProvider.future);
  return McpClientService.instance.getAllStatuses();
});
