import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/websearch.dart';

ToolContext _mockCtx() {
  return ToolContext(
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
}

void main() {
  group('websearch input validation (no network)', () {
    test('empty query returns error without throwing', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'query': ''}, ctx);
      expect(output, isA<ToolOutput>());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('required'));
    });

    test('whitespace-only query returns error without throwing', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'query': '   '}, ctx);
      expect(output, isA<ToolOutput>());
      expect(output.metadata?['error'], isTrue);
    });

    test('missing query returns error without throwing', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({}, ctx);
      expect(output, isA<ToolOutput>());
      expect(output.metadata?['error'], isTrue);
    });

    test('null query returns error without throwing', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'query': null}, ctx);
      expect(output, isA<ToolOutput>());
      expect(output.metadata?['error'], isTrue);
    });
  });

  group('websearch numResults parsing (no network)', () {
    test('numResults as string "3" does not throw', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      // Even if network fails, parsing should not throw
      final output = await tool.execute(
        {'query': 'test', 'numResults': '3'},
        ctx,
      );
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));

    test('numResults as string "0" does not throw', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute(
        {'query': 'test', 'numResults': '0'},
        ctx,
      );
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));

    test('numResults as string "100" does not throw', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute(
        {'query': 'test', 'numResults': '100'},
        ctx,
      );
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));

    test('numResults as invalid string "abc" does not throw', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute(
        {'query': 'test', 'numResults': 'abc'},
        ctx,
      );
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));

    test('numResults as negative number does not throw', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute(
        {'query': 'test', 'numResults': -5},
        ctx,
      );
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));

    test('numResults as double string "3.5" does not throw', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute(
        {'query': 'test', 'numResults': '3.5'},
        ctx,
      );
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));
  });

  group('websearch special characters (no network)', () {
    test('query with ampersand does not throw', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute(
        {'query': 'flutter & dart'},
        ctx,
      );
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));

    test('query with angle brackets does not throw', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute(
        {'query': 'flutter <test> dart'},
        ctx,
      );
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));

    test('query with quotes does not throw', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute(
        {'query': 'flutter "dart"'},
        ctx,
      );
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));

    test('query with unicode characters does not throw', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute(
        {'query': 'флатер дарт'},
        ctx,
      );
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));
  });

  group('websearch permission patterns', () {
    test('execute calls ctx.ask with correct permission and pattern', () async {
      final tool = createWebsearchTool();
      String? capturedPermission;
      List<String>? capturedPatterns;
      Map<String, dynamic>? capturedMetadata;
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
              capturedPermission = permission;
              capturedPatterns = patterns;
              capturedMetadata = metadata;
            },
        askQuestion:
            ({required question, options = const [], multiple = false}) async =>
                '',
      );
      await tool.execute({'query': 'flutter widgets', 'numResults': 3}, ctx);
      expect(capturedPermission, equals('websearch'));
      expect(capturedPatterns, equals(['websearch:query=flutter widgets']));
      expect(capturedMetadata?['query'], equals('flutter widgets'));
      expect(capturedMetadata?['numResults'], isA<int>());
    }, timeout: Timeout(const Duration(seconds: 20)));
  });

  group('websearch schema', () {
    test('inputSchema has numResults as integer type', () {
      final tool = createWebsearchTool();
      final schema = tool.inputSchema;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('numResults'), isTrue);
      expect(properties['numResults']['type'], equals('integer'));
    });

    test('inputSchema does not require numResults', () {
      final tool = createWebsearchTool();
      final schema = tool.inputSchema;
      final required = schema['required'] as List;
      expect(required.contains('numResults'), isFalse);
    });

    test('description is non-empty', () {
      final tool = createWebsearchTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required query field', () {
      final tool = createWebsearchTool();
      final schema = tool.inputSchema;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('query'), isTrue);
      expect(properties['query']['type'], equals('string'));
      expect((schema['required'] as List<String>).contains('query'), isTrue);
    });
  });

  group('websearch metadata', () {
    test('metadata contains count and query on success', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'query': 'dart programming'}, ctx);

      if (output.metadata?['error'] != true) {
        expect(output.metadata!.containsKey('count'), isTrue);
        expect(output.metadata!.containsKey('query'), isTrue);
      }
    });

    test('metadata contains error: true on failure', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'query': ''}, ctx);
      expect(output.metadata?['error'], isTrue);
    });
  });
}
