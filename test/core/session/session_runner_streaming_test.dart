import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart'
    show AssistantReasoning, AssistantText, AssistantTool;
import 'package:chatorai/features/chat/data/models/chat/message_part.dart'
    show ToolState;

void main() {
  group('SessionRunner.startSession', () {
    test('creates a session with the supplied agent and model', () {
      final runner = SessionRunner(
        SessionRepository(AppDatabase.inMemory()),
        null,
      );
      final session = runner.startSession(
        agent: 'code-reviewer',
        modelRef: 'claude-4',
        title: 'My Session',
      );

      expect(session.sessionId.value, startsWith('ses_'));
      expect(session.initialized, isFalse);
    });
  });

  group('SessionRunnerSession.initialize', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository, null);
    });

    tearDown(() async {
      await db.close();
    });

    test('appends SessionCreated event on first call', () async {
      final session = runner.startSession(agent: 'general');
      await session.initialize();

      expect(session.initialized, isTrue);
      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 1);
      expect(events.first, isA<SessionCreated>());
    });

    test('is idempotent — second call does not append again', () async {
      final session = runner.startSession(agent: 'general');
      await session.initialize();
      await session.initialize();

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 1);
    });
  });

  group('SessionRunner.startInitializedSession', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository, null);
    });

    tearDown(() async {
      await db.close();
    });

    test('returns an already-initialized session', () async {
      final session = await runner.startInitializedSession(
        agent: 'explore',
        modelRef: 'gpt-4',
      );

      expect(session.initialized, isTrue);
      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 1);
      expect(events.first, isA<SessionCreated>());
    });
  });

  group('SessionRunnerSession.onChunk', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository, null);
    });

    tearDown(() async {
      await db.close();
    });

    test('first chunk fires TextStarted + TextDelta events', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      // Exceed the flush threshold so the buffered delta is persisted.
      final chunk = 'Hello' + 'x' * 1100;
      await session.onChunk(chunk);

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<TextStarted>().length, 1);
      final deltas = events.whereType<TextDelta>();
      expect(deltas.length, 1);
      expect(deltas.first.delta, chunk);
    });

    test(
      'subsequent chunks do not fire additional TextStarted; each chunk flushes',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        const part = 'abcdefghij'; // 10 chars
        for (var i = 0; i < 12; i++) {
          await session.onChunk(part);
        }

        // Each chunk immediately flushes a TextDelta (eager flush).
        final eventsBefore = await repository.eventStore.getEvents(
          session.sessionId,
        );
        expect(eventsBefore.whereType<TextStarted>().length, 1);
        expect(
          eventsBefore.whereType<TextDelta>().length,
          12,
          reason: 'eager flush creates one TextDelta per chunk',
        );

        await session.onCompletion(content: part * 12, model: 'gpt-4');

        final events = await repository.eventStore.getEvents(session.sessionId);
        expect(events.whereType<TextStarted>().length, 1);
        final deltas = events.whereType<TextDelta>();
        expect(deltas.length, 12, reason: 'eager flush: 12 chunks = 12 deltas');
        // Each delta is one chunk (10 chars)
        expect(deltas.first.delta, part);
        expect(events.whereType<TextEnded>().single.fullText, part * 12);
      },
    );

    test('empty chunk is a no-op', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onChunk('');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 1);
    });

    test('chunk before initialize() is a no-op', () async {
      final session = runner.startSession(agent: 'general');
      await session.onChunk('Should not appear');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events, isEmpty);
    });
  });

  group('SessionRunnerSession.onReasoning', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository, null);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'first reasoning chunk fires ReasoningStarted + ReasoningDelta events',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        // Exceed the flush threshold so the buffered reasoning delta persists.
        final chunk = 'Thinking...' + 'x' * 1100;
        session.onReasoning(chunk);

        await Future.delayed(const Duration(milliseconds: 100));

        final events = await repository.eventStore.getEvents(session.sessionId);
        expect(events.whereType<ReasoningStarted>().length, 1);
        final deltas = events.whereType<ReasoningDelta>();
        expect(deltas.length, 1);
        expect(deltas.first.delta, chunk);
      },
    );

    test('empty reasoning chunk is a no-op', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onReasoning('');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 1);
    });
  });

  group('SessionRunnerSession.onToolStart / onToolEnd / onToolError', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository, null);
    });

    tearDown(() async {
      await db.close();
    });

    test('onToolStart defers tool card when reasoning is open', () async {
      final session = await runner.startInitializedSession(
        agent: 'general',
        toolCardGrace: const Duration(milliseconds: 50),
      );

      session.onReasoning('Thinking...');
      await session.onToolStart('tc_1', 'shell', {'cmd': 'ls'});

      // Before grace period: no ToolCalled yet, reasoning still open.
      await Future.delayed(const Duration(milliseconds: 10));
      final eventsBefore = await repository.eventStore.getEvents(session.sessionId);
      expect(eventsBefore.whereType<ToolCalled>().length, 0);
      expect(eventsBefore.whereType<ReasoningEnded>().length, 0);

      // After grace period: reasoning closes, then ToolCalled appears.
      await Future.delayed(const Duration(milliseconds: 100));
      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<ReasoningEnded>().length, 1);
      expect(events.whereType<ReasoningStarted>().length, 1);
      expect(events.whereType<ToolCalled>().length, 1);
      // Verify order: ReasoningEnded BEFORE ToolCalled.
      final reasoningEndedIndex = events.indexWhere((e) => e is ReasoningEnded);
      final toolCalledIndex = events.indexWhere((e) => e is ToolCalled);
      expect(reasoningEndedIndex, lessThan(toolCalledIndex));
    });

    test('onToolEnd appends ToolSuccess event', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onToolStart('tc_1', 'shell', {'cmd': 'pwd'});
      await session.onToolEnd('tc_1', 'shell', '/home/user');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final toolSuccesses = events.whereType<ToolSuccess>().toList();
      expect(toolSuccesses.length, 1);
      expect(toolSuccesses.first.toolCallId, 'tc_1');
    });

    test('onToolError appends ToolFailed event', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onToolStart('tc_1', 'shell', {'cmd': 'fail'});
      await session.onToolError('tc_1', 'shell', 'Command not found');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final toolFailedEvents = events.whereType<ToolFailed>().toList();
      expect(toolFailedEvents.length, 1);
      expect(toolFailedEvents.first.toolCallId, 'tc_1');
    });

    test('onToolStart skips delegated tools (no ToolCalled part)', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onToolStart('tc_task', 'task', {'prompt': 'do it'});
      await session.onToolStart('tc_container', 'task_container', {
        'tasks': [
          {'description': 'a', 'prompt': 'b', 'subagent_type': 'general'},
        ],
      });
      // Ordinary tools are still recorded.
      await session.onToolStart('tc_shell', 'shell', {'cmd': 'ls'});
      await session.onToolEnd('tc_container', 'task_container', 'ok');
      await session.onToolEnd('tc_task', 'task', 'ok');
      await session.onToolEnd('tc_shell', 'shell', 'file1');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final toolCalls = events.whereType<ToolCalled>().toList();
      expect(toolCalls.length, 1);
      expect(toolCalls.single.toolName, 'shell');
      // No tool parts may exist for delegated tools, only for the shell call.
      final toolSuccesses = events.whereType<ToolSuccess>().toList();
      expect(toolSuccesses.length, 1);
      expect(toolSuccesses.single.toolCallId, 'tc_shell');
    });

    test('onToolStart resets text part but does not emit TextEnded', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      // Each text chunk exceeds the flush threshold so its delta is persisted.
      await session.onChunk('Starting' + 'x' * 1100);
      await session.onToolStart('tc_order', 'shell', {'cmd': 'ls'});
      await session.onChunk(' middle' + 'x' * 1100);
      await session.onToolEnd('tc_order', 'shell', 'file1.txt');
      await session.onChunk(' end' + 'x' * 1100);

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final types = events.map((e) => e.runtimeType).toList();
      expect(types, const [
        SessionCreated,
        TextStarted,
        TextDelta,
        ToolCalled,
        // onToolStart resets _openTextPartId, so subsequent text opens a new part
        TextStarted,
        TextDelta,
        ToolSuccess,
        // ' end' continues the same (second) text part
        TextDelta,
      ]);
    });

    test('reasoning text preserved when text auto-closes it', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onReasoning('Thinking...');
      await session.onChunk('The answer is 42');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final reasoningEnded = events.whereType<ReasoningEnded>().singleOrNull;
      expect(reasoningEnded, isNotNull);
      expect(reasoningEnded!.fullReasoning, 'Thinking...');
    });

    test('onToolStart with open text does not emit TextEnded', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      // Exceed flush threshold so delta is persisted.
      await session.onChunk('Hello' + 'x' * 1100);
      await session.onToolStart('tc_1', 'shell', {'cmd': 'ls'});

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      // TextEnded must NOT be emitted on tool start.
      final textEnded = events.whereType<TextEnded>().toList();
      expect(textEnded.length, 0);
      // Subsequent text after tool call opens a new part (text part is reset).
      await session.onChunk('After tool' + 'x' * 1100);
      await Future.delayed(const Duration(milliseconds: 50));
      final events2 = await repository.eventStore.getEvents(session.sessionId);
      final textStarted = events2.whereType<TextStarted>().toList();
      expect(textStarted.length, 2);
    });

    test('delegated tool does not close open reasoning', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onReasoning('Thinking about task...');
      await session.onToolStart('tc_task', 'task', {'prompt': 'do it'});

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      // Reasoning must stay open across delegated tool start.
      expect(events.whereType<ReasoningEnded>().length, 0);
      expect(events.whereType<ReasoningStarted>().length, 1);
      // No ToolCalled for delegated tool.
      expect(events.whereType<ToolCalled>().length, 0);
    });

    test('post-task reasoning continues the same reasoning part', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onReasoning('Before task');
      await session.onToolStart('tc_task', 'task', {'prompt': 'do it'});
      await session.onToolEnd('tc_task', 'task', 'done');
      await session.onReasoning('After task');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final reasoningStarted = events.whereType<ReasoningStarted>().toList();
      expect(reasoningStarted.length, 1);
      final reasoningEnded = events.whereType<ReasoningEnded>().toList();
      expect(reasoningEnded.length, 0);
      // Reasoning stays open across the delegated tool call.
      expect(reasoningStarted.single.partId, isNotNull);
    });

    test('onReasoningEnd closes open reasoning and allows new part', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onReasoning('Thinking...');
      await session.onReasoningEnd();

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<ReasoningEnded>().length, 1);
      expect(
        events.whereType<ReasoningEnded>().single.fullReasoning,
        'Thinking...',
      );
      // Subsequent reasoning opens a new part.
      session.onReasoning('More thinking...');
      await Future.delayed(const Duration(milliseconds: 50));
      final events2 = await repository.eventStore.getEvents(session.sessionId);
      final reasoningStarted = events2.whereType<ReasoningStarted>().toList();
      expect(reasoningStarted.length, 2);
    });

    test('onReasoningEnd with no open reasoning is a no-op', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onReasoningEnd();

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<ReasoningEnded>().length, 0);
    });

    test('onReasoningEnd flushes pending deltas before closing', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onReasoning('Pending thought');
      await session.onReasoningEnd();

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final reasoningEnded = events.whereType<ReasoningEnded>().toList();
      expect(reasoningEnded.length, 1);
      expect(reasoningEnded.single.fullReasoning, 'Pending thought');
      final deltas = events.whereType<ReasoningDelta>().toList();
      expect(deltas.length, 1);
    });

    test('multi-step: reasoning, tool, reasoning in correct order', () async {
      final session = await runner.startInitializedSession(
        agent: 'general',
        toolCardGrace: const Duration(milliseconds: 50),
      );

      session.onReasoning('First thought');
      await session.onReasoningEnd();
      await session.onToolStart('tc_1', 'shell', {'cmd': 'ls'});
      await session.onToolEnd('tc_1', 'shell', 'file1');
      session.onReasoning('Second thought');
      await session.onReasoningEnd();

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final reasoningStarted = events.whereType<ReasoningStarted>().toList();
      expect(reasoningStarted.length, 2);
      final reasoningEnded = events.whereType<ReasoningEnded>().toList();
      expect(reasoningEnded.length, 2);
      final toolCalled = events.whereType<ToolCalled>().toList();
      expect(toolCalled.length, 1);
      // Verify order: first reasoning block, then tool, then second reasoning block.
      final types = events.map((e) => e.runtimeType).toList();
      expect(types, const [
        SessionCreated,
        ReasoningStarted,
        ReasoningDelta,
        ReasoningEnded,
        ToolCalled,
        ToolSuccess,
        ReasoningStarted,
        ReasoningDelta,
        ReasoningEnded,
      ]);
    });

    test('live reasoning with no tools behaves as before', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onReasoning('First');
      session.onReasoning(' second');
      await session.onReasoningEnd();

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final reasoningStarted = events.whereType<ReasoningStarted>().toList();
      expect(reasoningStarted.length, 1);
      final deltas = events.whereType<ReasoningDelta>().toList();
      expect(deltas.length, 2);
      expect(deltas.map((d) => d.delta).join(), 'First second');
      final reasoningEnded = events.whereType<ReasoningEnded>().toList();
      expect(reasoningEnded.length, 1);
      expect(reasoningEnded.single.fullReasoning, 'First second');
    });

    test('delegated tool does not split reasoning section', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onReasoning('Let me delegate');
      await session.onToolStart('tc_task', 'task', {'prompt': 'do it'});
      session.onReasoning(' and continue');
      await session.onReasoningEnd();

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final reasoningStarted = events.whereType<ReasoningStarted>().toList();
      expect(reasoningStarted.length, 1);
      final reasoningEnded = events.whereType<ReasoningEnded>().toList();
      expect(reasoningEnded.length, 1);
      expect(
        reasoningEnded.single.fullReasoning,
        'Let me delegate and continue',
      );
      expect(events.whereType<ToolCalled>().length, 0);
    });

    // --- New Design F tests ---

    test('deferred tool card: tail streams live, then card appears after grace',
        () async {
      final session = await runner.startInitializedSession(
        agent: 'general',
        toolCardGrace: const Duration(milliseconds: 50),
      );

      session.onReasoning('A');
      await session.onToolStart('tc1', 'shell', {'cmd': 'ls'});
      session.onReasoning('B');
      session.onReasoning('C');

      // Before grace: same reasoning part, no ToolCalled.
      await Future.delayed(const Duration(milliseconds: 20));
      var events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<ReasoningStarted>().length, 1);
      expect(events.whereType<ToolCalled>().length, 0);
      final partId = events.whereType<ReasoningStarted>().single.partId;

      // After grace: ReasoningEnded on same partId, then ToolCalled.
      await Future.delayed(const Duration(milliseconds: 100));
      events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<ReasoningEnded>().length, 1);
      expect(events.whereType<ReasoningEnded>().single.partId, partId);
      expect(events.whereType<ReasoningEnded>().single.fullReasoning, 'ABC');
      expect(events.whereType<ToolCalled>().length, 1);
      final toolCalledIndex = events.indexWhere((e) => e is ToolCalled);
      final reasoningEndedIndex = events.indexWhere((e) => e is ReasoningEnded);
      expect(reasoningEndedIndex, lessThan(toolCalledIndex));
    });

    test('tool card is not emitted immediately when reasoning is open', () async {
      final session = await runner.startInitializedSession(
        agent: 'general',
        toolCardGrace: const Duration(milliseconds: 100),
      );

      session.onReasoning('Thinking...');
      await session.onToolStart('tc1', 'shell', {'cmd': 'ls'});

      await Future.delayed(const Duration(milliseconds: 30));
      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<ToolCalled>().length, 0);
      expect(events.whereType<ReasoningEnded>().length, 0);

      session.dispose();
    });

    test('force-path: onToolEnd before grace emits ToolCalled then ToolSuccess',
        () async {
      final session = await runner.startInitializedSession(
        agent: 'general',
        toolCardGrace: const Duration(milliseconds: 200),
      );

      session.onReasoning('A');
      await session.onToolStart('tc1', 'shell', {'cmd': 'ls'});
      session.onReasoning('B');
      await session.onToolEnd('tc1', 'shell', 'file1');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<ReasoningEnded>().length, 1);
      expect(events.whereType<ToolCalled>().length, 1);
      expect(events.whereType<ToolSuccess>().length, 1);
      final reasoningEndedIndex = events.indexWhere((e) => e is ReasoningEnded);
      final toolCalledIndex = events.indexWhere((e) => e is ToolCalled);
      final toolSuccessIndex = events.indexWhere((e) => e is ToolSuccess);
      expect(reasoningEndedIndex, lessThan(toolCalledIndex));
      expect(toolCalledIndex, lessThan(toolSuccessIndex));
    });

    test('two waves: deferred cards in correct order', () async {
      final session = await runner.startInitializedSession(
        agent: 'general',
        toolCardGrace: const Duration(milliseconds: 50),
      );

      // Wave 1
      session.onReasoning('A1');
      await session.onToolStart('tc1', 'shell', {'cmd': 'ls'});
      session.onReasoning('A2');
      await session.onToolEnd('tc1', 'shell', 'file1');

      // Wave 2
      session.onReasoning('B1');
      await session.onToolStart('tc2', 'shell', {'cmd': 'pwd'});
      session.onReasoning('B2');
      await session.onToolEnd('tc2', 'shell', '/home');

      await Future.delayed(const Duration(milliseconds: 100));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final reasoningStarted = events.whereType<ReasoningStarted>().toList();
      expect(reasoningStarted.length, 2);
      final reasoningEnded = events.whereType<ReasoningEnded>().toList();
      expect(reasoningEnded.length, 2);
      expect(reasoningEnded[0].fullReasoning, 'A1A2');
      expect(reasoningEnded[1].fullReasoning, 'B1B2');
      expect(reasoningEnded[0].partId, reasoningStarted[0].partId);
      expect(reasoningEnded[1].partId, reasoningStarted[1].partId);
      final toolCalled = events.whereType<ToolCalled>().toList();
      expect(toolCalled.length, 2);
      expect(toolCalled[0].toolCallId, 'tc1');
      expect(toolCalled[1].toolCallId, 'tc2');
    });

    test('tool without preceding thought emits ToolCalled immediately', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onToolStart('tc1', 'shell', {'cmd': 'ls'});
      await session.onToolEnd('tc1', 'shell', 'file1');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final toolCalled = events.whereType<ToolCalled>().toList();
      expect(toolCalled.length, 1);
      expect(toolCalled.single.toolCallId, 'tc1');
      expect(events.whereType<ReasoningStarted>().length, 0);
    });

    test('onChunk with pending deferred cards emits cards before TextStarted',
        () async {
      final session = await runner.startInitializedSession(
        agent: 'general',
        toolCardGrace: const Duration(milliseconds: 100),
      );

      session.onReasoning('A');
      await session.onToolStart('tc1', 'shell', {'cmd': 'ls'});
      await session.onChunk('Answer' + 'x' * 1100);

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final types = events.map((e) => e.runtimeType).toList();
      // ReasoningEnded (closed by text start) appears BEFORE TextStarted.
      final reasoningEndedIndex = types.indexOf(ReasoningEnded);
      final textStartedIndex = types.indexOf(TextStarted);
      expect(reasoningEndedIndex, lessThan(textStartedIndex));
      final reasoningEnded = events.whereType<ReasoningEnded>().single;
      expect(reasoningEnded.fullReasoning, 'A');
      expect(events.whereType<ReasoningStarted>().length, 1);
      expect(events.whereType<TextStarted>().length, 1);
      expect(events.whereType<ToolCalled>().length, 1);
    });

    test('onCompletion with pending deferred emits cards before StepEnded',
        () async {
      final session = await runner.startInitializedSession(
        agent: 'general',
        toolCardGrace: const Duration(milliseconds: 50),
      );

      session.onReasoning('A');
      await session.onToolStart('tc1', 'shell', {'cmd': 'ls'});
      await session.onCompletion(
        content: 'Answer',
        model: 'gpt-4',
        tokensInput: 10,
        tokensOutput: 5,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final reasoningEnded = events.whereType<ReasoningEnded>().toList();
      expect(reasoningEnded.length, 1);
      expect(reasoningEnded.single.fullReasoning, 'A');
      final toolCalled = events.whereType<ToolCalled>().toList();
      expect(toolCalled.length, 1);
      final stepEnded = events.whereType<StepEnded>().toList();
      expect(stepEnded.length, 1);
      // ToolCalled must appear before StepEnded.
      expect(events.indexOf(toolCalled.single) < events.indexOf(stepEnded.single),
          isTrue);
    });

    test('onToolError force-path: ToolCalled before ToolFailed', () async {
      final session = await runner.startInitializedSession(
        agent: 'general',
        toolCardGrace: const Duration(milliseconds: 200),
      );

      session.onReasoning('A');
      await session.onToolStart('tc1', 'shell', {'cmd': 'fail'});
      await session.onToolError('tc1', 'shell', 'Command not found');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<ReasoningEnded>().length, 1);
      expect(events.whereType<ToolCalled>().length, 1);
      expect(events.whereType<ToolFailed>().length, 1);
      final toolCalledIndex = events.indexWhere((e) => e is ToolCalled);
      final toolFailedIndex = events.indexWhere((e) => e is ToolFailed);
      expect(toolCalledIndex, lessThan(toolFailedIndex));
    });

    test('parallel wave: both cards deferred, emitted in call order', () async {
      final session = await runner.startInitializedSession(
        agent: 'general',
        toolCardGrace: const Duration(milliseconds: 50),
      );

      session.onReasoning('A');
      await session.onToolStart('tc1', 'shell', {'cmd': 'ls'});
      await session.onToolStart('tc2', 'shell', {'cmd': 'pwd'});
      session.onReasoning('B');

      await Future.delayed(const Duration(milliseconds: 100));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<ReasoningEnded>().length, 1);
      expect(events.whereType<ReasoningEnded>().single.fullReasoning, 'AB');
      final toolCalled = events.whereType<ToolCalled>().toList();
      expect(toolCalled.length, 2);
      expect(toolCalled[0].toolCallId, 'tc1');
      expect(toolCalled[1].toolCallId, 'tc2');
    });

    test('flush pending with empty list and open reasoning only closes reasoning',
        () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onReasoning('A');
      await session.onReasoningEnd();

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<ReasoningEnded>().length, 1);
      expect(events.whereType<ToolCalled>().length, 0);
    });
  });

  group('SessionRunnerSession.onCompletion', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository, null);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'appends TextEnded, StepEnded events and returns SessionState',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        await session.onChunk('Final answer');

        final state = await session.onCompletion(
          content: 'Final answer',
          model: 'gpt-4',
          tokensInput: 100,
          tokensOutput: 50,
          tokensReasoning: 10,
        );

        final events = await repository.eventStore.getEvents(session.sessionId);
        expect(events.last, isA<StepEnded>());

        final stepEnded = events.last as StepEnded;
        expect(stepEnded.tokensInput, 100);
        expect(stepEnded.tokensOutput, 50);
        expect(stepEnded.tokensReasoning, 10);

        expect(events.whereType<TextEnded>().length, 1);
        expect(state.id, session.sessionId);
      },
    );

    test(
      'onCompletion finalizes unfinished tools with ToolFailed before StepEnded',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        await session.onToolStart('tc_1', 'shell', {'cmd': 'ls'});
        // Intentionally skip onToolEnd/onToolError for tc_1.
        await session.onCompletion(content: 'done', model: 'gpt-4');

        await Future.delayed(const Duration(milliseconds: 50));

        final events = await repository.eventStore.getEvents(session.sessionId);
        final toolFailed = events.whereType<ToolFailed>().toList();
        expect(toolFailed.length, 1);
        expect(toolFailed.single.toolCallId, 'tc_1');
        expect(
          toolFailed.single.error,
          'Tool execution aborted before completion.',
        );
        final stepEnded = events.whereType<StepEnded>().toList();
        expect(stepEnded.length, 1);
        // ToolFailed must appear before StepEnded.
        expect(
          events.indexOf(toolFailed.single) < events.indexOf(stepEnded.single),
          isTrue,
        );
      },
    );

    test('onCompletion does not re-finalize already completed tools', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onToolStart('tc_1', 'shell', {'cmd': 'ls'});
      await session.onToolEnd('tc_1', 'shell', 'file1');
      await session.onCompletion(content: 'done', model: 'gpt-4');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final toolFailed = events.whereType<ToolFailed>().toList();
      expect(toolFailed.length, 0);
      final toolSuccess = events.whereType<ToolSuccess>().toList();
      expect(toolSuccess.length, 1);
    });
  });

  group('SessionRunnerSession.onError', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository, null);
    });

    tearDown(() async {
      await db.close();
    });

    test('appends StepFailed event', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      // Exceed the flush threshold so the buffered text delta is persisted.
      await session.onChunk('Some text' + 'x' * 1100);
      await session.onError(Exception('Network error'));

      final events = await repository.eventStore.getEvents(session.sessionId);
      // SessionCreated + TextStarted + (flushed) TextDelta + StepFailed
      expect(events.whereType<TextStarted>().length, 1);
      expect(events.whereType<TextDelta>().length, 1);
      final stepFailed = events.whereType<StepFailed>().single;
      expect(stepFailed.error, contains('Network error'));
    });

    test(
      'onError flushes and closes an open text part (no dangling part)',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        // Buffered text that has NOT been flushed yet (below threshold).
        await session.onChunk('Partial answer');
        await session.onError(Exception('boom'));

        final events = await repository.eventStore.getEvents(session.sessionId);
        // The open part must be closed with TextEnded so replay is consistent.
        final textEnded = events.whereType<TextEnded>();
        expect(textEnded.length, 1);
        expect(textEnded.single.fullText, 'Partial answer');
        expect(events.whereType<StepFailed>().single.error, contains('boom'));

        // Replaying the events yields exactly one complete text part.
        final state = repository.eventStore;
        final all = await state.getEvents(session.sessionId);
        final loaded = await repository.loadSession(session.sessionId);
        expect(loaded, isNotNull);
        final texts = loaded!.parts.whereType<AssistantText>().toList();
        expect(texts.length, 1);
        expect(texts.single.text, 'Partial answer');
      },
    );

    test(
      'onError flushes and closes an open reasoning part (no dangling part)',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        await session.onReasoning('Partial thought');
        await session.onError(Exception('boom'));

        final events = await repository.eventStore.getEvents(session.sessionId);
        final reasoningEnded = events.whereType<ReasoningEnded>();
        expect(reasoningEnded.length, 1);
        expect(reasoningEnded.single.fullReasoning, 'Partial thought');
        expect(events.whereType<StepFailed>().single.error, contains('boom'));

        final loaded = await repository.loadSession(session.sessionId);
        expect(loaded, isNotNull);
        final reasonings = loaded!.parts
            .whereType<AssistantReasoning>()
            .toList();
        expect(reasonings.length, 1);
        expect(reasonings.single.text, 'Partial thought');
      },
    );

    test(
      'onError finalizes unfinished tools with ToolFailed before StepFailed',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        await session.onToolStart('tc_1', 'shell', {'cmd': 'ls'});
        // Intentionally skip onToolEnd/onToolError for tc_1.
        await session.onError(Exception('boom'));

        await Future.delayed(const Duration(milliseconds: 50));

        final events = await repository.eventStore.getEvents(session.sessionId);
        final toolFailed = events.whereType<ToolFailed>().toList();
        expect(toolFailed.length, 1);
        expect(toolFailed.single.toolCallId, 'tc_1');
        expect(
          toolFailed.single.error,
          'Tool execution aborted before completion.',
        );
        final stepFailed = events.whereType<StepFailed>().toList();
        expect(stepFailed.length, 1);
        // ToolFailed must appear before StepFailed.
        expect(
          events.indexOf(toolFailed.single) < events.indexOf(stepFailed.single),
          isTrue,
        );
      },
    );

    test(
      'onToolError without prior onToolStart creates ToolCalled + ToolFailed',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        await session.onToolError('tc_orphan', 'shell', 'Command not found');

        await Future.delayed(const Duration(milliseconds: 50));

        final events = await repository.eventStore.getEvents(session.sessionId);
        final toolCalled = events.whereType<ToolCalled>().toList();
        expect(toolCalled.length, 1);
        expect(toolCalled.single.toolCallId, 'tc_orphan');
        final toolFailed = events.whereType<ToolFailed>().toList();
        expect(toolFailed.length, 1);
        expect(toolFailed.single.toolCallId, 'tc_orphan');
        expect(toolFailed.single.error, 'Command not found');
        // The part should be in error state.
        final loaded = await repository.loadSession(session.sessionId);
        expect(loaded, isNotNull);
        final tools = loaded!.parts.whereType<AssistantTool>().toList();
        expect(tools.length, 1);
        expect(tools.single.state, ToolState.error);
      },
    );
  });

  group('SessionRunnerSession serialization (concurrent hot path)', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository, null);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'concurrent unawaited onChunk emits exactly one TextStarted',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        final futures = <Future<void>>[];
        for (var i = 0; i < 100; i++) {
          futures.add(Future(() => session.onChunk('${i % 10}')));
        }
        await Future.wait(futures);
        await session.onCompletion(content: 'final');

        final events = await repository.eventStore.getEvents(session.sessionId);
        expect(
          events.whereType<TextStarted>().length,
          1,
          reason: 'no duplicate TextStarted under concurrency',
        );
        expect(events.whereType<TextEnded>().length, 1);
        // Eager flush: each chunk creates a TextDelta.
        final deltas = events.whereType<TextDelta>();
        expect(
          deltas.length,
          100,
          reason: 'eager flush: 100 chunks = 100 deltas',
        );
        expect(
          deltas.map((d) => d.delta).join(),
          contains('9'),
          reason: 'all deltas concatenated contain all chars',
        );
      },
    );

    test(
      'concurrent unawaited onReasoning emits exactly one ReasoningStarted',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        final futures = <Future<void>>[];
        for (var i = 0; i < 100; i++) {
          futures.add(Future(() => session.onReasoning('think$i ')));
        }
        await Future.wait(futures);
        await session.onCompletion(content: 'final', reasoning: 'finalreason');

        final events = await repository.eventStore.getEvents(session.sessionId);
        expect(
          events.whereType<ReasoningStarted>().length,
          1,
          reason: 'no duplicate ReasoningStarted under concurrency',
        );
        expect(events.whereType<ReasoningEnded>().length, 1);
      },
    );

    test('overlapping flushes produce contiguous, unique sequences', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      // Each chunk exceeds the flush threshold, so every onChunk triggers a
      // flush. Fired concurrently to stress the serialization guard.
      final futures = <Future<void>>[];
      for (var i = 0; i < 40; i++) {
        futures.add(Future(() => session.onChunk('chunk$i ' + 'x' * 1100)));
      }
      await Future.wait(futures);
      await session.onCompletion(content: 'final');

      final events = await repository.eventStore.getEvents(session.sessionId);
      final sequences = events.map((e) => e.sequence).toList();
      // Unique and strictly increasing: 1..N (no duplicate/missing sequence).
      expect(
        sequences.toSet().length,
        sequences.length,
        reason: 'sequence numbers must be unique',
      );
      expect(sequences, [
        for (var i = 1; i <= sequences.length; i++) i
      ], reason: 'sequence numbers must be contiguous');
    });
  });

  group('SessionRunnerSession.onTaskStart/onTaskEnd/onTaskError', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository, null);
    });

    tearDown(() async {
      await db.close();
    });

    test('onTaskStart/onTaskEnd/onTaskError emit correct events', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onTaskStart(
        partId: 'part_task1',
        description: 'Test task',
        agent: 'general',
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<TaskPartStarted>().length, 1);

      await session.onTaskEnd('part_task1');

      await Future.delayed(const Duration(milliseconds: 50));

      final events2 = await repository.eventStore.getEvents(session.sessionId);
      expect(events2.whereType<TaskPartCompleted>().length, 1);

      await session.onTaskError('part_task2', 'Test error');

      await Future.delayed(const Duration(milliseconds: 50));

      final events3 = await repository.eventStore.getEvents(session.sessionId);
      expect(events3.whereType<TaskPartError>().length, 1);
    });
  });

  group('SessionRunnerSession.dispose', () {
    test('does not throw when called on fresh session', () {
      final runner = SessionRunner(
        SessionRepository(AppDatabase.inMemory()),
        null,
      );
      final session = runner.startSession(agent: 'general');

      expect(() => session.dispose(), returnsNormally);
    });
  });

  group('SessionRunner.runTaskInChild', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUpAll(() => AgentRegistry().init());

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository, null);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'emits exactly one TaskPartStarted with description and agent',
      () async {
        final parent = await runner.startInitializedSession(agent: 'general');
        final holder = SessionRunnerHolder(
          runner,
          parentSessionId: parent.sessionId.value,
        );

        await runner.runTaskInChild(
          parentSessionId: parent.sessionId,
          taskPrompt: 'Do the research',
          agent: 'general',
          title: 'AI market revenue',
          taskPartId: 'part_1',
          holder: holder,
          streamFn: (_) async {},
        );

        final events = await repository.eventStore.getEvents(parent.sessionId);
        final started = events.whereType<TaskPartStarted>().toList();
        expect(started.length, 1);
        expect(started.single.partId, 'part_1');
        expect(started.single.description, 'AI market revenue');
        expect(started.single.agent, 'general');
        expect(started.single.taskSessionId, isNotEmpty);
      },
    );
  });
}
