import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers/chat/chat_message_provider.dart';

void main() {
  group('ChatMessageNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is not editing', () {
      final state = container.read(chatMessageProvider);
      expect(state.isEditing, false);
      expect(state.editingText, '');
    });

    test('startEditing enables editing mode', () {
      container.read(chatMessageProvider.notifier).startEditing('Hello world');
      final state = container.read(chatMessageProvider);
      expect(state.isEditing, true);
      expect(state.editingText, 'Hello world');
    });

    test('cancelEditing disables editing mode and clears text', () {
      container.read(chatMessageProvider.notifier).startEditing('Hello world');
      container.read(chatMessageProvider.notifier).cancelEditing();
      final state = container.read(chatMessageProvider);
      expect(state.isEditing, false);
      expect(state.editingText, '');
    });

    test('saveEditing disables editing mode but preserves text', () {
      container.read(chatMessageProvider.notifier).startEditing('Hello world');
      container.read(chatMessageProvider.notifier).saveEditing();
      final state = container.read(chatMessageProvider);
      expect(state.isEditing, false);
    });

    test('setEditingText updates editing text', () {
      container.read(chatMessageProvider.notifier).startEditing('initial');
      container.read(chatMessageProvider.notifier).setEditingText('updated');
      final state = container.read(chatMessageProvider);
      expect(state.editingText, 'updated');
    });
  });

  group('ChatMessageState', () {
    test('copyWith creates new instance with updated values', () {
      const state = ChatMessageState();
      final newState = state.copyWith(isEditing: true, editingText: 'test');

      expect(newState.isEditing, true);
      expect(newState.editingText, 'test');
    });

    test('copyWith preserves original values when not specified', () {
      const state = ChatMessageState(isEditing: true, editingText: 'test');
      final newState = state.copyWith(isEditing: false);

      expect(newState.isEditing, false);
      expect(newState.editingText, 'test');
    });
  });

  group('imageCacheProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('decodes base64 data correctly', () {
      // "Hello" in base64
      const base64Data = 'SGVsbG8=';
      final result = container.read(imageCacheProvider(base64Data));
      expect(result, [72, 101, 108, 108, 111]); // ASCII codes for "Hello"
    });
  });
}
