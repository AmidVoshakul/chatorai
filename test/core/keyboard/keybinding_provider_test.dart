import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/keyboard/keybinding_provider.dart';
import 'package:chatorai/core/keyboard/keyboard_shortcut.dart';
import 'package:chatorai/core/keyboard/shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeybindingNotifier', () {
    test('loads empty map when no override', () {
      final container = ProviderContainer();
      final notifier = container.read(keybindingProvider.notifier);
      final bindings = container.read(keybindingProvider);

      expect(bindings, isEmpty);
    });

    test('activatorFor returns null when no override', () {
      final container = ProviderContainer();
      final notifier = container.read(keybindingProvider.notifier);

      expect(notifier.activatorFor('toggle_sidebar'), isNull);
    });

    test(
      'loads overrides from the resolved configProvider after restart',
      () async {
        final config = ChatOrAIConfig.fromJson({
          'permission': {},
          'keybinding': {'new_chat': 'Ctrl+K', 'toggle_sidebar': 'Ctrl+B'},
        });
        final container = ProviderContainer(
          overrides: [
            configProvider.overrideWith((ref) => Future.value(config)),
          ],
        );
        final notifier = container.read(keybindingProvider.notifier);

        // build() watches the async configProvider; wait for it to resolve.
        for (
          var i = 0;
          i < 100 && container.read(keybindingProvider).isEmpty;
          i++
        ) {
          await Future.delayed(const Duration(milliseconds: 10));
        }

        final bindings = container.read(keybindingProvider);
        expect(bindings['new_chat'], 'Ctrl+K');
        expect(bindings['toggle_sidebar'], 'Ctrl+B');
        expect(notifier.activatorFor('new_chat')?.key, LogicalKeyboardKey.keyK);
      },
    );

    test('setBinding persists and activatorFor returns override', () async {
      final container = ProviderContainer();
      final notifier = container.read(keybindingProvider.notifier);

      await notifier.setBinding('toggle_sidebar', 'Ctrl+Shift+B');

      final bindings = container.read(keybindingProvider);
      expect(bindings['toggle_sidebar'], 'Ctrl+Shift+B');

      final activator = notifier.activatorFor('toggle_sidebar');
      expect(activator, isNotNull);
      expect(activator!.ctrl, isTrue);
      expect(activator.shift, isTrue);
      expect(activator.key, LogicalKeyboardKey.keyB);
    });

    test('resetToDefaults clears overrides', () async {
      final container = ProviderContainer();
      final notifier = container.read(keybindingProvider.notifier);

      await notifier.setBinding('toggle_sidebar', 'Ctrl+Shift+B');
      await notifier.resetToDefaults();

      final bindings = container.read(keybindingProvider);
      expect(bindings, isEmpty);
    });

    test('conflicts detects duplicate combos', () async {
      final container = ProviderContainer();
      final notifier = container.read(keybindingProvider.notifier);

      await notifier.setBinding('toggle_sidebar', 'Ctrl+Shift+B');
      await notifier.setBinding('new_chat', 'Ctrl+Shift+B');

      final conflicts = notifier.conflicts();
      expect(conflicts.contains('toggle_sidebar'), isTrue);
      expect(conflicts.contains('new_chat'), isTrue);
    });

    test('no conflicts when combos are unique', () async {
      final container = ProviderContainer();
      final notifier = container.read(keybindingProvider.notifier);

      await notifier.setBinding('toggle_sidebar', 'Ctrl+Shift+B');
      await notifier.setBinding('new_chat', 'Ctrl+Shift+N');

      final conflicts = notifier.conflicts();
      expect(conflicts, isEmpty);
    });

    test('rejects bare printable key without modifier', () async {
      final container = ProviderContainer();
      final notifier = container.read(keybindingProvider.notifier);

      expect(
        () => notifier.setBinding('toggle_sidebar', 'A'),
        throwsFormatException,
      );
    });

    test('allows bare non-printable keys', () async {
      final container = ProviderContainer();
      final notifier = container.read(keybindingProvider.notifier);

      await notifier.setBinding('close_dialog', 'Esc');
      final bindings = container.read(keybindingProvider);
      expect(bindings['close_dialog'], 'Esc');
    });

    test('allows bare Home key', () async {
      final container = ProviderContainer();
      final notifier = container.read(keybindingProvider.notifier);

      await notifier.setBinding('scroll_to_chat_start', 'Home');
      final bindings = container.read(keybindingProvider);
      expect(bindings['scroll_to_chat_start'], 'Home');
    });
  });
}
