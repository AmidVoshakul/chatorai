import 'dart:convert';

import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/lsp.dart';
import 'package:chatorai/core/lsp/lsp_service.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';

class MockLspService extends Mock implements LspService {}

ToolContext _mockCtx() => ToolContext(
  toolCallId: 'test-call-id',
  sessionId: 'test-session',
  ask:
      ({
        required String permission,
        required List<String> patterns,
        Map<String, dynamic>? metadata,
        List<String>? always,
      }) async {},
  askQuestion:
      ({required question, options = const [], multiple = false}) async => '',
);

void main() {
  late MockLspService mockLsp;
  late ToolDef tool;

  setUp(() {
    mockLsp = MockLspService();
    tool = createLspTool(mockLsp);
  });

  group('schema & identity', () {
    test('tool id is "lsp"', () {
      expect(tool.id, 'lsp');
    });

    test('description is non-empty and mentions LSP', () {
      expect(tool.description, isNotEmpty);
      expect(tool.description.toLowerCase(), contains('language server'));
    });

    test('inputSchema requires filePath', () {
      final required = tool.inputSchema['required'] as List;
      expect(required, contains('filePath'));
    });

    test('inputSchema has action, line, character properties', () {
      final props = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(props.containsKey('action'), isTrue);
      expect(props.containsKey('line'), isTrue);
      expect(props.containsKey('character'), isTrue);
    });

    test('action enum lists all supported actions', () {
      final props = tool.inputSchema['properties'] as Map<String, dynamic>;
      final actionProp = props['action'] as Map<String, dynamic>;
      final enumValues = actionProp['enum'] as List;
      expect(
        enumValues,
        containsAll([
          'diagnostics',
          'hover',
          'definition',
          'references',
          'symbols',
        ]),
      );
    });
  });

  group('input validation', () {
    test('missing filePath returns error', () async {
      final output = await tool.execute({}, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('filePath is required'));
    });

    test('empty filePath returns error', () async {
      final output = await tool.execute({'filePath': ''}, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('filePath is required'));
    });
  });

  group('diagnostics action (default)', () {
    test('defaults to diagnostics when no action specified', () async {
      when(
        () => mockLsp.diagnostics('/tmp/f.dart'),
      ).thenAnswer((_) => const Stream.empty());

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
      }, _mockCtx());

      expect(output.metadata?['action'], 'diagnostics');
      expect(output.metadata?['errorCount'], 0);
      expect(output.metadata?['warningCount'], 0);
    });

    test('returns valid JSON with summary when no diagnostics', () async {
      when(
        () => mockLsp.diagnostics('/tmp/f.dart'),
      ).thenAnswer((_) => const Stream.empty());

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
      }, _mockCtx());
      final decoded = jsonDecode(output.output) as Map<String, dynamic>;

      expect(decoded['action'], 'diagnostics');
      expect(decoded['summary']['errors'], 0);
      expect(decoded['summary']['warnings'], 0);
      expect(decoded['summary']['total'], 0);
      expect(decoded['diagnostics'], isEmpty);
    });

    test('counts errors (severity 1) and warnings (severity 2)', () async {
      when(() => mockLsp.diagnostics('/tmp/f.dart')).thenAnswer(
        (_) => Stream.fromIterable([
          const LspDiagnostic(
            severity: 1,
            range: LspRange(
              start: LspPosition(line: 0, character: 0),
              end: LspPosition(line: 0, character: 5),
            ),
            message: 'error msg',
          ),
          const LspDiagnostic(
            severity: 1,
            range: LspRange(
              start: LspPosition(line: 1, character: 0),
              end: LspPosition(line: 1, character: 3),
            ),
            message: 'another error',
          ),
          const LspDiagnostic(
            severity: 2,
            range: LspRange(
              start: LspPosition(line: 2, character: 0),
              end: LspPosition(line: 2, character: 4),
            ),
            message: 'warning msg',
          ),
        ]),
      );

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
      }, _mockCtx());
      final decoded = jsonDecode(output.output) as Map<String, dynamic>;

      expect(decoded['summary']['errors'], 2);
      expect(decoded['summary']['warnings'], 1);
      expect(decoded['summary']['total'], 3);
      expect(decoded['diagnostics'], hasLength(3));
    });

    test('sets error=true in metadata when errors > 0', () async {
      when(() => mockLsp.diagnostics('/tmp/f.dart')).thenAnswer(
        (_) => Stream.fromIterable([
          const LspDiagnostic(
            severity: 1,
            range: LspRange(
              start: LspPosition(line: 0, character: 0),
              end: LspPosition(line: 0, character: 1),
            ),
            message: 'err',
          ),
        ]),
      );

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
      }, _mockCtx());
      expect(output.metadata?['error'], isTrue);
    });

    test('error key absent when no errors', () async {
      when(() => mockLsp.diagnostics('/tmp/f.dart')).thenAnswer(
        (_) => Stream.fromIterable([
          const LspDiagnostic(
            severity: 2,
            range: LspRange(
              start: LspPosition(line: 0, character: 0),
              end: LspPosition(line: 0, character: 1),
            ),
            message: 'warn',
          ),
        ]),
      );

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
      }, _mockCtx());
      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['warningCount'], 1);
    });

    test('title is set correctly', () async {
      when(
        () => mockLsp.diagnostics('/tmp/f.dart'),
      ).thenAnswer((_) => const Stream.empty());

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
      }, _mockCtx());
      expect(output.title, 'LSP diagnostics: /tmp/f.dart');
    });

    test('metadata includes filePath', () async {
      when(
        () => mockLsp.diagnostics('/tmp/f.dart'),
      ).thenAnswer((_) => const Stream.empty());

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
      }, _mockCtx());
      expect(output.metadata?['filePath'], '/tmp/f.dart');
    });
  });

  group('hover action', () {
    test('returns hover information', () async {
      when(() => mockLsp.hover('/tmp/f.dart', 10, 5)).thenAnswer(
        (_) async => {
          'contents': {'kind': 'markdown', 'value': '**int**'},
        },
      );

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'hover',
        'line': 10,
        'character': 5,
      }, _mockCtx());

      expect(output.metadata?['action'], 'hover');
      expect(output.metadata?['line'], 10);
      expect(output.metadata?['character'], 5);
      expect(output.output, contains('int'));
      expect(output.title, 'LSP hover: /tmp/f.dart:10:5');
    });

    test('defaults line and character to 0 when not provided', () async {
      when(
        () => mockLsp.hover('/tmp/f.dart', 0, 0),
      ).thenAnswer((_) async => null);

      await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'hover',
      }, _mockCtx());

      verify(() => mockLsp.hover('/tmp/f.dart', 0, 0)).called(1);
    });

    test('returns message when no hover info available', () async {
      when(
        () => mockLsp.hover('/tmp/f.dart', 0, 0),
      ).thenAnswer((_) async => null);

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'hover',
      }, _mockCtx());

      expect(output.output, contains('No hover information'));
      expect(output.metadata?['action'], 'hover');
    });
  });

  group('definition action', () {
    test('returns definition locations', () async {
      when(() => mockLsp.definition('/tmp/f.dart', 5, 10)).thenAnswer(
        (_) async => [
          {'uri': 'file:///lib/utils.dart', 'line': 20, 'character': 0},
        ],
      );

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'definition',
        'line': 5,
        'character': 10,
      }, _mockCtx());

      expect(output.metadata?['action'], 'definition');
      expect(output.metadata?['count'], 1);
      expect(output.output, contains('utils.dart'));
      expect(output.title, 'LSP definition: /tmp/f.dart:5:10');
    });

    test('defaults line and character to 0', () async {
      when(
        () => mockLsp.definition('/tmp/f.dart', 0, 0),
      ).thenAnswer((_) async => []);

      await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'definition',
      }, _mockCtx());

      verify(() => mockLsp.definition('/tmp/f.dart', 0, 0)).called(1);
    });

    test('count is 0 when no definitions found', () async {
      when(
        () => mockLsp.definition('/tmp/f.dart', 0, 0),
      ).thenAnswer((_) async => []);

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'definition',
      }, _mockCtx());

      expect(output.metadata?['count'], 0);
    });
  });

  group('references action', () {
    test('returns reference locations', () async {
      when(() => mockLsp.references('/tmp/f.dart', 3, 7)).thenAnswer(
        (_) async => [
          {'uri': 'file:///lib/main.dart', 'line': 10, 'character': 5},
          {'uri': 'file:///lib/app.dart', 'line': 42, 'character': 0},
        ],
      );

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'references',
        'line': 3,
        'character': 7,
      }, _mockCtx());

      expect(output.metadata?['action'], 'references');
      expect(output.metadata?['count'], 2);
      expect(output.output, contains('main.dart'));
      expect(output.title, 'LSP references: /tmp/f.dart:3:7');
    });

    test('defaults line and character to 0', () async {
      when(
        () => mockLsp.references('/tmp/f.dart', 0, 0),
      ).thenAnswer((_) async => []);

      await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'references',
      }, _mockCtx());

      verify(() => mockLsp.references('/tmp/f.dart', 0, 0)).called(1);
    });
  });

  group('unsupported action', () {
    test('returns error for unknown action', () async {
      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'symbols',
      }, _mockCtx());

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('Unsupported action'));
      expect(output.output, contains('symbols'));
    });
  });

  group('exception handling', () {
    test('catches LspService exception and returns error', () async {
      when(
        () => mockLsp.diagnostics('/tmp/f.dart'),
      ).thenThrow(StateError('LSP server crashed'));

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'diagnostics',
      }, _mockCtx());

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('LSP error'));
    });

    test('hover exception returns error', () async {
      when(
        () => mockLsp.hover('/tmp/f.dart', 0, 0),
      ).thenThrow(StateError('connection lost'));

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'hover',
      }, _mockCtx());

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('LSP error'));
    });

    test('definition exception returns error', () async {
      when(
        () => mockLsp.definition('/tmp/f.dart', 0, 0),
      ).thenThrow(StateError('timeout'));

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'definition',
      }, _mockCtx());

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('LSP error'));
    });

    test('references exception returns error', () async {
      when(
        () => mockLsp.references('/tmp/f.dart', 0, 0),
      ).thenThrow(StateError('server died'));

      final output = await tool.execute({
        'filePath': '/tmp/f.dart',
        'action': 'references',
      }, _mockCtx());

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('LSP error'));
    });
  });

  group('permission', () {
    test('does not call ctx.ask', () async {
      bool askCalled = false;
      when(
        () => mockLsp.diagnostics('/tmp/f.dart'),
      ).thenAnswer((_) => const Stream.empty());

      final ctx = ToolContext(
        toolCallId: 'test',
        sessionId: 'test',
        ask:
            ({
              required String permission,
              required List<String> patterns,
              Map<String, dynamic>? metadata,
              List<String>? always,
            }) async {
              askCalled = true;
            },
        askQuestion:
            ({required question, options = const [], multiple = false}) async =>
                '',
      );

      await tool.execute({'filePath': '/tmp/f.dart'}, ctx);
      expect(askCalled, isFalse);
    });
  });
}
