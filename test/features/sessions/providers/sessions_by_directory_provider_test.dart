import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chatorai/core/session/session_db_provider.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/sessions/providers/session_providers.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  group('sessionsByDirectoryProvider', () {
    test('returns repository results for the requested directory', () async {
      final mockRepo = MockSessionRepository();
      when(() => mockRepo.findSessionsByDirectory('/tmp/dir')).thenAnswer(
        (_) async => [
          SessionState(
            id: SessionID.fromString('ses_1'),
            title: 'Session 1',
            agent: 'general',
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
            directory: '/tmp/dir',
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        sessionsByDirectoryProvider('/tmp/dir').future,
      );
      expect(result.length, 1);
      expect(result.single.title, 'Session 1');
      expect(result.single.directory, '/tmp/dir');
    });

    test('different family arguments produce separate results', () async {
      final mockRepo = MockSessionRepository();
      when(() => mockRepo.findSessionsByDirectory('/tmp/dir_a')).thenAnswer(
        (_) async => [
          SessionState(
            id: SessionID.fromString('ses_a'),
            title: 'A',
            agent: 'general',
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
            directory: '/tmp/dir_a',
          ),
        ],
      );
      when(() => mockRepo.findSessionsByDirectory('/tmp/dir_b')).thenAnswer(
        (_) async => [
          SessionState(
            id: SessionID.fromString('ses_b'),
            title: 'B',
            agent: 'general',
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
            directory: '/tmp/dir_b',
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final resultA = await container.read(
        sessionsByDirectoryProvider('/tmp/dir_a').future,
      );
      final resultB = await container.read(
        sessionsByDirectoryProvider('/tmp/dir_b').future,
      );

      expect(resultA.length, 1);
      expect(resultA.single.title, 'A');
      expect(resultB.length, 1);
      expect(resultB.single.title, 'B');
    });

    test('returns empty list when repository returns empty', () async {
      final mockRepo = MockSessionRepository();
      when(
        () => mockRepo.findSessionsByDirectory('/tmp/empty'),
      ).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        sessionsByDirectoryProvider('/tmp/empty').future,
      );
      expect(result, isEmpty);
    });
  });
}
