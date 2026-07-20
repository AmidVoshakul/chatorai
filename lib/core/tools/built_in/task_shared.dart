import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/tools/tool_registry.dart';

const Set<String> subagentDeniedTools = {'task', 'todowrite'};

String normalizeSessionId(String id) {
  if (id.startsWith('ses_')) return id;
  return 'ses_$id';
}

/// Returns the tools available to a delegated child session: every registered
/// tool except those that would let a subagent spawn more subagents or mutate
/// the parent's todo list.
Map<String, sdk.Tool<dynamic, dynamic>> deriveSubagentTools(
  ToolRegistry registry,
) {
  final allTools = registry.toSDKTools();
  final result = <String, sdk.Tool<dynamic, dynamic>>{};
  for (final entry in allTools.entries) {
    if (!subagentDeniedTools.contains(entry.key)) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}
