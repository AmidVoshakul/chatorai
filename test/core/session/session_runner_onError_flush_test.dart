import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:test/test.dart';

void main() {
  group('SessionRunnerSession onError flushes', () {
    late AppDatabase db;
    late SessionRepository repo;
    late SessionRunner runner;

    setUp(() async {
      db = AppDatabase.inMemory();
      repo = SessionRepository(db);
      runner = SessionRunner(repo);
    });

    tearDown(() async {
      await db.close();
    });

    test('onError flushes pending text and reasoning before StepFailed', () async {
      final session = runner.startSession(agent: 'test');
      await session.initialize();

      // Simulate pending text and reasoning
      session.onChunk('partial text');
      session.onReasoning('partial reasoning');
      // At this point _pendingText and _pendingReasoning are non-empty, but not flushed

      // Trigger error
      await session.onError('test error');

      // Read events
      final events = await repo.eventStore.getEvents(session.sessionId);

      // Should have TextDelta and ReasoningDelta before StepFailed (order: flush first)
      final deltas = events.whereType<TextDelta>().toList();
      expect(deltas, hasLength(1));
      expect(deltas.first.delta, 'partial text');

      final reasoningDeltas = events.whereType<ReasoningDelta>().toList();
      expect(reasoningDeltas, hasLength(1));
      expect(reasoningDeltas.first.delta, 'partial reasoning');

      final stepFailed = events.whereType<StepFailed>().single;
      expect(stepFailed.error, 'test error');
    });
  });
}
