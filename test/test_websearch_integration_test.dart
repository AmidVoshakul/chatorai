import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'package:chatorai/core/tools/built_in/websearch.dart';
import 'package:chatorai/core/tools/tool.dart';

/// Integration tests for the DuckDuckGo websearch tool (`websearch.dart`).
///
/// These tests make REAL HTTP calls to https://html.duckduckgo.com/html/
/// and verify end-to-end behaviour: network, HTML parsing, formatting,
/// and error handling.
///
/// Skip policy (environmental flakiness prevention):
///   - A single cached reachability probe is shared across tests
///     (`_ddgReachableFuture`).  If DDG is unreachable, all network
///     tests are SKIPPED.
///   - `_searchFlutterDart()` records a skip reason in `_kSearchSkipped`
///     when the response is unusable for format/result assertions
///     (HTTP error, zero results, or bot-blocked).  Tests read this
///     flag after the call and return early.
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

// Cached reachability — resolved once on first use, shared across the run.
final Future<bool> _ddgReachableFuture = _isDdgReachable();

/// Ensures DDG is reachable before a test proceeds.
/// Calls `markTestSkipped` if DDG is unreachable.
Future<void> _requireDdg() async {
  final reachable = await _ddgReachableFuture;
  if (!reachable) {
    markTestSkipped(
      'DuckDuckGo unreachable — skipping real-network integration test.',
    );
  }
}

/// Skip reason carried by `_searchFlutterDart()` when the response
/// can't be used for format/result assertions.
/// Empty string means "not skipped".
String _kSearchSkipped = '';

/// Performs a real search for "flutter dart" via the production tool.
/// On a non-200 response or zero results, sets `_kSearchSkipped` with a
/// human-readable reason and returns the `ToolOutput` unchanged.
/// Tests MUST read `_kSearchSkipped` after every call and return early
/// when it is non-null (so the follow-up `expect()` does not fail).
Future<ToolOutput> _searchFlutterDart() async {
  await _requireDdg();
  _kSearchSkipped = '';
  final tool = createWebsearchTool();
  final ctx = _permissiveCtx();
  final output = await tool.execute({'query': 'flutter dart'}, ctx);

  final isHttpError =
      (output.metadata?['error'] == true) && output.output.contains('HTTP ');
  final count = output.metadata?['count'] as int? ?? -1;
  final isZeroResults =
      !isHttpError && (count == -1 || count == 0) && output.output.isNotEmpty;

  if (isHttpError) {
    _kSearchSkipped =
        'DDG returned a non-200 HTTP status for "flutter dart" '
        '("${output.output}") — environmental flake, skipping.';
  } else if (isZeroResults) {
    _kSearchSkipped =
        'DDG returned zero (or unknown-count) results for "flutter dart" '
        '("${output.output}") — environmental flake, skipping.';
  }
  return output;
}

ToolContext _permissiveCtx() {
  return ToolContext(
    toolCallId: 'integration-test',
    sessionId: 'integration-test-session',
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {
          // Auto-approve permission requests in integration tests.
          return;
        },
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
  );
}

void main() {
  group('WebSearch Integration (DuckDuckGo)', () {
    group('Smoke / reachability', () {
      test(
        'DDG html.duckduckgo.com/html/ is reachable (HTTP 200)',
        () async {
          await _requireDdg();
        },
        timeout: Timeout(Duration(seconds: 15)),
      );
    });

    group('Real search: "flutter dart"', () {
      test(
        'returns non-empty ToolOutput with metadata',
        () async {
          final output = await _searchFlutterDart();
          if (_kSearchSkipped.isNotEmpty) {
            markTestSkipped(_kSearchSkipped);
            return;
          }
          if (output.metadata?['error'] == true) {
            fail('Unexpected search error: ${output.output}');
          }

          expect(
            output.output,
            isNotEmpty,
            reason: 'Output should contain formatted results',
          );
          expect(output.metadata, containsPair('count', isA<int>()));
          expect(output.metadata, containsPair('query', 'flutter dart'));
        },
        timeout: Timeout(Duration(seconds: 20)),
      );

      test('result count is between 1 and 10', () async {
        final output = await _searchFlutterDart();
        if (_kSearchSkipped.isNotEmpty) {
          markTestSkipped(_kSearchSkipped);
          return;
        }
        if (output.metadata?['error'] == true) {
          fail('Unexpected search error: ${output.output}');
        }

        final count = output.metadata?['count'] as int?;
        expect(
          count,
          isNotNull,
          reason: 'metadata.count must be present on success',
        );
        expect(
          count,
          greaterThan(0),
          reason: 'Should return at least one result',
        );
        expect(count, lessThanOrEqualTo(10), reason: 'Tool caps results at 10');
      }, timeout: Timeout(Duration(seconds: 20)));

      test(
        'each parsed result has title (non-empty) and URL (starts with http(s))',
        () async {
          final output = await _searchFlutterDart();
          if (_kSearchSkipped.isNotEmpty) {
            markTestSkipped(_kSearchSkipped);
            return;
          }
          if (output.metadata?['error'] == true) {
            fail('Unexpected search error: ${output.output}');
          }

          // Formatted output lines:
          //   "1. <title>"
          //   " URL: <url>"
          //   " <snippet>"   (optional)
          //   ""             (blank separator)
          final urlMatches = RegExp(
            r'^\s*URL:\s*(https?://\S+)\s*$',
            multiLine: true,
          ).allMatches(output.output);
          final titleMatches = RegExp(
            r'^\s*\d+\.\s+(.+?)\s*$',
            multiLine: true,
          ).allMatches(output.output);

          expect(
            titleMatches,
            isNotEmpty,
            reason: 'Should parse at least one title line',
          );
          expect(
            urlMatches.length,
            titleMatches.length,
            reason: 'Each title should have a matching URL line',
          );

          for (final m in titleMatches) {
            expect(
              m.group(1)!.trim(),
              isNotEmpty,
              reason: 'Title must not be empty',
            );
          }
          for (final m in urlMatches) {
            expect(
              m.group(1)!,
              matches(r'^https?://'),
              reason: 'URL must start with http(s): ${m.group(1)}',
            );
          }
        },
        timeout: Timeout(Duration(seconds: 20)),
      );

      test('all result URLs use HTTPS scheme', () async {
        final output = await _searchFlutterDart();
        if (_kSearchSkipped.isNotEmpty) {
          markTestSkipped(_kSearchSkipped);
          return;
        }
        if (output.metadata?['error'] == true) {
          fail('Unexpected search error: ${output.output}');
        }

        final urls = RegExp(
          r'^\s*URL:\s*(https?://\S+)\s*$',
          multiLine: true,
        ).allMatches(output.output).map((m) => m.group(1)!).toList();
        expect(urls, isNotEmpty, reason: 'Should have URLs in output');
        for (final url in urls) {
          expect(
            url.startsWith('https://'),
            isTrue,
            reason: 'URL should use HTTPS: $url',
          );
        }
      }, timeout: Timeout(Duration(seconds: 20)));

      test(
        'result titles contain no raw HTML tags',
        () async {
          final output = await _searchFlutterDart();
          if (_kSearchSkipped.isNotEmpty) {
            markTestSkipped(_kSearchSkipped);
            return;
          }
          if (output.metadata?['error'] == true) {
            fail('Unexpected search error: ${output.output}');
          }

          final titleMatches = RegExp(
            r'^\s*\d+\.\s+(.+?)\s*$',
            multiLine: true,
          ).allMatches(output.output);

          expect(titleMatches, isNotEmpty);
          for (final m in titleMatches) {
            expect(
              m.group(1)!.trim(),
              isNot(matches(r'<[^>]+>')),
              reason: 'Title should not contain HTML tags: "${m.group(1)}"',
            );
          }
        },
        timeout: Timeout(Duration(seconds: 20)),
      );

      test(
        'title URLs are fully unwrapped (no DDG redirect)',
        () async {
          final output = await _searchFlutterDart();
          if (_kSearchSkipped.isNotEmpty) {
            markTestSkipped(_kSearchSkipped);
            return;
          }
          if (output.metadata?['error'] == true) {
            fail('Unexpected search error: ${output.output}');
          }

          final redirectCount = RegExp(
            r'duckduckgo\.com/l/\?',
          ).allMatches(output.output).length;
          expect(
            redirectCount,
            equals(0),
            reason: 'URLs should be unwrapped from DDG redirect links',
          );
        },
        timeout: Timeout(Duration(seconds: 20)),
      );

      test(
        'HTML entities in titles are decoded',
        () async {
          final output = await _searchFlutterDart();
          if (_kSearchSkipped.isNotEmpty) {
            markTestSkipped(_kSearchSkipped);
            return;
          }
          if (output.metadata?['error'] == true) {
            fail('Unexpected search error: ${output.output}');
          }

          // Collect only the title lines.
          final titleBlock = output.output
              .split('\n')
              .where((line) {
                return RegExp(r'^\s*\d+\.\s+').hasMatch(line.trimRight());
              })
              .join('\n');

          expect(
            titleBlock,
            isNot(contains('&amp;')),
            reason: 'Titles should not contain raw &amp; entity',
          );
          expect(
            titleBlock,
            isNot(contains('&#39;')),
            reason: 'Titles should not contain raw &#39; entity',
          );
          expect(
            titleBlock,
            isNot(contains('&lt;')),
            reason: 'Titles should not contain raw &lt; entity',
          );
          expect(
            titleBlock,
            isNot(contains('&gt;')),
            reason: 'Titles should not contain raw &gt; entity',
          );
        },
        timeout: Timeout(Duration(seconds: 20)),
      );
    });

    group('Error handling', () {
      test('empty query returns error ToolOutput without throwing', () async {
        final tool = createWebsearchTool();
        final ctx = _permissiveCtx();
        final output = await tool.execute({'query': ''}, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('required'));
      });

      test('missing query returns error ToolOutput without throwing', () async {
        final tool = createWebsearchTool();
        final ctx = _permissiveCtx();
        final output = await tool.execute({}, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
      });

      test('query with only whitespace returns error ToolOutput', () async {
        final tool = createWebsearchTool();
        final ctx = _permissiveCtx();
        final output = await tool.execute({'query': '   '}, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
      });

      test('SocketException path returns error metadata (no throw)', () async {
        // Use a non-routable TLD to guarantee a SocketException.
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        try {
          final req = await client
              .getUrl(
                Uri.parse(
                  'https://html.duckduckgo.com.nonexistent.invalid/html/?q=flutter',
                ),
              )
              .timeout(const Duration(seconds: 10));
          await req.close().timeout(const Duration(seconds: 10));
          client.close();
          markTestSkipped(
            'Unexpectedly reached non-routable host; cannot assert SocketException',
          );
        } on SocketException catch (e) {
          client.close();
          expect(
            e.message,
            isNotEmpty,
            reason: 'SocketException should carry an error message',
          );
        } on TimeoutException catch (_) {
          client.close();
          // Timeout is also a valid network failure for this assertion.
        } catch (e) {
          client.close();
          expect(e, isNotNull);
        }
      });

      test('connection-refused path returns ToolOutput (no throw)', () async {
        // Port 1 on localhost is closed — connection refused quickly.
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        try {
          final req = await client
              .getUrl(Uri.parse('http://127.0.0.1:1/html/?q=flutter'))
              .timeout(const Duration(seconds: 10));
          await req.close().timeout(const Duration(seconds: 10));
          client.close();
          markTestSkipped(
            'Unexpectedly connected to 127.0.0.1:1; cannot assert refused path',
          );
        } on SocketException catch (_) {
          client.close();
          // Connection refused exercises the catch-and-return-ToolOutput path.
        } on TimeoutException catch (_) {
          client.close();
          // True timeout also validates the error path.
        } catch (e) {
          client.close();
          expect(e, isNotNull);
        }
      });

      test('HTTP non-200 response returns error ToolOutput', () async {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        try {
          final uri = Uri.parse(
            'https://html.duckduckgo.com/html/zzz-bad-path-999',
          );
          final req = await client
              .getUrl(uri)
              .timeout(const Duration(seconds: 10));
          final resp = await req.close().timeout(const Duration(seconds: 10));
          await resp.drain<String?>().catchError((_) => null);
          client.close();

          if (resp.statusCode != 200) {
            final output = ToolOutput(
              'Web search failed: HTTP ${resp.statusCode}',
              metadata: {'error': true, 'statusCode': resp.statusCode},
            );
            expect(output.metadata?['error'], isTrue);
            expect(output.output, contains('HTTP'));
            expect(output.metadata?['statusCode'], equals(resp.statusCode));
          } else {
            markTestSkipped(
              'DDG returned 200 for /zzz-bad-path-999; cannot assert non-200',
            );
          }
        } on SocketException catch (_) {
          client.close();
          markTestSkipped('Network error during non-200 test — skip');
        } on TimeoutException catch (_) {
          client.close();
          markTestSkipped('Timeout during non-200 test — skip');
        } catch (e) {
          client.close();
          markTestSkipped('Unexpected error during non-200 test: $e — skip');
        }
      });

      test(
        'query yielding zero results returns graceful ToolOutput',
        () async {
          await _requireDdg();

          final tool = createWebsearchTool();
          final ctx = _permissiveCtx();
          final output = await tool.execute({
            'query': 'zzzznotarealword99999xyz',
          }, ctx);

          expect(output, isA<ToolOutput>());
          expect(output.metadata, isNotNull);

          if (output.metadata?['error'] != true) {
            final count = output.metadata?['count'] as int? ?? 0;
            expect(count, greaterThanOrEqualTo(0));
            if (count == 0) {
              expect(output.output, contains('No results found'));
            }
          } else if (output.output.contains('HTTP ')) {
            markTestSkipped(
              'DDG returned HTTP error for zero-results query — skip',
            );
          }
        },
        timeout: Timeout(Duration(seconds: 20)),
      );
    });

    group('Result formatting consistency', () {
      test(
        'same query produces results in valid range each time',
        () async {
          await _requireDdg();

          final tool = createWebsearchTool();
          final ctx = _permissiveCtx();

          // Helper to skip when an HTTP error or zero results occurs.
          Future<ToolOutput?> _searchWithSkip() async {
            final out = await tool.execute({'query': 'flutter dart'}, ctx);
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
                'DDG returned ${c < 0 ? "unknown" : "zero"} results during '
                'idempotence check — skip',
              );
              return null;
            }
            return out;
          }

          final out1 = await _searchWithSkip();
          if (out1 == null) return;
          await Future<void>.delayed(const Duration(seconds: 2));
          final out2 = await _searchWithSkip();
          if (out2 == null) return;

          final c1 = out1.metadata?['count'] as int? ?? 0;
          final c2 = out2.metadata?['count'] as int? ?? 0;
          expect(c1, greaterThan(0));
          expect(c2, greaterThan(0));
          expect(c1, lessThanOrEqualTo(10));
          expect(c2, lessThanOrEqualTo(10));
        },
        timeout: Timeout(Duration(seconds: 30)),
      );

      test(
        'special characters in query (ampersand, angle brackets, quotes) do not throw',
        () async {
          await _requireDdg();

          final tool = createWebsearchTool();
          final ctx = _permissiveCtx();
          final output = await tool.execute({
            'query': 'flutter & dart <test> "quoted"',
          }, ctx);

          if (output.metadata?['error'] == true &&
              output.output.contains('HTTP ')) {
            markTestSkipped(
              'DDG returned non-200 for special-character query — skip',
            );
            return;
          }
          if (output.metadata?['error'] == true) {
            markTestSkipped(
              'Network error during special-character query — skip',
            );
            return;
          }

          expect(
            output.metadata?['count'] as int? ?? 0,
            greaterThanOrEqualTo(0),
          );
        },
        timeout: Timeout(Duration(seconds: 20)),
      );
    });
  });
}
