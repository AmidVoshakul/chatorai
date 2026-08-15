import 'package:chatorai/core/context/completion_provider.dart';
import 'package:chatorai/core/context/compaction_orchestrator.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCompletionProvider implements CompletionProvider {
  FakeCompletionProvider({this.fakeSummary = '## Goal\n- Summary generated.'});

  final String fakeSummary;
  int callCount = 0;

  @override
  Future<String> generateCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
  }) async {
    callCount++;
    return fakeSummary;
  }
}

void main() {
  group('CompactionOrchestrator', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionID sessionId;

    setUp(() async {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      sessionId = SessionID.create();
      await repository.createSession(
        id: sessionId,
        title: 'Test',
        agent: 'general',
      );
    });

    tearDown(() async {
      await db.close();
    });

    group('compactSessionFromResult', () {
      test('persists pre-compacted messages without calling LLM', () async {
        final fakeAi = FakeCompletionProvider();
        final orchestrator = CompactionOrchestrator(
          repository,
          completionProvider: fakeAi,
        );

        await repository.appendEvent(
          MessageAdded(
            sessionId: sessionId,
            messageId: 'user_trigger',
            role: 'user',
            content: 'Trigger message',
            timestamp: DateTime.now(),
          ),
        );

        final compactedMessages = <Map<String, dynamic>>[
          {
            'role': 'assistant',
            'content': '## Goal\n- Pre-compacted summary.',
            'isCompactionSummary': true,
            'agent': 'compaction',
          },
          {'role': 'user', 'content': 'latest message'},
        ];

        final result = await orchestrator.compactSessionFromResult(
          sessionId,
          compactedMessages,
          model: 'test-model',
          tailStartId: 'user_trigger',
        );

        expect(result, isNotNull);
        expect(result!.messages.length, 2);
        expect(result.messages[0].id, 'user_trigger');
        expect(result.messages[0].isCompactionTrigger, isTrue);
        expect(result.messages[1].id, isNotNull);
        expect(result.messages[1].isCompactionSummary, isTrue);
        expect(result.messages[1].role, MessageRole.assistant);
        expect(result.messages[1].content, contains('Pre-compacted summary'));
        expect(result.messages[1].agent, 'compaction');
        // `compactedContext` is tail-only (summary lives in `messages` as the
        // single source of truth), so it holds just the tail element.
        expect(result.compactedContext, isNotNull);
        expect(result.compactedContext!.length, 1);
        expect(result.compactedContext![0].role, MessageRole.user);
        expect(result.compactedContext![0].content, 'latest message');
        expect(result.compactedContext![0].isCompactionSummary, isFalse);
        expect(fakeAi.callCount, 0);
      });

      test('returns null when session does not exist', () async {
        final fakeAi = FakeCompletionProvider();
        final orchestrator = CompactionOrchestrator(
          repository,
          completionProvider: fakeAi,
        );

        final nonExistentId = SessionID.create();
        final result = await orchestrator.compactSessionFromResult(
          nonExistentId,
          [
            {
              'role': 'assistant',
              'content': 'summary',
              'isCompactionSummary': true,
            },
          ],
          model: 'test-model',
        );

        expect(result, isNull);
        expect(fakeAi.callCount, 0);
      });

      test('preserves old messages alongside compaction summary', () async {
        final fakeAi = FakeCompletionProvider();
        final orchestrator = CompactionOrchestrator(
          repository,
          completionProvider: fakeAi,
        );

        await repository.appendEvent(
          MessageAdded(
            sessionId: sessionId,
            messageId: 'msg_1',
            role: 'user',
            content: 'Hello',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: sessionId,
            messageId: 'msg_2',
            role: 'assistant',
            content: 'Hi there!',
            timestamp: DateTime.now(),
          ),
        );

        final compactedMessages = <Map<String, dynamic>>[
          {
            'role': 'assistant',
            'content': '## Goal\n- Summary.',
            'isCompactionSummary': true,
            'agent': 'compaction',
          },
          {'role': 'user', 'content': 'latest'},
        ];

        final result = await orchestrator.compactSessionFromResult(
          sessionId,
          compactedMessages,
          model: 'test-model',
          tailStartId: 'msg_2',
        );

        expect(result, isNotNull);
        expect(result!.messages.length, greaterThan(2));
        expect(result.messages.any((m) => m.id == 'msg_1'), isTrue);
        expect(
          result.messages.any((m) => m.id == 'msg_2' && m.isCompactionTrigger),
          isTrue,
        );
        expect(result.messages.any((m) => m.isCompactionSummary), isTrue);
        // `compactedContext` is tail-only (summary lives in `messages`).
        expect(result.compactedContext!.length, 1);
        expect(result.compactedContext![0].role, MessageRole.user);
        expect(result.compactedContext![0].content, 'latest');
        expect(result.compactedContext![0].isCompactionSummary, isFalse);
      });
    });

    group('compactSession', () {
      test('calls LLM once and persists result', () async {
        final fakeAi = FakeCompletionProvider();
        final orchestrator = CompactionOrchestrator(
          repository,
          completionProvider: fakeAi,
        );

        await repository.appendEvent(
          MessageAdded(
            sessionId: sessionId,
            messageId: 'msg_1',
            role: 'user',
            content: 'Hello',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: sessionId,
            messageId: 'msg_2',
            role: 'assistant',
            content: 'Hi there!',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: sessionId,
            messageId: 'msg_3',
            role: 'user',
            content: 'How are you?',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: sessionId,
            messageId: 'msg_4',
            role: 'assistant',
            content: 'I am good.',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: sessionId,
            messageId: 'msg_5',
            role: 'user',
            content: 'What is your name?',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: sessionId,
            messageId: 'msg_6',
            role: 'assistant',
            content: 'I am AI.',
            timestamp: DateTime.now(),
          ),
        );

        final result = await orchestrator.compactSession(
          sessionId,
          model: 'test-model',
        );

        expect(result, isNotNull);
        expect(fakeAi.callCount, 1);
        expect(result!.messages.isNotEmpty, true);
        expect(result.messages.any((m) => m.isCompactionSummary), isTrue);
        expect(result.compactedContext, isNotNull);
        expect(result.compactedContext!.isNotEmpty, true);
      });
    });
  });
}
