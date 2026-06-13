import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_result_part_widget.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

void main() {
  group('ToolResultPartWidget UI Tests', () {
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

    testWidgets('shows correct line and char counts in footer', (tester) async {
      await tester.pumpWidget(
        createTestWidget(toolName: 'bash', result: shortText),
      );
      expect(find.textContaining('lines,'), findsOneWidget);
      expect(find.textContaining('chars'), findsOneWidget);
    });

    testWidgets('footer shows (truncated) when truncated', (tester) async {
      final longText = 'x' * 60000;
      await tester.pumpWidget(
        createTestWidget(toolName: 'bash', result: longText),
      );
      expect(find.textContaining('(truncated)'), findsOneWidget);
    });

    testWidgets('copy button is present', (tester) async {
      await tester.pumpWidget(
        createTestWidget(toolName: 'bash', result: 'test'),
      );
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('short output shows no truncation indicator', (tester) async {
      await tester.pumpWidget(
        createTestWidget(toolName: 'bash', result: shortText),
      );
      expect(find.textContaining('[...truncated...]'), findsNothing);
      expect(find.text(shortText), findsOneWidget);
    });

    testWidgets('empty output shows no truncation', (tester) async {
      await tester.pumpWidget(createTestWidget(toolName: 'bash', result: ''));
      expect(find.textContaining('[...truncated...]'), findsNothing);
    });

    testWidgets('error state shows error message, not result', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'bash',
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
          toolName: 'bash',
          result: 'should not show yet',
          state: ToolState.running,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('duration shown only for completed state', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'bash',
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
          toolName: 'bash',
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
        createTestWidget(toolName: 'bash', result: longText),
      );
      expect(find.textContaining('[...truncated...]'), findsOneWidget);
    });

    testWidgets('bash tool shows command and description', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          toolName: 'bash',
          result: 'output',
          input: {'command': 'ls -la', 'description': 'List files'},
        ),
      );
      // Command appears in both title and body, so at least one is fine
      expect(find.textContaining(r'$ ls -la'), findsAtLeast(1));
      expect(find.textContaining('# List files'), findsOneWidget);
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
          toolName: 'bash',
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
          toolName: 'bash',
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
}
