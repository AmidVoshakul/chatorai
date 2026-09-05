import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/tools/built_in/task.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionRunner extends Mock implements SessionRunner {}

class _MockChatAiService extends Mock implements ChatAiService {
  @override
  Future<void> runChildCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
    required Future<void> Function(String) onChunk,
    required Future<void> Function(String) onReasoning,
    Future<void> Function()? onReasoningEnd,
    required Future<void> Function(String) onCompletion,
    sdk.ToolSet tools = const {},
    ToolStartCallback? onToolStart,
    ToolEndCallback? onToolEnd,
    ToolErrorCallback? onToolError,
    UsageCallback? onUsage,
    int maxSteps = 5,
    String? sessionId,
    sdk.CancellationToken? abortSignal,
  }) async {
    await onChunk('mock task result');
    await onCompletion('mock task result');
  }

  @override
  Future<void> runSubagentCompletion({
    required SessionRunnerSession child,
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
    required String sessionId,
    required sdk.ToolSet tools,
    required int maxSteps,
    sdk.CancellationToken? abortSignal,
    void Function(
      int tokensInput,
      int tokensOutput,
      int tokensCacheRead,
      int tokensCacheWrite,
      int tokensReasoning,
    )?
    onUsage,
    void Function(String childSessionId, String toolName, String? title)?
    onChildToolTitle,
  }) {
    return runChildCompletion(
      messages: messages,
      model: model,
      temperature: temperature,
      sessionId: sessionId,
      tools: tools,
      maxSteps: maxSteps,
      abortSignal: abortSignal,
      onUsage: onUsage == null
          ? null
          : (input, output, cacheRead, cacheWrite, reasoning, _) =>
                onUsage(input, output, cacheRead, cacheWrite, reasoning),
      onChunk: child.onChunk,
      onReasoning: child.onReasoning,
      onReasoningEnd: child.onReasoningEnd,
      onToolStart: child.onToolStart,
      onToolEnd: child.onToolEnd,
      onToolError: child.onToolError,
      onCompletion: (content) =>
          child.onCompletion(content: content, reasoning: null, model: model),
    );
  }
}

/// Creates a [SessionRunnerHolder] whose mock runner returns
/// [TaskChildResult] with the given [result] and [aborted] flag.
SessionRunnerHolder _makeRunnerHolder({
  String result = 'mock task result',
  bool aborted = false,
}) {
  final mock = _MockSessionRunner();
  when(
    () => mock.runTaskInChild(
      parentSessionId: any(named: 'parentSessionId'),
      taskPrompt: any(named: 'taskPrompt'),
      streamFn: any(named: 'streamFn'),
      agent: any(named: 'agent'),
      modelRef: any(named: 'modelRef'),
      title: any(named: 'title'),
      taskId: any(named: 'taskId'),
      taskPartId: any(named: 'taskPartId'),
      holder: any(named: 'holder'),
      abortSignal: any(named: 'abortSignal'),
    ),
  ).thenAnswer(
    (_) async => TaskChildResult(
      result,
      sessionId: SessionID.fromString('ses_mock'),
      aborted: aborted,
    ),
  );
  return SessionRunnerHolder(mock);
}

ToolDef _makeTaskTool({String runnerResult = 'mock task result'}) {
  final registry = ToolRegistry(PermissionService(), PermissionRuleset());
  final mockChat = _MockChatAiService();
  when(() => mockChat.currentModel).thenReturn('mock-model');
  when(() => mockChat.currentTemperature).thenReturn(0.7);
  return createTaskTool(
    chatAiService: mockChat,
    toolRegistry: registry,
    currentSessionRunner: _makeRunnerHolder(result: runnerResult),
  );
}

ToolContext _mockCtx({String? sessionId, sdk.CancellationToken? abortSignal}) {
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: sessionId ?? 'test-session',
    abortSignal: abortSignal,
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {},
    askQuestion:
        ({
          required String question,
          options = const [],
          bool multiple = false,
        }) async => '',
  );
}

void main() {
  setUpAll(() async {
    registerFallbackValue(SessionID.create());
    await AgentRegistry().init();
  });

  // ---------------------------------------------------------------------------
  // 1. TaskChildResult
  // ---------------------------------------------------------------------------
  group('TaskChildResult', () {
    test('constructor sets output correctly', () {
      final result = TaskChildResult(
        'hello world',
        sessionId: SessionID.fromString('ses_mock'),
      );
      expect(result.output, equals('hello world'));
    });

    test('constructor sets aborted flag when true', () {
      final result = TaskChildResult(
        'partial output',
        sessionId: SessionID.fromString('ses_mock'),
        aborted: true,
      );
      expect(result.aborted, isTrue);
    });

    test('default aborted is false', () {
      final result = TaskChildResult(
        'complete output',
        sessionId: SessionID.fromString('ses_mock'),
      );
      expect(result.aborted, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. task.dart cancel handling
  // ---------------------------------------------------------------------------
  group('task.dart cancel handling', () {
    test('when childResult.aborted, XML state is cancelled', () async {
      final mockRunner = _MockSessionRunner();
      when(
        () => mockRunner.runTaskInChild(
          parentSessionId: any(named: 'parentSessionId'),
          taskPrompt: any(named: 'taskPrompt'),
          streamFn: any(named: 'streamFn'),
          agent: any(named: 'agent'),
          modelRef: any(named: 'modelRef'),
          title: any(named: 'title'),
          taskId: any(named: 'taskId'),
          taskPartId: any(named: 'taskPartId'),
          holder: any(named: 'holder'),
          abortSignal: any(named: 'abortSignal'),
        ),
      ).thenAnswer(
        (_) async => TaskChildResult(
          'partial output',
          sessionId: SessionID.fromString('ses_mock'),
          aborted: true,
        ),
      );

      final registry = ToolRegistry(PermissionService(), PermissionRuleset());
      final mockChat = _MockChatAiService();
      when(() => mockChat.currentModel).thenReturn('mock-model');
      when(() => mockChat.currentTemperature).thenReturn(0.7);

      final toolWithAbort = createTaskTool(
        chatAiService: mockChat,
        toolRegistry: registry,
        currentSessionRunner: SessionRunnerHolder(mockRunner),
      );

      final ctx = _mockCtx();
      final output = await toolWithAbort.execute({
        'description': 'Abort test',
        'prompt': 'Do work',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('(task failed)'));
    });

    test('when childResult.aborted, metadata includes error: true', () async {
      final mockRunner = _MockSessionRunner();
      when(
        () => mockRunner.runTaskInChild(
          parentSessionId: any(named: 'parentSessionId'),
          taskPrompt: any(named: 'taskPrompt'),
          streamFn: any(named: 'streamFn'),
          agent: any(named: 'agent'),
          modelRef: any(named: 'modelRef'),
          title: any(named: 'title'),
          taskId: any(named: 'taskId'),
          taskPartId: any(named: 'taskPartId'),
          holder: any(named: 'holder'),
          abortSignal: any(named: 'abortSignal'),
        ),
      ).thenAnswer(
        (_) async => TaskChildResult(
          'output',
          sessionId: SessionID.fromString('ses_mock'),
          aborted: true,
        ),
      );

      final registry = ToolRegistry(PermissionService(), PermissionRuleset());
      final mockChat = _MockChatAiService();
      when(() => mockChat.currentModel).thenReturn('mock-model');
      when(() => mockChat.currentTemperature).thenReturn(0.7);

      final toolWithAbort = createTaskTool(
        chatAiService: mockChat,
        toolRegistry: registry,
        currentSessionRunner: SessionRunnerHolder(mockRunner),
      );

      final ctx = _mockCtx();
      final output = await toolWithAbort.execute({
        'description': 'Abort meta test',
        'prompt': 'Do work',
        'subagent_type': 'general',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });

    test(
      'when childResult.aborted, output is (task failed) with error metadata',
      () async {
        final mockRunner = _MockSessionRunner();
        const partialOutput = 'This is the partial result before abort';
        when(
          () => mockRunner.runTaskInChild(
            parentSessionId: any(named: 'parentSessionId'),
            taskPrompt: any(named: 'taskPrompt'),
            streamFn: any(named: 'streamFn'),
            agent: any(named: 'agent'),
            modelRef: any(named: 'modelRef'),
            title: any(named: 'title'),
            taskId: any(named: 'taskId'),
            taskPartId: any(named: 'taskPartId'),
            holder: any(named: 'holder'),
            abortSignal: any(named: 'abortSignal'),
          ),
        ).thenAnswer(
          (_) async => TaskChildResult(
            partialOutput,
            sessionId: SessionID.fromString('ses_mock'),
            aborted: true,
          ),
        );

        final registry = ToolRegistry(PermissionService(), PermissionRuleset());
        final mockChat = _MockChatAiService();
        when(() => mockChat.currentModel).thenReturn('mock-model');
        when(() => mockChat.currentTemperature).thenReturn(0.7);

        final toolWithAbort = createTaskTool(
          chatAiService: mockChat,
          toolRegistry: registry,
          currentSessionRunner: SessionRunnerHolder(mockRunner),
        );

        final ctx = _mockCtx();
        final output = await toolWithAbort.execute({
          'description': 'Output preservation test',
          'prompt': 'Do work',
          'subagent_type': 'general',
        }, ctx);

        expect(output.output, contains('(task failed)'));
        expect(output.metadata?['error'], isTrue);
        expect(output.metadata?['aborted'], isTrue);
      },
    );

    test('normal (non-aborted) flow has state=completed', () async {
      final tool = _makeTaskTool(runnerResult: 'normal result');
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Normal task',
        'prompt': 'Do work',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('normal result'));
      expect(output.output, isNot(contains('(task failed)')));
      expect(output.metadata?['aborted'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Mock integration
  // ---------------------------------------------------------------------------
  group('mock integration with CancellationToken', () {
    test(
      'mock SessionRunner returns TaskChildResult with aborted=true',
      () async {
        final mockRunner = _MockSessionRunner();
        when(
          () => mockRunner.runTaskInChild(
            parentSessionId: any(named: 'parentSessionId'),
            taskPrompt: any(named: 'taskPrompt'),
            streamFn: any(named: 'streamFn'),
            agent: any(named: 'agent'),
            title: any(named: 'title'),
            taskId: any(named: 'taskId'),
            abortSignal: any(named: 'abortSignal'),
          ),
        ).thenAnswer(
          (_) async => TaskChildResult(
            'delegated work result',
            sessionId: SessionID.fromString('ses_mock'),
            aborted: true,
          ),
        );

        final registry = ToolRegistry(PermissionService(), PermissionRuleset());
        final mockChat = _MockChatAiService();
        when(() => mockChat.currentModel).thenReturn('mock-model');
        when(() => mockChat.currentTemperature).thenReturn(0.7);

        final tool = createTaskTool(
          chatAiService: mockChat,
          toolRegistry: registry,
          currentSessionRunner: SessionRunnerHolder(mockRunner),
        );

        final ctx = _mockCtx(sessionId: 'integration-test-session');
        final output = await tool.execute({
          'description': 'Integration abort test',
          'prompt': 'Do work that gets aborted',
          'subagent_type': 'general',
        }, ctx);

        expect(output.output, contains('(task failed)'));
        expect(output.metadata?['error'], isTrue);
        expect(
          output.metadata?['session_id'],
          equals('integration-test-session'),
        );
      },
    );

    test(
      'full pipeline: CancellationToken cancelled before execution',
      () async {
        final token = sdk.CancellationToken();
        token.cancel();

        final mockRunner = _MockSessionRunner();
        when(
          () => mockRunner.runTaskInChild(
            parentSessionId: any(named: 'parentSessionId'),
            taskPrompt: any(named: 'taskPrompt'),
            streamFn: any(named: 'streamFn'),
            agent: any(named: 'agent'),
            title: any(named: 'title'),
            taskId: any(named: 'taskId'),
            abortSignal: any(named: 'abortSignal'),
          ),
        ).thenAnswer((_) async {
          // Simulate checking the token state
          if (token.isCancelled) {
            return TaskChildResult(
              '',
              sessionId: SessionID.fromString('ses_mock'),
              aborted: true,
            );
          }
          return TaskChildResult(
            'should not reach',
            sessionId: SessionID.fromString('ses_mock'),
          );
        });

        final registry = ToolRegistry(PermissionService(), PermissionRuleset());
        final mockChat = _MockChatAiService();
        when(() => mockChat.currentModel).thenReturn('mock-model');
        when(() => mockChat.currentTemperature).thenReturn(0.7);

        final tool = createTaskTool(
          chatAiService: mockChat,
          toolRegistry: registry,
          currentSessionRunner: SessionRunnerHolder(mockRunner),
        );

        final ctx = _mockCtx(abortSignal: token);
        final output = await tool.execute({
          'description': 'Pre-cancelled token test',
          'prompt': 'Do work',
          'subagent_type': 'general',
        }, ctx);

        expect(output.output, contains('(task failed)'));
        expect(output.metadata?['error'], isTrue);
      },
    );
  });
}
