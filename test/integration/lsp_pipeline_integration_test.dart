import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/lsp_diagnostics_format.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/core/chat/chat/tool_result_part.dart';
import 'package:chatorai/core/chat/chat/message_part.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/parts/tool_result_part_widget.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';

void main() {
  group('LSP Pipeline Integration', () {
    group('parseLspFromToolOutput', () {
      test('parses single error from tool output text', () {
        const text =
            'LSP errors detected in this file, please fix:\n'
            '[ Error ] 5:10 — some error';
        final result = parseLspFromToolOutput(text);
        expect(result, hasLength(1));
        expect(result[5], hasLength(1));
        expect(result[5]![0].severity, equals(1));
        expect(result[5]![0].message, equals('some error'));
        expect(result[5]![0].range.start.line, equals(4));
        expect(result[5]![0].range.start.character, equals(9));
      });

      test('parses mixed errors and warnings', () {
        const text =
            'LSP errors detected in this file, please fix:\n'
            '[ Error ] 5:10 — first error\n'
            '[ Warning ] 8:3 — a warning\n'
            '[ Error ] 5:20 — second error';
        final result = parseLspFromToolOutput(text);
        expect(result, hasLength(2));
        expect(result[5], hasLength(2));
        expect(result[8], hasLength(1));
        expect(result[5]![0].message, equals('first error'));
        expect(result[5]![0].severity, equals(1));
        expect(result[5]![1].message, equals('second error'));
        expect(result[5]![1].severity, equals(1));
        expect(result[8]![0].message, equals('a warning'));
        expect(result[8]![0].severity, equals(2));
      });

      test('returns empty map for text without diagnostics', () {
        const text = '{"message": "File edited successfully"}';
        final result = parseLspFromToolOutput(text);
        expect(result, isEmpty);
      });

      test('returns empty map for No LSP errors detected message', () {
        const text = '{"message": "ok"}\n\nNo LSP errors detected.';
        final result = parseLspFromToolOutput(text);
        expect(result, isEmpty);
      });

      test('parses diagnostics wrapped in JSON tool output', () {
        final toolOutput =
            jsonEncode({
              'message': 'File edited successfully',
              'patch': '@@ -1 +1 @@\n-old\n+new',
            }) +
            '\n\n'
                'LSP errors detected in this file, please fix:\n'
                '[ Error ] 5:10 — missing semicolon';
        final result = parseLspFromToolOutput(toolOutput);
        expect(result, hasLength(1));
        expect(result[5], hasLength(1));
        expect(result[5]![0].message, equals('missing semicolon'));
      });

      test('handles Windows line endings (CRLF)', () {
        const text =
            'LSP errors detected in this file, please fix:\r\n'
            '[ Error ] 5:10 — some error\r\n';
        final result = parseLspFromToolOutput(text);
        expect(result, hasLength(1));
        expect(result[5], hasLength(1));
        expect(result[5]![0].message, equals('some error'));
      });

      test('handles XML special characters in messages', () {
        const text =
            'LSP errors detected in this file, please fix:\n'
            '[ Error ] 5:10 — use "const" where possible';
        final result = parseLspFromToolOutput(text);
        expect(result, hasLength(1));
        expect(result[5]![0].message, equals('use "const" where possible'));
      });
    });

    group('formatLspDiagnosticsXml round-trip', () {
      test('produces valid XML for errors and warnings', () {
        final diagnostics = [
          LspDiagnosticLine(
            line: 5,
            column: 10,
            severity: 'error',
            message: 'missing semicolon',
          ),
          LspDiagnosticLine(
            line: 8,
            column: 3,
            severity: 'warning',
            message: 'unused variable',
          ),
        ];
        final xml = formatLspDiagnosticsXml(diagnostics);
        expect(xml, contains('<diagnostics>'));
        expect(
          xml,
          contains('<error line="5" column="10" message="missing semicolon"/>'),
        );
        expect(
          xml,
          contains('<warning line="8" column="3" message="unused variable"/>'),
        );
        expect(xml, contains('</diagnostics>'));
      });

      test('escapes XML special characters in messages', () {
        final diagnostics = [
          LspDiagnosticLine(
            line: 1,
            column: 1,
            severity: 'error',
            message: 'use & < > " quotes',
          ),
        ];
        final xml = formatLspDiagnosticsXml(diagnostics);
        expect(xml, contains('&amp;'));
        expect(xml, contains('&lt;'));
        expect(xml, contains('&gt;'));
        expect(xml, contains('&quot;'));
      });

      test('includes file path attribute when provided', () {
        final diagnostics = [
          LspDiagnosticLine(
            line: 1,
            column: 1,
            severity: 'error',
            message: 'syntax error',
          ),
        ];
        final xml = formatLspDiagnosticsXml(
          diagnostics,
          filePath: 'lib/foo.dart',
        );
        expect(xml, contains('<diagnostics file="lib/foo.dart">'));
      });
    });

    group('ToolResultPartWidget — diagnostics UI for file tools', () {
      Widget buildWidget(
        String toolName,
        String result, {
        Map<String, dynamic>? input,
      }) {
        return MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ToolResultPartWidget(
              part: ToolResultPart(
                toolCallId: 'integration-test',
                toolName: toolName,
                result: result,
                state: ToolState.completed,
                input:
                    input ??
                    const {
                      'path': '/project/lib/foo.dart',
                      'content': 'hello\nworld',
                    },
                metadata: const {'session_id': 'test-session'},
              ),
            ),
          ),
        );
      }

      testWidgets('write tool shows diagnostics footer with error count', (
        tester,
      ) async {
        final toolOutput =
            'File written successfully\n\n'
            'LSP errors detected in this file, please fix:\n'
            '[ Error ] 5:10 — missing semicolon\n'
            '[ Error ] 8:3 — unused import';
        await tester.pumpWidget(buildWidget('write', toolOutput));
        await tester.pumpAndSettle();

        expect(find.textContaining('errors'), findsOneWidget);
        expect(find.textContaining('2 errors'), findsOneWidget);
      });

      testWidgets('edit tool shows diagnostics footer with warning count', (
        tester,
      ) async {
        final toolOutput =
            'File edited successfully\n\n'
            'LSP errors detected in this file, please fix:\n'
            '[ Warning ] 3:1 — unused variable\n'
            '[ Warning ] 6:5 — prefer const';
        await tester.pumpWidget(
          buildWidget(
            'edit',
            toolOutput,
            input: const {
              'path': '/project/lib/foo.dart',
              'old_string': 'hello world',
              'new_string': 'hello dart',
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('warnings'), findsOneWidget);
        expect(find.textContaining('2 warnings'), findsOneWidget);
      });

      testWidgets('apply_patch tool shows mixed errors and warnings', (
        tester,
      ) async {
        final toolOutput =
            jsonEncode({
              'message': 'Patch applied successfully',
              'patch': '@@ -1 +1 @@\n-old\n+new',
            }) +
            '\n\n'
                'LSP errors detected in this file, please fix:\n'
                '[ Error ] 1:1 — syntax error\n'
                '[ Warning ] 2:3 — prefer final\n'
                '[ Error ] 3:10 — missing return';
        await tester.pumpWidget(
          buildWidget(
            'apply_patch',
            toolOutput,
            input: const {
              'path': '/project/lib/foo.dart',
              'old_string': 'old content',
              'new_string': 'new content',
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('errors'), findsOneWidget);
        expect(find.textContaining('warning'), findsOneWidget);
        expect(find.textContaining('2 errors'), findsOneWidget);
        expect(find.textContaining('1 warning'), findsOneWidget);
      });

      testWidgets('no diagnostics hides footer', (tester) async {
        final toolOutput = '{"message": "ok"}\n\nNo LSP errors detected.';
        await tester.pumpWidget(buildWidget('write', toolOutput));
        await tester.pumpAndSettle();

        expect(find.textContaining('errors'), findsNothing);
        expect(find.textContaining('warnings'), findsNothing);
      });

      testWidgets('diagnostics footer shows error icon for errors', (
        tester,
      ) async {
        final toolOutput =
            'File written successfully\n\n'
            'LSP errors detected in this file, please fix:\n'
            '[ Error ] 1:1 — boom';
        await tester.pumpWidget(buildWidget('write', toolOutput));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('diagnostics footer shows warning icon for warnings only', (
        tester,
      ) async {
        final toolOutput =
            'File written successfully\n\n'
            'LSP errors detected in this file, please fix:\n'
            '[ Warning ] 1:1 — hint';
        await tester.pumpWidget(buildWidget('write', toolOutput));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.byIcon(Icons.error), findsNothing);
      });
    });
  });
}
