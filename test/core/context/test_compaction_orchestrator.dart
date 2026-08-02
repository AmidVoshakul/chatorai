import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/context/completion_provider.dart';
import 'package:chatorai/core/context/compaction_orchestrator.dart';
import 'package:chatorai/core/context/compaction_service.dart';
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
      await AgentRegistry().init();
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

        // Add a user message as the trigger for compaction
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
          {'role': 'system', 'content': '## Goal\n- Pre-compacted summary.'},
          {'role': 'user', 'content': 'latest message'},
        ];

        final result = await orchestrator.compactSessionFromResult(
          sessionId,
          compactedMessages,
          model: 'test-model',
          tailStartId: 'user_trigger',
          retainedIds: const ['latest_msg_id'],
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
        expect(result.compactedContext, isNotNull);
        expect(result.compactedContext!.length, 2);
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
            {'role': 'system', 'content': 'summary'},
          ],
          model: 'test-model',
        );

        expect(result, isNull);
        expect(fakeAi.callCount, 0);
      });
    });

    group('compactSession', () {
      test('calls LLM once and persists result', () async {
        final fakeAi = FakeCompletionProvider();
        final orchestrator = CompactionOrchestrator(
          repository,
          completionProvider: fakeAi,
        );

        // Add enough messages to trigger compaction (need > tailTurns*2 = 4 messages)
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
      });
    });
  });
}
