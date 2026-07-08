import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';

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

      await session.onChunk('Hello');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 3);
      expect(events[1], isA<TextStarted>());
      expect(events[2], isA<TextDelta>());
      expect((events[2] as TextDelta).delta, 'Hello');
    });

    test('subsequent chunks do not fire additional TextStarted', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onChunk('Hello');
      await session.onChunk(' world');
      await session.onChunk('!');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final textStartedEvents = events.whereType<TextStarted>().toList();
      expect(textStartedEvents.length, 1);
      final textDeltas = events.whereType<TextDelta>().toList();
      expect(textDeltas.length, 3);
    });

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

        session.onReasoning('Thinking...');

        await Future.delayed(const Duration(milliseconds: 100));

        final events = await repository.eventStore.getEvents(session.sessionId);
        expect(events.length, 3);
        expect(events[1], isA<ReasoningStarted>());
        expect(events[2], isA<ReasoningDelta>());
        expect((events[2] as ReasoningDelta).delta, 'Thinking...');
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

      await session.onChunk('Starting');
      await session.onToolStart('tc_order', 'bash', {'cmd': 'ls'});
      await session.onChunk(' middle');
      await session.onToolEnd('tc_order', 'bash', 'file1.txt');
      await session.onChunk(' end');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      final types = events.map((e) => e.runtimeType).toList();
      expect(types.length, 8);
      expect(types[0], SessionCreated);
      expect(types[1], TextStarted);
      expect(types[2], TextDelta);
      expect(types[3], ToolCalled);
      // onToolStart resets _openTextPartId, so subsequent text creates a new part
      expect(types[4], TextStarted);
      expect(types[5], TextDelta);
      expect(types[6], ToolSuccess);
      expect(types[7], TextDelta);
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

      await session.onChunk('Some text');
      await session.onError(Exception('Network error'));

      final events = await repository.eventStore.getEvents(session.sessionId);
      // SessionCreated + TextStarted + TextDelta + StepFailed = 4
      expect(events.length, 4);
      expect(events[3], isA<StepFailed>());
      final stepFailed = events[3] as StepFailed;
      expect(stepFailed.error, contains('Network error'));
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
