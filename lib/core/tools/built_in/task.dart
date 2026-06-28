import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';

const _subagentDeniedTools = {'task', 'todowrite'};

class SessionRunnerHolder {
  final SessionRunner? runner;
  const SessionRunnerHolder(this.runner);
}

String _escapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _buildTaskXml({
  required String sessionId,
  required String taskId,
  required String agent,
  required String state,
  required String summary,
  required String content,
  String? userTaskId,
}) {
  final safeId = _escapeXml(taskId);
  final safeAgent = _escapeXml(agent);
  final safeSessionId = _escapeXml(sessionId);
  final safeSummary = _escapeXml(summary);
  final safeContent = content.replaceAll(']]>', ']]]]><![CDATA[>');

  final taskIdAttr = userTaskId != null && userTaskId.isNotEmpty
      ? ' task_id="${_escapeXml(userTaskId)}"'
      : '';

  return '<task id="$safeId"$taskIdAttr agent="$safeAgent" session_id="$safeSessionId" state="$state">'
      '<summary>$safeSummary</summary>'
      '<task_result><![CDATA[$safeContent]]></task_result>'
      '</task>';
}

ToolDef createTaskTool({
  ChatAiService? chatAiService,
  ToolRegistry? toolRegistry,
  SessionRunnerHolder? currentSessionRunner,
}) {
  return ToolDef(
    id: 'task',
    description:
        'Delegate a complex, multi-step task to a specialized subagent.',
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
          'description': 'Agent type: build, explore, plan, general',
          'enum': ['build', 'explore', 'plan', 'general'],
        },
        'task_id': {
          'type': 'string',
          'description': 'Optional unique identifier for this task',
        },
        'background': {
          'type': 'string',
          'description': 'Optional background context',
        },
        'title': {
          'type': 'string',
          'description': 'Optional title for the child session',
        },
      },
      'required': ['description', 'prompt', 'subagent_type'],
    },
    execute: (input, ctx) async {
      final description = input['description'] as String?;
      final prompt = input['prompt'] as String?;
      final subagentType = input['subagent_type'] as String?;
      final taskId = input['task_id'] as String?;
      final background = input['background'] as String?;
      final titleInput = input['title'] as String?;

      if (description == null ||
          description.isEmpty ||
          prompt == null ||
          prompt.isEmpty ||
          subagentType == null ||
          subagentType.isEmpty) {
        return ToolOutput(
          'Error: Missing required fields',
          metadata: {'error': true},
        );
      }

      final sessionId = ctx.sessionId;
      if (sessionId == null) {
        return ToolOutput(
          'Error: Missing session ID',
          metadata: {'error': true},
        );
      }

      final agent = AgentRegistry().get(subagentType);
      if (agent == null) {
        return ToolOutput(
          'Error: Unknown agent type "$subagentType"',
          metadata: {'error': true},
        );
      }

      await ctx.ask(
        permission: 'task',
        patterns: [subagentType, agent.name],
        metadata: {
          'description': description,
          'subagent_type': subagentType,
          if (taskId != null && taskId.isNotEmpty) 'task_id': taskId,
        },
      );

      final runner = currentSessionRunner?.runner;
      if (runner == null) {
        return ToolOutput(
          'Error: No session runner available for task delegation. '
          'Task tool requires an active parent session to create child sessions.',
          metadata: {'error': true},
        );
      }

      final effectiveToolRegistry = toolRegistry;
      if (effectiveToolRegistry == null) {
        return ToolOutput(
          'Error: ToolRegistry not available for task delegation',
          metadata: {'error': true},
        );
      }
      final ToolSet subagentTools = deriveSubagentTools(effectiveToolRegistry);

      final systemContent = background != null && background.isNotEmpty
          ? '${agent.systemPrompt ?? "You are a helpful assistant."}\n\nBackground: $background'
          : agent.systemPrompt ?? 'You are a helpful assistant.';

      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemContent},
        {'role': 'user', 'content': prompt},
      ];

      final effectiveChatAiService = chatAiService;
      if (effectiveChatAiService == null) {
        return ToolOutput(
          'Error: ChatAiService not available for task delegation',
          metadata: {'error': true},
        );
      }

      final currentModel = effectiveChatAiService.currentModel;
      if (currentModel == null) {
        return ToolOutput(
          'Error: No model selected in ChatAiService',
          metadata: {'error': true},
        );
      }

      final temperatureToUse = effectiveChatAiService.currentTemperature ?? 0.7;

      final childResult = await runner.runTaskInChild(
        parentSessionId: _toSessionId(sessionId),
        taskPrompt: prompt,
        streamFn: (child) async {
          await chatAiService!.streamChatCompletion(
            messages: messages,
            model: currentModel,
            temperature: temperatureToUse,
            tools: subagentTools,
            maxSteps: agent.maxSteps,
            onChunk: child.onChunk,
            onReasoning: child.onReasoning,
            onToolStart: child.onToolStart,
            onToolEnd: child.onToolEnd,
            onToolError: (toolCallId, toolName, error) {
              child.onError(Exception(error));
            },
            onCompletion: (content) async {
              await child.onCompletion(
                content: content,
                reasoning: null,
                model: currentModel,
              );
            },
          );
        },
        agent: subagentType,
        title: titleInput,
        taskId: taskId,
        abortSignal: ctx.abortSignal,
      );

      final effectiveTaskId = taskId ?? 'task_${_toSessionId(sessionId).value}';

      final xml = _buildTaskXml(
        sessionId: sessionId,
        taskId: effectiveTaskId,
        agent: agent.name,
        state: childResult.aborted ? 'cancelled' : 'completed',
        summary: childResult.output,
        content: childResult.output,
      );
      return ToolOutput(
        xml,
        metadata: {
          'task_id': effectiveTaskId,
          'subagent_type': subagentType,
          'agent_name': agent.name,
          'description': description,
          'session_id': sessionId,
          if (childResult.aborted) 'aborted': true,
        },
      );
    },
  );
}

SessionID _toSessionId(String raw) {
  final value = raw.startsWith('ses_') ? raw : 'ses_$raw';
  return SessionID.fromString(value);
}

ToolSet deriveSubagentTools(ToolRegistry registry) {
  final allTools = registry.toSDKTools();
  final result = <String, Tool<dynamic, dynamic>>{};
  for (final entry in allTools.entries) {
    if (!_subagentDeniedTools.contains(entry.key)) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}
