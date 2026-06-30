import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/task.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';

class _MockSessionRunner extends Mock implements SessionRunner {}

class _MockChatAiService extends Mock implements ChatAiService {}

SessionRunnerHolder _makeRunnerHolder([String result = 'mock task result']) {
  final mock = _MockSessionRunner();
  when(
    () => mock.runTaskInChild(
      parentSessionId: any(named: 'parentSessionId'),
      taskPrompt: any(named: 'taskPrompt'),
      streamFn: any(named: 'streamFn'),
      agent: any(named: 'agent'),
      title: any(named: 'title'),
      taskId: any(named: 'taskId'),
      holder: any(named: 'holder'),
    ),
  ).thenAnswer((_) async => TaskChildResult(result, sessionId: SessionID.fromString('ses_mock_child')));
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
  setUpAll(() {
    registerFallbackValue(SessionID.create());
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

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('session_id'));
      expect(output.metadata?['session_id'], isNotNull);
    });

    test('execute includes description and subagent_type in result', () async {
      final tool = _makeTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'My test task',
        'prompt': 'Do work',
        'subagent_type': 'build',
      }, ctx);

      expect(output.metadata?['description'], equals('My test task'));
      expect(output.metadata?['subagent_type'], equals('build'));
    });

    group('XML output format', () {
      final testCases = <_XmlTestCase>[
        _XmlTestCase(
          name: 'output contains state="completed" attribute',
          expectedSubstring: 'state="completed"',
        ),
        _XmlTestCase(
          name: 'output contains <summary> tag',
          runnerResult: 'My summary text',
          description: 'My summary text',
          expectedSubstring: '<summary>My summary text</summary>',
        ),
        _XmlTestCase(
          name: 'output contains <task_result> tag',
          expectedSubstring: '<task_result>',
          expectedEndSubstring: '</task_result>',
        ),
        _XmlTestCase(
          name: 'output wraps in <task> root element',
          expectedStartsWith: '<task ',
          expectedEndsWith: '</task>',
        ),
        _XmlTestCase(
          name: 'output includes session_id attribute in <task> tag',
          sessionId: 'sess-abc-123',
          expectedSubstring: 'session_id="sess-abc-123"',
        ),
        _XmlTestCase(
          name: 'output includes task_id when provided',
          inputOverrides: {'task_id': 'my-custom-id-42'},
          expectedSubstring: 'id="my-custom-id-42"',
        ),
        _XmlTestCase(
          name: 'output auto-generates id when task_id not provided',
          expectedSubstring: 'id="task_',
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

          final substring = tc.expectedSubstring;
          final startsWithStr = tc.expectedStartsWith;
          final endsWithStr = tc.expectedEndsWith;
          final endSubstring = tc.expectedEndSubstring;
          if (substring != null) {
            expect(output.output, contains(substring));
          }
          if (startsWithStr != null) {
            expect(output.output, startsWith(startsWithStr));
          }
          if (endsWithStr != null) {
            expect(output.output, endsWith(endsWithStr));
          }
          if (endSubstring != null) {
            expect(output.output, contains(endSubstring));
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
            id: 'bash',
            description: 'Mock bash',
            inputSchema: const {'type': 'object'},
            execute: (input, ctx) async => ToolOutput('result-bash'),
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
        expect(subagentTools.containsKey('bash'), isTrue);
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
  final String? expectedStartsWith;
  final String? expectedEndsWith;
  final String? expectedEndSubstring;

  _XmlTestCase({
    required this.name,
    this.runnerResult = 'mock task result',
    this.sessionId,
    this.description = 'Format test',
    this.inputOverrides = const {},
    this.expectedSubstring,
    this.expectedStartsWith,
    this.expectedEndsWith,
    this.expectedEndSubstring,
  });
}
