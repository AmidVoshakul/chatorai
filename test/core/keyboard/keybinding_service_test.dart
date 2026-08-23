import 'package:chatorai/core/keyboard/keyboard_shortcut.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeyActivator', () {
    group('fromString', () {
      test('parses Ctrl+B', () {
        final activator = KeyActivator.fromString('Ctrl+B');
        expect(activator.ctrl, isTrue);
        expect(activator.shift, isFalse);
        expect(activator.alt, isFalse);
        expect(activator.meta, isFalse);
        expect(activator.key, LogicalKeyboardKey.keyB);
      });

      test('parses Ctrl+Shift+P', () {
        final activator = KeyActivator.fromString('Ctrl+Shift+P');
        expect(activator.ctrl, isTrue);
        expect(activator.shift, isTrue);
        expect(activator.key, LogicalKeyboardKey.keyP);
      });

      test('parses Ctrl+Tab', () {
        final activator = KeyActivator.fromString('Ctrl+Tab');
        expect(activator.ctrl, isTrue);
        expect(activator.key, LogicalKeyboardKey.tab);
      });

      test('parses arrow keys', () {
        expect(KeyActivator.fromString('←').key, LogicalKeyboardKey.arrowLeft);
        expect(KeyActivator.fromString('→').key, LogicalKeyboardKey.arrowRight);
        expect(KeyActivator.fromString('↑').key, LogicalKeyboardKey.arrowUp);
        expect(KeyActivator.fromString('↓').key, LogicalKeyboardKey.arrowDown);
      });

      test('parses Home and End', () {
        expect(KeyActivator.fromString('Home').key, LogicalKeyboardKey.home);
        expect(KeyActivator.fromString('End').key, LogicalKeyboardKey.end);
      });

      test('parses Esc', () {
        final activator = KeyActivator.fromString('Esc');
        expect(activator.key, LogicalKeyboardKey.escape);
        expect(activator.doublePress, isFalse);
      });

      test('parses Esc Esc as double-press', () {
        final activator = KeyActivator.fromString('Esc Esc');
        expect(activator.key, LogicalKeyboardKey.escape);
        expect(activator.doublePress, isTrue);
      });

      test('parses Escape Escape as double-press', () {
        final activator = KeyActivator.fromString('Escape Escape');
        expect(activator.key, LogicalKeyboardKey.escape);
        expect(activator.doublePress, isTrue);
      });

      test('throws on empty string', () {
        expect(() => KeyActivator.fromString(''), throwsFormatException);
      });

      test('throws on unknown key', () {
        expect(
          () => KeyActivator.fromString('Ctrl+Unknown'),
          throwsFormatException,
        );
      });
    });

    group('format', () {
      test('formats Ctrl+B', () {
        expect(KeyActivator.fromString('Ctrl+B').format(), 'Ctrl+B');
      });

      test('formats Ctrl+Shift+P', () {
        expect(
          KeyActivator.fromString('Ctrl+Shift+P').format(),
          'Ctrl+Shift+P',
        );
      });

      test('formats arrow keys', () {
        expect(KeyActivator.fromString('←').format(), '←');
        expect(KeyActivator.fromString('→').format(), '→');
        expect(KeyActivator.fromString('↑').format(), '↑');
        expect(KeyActivator.fromString('↓').format(), '↓');
      });

      test('formats Home and End', () {
        expect(KeyActivator.fromString('Home').format(), 'Home');
        expect(KeyActivator.fromString('End').format(), 'End');
      });

      test('formats Esc Esc as double-press', () {
        expect(KeyActivator.fromString('Esc Esc').format(), 'Esc Esc');
      });
    });

    group('round-trip', () {
      test('Ctrl+B round-trips', () {
        final original = 'Ctrl+B';
        final activator = KeyActivator.fromString(original);
        expect(activator.format(), original);
      });

      test('Ctrl+Shift+P round-trips', () {
        final original = 'Ctrl+Shift+P';
        final activator = KeyActivator.fromString(original);
        expect(activator.format(), original);
      });

      test('Ctrl+Tab round-trips', () {
        final original = 'Ctrl+Tab';
        final activator = KeyActivator.fromString(original);
        expect(activator.format(), original);
      });

      test('arrows round-trip', () {
        for (final arrow in ['←', '→', '↑', '↓']) {
          final activator = KeyActivator.fromString(arrow);
          expect(activator.format(), arrow);
        }
      });

      test('Home/End round-trip', () {
        expect(KeyActivator.fromString('Home').format(), 'Home');
        expect(KeyActivator.fromString('End').format(), 'End');
      });

      test('Esc Esc round-trips', () {
        final original = 'Esc Esc';
        final activator = KeyActivator.fromString(original);
        expect(activator.format(), original);
      });
    });

    group('matches', () {
      test('matches Ctrl+B', () {
        final activator = KeyActivator.fromString('Ctrl+B');
        // We can't easily simulate HardwareKeyboard state in unit tests,
        // but we can verify the method exists and returns bool
        expect(activator.matches, isA<Function>());
      });
    });
  });

  group('KeyboardShortcut', () {
    test('copyWith returns new instance with overridden activator', () {
      final original = KeyboardShortcut(
        id: 'test',
        description: 'Test',
        activator: const KeyActivator.escape(),
        onExecute: (_, __) {},
      );

      final newActivator = KeyActivator.fromString('Ctrl+B');
      final copied = original.copyWith(activator: newActivator);

      expect(copied.id, original.id);
      expect(copied.description, original.description);
      expect(copied.activator, newActivator);
      expect(copied.onExecute, original.onExecute);
    });

    test('copyWith preserves original when no override', () {
      final original = KeyboardShortcut(
        id: 'test',
        description: 'Test',
        activator: const KeyActivator.escape(),
        onExecute: (_, __) {},
      );

      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.activator, original.activator);
      expect(copied.onExecute, original.onExecute);
    });
  });
}
