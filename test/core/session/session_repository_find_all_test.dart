import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';

void main() {
  group('SessionRepository.findAll()', () {
    late AppDatabase db;
    late SessionRepository repository;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('findAll() returns sessions sorted by updatedAt DESC', () async {
      // Create three sessions with explicit timestamps to ensure ordering
      final t1 = DateTime(2025, 1, 1, 10, 0, 0);
      final t2 = DateTime(2025, 1, 1, 11, 0, 0);
      final t3 = DateTime(2025, 1, 1, 12, 0, 0);

      // Insert sessions directly with controlled timestamps
      // so we can guarantee the sort order
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 'ses_oldest',
              title: const Value('Oldest Session'),
              agent: const Value('general'),
              createdAt: t1,
              updatedAt: t1,
            ),
          );

      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 'ses_middle',
              title: const Value('Middle Session'),
              agent: const Value('general'),
              createdAt: t2,
              updatedAt: t2,
            ),
          );

      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 'ses_newest',
              title: const Value('Newest Session'),
              agent: const Value('general'),
              createdAt: t3,
              updatedAt: t3,
            ),
          );

      final all = await repository.findAll();

      // All 3 sessions should be returned
      expect(all.length, 3);

      // Should be sorted by updatedAt DESC (most recently updated first)
      expect(all[0].title, 'Newest Session');
      expect(all[1].title, 'Middle Session');
      expect(all[2].title, 'Oldest Session');

      // Verify the ordering is strictly by updatedAt descending
      for (int i = 0; i < all.length - 1; i++) {
        expect(
          all[i].updatedAt.isAfter(all[i + 1].updatedAt) ||
              all[i].updatedAt.isAtSameMomentAs(all[i + 1].updatedAt),
          isTrue,
          reason:
              'Session at index $i (${all[i].title}) should have '
              'updatedAt >= session at index ${i + 1} (${all[i + 1].title})',
        );
      }
    });

    test('findAll() excludes archived sessions', () async {
      // Create two sessions
      final state1 = await repository.createSession(
        agent: 'general',
        title: 'Active Session',
      );

      await Future.delayed(const Duration(milliseconds: 10));

      final state2 = await repository.createSession(
        agent: 'general',
        title: 'To-be-archived Session',
      );

      // Verify both are returned
      var all = await repository.findAll();
      expect(all.length, 2);

      // Archive state2 via event sourcing
      await repository.archiveSession(state2.id);

      // Now findAll should only return the non-archived session
      all = await repository.findAll();
      expect(all.length, 1);
      expect(all.first.id, state1.id);
      expect(all.first.title, 'Active Session');
    });

    test('findAll() with no sessions returns empty list', () async {
      final all = await repository.findAll();
      expect(all, isEmpty);
    });

    test(
      'findAll() returns only non-archived when mix of archived and active',
      () async {
        // Create 5 sessions
        final states = <SessionState>[];
        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(milliseconds: 10));
          states.add(
            await repository.createSession(
              agent: 'general',
              title: 'Session $i',
            ),
          );
        }

        // Archive sessions at indices 1 and 3
        await repository.archiveSession(states[1].id);
        await repository.archiveSession(states[3].id);

        final all = await repository.findAll();
        expect(all.length, 3);

        // Verify none are archived
        for (final session in all) {
          expect(session.archivedAt, equals(null));
        }

        // Verify the correct sessions are returned
        final titles = all.map((s) => s.title).toSet();
        expect(titles.contains('Session 0'), isTrue);
        expect(titles.contains('Session 2'), isTrue);
        expect(titles.contains('Session 4'), isTrue);
        expect(titles.contains('Session 1'), isFalse);
        expect(titles.contains('Session 3'), isFalse);
      },
    );

    test(
      'findAll() sorts archived-last even if archived has latest timestamp',
      () async {
        // Create two sessions
        await repository.createSession(agent: 'general', title: 'Active Old');

        await Future.delayed(const Duration(milliseconds: 10));

        final toArchiveState = await repository.createSession(
          agent: 'general',
          title: 'To Archive New',
        );

        // Archive the newer one
        await repository.archiveSession(toArchiveState.id);

        final all = await repository.findAll();
        expect(all.length, 1);
        expect(all.first.title, 'Active Old');
      },
    );
  });
}
