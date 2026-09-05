import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/session/event_bus.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/chat/chat/assistant_content.dart';
import 'package:chatorai/core/chat/chat/message_part.dart'
    show ToolState;
import 'package:test/test.dart';

Future<
  ({
    AppDatabase db,
    SessionRepository repository,
    SessionRunner runner,
    SessionEventBus bus,
  })
>
_createHarness() async {
  final db = AppDatabase.inMemory();
  final repository = SessionRepository(db);
  final bus = SessionEventBus();
  final runner = SessionRunner(repository, null, eventBus: bus);
  return (db: db, repository: repository, runner: runner, bus: bus);
}

Future<SessionState> _replay(
  SessionRepository repository,
  SessionID sessionId,
) async {
  final events = await repository.eventStore.getEvents(sessionId);
  return replayEvents(events);
}

void main() {
  group('Tool Execution Safety', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;
    late SessionEventBus bus;

    setUp(() async {
      final harness = await _createHarness();
      db = harness.db;
      repository = harness.repository;
      runner = harness.runner;
      bus = harness.bus;
    });

    tearDown(() async {
      bus.dispose();
      await db.close();
    });

    Future<SessionRunnerSession> _startSession() async {
      final session = await runner.startInitializedSession(
        agent: 'test',
        modelRef: 'mock/model',
      );
      return session;
    }

    // -----------------------------------------------------------------------
    // Test 1: Text + tool + text — все части сохраняются
    // -----------------------------------------------------------------------
    test('streaming preserves text before and after tool execution', () async {
      final session = await _startSession();
      final sid = session.sessionId;

      await session.onChunk('Before tool. ');
      await session.onToolStart('c1', 'todowrite', {'cmd': 'ls'});
      await session.onToolEnd('c1', 'todowrite', '{"ok":true}');
      await session.onChunk('After tool.');
      await session.onCompletion(content: 'Before tool. After tool.');

      final state = await _replay(repository, sid);
      expect(
        state.parts.whereType<AssistantText>().any(
          (p) => p.text.contains('Before tool'),
        ),
        isTrue,
      );
      expect(
        state.parts.whereType<AssistantText>().any(
          (p) => p.text.contains('After tool'),
        ),
        isTrue,
      );
      expect(
        state.parts.whereType<AssistantTool>().any(
          (p) => p.state == ToolState.completed,
        ),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // Test 2: Crash после успешного tool — результат не теряется
    // -----------------------------------------------------------------------
    test('tool result survives finalize (crash simulation)', () async {
      final session = await _startSession();
      final sid = session.sessionId;

      await session.onChunk('Thinking...');
      await session.onToolStart('c1', 'todowrite', {'cmd': 'ls'});
      await session.onToolEnd('c1', 'todowrite', 'Done');
      await session.onToolStart('c2', 'todowrite', {'cmd': 'pwd'});
      await session.onError(Exception('crash'));

      final state = await _replay(repository, sid);
      expect(
        state.parts.any(
          (p) =>
              p is AssistantTool &&
              p.callId == 'c1' &&
              p.state == ToolState.completed,
        ),
        isTrue,
        reason: 'completed tool survives crash',
      );
      expect(
        state.parts.any(
          (p) => p is AssistantText && p.text.contains('Thinking'),
        ),
        isTrue,
        reason: 'text survives crash',
      );
    });

    // -----------------------------------------------------------------------
    // Test 3: 3+ параллельных tool — все появляются
    // -----------------------------------------------------------------------
    test('parallel tool calls all appear in parts', () async {
      final session = await _startSession();
      final sid = session.sessionId;

      await session.onToolStart('ca', 'todowrite', {});
      await session.onToolEnd('ca', 'todowrite', 'A');
      await session.onToolStart('cb', 'todowrite', {});
      await session.onToolEnd('cb', 'todowrite', 'B');
      await session.onToolStart('cc', 'todowrite', {});
      await session.onToolEnd('cc', 'todowrite', 'C');
      await session.onCompletion(content: 'done');

      final state = await _replay(repository, sid);
      expect(state.parts.whereType<AssistantTool>().length, equals(3));
      expect(
        state.parts.whereType<AssistantTool>().every(
          (t) => t.state == ToolState.completed,
        ),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // Test 4: Порядок частей не меняется от порядка onToolEnd
    // -----------------------------------------------------------------------
    test('part order reflects start order, not completion order', () async {
      final session = await _startSession();
      final sid = session.sessionId;

      await session.onToolStart('ca', 'todowrite', {});
      await session.onToolStart('cb', 'todowrite', {});
      await session.onToolStart('cc', 'todowrite', {});
      await session.onToolEnd('cc', 'todowrite', 'C');
      await session.onToolEnd('cb', 'todowrite', 'B');
      await session.onToolEnd('ca', 'todowrite', 'A');
      await session.onCompletion(content: 'done');

      final state = await _replay(repository, sid);
      final tools = state.parts.whereType<AssistantTool>().toList();
      expect(tools[0].callId, 'ca');
      expect(tools[1].callId, 'cb');
      expect(tools[2].callId, 'cc');
    });

    // -----------------------------------------------------------------------
    // Test 5: Повторный запуск после сбоя — новая сессия
    // -----------------------------------------------------------------------
    test('new session after finalized streaming starts clean', () async {
      final sessionA = await _startSession();
      final sidA = sessionA.sessionId;

      await sessionA.onChunk('Message 1');
      await sessionA.onToolStart('c1', 'todowrite', {});
      await sessionA.onToolEnd('c1', 'todowrite', 'OK');
      await sessionA.onCompletion(content: 'Message 1');

      final stateA = await _replay(repository, sidA);
      expect(
        stateA.parts.length,
        greaterThan(0),
        reason: 'closed parts from ses_a survive',
      );

      final sessionB = await _startSession();
      final sidB = sessionB.sessionId;

      await sessionB.onChunk('Message 2');
      await sessionB.onToolStart('c2', 'todowrite', {});
      await sessionB.onToolEnd('c2', 'todowrite', 'OK');
      await sessionB.onCompletion(content: 'Message 2');

      final stateB = await _replay(repository, sidB);
      expect(
        stateB.parts.whereType<AssistantText>().any(
          (p) => p.text.contains('Message 2'),
        ),
        isTrue,
        reason: 'new session has its own text',
      );
    });

    // -----------------------------------------------------------------------
    // Test 6: Чередование текст → тул → текст → тул
    // -----------------------------------------------------------------------
    test(
      'interleaved text and tools maintain correct part types order',
      () async {
        final session = await _startSession();
        final sid = session.sessionId;

        await session.onChunk('Text 1\n');
        await session.onToolStart('c1', 'todowrite', {});
        await session.onToolEnd('c1', 'todowrite', 'R1');
        await session.onChunk('Text 2\n');
        await session.onToolStart('c2', 'todowrite', {});
        await session.onToolEnd('c2', 'todowrite', 'R2');
        await session.onChunk('Text 3\n');
        await session.onCompletion(content: 'Text 1\nText 2\nText 3\n');

        final state = await _replay(repository, sid);
        expect(state.parts.length, equals(5));
        expect(state.parts[0], isA<AssistantText>());
        expect(state.parts[1], isA<AssistantTool>());
        expect(state.parts[2], isA<AssistantText>());
        expect(state.parts[3], isA<AssistantTool>());
        expect(state.parts[4], isA<AssistantText>());
      },
    );

    // -----------------------------------------------------------------------
    // Test 7: Пустой результат тула не ломает состояние
    // -----------------------------------------------------------------------
    test('empty tool result produces valid part', () async {
      final session = await _startSession();
      final sid = session.sessionId;

      await session.onToolStart('c1', 'todowrite', {});
      await session.onToolEnd('c1', 'todowrite', '');
      await session.onCompletion(content: '');

      final state = await _replay(repository, sid);
      expect(
        state.parts.whereType<AssistantTool>().any((p) => p.callId == 'c1'),
        isTrue,
      );
      expect(
        state.parts.whereType<AssistantTool>().any(
          (p) => p.state == ToolState.completed,
        ),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // Test 8: Дубликат toolCallId игнорируется
    // -----------------------------------------------------------------------
    test('duplicate tool call ID is ignored', () async {
      final session = await _startSession();
      final sid = session.sessionId;

      await session.onToolStart('c1', 'todowrite', {});
      await session.onToolStart('c1', 'todowrite', {});
      await session.onCompletion(content: '');

      final state = await _replay(repository, sid);
      expect(state.parts.whereType<AssistantTool>().length, equals(1));
    });

    // -----------------------------------------------------------------------
    // Test 9: Tool error не теряет части
    // -----------------------------------------------------------------------
    test('tool error preserves text and previous tool results', () async {
      final session = await _startSession();
      final sid = session.sessionId;

      await session.onChunk('Working...');
      await session.onToolStart('c1', 'todowrite', {});
      await session.onToolEnd('c1', 'todowrite', 'OK');
      await session.onToolStart('c2', 'todowrite', {});
      await session.onToolError('c2', 'todowrite', 'Error!');
      await session.onChunk('Done.');
      await session.onCompletion(content: 'Working...Done.');

      final state = await _replay(repository, sid);
      expect(
        state.parts.any(
          (p) => p is AssistantText && p.text.contains('Working'),
        ),
        isTrue,
        reason: 'text before error survives',
      );
      expect(
        state.parts.any(
          (p) =>
              p is AssistantTool &&
              p.callId == 'c1' &&
              p.state == ToolState.completed,
        ),
        isTrue,
        reason: 'completed tool survives',
      );
      expect(
        state.parts.any(
          (p) =>
              p is AssistantTool &&
              p.callId == 'c2' &&
              p.state == ToolState.error,
        ),
        isTrue,
        reason: 'failed tool is marked error',
      );
    });

    // -----------------------------------------------------------------------
    // Test 10: 10 последовательных инструментов
    // -----------------------------------------------------------------------
    test('10 sequential tools all appear with correct state', () async {
      final session = await _startSession();
      final sid = session.sessionId;

      for (int i = 0; i < 10; i++) {
        await session.onToolStart('c$i', 'todowrite', {});
        await session.onToolEnd('c$i', 'todowrite', 'R$i');
      }
      await session.onCompletion(content: '');

      final state = await _replay(repository, sid);
      final tools = state.parts.whereType<AssistantTool>().toList();
      expect(tools.length, equals(10));
      expect(tools.every((t) => t.state == ToolState.completed), isTrue);
    });

    // -----------------------------------------------------------------------
    // Test 11: Reasoning + tool + text последовательность
    // -----------------------------------------------------------------------
    test('reasoning block before and after tool execution', () async {
      final session = await _startSession();
      final sid = session.sessionId;

      await session.onReasoning('Thinking step 1...\n');
      await session.onToolStart('c1', 'todowrite', {});
      await session.onToolEnd('c1', 'todowrite', 'Result');
      await session.onReasoning('Thinking step 2...\n');
      await session.onChunk('Final answer.');
      await session.onCompletion(content: 'Final answer.');

      final state = await _replay(repository, sid);
      expect(
        state.parts.whereType<AssistantReasoning>().isNotEmpty,
        isTrue,
        reason: 'reasoning parts exist',
      );
      expect(
        state.parts.whereType<AssistantText>().any(
          (p) => p.text.contains('Final answer'),
        ),
        isTrue,
        reason: 'final text exists',
      );
    });

    // -----------------------------------------------------------------------
    // Test 12: runTaskInChild creates AssistantTask in parent session
    // -----------------------------------------------------------------------
    test('runTaskInChild emits task parts in parent session', () async {
      await AgentRegistry().init();

      final parentSession = await runner.startInitializedSession(
        agent: 'test',
        modelRef: 'mock/model',
      );
      final parentId = parentSession.sessionId;

      Future<void> streamFn(SessionRunnerSession child) async {
        await child.onChunk('child output');
      }

      final result = await runner.runTaskInChild(
        parentSessionId: parentId,
        taskPrompt: 'do something',
        streamFn: streamFn,
        taskPartId: 'task-12',
      );

      final state = await _replay(repository, parentId);
      final taskParts = state.parts.whereType<AssistantTask>().toList();
      expect(
        taskParts.length,
        equals(1),
        reason: 'parent session got one task part',
      );
      expect(
        taskParts.first.state,
        ToolState.completed,
        reason: 'task completed',
      );
      expect(taskParts.first.taskSessionId, result.sessionId.value);
    });

    // -----------------------------------------------------------------------
    // Test 13: runTaskInChild correctly counts tool calls
    // -----------------------------------------------------------------------
    test('runTaskInChild counts tool calls in child session', () async {
      await AgentRegistry().init();

      final parentSession = await runner.startInitializedSession(
        agent: 'test',
        modelRef: 'mock/model',
      );
      final parentId = parentSession.sessionId;

      Future<void> streamFn(SessionRunnerSession child) async {
        await child.onToolStart('c1', 'web_search', {'q': 'hello'});
        await child.onToolEnd('c1', 'web_search', 'world');
        await child.onToolStart('c2', 'webfetch', {'url': 'test'});
        await child.onToolEnd('c2', 'webfetch', 'content');
        await child.onToolStart('c3', 'todowrite', {'cmd': 'ls'});
        await child.onToolEnd('c3', 'todowrite', 'files');
        await child.onCompletion(content: 'done');
      }

      final result = await runner.runTaskInChild(
        parentSessionId: parentId,
        taskPrompt: 'do something',
        streamFn: streamFn,
        taskPartId: 'task-tools-13',
      );

      // Verify child session has 3 AssistantTool parts
      final childState = await repository.loadSession(result.sessionId);
      expect(childState, isNotNull);
      final childTools = childState!.parts.whereType<AssistantTool>().toList();
      expect(
        childTools.length,
        equals(3),
        reason: 'child session should have 3 tool parts',
      );

      // Verify parent session AssistantTask has toolCallsCount = 3
      // by replaying all events (simulates load from DB)
      final parentState = await _replay(repository, parentId);
      final taskParts = parentState.parts.whereType<AssistantTask>().toList();
      expect(
        taskParts.length,
        equals(1),
        reason: 'parent session got one task part',
      );
      expect(
        taskParts.first.toolCallsCount,
        equals(3),
        reason: 'toolCallsCount should be 3 (matching the 3 tools in child)',
      );

      // Verify the same via loadSession (uses state cache)
      final loadedParent = await repository.loadSession(parentId);
      final loadedTasks = loadedParent!.parts
          .whereType<AssistantTask>()
          .toList();
      expect(loadedTasks.length, equals(1));
      expect(loadedTasks.first.toolCallsCount, equals(3));
    });

    // -----------------------------------------------------------------------
    // Test 14: Serialization round-trip preserves toolCallsCount
    // -----------------------------------------------------------------------
    test(
      'TaskPartCompleted serialization round-trip preserves toolCallsCount',
      () async {
        await AgentRegistry().init();

        final parentSession = await runner.startInitializedSession(
          agent: 'test',
          modelRef: 'mock/model',
        );
        final parentId = parentSession.sessionId;

        // Emulate what runTaskInChild does: count tools, emit TaskPartCompleted
        Future<void> streamFn(SessionRunnerSession child) async {
          await child.onToolStart('t1', 'web_search', {'q': 'a'});
          await child.onToolEnd('t1', 'web_search', 'res1');
          await child.onToolStart('t2', 'web_search', {'q': 'b'});
          await child.onToolEnd('t2', 'web_search', 'res2');
          await child.onToolStart('t3', 'web_search', {'q': 'c'});
          await child.onToolEnd('t3', 'web_search', 'res3');
          await child.onToolStart('t4', 'web_search', {'q': 'd'});
          await child.onToolEnd('t4', 'web_search', 'res4');
          await child.onToolStart('t5', 'web_search', {'q': 'e'});
          await child.onToolEnd('t5', 'web_search', 'res5');
          await child.onCompletion(content: 'done');
        }

        final result = await runner.runTaskInChild(
          parentSessionId: parentId,
          taskPrompt: 'do something',
          streamFn: streamFn,
          taskPartId: 'task-roundtrip-14',
        );

        // Load events from database and verify TaskPartCompleted has toolCallsCount
        final parentEvents = await repository.eventStore.getEvents(parentId);
        final tpcEvents = parentEvents.whereType<TaskPartCompleted>().toList();
        expect(
          tpcEvents.length,
          equals(1),
          reason: 'should have exactly one TaskPartCompleted event',
        );
        expect(
          tpcEvents.first.toolCallsCount,
          equals(5),
          reason: 'TaskPartCompleted event should carry toolCallsCount=5',
        );

        // Now simulate DB reload by replaying events from scratch
        final replayed = replayEvents(parentEvents);
        final replayedTasks = replayed.parts
            .whereType<AssistantTask>()
            .toList();
        expect(replayedTasks.length, equals(1));
        expect(
          replayedTasks.first.toolCallsCount,
          equals(5),
          reason: 'After full replay, toolCallsCount must still be 5',
        );
      },
    );

    // -----------------------------------------------------------------------
    // Test 15: параллельные тулы — обрыв шага не оставляет висящих в running
    // -----------------------------------------------------------------------
    test(
      'dangling tool calls are finalized so none stays in running state',
      () async {
        final session = await _startSession();
        final sid = session.sessionId;

        // Имитация SDK-шага: все 3 тула стартуют (onToolStart уже сработал
        // во время парсинга потока), затем 2-й падает и прерывает цикл
        // выполнения — 1-й и 3-й никогда не получают терминального события.
        await session.onToolStart('c1', 'todowrite', {});
        await session.onToolStart('c2', 'todowrite', {});
        await session.onToolStart('c3', 'todowrite', {});

        // Сервис (chat_ai_service) теперь дофинализирует висящие тулы
        // через onToolError. Имитируем именно это поведение.
        await session.onToolError('c2', 'todowrite', 'Tool failed');
        await session.onToolError('c1', 'todowrite', 'Aborted');
        await session.onToolError('c3', 'todowrite', 'Aborted');
        await session.onCompletion(content: 'done');

        final state = await _replay(repository, sid);
        final tools = state.parts.whereType<AssistantTool>().toList();
        expect(tools.length, equals(3));
        expect(
          tools.any((t) => t.state == ToolState.running),
          isFalse,
          reason: 'no tool must remain stuck in running after step abort',
        );
        expect(
          tools.where((t) => t.state == ToolState.error).length,
          equals(3),
          reason: 'all aborted/errored tools must be marked error (red)',
        );
      },
    );
  });
}
