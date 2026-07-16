import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/core/tools/tool_registry_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Snapshot of every MCP server status.
///
/// Depends on [toolRegistryProvider] — the sole owner of MCP initialization —
/// so statuses are populated only after the tool registry has finished loading.
final mcpStatusesProvider =
    FutureProvider<Map<String, McpServerStatus>>((ref) async {
  await ref.watch(toolRegistryProvider.future);
  return McpClientService.instance.getAllStatuses();
});
