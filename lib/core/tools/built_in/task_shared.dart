import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/tools/tool_registry.dart';

const Set<String> subagentDeniedTools = {
  'task',
  'task_container',
  'todowrite',
  'plan_enter',
  'plan_exit',
};

/// Tools that spawn their own child sessions and are rendered in the parent
/// chat as per-task [TaskPart] cards instead of a regular tool part.
///
/// The parent [SessionRunnerSession] must not record a `ToolCalled` part for
/// these tools: the sub-tasks' progress is represented by `TaskPartStarted`
/// events (emitted by `runTaskInChild`), and recording a tool part as well
/// would render a redundant "header" next to the task cards.
const Set<String> delegatedToolIds = {'task', 'task_container'};

/// Whether [toolId] is a delegated tool whose result is surfaced through
/// per-task cards rather than a tool part.
bool isDelegatedTool(String toolId) => delegatedToolIds.contains(toolId);

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
