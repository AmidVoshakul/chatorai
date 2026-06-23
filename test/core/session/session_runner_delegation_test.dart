import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:test/test.dart';

void main() {
  group('SessionRunner delegation', () {
    late AppDatabase db;
    late SessionRepository repo;
    late SessionRunner runner;

    setUp(() async {
      db = AppDatabase.inMemory();
      repo = SessionRepository(db);
      runner = SessionRunner(repo, null);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'runTaskInChild creates child session and publishes ChildSessionCreated on parent',
      () async {
        // Create a parent session
        final parentState = await repo.createSession(
          title: 'Parent',
          agent: 'general',
        );

        // Run a child task
        Future<void> simulateChild(SessionRunnerSession child) async {
          child.onChunk('Hello');
          await child.onCompletion(
            content: 'Hello',
            reasoning: '',
            model: 'test',
          );
        }

        final output = await runner.runTaskInChild(
          parentSessionId: parentState.id,
          taskPrompt: 'Say hello',
          streamFn: simulateChild,
          title: 'Child task',
        );

        // Output should be the child's streaming result
        expect(output, 'Hello');

        // Verify child created event exists on parent
        final parentEvents = await repo.eventStore.getEvents(parentState.id);
        final childCreated = parentEvents
            .whereType<ChildSessionCreated>()
            .first;
        expect(childCreated.parentSessionId, parentState.id);
        expect(childCreated.title, 'Child task');

        // Child session should exist
        final childState = await repo.loadSession(childCreated.childSessionId);
        expect(childState, isNot(null));
        expect(childState!.parentId, parentState.id);

        // Child runner should have been removed
        expect(runner.childRunners, isEmpty);
      },
    );

    test('child session receives user message and streaming events', () async {
      final parentState = await repo.createSession(agent: 'general');

      List<String> capturedChunks = [];
      List<SessionEvent> childEvents = [];

      Future<void> simulateChild(SessionRunnerSession child) async {
        // Listen to child events via repository appendEvent mock? Simpler: store them manually via a callback?
        // Instead we will read events from repo after completion.
        child.onChunk('A');
        child.onChunk('B');
        await child.onCompletion(
          content: 'AB',
          reasoning: '',
          model: 'test',
          tokensInput: 1,
          tokensOutput: 2,
        );
      }

      await runner.runTaskInChild(
        parentSessionId: parentState.id,
        taskPrompt: 'Task msg',
        streamFn: simulateChild,
      );

      // Find the child session ID from ChildSessionCreated
      final parentEvents = await repo.eventStore.getEvents(parentState.id);
      final childCreated = parentEvents.whereType<ChildSessionCreated>().single;
      final childId = childCreated.childSessionId;

      // Read events for child
      final events = await repo.eventStore.getEvents(childId);
      // Should contain:
      // SessionCreated (handled by initialize), MessageAdded (user message), TextStarted, TextDelta (two deltas), TextEnded, StepEnded
      final messageAdded = events.whereType<MessageAdded>().singleWhere(
        (e) => e.role == 'user',
      );
      expect(messageAdded.content, 'Task msg');

      final textStarted = events.whereType<TextStarted>().single;
      expect(textStarted.messageId, isNot(null));

      final deltas = events.whereType<TextDelta>().toList();
      expect(deltas.map((e) => e.delta).join(), 'AB');

      final textEnded = events.whereType<TextEnded>().single;
      expect(textEnded.fullText, 'AB');

      final stepEnded = events.whereType<StepEnded>().single;
      expect(stepEnded.tokensOutput, 2);
    });

    test('TaskStarted and TaskCompleted events published on parent', () async {
      final parentState = await repo.createSession(agent: 'general');

      Future<void> simulateChild(SessionRunnerSession child) async {
        child.onChunk('Result');
        await child.onCompletion(content: 'Result');
      }

      await runner.runTaskInChild(
        parentSessionId: parentState.id,
        taskPrompt: 'Do task',
        streamFn: simulateChild,
      );

      final events = await repo.eventStore.getEvents(parentState.id);
      final taskStarted = events.whereType<TaskStarted>().single;
      expect(taskStarted.description, 'Do task');

      final taskCompleted = events.whereType<TaskCompleted>().single;
      expect(taskCompleted.output, 'Result');
      expect(taskCompleted.taskId, taskStarted.taskId);
    });

    test('child runner disposed after completion', () async {
      final parentState = await repo.createSession(agent: 'general');

      Future<void> simulateChild(SessionRunnerSession child) async {
        child.onChunk('X');
        await child.onCompletion(content: 'X');
      }

      await runner.runTaskInChild(
        parentSessionId: parentState.id,
        taskPrompt: 'x',
        streamFn: simulateChild,
      );

      // Child runner should be removed from map
      expect(runner.childRunners, isEmpty);
      // The underlying runner is disposed; no way to assert directly but we trust dispose called
    });

    test(
      'runTaskInChild propagates parent session tokens via StepEnded in child',
      () async {
        final parentState = await repo.createSession(agent: 'general');

        Future<void> simulateChild(SessionRunnerSession child) async {
          child.onChunk('out');
          await child.onCompletion(
            content: 'out',
            tokensInput: 10,
            tokensOutput: 5,
            tokensReasoning: 2,
          );
        }

        await runner.runTaskInChild(
          parentSessionId: parentState.id,
          taskPrompt: 't',
          streamFn: simulateChild,
        );

        final childCreated = (await repo.eventStore.getEvents(
          parentState.id,
        )).whereType<ChildSessionCreated>().single;
        final childEvents = await repo.eventStore.getEvents(
          childCreated.childSessionId,
        );
        final stepEnded = childEvents.whereType<StepEnded>().single;
        expect(stepEnded.tokensInput, 10);
        expect(stepEnded.tokensOutput, 5);
        expect(stepEnded.tokensReasoning, 2);
      },
    );
  });
}
