import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/webfetch.dart';

ToolContext _mockCtx({
  bool askResult = true,
  List<String>? askedPermission,
  List<String>? askedPatterns,
}) {
  askedPermission = askedPermission;
  askedPatterns = askedPatterns;
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: 'test-session',
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {
          askedPermission = [permission];
          askedPatterns = patterns;
        },
  );
}

void main() {
  group('webfetch tool', () {
    test('description is non-empty', () {
      final tool = createWebfetchTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required url field', () {
      final tool = createWebfetchTool();
      final schema = tool.inputSchema as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('url'), isTrue);
      expect(properties['url']['type'], equals('string'));
      expect((schema['required'] as List).contains('url'), isTrue);
    });

    test('execute with missing url throws error', () async {
      final tool = createWebfetchTool();
      final ctx = _mockCtx();
      expect(() => tool.execute({}, ctx), throwsArgumentError);
    });

    test('execute calls ctx.ask with correct permission and pattern', () async {
      final tool = createWebfetchTool();
      String? capturedPermission;
      List<String>? capturedPatterns;
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
            },
      );
      await tool.execute({'url': 'https://example.com'}, ctx);
      expect(capturedPermission, equals('webfetch'));
      expect(capturedPatterns, contains('webfetch:url=https://example.com'));
    });

    test('execute with invalid URL returns error', () async {
      final tool = createWebfetchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'url': 'not-a-valid-url'}, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('invalid URL'));
    });

    test('execute with non-http scheme returns error', () async {
      final tool = createWebfetchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'url': 'ftp://example.com'}, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('only http/https'));
    });

    test('execute with private host returns error', () async {
      final tool = createWebfetchTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'url': 'http://localhost:8080'}, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('private/internal hosts'));
    });

    test(
      'execute with connection timeout returns error',
      () async {
        final tool = createWebfetchTool();
        final ctx = _mockCtx();
        // Use a non-routable IP to trigger timeout
        final output = await tool.execute({
          'url': 'http://10.255.255.1/',
          'max_chars': 100,
        }, ctx);
        // Should timeout or connection refused
        expect(output.metadata?.containsKey('error'), isTrue);
      },
      timeout: Timeout(const Duration(seconds: 15)),
    );

    test(
      'execute with successful HTTP 200 returns content',
      () async {
        final tool = createWebfetchTool();
        final ctx = _mockCtx();

        // Use a reliable public endpoint
        final output = await tool.execute({
          'url': 'https://httpbin.org/status/200',
          'max_chars': 1000,
        }, ctx);

        // httpbin.org returns empty body for 200, but should not error
        expect(output.metadata?['error'], isNull);
      },
      skip: 'Network test - may fail if httpbin.org is unreachable',
    );

    test(
      'execute handles UTF-8 content correctly',
      () async {
        final tool = createWebfetchTool();
        final ctx = _mockCtx();

        // Use a URL that returns UTF-8 content
        final output = await tool.execute({
          'url': 'https://httpbin.org/encoding/utf8',
          'max_chars': 500,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        // The response should contain UTF-8 Chinese/Russian characters
        if (output.output.isNotEmpty) {
          expect(output.output, isA<String>());
        }
      },
      skip: 'Network test - verifies UTF-8 decoding',
    );
  });
}
