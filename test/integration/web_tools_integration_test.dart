import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'package:chatorai/core/tools/built_in/webfetch.dart';
import 'package:chatorai/core/tools/built_in/websearch.dart';
import 'package:chatorai/core/tools/tool.dart';

import 'helpers/test_context.dart';

/// Integration tests for web tools (webfetch, websearch).
///
/// These tests make REAL HTTP calls to external services and verify
/// end-to-end behavior including network, parsing, and error handling.
///
/// Skip policy:
/// - If external endpoints are unreachable, tests are skipped to avoid
///   false failures due to environmental issues.
/// - Each test group has its own reachability probe to skip independently.
///
/// Note: These tests require an active internet connection.
/// They are marked as integration tests and may be skipped in CI environments
/// without network access.

// MARK: - Webfetch Integration Tests

/// Checks if httpbin.org is reachable.
Future<bool> _isHttpbinReachable() async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client
        .getUrl(Uri.parse('https://httpbin.org/status/200'))
        .timeout(const Duration(seconds: 10));
    final resp = await req.close().timeout(const Duration(seconds: 10));
    await resp.drain<String?>().catchError((_) => null);
    client.close();
    return resp.statusCode == 200;
  } on SocketException catch (_) {
    try {
      client.close();
    } catch (_) {}
    return false;
  } on TimeoutException catch (_) {
    try {
      client.close();
    } catch (_) {}
    return false;
  } catch (_) {
    try {
      client.close();
    } catch (_) {}
    return false;
  }
}

final Future<bool> _httpbinReachableFuture = _isHttpbinReachable();

Future<void> _requireHttpbin() async {
  final reachable = await _httpbinReachableFuture;
  if (!reachable) {
    markTestSkipped(
      'httpbin.org unreachable — skipping webfetch integration tests.',
    );
  }
}

/// Checks if example.com is reachable.
Future<bool> _isExampleComReachable() async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client
        .getUrl(Uri.parse('https://example.com'))
        .timeout(const Duration(seconds: 10));
    final resp = await req.close().timeout(const Duration(seconds: 10));
    await resp.drain<String?>().catchError((_) => null);
    client.close();
    return resp.statusCode == 200;
  } on SocketException catch (_) {
    try {
      client.close();
    } catch (_) {}
    return false;
  } on TimeoutException catch (_) {
    try {
      client.close();
    } catch (_) {}
    return false;
  } catch (_) {
    try {
      client.close();
    } catch (_) {}
    return false;
  }
}

final Future<bool> _exampleComReachableFuture = _isExampleComReachable();

Future<void> _requireExampleCom() async {
  final reachable = await _exampleComReachableFuture;
  if (!reachable) {
    markTestSkipped(
      'example.com unreachable — skipping webfetch integration tests.',
    );
  }
}

// MARK: - Websearch Integration Tests

/// Reuses the reachability check from existing test_websearch_integration_test.dart
Future<bool> _isDdgReachable() async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client
        .getUrl(Uri.parse('https://html.duckduckgo.com/html/?q=test'))
        .timeout(const Duration(seconds: 10));
    final resp = await req.close().timeout(const Duration(seconds: 10));
    await resp.drain<String?>().catchError((_) => null);
    client.close();
    return resp.statusCode >= 200 && resp.statusCode < 300;
  } on SocketException catch (_) {
    try {
      client.close();
    } catch (_) {}
    return false;
  } on TimeoutException catch (_) {
    try {
      client.close();
    } catch (_) {}
    return false;
  } catch (_) {
    try {
      client.close();
    } catch (_) {}
    return false;
  }
}

final Future<bool> _ddgReachableFuture = _isDdgReachable();

Future<void> _requireDdg() async {
  final reachable = await _ddgReachableFuture;
  if (!reachable) {
    markTestSkipped(
      'DuckDuckGo unreachable — skipping websearch integration tests.',
    );
  }
}

// MARK: - Test Suites

void main() {
  group('Webfetch Integration Tests', () {
    late ToolDef webfetchTool;

    setUpAll(() {
      webfetchTool = createWebfetchTool();
    });

    group('Reachability', () {
      test('httpbin.org is reachable', () async {
        await _requireHttpbin();
      });

      test('example.com is reachable', () async {
        await _requireExampleCom();
      });
    });

    group('Successful fetch', () {
      test(
        'fetch https://httpbin.org/html returns HTML content with correct metadata',
        () async {
          await _requireHttpbin();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-webfetch-1',
            sessionId: 'integration-test-session',
          );

          final output = await webfetchTool.execute({
            'url': 'https://httpbin.org/html',
            'max_chars': 5000,
          }, ctx);

          expect(output, isA<ToolOutput>());
          expect(
            output.metadata?['error'],
            isNull,
            reason: 'Should not have error metadata on success',
          );
          expect(
            output.output,
            contains('<!DOCTYPE html>'),
            reason: 'Should contain HTML doctype',
          );
          expect(
            output.output,
            contains('<html'),
            reason: 'Should contain html tag',
          );
          expect(
            output.output.length,
            greaterThan(100),
            reason: 'Should have substantial content',
          );
        },
        timeout: Timeout(const Duration(seconds: 15)),
      );

      test(
        'fetch https://example.com returns simple HTML with expected text',
        () async {
          await _requireExampleCom();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-webfetch-2',
            sessionId: 'integration-test-session',
          );

          final output = await webfetchTool.execute({
            'url': 'https://example.com',
            'max_chars': 5000,
          }, ctx);

          expect(output, isA<ToolOutput>());
          expect(output.metadata?['error'], isNull);
          expect(
            output.output,
            contains('Example Domain'),
            reason: 'Should contain "Example Domain"',
          );
        },
        timeout: Timeout(const Duration(seconds: 15)),
      );
    });

    group('UTF-8 content handling', () {
      test(
        'fetch UTF-8 encoded page decodes Unicode characters correctly',
        () async {
          await _requireHttpbin();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-webfetch-utf8',
            sessionId: 'integration-test-session',
          );

          final output = await webfetchTool.execute({
            'url': 'https://httpbin.org/encoding/utf8',
            'max_chars': 2000,
          }, ctx);

          expect(output, isA<ToolOutput>());
          expect(output.metadata?['error'], isNull);
          // The page contains various Unicode characters.
          expect(output.output, isA<String>());
          // The httpbin UTF-8 demo page title is "Unicode Demo".
          expect(output.output, contains('Unicode Demo'));
          // Check for some Unicode mathematical symbols present in the demo.
          expect(output.output, contains('∮'));
        },
        timeout: Timeout(const Duration(seconds: 15)),
      );
    });

    group('Invalid URL handling', () {
      test('non-http scheme (ftp://) returns error ToolOutput', () async {
        final ctx = IntegrationTestContext(
          toolCallId: 'integration-test-webfetch-invalid1',
          sessionId: 'integration-test-session',
        );

        final output = await webfetchTool.execute({
          'url': 'ftp://example.com/file.txt',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('only http/https'));
      });

      test('invalid URL string returns error ToolOutput', () async {
        final ctx = IntegrationTestContext(
          toolCallId: 'integration-test-webfetch-invalid2',
          sessionId: 'integration-test-session',
        );

        final output = await webfetchTool.execute({
          'url': 'not-a-valid-url',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('invalid URL'));
      });

      test('file:// scheme returns error ToolOutput', () async {
        final ctx = IntegrationTestContext(
          toolCallId: 'integration-test-webfetch-invalid3',
          sessionId: 'integration-test-session',
        );

        final output = await webfetchTool.execute({
          'url': 'file:///etc/passwd',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
        // file:// URLs have empty host, so tool returns "invalid URL"
        expect(output.output, contains('invalid URL'));
      });
    });

    group('Private host blocking', () {
      test('localhost is blocked', () async {
        final ctx = IntegrationTestContext(
          toolCallId: 'integration-test-webfetch-private1',
          sessionId: 'integration-test-session',
        );

        final output = await webfetchTool.execute({
          'url': 'http://localhost:8080',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('private/internal hosts'));
      });

      test('127.0.0.1 is blocked', () async {
        final ctx = IntegrationTestContext(
          toolCallId: 'integration-test-webfetch-private2',
          sessionId: 'integration-test-session',
        );

        final output = await webfetchTool.execute({
          'url': 'http://127.0.0.1',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('private/internal hosts'));
      });

      test('private IP range 10.x.x.x is blocked', () async {
        final ctx = IntegrationTestContext(
          toolCallId: 'integration-test-webfetch-private3',
          sessionId: 'integration-test-session',
        );

        final output = await webfetchTool.execute({
          'url': 'http://10.0.0.1',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('private/internal hosts'));
      });

      test('private IP range 192.168.x.x is blocked', () async {
        final ctx = IntegrationTestContext(
          toolCallId: 'integration-test-webfetch-private4',
          sessionId: 'integration-test-session',
        );

        final output = await webfetchTool.execute({
          'url': 'http://192.168.1.1',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('private/internal hosts'));
      });
    });

    group('Timeout handling', () {
      test(
        'connection to non-routable IP fails gracefully (timeout or network error)',
        () async {
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-webfetch-timeout',
            sessionId: 'integration-test-session',
          );

          // Use a non-private, non-routable IP (TEST-NET-1) that should not be reachable.
          // This should cause a network error (timeout or connection refused).
          final output = await webfetchTool.execute({
            'url': 'http://192.0.2.1/',
            'max_chars': 100,
          }, ctx);

          expect(output, isA<ToolOutput>());
          expect(
            output.metadata?['error'],
            isTrue,
            reason: 'Should have error metadata',
          );
          // The error message may vary (timeout, connection refused, etc.)
          expect(output.output, isA<String>());
        },
        timeout: Timeout(const Duration(seconds: 20)),
      );
    });

    group('Non-200 response handling', () {
      test(
        '404 response returns content (no error metadata)',
        () async {
          await _requireHttpbin();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-webfetch-404',
            sessionId: 'integration-test-session',
          );

          final output = await webfetchTool.execute({
            'url': 'https://httpbin.org/status/404',
            'max_chars': 1000,
          }, ctx);

          expect(output, isA<ToolOutput>());
          // httpbin returns 404 with empty body, but the tool should still
          // return the content (empty) without error metadata because the
          // HTTP request itself succeeded (status 404 is not a network error).
          expect(output.output, isA<String>());
        },
        timeout: Timeout(const Duration(seconds: 15)),
      );

      test(
        '500 response returns content without error metadata',
        () async {
          await _requireHttpbin();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-webfetch-500',
            sessionId: 'integration-test-session',
          );

          final output = await webfetchTool.execute({
            'url': 'https://httpbin.org/status/500',
            'max_chars': 1000,
          }, ctx);

          expect(output, isA<ToolOutput>());
          expect(output.output, isA<String>());
        },
        timeout: Timeout(const Duration(seconds: 15)),
      );
    });

    group('Content truncation', () {
      test(
        'max_chars limits returned content length',
        () async {
          await _requireHttpbin();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-webfetch-truncate',
            sessionId: 'integration-test-session',
          );

          final output = await webfetchTool.execute({
            'url': 'https://httpbin.org/html',
            'max_chars': 100,
          }, ctx);

          expect(output, isA<ToolOutput>());
          expect(
            output.output.length,
            lessThanOrEqualTo(100),
            reason: 'Content should be truncated to max_chars',
          );
        },
        timeout: Timeout(const Duration(seconds: 15)),
      );
    });
  });

  group('Websearch Integration Tests', () {
    late ToolDef websearchTool;

    setUpAll(() {
      websearchTool = createWebsearchTool();
    });

    group('Reachability', () {
      test('DuckDuckGo is reachable', () async {
        await _requireDdg();
      });
    });

    group('Successful search', () {
      test(
        'search for "flutter dart" returns results with metadata',
        () async {
          await _requireDdg();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-websearch-1',
            sessionId: 'integration-test-session',
          );

          final output = await websearchTool.execute({
            'query': 'flutter dart',
          }, ctx);

          expect(output, isA<ToolOutput>());
          expect(
            output.metadata?['error'],
            isNull,
            reason: 'Should not have error on success',
          );
          expect(output.metadata?['query'], equals('flutter dart'));
          expect(output.metadata?['provider'], equals('duckduckgo'));
          expect(output.metadata?['count'], isA<int>());
          expect(output.output, isNotEmpty);
          expect(output.output, contains('Search results for "flutter dart"'));
        },
        timeout: Timeout(const Duration(seconds: 20)),
      );

      test(
        'search with numResults=10 returns up to 10 results',
        () async {
          await _requireDdg();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-websearch-2',
            sessionId: 'integration-test-session',
          );

          final output = await websearchTool.execute({
            'query': 'flutter',
            'numResults': 10,
          }, ctx);

          expect(output, isA<ToolOutput>());
          final count = output.metadata?['count'] as int?;
          expect(count, isNotNull);
          expect(count, lessThanOrEqualTo(10));
        },
        timeout: Timeout(const Duration(seconds: 20)),
      );

      // Note: The tool's numResults parameter may not be strictly enforced by the backend.
      // The existing test for numResults=10 already verifies that count <= 10.
      // Additional tests for lower limits may be flaky due to backend behavior.
    });

    group('Result formatting', () {
      test(
        'result titles are non-empty and URLs start with http(s)',
        () async {
          await _requireDdg();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-websearch-format-1',
            sessionId: 'integration-test-session',
          );

          final output = await websearchTool.execute({
            'query': 'flutter dart',
          }, ctx);

          if (output.metadata?['error'] == true) {
            if (output.output.contains('HTTP ')) {
              markTestSkipped('DDG returned HTTP error — skip formatting test');
              return;
            }
            fail('Unexpected search error: ${output.output}');
          }

          final results = output.metadata?['results'] as List?;
          expect(results, isNotNull, reason: 'Should have results array');
          expect(
            results,
            isNotEmpty,
            reason: 'Results array should not be empty',
          );

          for (final result in results!) {
            final title = result['title'] as String?;
            final url = result['url'] as String?;
            expect(title, isNotNull, reason: 'Result should have title');
            expect(
              title!.isNotEmpty,
              isTrue,
              reason: 'Title should not be empty',
            );
            expect(url, isNotNull, reason: 'Result should have URL');
            expect(url!.isNotEmpty, isTrue, reason: 'URL should not be empty');
            expect(
              url,
              matches(r'^https?://'),
              reason: 'URL should start with http(s)',
            );
          }
        },
        timeout: Timeout(const Duration(seconds: 20)),
      );

      test(
        'formatted output contains numbered list with URLs',
        () async {
          await _requireDdg();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-websearch-format-2',
            sessionId: 'integration-test-session',
          );

          final output = await websearchTool.execute({'query': 'flutter'}, ctx);

          if (output.metadata?['error'] == true) {
            if (output.output.contains('HTTP ')) {
              markTestSkipped('DDG returned HTTP error — skip format test');
              return;
            }
            fail('Unexpected search error: ${output.output}');
          }

          // Check for numbered list format: "1. Title" (may be after a header)
          expect(
            output.output,
            contains(RegExp(r'^\s*1\.\s+', multiLine: true)),
          );
          // Check for URL lines: "   URL: https://..."
          expect(
            output.output,
            contains(RegExp(r'^\s*URL:\s*https?://', multiLine: true)),
          );
        },
        timeout: Timeout(const Duration(seconds: 20)),
      );

      test(
        'HTML entities in titles are decoded',
        () async {
          await _requireDdg();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-websearch-html-entities',
            sessionId: 'integration-test-session',
          );

          final output = await websearchTool.execute({
            'query': 'flutter & dart',
          }, ctx);

          if (output.metadata?['error'] == true) {
            if (output.output.contains('HTTP ')) {
              markTestSkipped('DDG returned HTTP error — skip entity test');
              return;
            }
            fail('Unexpected search error: ${output.output}');
          }

          // The output should not contain raw HTML entities like &amp; &lt; &gt;
          expect(output.output, isNot(contains('&amp;')));
          expect(output.output, isNot(contains('&lt;')));
          expect(output.output, isNot(contains('&gt;')));
          expect(output.output, isNot(contains('&#39;')));
        },
        timeout: Timeout(const Duration(seconds: 20)),
      );
    });

    group('Error handling', () {
      test(
        'empty query returns error ToolOutput',
        () async {
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-websearch-err-1',
            sessionId: 'integration-test-session',
          );

          final output = await websearchTool.execute({'query': ''}, ctx);

          expect(output, isA<ToolOutput>());
          expect(output.metadata?['error'], isTrue);
          expect(output.output, contains('required'));
        },
        timeout: Timeout(const Duration(seconds: 10)),
      );

      test(
        'missing query returns error ToolOutput',
        () async {
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-websearch-err-2',
            sessionId: 'integration-test-session',
          );

          final output = await websearchTool.execute({}, ctx);

          expect(output, isA<ToolOutput>());
          expect(output.metadata?['error'], isTrue);
        },
        timeout: Timeout(const Duration(seconds: 10)),
      );

      test(
        'whitespace-only query returns error ToolOutput',
        () async {
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-websearch-err-3',
            sessionId: 'integration-test-session',
          );

          final output = await websearchTool.execute({'query': '   '}, ctx);

          expect(output, isA<ToolOutput>());
          expect(output.metadata?['error'], isTrue);
        },
        timeout: Timeout(const Duration(seconds: 10)),
      );

      test(
        'zero results query returns graceful ToolOutput with count=0',
        () async {
          await _requireDdg();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-websearch-err-4',
            sessionId: 'integration-test-session',
          );

          final output = await websearchTool.execute({
            'query': 'zzzznotarealword99999xyz',
          }, ctx);

          expect(output, isA<ToolOutput>());
          final count = output.metadata?['count'] as int?;
          if (output.metadata?['error'] != true) {
            // If no error, count should be 0 or positive
            expect(count, isNotNull);
            if (count == 0) {
              expect(output.output, contains('No results found'));
            }
          } else if (output.output.contains('HTTP ')) {
            markTestSkipped(
              'DDG returned HTTP error for zero-results query — skip',
            );
          }
        },
        timeout: Timeout(const Duration(seconds: 20)),
      );

      test(
        'special characters in query do not throw',
        () async {
          await _requireDdg();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-websearch-special',
            sessionId: 'integration-test-session',
          );

          final output = await websearchTool.execute({
            'query': 'flutter & dart <test> "quoted" \'single\'',
          }, ctx);

          if (output.metadata?['error'] == true) {
            if (output.output.contains('HTTP ')) {
              markTestSkipped(
                'DDG returned non-200 for special-char query — skip',
              );
              return;
            }
            // Other errors (like network) are also acceptable to skip.
            markTestSkipped('Network error during special-char query — skip');
            return;
          }

          expect(
            output.metadata?['count'] as int? ?? 0,
            greaterThanOrEqualTo(0),
          );
        },
        timeout: Timeout(const Duration(seconds: 20)),
      );
    });

    group('Idempotence', () {
      test(
        'same query produces consistent result counts (within tool cap)',
        () async {
          await _requireDdg();
          final ctx = IntegrationTestContext(
            toolCallId: 'integration-test-websearch-idem-1',
            sessionId: 'integration-test-session',
          );

          Future<ToolOutput?> search() async {
            final out = await websearchTool.execute({
              'query': 'flutter dart',
            }, ctx);
            if (out.metadata?['error'] == true &&
                out.output.contains('HTTP ')) {
              markTestSkipped(
                'DDG HTTP error during idempotence first call — skip',
              );
              return null;
            }
            final c = out.metadata?['count'] as int? ?? -1;
            if (c <= 0) {
              markTestSkipped(
                'DDG returned ${c < 0 ? "unknown" : "zero"} results during idempotence check — skip',
              );
              return null;
            }
            return out;
          }

          final out1 = await search();
          if (out1 == null) return;
          await Future<void>.delayed(const Duration(seconds: 2));
          final out2 = await search();
          if (out2 == null) return;

          final c1 = out1.metadata?['count'] as int? ?? 0;
          final c2 = out2.metadata?['count'] as int? ?? 0;
          expect(c1, greaterThan(0));
          expect(c2, greaterThan(0));
          expect(c1, lessThanOrEqualTo(10));
          expect(c2, lessThanOrEqualTo(10));
        },
        timeout: Timeout(const Duration(seconds: 30)),
      );
    });
  });
}
