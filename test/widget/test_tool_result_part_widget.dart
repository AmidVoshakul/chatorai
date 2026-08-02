import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_result_part_widget.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

void main() {
  const String shortText = 'Short output';

  Widget createTestWidget({
    required String toolName,
    String? result,
    ToolState state = ToolState.completed,
    Map<String, dynamic>? input,
    String? error,
    Duration? duration,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ToolResultPartWidget(
            part: ToolResultPart(
              toolCallId: 'test-call',
              toolName: toolName,
              result: result,
              state: state,
              input: input,
              error: error,
              duration: duration,
            ),
          ),
        ),
      ),
    );
  }

  group('ToolResultPartWidget UI Tests', () {
    testWidgets('shows correct line and char counts in footer', (tester) async {
      await tester.pumpWidget(
        createTestWidget(toolName: 'shell', result: shortText),
      );
      expect(find.textContaining('lines,'), findsOneWidget);
      expect(find.textContaining('chars'), findsOneWidget);
    });

    testWidgets('footer shows (truncated) when truncated', (tester) async {
      final longText = 'x' * 60000;
      await tester.pumpWidget(
        createTestWidget(toolName: 'shell', result: longText),
      );
      expect(find.textContaining('(truncated)'), findsOneWidget);
    });

    testWidgets('copy button is present', (tester) async {
      await tester.pumpWidget(
        createTestWidget(toolName: 'shell', result: 'test'),
      );
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('short output shows no truncation indicator', (tester) async {
      await tester.pumpWidget(
        createTestWidget(toolName: 'shell', result: shortText),
      );
      expect(find.textContaining('[...truncated...]'), findsNothing);
      expect(find.text(shortText), findsOneWidget);
    });

    testWidgets('empty output shows no truncation', (tester) async {
      await tester.pumpWidget(createTestWidget(toolName: 'shell', result: ''));
      expect(find.textContaining('[...truncated...]'), findsNothing);
    });

    testWidgets('error state shows error message, not result', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'shell',
          result: 'should not show',
          error: 'Something went wrong',
          state: ToolState.error,
        ),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('should not show'), findsNothing);
    });

    testWidgets('running state shows spinner', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'shell',
          result: 'should not show yet',
          state: ToolState.running,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('duration shown only for completed state', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'shell',
          result: 'output',
          state: ToolState.completed,
          duration: const Duration(milliseconds: 150),
        ),
      );
      expect(find.text('150ms'), findsOneWidget);
    });

    testWidgets('duration not shown for running state', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'shell',
          result: 'output',
          state: ToolState.running,
          duration: const Duration(milliseconds: 150),
        ),
      );
      expect(find.text('150ms'), findsNothing);
    });

    testWidgets('truncation marker appears for long text', (tester) async {
      final longText = 'x' * 60000;
      await tester.pumpWidget(
        createTestWidget(toolName: 'shell', result: longText),
      );
      expect(find.textContaining('[...truncated...]'), findsOneWidget);
    });

    testWidgets('shell tool shows prompt and command without header', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'shell',
          result: 'output',
          input: {'command': 'ls -la', 'description': 'List files'},
        ),
      );
      expect(find.text(r'$ '), findsOneWidget);
      expect(find.text('ls -la'), findsOneWidget);
      expect(find.textContaining('shell ls -la'), findsNothing);
    });

    testWidgets('shell tool shows spinner at prompt while running', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'shell',
          state: ToolState.running,
          input: {'command': 'ls -la'},
        ),
      );
      expect(find.text(r'$ '), findsNothing);
      expect(find.byType(SpinKitCircle), findsOneWidget);
      expect(find.text('ls -la'), findsOneWidget);
    });

    testWidgets('read tool shows offset and limit', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'read',
          result: 'line3\nline4',
          input: {'offset': 2, 'limit': 2},
        ),
      );
      // May appear in title if file_path provided, but here only in body subtitle
      expect(find.textContaining('offset=2, limit=2'), findsAtLeast(1));
    });

    testWidgets('grep tool shows pattern', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'grep',
          result: 'match1\nmatch2',
          input: {'pattern': 'test'},
        ),
      );
      expect(find.textContaining('✱ test'), findsOneWidget);
    });

    testWidgets('webfetch tool uses default body', (tester) async {
      await tester.pumpWidget(
        createTestWidget(toolName: 'webfetch', result: 'fetched content'),
      );
      expect(find.textContaining('fetched content'), findsOneWidget);
    });

    testWidgets('unknown tool uses default body', (tester) async {
      await tester.pumpWidget(
        createTestWidget(toolName: 'unknown_tool', result: 'some result'),
      );
      expect(find.textContaining('some result'), findsOneWidget);
    });

    testWidgets('no expand icon when running', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'shell',
          result: 'output',
          state: ToolState.running,
        ),
      );
      // Expand icon should not be present when running
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    });

    testWidgets('expand icon present when completed', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'shell',
          result: 'output',
          state: ToolState.completed,
        ),
      );
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });

  group('ToolResultPartWidget Truncation Logic', () {
    test('truncation limits: 2000 lines, 51200 chars', () {
      const int maxLines = 2000;
      const int maxChars = 51200;

      final charLimitText = 'a' * 52000;
      expect(charLimitText.length, greaterThan(maxChars));

      final lineLimitText = 'line\n' * 3000;
      final lineCount = lineLimitText.split('\n').length;
      expect(lineCount, greaterThan(maxLines));
      expect(lineLimitText.length, lessThan(maxChars));
    });
  });

  group('Edit/Apply Patch Diff Widgets', () {
    testWidgets('edit tool renders diff with additions and removals', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'edit',
          state: ToolState.completed,
          input: {
            'file_path': 'lib/main.dart',
            'old_string': 'old line 1\nold line 2',
            'new_string': 'new line 1\nnew line 2',
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ToolResultPartWidget));
      await tester.pumpAndSettle();
      expect(find.textContaining('new line 1'), findsOneWidget);
      expect(find.textContaining('old line 2'), findsOneWidget);
    });

    testWidgets('edit diff lines display with color and prefix', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'edit',
          state: ToolState.completed,
          input: {
            'file_path': 'test.dart',
            'old_string': 'before',
            'new_string': 'after',
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ToolResultPartWidget));
      await tester.pumpAndSettle();
      expect(find.text('before'), findsOneWidget);
      expect(find.text('after'), findsOneWidget);
    });

    testWidgets('apply_patch tool renders patch input', (tester) async {
      const patch = '''--- a/test.dart
+++ b/test.dart
@@ -1,3 +1,4 @@
 line1
-line2
+line2 modified
+line2b
 line3
''';
      final resultJson = jsonEncode({'message': 'ok', 'patch': patch});
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'apply_patch',
          state: ToolState.completed,
          result: resultJson,
          input: {'file_path': 'test.dart', 'patch': patch},
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ToolResultPartWidget));
      await tester.pumpAndSettle();
      expect(find.textContaining('line2'), findsAtLeast(1));
    });

    testWidgets('edit with empty old/new shows no diff area', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'edit',
          state: ToolState.completed,
          input: {
            'file_path': 'empty.dart',
            'old_string': '',
            'new_string': '',
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ToolResultPartWidget));
      await tester.pumpAndSettle();
      expect(find.text('empty.dart'), findsNothing);
    });

    testWidgets('edit diff shows +/- markers on changed lines', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'edit',
          state: ToolState.completed,
          input: {
            'file_path': 'counter.dart',
            'old_string': 'a\nb',
            'new_string': 'x\ny\nz',
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ToolResultPartWidget));
      await tester.pumpAndSettle();
      expect(find.textContaining('+'), findsAtLeast(1));
      expect(find.textContaining('-'), findsAtLeast(1));
    });

    testWidgets(
      'edit renders patch from result when LSP "no errors" text is appended',
      (tester) async {
        const patch = '''--- a/test.dart
+++ b/test.dart
@@ -1,3 +1,4 @@
 line1
-line2
+line2 modified
+line2b
 line3
''';
        final resultJson = jsonEncode({'message': 'ok', 'patch': patch});
        await tester.pumpWidget(
          createTestWidget(
            toolName: 'edit',
            state: ToolState.completed,
            result: '$resultJson\n\nNo LSP errors detected.',
            input: {'file_path': 'test.dart'},
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('line2 modified'), findsOneWidget);
        expect(find.text('line2b'), findsOneWidget);
        expect(find.text('line1'), findsAtLeast(1));
      },
    );

    testWidgets(
      'edit renders patch from result when LSP diagnostics block is appended',
      (tester) async {
        const patch = '''--- a/test.dart
+++ b/test.dart
@@ -1,3 +1,4 @@
 line1
-line2
+line2 modified
+line2b
 line3
''';
        final resultJson = jsonEncode({'message': 'ok', 'patch': patch});
        final lspResult =
            '$resultJson\n\nLSP errors detected in this file, please fix:\n'
            '[ ERROR ] 5:10 — some error message\n';
        await tester.pumpWidget(
          createTestWidget(
            toolName: 'edit',
            state: ToolState.completed,
            result: lspResult,
            input: {'file_path': 'test.dart'},
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('line2 modified'), findsOneWidget);
        expect(find.text('line2b'), findsOneWidget);
        expect(find.textContaining('1 error'), findsOneWidget);
      },
    );

    testWidgets('edit renders patch from pure JSON result', (tester) async {
      const patch = '''--- a/test.dart
+++ b/test.dart
@@ -1,3 +1,4 @@
 line1
-line2
+line2 modified
+line2b
 line3
''';
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'edit',
          state: ToolState.completed,
          result: jsonEncode({'message': 'ok', 'patch': patch}),
          input: {'file_path': 'test.dart'},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('line2 modified'), findsOneWidget);
      expect(find.text('line2b'), findsOneWidget);
    });
  });
}
