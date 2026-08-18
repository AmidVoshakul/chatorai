import 'package:chatorai/core/keyboard/keyboard_shortcut.dart';
import 'package:chatorai/core/keyboard/shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KeyActivator', () {
    test('escape activator matches a bare KeyDown', () {
      const activator = KeyActivator.escape();

      expect(
        activator.matches(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.escape,
            logicalKey: LogicalKeyboardKey.escape,
            timeStamp: Duration.zero,
          ),
        ),
        isTrue,
      );
      // Key-up events never match.
      expect(
        activator.matches(
          const KeyUpEvent(
            physicalKey: PhysicalKeyboardKey.escape,
            logicalKey: LogicalKeyboardKey.escape,
            timeStamp: Duration.zero,
          ),
        ),
        isFalse,
      );
    });

    test('ctrlKey activator requires Ctrl held to match', () {
      const activator = KeyActivator.ctrlKey(LogicalKeyboardKey.keyB);

      // With no modifier pressed, a bare KeyDown must NOT match.
      expect(
        activator.matches(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyB,
            logicalKey: LogicalKeyboardKey.keyB,
            timeStamp: Duration.zero,
          ),
        ),
        isFalse,
      );
    });

    test('non-ctrl activator matches a bare KeyDown', () {
      const activator = KeyActivator.arrowLeft();

      expect(
        activator.matches(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowLeft,
            logicalKey: LogicalKeyboardKey.arrowLeft,
            timeStamp: Duration.zero,
          ),
        ),
        isTrue,
      );
      // Key-up events never match.
      expect(
        activator.matches(
          const KeyUpEvent(
            physicalKey: PhysicalKeyboardKey.arrowLeft,
            logicalKey: LogicalKeyboardKey.arrowLeft,
            timeStamp: Duration.zero,
          ),
        ),
        isFalse,
      );
    });

    test('home and end activators match their bare KeyDown', () {
      for (final (key, physical) in [
        (LogicalKeyboardKey.home, PhysicalKeyboardKey.home),
        (LogicalKeyboardKey.end, PhysicalKeyboardKey.end),
      ]) {
        final activator = switch (key) {
          LogicalKeyboardKey.home => const KeyActivator.home(),
          _ => const KeyActivator.end(),
        };
        expect(
          activator.matches(
            KeyDownEvent(
              physicalKey: physical,
              logicalKey: key,
              timeStamp: Duration.zero,
            ),
          ),
          isTrue,
          reason: '$key must match its own KeyDown',
        );
      }
    });
  });

  group('AppShortcuts navigation shortcuts', () {
    test('bind Ctrl+B/N/M/P to the expected activators', () {
      void run() {}

      final cases = <(String, KeyboardShortcut, LogicalKeyboardKey, bool)>[
        (
          'sidebar',
          AppShortcuts.toggleSidebar(run),
          LogicalKeyboardKey.keyB,
          true,
        ),
        ('new chat', AppShortcuts.newChat(run), LogicalKeyboardKey.keyN, true),
        (
          'model selector',
          AppShortcuts.openModelSelector(run),
          LogicalKeyboardKey.keyM,
          true,
        ),
        (
          'settings',
          AppShortcuts.openSettings(run),
          LogicalKeyboardKey.keyP,
          true,
        ),
        (
          'scroll to chat start',
          AppShortcuts.scrollToChatStart(run),
          LogicalKeyboardKey.home,
          false,
        ),
        (
          'scroll to chat end',
          AppShortcuts.scrollToChatEnd(run),
          LogicalKeyboardKey.end,
          false,
        ),
      ];

      for (final (name, shortcut, key, usesCtrl) in cases) {
        expect(shortcut.activator.key, key, reason: '$name must use $key');
        expect(
          shortcut.activator.ctrl,
          usesCtrl,
          reason: '$name must ${usesCtrl ? 'use Ctrl' : 'not use Ctrl'}',
        );
      }
    });
  });
}
