import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart'
    show AssistantReasoning, AssistantText;

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
      'subsequent chunks do not fire additional TextStarted; deltas are batched',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        const part = 'abcdefghij'; // 10 chars
        for (var i = 0; i < 50; i++) {
          await session.onChunk(
            part,
          ); // total 500 < threshold -> stays buffered
        }

        final eventsBefore = await repository.eventStore.getEvents(
          session.sessionId,
        );
        // Still buffered: only the single TextStarted, no delta yet.
        expect(eventsBefore.whereType<TextStarted>().length, 1);
        expect(eventsBefore.whereType<TextDelta>().length, 0);

        // Completing flushes all buffered chunks as a single aggregated delta.
        await session.onCompletion(content: part * 50, model: 'gpt-4');

        final events = await repository.eventStore.getEvents(session.sessionId);
        expect(events.whereType<TextStarted>().length, 1);
        final deltas = events.whereType<TextDelta>();
        expect(deltas.length, 1); // 50 tokens -> 1 batched delta
        expect(deltas.first.delta, part * 50);
        expect(events.whereType<TextEnded>().single.fullText, part * 50);
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

    test('onToolStart closes open reasoning and appends events', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onReasoning('Thinking...');
      await session.onToolStart('tc_1', 'bash', {'cmd': 'ls'});

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<ReasoningEnded>().length, 1);
      expect(events.whereType<ToolCalled>().length, 1);
    });

    test('onToolEnd appends ToolSuccess event', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onToolStart('tc_1', 'bash', {'cmd': 'pwd'});
      await session.onToolEnd('tc_1', 'bash', '/home/user');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final toolSuccesses = events.whereType<ToolSuccess>().toList();
      expect(toolSuccesses.length, 1);
      expect(toolSuccesses.first.toolCallId, 'tc_1');
    });

    test('onToolError appends ToolFailed event', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onToolStart('tc_1', 'bash', {'cmd': 'fail'});
      await session.onToolError('tc_1', 'bash', 'Command not found');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final toolFailedEvents = events.whereType<ToolFailed>().toList();
      expect(toolFailedEvents.length, 1);
      expect(toolFailedEvents.first.toolCallId, 'tc_1');
    });

    test('onToolStart/auto-close reasoning preserves event order', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      // Each text chunk exceeds the flush threshold so its delta is persisted.
      await session.onChunk('Starting' + 'x' * 1100);
      await session.onToolStart('tc_order', 'bash', {'cmd': 'ls'});
      await session.onChunk(' middle' + 'x' * 1100);
      await session.onToolEnd('tc_order', 'bash', 'file1.txt');
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
          // Small chunks stay buffered until completion (no threshold flush).
          futures.add(Future(() => session.onChunk('tok$i ')));
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
        // All 100 tokens aggregated into a single flushed delta.
        final deltas = events.whereType<TextDelta>();
        expect(deltas.length, 1);
        expect(deltas.single.delta, contains('tok99'));
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
        for (var i = 1; i <= sequences.length; i++) i,
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
}
