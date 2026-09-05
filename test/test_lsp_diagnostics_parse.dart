import 'dart:convert';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/lsp_diagnostics_format.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';

void main() {
  group('parseLspFromToolOutput', () {
    test('parses single error', () {
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

    test('parses multiple diagnostics on different lines', () {
      const text =
          'LSP errors detected in this file, please fix:\n'
          '[ Error ] 5:10 — first error\n'
          '[ Warning ] 8:3 — a warning\n'
          '[ Error ] 5:20 — second error on line 5';
      final result = parseLspFromToolOutput(text);
      expect(result, hasLength(2));
      expect(result[5], hasLength(2));
      expect(result[8], hasLength(1));
      expect(result[5]![0].message, equals('first error'));
      expect(result[5]![1].message, equals('second error on line 5'));
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

    test('parses from actual tool output format', () {
      final toolOutput =
          jsonEncode({
            'message': 'File edited successfully',
            'patch': '@@ -1 +1 @@\n-old\n+new',
          }) +
          '\n\nLSP errors detected in this file, please fix:\n'
              '[ Error ] 3:1 — The argument type \'int\' can\'t be assigned';
      final result = parseLspFromToolOutput(toolOutput);
      expect(result, hasLength(1));
      expect(
        result[3]![0].message,
        contains("The argument type 'int' can't be assigned"),
      );
    });

    test('handles ERROR (uppercase) labels', () {
      const text =
          'LSP errors detected in this file, please fix:\n'
          '[ ERROR ] 1:1 — something\n'
          '[ WARN ] 2:2 — watch out';
      final result = parseLspFromToolOutput(text);
      expect(result[1]![0].severity, equals(1));
      expect(result[2]![0].severity, equals(2));
    });

    test('round-trips through format then parse', () {
      final lines = [
        LspDiagnosticLine(
          severity: 'Error',
          line: 5,
          column: 10,
          message: 'some error',
        ),
        LspDiagnosticLine(
          severity: 'Warning',
          line: 8,
          column: 3,
          message: 'some warning',
        ),
      ];
      final formatted = formatLspDiagnostics(lines);
      final parsed = parseLspFromToolOutput(formatted);
      expect(parsed, hasLength(2));
      expect(parsed[5]![0].message, equals('some error'));
      expect(parsed[5]![0].severity, equals(1));
      expect(parsed[8]![0].message, equals('some warning'));
      expect(parsed[8]![0].severity, equals(2));
    });
  });

  group('stripLspFromToolOutput', () {
    test('removes LSP block from tool output', () {
      final json = jsonEncode({'message': 'ok', 'patch': '...'});
      const lsp =
          '\n\nLSP errors detected in this file, please fix:\n'
          '[ Error ] 5:10 — error';
      final combined = json + lsp;
      expect(stripLspFromToolOutput(combined), equals(json));
    });

    test('returns original if no LSP block', () {
      const text = '{"message": "ok"}';
      expect(stripLspFromToolOutput(text), equals(text));
    });
  });

  group('formatLspDiagnosticsXml', () {
    test('generates XML without file path', () {
      final diags = [
        LspDiagnosticLine(
          severity: 'Error',
          line: 5,
          column: 10,
          message: 'some error',
        ),
        LspDiagnosticLine(
          severity: 'Warning',
          line: 8,
          column: 3,
          message: 'some warning',
        ),
      ];
      final xml = formatLspDiagnosticsXml(diags);
      expect(xml, startsWith('<diagnostics>'));
      expect(xml, contains('<error line="5" column="10"'));
      expect(xml, contains('<warning line="8" column="3"'));
      expect(xml, endsWith('</diagnostics>'));
    });

    test('generates XML with file path', () {
      final diags = [
        LspDiagnosticLine(
          severity: 'Error',
          line: 1,
          column: 1,
          message: 'test',
        ),
      ];
      final xml = formatLspDiagnosticsXml(diags, filePath: 'src/main.dart');
      expect(xml, contains('<diagnostics file="src/main.dart">'));
    });

    test('escapes XML special characters in message', () {
      final diags = [
        LspDiagnosticLine(
          severity: 'Error',
          line: 1,
          column: 1,
          message: 'type "int" & <String>',
        ),
      ];
      final xml = formatLspDiagnosticsXml(diags);
      expect(xml, contains('&quot;int&quot;'));
      expect(xml, contains('&amp;'));
      expect(xml, contains('&lt;String&gt;'));
    });
  });
}
