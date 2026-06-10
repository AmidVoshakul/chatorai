import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Bing search via Dart http package', () async {
    final response = await http.get(
      Uri.parse('https://www.bing.com/search?q=python+2026&setlang=en'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    );
    print('Status: ${response.statusCode}');
    print('Body length: ${response.body.length}');

    final hasBAlgo = response.body.contains('class="b_algo"');
    final hasBTitle = response.body.contains('class="b_title"');
    print('Has b_algo: $hasBAlgo');
    print('Has b_title: $hasBTitle');

    if (hasBAlgo) {
      // Parse Bing results
      final regex = RegExp(r'<li class="b_algo"[^>]*>(.*?)</li>', dotAll: true);
      final matches = regex.allMatches(response.body);
      print('Results found: ${matches.length}');
      for (final m in matches.take(3)) {
        final block = m.group(1)!;
        final titleMatch = RegExp(
          r'<h2><a[^>]+href="([^"]+)"[^>]*>(.*?)</a>',
        ).firstMatch(block);
        if (titleMatch != null) {
          final url = titleMatch.group(1)!;
          final title = titleMatch.group(2)!.replaceAll(RegExp(r'<[^>]+>'), '');
          print('  Title: $title');
          print('  URL: $url');
        }
      }
    }

    expect(response.statusCode, 200);
    expect(hasBAlgo, isTrue);
  });
}
