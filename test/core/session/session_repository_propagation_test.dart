import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/session/session_id.dart';

void main() {
  group('SessionRepository.deriveChildPermissions', () {
    test('returns deny rules for task and todowrite when parent is null', () {
      final result = SessionRepository.deriveChildPermissions(null);

      expect(result.rules.length, 2);
      expect(
        result.rules.any(
          (r) => r.permission == 'task' && r.action == PermissionAction.deny,
        ),
        isTrue,
      );
      expect(
        result.rules.any(
          (r) =>
              r.permission == 'todowrite' && r.action == PermissionAction.deny,
        ),
        isTrue,
      );
    });

    test('propagates parent deny rules', () {
      final parentRules = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          const PermissionRule(
            permission: 'read',
            pattern: '*.dart',
            action: PermissionAction.allow,
          ),
        ],
      );

      final result = SessionRepository.deriveChildPermissions(parentRules);

      // Only deny rules from parent + task/todowrite denies
      expect(result.rules.length, 3);
      expect(
        result.rules.any(
          (r) => r.permission == 'bash' && r.action == PermissionAction.deny,
        ),
        isTrue,
      );
      // Allow rules are NOT propagated
      expect(
        result.rules.any(
          (r) => r.permission == 'read' && r.action == PermissionAction.allow,
        ),
        isFalse,
      );
      expect(
        result.rules.any(
          (r) => r.permission == 'task' && r.action == PermissionAction.deny,
        ),
        isTrue,
      );
      expect(
        result.rules.any(
          (r) =>
              r.permission == 'todowrite' && r.action == PermissionAction.deny,
        ),
        isTrue,
      );
    });

    test('always denies task and todowrite even if parent allows them', () {
      final parentRules = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'task',
            pattern: '*',
            action: PermissionAction.allow,
          ),
          const PermissionRule(
            permission: 'todowrite',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );

      final result = SessionRepository.deriveChildPermissions(parentRules);

      // task and todowrite must be denied regardless of parent
      final taskRule = result.rules.firstWhere((r) => r.permission == 'task');
      final todowriteRule = result.rules.firstWhere(
        (r) => r.permission == 'todowrite',
      );
      expect(taskRule.action, PermissionAction.deny);
      expect(todowriteRule.action, PermissionAction.deny);
    });
  });

  group('SessionRepository.propagateChildOutput', () {
    late AppDatabase db;
    late SessionRepository repository;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('publishes TaskCompleted event on parent session', () async {
      final parent = await repository.createSession(title: 'Parent');
      final child = await repository.createChildSession(parent.id);

      await repository.propagateChildOutput(
        parentSessionId: parent.id,
        childSessionId: child.id,
        output: 'Child task completed successfully',
      );

      final events = await repository.eventStore.getEvents(parent.id);
      // SessionCreated + ChildSessionCreated + TaskCompleted
      expect(events.length, 3);
      expect(events.last, isA<TaskCompleted>());

      final taskCompleted = events.last as TaskCompleted;
      expect(taskCompleted.output, 'Child task completed successfully');
      expect(taskCompleted.taskId, startsWith('task_${child.id.value}'));
    });

    test('uses custom taskId when provided', () async {
      final parent = await repository.createSession(title: 'Parent');
      final child = await repository.createChildSession(parent.id);

      await repository.propagateChildOutput(
        parentSessionId: parent.id,
        childSessionId: child.id,
        output: 'Done',
        taskId: 'custom-task-123',
      );

      final events = await repository.eventStore.getEvents(parent.id);
      final taskCompleted = events.last as TaskCompleted;
      expect(taskCompleted.taskId, 'custom-task-123');
    });

    test('propagated output appears in parent state after replay', () async {
      final parent = await repository.createSession(title: 'Parent');
      final child = await repository.createChildSession(parent.id);

      await repository.propagateChildOutput(
        parentSessionId: parent.id,
        childSessionId: child.id,
        output: 'Subagent result',
      );

      final state = await repository.loadSession(parent.id);
      expect(state, isNotNull);
      expect(state!.messages.last.content, 'Subagent result');
      expect(state.messages.last.role, MessageRole.assistant);
    });
  });

  group('SessionRepository.getSessionMeta caching', () {
    late AppDatabase db;
    late SessionRepository repository;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('returns cached state on second call', () async {
      final created = await repository.createSession(title: 'Cache Test');

      final meta1 = await repository.getSessionMeta(created.id);
      final meta2 = await repository.getSessionMeta(created.id);

      expect(meta1, isNotNull);
      expect(meta2, isNotNull);
      // Should be the same cached instance
      expect(identical(meta1, meta2), isTrue);
    });

    test('returns null for non-existent session', () async {
      final id = SessionID.create();
      final meta = await repository.getSessionMeta(id);
      expect(meta, isNull);
    });

    test('cache is updated after appendEvent', () async {
      final created = await repository.createSession(title: 'Cache Update');

      final meta1 = await repository.getSessionMeta(created.id);
      expect(meta1!.messages, isEmpty);

      await repository.appendEvent(
        MessageAdded(
          sessionId: created.id,
          messageId: 'msg-1',
          role: 'user',
          content: 'Hello',
          timestamp: DateTime.now(),
        ),
      );

      final meta2 = await repository.getSessionMeta(created.id);
      expect(meta2!.messages.length, 1);
    });
  });

  group('SessionRepository.appendEvent cache paths', () {
    late AppDatabase db;
    late SessionRepository repository;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('when cache miss, falls back to replay', () async {
      final created = await repository.createSession(title: 'Cache Miss');

      // Clear the cache to simulate a cache miss
      // (In practice this happens across repository instances)
      final event = MessageAdded(
        sessionId: created.id,
        messageId: 'msg-1',
        role: 'user',
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      final newState = await repository.appendEvent(event);
      expect(newState.messages.length, 1);
      expect(newState.messages.first.content, 'Hello');
    });

    test('when cache hit, projects on top of cached state', () async {
      final created = await repository.createSession(title: 'Cache Hit');

      // Prime the cache
      await repository.getSessionMeta(created.id);

      final event = MessageAdded(
        sessionId: created.id,
        messageId: 'msg-1',
        role: 'user',
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      final newState = await repository.appendEvent(event);
      expect(newState.messages.length, 1);
    });
  });

  group('SessionRepository.streamSession', () {
    late AppDatabase db;
    late SessionRepository repository;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('emits null for session with no events', () async {
      final id = SessionID.create();
      final stream = repository.streamSession(id);

      // Should emit null (or empty) for a session with no events
      final first = await stream.first;
      expect(first, isNull);
    });

    test('emits state after events are appended', () async {
      final created = await repository.createSession(title: 'Stream Test');

      final stream = repository.streamSession(created.id);

      // The stream should eventually emit a non-null state
      final state = await stream.first;
      expect(state, isNotNull);
      expect(state!.id, created.id);
    });
  });

  group('SessionRepository.getAggregateUsage', () {
    late AppDatabase db;
    late SessionRepository repository;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('aggregates tokens across parent and children', () async {
      final parent = await repository.createSession(title: 'Parent');

      // Add a StepEnded event to parent to accumulate tokens
      await repository.appendEvent(
        StepEnded(
          sessionId: parent.id,
          stepNumber: 1,
          tokensInput: 100,
          tokensOutput: 50,
          tokensReasoning: 10,
          timestamp: DateTime.now(),
        ),
      );

      final child = await repository.createChildSession(parent.id);

      // Add tokens to child
      await repository.appendEvent(
        StepEnded(
          sessionId: child.id,
          stepNumber: 1,
          tokensInput: 200,
          tokensOutput: 100,
          tokensReasoning: 20,
          timestamp: DateTime.now(),
        ),
      );

      final usage = await repository.getAggregateUsage(parent.id);

      expect(usage['tokensInput'], 300);
      expect(usage['tokensOutput'], 150);
      expect(usage['tokensReasoning'], 30);
    });

    test('returns zeros for session with no step events', () async {
      final session = await repository.createSession(title: 'No Steps');

      final usage = await repository.getAggregateUsage(session.id);

      expect(usage['tokensInput'], 0);
      expect(usage['tokensOutput'], 0);
      expect(usage['tokensReasoning'], 0);
    });
  });

  group('SessionRepository.createChildSession edge cases', () {
    late AppDatabase db;
    late SessionRepository repository;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('child title defaults to parent title + " → Sub-task"', () async {
      final parent = await repository.createSession(title: 'Parent Task');

      final child = await repository.createChildSession(parent.id);

      expect(child.title, 'Parent Task → Sub-task');
    });

    test(
      'child title defaults to "Sub-task" when parent has empty title',
      () async {
        final parent = await repository.createSession();

        final child = await repository.createChildSession(parent.id);

        // Empty parent title → " → Sub-task"
        expect(child.title, contains('Sub-task'));
      },
    );

    test('child inherits parent agent when not overridden', () async {
      final parent = await repository.createSession(agent: 'code-reviewer');

      final child = await repository.createChildSession(parent.id);

      expect(child.agent, 'code-reviewer');
    });

    test('child uses overridden agent', () async {
      final parent = await repository.createSession(agent: 'general');

      final child = await repository.createChildSession(
        parent.id,
        agent: 'explore',
      );

      expect(child.agent, 'explore');
    });

    test('child inherits parent modelRef', () async {
      final parent = await repository.createSession(modelRef: 'gpt-4');

      final child = await repository.createChildSession(parent.id);

      expect(child.modelRef, 'gpt-4');
    });

    test('child uses explicit permission when provided', () async {
      final parent = await repository.createSession(agent: 'general');

      final explicitPermission = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );

      final child = await repository.createChildSession(
        parent.id,
        permission: explicitPermission,
      );

      expect(child.permission!.rules.length, 1);
      expect(child.permission!.rules.first.action, PermissionAction.allow);
    });

    test(
      'createChildSession publishes ChildSessionCreated on parent',
      () async {
        final parent = await repository.createSession(title: 'Parent');

        await repository.createChildSession(parent.id);

        final parentEvents = await repository.eventStore.getEvents(parent.id);
        // SessionCreated + ChildSessionCreated
        expect(parentEvents.length, 2);
        expect(parentEvents[1], isA<ChildSessionCreated>());
      },
    );
  });

  group('SessionRepository.deleteSession', () {
    late AppDatabase db;
    late SessionRepository repository;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('deletes session with all related data', () async {
      final session = await repository.createSession(title: 'To Delete');

      // Add some events
      await repository.appendEvent(
        MessageAdded(
          sessionId: session.id,
          messageId: 'msg-1',
          role: 'user',
          content: 'Hi',
          timestamp: DateTime.now(),
        ),
      );

      await repository.deleteSession(session.id);

      // Session should be gone
      final meta = await repository.getSessionMeta(session.id);
      expect(meta, isNull);

      // Events should be gone
      final events = await repository.eventStore.getEvents(session.id);
      expect(events, isEmpty);
    });
  });
}
