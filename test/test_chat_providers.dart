import 'dart:async';

import 'package:chatorai/core/session/database.dart' as db;
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_db_provider.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/data/models/chat/message_converter.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart'
    as chat_models;
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
import 'package:chatorai/features/sessions/providers/sidebar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

chat_models.Chat _chat(String id, {String title = ''}) {
  return chat_models.Chat(
    id: id,
    title: title,
    messages: const [],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

/// Polls until [chatListProvider] leaves its loading state. NotifierProvider
/// has no `.future`, so we rely on a short polling loop instead.
Future<void> waitForLoad(ProviderContainer container) async {
  for (var i = 0; i < 50; i++) {
    if (!container.read(chatListProvider).isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(SessionID.fromString('ses_fallback'));
  });

  group('CurrentChatIdNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is null', () {
      final state = container.read(currentChatIdProvider);
      expect(state, isNull);
    });

    test('setChatId updates state', () {
      container.read(currentChatIdProvider.notifier).setChatId('chat-123');
      final state = container.read(currentChatIdProvider);
      expect(state, 'chat-123');
    });

    test('clearChatId sets state to null', () {
      container.read(currentChatIdProvider.notifier).setChatId('chat-123');
      container.read(currentChatIdProvider.notifier).clearChatId();
      final state = container.read(currentChatIdProvider);
      expect(state, isNull);
    });
  });

  group('currentChatProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('returns null when currentChatId is null', () {
      final chat = container.read(currentChatProvider);
      expect(chat, isNull);
    });
  });

  group('ChatListNotifier.updateChat', () {
    late ProviderContainer container;

    ProviderContainer buildContainer({bool hangLoad = false}) {
      final mock = MockSessionRepository();
      when(() => mock.cleanupOrphanSessions()).thenAnswer((_) async => 0);
      if (hangLoad) {
        final completer = Completer<List<SessionState>>();
        when(() => mock.findAll()).thenAnswer((_) => completer.future);
      } else {
        when(() => mock.findAll()).thenAnswer((_) async => <SessionState>[]);
      }
      return ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => mock),
        ],
      );
    }

    setUp(() {
      container = buildContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('adds the chat when the list is empty', () async {
      await waitForLoad(container);
      final notifier = container.read(chatListProvider.notifier);
      final chat = _chat('a');

      notifier.updateChat(chat);

      final chats = container.read(chatListProvider).value!;
      expect(chats.map((c) => c.id), ['a']);
    });

    test('upserts while the list is still loading', () async {
      container.dispose();
      container = buildContainer(hangLoad: true);
      addTearDown(container.dispose);
      final notifier = container.read(chatListProvider.notifier);
      expect(container.read(chatListProvider).isLoading, isTrue);

      notifier.updateChat(_chat('a', title: 'In-flight'));

      final chats = container.read(chatListProvider).value!;
      expect(chats.map((c) => c.id), ['a']);
      expect(chats.single.title, 'In-flight');
    });

    test('replaces an existing chat with the same id', () async {
      await waitForLoad(container);
      final notifier = container.read(chatListProvider.notifier);
      notifier.updateChat(_chat('a'));
      notifier.updateChat(_chat('a', title: 'Renamed'));

      final chats = container.read(chatListProvider).value!;
      expect(chats, hasLength(1));
      expect(chats.single.title, 'Renamed');
    });

    test('keeps unrelated chats when adding a new one', () async {
      await waitForLoad(container);
      final notifier = container.read(chatListProvider.notifier);
      notifier.updateChat(_chat('a'));
      notifier.updateChat(_chat('b'));

      final chats = container.read(chatListProvider).value!;
      expect(chats.map((c) => c.id).toSet(), {'a', 'b'});
    });
  });

  group('chatListLoadingProvider', () {
    test('returns true while the chat list is loading', () {
      final mock = MockSessionRepository();
      when(() => mock.cleanupOrphanSessions()).thenAnswer((_) async => 0);
      final completer = Completer<List<SessionState>>();
      when(() => mock.findAll()).thenAnswer((_) => completer.future);
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => mock),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(chatListLoadingProvider), isTrue);
      expect(container.read(chatListProvider).isLoading, isTrue);
    });
  });

  group('ChatListNotifier.load', () {
    test('load builds metadata-only list without fetching events', () async {
      final mock = MockSessionRepository();
      when(() => mock.cleanupOrphanSessions()).thenAnswer((_) async => 0);
      when(() => mock.findAll()).thenAnswer(
        (_) async => [
          SessionState(
            id: SessionID.fromString('ses_a'),
            title: 'Session A',
            agent: 'general',
            createdAt: DateTime(2025, 1, 1, 10, 0, 0),
            updatedAt: DateTime(2025, 1, 1, 12, 0, 0),
          ),
          SessionState(
            id: SessionID.fromString('ses_b'),
            title: 'Session B',
            agent: 'general',
            createdAt: DateTime(2025, 1, 1, 9, 0, 0),
            updatedAt: DateTime(2025, 1, 1, 11, 0, 0),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => mock),
        ],
      );
      addTearDown(container.dispose);

      await waitForLoad(container);
      final chatState = container.read(chatListProvider);
      final chats = chatState.value!;
      expect(chats, hasLength(2));
      final byId = {for (final c in chats) c.id: c};
      expect(byId.keys, containsAll(['ses_a', 'ses_b']));
      expect(byId['ses_a']!.messages, isEmpty);
      expect(byId['ses_b']!.messages, isEmpty);
      expect(byId['ses_a']!.title, 'Session A');
      expect(byId['ses_b']!.title, 'Session B');
      expect(chats[0].updatedAt.isAfter(chats[1].updatedAt), isTrue);

      verifyNever(() => mock.getEventRowsForSessions(any()));
    });

    test(
      'real in-memory DB: chat list loads with empty messages (metadata only)',
      () async {
        final dbInstance = db.AppDatabase.inMemory();
        final repository = SessionRepository(dbInstance);
        addTearDown(dbInstance.close);

        final session = await repository.createSession(
          title: 'Real Session',
          agent: 'general',
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm1',
            role: 'user',
            content: 'hi from real db',
            timestamp: DateTime.now(),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        await waitForLoad(container);
        final chats = container.read(chatListProvider).value!;
        expect(chats, hasLength(1));
        expect(chats.single.id, session.id.value);
        expect(chats.single.messages, isEmpty);
      },
    );

    test(
      'real in-memory DB: ensureChatLoaded lazily replays messages',
      () async {
        final dbInstance = db.AppDatabase.inMemory();
        final repository = SessionRepository(dbInstance);
        addTearDown(dbInstance.close);

        final session = await repository.createSession(
          title: 'Lazy Session',
          agent: 'general',
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm1',
            role: 'user',
            content: 'hi from real db',
            timestamp: DateTime.now(),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        await waitForLoad(container);
        final chats = container.read(chatListProvider).value!;
        expect(chats, hasLength(1));
        expect(chats.single.messages, isEmpty);

        final notifier = container.read(chatListProvider.notifier);
        final loaded = await notifier.ensureChatLoaded(session.id.value);
        expect(loaded, isNotNull);
        expect(loaded!.messages, hasLength(1));
        expect(loaded.messages.single.content, 'hi from real db');

        // Second call should return cached result without hitting DB again
        final cached = await notifier.ensureChatLoaded(session.id.value);
        expect(cached, isNotNull);
        expect(cached!.messages, hasLength(1));
      },
    );

    test(
      'real in-memory DB: ensureChatLoaded preserves final text via TextEnded',
      () async {
        final dbInstance = db.AppDatabase.inMemory();
        final repository = SessionRepository(dbInstance);
        addTearDown(dbInstance.close);

        final session = await repository.createSession(
          title: 'Durable Filter',
          agent: 'general',
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm1',
            role: 'user',
            content: 'hi',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          TextStarted(
            sessionId: session.id,
            messageId: 'm2',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          TextDelta(
            sessionId: session.id,
            messageId: 'm2',
            delta: 'hel',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          TextDelta(
            sessionId: session.id,
            messageId: 'm2',
            delta: 'lo',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          TextEnded(
            sessionId: session.id,
            messageId: 'm2',
            fullText: 'hello',
            timestamp: DateTime.now(),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        await waitForLoad(container);
        final chats = container.read(chatListProvider).value!;
        expect(chats, hasLength(1));
        expect(chats.single.messages, isEmpty);

        final notifier = container.read(chatListProvider.notifier);
        final loaded = await notifier.ensureChatLoaded(session.id.value);
        expect(loaded, isNotNull);
        expect(loaded!.messages, hasLength(2));
        final assistant = loaded.messages.last;
        expect(assistant.role.name, 'assistant');
        expect(assistant.content, 'hello');

        // RED test: verify rendered text parts contain 'hello' (fails before Fix A)
        final chatMsg = messageToChatMessage(assistant);
        final text = chatMsg is AssistantMessage
            ? chatMsg.parts.whereType<TextPart>().map((p) => p.content).join()
            : '';
        expect(text, 'hello');
      },
    );

    test('ensureChatLoaded loads and caches', () async {
      final mock = MockSessionRepository();
      when(() => mock.cleanupOrphanSessions()).thenAnswer((_) async => 0);
      when(() => mock.findAll()).thenAnswer(
        (_) async => [
          SessionState(
            id: SessionID.fromString('ses_a'),
            title: 'Session A',
            agent: 'general',
            createdAt: DateTime(2025, 1, 1, 10, 0, 0),
            updatedAt: DateTime(2025, 1, 1, 12, 0, 0),
          ),
        ],
      );
      when(() => mock.readChatSnapshot(any())).thenAnswer((_) async => null);
      when(() => mock.getEventRowsForSessions(any())).thenAnswer(
        (_) async => [
          db.Event(
            id: 1,
            sessionId: 'ses_a',
            eventType: 'SessionCreated',
            eventData:
                '{"type":"SessionCreated","title":"Session A","agent":"general"}',
            sequence: 1,
            createdAt: DateTime(2025, 1, 1, 10, 0, 0),
          ),
          db.Event(
            id: 2,
            sessionId: 'ses_a',
            eventType: 'MessageAdded',
            eventData:
                '{"type":"MessageAdded","messageId":"m1","role":"user","content":"hello"}',
            sequence: 2,
            createdAt: DateTime(2025, 1, 1, 10, 0, 1),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => mock),
        ],
      );
      addTearDown(container.dispose);

      await waitForLoad(container);
      final notifier = container.read(chatListProvider.notifier);
      final loaded = await notifier.ensureChatLoaded('ses_a');
      expect(loaded, isNotNull);
      expect(loaded!.messages, hasLength(1));
      expect(loaded.messages.single.content, 'hello');

      // Second call should return cached result
      final cached = await notifier.ensureChatLoaded('ses_a');
      expect(cached, isNotNull);
      expect(cached!.messages, hasLength(1));
      verify(() => mock.getEventRowsForSessions(any())).called(1);
    });

    test(
      'deleted chat is not resurrected by in-flight ensureChatLoaded',
      () async {
        final mock = MockSessionRepository();
        when(() => mock.cleanupOrphanSessions()).thenAnswer((_) async => 0);
        when(() => mock.findAll()).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_a'),
              title: 'Session A',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1, 10, 0, 0),
              updatedAt: DateTime(2025, 1, 1, 12, 0, 0),
            ),
          ],
        );
        when(() => mock.readChatSnapshot(any())).thenAnswer((_) async => null);
        when(() => mock.deleteSession(any())).thenAnswer((_) async {});
        final eventCompleter = Completer<List<db.Event>>();
        when(
          () => mock.getEventRowsForSessions(any()),
        ).thenAnswer((_) => eventCompleter.future);

        final container = ProviderContainer(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) async => mock),
          ],
        );
        addTearDown(container.dispose);

        await waitForLoad(container);
        final notifier = container.read(chatListProvider.notifier);
        final loadFuture = notifier.ensureChatLoaded('ses_a');
        // Delete the chat while the event fetch is still in-flight.
        await notifier.deleteChat('ses_a');
        // Complete the events — the in-flight load should see the chat is gone.
        eventCompleter.complete([]);
        await loadFuture;
        final chats = container.read(chatListProvider).value;
        expect(chats, isNotNull);
        expect(chats!.any((c) => c.id == 'ses_a'), isFalse);
      },
    );

    test('ensureChatLoaded forceRefresh re-queries and second result wins', () async {
      final mock = MockSessionRepository();
      when(() => mock.cleanupOrphanSessions()).thenAnswer((_) async => 0);
      when(() => mock.findAll()).thenAnswer(
        (_) async => [
          SessionState(
            id: SessionID.fromString('ses_a'),
            title: 'Session A',
            agent: 'general',
            createdAt: DateTime(2025, 1, 1, 10, 0, 0),
            updatedAt: DateTime(2025, 1, 1, 12, 0, 0),
          ),
        ],
      );
      when(() => mock.readChatSnapshot(any())).thenAnswer((_) async => null);
      var callCount = 0;
      when(() => mock.getEventRowsForSessions(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return [
            db.Event(
              id: 1,
              sessionId: 'ses_a',
              eventType: 'SessionCreated',
              eventData:
                  '{"type":"SessionCreated","title":"Session A","agent":"general"}',
              sequence: 1,
              createdAt: DateTime(2025, 1, 1, 10, 0, 0),
            ),
            db.Event(
              id: 2,
              sessionId: 'ses_a',
              eventType: 'MessageAdded',
              eventData:
                  '{"type":"MessageAdded","messageId":"m1","role":"user","content":"hello"}',
              sequence: 2,
              createdAt: DateTime(2025, 1, 1, 10, 0, 1),
            ),
          ];
        }
        return [
          db.Event(
            id: 1,
            sessionId: 'ses_a',
            eventType: 'SessionCreated',
            eventData:
                '{"type":"SessionCreated","title":"Session A","agent":"general"}',
            sequence: 1,
            createdAt: DateTime(2025, 1, 1, 10, 0, 0),
          ),
          db.Event(
            id: 2,
            sessionId: 'ses_a',
            eventType: 'MessageAdded',
            eventData:
                '{"type":"MessageAdded","messageId":"m1","role":"user","content":"hello"}',
            sequence: 2,
            createdAt: DateTime(2025, 1, 1, 10, 0, 1),
          ),
          db.Event(
            id: 3,
            sessionId: 'ses_a',
            eventType: 'MessageAdded',
            eventData:
                '{"type":"MessageAdded","messageId":"m2","role":"user","content":"world"}',
            sequence: 3,
            createdAt: DateTime(2025, 1, 1, 10, 0, 2),
          ),
        ];
      });

      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => mock),
        ],
      );
      addTearDown(container.dispose);

      await waitForLoad(container);
      final notifier = container.read(chatListProvider.notifier);
      final loaded = await notifier.ensureChatLoaded('ses_a');
      expect(loaded, isNotNull);
      expect(loaded!.messages, hasLength(1));

      final refreshed = await notifier.ensureChatLoaded(
        'ses_a',
        forceRefresh: true,
      );
      expect(refreshed, isNotNull);
      expect(refreshed!.messages, hasLength(2));
      verify(() => mock.getEventRowsForSessions(any())).called(2);
    });

    group('shouldBuildInline', () {
      test('boundary: 0, 1, 2000 are inline', () {
        expect(ChatListNotifier.shouldBuildInline(0), isTrue);
        expect(ChatListNotifier.shouldBuildInline(1), isTrue);
        expect(ChatListNotifier.shouldBuildInline(2000), isTrue);
      });

      test('boundary: 2001, 10000 are isolate', () {
        expect(ChatListNotifier.shouldBuildInline(2001), isFalse);
        expect(ChatListNotifier.shouldBuildInline(10000), isFalse);
      });
    });

    test(
      'real in-memory DB: ensureChatLoaded uses inline build for small chat',
      () async {
        final dbInstance = db.AppDatabase.inMemory();
        final repository = SessionRepository(dbInstance);
        addTearDown(dbInstance.close);

        final session = await repository.createSession(
          title: 'Inline Session',
          agent: 'general',
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm1',
            role: 'user',
            content: 'inline test',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm2',
            role: 'assistant',
            content: 'inline reply',
            timestamp: DateTime.now(),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        await waitForLoad(container);
        final notifier = container.read(chatListProvider.notifier);
        final loaded = await notifier.ensureChatLoaded(session.id.value);
        expect(loaded, isNotNull);
        expect(loaded!.messages, hasLength(2));
        expect(loaded.messages[0].content, 'inline test');
        expect(loaded.messages[1].content, 'inline reply');
      },
    );

    group('snapshot cache', () {
      test('uses snapshot when events_count matches', () async {
        final dbInstance = db.AppDatabase.inMemory();
        final repository = SessionRepository(dbInstance);
        addTearDown(dbInstance.close);

        final session = await repository.createSession(
          title: 'Snapshot Session',
          agent: 'general',
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm1',
            role: 'user',
            content: 'hello from snapshot',
            timestamp: DateTime.now(),
          ),
        );

        // Write a valid snapshot.
        final state = await repository.loadSessionState(session.id);
        final chat = sessionStateToChat(state);
        final messages = chat.messages;
        await repository.writeChatSnapshot(
          session.id,
          messages.map((m) => messageToChatMessage(m)).toList(),
        );

        final container = ProviderContainer(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        await waitForLoad(container);
        final notifier = container.read(chatListProvider.notifier);
        final loaded = await notifier.ensureChatLoaded(session.id.value);
        expect(loaded, isNotNull);
        expect(loaded!.messages, hasLength(1));
        expect(loaded.messages.single.content, 'hello from snapshot');
      });

      test('replays events when snapshot is stale', () async {
        final dbInstance = db.AppDatabase.inMemory();
        final repository = SessionRepository(dbInstance);
        addTearDown(dbInstance.close);

        final session = await repository.createSession(
          title: 'Stale Session',
          agent: 'general',
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm1',
            role: 'user',
            content: 'first',
            timestamp: DateTime.now(),
          ),
        );

        // Write snapshot with 1 event.
        final state = await repository.loadSessionState(session.id);
        final chat = sessionStateToChat(state);
        await repository.writeChatSnapshot(
          session.id,
          chat.messages.map((m) => messageToChatMessage(m)).toList(),
        );

        // Add another event after snapshot.
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm2',
            role: 'user',
            content: 'second',
            timestamp: DateTime.now(),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        await waitForLoad(container);
        final notifier = container.read(chatListProvider.notifier);
        final loaded = await notifier.ensureChatLoaded(session.id.value);
        expect(loaded, isNotNull);
        expect(loaded!.messages, hasLength(2));
        expect(loaded.messages[0].content, 'first');
        expect(loaded.messages[1].content, 'second');
      });

      test('forceRefresh bypasses snapshot', () async {
        final dbInstance = db.AppDatabase.inMemory();
        final repository = SessionRepository(dbInstance);
        addTearDown(dbInstance.close);

        final session = await repository.createSession(
          title: 'Force Session',
          agent: 'general',
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm1',
            role: 'user',
            content: 'first',
            timestamp: DateTime.now(),
          ),
        );

        // Write snapshot.
        final state = await repository.loadSessionState(session.id);
        final chat = sessionStateToChat(state);
        await repository.writeChatSnapshot(
          session.id,
          chat.messages.map((m) => messageToChatMessage(m)).toList(),
        );

        // Add another event.
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm2',
            role: 'user',
            content: 'second',
            timestamp: DateTime.now(),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        await waitForLoad(container);
        final notifier = container.read(chatListProvider.notifier);
        final loaded = await notifier.ensureChatLoaded(
          session.id.value,
          forceRefresh: true,
        );
        expect(loaded, isNotNull);
        expect(loaded!.messages, hasLength(2));
      });

      test('deleteChat removes snapshot', () async {
        final dbInstance = db.AppDatabase.inMemory();
        final repository = SessionRepository(dbInstance);
        addTearDown(dbInstance.close);

        final session = await repository.createSession(
          title: 'Delete Session',
          agent: 'general',
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm1',
            role: 'user',
            content: 'bye',
            timestamp: DateTime.now(),
          ),
        );

        final state = await repository.loadSessionState(session.id);
        final chat = sessionStateToChat(state);
        await repository.writeChatSnapshot(
          session.id,
          chat.messages.map((m) => messageToChatMessage(m)).toList(),
        );

        // Verify snapshot exists.
        var snap = await repository.readChatSnapshot(session.id);
        expect(snap, isNotNull);

        final container = ProviderContainer(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        await waitForLoad(container);
        final notifier = container.read(chatListProvider.notifier);
        await notifier.deleteChat(session.id.value);

        snap = await repository.readChatSnapshot(session.id);
        expect(snap, isNull);
      });

      test('ensureChatLoaded preserves per-message tokens from StepEnded',
          () async {
        final dbInstance = db.AppDatabase.inMemory();
        final repository = SessionRepository(dbInstance);
        addTearDown(dbInstance.close);

        final session = await repository.createSession(
          title: 'Token Session',
          agent: 'general',
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'm1',
            role: 'user',
            content: 'hi',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: session.id,
            messageId: 'a1',
            role: 'assistant',
            content: 'answer',
            timestamp: DateTime.now(),
          ),
        );
        await repository.appendEvent(
          StepEnded(
            sessionId: session.id,
            stepNumber: 1,
            tokensInput: 100,
            tokensOutput: 50,
            tokensReasoning: 10,
            timestamp: DateTime.now(),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        await waitForLoad(container);
        final notifier = container.read(chatListProvider.notifier);
        final loaded = await notifier.ensureChatLoaded(session.id.value);
        expect(loaded, isNotNull);
        expect(loaded!.messages, hasLength(2));
        final assistant = loaded.messages.firstWhere(
          (m) => m.role == chat_models.MessageRole.assistant,
        );
        expect(assistant.tokensInput, 100);
        expect(assistant.tokensOutput, 50);
        expect(assistant.tokensReasoning, 10);
      });
    });
  });
}
