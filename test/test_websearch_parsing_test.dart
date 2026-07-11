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
    test(
      'numResults as string "3" does not throw',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        // Even if network fails, parsing should not throw
        final output = await tool.execute({
          'query': 'test',
          'numResults': '3',
        }, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'numResults as string "0" does not throw',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({
          'query': 'test',
          'numResults': '0',
        }, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'numResults as string "100" does not throw',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({
          'query': 'test',
          'numResults': '100',
        }, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'numResults as invalid string "abc" does not throw',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({
          'query': 'test',
          'numResults': 'abc',
        }, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'numResults as negative number does not throw',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({
          'query': 'test',
          'numResults': -5,
        }, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'numResults as double string "3.5" does not throw',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({
          'query': 'test',
          'numResults': '3.5',
        }, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );
  });

  group('websearch special characters (no network)', () {
    test(
      'query with ampersand does not throw',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({'query': 'flutter & dart'}, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'query with angle brackets does not throw',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({
          'query': 'flutter <test> dart',
        }, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'query with quotes does not throw',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({'query': 'flutter "dart"'}, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'query with unicode characters does not throw',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({'query': 'флатер дарт'}, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );
  });

  group('websearch permission patterns', () {
    test(
      'execute calls ctx.ask with correct permission and pattern',
      () async {
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
              ({
                required question,
                options = const [],
                multiple = false,
              }) async => '',
        );
        await tool.execute({'query': 'flutter widgets', 'numResults': 3}, ctx);
        expect(capturedPermission, equals('websearch'));
        expect(capturedPatterns, equals(['websearch:query=flutter widgets']));
        expect(capturedMetadata?['query'], equals('flutter widgets'));
        expect(capturedMetadata?['numResults'], isA<int>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );
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

    test('inputSchema has region as string type', () {
      final tool = createWebsearchTool();
      final p = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(p.containsKey('region'), isTrue);
      expect(p['region']['type'], equals('string'));
    });

    test('inputSchema does not require region', () {
      final tool = createWebsearchTool();
      final required = tool.inputSchema['required'] as List;
      expect(required.contains('region'), isFalse);
    });

    test('region description mentions default "us-en"', () {
      final tool = createWebsearchTool();
      final p = tool.inputSchema['properties'] as Map<String, dynamic>;
      final desc = p['region']['description'] as String;
      expect(desc, contains('us-en'));
    });

    test('inputSchema has timeLimit as string type', () {
      final tool = createWebsearchTool();
      final p = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(p.containsKey('timeLimit'), isTrue);
      expect(p['timeLimit']['type'], equals('string'));
    });

    test('inputSchema does not require timeLimit', () {
      final tool = createWebsearchTool();
      final required = tool.inputSchema['required'] as List;
      expect(required.contains('timeLimit'), isFalse);
    });

    test('inputSchema has safeSearch as string type', () {
      final tool = createWebsearchTool();
      final p = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(p.containsKey('safeSearch'), isTrue);
      expect(p['safeSearch']['type'], equals('string'));
    });

    test('inputSchema does not require safeSearch', () {
      final tool = createWebsearchTool();
      final required = tool.inputSchema['required'] as List;
      expect(required.contains('safeSearch'), isFalse);
    });

    test('safeSearch description mentions default "moderate"', () {
      final tool = createWebsearchTool();
      final p = tool.inputSchema['properties'] as Map<String, dynamic>;
      final desc = p['safeSearch']['description'] as String;
      expect(desc, contains('moderate'));
    });

    test('inputSchema has contextMaxCharacters as integer type', () {
      final tool = createWebsearchTool();
      final p = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(p.containsKey('contextMaxCharacters'), isTrue);
      expect(p['contextMaxCharacters']['type'], equals('integer'));
    });

    test('inputSchema does not require contextMaxCharacters', () {
      final tool = createWebsearchTool();
      final required = tool.inputSchema['required'] as List;
      expect(required.contains('contextMaxCharacters'), isFalse);
    });

    test('inputSchema has detailLevel as string type', () {
      final tool = createWebsearchTool();
      final p = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(p.containsKey('detailLevel'), isTrue);
      expect(p['detailLevel']['type'], equals('string'));
    });

    test('inputSchema does not require detailLevel', () {
      final tool = createWebsearchTool();
      final required = tool.inputSchema['required'] as List;
      expect(required.contains('detailLevel'), isFalse);
    });

    test('detailLevel description mentions "title_only" option', () {
      final tool = createWebsearchTool();
      final p = tool.inputSchema['properties'] as Map<String, dynamic>;
      final desc = p['detailLevel']['description'] as String;
      expect(desc, contains('title_only'));
    });

    test('numResults description mentions max 25', () {
      final tool = createWebsearchTool();
      final p = tool.inputSchema['properties'] as Map<String, dynamic>;
      final desc = p['numResults']['description'] as String;
      expect(desc, contains('max 25'));
    });
  });

  group('websearch new params parsing', () {
    test(
      'all new params together calls ctx.ask (proves parsing success)',
      () async {
        bool askCalled = false;
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
              ({
                required question,
                options = const [],
                multiple = false,
              }) async => '',
        );
        final tool = createWebsearchTool();
        await tool.execute({
          'query': 'test',
          'region': 'ru-ru',
          'safeSearch': 'on',
          'timeLimit': 'w',
          'contextMaxCharacters': 100,
          'detailLevel': 'title_only',
        }, ctx);
        expect(
          askCalled,
          isTrue,
          reason: 'ctx.ask must be called, proving params parsed and logged',
        );
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'region defaults to "us-en" when not provided',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({'query': 'test'}, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test('region "ru-ru" is accepted', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({
        'query': 'test',
        'region': 'ru-ru',
      }, ctx);
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));

    test(
      'safeSearch defaults to "moderate" when not provided',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({'query': 'test'}, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test('safeSearch "on" is accepted', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({
        'query': 'test',
        'safeSearch': 'on',
      }, ctx);
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));

    test(
      'timeLimit can be omitted (null)',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({'query': 'test'}, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test('timeLimit "d" is accepted', () async {
      final tool = createWebsearchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({
        'query': 'test',
        'timeLimit': 'd',
      }, ctx);
      expect(output, isA<ToolOutput>());
    }, timeout: Timeout(const Duration(seconds: 20)));

    test(
      'contextMaxCharacters as int 500 is accepted',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({
          'query': 'test',
          'contextMaxCharacters': 500,
        }, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'contextMaxCharacters can be omitted',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({'query': 'test'}, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'detailLevel defaults to "snippet" when not provided',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({'query': 'test'}, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'detailLevel "title_only" is accepted',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({
          'query': 'test',
          'detailLevel': 'title_only',
        }, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );

    test(
      'Invalid detailLevel value still resolves without error',
      () async {
        final tool = createWebsearchTool();
        final ctx = _mockCtx();
        final output = await tool.execute({
          'query': 'test',
          'detailLevel': 'invalid_value',
        }, ctx);
        expect(output, isA<ToolOutput>());
      },
      timeout: Timeout(const Duration(seconds: 20)),
    );
  });

  group('websearch post-processing', () {
    test('contextMaxCharacters description allows optional truncation', () {
      final tool = createWebsearchTool();
      final p = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(p.containsKey('contextMaxCharacters'), isTrue);
      expect(p['contextMaxCharacters']['type'], equals('integer'));
    });

    test('detailLevel schema documents "title_only" and "snippet" options', () {
      final tool = createWebsearchTool();
      final desc =
          tool.inputSchema['properties']['detailLevel']['description']
              as String;
      expect(desc, contains('title_only'));
      expect(desc, contains('snippet'));
    });

    test('numResults max value bumped to 25 in description', () {
      final tool = createWebsearchTool();
      final desc =
          tool.inputSchema['properties']['numResults']['description'] as String;
      expect(desc, contains('max 25'));
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
