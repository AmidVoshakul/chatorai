import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/link_launcher.dart';
import 'package:chatorai/features/chat/presentation/widgets/link_confirm_sheet.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/table_block.dart';

class _RecordingLauncher {
  final List<String> calls = <String>[];
  Future<LinkLaunchResult> call(String href) async {
    calls.add(href);
    return LinkLaunchResult.opened;
  }
}

void main() {
  group('LinkConfirmSheet', () {
    Future<void> pumpApp(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('tap link opens confirmation sheet', (tester) async {
      await pumpApp(
        tester,
        ElevatedButton(
          onPressed: () => showLinkConfirmSheet(
            tester.element(find.byType(ElevatedButton)),
            href: 'https://example.com',
          ),
          child: const Text('open'),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to open:'), findsOneWidget);
      expect(find.text('https://example.com'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('tap Open calls launcher', (tester) async {
      final launcher = _RecordingLauncher();

      await pumpApp(
        tester,
        ElevatedButton(
          onPressed: () => showLinkConfirmSheet(
            tester.element(find.byType(ElevatedButton)),
            href: 'https://example.com',
            launcher: launcher.call,
          ),
          child: const Text('open'),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(launcher.calls, ['https://example.com']);
    });

    testWidgets('tap Cancel does not call launcher', (tester) async {
      final launcher = _RecordingLauncher();

      await pumpApp(
        tester,
        ElevatedButton(
          onPressed: () => showLinkConfirmSheet(
            tester.element(find.byType(ElevatedButton)),
            href: 'https://example.com',
            launcher: launcher.call,
          ),
          child: const Text('open'),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(launcher.calls, isEmpty);
    });

    testWidgets('Escape dismisses without calling launcher', (tester) async {
      final launcher = _RecordingLauncher();

      await pumpApp(
        tester,
        ElevatedButton(
          onPressed: () => showLinkConfirmSheet(
            tester.element(find.byType(ElevatedButton)),
            href: 'https://example.com',
            launcher: launcher.call,
          ),
          child: const Text('open'),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(launcher.calls, isEmpty);
    });

    testWidgets('Enter confirms and calls launcher', (tester) async {
      final launcher = _RecordingLauncher();

      await pumpApp(
        tester,
        ElevatedButton(
          onPressed: () => showLinkConfirmSheet(
            tester.element(find.byType(ElevatedButton)),
            href: 'https://example.com',
            launcher: launcher.call,
          ),
          child: const Text('open'),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(launcher.calls, ['https://example.com']);
    });

    testWidgets('javascript scheme does not open sheet', (tester) async {
      int opens = 0;
      await pumpApp(
        tester,
        ElevatedButton(
          onPressed: () {
            opens++;
            showLinkConfirmSheet(
              tester.element(find.byType(ElevatedButton)),
              href: 'javascript:alert(1)',
            );
          },
          child: const Text('open'),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(opens, 1);
      expect(find.text('Are you sure you want to open:'), findsNothing);
    });

    testWidgets('link inside table cell opens confirmation sheet', (
      tester,
    ) async {
      final rows = TableParser.parseTableLines([
        '| Link |',
        '| --- |',
        '| [example](https://example.com) |',
      ])!;

      await pumpApp(tester, TableBlock(rows: rows));

      await tester.tap(find.text('example'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to open:'), findsOneWidget);
      expect(find.text('https://example.com'), findsOneWidget);
    });
  });
}
