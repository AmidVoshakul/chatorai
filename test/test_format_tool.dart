import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chatorai/core/tools/built_in/format.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';

class MockFormatService extends Mock implements FormatService {}

void main() {
  late MockFormatService mockService;
  late ToolDef tool;

  setUp(() {
    mockService = MockFormatService();
    // Default: error path (no suitable formatter) for the catch-all tests
  });

  ToolContext makeCtx() => ToolContext(
    toolCallId: 'fmt-call-1',
    sessionId: 'fmt-session',
    ask: ({required permission, required patterns, metadata, always}) async {},
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
  );

  group('createFormatTool — schema & identity', () {
    test('tool id is format', () {
      tool = createFormatTool(mockService);
      expect(tool.id, 'format');
    });

    test('description mentions formatters', () {
      tool = createFormatTool(mockService);
      expect(tool.description, isNotEmpty);
      expect(tool.description.toLowerCase(), contains('format'));
    });

    test('inputSchema requires filePath', () {
      tool = createFormatTool(mockService);
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      final required = schema['required'] as List;
      expect(required, contains('filePath'));
    });

    test('inputSchema has filePath and formatter properties', () {
      tool = createFormatTool(mockService);
      final props = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(props.containsKey('filePath'), isTrue);
      expect(props.containsKey('formatter'), isTrue);
    });
  });

  group('createFormatTool — missing filePath', () {
    test('returns error ToolOutput when filePath is null', () async {
      tool = createFormatTool(mockService);
      final result = await tool.execute({}, makeCtx());
      expect(result.metadata?['error'], isTrue);
      expect(result.output, contains('filePath is required'));
    });

    test('returns error ToolOutput when filePath is empty string', () async {
      tool = createFormatTool(mockService);
      final result = await tool.execute({'filePath': ''}, makeCtx());
      expect(result.metadata?['error'], isTrue);
      expect(result.output, contains('filePath is required'));
    });
  });

  group('createFormatTool — success path', () {
    test('returns formatted output with metadata on success', () async {
      when(
        () => mockService.formatFile(
          '/tmp/test.dart',
          preferredFormatter: null,
          formatterConfig: null,
        ),
      ).thenAnswer(
        (_) async => FormatResult(
          formattedContent: 'void main() {}',
          formatter: 'dartfmt',
          changed: true,
        ),
      );

      tool = createFormatTool(mockService);
      final result = await tool.execute({
        'filePath': '/tmp/test.dart',
      }, makeCtx());

      expect(result.metadata?['error'], isNull);
      expect(result.metadata?['filePath'], '/tmp/test.dart');
      expect(result.metadata?['action'], 'format');
      expect(result.metadata?['formatter'], 'dartfmt');
      expect(result.metadata?['changed'], isTrue);
      expect(result.output, contains('dartfmt'));
      expect(result.output, contains('void main() {}'));
      expect(result.title, 'Format: /tmp/test.dart');
    });

    test('passes preferredFormatter to service', () async {
      when(
        () => mockService.formatFile(
          any(),
          preferredFormatter: 'prettier',
          formatterConfig: null,
        ),
      ).thenAnswer(
        (_) async => FormatResult(formattedContent: 'x', formatter: 'prettier'),
      );

      tool = createFormatTool(mockService);
      await tool.execute({
        'filePath': '/tmp/f.md',
        'formatter': 'prettier',
      }, makeCtx());

      verify(
        () => mockService.formatFile(
          any(),
          preferredFormatter: 'prettier',
          formatterConfig: null,
        ),
      ).called(1);
    });

    test('passes formatterConfig to service when provided', () async {
      final config = FormatterConfig();
      when(
        () => mockService.formatFile(
          any(),
          preferredFormatter: null,
          formatterConfig: config,
        ),
      ).thenAnswer(
        (_) async => FormatResult(formattedContent: 'x', formatter: 'dartfmt'),
      );

      tool = createFormatTool(mockService, config);
      await tool.execute({'filePath': '/tmp/f.dart'}, makeCtx());

      verify(
        () => mockService.formatFile(
          any(),
          preferredFormatter: null,
          formatterConfig: config,
        ),
      ).called(1);
    });
  });

  group('createFormatTool — service error result', () {
    test('returns error metadata when service returns error', () async {
      when(
        () => mockService.formatFile(
          any(),
          preferredFormatter: null,
          formatterConfig: null,
        ),
      ).thenAnswer(
        (_) async => FormatResult(
          formattedContent: '',
          formatter: 'none',
          error: 'No suitable formatter found',
        ),
      );

      tool = createFormatTool(mockService);
      final result = await tool.execute({
        'filePath': '/tmp/unknown.xyz',
      }, makeCtx());

      expect(result.metadata?['error'], isTrue);
      expect(result.metadata?['formatter'], 'none');
      expect(result.output, contains('Format failed'));
      expect(result.output, contains('No suitable formatter found'));
    });
  });

  group('createFormatTool — changed: false path', () {
    test('reports changed: false when no changes made', () async {
      when(
        () => mockService.formatFile(
          any(),
          preferredFormatter: null,
          formatterConfig: null,
        ),
      ).thenAnswer(
        (_) async => FormatResult(
          formattedContent: 'void main() {}',
          formatter: 'dartfmt',
          changed: false,
        ),
      );

      tool = createFormatTool(mockService);
      final result = await tool.execute({'filePath': '/tmp/f.dart'}, makeCtx());

      expect(result.metadata?['error'], isNull);
      expect(result.metadata?['changed'], isFalse);
      expect(result.output, contains('dartfmt'));
    });
  });

  group('createFormatTool — originalContent in output', () {
    test('includes original content when provided by service', () async {
      when(
        () => mockService.formatFile(
          any(),
          preferredFormatter: null,
          formatterConfig: null,
        ),
      ).thenAnswer(
        (_) async => FormatResult(
          formattedContent: 'void main() {}',
          originalContent: 'void main(){}',
          formatter: 'dartfmt',
          changed: true,
        ),
      );

      tool = createFormatTool(mockService);
      final result = await tool.execute({'filePath': '/tmp/f.dart'}, makeCtx());

      expect(result.output, contains('original'));
      expect(result.output, contains('void main(){}'));
    });

    test('omits original key when null', () async {
      when(
        () => mockService.formatFile(
          any(),
          preferredFormatter: null,
          formatterConfig: null,
        ),
      ).thenAnswer(
        (_) async => FormatResult(
          formattedContent: 'void main() {}',
          formatter: 'dartfmt',
          changed: true,
        ),
      );

      tool = createFormatTool(mockService);
      final result = await tool.execute({'filePath': '/tmp/f.dart'}, makeCtx());

      expect(result.output, isNot(contains('"original"')));
    });
  });

  group('createFormatTool — exception path', () {
    test('catches exception and returns error output', () async {
      when(
        () => mockService.formatFile(
          any(),
          preferredFormatter: null,
          formatterConfig: null,
        ),
      ).thenThrow(StateError('process not found'));

      tool = createFormatTool(mockService);
      final result = await tool.execute({'filePath': '/tmp/f.dart'}, makeCtx());

      expect(result.metadata?['error'], isTrue);
      expect(result.output, contains('Format error'));
    });
  });
}
