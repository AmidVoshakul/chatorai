import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers/chat/streaming_content_controller.dart';

void main() {
  group('StreamingContentNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has default values', () {
      final state = container.read(streamingContentProvider);
      expect(state.currentChatId, '');
      expect(state.content, '');
      expect(state.reasoning, '');
      expect(state.isStreaming, false);
      expect(state.lastUpdate, isNotNull);
    });

    test('startStreaming initializes streaming state', () {
      container
          .read(streamingContentProvider.notifier)
          .startStreaming('chat-123');
      final state = container.read(streamingContentProvider);
      expect(state.currentChatId, 'chat-123');
      expect(state.content, '');
      expect(state.reasoning, '');
      expect(state.isStreaming, true);
    });

    test('updateContent updates content and reasoning', () {
      container
          .read(streamingContentProvider.notifier)
          .startStreaming('chat-123');
      container
          .read(streamingContentProvider.notifier)
          .updateContent('Hello', reasoning: 'Thinking...');
      final state = container.read(streamingContentProvider);
      expect(state.content, 'Hello');
      expect(state.reasoning, 'Thinking...');
    });

    test('updateContent does nothing when not streaming', () {
      container.read(streamingContentProvider.notifier).updateContent('Hello');
      final state = container.read(streamingContentProvider);
      expect(state.content, '');
    });

    test('stopStreaming stops streaming and sets justEnded', () {
      container
          .read(streamingContentProvider.notifier)
          .startStreaming('chat-123');
      container.read(streamingContentProvider.notifier).stopStreaming();
      final state = container.read(streamingContentProvider);
      expect(state.isStreaming, false);
      expect(state.justEnded, true);
    });

    test('flushAndStop stops streaming and schedules reset', () async {
      container
          .read(streamingContentProvider.notifier)
          .startStreaming('chat-123');
      container.read(streamingContentProvider.notifier).updateContent('Hello');
      container.read(streamingContentProvider.notifier).flushAndStop();
      // After flushAndStop is called, justEnded is set immediately
      var state = container.read(streamingContentProvider);
      expect(state.isStreaming, false);
      expect(state.justEnded, true);
      // Wait for reset to happen
      await Future.delayed(const Duration(milliseconds: 350));
      state = container.read(streamingContentProvider);
      expect(state.content, '');
      expect(state.justEnded, false);
    });

    test('reset clears all state', () {
      container
          .read(streamingContentProvider.notifier)
          .startStreaming('chat-123');
      container.read(streamingContentProvider.notifier).updateContent('Hello');
      container.read(streamingContentProvider.notifier).reset();
      final state = container.read(streamingContentProvider);
      expect(state.currentChatId, '');
      expect(state.content, '');
      expect(state.reasoning, '');
      expect(state.isStreaming, false);
    });
  });

  group('StreamingContentState', () {
    test('copyWith creates new instance with updated values', () {
      final state = StreamingContentState();
      final newState = state.copyWith(content: 'test', reasoning: 'thought');

      expect(newState.content, 'test');
      expect(newState.reasoning, 'thought');
      expect(newState.isStreaming, false);
      expect(newState.justEnded, false);
    });

    test('copyWith can set justEnded flag', () {
      final state = StreamingContentState();
      final newState = state.copyWith(justEnded: true);

      expect(newState.justEnded, true);
      expect(newState.content, '');
    });

    test('effectiveLastUpdate returns lastUpdate or current time', () {
      final state = StreamingContentState();
      expect(state.effectiveLastUpdate, isNotNull);

      final specificTime = DateTime(2024, 1, 1);
      final stateWithTime = StreamingContentState(lastUpdate: specificTime);
      expect(stateWithTime.effectiveLastUpdate, specificTime);
    });

    test('reset creates new state with current timestamp', () {
      final state = StreamingContentState(
        currentChatId: 'chat-123',
        content: 'test',
        isStreaming: true,
        justEnded: true,
      );
      final resetState = state.reset();

      expect(resetState.currentChatId, '');
      expect(resetState.content, '');
      expect(resetState.isStreaming, false);
      expect(resetState.justEnded, false);
      expect(resetState.lastUpdate, isNotNull);
    });
  });
}
