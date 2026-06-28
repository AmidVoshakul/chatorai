import 'package:test/test.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';

void main() {
  group('LspPosition', () {
    test('creates from JSON', () {
      final json = {'line': 10, 'character': 5};
      final pos = LspPosition.fromJson(json);
      expect(pos.line, 10);
      expect(pos.character, 5);
    });

    test('converts to JSON', () {
      const pos = LspPosition(line: 1, character: 2);
      expect(pos.toJson(), {'line': 1, 'character': 2});
    });
  });

  group('LspRange', () {
    test('creates from JSON', () {
      final json = {
        'start': {'line': 0, 'character': 0},
        'end': {'line': 10, 'character': 5},
      };
      final range = LspRange.fromJson(json);
      expect(range.start.line, 0);
      expect(range.end.character, 5);
    });

    test('converts to JSON', () {
      const range = LspRange(
        start: LspPosition(line: 0, character: 0),
        end: LspPosition(line: 1, character: 1),
      );
      expect(range.toJson(), {
        'start': {'line': 0, 'character': 0},
        'end': {'line': 1, 'character': 1},
      });
    });
  });

  group('LspDiagnostic', () {
    test('creates from JSON', () {
      final json = {
        'range': {
          'start': {'line': 0, 'character': 0},
          'end': {'line': 5, 'character': 10},
        },
        'severity': 1,
        'message': 'Test error',
        'source': 'dart',
      };
      final diag = LspDiagnostic.fromJson(json);
      expect(diag.severity, 1);
      expect(diag.message, 'Test error');
      expect(diag.source, 'dart');
      expect(diag.range.start.line, 0);
    });

    test('converts to JSON', () {
      const diag = LspDiagnostic(
        range: LspRange(
          start: LspPosition(line: 0, character: 0),
          end: LspPosition(line: 1, character: 1),
        ),
        severity: 2,
        message: 'Warning',
      );
      final json = diag.toJson();
      expect(json['severity'], 2);
      expect(json['message'], 'Warning');
      expect(json['range'], isA<Map<String, dynamic>>());
    });

    test('handles optional fields', () {
      final diag = LspDiagnostic(
        range: const LspRange(
          start: LspPosition(line: 0, character: 0),
          end: LspPosition(line: 0, character: 0),
        ),
        severity: 3,
        message: 'Info',
      );
      expect(diag.code, isNull);
      expect(diag.source, isNull);
      expect(diag.data, isNull);
      expect(diag.relatedInformation, isNull);
    });
  });

  group('LspPublishDiagnosticsParams', () {
    test('creates from JSON', () {
      final json = {
        'uri': 'file:///test.dart',
        'version': '1',
        'diagnostics': [
          {
            'range': {
              'start': {'line': 0, 'character': 0},
              'end': {'line': 0, 'character': 10},
            },
            'severity': 1,
            'message': 'Error',
          },
        ],
      };
      final params = LspPublishDiagnosticsParams.fromJson(json);
      expect(params.uri, 'file:///test.dart');
      expect(params.diagnostics.length, 1);
      expect(params.diagnostics.first.severity, 1);
    });

    test('converts to JSON', () {
      const params = LspPublishDiagnosticsParams(
        uri: 'file:///test.dart',
        version: '1',
        diagnostics: [],
      );
      expect(params.toJson()['uri'], 'file:///test.dart');
    });
  });

  group('LspInitializeParams', () {
    test('creates from JSON', () {
      final json = {
        'processId': 123,
        'rootUri': 'file:///project',
        'capabilities': {
          'textDocument': {'hover': {}},
        },
      };
      final params = LspInitializeParams.fromJson(json);
      expect(params.processId, 123);
      expect(params.rootUri, 'file:///project');
      expect(params.capabilities, isNotNull);
    });

    test('converts to JSON', () {
      const params = LspInitializeParams(
        processId: 456,
        rootUri: 'file:///proj',
      );
      final json = params.toJson();
      expect(json['processId'], 456);
      expect(json['rootUri'], 'file:///proj');
    });

    test('handles null fields', () {
      const params = LspInitializeParams();
      final json = params.toJson();
      expect(json, isEmpty);
    });
  });

  group('LspInitializeResult', () {
    test('creates from JSON', () {
      final json = {
        'capabilities': {
          'textDocument': {'completion': {}},
        },
        'serverInfo': 'Dart Analysis Server',
      };
      final result = LspInitializeResult.fromJson(json);
      expect(result.capabilities, isNotNull);
      expect(result.serverInfo, 'Dart Analysis Server');
    });

    test('converts to JSON', () {
      const result = LspInitializeResult(serverInfo: 'Test Server');
      expect(result.toJson()['serverInfo'], 'Test Server');
    });
  });

  group('LspDiagnosticSeverity', () {
    test('has correct severity values', () {
      expect(LspDiagnosticSeverity.error, 1);
      expect(LspDiagnosticSeverity.warning, 2);
      expect(LspDiagnosticSeverity.info, 3);
      expect(LspDiagnosticSeverity.hint, 4);
    });

    test('labels severity correctly', () {
      expect(LspDiagnosticSeverity.label(1), 'Error');
      expect(LspDiagnosticSeverity.label(2), 'Warning');
      expect(LspDiagnosticSeverity.label(3), 'Info');
      expect(LspDiagnosticSeverity.label(4), 'Hint');
      expect(LspDiagnosticSeverity.label(99), 'Unknown');
    });
  });
}
