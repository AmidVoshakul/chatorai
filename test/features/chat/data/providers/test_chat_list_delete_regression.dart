import 'dart:io';

import 'package:chatorai/core/session/database.dart' as db;
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/chat/chat_models.dart';
import 'package:chatorai/gui/features/chat/data/providers/chat_providers.dart';
import 'package:chatorai/providers.dart' show sessionRepositoryProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

/// Seeds the chat list with a metadata entry so ensureChatLoaded has a
/// `current` chat to rebuild (the stale-metadata path of the deletion bug).
class _SeedableChatListNotifier extends ChatListNotifier {
  _SeedableChatListNotifier(this._initialChats);
  final List<Chat> _initialChats;

  @override
  AsyncValue<List<Chat>> build() => AsyncValue.data(_initialChats);
}

Message _assistant(String id, String content) {
  final now = DateTime.now();
  return Message(
    id: id,
    role: MessageRole.assistant,
    content: content,
    timestamp: now,
    isComplete: true,
    synthetic: false,
    tokensInput: 0,
    tokensOutput: 0,
    tokensReasoning: 0,
    contextLength: 0,
    model: null,
    agent: null,
    reasoning: null,
    partsJson: const [],
  );
}

Message _user(String id, String content) {
  final now = DateTime.now();
  return Message(
    id: id,
    role: MessageRole.user,
    content: content,
    timestamp: now,
    isComplete: true,
    synthetic: false,
    tokensInput: 0,
    tokensOutput: 0,
    tokensReasoning: 0,
    contextLength: 0,
    model: null,
    agent: null,
    reasoning: null,
    partsJson: const [],
  );
}

void main() {
  late Directory tempDir;
  late db.AppDatabase _db;
  late SessionRepository realRepository;
  late _MockSessionRepository mockRepository;
  const sessionId = 'ses_del_regression';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_del_regression');
    _db = db.AppDatabase.file('${tempDir.path}/db.sqlite');
    realRepository = SessionRepository(_db);
    mockRepository = _MockSessionRepository();

    registerFallbackValue(SessionID.fromString('ses_fallback'));
    registerFallbackValue(
      MessageAdded(
        sessionId: SessionID.fromString(sessionId),
        messageId: 'x',
        role: 'user',
        content: '',
        timestamp: DateTime.now(),
      ),
    );
    registerFallbackValue(
      MessageDeleted(
        sessionId: SessionID.fromString(sessionId),
        messageId: 'x',
        timestamp: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await _db.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<List<db.Event>> _appendAll(List<SessionEvent> events) async {
    for (final e in events) {
      await realRepository.appendEvent(e);
    }
    return realRepository.getEventRowsForSessions([
      SessionID.fromString(sessionId),
    ]);
  }

  test('deleting all replies keeps only the remaining user message '
      '(deferred-deletion regression)', () async {
    final sid = SessionID.fromString(sessionId);
    final t0 = DateTime.now();
    final rows = await _appendAll([
      // /test answer: placeholder + task card + streamed answer.
      MessageAdded(
        sessionId: sid,
        messageId: 'msg_a',
        role: 'assistant',
        content: '',
        timestamp: t0,
      ),
      TaskPartStarted(
        sessionId: sid,
        partId: 'task-1',
        description: 'command test',
        agent: 'general',
        taskSessionId: 'ses_child',
        timestamp: t0,
      ),
      TaskPartCompleted(
        sessionId: sid,
        partId: 'task-1',
        toolCallsCount: 0,
        timestamp: t0.add(const Duration(seconds: 36)),
      ),
      TaskCompleted(
        sessionId: sid,
        taskId: 'task-1',
        output: 'This is custom commands',
        timestamp: t0.add(const Duration(seconds: 37)),
      ),
      MessageUpdated(
        sessionId: sid,
        messageId: 'msg_a',
        content: 'Hi! The /test command returned the result.',
        timestamp: t0.add(const Duration(seconds: 38)),
      ),
      // User deletes the /test answer — the UI failed to reflect it (the
      // stale-metadata bug), but the event WAS persisted.
      MessageDeleted(
        sessionId: sid,
        messageId: 'msg_a',
        timestamp: t0.add(const Duration(seconds: 50)),
      ),
      // Second plain exchange.
      MessageAdded(
        sessionId: sid,
        messageId: 'msg_u',
        role: 'user',
        content: 'plain question',
        timestamp: t0.add(const Duration(minutes: 1)),
      ),
      MessageAdded(
        sessionId: sid,
        messageId: 'msg_b',
        role: 'assistant',
        content: '',
        timestamp: t0.add(const Duration(minutes: 1, seconds: 1)),
      ),
      MessageUpdated(
        sessionId: sid,
        messageId: 'msg_b',
        content: 'plain answer',
        timestamp: t0.add(const Duration(minutes: 1, seconds: 2)),
      ),
      // User deletes the last assistant reply.
      MessageDeleted(
        sessionId: sid,
        messageId: 'msg_b',
        timestamp: t0.add(const Duration(minutes: 2)),
      ),
    ]);

    when(
      () => mockRepository.getEventRowsForSessions(any()),
    ).thenAnswer((_) async => rows);
    when(
      () => mockRepository.readChatSnapshot(any()),
    ).thenAnswer((_) async => null);

    final staleMetadata = Chat(
      id: sessionId,
      title: 'Deletion regression',
      // Stale in-memory view: the provider still shows BOTH assistant
      // bubbles even though msg_a was already deleted in the event log.
      messages: [
        _assistant('msg_a', 'Hi! The /test command returned the result.'),
        _user('msg_u', 'plain question'),
        _assistant('msg_b', 'plain answer'),
      ],
      createdAt: t0,
      updatedAt: t0,
    );

    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWith((_) => mockRepository),
        chatListProvider.overrideWith(
          () => _SeedableChatListNotifier([staleMetadata]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final chat = await container
        .read(chatListProvider.notifier)
        .ensureChatLoaded(sessionId, forceRefresh: true);

    expect(chat, isNotNull);
    // msg_a (deleted earlier, deferred by the stale view) and msg_b (deleted
    // just now) are both gone; only the user message survives.
    expect(chat!.messages.map((m) => m.id).toList(), ['msg_u']);
  });

  test('deleting the only message clears the chat to an empty list', () async {
    final sid = SessionID.fromString(sessionId);
    final t0 = DateTime.now();
    final rows = await _appendAll([
      MessageAdded(
        sessionId: sid,
        messageId: 'msg_only',
        role: 'assistant',
        content: 'only answer',
        timestamp: t0,
      ),
      MessageDeleted(
        sessionId: sid,
        messageId: 'msg_only',
        timestamp: t0.add(const Duration(seconds: 5)),
      ),
    ]);

    when(
      () => mockRepository.getEventRowsForSessions(any()),
    ).thenAnswer((_) async => rows);
    when(
      () => mockRepository.readChatSnapshot(any()),
    ).thenAnswer((_) async => null);

    final staleMetadata = Chat(
      id: sessionId,
      title: 'Empty after delete',
      messages: [_assistant('msg_only', 'only answer')],
      createdAt: t0,
      updatedAt: t0,
    );

    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWith((_) => mockRepository),
        chatListProvider.overrideWith(
          () => _SeedableChatListNotifier([staleMetadata]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final chat = await container
        .read(chatListProvider.notifier)
        .ensureChatLoaded(sessionId, forceRefresh: true);

    expect(chat, isNotNull);
    expect(chat!.messages, isEmpty);
  });
}
