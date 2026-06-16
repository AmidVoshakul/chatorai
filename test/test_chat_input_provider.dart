import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/features/chat/data/providers/chat_input_provider.dart';
import 'package:chatorai/features/chat/domain/services/speech_to_text_service.dart';

void main() {
  group('ChatInputNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has default values', () {
      final state = container.read(chatInputProvider);
      expect(state.speechUiState, SpeechUiState.idle);
      expect(state.speechStatusMessage, '');
      expect(state.isSending, false);
      expect(state.plusActive, false);
      expect(state.attachedFilePath, isNull);
    });

    test('setSpeechUiState updates speech UI state', () {
      container
          .read(chatInputProvider.notifier)
          .setSpeechUiState(SpeechUiState.listening);
      final state = container.read(chatInputProvider);
      expect(state.speechUiState, SpeechUiState.listening);
    });

    test('setSpeechStatusMessage updates status message', () {
      container
          .read(chatInputProvider.notifier)
          .setSpeechStatusMessage('Listening...');
      final state = container.read(chatInputProvider);
      expect(state.speechStatusMessage, 'Listening...');
    });

    test('setIsSending updates sending state', () {
      container.read(chatInputProvider.notifier).setIsSending(true);
      final state = container.read(chatInputProvider);
      expect(state.isSending, true);
    });

    test('setPlusActive updates plus button state', () {
      container.read(chatInputProvider.notifier).setPlusActive(true);
      final state = container.read(chatInputProvider);
      expect(state.plusActive, true);
    });

    test('setAttachedFile updates attached file', () {
      container
          .read(chatInputProvider.notifier)
          .setAttachedFile(
            path: '/path/to/file.jpg',
            name: 'file.jpg',
            imageType: 'image/jpeg',
            base64Data: 'base64data',
          );
      final state = container.read(chatInputProvider);
      expect(state.attachedFilePath, '/path/to/file.jpg');
      expect(state.attachedFileName, 'file.jpg');
      expect(state.attachedImageType, 'image/jpeg');
      expect(state.attachedBase64Data, 'base64data');
    });

    test('clearAttachedFile removes attached file', () {
      container
          .read(chatInputProvider.notifier)
          .setAttachedFile(path: '/path/to/file.jpg', name: 'file.jpg');
      container.read(chatInputProvider.notifier).clearAttachedFile();

      final state = container.read(chatInputProvider);
      expect(state.attachedFilePath, isNull);
      expect(state.attachedFileName, isNull);
    });

    test('preserves other state when setting attached file', () {
      container.read(chatInputProvider.notifier).setIsSending(true);
      container.read(chatInputProvider.notifier).setPlusActive(true);
      container
          .read(chatInputProvider.notifier)
          .setSpeechUiState(SpeechUiState.listening);

      container
          .read(chatInputProvider.notifier)
          .setAttachedFile(path: '/path/to/file.jpg', name: 'file.jpg');

      final state = container.read(chatInputProvider);
      expect(state.isSending, true);
      expect(state.plusActive, true);
      expect(state.speechUiState, SpeechUiState.listening);
      expect(state.attachedFilePath, '/path/to/file.jpg');
    });
  });

  group('ChatInputState', () {
    test('copyWith creates new instance with updated values', () {
      const state = ChatInputState();
      final newState = state.copyWith(isSending: true, plusActive: true);

      expect(newState.isSending, true);
      expect(newState.plusActive, true);
      expect(newState.speechUiState, SpeechUiState.idle);
    });

    test('copyWith preserves original values when not specified', () {
      const state = ChatInputState(isSending: true, plusActive: true);
      final newState = state.copyWith(isSending: false);

      expect(newState.isSending, false);
      expect(newState.plusActive, true);
    });
  });
}
