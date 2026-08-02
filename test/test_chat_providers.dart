import 'dart:async';

import 'package:chatorai/core/session/session_db_provider.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
import 'package:chatorai/features/sessions/providers/sidebar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

Chat _chat(String id, {String title = ''}) {
  return Chat(
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
}
