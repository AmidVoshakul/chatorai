import 'package:chatorai/core/keyboard/keyboard_shortcut.dart';
import 'package:chatorai/core/keyboard/shortcut_handler.dart';
import 'package:chatorai/features/settings/widgets/settings_modal.dart';
import 'package:chatorai/features/settings/widgets/settings_window.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      overrides: [
        themeProvider.overrideWith(() => ThemeNotifier()),
        languageProvider.overrideWith(() => LanguageNotifier()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Directionality(textDirection: TextDirection.ltr, child: child),
      ),
    );
  }

  group('SettingsWindow categories', () {
    testWidgets('includes Appearance and Accessibility categories', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Material(
            child: MediaQuery(
              data: const MediaQueryData(size: Size(1280, 720)),
              child: const SettingsWindow(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the new categories are present in the nav.
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Accessibility'), findsOneWidget);
    });

    testWidgets('tapping Appearance shows appearance content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Material(
            child: MediaQuery(
              data: const MediaQueryData(size: Size(1280, 720)),
              child: const SettingsWindow(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Font size'), findsOneWidget);
    });

    testWidgets('tapping Accessibility shows accessibility content', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Material(
            child: MediaQuery(
              data: const MediaQueryData(size: Size(1280, 720)),
              child: const SettingsWindow(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accessibility'));
      await tester.pumpAndSettle();

      expect(find.text('Wide screen mode'), findsOneWidget);
      expect(find.text('Auto-scroll during streaming'), findsOneWidget);
    });
  });

  group('SettingsModalWindow escape handling', () {
    testWidgets('single Escape closes the settings modal', (tester) async {
      var dialogClosed = false;

      await tester.pumpWidget(
        buildTestApp(
          Material(
            child: ElevatedButton(
              onPressed: () {
                showSettingsModal(
                  tester.element(find.byType(ElevatedButton)),
                ).then((_) {
                  dialogClosed = true;
                });
              },
              child: const Text('Open settings'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the modal.
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify the settings window is visible.
      expect(find.byType(SettingsWindow), findsOneWidget);

      // Send single Escape.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // The dialog should be closed.
      expect(find.byType(SettingsWindow), findsNothing);
      expect(dialogClosed, isTrue);
    });

    testWidgets('single Escape does not trigger outer double-press handler', (
      tester,
    ) async {
      var doublePressFired = false;

      await tester.pumpWidget(
        ShortcutHandler(
          autofocus: true,
          shortcuts: [
            KeyboardShortcut(
              id: 'outer_double_escape',
              description: 'Outer double escape',
              activator: const KeyActivator.escapeDoublePress(),
              onExecute: (context, ref) {
                doublePressFired = true;
              },
            ),
          ],
          child: buildTestApp(
            Material(
              child: ElevatedButton(
                onPressed: () {
                  showSettingsModal(
                    tester.element(find.byType(ElevatedButton)),
                  );
                },
                child: const Text('Open settings'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the modal.
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify the settings window is visible.
      expect(find.byType(SettingsWindow), findsOneWidget);

      // Send single Escape (should close modal, not trigger outer handler).
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // The dialog should be closed.
      expect(find.byType(SettingsWindow), findsNothing);
      // The outer double-press handler must NOT have fired.
      expect(
        doublePressFired,
        isFalse,
        reason: 'Outer double-press handler must not fire when modal is open',
      );
    });

    testWidgets('double Escape works when no modal is open', (tester) async {
      var doublePressFired = false;

      await tester.pumpWidget(
        ShortcutHandler(
          autofocus: true,
          shortcuts: [
            KeyboardShortcut(
              id: 'outer_double_escape',
              description: 'Outer double escape',
              activator: const KeyActivator.escapeDoublePress(),
              onExecute: (context, ref) {
                doublePressFired = true;
              },
            ),
          ],
          child: buildTestApp(
            Material(
              child: const Scaffold(body: Center(child: Text('hello'))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First Escape press.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        doublePressFired,
        isFalse,
        reason: 'First press must not fire double-press',
      );

      // Second Escape press (within 500ms).
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        doublePressFired,
        isTrue,
        reason: 'Second press must fire double-press',
      );
    });
  });
}
