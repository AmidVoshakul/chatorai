import 'package:chatorai/gui/features/chat/data/providers/chat_screen_notifier.dart';
import 'package:chatorai/gui/features/sessions/providers/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activeSessionIdsProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          chatScreenProvider.overrideWith(() => ChatScreenNotifier()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('returns empty set when not streaming', () {
      final notifier = container.read(chatScreenProvider.notifier);
      notifier.finalizeStreaming();

      final ids = container.read(activeSessionIdsProvider);
      expect(ids, isEmpty);
    });

    test('returns set with streamingSessionId when streaming', () {
      final notifier = container.read(chatScreenProvider.notifier);
      notifier.startStreaming('session-123');

      final ids = container.read(activeSessionIdsProvider);
      expect(ids, {'session-123'});
    });

    test('returns empty set when streaming but streamingSessionId is null', () {
      final notifier = container.read(chatScreenProvider.notifier);
      notifier.setStreaming(true);

      final ids = container.read(activeSessionIdsProvider);
      expect(ids, isEmpty);
    });

    test('updates when streaming session changes', () {
      final notifier = container.read(chatScreenProvider.notifier);
      notifier.startStreaming('session-1');

      expect(container.read(activeSessionIdsProvider), {'session-1'});

      notifier.startStreaming('session-2');
      expect(container.read(activeSessionIdsProvider), {'session-2'});

      notifier.finalizeStreaming();
      expect(container.read(activeSessionIdsProvider), isEmpty);
    });
  });
}
