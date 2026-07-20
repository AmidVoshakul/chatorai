import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/task_container.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';

class _MockSessionRunner extends Mock implements SessionRunner {}

class _MockChatAiService extends Mock implements ChatAiService {}

/// Builds a holder whose runTaskInChild resolves with a controllable, delayed
/// result. [results] maps child index -> (output, fail, delayMs). This lets us
/// assert parallel execution and partial-failure handling.
SessionRunnerHolder _makeRunnerHolder(Map<int, (String, bool, int)> results) {
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
  ).thenAnswer((invocation) async {
    final partId = invocation.namedArguments[#taskPartId] as String? ?? '';
    final index = int.tryParse(partId.replaceFirst('container_task_', '')) ?? 0;
    final (output, fail, delayMs) = results[index] ?? ('ok', false, 0);
    await Future<void>.delayed(Duration(milliseconds: delayMs));
    if (fail) throw StateError(output);
    return TaskChildResult(output, sessionId: SessionID.create());
  });
  return SessionRunnerHolder(mock);
}

ToolDef _makeContainerTool(Map<int, (String, bool, int)> results) {
  final registry = ToolRegistry(PermissionService(), PermissionRuleset());
  final mockChat = _MockChatAiService();
  when(() => mockChat.currentModel).thenReturn('mock-model');
  when(() => mockChat.currentTemperature).thenReturn(0.7);
  return createTaskContainerTool(
    chatAiService: mockChat,
    toolRegistry: registry,
    currentSessionRunner: _makeRunnerHolder(results),
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

const _agent = 'general';

void main() {
  setUpAll(() async {
    registerFallbackValue(SessionID.create());
    await AgentRegistry().init();
  });

  group('task_container tool', () {
    test('inputSchema requires a non-empty tasks list', () {
      final tool = createTaskContainerTool();
      final schema = tool.inputSchema;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('tasks'), isTrue);
      expect((schema['required'] as List).contains('tasks'), isTrue);
    });

    test('empty tasks list returns error', () async {
      final tool = _makeContainerTool({});
      final ctx = _mockCtx();
      final output = await tool.execute({'tasks': []}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('missing tasks key returns error', () async {
      final tool = _makeContainerTool({});
      final ctx = _mockCtx();
      final output = await tool.execute({}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('aggregates all task outputs into one result', () async {
      final tool = _makeContainerTool({
        0: ('result A', false, 10),
        1: ('result B', false, 10),
        2: ('result C', false, 10),
      });
      final ctx = _mockCtx();
      final output = await tool.execute({
        'tasks': [
          {
            'description': 'task one',
            'prompt': 'do one',
            'subagent_type': _agent,
          },
          {
            'description': 'task two',
            'prompt': 'do two',
            'subagent_type': _agent,
          },
          {
            'description': 'task three',
            'prompt': 'do three',
            'subagent_type': _agent,
          },
        ],
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['task_count'], 3);
      expect(output.metadata?['failed_count'], 0);
      expect(output.output, contains('result A'));
      expect(output.output, contains('result B'));
      expect(output.output, contains('result C'));
      expect(output.metadata?['aggregated'], isTrue);
    });

    test('runs tasks in parallel (total time < sum of delays)', () async {
      // Three tasks each delayed 100ms. Sequential would be ~300ms; parallel
      // should finish well under that.
      final tool = _makeContainerTool({
        0: ('a', false, 100),
        1: ('b', false, 100),
        2: ('c', false, 100),
      });
      final ctx = _mockCtx();
      final sw = Stopwatch()..start();
      await tool.execute({
        'tasks': [
          {'description': 't1', 'prompt': 'p1', 'subagent_type': _agent},
          {'description': 't2', 'prompt': 'p2', 'subagent_type': _agent},
          {'description': 't3', 'prompt': 'p3', 'subagent_type': _agent},
        ],
      }, ctx);
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(250));
    });

    test(
      'partial failure: failed task marked, others still returned',
      () async {
        final tool = _makeContainerTool({
          0: ('good result', false, 10),
          1: ('boom', true, 10),
          2: ('another good', false, 10),
        });
        final ctx = _mockCtx();
        final output = await tool.execute({
          'tasks': [
            {'description': 'ok', 'prompt': 'p1', 'subagent_type': _agent},
            {'description': 'bad', 'prompt': 'p2', 'subagent_type': _agent},
            {'description': 'ok2', 'prompt': 'p3', 'subagent_type': _agent},
          ],
        }, ctx);

        expect(output.metadata?['task_count'], 3);
        expect(output.metadata?['failed_count'], 1);
        expect(output.output, contains('good result'));
        expect(output.output, contains('another good'));
        expect(output.output, contains('failed'));
        expect(output.output, isNot(contains('boom')));
      },
    );

    test(
      'returns a single aggregated result, not a delegated marker',
      () async {
        final tool = _makeContainerTool({0: ('only result', false, 5)});
        final ctx = _mockCtx();
        final output = await tool.execute({
          'tasks': [
            {'description': 'single', 'prompt': 'p', 'subagent_type': _agent},
          ],
        }, ctx);

        expect(output.metadata?['delegated'], isNull);
        expect(output.output, contains('only result'));
        expect(output.output, isNot(contains('Delegated')));
      },
    );
  });
}
