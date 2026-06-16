import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:test/test.dart';

void main() {
  group('SessionRunner error handling', () {
    late AppDatabase db;
    late SessionRepository repo;
    late SessionRunner runner;

    setUp(() async {
      db = AppDatabase.inMemory();
      repo = SessionRepository(db);
      runner = SessionRunner(repo);
    });

    tearDown(() async {
      // Wait for any pending async operations to complete before closing
      await Future.delayed(const Duration(milliseconds: 100));
      await db.close();
    });

    test('runTaskInChild throws when streamFn throws and disposes child', () async {
      final parentState = await repo.createSession(agent: 'general');

      Future<void> failingStream(SessionRunnerSession child) async {
        // Don't call onChunk before throwing - it creates pending async operations
        // that cause race conditions with database closure
        throw StateError('AI failure');
      }

      expect(
        runner.runTaskInChild(
          parentSessionId: parentState.id,
          taskPrompt: 'task',
          streamFn: failingStream,
        ),
        throwsA(isA<StateError>()),
      );

      // Wait for async cleanup
      await Future.delayed(const Duration(milliseconds: 50));

      // Child should be removed
      expect(runner.childRunners, isEmpty);
    });

    test('TaskStarted event is published even if streamFn fails', () async {
      final parentState = await repo.createSession(agent: 'general');

      Future<void> failingStream(SessionRunnerSession child) async {
        // Throw immediately without any prior async operations
        throw 'fail';
      }

      try {
        await runner.runTaskInChild(
          parentSessionId: parentState.id,
          taskPrompt: 'task',
          streamFn: failingStream,
        );
      } catch (_) {}

      // Wait for async operations to settle
      await Future.delayed(const Duration(milliseconds: 50));

      final events = await repo.eventStore.getEvents(parentState.id);
      
      // Find TaskStarted event - use firstWhere with orElse to avoid throwing
      final taskStartedEvents = events.whereType<TaskStarted>().toList();
      expect(taskStartedEvents, hasLength(greaterThanOrEqualTo(1)));
      expect(taskStartedEvents.first.description, 'task');
      
      // No TaskCompleted should be present
      final taskCompleteds = events.whereType<TaskCompleted>();
      expect(taskCompleteds, isEmpty);
    });

    test('child session is created but cleaned up on streamFn failure', () async {
      final parentState = await repo.createSession(agent: 'general');

      Future<void> failingStream(SessionRunnerSession child) async {
        throw StateError('Immediate failure');
      }

      try {
        await runner.runTaskInChild(
          parentSessionId: parentState.id,
          taskPrompt: 'failing task',
          streamFn: failingStream,
        );
      } catch (_) {}

      // Wait for cleanup
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify child was created (ChildSessionCreated event exists)
      final parentEvents = await repo.eventStore.getEvents(parentState.id);
      final childCreatedEvents = parentEvents.whereType<ChildSessionCreated>().toList();
      expect(childCreatedEvents, hasLength(greaterThanOrEqualTo(1)));
      
      // Verify child runner was cleaned up
      expect(runner.childRunners, isEmpty);
    });
  });
}
