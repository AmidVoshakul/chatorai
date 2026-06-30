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
      expect(session.creationEvent.agent, 'code-reviewer');
      expect(session.creationEvent.modelRef, 'claude-4');
      expect(session.creationEvent.title, 'My Session');
      expect(session.initialized, isFalse);
    });

    test('defaults agent to general and title to empty', () {
      final runner = SessionRunner(
        SessionRepository(AppDatabase.inMemory()),
        null,
      );
      final session = runner.startSession(agent: 'general');

      expect(session.creationEvent.agent, 'general');
      expect(session.creationEvent.title, '');
      expect(session.creationEvent.modelRef, isNull);
    });

    test('links parent session when parentSessionId is provided', () {
      final runner = SessionRunner(
        SessionRepository(AppDatabase.inMemory()),
        null,
      );
      final session = runner.startSession(
        agent: 'general',
        parentSessionId: 'ses_parent123',
      );

      expect(session.creationEvent.parentId, isNotNull);
      expect(session.creationEvent.parentId!.value, 'ses_parent123');
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

  group('SessionRunnerSession._handleChunk', () {
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

    test('first chunk fires TextStarted event', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onChunk('Hello');

      // Allow microtasks (unawaited appends) to settle
      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      // SessionCreated + TextStarted
      expect(events.length, 2);
      expect(events[1], isA<TextStarted>());
      expect(session.textStarted, isTrue);
      expect(session.fullText, 'Hello');
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
      expect(session.fullText, 'Hello world!');
    });

    test('empty chunk is a no-op', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onChunk('');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      // Only SessionCreated — no TextStarted
      expect(events.length, 1);
      expect(session.textStarted, isFalse);
    });

    test('chunk before initialize() is a no-op', () async {
      final session = runner.startSession(agent: 'general');
      // Do NOT initialize

      await session.onChunk('Should not appear');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events, isEmpty);
    });

    test('word-boundary chunk triggers immediate flush', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      // Append a word-boundary character — should trigger immediate flush
      await session.onChunk('Hello ');
      await session.flushText(force: true);

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<TextDelta>().length, 1);
    });
  });

  group('SessionRunnerSession._onReasoning', () {
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
      'first reasoning chunk fires TextStarted + ReasoningStarted',
      () async {
        final session = await runner.startInitializedSession(agent: 'general');

        session.onReasoning('Thinking...');

        await Future.delayed(const Duration(milliseconds: 100));

        final events = await repository.eventStore.getEvents(session.sessionId);
        // SessionCreated + TextStarted + ReasoningStarted + ReasoningDelta
        expect(events.length, 4);
        expect(events[1], isA<TextStarted>());
        expect(events[2], isA<ReasoningStarted>());
        expect(events[3], isA<ReasoningDelta>());
        expect(session.reasoningStarted, isTrue);
        expect(session.fullReasoning, 'Thinking...');
      },
    );

    test('empty reasoning chunk is a no-op', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onReasoning('');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 1);
      expect(session.reasoningStarted, isFalse);
    });

    test('reasoning before initialize() is a no-op', () async {
      final session = runner.startSession(agent: 'general');

      session.onReasoning('Should not appear');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events, isEmpty);
    });
  });

  group('SessionRunnerSession._onToolStart / _onToolEnd / _onToolError', () {
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

    test('onToolStart appends ToolCalled event', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onToolStart('tc_1', 'bash', {'cmd': 'ls'});

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 2);
      expect(events[1], isA<ToolCalled>());
      final toolCalled = events[1] as ToolCalled;
      expect(toolCalled.toolCallId, 'tc_1');
      expect(toolCalled.toolName, 'bash');
      expect(toolCalled.input, {'cmd': 'ls'});
    });

    test('onToolEnd appends ToolSuccess event', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onToolEnd('tc_1', 'bash', 'file1.txt');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 2);
      expect(events[1], isA<ToolSuccess>());
      final toolSuccess = events[1] as ToolSuccess;
      expect(toolSuccess.toolCallId, 'tc_1');
      expect(toolSuccess.outputText, 'file1.txt');
      expect(toolSuccess.durationMs, 0);
    });

    test('onToolError appends ToolFailed event', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onToolError('tc_1', 'bash', 'Command not found');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 2);
      expect(events[1], isA<ToolFailed>());
      final toolFailed = events[1] as ToolFailed;
      expect(toolFailed.toolCallId, 'tc_1');
      expect(toolFailed.error, 'Command not found');
    });

    test('tool callbacks before initialize() are no-ops', () async {
      final session = runner.startSession(agent: 'general');

      session.onToolStart('tc_1', 'bash', {'cmd': 'ls'});
      session.onToolEnd('tc_1', 'bash', 'result');
      session.onToolError('tc_1', 'bash', 'error');

      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events, isEmpty);
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

    test('appends TextEnded, ReasoningEnded, and StepEnded events', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onChunk('Final answer');
      session.onReasoning('Some thinking');

      await Future.delayed(const Duration(milliseconds: 50));

      await session.onCompletion(
        content: 'Final answer',
        reasoning: 'Some thinking',
        model: 'gpt-4',
        tokensInput: 100,
        tokensOutput: 50,
        tokensReasoning: 10,
      );

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events, isNotEmpty);
      expect(events.last, isA<StepEnded>());

      final stepEnded = events.last as StepEnded;
      expect(stepEnded.tokensInput, 100);
      expect(stepEnded.tokensOutput, 50);
      expect(stepEnded.tokensReasoning, 10);

      // TextEnded and ReasoningEnded should be present
      expect(events.whereType<TextEnded>().length, 1);
      expect(events.whereType<ReasoningEnded>().length, 1);
    });

    test('without prior text/reasoning only appends StepEnded', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      await session.onCompletion(content: '');

      final events = await repository.eventStore.getEvents(session.sessionId);
      // SessionCreated + StepEnded
      expect(events.length, 2);
      expect(events[1], isA<StepEnded>());
    });

    test('returns a valid SessionState', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      session.onChunk('Hello');
      await Future.delayed(const Duration(milliseconds: 50));

      final state = await session.onCompletion(content: 'Hello');

      expect(state.id, session.sessionId);
      expect(state.messages, isNotEmpty);
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

      await session.onError(Exception('Network error'));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 2);
      expect(events[1], isA<StepFailed>());
      final stepFailed = events[1] as StepFailed;
      expect(stepFailed.error, contains('Network error'));
    });
  });

  group('SessionRunnerSession.flushText', () {
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

test('force flush appends TextDelta event', () async {
  final session = await runner.startInitializedSession(agent: 'general');

  await session.onChunk('Hello');
  await session.flushText(force: true);

  final events = await repository.eventStore.getEvents(session.sessionId);
  expect(events.whereType<TextDelta>().length, 1);
  final textDelta = events.whereType<TextDelta>().first;
  expect(textDelta.delta, 'Hello');
});

test('non-force flush before 250ms is a no-op', () async {
  final session = await runner.startInitializedSession(agent: 'general');

  await session.onChunk('Hi');
  // Immediately flush without force — should be suppressed
  await session.flushText(force: false);

  final events = await repository.eventStore.getEvents(session.sessionId);
  expect(events.whereType<TextDelta>(), isEmpty);
});

    test('flush with empty pending text is a no-op', () async {
      final session = await runner.startInitializedSession(agent: 'general');

      // No chunks — pendingText is empty
      await session.flushText(force: true);

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.whereType<TextDelta>(), isEmpty);
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
