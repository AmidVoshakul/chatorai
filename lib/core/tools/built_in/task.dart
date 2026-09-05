import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';
import 'package:chatorai/shared/utils/logger.dart';

import 'task_shared.dart';

ToolDef createTaskTool({
  ChatAiService? chatAiService,
  ToolRegistry? toolRegistry,
  SessionRunnerHolder? currentSessionRunner,
}) {
  final delegatableAgents = AgentRegistry().getSubagents();
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
      final normalizedSessionId = normalizeSessionId(rawSessionId);

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
        always: ['*'],
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

      final taskPartId = taskId ?? ctx.toolCallId;

      try {
        final taskResult = await runner.runTaskInChild(
          parentSessionId: SessionID.fromString(normalizedSessionId),
          taskPrompt: prompt,
          agent: subagentType,
          modelRef: childModel,
          title: titleInput ?? description,
          taskId: taskId,
          taskPartId: taskPartId,
          holder: currentSessionRunner,
          abortSignal: ctx.abortSignal,
          streamFn: (child) async {
            LogTags.chatService.logInfo(
              'TaskTool: child stream starting agent=$subagentType parent=$normalizedSessionId child=${child.sessionId.value}',
            );
            await chatAiService!.runSubagentCompletion(
              child: child,
              messages: messages,
              model: childModel,
              temperature: temperatureToUse,
              sessionId: normalizedSessionId,
              tools: subagentTools,
              maxSteps: agent.maxSteps ?? unlimitedMaxSteps,
              abortSignal: ctx.abortSignal,
              onChildToolTitle: (childSessionId, toolName, title) {
                currentSessionRunner?.onChildToolEvent?.call(
                  childSessionId,
                  toolName,
                  title,
                );
              },
            );
            LogTags.chatService.logInfo(
              'TaskTool: child finished streaming agent=$subagentType part=$taskPartId',
            );
          },
        );
        LogTags.chatService.logInfo(
          'TaskTool: child finished agent=$subagentType part=$taskPartId',
        );
        final delegatedTaskId = taskId ?? 'task_$taskPartId';
        if (taskResult.aborted) {
          return ToolOutput(
            '(task failed)',
            metadata: {
              'task_id': delegatedTaskId,
              'subagent_type': subagentType,
              'agent_name': agent.name,
              'description': description,
              'session_id': rawSessionId,
              'delegated': false,
              'error': true,
              'aborted': true,
            },
          );
        }
        return ToolOutput(
          taskResult.output,
          metadata: {
            'task_id': delegatedTaskId,
            'subagent_type': subagentType,
            'agent_name': agent.name,
            'description': description,
            'session_id': rawSessionId,
            'delegated': false,
          },
        );
      } catch (e) {
        LogTags.chatService.logWarning(
          'TaskTool: child failed agent=$subagentType part=$taskPartId error=$e',
        );
        final delegatedTaskId = taskId ?? 'task_$taskPartId';
        return ToolOutput(
          '(task failed)',
          metadata: {
            'task_id': delegatedTaskId,
            'subagent_type': subagentType,
            'agent_name': agent.name,
            'description': description,
            'session_id': rawSessionId,
            'error': true,
            'error_message': '$e',
          },
        );
      }
    },
  );
}
