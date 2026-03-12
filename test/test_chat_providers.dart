import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers/chat/chat_providers.dart';
import 'package:chatorai/models/chat_models.dart';

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

  group('ChatListNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is loading', () {
      final state = container.read(chatListProvider);
      expect(state.isLoading, true);
    });
  });
}
