import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:chatorai/features/agents/data/models/agent_registry.dart';
import 'package:chatorai/features/chat/domain/services/chat_ai_service.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:chatorai/features/tools/data/models/tool_registry.dart';

/// Tools always denied to subagents (prevents infinite delegation loops).
const _subagentDeniedTools = {'task', 'todowrite'};

ToolDef createTaskTool({
  ChatAiService? chatAiService,
  ToolRegistry? toolRegistry,
}) {
  return ToolDef(
    id: 'task',
    description:
        'Delegate a complex, multi-step task to a specialized subagent. Use for tasks requiring exploration, analysis, or specialized expertise.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'description': {
          'type': 'string',
          'description': 'Short task summary (3-5 words)',
        },
        'prompt': {
          'type': 'string',
          'description': 'Full task instructions for the subagent',
        },
        'subagent_type': {
          'type': 'string',
          'description':
              'Agent type: build, explore, plan, general, compaction, title, summary',
          'enum': [
            'build',
            'explore',
            'plan',
            'general',
            'compaction',
            'title',
            'summary',
          ],
        },
      },
      'required': ['description', 'prompt', 'subagent_type'],
    },
    execute: (input, ctx) async {
      // Validate required fields
      final description = input['description'] as String?;
      final prompt = input['prompt'] as String?;
      final subagentType = input['subagent_type'] as String?;
      final taskId = input['task_id'] as String?;

      if (description == null ||
          description.isEmpty ||
          prompt == null ||
          prompt.isEmpty ||
          subagentType == null ||
          subagentType.isEmpty) {
        return ToolOutput(
          'Error: Missing required fields: description, prompt, subagent_type',
          metadata: {'error': true},
        );
      }

      // Ensure session ID is available
      final sessionId = ctx.sessionId;
      if (sessionId == null) {
        return ToolOutput(
          'Error: Missing session ID',
          metadata: {'error': true},
        );
      }

      // Permission check
      await ctx.ask(
        permission: 'task',
        patterns: [subagentType],
        metadata: {'description': description, 'subagent_type': subagentType},
      );

      // Resolve agent
      final agent = AgentRegistry().get(subagentType);
      if (agent == null) {
        return ToolOutput(
          'Error: Unknown agent type "$subagentType". Available: ${AgentRegistry().getSubagents().map((a) => a.id).join(", ")}',
          metadata: {'error': true},
        );
      }

      // Derive subagent tool roster: available tools minus denied ones
      final ToolSet subagentTools = toolRegistry != null
          ? _deriveSubagentTools(toolRegistry)
          : <String, Tool<dynamic, dynamic>>{};

      // If no ChatAiService provided, return placeholder (MVP fallback)
      if (chatAiService == null) {
        final idAttr = taskId != null
            ? 'id="$taskId"'
            : 'id="sub-${DateTime.now().millisecondsSinceEpoch}"';
        final sessionIdAttr = 'session_id="$sessionId"';
        final taskIdAttr = taskId != null ? 'task_id="$taskId"' : '';
        return ToolOutput(
          '<task $idAttr $sessionIdAttr $taskIdAttr state="completed">'
          '<summary>$description</summary>'
          '<task_result>[Subagent MVP not yet wired to ChatAiService. Agent: ${agent.name}]\n'
          'Prompt: $prompt</task_result>'
          '</task>',
           metadata: {
             'subagent_type': subagentType,
             'agent_name': agent.name,
             'description': description,
             'session_id': sessionId,
             ...(taskId != null ? {'task_id': taskId} : {}),
           },
        );
      }

      // Run subagent via existing ChatAiService
      final messages = <Map<String, dynamic>>[
        {
          'role': 'system',
          'content': agent.systemPrompt ?? 'You are a helpful assistant.',
        },
        {'role': 'user', 'content': prompt},
      ];

      final sb = StringBuffer();

      await chatAiService.streamChatCompletion(
        messages: messages,
        model: 'openrouter/auto',
        temperature: 0.7,
        tools: subagentTools,
        maxSteps: agent.maxSteps,
        onChunk: (chunk) => sb.write(chunk),
        onReasoning: (_) {},
        onCompletion: (_) {},
        onToolStart: (_, _, _) {},
        onToolEnd: (_, _, result) => sb.write(result),
        onToolError: (_, _, error) => sb.writeln('\n[Tool error: $error]'),
      );

      final result = sb.toString();
      final idAttr = taskId != null
          ? 'id="$taskId"'
          : 'id="sub-${DateTime.now().millisecondsSinceEpoch}"';
      final sessionIdAttr = 'session_id="$sessionId"';
      final taskIdAttr = taskId != null ? 'task_id="$taskId"' : '';
      return ToolOutput(
        '<task $idAttr $sessionIdAttr $taskIdAttr state="completed">'
        '<summary>$description</summary>'
        '<task_result>$result</task_result>'
        '</task>',
         metadata: {
           'subagent_type': subagentType,
           'agent_name': agent.name,
           'description': description,
           'session_id': sessionId,
           ...(taskId != null ? {'task_id': taskId} : {}),
         },
      );
    },
  );
}

/// Derive subagent tools from the parent registry:
/// - Start with all available (non-denied) tools
/// - Remove `task` and `todowrite` (prevents infinite delegation)
/// - Return as SDK tool set for streaming
ToolSet _deriveSubagentTools(ToolRegistry registry) {
  final allTools = registry.toSDKTools();
  final result = <String, Tool<dynamic, dynamic>>{};
  for (final entry in allTools.entries) {
    if (!_subagentDeniedTools.contains(entry.key)) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}
