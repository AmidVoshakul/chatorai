import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';

void main() {
  group('SessionRepository directory', () {
    late AppDatabase db;
    late SessionRepository repository;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('createSession(directory:)', () {
      test('stores and round-trips directory via getSessionMeta', () async {
        final state = await repository.createSession(
          title: 'With Dir',
          agent: 'general',
          directory: '/tmp/workspace',
        );

        final meta = await repository.getSessionMeta(state.id);
        expect(meta, isNotNull);
        expect(meta!.directory, '/tmp/workspace');
      });

      test('directory is null when not provided', () async {
        final state = await repository.createSession(
          title: 'No Dir',
          agent: 'general',
        );

        final meta = await repository.getSessionMeta(state.id);
        expect(meta, isNotNull);
        expect(meta!.directory, isNull);
      });

      test('directory round-trips after reload via loadSession', () async {
        final state = await repository.createSession(
          title: 'Reload Dir',
          agent: 'general',
          directory: '/tmp/workspace',
        );

        final reloaded = await repository.loadSession(state.id);
        expect(reloaded, isNotNull);
        expect(reloaded!.directory, '/tmp/workspace');
      });
    });

    group('createChildSession', () {
      test('inherits parent directory', () async {
        final parent = await repository.createSession(
          title: 'Parent',
          agent: 'general',
          directory: '/tmp/workspace',
        );

        final child = await repository.createChildSession(parent.id);
        expect(child.directory, '/tmp/workspace');
      });

      test('child inherits null when parent has no directory', () async {
        final parent = await repository.createSession(
          title: 'Parent No Dir',
          agent: 'general',
        );

        final child = await repository.createChildSession(parent.id);
        expect(child.directory, isNull);
      });
    });

    group('findSessionsByDirectory', () {
      test('returns only sessions with the exact directory', () async {
        await repository.createSession(
          title: 'In Dir A',
          agent: 'general',
          directory: '/tmp/dir_a',
        );
        await repository.createSession(
          title: 'In Dir B',
          agent: 'general',
          directory: '/tmp/dir_b',
        );

        final results = await repository.findSessionsByDirectory('/tmp/dir_a');
        expect(results.length, 1);
        expect(results.single.title, 'In Dir A');
        expect(results.single.directory, '/tmp/dir_a');
      });

      test('excludes sessions with null directory', () async {
        await repository.createSession(title: 'No Dir', agent: 'general');
        await repository.createSession(
          title: 'With Dir',
          agent: 'general',
          directory: '/tmp/dir',
        );

        final results = await repository.findSessionsByDirectory('/tmp/dir');
        expect(results.length, 1);
        expect(results.single.title, 'With Dir');
      });

      test('excludes child sessions', () async {
        final parent = await repository.createSession(
          title: 'Parent',
          agent: 'general',
          directory: '/tmp/dir',
        );

        await repository.createChildSession(parent.id);

        final results = await repository.findSessionsByDirectory('/tmp/dir');
        expect(results.length, 1);
        expect(results.single.title, 'Parent');
        expect(results.single.parentId, isNull);
      });

      test('orders by updatedAt descending', () async {
        final s1 = await repository.createSession(
          title: 'Old',
          agent: 'general',
          directory: '/tmp/dir',
        );

        await Future.delayed(const Duration(milliseconds: 10));

        final s2 = await repository.createSession(
          title: 'New',
          agent: 'general',
          directory: '/tmp/dir',
        );

        // Touch s1 to make it newer than s2.
        await repository.appendEvent(
          SessionTitleUpdated(
            sessionId: s1.id,
            title: 'Old Updated',
            timestamp: DateTime.now(),
          ),
        );

        final results = await repository.findSessionsByDirectory('/tmp/dir');
        expect(results.length, 2);
        expect(results.first.title, 'Old Updated');
        expect(results.last.title, 'New');
      });

      test('returns empty list when no sessions match', () async {
        final results = await repository.findSessionsByDirectory('/tmp/none');
        expect(results, isEmpty);
      });
    });
  });
}
