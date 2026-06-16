import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_state.dart';

void main() {
  group('SessionRunner', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository);
    });

    tearDown(() async {
      await db.close();
    });

    test('startSession creates session and returns event callbacks', () async {
      final session = runner.startSession(
        agent: 'code-reviewer',
        modelRef: 'gpt-4',
      );

      expect(session, isNotNull);
      expect(session.sessionId, isNotNull);
      expect(session.sessionId.value, startsWith('ses_'));

      // Initialize (persists SessionCreated)
      final initialState = await session.initialize();
      expect(initialState.agent, 'code-reviewer');
      expect(initialState.modelRef, 'gpt-4');

      // Verify event was stored
      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 1);
      expect(events.first, isA<SessionCreated>());
      final createdEvent = events.first as SessionCreated;
      expect(createdEvent.agent, 'code-reviewer');
      expect(createdEvent.modelRef, 'gpt-4');

      // Callbacks exist
      expect(session.onChunk, isA<Function>());
      expect(session.onReasoning, isA<Function>());
      expect(session.onToolStart, isA<Function>());
      expect(session.onToolEnd, isA<Function>());
      expect(session.onToolError, isA<Function>());
    });

    test('onChunk publishes TextStarted event', () async {
      final session = runner.startSession(agent: 'general');
      await session.initialize();

      // Trigger first chunk — starts TextStarted immediately
      session.onChunk('Hello');

      // Wait for async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));

      final events = await repository.eventStore.getEvents(session.sessionId);
      // Should have: SessionCreated + TextStarted
      expect(events.length, greaterThanOrEqualTo(2));

      // SessionCreated is first
      expect(events[0], isA<SessionCreated>());
      // TextStarted is second (or later if delta snuck in)
      final hasTextStarted = events.any((e) => e is TextStarted);
      expect(hasTextStarted, isTrue);
    });

    test('onToolStart publishes ToolCalled event', () async {
      final session = runner.startSession(agent: 'general');
      await session.initialize();

      session.onToolStart('tc_1', 'bash', {'cmd': 'ls -la'});

      // Wait for async unawaited operations
      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repository.eventStore.getEvents(session.sessionId);
      expect(events.length, 2); // SessionCreated + ToolCalled

      final toolEvent = events[1] as ToolCalled;
      expect(toolEvent.toolCallId, 'tc_1');
      expect(toolEvent.toolName, 'bash');
      expect(toolEvent.input, {'cmd': 'ls -la'});
    });

    test('onCompletion finalizes the session state', () async {
      final session = runner.startSession(
        agent: 'explore',
        modelRef: 'claude-4',
      );
      await session.initialize();

      // Simulate streaming text
      session.onChunk('Hello ');
      session.onReasoning('Thinking...');
      session.onToolStart('tc_2', 'read', {'path': 'file.txt'});
      session.onToolEnd('tc_2', 'read', 'file content');

      // Wait for async operations
      await Future.delayed(const Duration(milliseconds: 100));

      // Finalize
      final finalState = await session.onCompletion(
        content: 'Hello world',
        reasoning: 'I thought about it',
        model: 'claude-4',
        tokensInput: 100,
        tokensOutput: 50,
        tokensReasoning: 10,
      );

      // Verify session state
      expect(finalState, isNotNull);
      expect(finalState.agent, 'explore');
      expect(finalState.modelRef, 'claude-4');

      // Verify the session was updated with StepEnded
      final loadedState = await repository.loadSession(session.sessionId);
      expect(loadedState, isNotNull);
      expect(loadedState!.tokensInput, 100);
      expect(loadedState.tokensOutput, 50);
      expect(loadedState.tokensReasoning, 10);

      // Verify events are all persisted
      final allEvents = await repository.eventStore.getEvents(
        session.sessionId,
      );
      expect(
        allEvents.length,
        greaterThanOrEqualTo(5),
      ); // SessionCreated + TextStarted + ReasoningStarted + ToolCalled + ToolSuccess + TextEnded + ReasoningEnded + StepEnded

      // Check event types present in the chain
      final eventTypes = allEvents.map((e) => e.runtimeType).toSet();
      expect(eventTypes.contains(SessionCreated), isTrue);
      expect(eventTypes.contains(ToolCalled), isTrue);
      expect(eventTypes.contains(ToolSuccess), isTrue);
    });
  });
}
