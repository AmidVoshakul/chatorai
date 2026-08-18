import 'package:chatorai/core/keyboard/keyboard_shortcut.dart';
import 'package:chatorai/core/keyboard/shortcut_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Directionality(textDirection: TextDirection.ltr, child: child),
      ),
    );
  }

  group('ShortcutHandler', () {
    testWidgets('fires callback when nothing is focused (autofocus)', (
      tester,
    ) async {
      var fired = false;

      await tester.pumpWidget(
        buildTestApp(
          ShortcutHandler(
            autofocus: true,
            shortcuts: [
              KeyboardShortcut(
                id: 'test_ctrl_m',
                description: 'Test Ctrl+M',
                activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyM),
                onExecute: (context, ref) {
                  fired = true;
                },
              ),
            ],
            child: const Scaffold(body: Center(child: Text('hello'))),
          ),
        ),
      );

      // Simulate Ctrl+M with nothing focused.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(fired, isTrue, reason: 'Ctrl+M must fire when nothing is focused');
    });

    testWidgets('fires callback when a TextField child is focused', (
      tester,
    ) async {
      var fired = false;
      final controller = TextEditingController();

      await tester.pumpWidget(
        buildTestApp(
          ShortcutHandler(
            autofocus: true,
            shortcuts: [
              KeyboardShortcut(
                id: 'test_ctrl_b',
                description: 'Test Ctrl+B',
                activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyB),
                onExecute: (context, ref) {
                  fired = true;
                },
              ),
            ],
            child: Scaffold(
              body: Center(child: TextField(controller: controller)),
            ),
          ),
        ),
      );

      // Tap the TextField to focus it.
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Send Ctrl+B.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(
        fired,
        isTrue,
        reason: 'Ctrl+B must fire when TextField is focused',
      );
    });

    testWidgets('does not swallow plain typing in a focused TextField', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        buildTestApp(
          ShortcutHandler(
            autofocus: true,
            shortcuts: [
              KeyboardShortcut(
                id: 'test_ctrl_m',
                description: 'Test Ctrl+M',
                activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyM),
                onExecute: (context, ref) {},
              ),
            ],
            child: Scaffold(
              body: Center(child: TextField(controller: controller)),
            ),
          ),
        ),
      );

      // Tap the TextField to focus it.
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Type plain text (no Ctrl).
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pumpAndSettle();

      expect(
        controller.text,
        'hello',
        reason: 'Plain typing must not be swallowed by the handler',
      );
    });

    testWidgets('does not fire when shortcut is inactive', (tester) async {
      var fired = false;

      await tester.pumpWidget(
        buildTestApp(
          ShortcutHandler(
            autofocus: true,
            shortcuts: [
              KeyboardShortcut(
                id: 'test_inactive',
                description: 'Test inactive',
                activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyM),
                isActive: (ref) => false,
                onExecute: (context, ref) {
                  fired = true;
                },
              ),
            ],
            child: const Scaffold(body: Center(child: Text('hello'))),
          ),
        ),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(fired, isFalse, reason: 'Inactive shortcut must not fire');
    });

    testWidgets('single-press Escape fires on every press', (tester) async {
      var fired = 0;

      await tester.pumpWidget(
        buildTestApp(
          ShortcutHandler(
            autofocus: true,
            shortcuts: [
              KeyboardShortcut(
                id: 'test_escape',
                description: 'Test Escape',
                activator: const KeyActivator.escape(),
                onExecute: (context, ref) {
                  fired++;
                },
              ),
            ],
            child: const Scaffold(body: Center(child: Text('hello'))),
          ),
        ),
      );

      // First Escape press.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(fired, 1, reason: 'First Escape must fire immediately');

      // Second Escape press.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(fired, 2, reason: 'Second Escape must also fire immediately');
    });
  });
}
