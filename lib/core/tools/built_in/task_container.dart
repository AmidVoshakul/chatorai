import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';
import 'package:chatorai/shared/utils/logger.dart';

import 'task_shared.dart';

/// Result of a single task within the container: either the child session's
/// aggregated output, or a failure marker if the child threw.
class _ContainerTaskOutcome {
  final String taskId;
  final String agentName;
  final String output;
  final bool failed;

  const _ContainerTaskOutcome({
    required this.taskId,
    required this.agentName,
    required this.output,
    this.failed = false,
  });
}

/// Invisible-to-chat container: the model calls it with a list of tasks, it
/// runs each as its own child session in parallel via [Future.wait], waits for
/// all of them, and returns one aggregated result. The header of this tool is
/// suppressed in the chat UI (see chat_screen_streaming.dart) — only the
/// individual TaskPart cards (with live tool titles) are shown, exactly like a
/// set of ordinary delegated `task` calls.
ToolDef createTaskContainerTool({
  ChatAiService? chatAiService,
  ToolRegistry? toolRegistry,
  SessionRunnerHolder? currentSessionRunner,
}) {
  final delegatableAgents = AgentRegistry().getDelegatableAgents();
  final agentTypes = delegatableAgents.map((a) => a.id).toList();
  final agentDescription = agentTypes.join(', ');

  return ToolDef(
    id: 'task_container',
    description:
        'Execute multiple independent subagent tasks in parallel and return '
        'their aggregated results as a single response. Pass a list of tasks; '
        'each runs as its own isolated child session concurrently. The tool '
        'waits for every task to finish before returning, so the parent always '
        'receives the complete results.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'tasks': {
          'type': 'array',
          'description':
              'List of independent tasks to run in parallel. Each task is '
              'delegated to a specialized subagent.',
          'items': {
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
        },
      },
      'required': ['tasks'],
    },
    execute: (input, ctx) async {
      final rawTasks = input['tasks'];
      if (rawTasks is! List || rawTasks.isEmpty) {
        return const ToolOutput(
          'Error: "tasks" must be a non-empty list of task objects.',
          metadata: {'error': true},
        );
      }

      final parentSessionId = currentSessionRunner?.parentSessionId;
      final rawSessionId = parentSessionId ?? ctx.sessionId;
      if (rawSessionId == null) {
        LogTags.chatService.logWarning(
          'TaskContainer: no parent sessionId available',
        );
        return const ToolOutput(
          'Error: Missing session ID for task delegation',
          metadata: {'error': true},
        );
      }
      final normalizedSessionId = normalizeSessionId(rawSessionId);

      final runner = currentSessionRunner?.runner;
      if (runner == null) {
        return const ToolOutput(
          'Error: No session runner available for task delegation.',
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
      final subagentTools = deriveSubagentTools(effectiveToolRegistry);

      final effectiveChatAiService = chatAiService;
      if (effectiveChatAiService == null) {
        return const ToolOutput(
          'Error: ChatAiService not available for task delegation',
          metadata: {'error': true},
        );
      }

      final currentModel = effectiveChatAiService.currentModel;
      final temperatureToUse = effectiveChatAiService.currentTemperature ?? 0.7;

      // Build a per-task executor. Each task launches its own child session
      // through runTaskInChild. Errors are caught per-task so one failure does
      // not abort the whole parallel batch (partial result + failure marker).
      Future<_ContainerTaskOutcome> runOne(
        Map<String, dynamic> task,
        int index,
      ) async {
        final description = task['description'] as String?;
        final prompt = task['prompt'] as String?;
        final subagentType = task['subagent_type'] as String?;
        final taskId = task['task_id'] as String?;
        final background = task['background'] as String?;
        final titleInput = task['title'] as String?;

        final effectiveTaskId = taskId ?? 'container_task_$index';

        if (description == null ||
            prompt == null ||
            subagentType == null ||
            subagentType.isEmpty) {
          return _ContainerTaskOutcome(
            taskId: effectiveTaskId,
            agentName: subagentType ?? 'unknown',
            output:
                'Error: Missing required fields (description, prompt, '
                'subagent_type).',
            failed: true,
          );
        }

        final agent = AgentRegistry().get(subagentType);
        if (agent == null) {
          return _ContainerTaskOutcome(
            taskId: effectiveTaskId,
            agentName: subagentType,
            output: 'Error: Unknown agent type "$subagentType".',
            failed: true,
          );
        }
        if (agent.mode != AgentMode.subagent || agent.hidden) {
          return _ContainerTaskOutcome(
            taskId: effectiveTaskId,
            agentName: agent.name,
            output:
                'Error: Cannot delegate to "$subagentType": not a '
                'delegatable subagent.',
            failed: true,
          );
        }

        final childModel = agent.model ?? currentModel;
        if (childModel == null) {
          return _ContainerTaskOutcome(
            taskId: effectiveTaskId,
            agentName: agent.name,
            output: 'Error: No model selected in ChatAiService.',
            failed: true,
          );
        }

        final systemContent = background != null && background.isNotEmpty
            ? '${agent.systemPrompt ?? "You are a helpful assistant."}\n\n'
                  'Background: $background'
            : agent.systemPrompt ?? 'You are a helpful assistant.';

        final messages = <Map<String, dynamic>>[
          {'role': 'system', 'content': systemContent},
          {'role': 'user', 'content': prompt},
        ];

        try {
          final result = await runner.runTaskInChild(
            parentSessionId: SessionID.fromString(normalizedSessionId),
            taskPrompt: prompt,
            agent: subagentType,
            modelRef: childModel,
            title: titleInput ?? description,
            taskId: taskId,
            taskPartId: effectiveTaskId,
            holder: currentSessionRunner,
            abortSignal: ctx.abortSignal,
            streamFn: (child) async {
              LogTags.chatService.logInfo(
                'TaskContainer: child stream starting agent=$subagentType '
                'parent=$normalizedSessionId child=${child.sessionId.value}',
              );
              var lastTokensInput = 0;
              var lastTokensOutput = 0;
              var lastTokensCacheRead = 0;
              var lastTokensCacheWrite = 0;
              var lastTokensReasoning = 0;
              await chatAiService!.runChildCompletion(
                messages: messages,
                model: childModel,
                temperature: temperatureToUse,
                tools: subagentTools,
                maxSteps: agent.maxSteps ?? unlimitedMaxSteps,
                abortSignal: ctx.abortSignal,
                onUsage: (input, output, cacheRead, cacheWrite, reasoning) {
                  lastTokensInput = input;
                  lastTokensOutput = output;
                  lastTokensCacheRead = cacheRead;
                  lastTokensCacheWrite = cacheWrite;
                  lastTokensReasoning = reasoning;
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
                  currentSessionRunner?.onChildToolEvent?.call(
                    child.sessionId.value,
                    toolName,
                    title,
                  );
                  return;
                },
                onToolEnd: (toolCallId, toolName, result) async {
                  await child.onToolEnd(toolCallId, toolName, result);
                  return;
                },
                onToolError: (toolCallId, toolName, error) async {
                  // Use onToolError (not onError) to mark the tool as failed
                  // WITHOUT finalizing the child session. This lets the agent
                  // recover and continue working after a tool error.
                  await child.onToolError(toolCallId, toolName, error);
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
                    tokensReasoning: lastTokensReasoning,
                  );
                },
              );
            },
          );
          return _ContainerTaskOutcome(
            taskId: effectiveTaskId,
            agentName: agent.name,
            output: result.output,
          );
        } catch (e) {
          LogTags.chatService.logWarning(
            'TaskContainer: child failed agent=$subagentType '
            'task=$effectiveTaskId error=$e',
          );
          return _ContainerTaskOutcome(
            taskId: effectiveTaskId,
            agentName: agent.name,
            output: '(task failed)',
            failed: true,
          );
        }
      }

      // Launch all tasks concurrently and WAIT for every one of them. The SDK
      // holds this single tool call open until execute returns, so the parent
      // cannot finalize its answer before the aggregated results are ready.
      final outcomes = await Future.wait(
        rawTasks.asMap().entries.map((e) => runOne(e.value, e.key)),
      );

      final buffer = StringBuffer();
      for (final outcome in outcomes) {
        buffer.writeln(
          '<task id="${outcome.taskId}" agent="${outcome.agentName}" '
          'state="${outcome.failed ? 'failed' : 'completed'}">',
        );
        buffer.writeln(outcome.output);
        buffer.writeln('</task>');
      }

      return ToolOutput(
        buffer.toString(),
        metadata: {
          'task_count': outcomes.length,
          'failed_count': outcomes.where((o) => o.failed).length,
          'session_id': rawSessionId,
          'aggregated': true,
        },
      );
    },
  );
}
