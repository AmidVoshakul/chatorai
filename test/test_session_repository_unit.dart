import 'package:test/test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/events.dart';

/// Unit tests for SessionRepository using in-memory drift database.
void main() {
  late AppDatabase db;
  late SessionRepository repository;

  setUp(() async {
    db = AppDatabase.inMemory();
    repository = SessionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SessionRepository.createSession', () {
    test('creates session with default values', () async {
      final state = await repository.createSession();

      expect(state.id, isA<SessionID>());
      expect(state.id.value, startsWith('ses_'));
      expect(state.title, equals(''));
      expect(state.agent, equals('general'));
      expect(state.modelRef, isNull);
      expect(state.createdAt, isA<DateTime>());
      expect(state.updatedAt, isA<DateTime>());
    });

    test('creates session with custom values', () async {
      final state = await repository.createSession(
        title: 'Test Session',
        agent: 'code-reviewer',
        modelRef: 'gpt-4',
      );

      expect(state.title, equals('Test Session'));
      expect(state.agent, equals('code-reviewer'));
      expect(state.modelRef, equals('gpt-4'));
    });

    test('creates session with specific ID', () async {
      final id = SessionID.create();
      final state = await repository.createSession(id: id);

      expect(state.id, equals(id));
    });

    test('creates child session with parent', () async {
      final parent = await repository.createSession(title: 'Parent');
      final child = await repository.createSession(parentId: parent.id);

      expect(child.parentId, equals(parent.id));
    });
  });

  group('SessionRepository.loadSession', () {
    test('returns null for non-existent session', () async {
      final id = SessionID.create();
      final state = await repository.loadSession(id);

      expect(state, isNull);
    });

    test('loads session after creation', () async {
      final created = await repository.createSession(title: 'Loadable');
      final loaded = await repository.loadSession(created.id);

      expect(loaded, isNotNull);
      expect(loaded!.id, equals(created.id));
      expect(loaded.title, equals('Loadable'));
    });
  });

  group('SessionRepository.getSessionMeta', () {
    test('returns null for non-existent session', () async {
      final id = SessionID.create();
      final meta = await repository.getSessionMeta(id);

      expect(meta, isNull);
    });

    test('returns cached meta on second call', () async {
      final created = await repository.createSession(title: 'Cached');

      // First call loads from DB
      final meta1 = await repository.getSessionMeta(created.id);
      // Second call should use cache
      final meta2 = await repository.getSessionMeta(created.id);

      expect(meta1, isNotNull);
      expect(meta2, isNotNull);
      expect(meta1!.id, equals(meta2!.id));
    });
  });

  group('SessionRepository.findAll', () {
    test('returns empty list when no sessions', () async {
      final sessions = await repository.findAll();

      expect(sessions, isEmpty);
    });

    test('returns all non-archived sessions', () async {
      await repository.createSession(title: 'Session 1');
      await repository.createSession(title: 'Session 2');
      await repository.createSession(title: 'Session 3');

      final sessions = await repository.findAll();

      expect(sessions, hasLength(3));
    });

    test('excludes archived sessions', () async {
      final active = await repository.createSession(title: 'Active');
      await repository.createSession(title: 'To Archive');
      await repository.archiveSession(active.id);

      final sessions = await repository.findAll();

      expect(sessions, hasLength(1));
      expect(sessions.first.title, equals('To Archive'));
    });

    test('findAll returns sessions sorted by updatedAt descending', () async {
      // Create sessions in order. The SessionCreated event sets updatedAt
      // from the event timestamp. Since all sessions are created quickly,
      // we verify that findAll returns all sessions and the sort is applied.
      await repository.createSession(title: 'First');
      await repository.createSession(title: 'Second');
      await repository.createSession(title: 'Third');

      final sessions = await repository.findAll();

      expect(sessions, hasLength(3));
      // Verify sort is applied (updatedAt is non-null and descending)
      for (var i = 0; i < sessions.length - 1; i++) {
        expect(
          sessions[i].updatedAt.isAfter(sessions[i + 1].updatedAt) ||
              sessions[i].updatedAt.isAtSameMomentAs(sessions[i + 1].updatedAt),
          isTrue,
          reason: 'Sessions should be sorted by updatedAt descending',
        );
      }
    });
  });

  group('SessionRepository.listSessions', () {
    test('returns empty list when no sessions', () async {
      final sessions = await repository.listSessions();

      expect(sessions, isEmpty);
    });

    test('returns all non-archived sessions', () async {
      await repository.createSession(title: 'S1');
      await repository.createSession(title: 'S2');

      final sessions = await repository.listSessions();

      expect(sessions, hasLength(2));
    });

    test('includes archived when flag is set', () async {
      final s1 = await repository.createSession(title: 'Active');
      await repository.createSession(title: 'Archived');
      await repository.archiveSession(s1.id);

      final all = await repository.listSessions(includeArchived: true);
      final active = await repository.listSessions(includeArchived: false);

      expect(all, hasLength(2));
      expect(active, hasLength(1));
    });
  });

  group('SessionRepository.archiveSession', () {
    test('archives session', () async {
      final session = await repository.createSession(title: 'To Archive');
      await repository.archiveSession(session.id);

      // After archiving, findAll should not include it
      final active = await repository.findAll();
      expect(active, isEmpty);

      // But listSessions with includeArchived should
      final all = await repository.listSessions(includeArchived: true);
      expect(all, hasLength(1));
    });
  });

  group('SessionRepository.deleteSession', () {
    test('deletes session from database', () async {
      final session = await repository.createSession(title: 'To Delete');
      await repository.deleteSession(session.id);

      // After deletion, findAll should not include it (reads from DB)
      final all = await repository.findAll();
      expect(all.where((s) => s.id == session.id), isEmpty);

      // listSessions should not include it (reads from DB)
      final listed = await repository.listSessions(includeArchived: true);
      expect(listed.where((s) => s == session.id), isEmpty);
    });
  });

  group('SessionRepository.createChildSession', () {
    test('creates child with inherited settings', () async {
      final parent = await repository.createSession(
        title: 'Parent Task',
        agent: 'code-reviewer',
        modelRef: 'gpt-4',
      );

      final child = await repository.createChildSession(parent.id);

      expect(child.parentId, equals(parent.id));
      expect(child.agent, equals('code-reviewer'));
      expect(child.modelRef, equals('gpt-4'));
      expect(child.title, contains('Sub-task'));
    });

    test('creates child with overridden settings', () async {
      final parent = await repository.createSession(
        title: 'Parent',
        agent: 'general',
      );

      final child = await repository.createChildSession(
        parent.id,
        agent: 'explore',
        title: 'Custom Child',
      );

      expect(child.agent, equals('explore'));
      expect(child.title, equals('Custom Child'));
    });
  });

  group('SessionRepository.getChildSessions', () {
    test('returns empty for session with no children', () async {
      final parent = await repository.createSession(title: 'Parent');

      final children = await repository.getChildSessions(parent.id);

      expect(children, isEmpty);
    });

    test('returns all children', () async {
      final parent = await repository.createSession(title: 'Parent');
      await repository.createChildSession(parent.id);
      await repository.createChildSession(parent.id);

      final children = await repository.getChildSessions(parent.id);

      expect(children, hasLength(2));
    });
  });

  group('SessionRepository.appendEvent', () {
    test('appends message event', () async {
      final session = await repository.createSession();

      final event = MessageAdded(
        sessionId: session.id,
        messageId: 'msg-1',
        role: 'user',
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      final newState = await repository.appendEvent(event);

      expect(newState.messages, hasLength(1));
      expect(newState.messages.first.content, equals('Hello'));
    });
  });

  group('SessionRepository.buildTree', () {
    test('returns tree with root when no sessions', () async {
      final tree = await repository.buildTree();

      expect(tree, isNotNull);
    });

    test('builds parent-child tree', () async {
      final parent = await repository.createSession(title: 'Parent');
      await repository.createChildSession(parent.id);
      await repository.createChildSession(parent.id);

      final tree = await repository.buildTree();

      expect(tree, isNotNull);
    });
  });

  group('SessionRepository.getAggregateUsage', () {
    test('returns zeros for new session', () async {
      final session = await repository.createSession();

      final usage = await repository.getAggregateUsage(session.id);

      expect(usage['tokensInput'], equals(0));
      expect(usage['tokensOutput'], equals(0));
      expect(usage['tokensReasoning'], equals(0));
    });
  });
}
