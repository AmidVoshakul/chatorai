import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/task.dart';
import 'package:chatorai/core/tools/built_in/task_shared.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';

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

SessionRunnerHolder _makeRunnerHolder([String result = 'mock task result']) {
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
      sessionId: SessionID.fromString('ses_mock_child'),
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
    currentSessionRunner: _makeRunnerHolder(runnerResult),
  );
}

ToolContext _mockCtx({String? sessionId}) {
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: sessionId ?? 'test-session',
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {},
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
  );
}

void main() {
  setUpAll(() async {
    registerFallbackValue(SessionID.create());
    await AgentRegistry().init();
  });

  group('task tool', () {
    test('description is non-empty', () {
      final tool = createTaskTool();
      expect(tool.description, isNotEmpty);
    });

    test(
      'inputSchema has required description, prompt, subagent_type fields',
      () {
        final tool = createTaskTool();
        final schema = tool.inputSchema;
        final properties = schema['properties'] as Map<String, dynamic>;
        expect(properties.containsKey('description'), isTrue);
        expect(properties.containsKey('prompt'), isTrue);
        expect(properties.containsKey('subagent_type'), isTrue);
        expect((schema['required'] as List).contains('description'), isTrue);
        expect((schema['required'] as List).contains('prompt'), isTrue);
        expect((schema['required'] as List).contains('subagent_type'), isTrue);
      },
    );

    test('execute with missing required fields returns error', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'test task',
        'prompt': 'do something',
      }, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute creates task result with session ID', () async {
      final tool = _makeTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Simple task',
        'prompt': 'Say hello',
        'subagent_type': 'general',
      }, ctx);

      expect(output.metadata?['session_id'], isNotNull);
    });

    test('execute includes description and subagent_type in result', () async {
      final tool = _makeTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'My test task',
        'prompt': 'Do work',
        'subagent_type': 'general',
      }, ctx);

      expect(output.metadata?['description'], equals('My test task'));
      expect(output.metadata?['subagent_type'], equals('general'));
    });

    group('task tool output format', () {
      final testCases = <_XmlTestCase>[
        _XmlTestCase(
          name: 'output contains runner result',
          expectedSubstring: 'mock task result',
        ),
        _XmlTestCase(
          name: 'output contains custom summary text',
          runnerResult: 'My summary text',
          description: 'My summary text',
          expectedSubstring: 'My summary text',
        ),
        _XmlTestCase(
          name: 'output includes task_id in metadata when provided',
          inputOverrides: {'task_id': 'my-custom-id-42'},
          metadataAssertions: {'task_id': 'my-custom-id-42'},
        ),
        _XmlTestCase(
          name: 'output includes session_id in metadata',
          sessionId: 'sess-abc-123',
        ),
        _XmlTestCase(
          name: 'output auto-generates task_id in metadata when not provided',
          metadataAssertions: {'task_id': 'task_test-call-id'},
        ),
      ];

      for (final tc in testCases) {
        test(tc.name, () async {
          final tool = _makeTaskTool(runnerResult: tc.runnerResult);
          final ctx = _mockCtx(sessionId: tc.sessionId);

          final input = <String, dynamic>{
            'description': tc.description,
            'prompt': 'Test',
            'subagent_type': 'general',
            ...tc.inputOverrides,
          };

          final output = await tool.execute(input, ctx);

          if (tc.expectedSubstring != null) {
            expect(output.output, contains(tc.expectedSubstring!));
          }
          if (tc.sessionId != null) {
            expect(output.metadata?['session_id'], equals(tc.sessionId));
          }
          for (final entry in tc.metadataAssertions.entries) {
            expect(output.metadata?[entry.key], entry.value);
          }
        });
      }
    });

    group('error when no runner', () {
      test('returns error when no currentSessionRunner provided', () async {
        final tool = createTaskTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'description': 'No runner',
          'prompt': 'Test',
          'subagent_type': 'general',
        }, ctx);

        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('No session runner available'));
      });
    });

    group('deriveSubagentTools', () {
      test('excludes task and todowrite from subagent tool set', () {
        final registry = ToolRegistry(PermissionService(), PermissionRuleset());
        registry.register(
          ToolDef(
            id: 'read',
            description: 'Mock read',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-read'),
          ),
        );
        registry.register(
          ToolDef(
            id: 'edit',
            description: 'Mock edit',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-edit'),
          ),
        );
        registry.register(
          ToolDef(
            id: 'task',
            description: 'Mock task',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-task'),
          ),
        );
        registry.register(
          ToolDef(
            id: 'todowrite',
            description: 'Mock todowrite',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-todowrite'),
          ),
        );
        registry.register(
          ToolDef(
            id: 'glob',
            description: 'Mock glob',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-glob'),
          ),
        );

        final subagentTools = deriveSubagentTools(registry);

        expect(subagentTools.containsKey('task'), isFalse);
        expect(subagentTools.containsKey('todowrite'), isFalse);
        expect(subagentTools.containsKey('read'), isTrue);
        expect(subagentTools.containsKey('edit'), isTrue);
        expect(subagentTools.containsKey('glob'), isTrue);
      });

      test('returns empty map when registry has only denied tools', () {
        final registry = ToolRegistry(PermissionService(), PermissionRuleset());
        registry.register(
          ToolDef(
            id: 'task',
            description: 'Mock task',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-task'),
          ),
        );
        registry.register(
          ToolDef(
            id: 'todowrite',
            description: 'Mock todowrite',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-todowrite'),
          ),
        );

        final subagentTools = deriveSubagentTools(registry);

        expect(subagentTools, isEmpty);
      });

      test('preserves all non-denied tools', () {
        final registry = ToolRegistry(PermissionService(), PermissionRuleset());
        registry.register(
          ToolDef(
            id: 'shell',
            description: 'Mock shell',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-shell'),
          ),
        );
        registry.register(
          ToolDef(
            id: 'read',
            description: 'Mock read',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-read'),
          ),
        );
        registry.register(
          ToolDef(
            id: 'write',
            description: 'Mock write',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-write'),
          ),
        );
        registry.register(
          ToolDef(
            id: 'grep',
            description: 'Mock grep',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-grep'),
          ),
        );

        final subagentTools = deriveSubagentTools(registry);

        expect(subagentTools.length, equals(4));
        expect(subagentTools.containsKey('shell'), isTrue);
        expect(subagentTools.containsKey('read'), isTrue);
        expect(subagentTools.containsKey('write'), isTrue);
        expect(subagentTools.containsKey('grep'), isTrue);
      });
    });
  });
}

class _XmlTestCase {
  final String name;
  final String runnerResult;
  final String? sessionId;
  final String description;
  final Map<String, dynamic> inputOverrides;
  final String? expectedSubstring;
  final Map<String, dynamic> metadataAssertions;

  _XmlTestCase({
    required this.name,
    this.runnerResult = 'mock task result',
    this.sessionId,
    this.description = 'Format test',
    this.inputOverrides = const {},
    this.expectedSubstring,
    this.metadataAssertions = const {},
  });
}
