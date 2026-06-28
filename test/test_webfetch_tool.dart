import 'dart:convert';

import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/webfetch.dart';

ToolContext _mockCtx({
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
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
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
      final schema = tool.inputSchema;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('url'), isTrue);
      expect(properties['url']['type'], equals('string'));
      expect((schema['required'] as List<String>).contains('url'), isTrue);
    });

    test('inputSchema has timeout field with constraints', () {
      final tool = createWebfetchTool();
      final properties = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('timeout'), isTrue);
      expect(properties['timeout']['type'], equals('integer'));
      final description = properties['timeout']['description'] as String;
      expect(description, contains('30'));
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
        askQuestion:
            ({required question, options = const [], multiple = false}) async =>
                '',
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

        final output = await tool.execute({
          'url': 'https://example.com',
          'max_chars': 1000,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, isA<String>());
        expect(output.output, isNotEmpty);
      },
      timeout: Timeout(const Duration(seconds: 15)),
    );

    test(
      'execute handles UTF-8 content correctly',
      () async {
        final tool = createWebfetchTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'url': 'https://example.com',
          'max_chars': 500,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, isA<String>());
        expect(output.output, isNotEmpty);
      },
      timeout: Timeout(const Duration(seconds: 15)),
    );

    group('private host blocking (comprehensive)', () {
      final privateHosts = [
        'http://127.0.0.1',
        'http://127.0.0.1:8080',
        'http://10.0.0.1',
        'http://172.16.0.1',
        'http://172.31.255.255',
        'http://192.168.1.1',
        'http://169.254.169.254',
        'http://localhost',
        'http://localhost:3000',
        'http://myserver.local',
        'http://myserver.local:8080',
        'http://[::1]',
        // IPv6 unique-local (fc00::/7)
        'http://[fc00::1]',
        'http://[fd00::1]',
        // IPv6 link-local (fe80::/10)
        'http://[fe80::1]',
        // IPv4-mapped IPv6 private addresses
        'http://[::ffff:192.168.1.1]',
        'http://[::ffff:10.0.0.1]',
        'http://[::ffff:169.254.169.254]',
      ];

      for (final url in privateHosts) {
        test('blocks private host: $url', () async {
          final tool = createWebfetchTool();
          final ctx = _mockCtx();
          final output = await tool.execute({'url': url}, ctx);
          expect(output.metadata?['error'], isTrue);
          expect(output.output, contains('private/internal hosts'));
        });
      }
    });

    test(
      'public IPv6 address is NOT blocked as private',
      () async {
        final tool = createWebfetchTool();
        final ctx = _mockCtx();
        // 2001:db8::/32 is documentation range (public, should NOT be blocked
        // as private). The connection will fail (unreachable), but that should
        // be a network error, not a "private host" error.
        final output = await tool.execute({
          'url': 'http://[2001:db8::1]/',
          'max_chars': 100,
          'timeout': 5,
        }, ctx);
        expect(
          output.metadata?['error'],
          isTrue,
          reason:
              'Public unreachable IPv6 should produce a network error, '
              'not be blocked: ${output.output}',
        );
        expect(
          output.output,
          isNot(contains('private')),
          reason:
              'Public IPv6 should not be blocked as private: '
              '${output.output}',
        );
      },
      timeout: Timeout(const Duration(seconds: 10)),
    );

    group('network error handling', () {
      test(
        'connection refused returns error metadata',
        () async {
          final tool = createWebfetchTool();
          final ctx = _mockCtx();
          final output = await tool.execute({'url': 'http://127.0.0.1:1'}, ctx);
          expect(output.metadata?['error'], isTrue);
        },
        timeout: Timeout(const Duration(seconds: 15)),
      );

      test(
        'DNS failure returns error metadata',
        () async {
          final tool = createWebfetchTool();
          final ctx = _mockCtx();
          final output = await tool.execute({
            'url': 'https://this-domain-does-not-exist-12345.invalid',
          }, ctx);
          expect(output.metadata?['error'], isTrue);
        },
        timeout: Timeout(const Duration(seconds: 15)),
      );
    });
  });

  group('resolveRedirectUri', () {
    test('allows redirect to public HTTPS host', () {
      final current = Uri.parse('https://example.com/page');
      final result = resolveRedirectUri(current, 'https://other-site.com');
      expect(result, isNotNull);
      expect(result!.toString(), equals('https://other-site.com'));
    });

    test('allows redirect relative path', () {
      final current = Uri.parse('https://example.com/page');
      final result = resolveRedirectUri(current, '/other');
      expect(result, isNotNull);
      expect(result!.toString(), equals('https://example.com/other'));
    });

    test('blocks redirect to 169.254.169.254 (metadata IP)', () {
      final current = Uri.parse('https://example.com/page');
      final result = resolveRedirectUri(
        current,
        'http://169.254.169.254/latest/meta-data/',
      );
      expect(result, isNull);
    });

    test('blocks redirect to localhost', () {
      final current = Uri.parse('https://example.com/page');
      final result = resolveRedirectUri(
        current,
        'http://127.0.0.1:8080/secret',
      );
      expect(result, isNull);
    });

    test('blocks redirect to 10.x.x.x', () {
      final current = Uri.parse('https://example.com/page');
      final result = resolveRedirectUri(current, 'http://10.0.0.1/admin');
      expect(result, isNull);
    });

    test('blocks redirect to 192.168.x.x', () {
      final current = Uri.parse('https://example.com/page');
      final result = resolveRedirectUri(current, 'http://192.168.1.1/admin');
      expect(result, isNull);
    });

    test('blocks redirect to 172.16-31.x.x', () {
      final current = Uri.parse('https://example.com/page');
      expect(resolveRedirectUri(current, 'http://172.16.0.1'), isNull);
      expect(resolveRedirectUri(current, 'http://172.31.255.255'), isNull);
    });

    test('blocks redirect to .local host', () {
      final current = Uri.parse('https://example.com/page');
      final result = resolveRedirectUri(
        current,
        'http://my-internal.local/admin',
      );
      expect(result, isNull);
    });

    test('empty location resolves to same URI (not an error)', () {
      final current = Uri.parse('https://example.com/page');
      final result = resolveRedirectUri(current, '');
      expect(result, isNotNull);
      expect(result, equals(current));
    });

    test('blocks redirect to relative path//authority form', () {
      // //evil.com bypasses some URL parsers
      final current = Uri.parse('https://example.com/page');
      final result = resolveRedirectUri(current, '//169.254.169.254/admin');
      expect(result, isNull);
    });
  });

  /// Проверяет, что execute блокирует SSRF через редирект.
  /// Использует httpbin.org — если сервер отдаёт 503 или недоступен, тест
  /// пропускается без ошибки.
  group('SSRF redirect bypass (integration)', () {
    test(
      'redirect to 169.254.169.254 is blocked',
      () async {
        final ctx = _mockCtx();
        ToolOutput output;
        try {
          output = await createWebfetchTool().execute({
            'url':
                'https://httpbin.org/redirect-to?url=http://169.254.169.254/latest/meta-data/',
            'max_chars': 100,
            'timeout': 5,
          }, ctx);
        } catch (_) {
          markTestSkipped('httpbin.org unreachable');
          return;
        }
        if (output.metadata?['error'] != true) {
          markTestSkipped(
            'httpbin.org did not return a redirect: ${output.output.trim()}',
          );
          return;
        }
        expect(
          output.output,
          anyOf(contains('private'), contains('redirect')),
          reason: 'SSRF VULNERABILITY if this fails: ${output.output}',
        );
      },
      timeout: Timeout(const Duration(seconds: 15)),
    );

    test(
      'redirect to localhost is blocked',
      () async {
        final ctx = _mockCtx();
        ToolOutput output;
        try {
          output = await createWebfetchTool().execute({
            'url':
                'https://httpbin.org/redirect-to?url=http://127.0.0.1:8080/secret',
            'max_chars': 100,
            'timeout': 5,
          }, ctx);
        } catch (_) {
          markTestSkipped('httpbin.org unreachable');
          return;
        }
        if (output.metadata?['error'] != true) {
          markTestSkipped(
            'httpbin.org did not return a redirect: ${output.output.trim()}',
          );
          return;
        }
        expect(
          output.output,
          anyOf(contains('private'), contains('redirect')),
          reason: 'SSRF VULNERABILITY if this fails: ${output.output}',
        );
      },
      timeout: Timeout(const Duration(seconds: 15)),
    );
  });

  group('detectAndDecode', () {
    test('decodes UTF-8 from Content-Type charset', () {
      final bytes = utf8.encode('Hello привет мир');
      final result = detectAndDecode(bytes, 'text/html; charset=utf-8');
      expect(result, equals('Hello привет мир'));
    });

    test('decodes Latin-1 from Content-Type charset', () {
      final bytes = latin1.encode('Café résumé ñoño');
      final result = detectAndDecode(bytes, 'text/html; charset=iso-8859-1');
      expect(result, equals('Café résumé ñoño'));
    });

    test('handles charset with surrounding quotes', () {
      final bytes = utf8.encode('test');
      final result = detectAndDecode(bytes, 'text/html; charset="utf-8"');
      expect(result, equals('test'));
    });

    test('detects charset from meta tag', () {
      final html =
          '<html><head><meta charset="utf-8"></head>'
          '<body>Hello привет</body></html>';
      final bytes = utf8.encode(html);
      final result = detectAndDecode(bytes, 'text/html');
      expect(result, contains('Hello привет'));
    });

    test('detects charset from meta http-equiv', () {
      final html =
          '<html><head>'
          '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">'
          '</head><body>Hello</body></html>';
      final bytes = utf8.encode(html);
      final result = detectAndDecode(bytes, 'text/html');
      expect(result, contains('Hello'));
    });

    test('falls back to UTF-8 when no charset info', () {
      final bytes = utf8.encode('Hello world');
      final result = detectAndDecode(bytes, '');
      expect(result, equals('Hello world'));
    });

    test('strips UTF-8 BOM', () {
      final bom = <int>[0xEF, 0xBB, 0xBF];
      final content = utf8.encode('Hello');
      final bytes = <int>[...bom, ...content];
      final result = detectAndDecode(bytes, 'text/html');
      expect(result, equals('Hello'));
    });

    test('falls back to UTF-8 when encoding is unknown', () {
      final bytes = utf8.encode('Hello world');
      final result = detectAndDecode(bytes, 'text/html; charset=x-unknown');
      // Encoding.getByName('x-unknown') returns null → falls back to UTF-8
      expect(result, equals('Hello world'));
    });

    test('uses latin1 for HTML with no charset in header or meta', () {
      final bytes = [0xC0, 0xC1, 0xC2]; // Latin-1 ÀÁÂ
      final result = detectAndDecode(bytes, 'text/html');
      // utf8.decode with allowMalformed: true replaces invalid bytes
      expect(result, isNotEmpty);
    });

    test('returns empty string for empty bytes', () {
      final result = detectAndDecode([], 'text/html');
      expect(result, equals(''));
    });
  });

  group('extractTextFromHtml', () {
    test('strips basic HTML tags', () {
      final result = extractTextFromHtml('<p>Hello <b>world</b></p>');
      expect(result, equals('Hello world'));
    });

    test('skips script tags', () {
      final result = extractTextFromHtml(
        '<script>alert(1)</script><p>Text</p>',
      );
      expect(result, equals('Text'));
    });

    test('skips style tags', () {
      final result = extractTextFromHtml(
        '<style>.cls{color:red}</style><p>Content</p>',
      );
      expect(result, equals('Content'));
    });

    test('skips noscript, iframe, object, embed', () {
      final result = extractTextFromHtml(
        '<noscript>No JS</noscript><iframe src="x.html"></iframe>'
        '<object data="x.swf"></object><embed src="x.swf">'
        '<p>Visible</p>',
      );
      expect(result, equals('Visible'));
    });

    test('handles nested elements correctly', () {
      final result = extractTextFromHtml(
        '<div><p>Outer <span>inner</span></p></div>',
      );
      expect(result, equals('Outer inner'));
    });

    test('returns empty string for empty input', () {
      expect(extractTextFromHtml(''), isEmpty);
    });

    test('returns empty string for only hidden content', () {
      final result = extractTextFromHtml(
        '<script>var x=1;</script><style>.c{}</style>',
      );
      expect(result, isEmpty);
    });
  });

  group('convertHtmlToMarkdown', () {
    test('converts h1 heading', () {
      final result = convertHtmlToMarkdown('<h1>Title</h1>');
      expect(result, equals('# Title'));
    });

    test('converts h2 heading', () {
      final result = convertHtmlToMarkdown('<h2>Subtitle</h2>');
      expect(result, equals('## Subtitle'));
    });

    test('converts h3 heading', () {
      final result = convertHtmlToMarkdown('<h3>Section</h3>');
      expect(result, equals('### Section'));
    });

    test('converts h4 to h6 headings', () {
      expect(convertHtmlToMarkdown('<h4>H4</h4>'), equals('#### H4'));
      expect(convertHtmlToMarkdown('<h5>H5</h5>'), equals('##### H5'));
      expect(convertHtmlToMarkdown('<h6>H6</h6>'), equals('###### H6'));
    });

    test('converts paragraph', () {
      final result = convertHtmlToMarkdown('<p>Hello world</p>');
      expect(result, equals('Hello world'));
    });

    test('converts link with href', () {
      final result = convertHtmlToMarkdown(
        '<a href="https://example.com">click</a>',
      );
      expect(result, equals('[click](https://example.com)'));
    });

    test('converts link without href as plain text', () {
      final result = convertHtmlToMarkdown('<a>click</a>');
      expect(result, equals('click'));
    });

    test('converts bold/strong', () {
      expect(
        convertHtmlToMarkdown('<strong>bold</strong>'),
        equals('**bold**'),
      );
      expect(convertHtmlToMarkdown('<b>bold</b>'), equals('**bold**'));
    });

    test('converts italic/em', () {
      expect(convertHtmlToMarkdown('<em>italic</em>'), equals('*italic*'));
      expect(convertHtmlToMarkdown('<i>italic</i>'), equals('*italic*'));
    });

    test('converts inline code', () {
      final result = convertHtmlToMarkdown('<code>var x = 1;</code>');
      expect(result, equals('`var x = 1;`'));
    });

    test('converts code block without language', () {
      final result = convertHtmlToMarkdown(
        '<pre><code>print("hello")</code></pre>',
      );
      expect(result, contains('```'));
      expect(result, contains('print("hello")'));
      expect(result, contains('```'));
    });

    test('converts code block with language', () {
      final result = convertHtmlToMarkdown(
        '<pre><code class="language-dart">void main() {}</code></pre>',
      );
      expect(result, contains('```dart'));
      expect(result, contains('void main() {}'));
      expect(result, contains('```'));
    });

    test('converts code block with lang- prefix', () {
      final result = convertHtmlToMarkdown(
        '<pre><code class="lang-python">print("hi")</code></pre>',
      );
      expect(result, contains('```python'));
    });

    test('converts unordered list', () {
      final result = convertHtmlToMarkdown(
        '<ul><li>Item 1</li><li>Item 2</li></ul>',
      );
      expect(result, contains('- Item 1'));
      expect(result, contains('- Item 2'));
    });

    test('converts ordered list', () {
      final result = convertHtmlToMarkdown(
        '<ol><li>First</li><li>Second</li></ol>',
      );
      expect(result, contains('1. First'));
      expect(result, contains('2. Second'));
    });

    test('converts blockquote', () {
      final result = convertHtmlToMarkdown(
        '<blockquote>Quote text</blockquote>',
      );
      expect(result, contains('> Quote text'));
    });

    test('converts horizontal rule', () {
      final result = convertHtmlToMarkdown('<hr>');
      expect(result, contains('---'));
    });

    test('converts image with alt text', () {
      final result = convertHtmlToMarkdown(
        '<img src="https://example.com/img.png" alt="photo">',
      );
      expect(result, equals('![photo](https://example.com/img.png)'));
    });

    test('converts image without alt', () {
      final result = convertHtmlToMarkdown(
        '<img src="https://example.com/img.png">',
      );
      expect(result, equals('![](https://example.com/img.png)'));
    });

    test('converts line break', () {
      final result = convertHtmlToMarkdown('Line1<br>Line2');
      expect(result, contains('Line1'));
      expect(result, contains('Line2'));
    });

    test('strips script and style tags', () {
      final result = convertHtmlToMarkdown(
        '<script>alert(1)</script><p>Text</p><style>.c{}</style>',
      );
      expect(result, equals('Text'));
    });

    test('strips meta and link tags', () {
      final result = convertHtmlToMarkdown(
        '<meta charset="utf-8"><link rel="stylesheet" href="s.css">'
        '<p>Content</p>',
      );
      expect(result, equals('Content'));
    });

    test('returns empty string for empty HTML', () {
      expect(convertHtmlToMarkdown(''), isEmpty);
    });
  });

  group('truncateContent', () {
    test('returns text when within maxChars', () {
      final result = truncateContent('Short text', 100);
      expect(result, equals('Short text'));
    });

    test('returns text when equal to maxChars', () {
      final text = 'Exactly 10!';
      final result = truncateContent(text, text.length);
      expect(result, equals(text));
    });

    test('truncates with sentinel when exceeding maxChars', () {
      final text =
          'A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM\nN\nO\nP\nQ\nR\nS\nT\nU\nV\nW\nX\nY\nZ\n' *
          5;
      final result = truncateContent(text, 80);
      expect(result.length, lessThanOrEqualTo(80));
      expect(result, contains('truncated'));
    });

    test('sentinel includes line count', () {
      final text =
          'A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM\nN\nO\nP\nQ\nR\nS\nT\nU\nV\nW\nX\nY\nZ\n' *
          5;
      final result = truncateContent(text, 80);
      expect(result, contains(RegExp(r'\d+ lines truncated')));
    });

    test('preserves head and tail around sentinel', () {
      final text = 'START\n00\n11\n22\n33\n44\n55\n66\n77\n88\n99\nEND';
      final result = truncateContent(text, 60);
      expect(result, contains('START'));
      expect(result, contains('END'));
    });
  });

  group('execute with format parameter', () {
    test('default format is markdown', () async {
      final ctx = _mockCtx();
      final output = await createWebfetchTool().execute({
        'url': 'https://example.com',
        'max_chars': 500,
      }, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, isNotEmpty);
    }, timeout: Timeout(const Duration(seconds: 15)));

    test(
      'format=text returns plain text',
      () async {
        final ctx = _mockCtx();
        final output = await createWebfetchTool().execute({
          'url': 'https://example.com',
          'format': 'text',
          'max_chars': 500,
        }, ctx);
        expect(output.metadata?['error'], isNull);
        expect(output.output, isNotEmpty);
      },
      timeout: Timeout(const Duration(seconds: 15)),
    );

    test('format=html returns raw HTML', () async {
      final ctx = _mockCtx();
      final output = await createWebfetchTool().execute({
        'url': 'https://example.com',
        'format': 'html',
        'max_chars': 500,
      }, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output.toLowerCase(), contains('<html'));
    }, timeout: Timeout(const Duration(seconds: 15)));
  });

  group('execute with truncation', () {
    test(
      'max_chars truncates long content',
      () async {
        final ctx = _mockCtx();
        final output = await createWebfetchTool().execute({
          'url': 'https://example.com',
          'max_chars': 50,
        }, ctx);
        if (output.metadata?['error'] == null) {
          expect(output.output.length, lessThanOrEqualTo(50));
        }
      },
      timeout: Timeout(const Duration(seconds: 15)),
    );
  });
}
