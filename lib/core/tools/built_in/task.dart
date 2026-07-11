import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';
import 'package:chatorai/shared/utils/logger.dart';

const _subagentDeniedTools = {'task', 'todowrite'};

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

String _normalizeSessionId(String id) {
  if (id.startsWith('ses_')) return id;
  return 'ses_$id';
}

ToolDef createTaskTool({
  ChatAiService? chatAiService,
  ToolRegistry? toolRegistry,
  SessionRunnerHolder? currentSessionRunner,
}) {
  final delegatableAgents = AgentRegistry().getDelegatableAgents();
  final agentTypes = delegatableAgents.map((a) => a.id).toList();
  final agentDescription = agentTypes.join(', ');

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
          'description': 'Agent type: $agentDescription',
          'enum': agentTypes,
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
        return const ToolOutput(
          'Error: Missing required fields',
          metadata: {'error': true},
        );
      }

      final parentSessionId = currentSessionRunner?.parentSessionId;
      final rawSessionId = parentSessionId ?? ctx.sessionId;
      if (rawSessionId == null) {
        LogTags.chatService.logWarning(
          'TaskTool: no parent sessionId available',
        );
        return const ToolOutput(
          'Error: Missing session ID for task delegation',
          metadata: {'error': true},
        );
      }
      final normalizedSessionId = _normalizeSessionId(rawSessionId);

      final agent = AgentRegistry().get(subagentType);
      if (agent == null) {
        return ToolOutput(
          'Error: Unknown agent type "$subagentType"',
          metadata: {'error': true},
        );
      }

      if (agent.mode != AgentMode.subagent || agent.hidden) {
        return ToolOutput(
          'Error: Cannot delegate to "$subagentType": not a delegatable subagent',
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
        return const ToolOutput(
          'Error: No session runner available for task delegation. '
          'Task tool requires an active parent session to create child sessions.',
          metadata: {'error': true},
        );
      }

      final effectiveToolRegistry = toolRegistry;
      if (effectiveToolRegistry == null) {
        return const ToolOutput(
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
        return const ToolOutput(
          'Error: ChatAiService not available for task delegation',
          metadata: {'error': true},
        );
      }

      final currentModel = effectiveChatAiService.currentModel;
      final childModel = agent.model ?? currentModel;
      if (childModel == null) {
        return const ToolOutput(
          'Error: No model selected in ChatAiService',
          metadata: {'error': true},
        );
      }

      final temperatureToUse = effectiveChatAiService.currentTemperature ?? 0.7;

      final childResult = await runner.runTaskInChild(
        parentSessionId: SessionID.fromString(normalizedSessionId),
        taskPrompt: prompt,
        agent: subagentType,
        modelRef: childModel,
        title: titleInput ?? description,
        taskId: taskId,
        holder: currentSessionRunner,
        streamFn: (child) async {
          LogTags.chatService.logInfo(
            'TaskTool: child stream starting agent=$subagentType parent=$normalizedSessionId child=${child.sessionId.value}',
          );
          var lastTokensInput = 0;
          var lastTokensOutput = 0;
          var lastTokensCacheRead = 0;
          var lastTokensCacheWrite = 0;
          await chatAiService!.runChildCompletion(
            messages: messages,
            model: childModel,
            temperature: temperatureToUse,
            tools: subagentTools,
            maxSteps: agent.maxSteps ?? unlimitedMaxSteps,
            onUsage: (input, output, cacheRead, cacheWrite) {
              lastTokensInput = input;
              lastTokensOutput = output;
              lastTokensCacheRead = cacheRead;
              lastTokensCacheWrite = cacheWrite;
            },
            onChunk: child.onChunk,
            onReasoning: child.onReasoning,
            onToolStart: (toolCallId, toolName, input) async {
              await child.onToolStart(toolCallId, toolName, input);
              final title =
                  input['command'] as String? ??
                  input['query'] as String? ??
                  input['filePath'] as String? ??
                  input['path'] as String?;
              currentSessionRunner?.onChildToolEvent?.call(toolName, title);
              return;
            },
            onToolEnd: (toolCallId, toolName, result) async {
              await child.onToolEnd(toolCallId, toolName, result);
              return;
            },
            onToolError: (toolCallId, toolName, error) async {
              await child.onError(Exception(error));
              return;
            },
            onCompletion: (content) async {
              await child.onCompletion(
                content: content,
                reasoning: null,
                model: childModel,
                tokensInput: lastTokensInput,
                tokensOutput: lastTokensOutput,
                tokensCacheRead: lastTokensCacheRead,
                tokensCacheWrite: lastTokensCacheWrite,
              );
            },
          );
        },
      );

      final childTaskId = taskId ?? 'task_${childResult.sessionId.value}';

      final xml = _buildTaskXml(
        sessionId: rawSessionId,
        taskId: childTaskId,
        agent: agent.name,
        state: childResult.aborted ? 'cancelled' : 'completed',
        summary: childResult.output,
        content: childResult.output,
      );
      LogTags.chatService.logInfo(
        'TaskTool: child finished agent=$subagentType aborted=${childResult.aborted} outputLen=${childResult.output.length}',
      );
      return ToolOutput(
        xml,
        metadata: {
          'task_id': childTaskId,
          'subagent_type': subagentType,
          'agent_name': agent.name,
          'description': description,
          'session_id': rawSessionId,
          if (childResult.aborted) 'aborted': true,
        },
      );
    },
  );
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
