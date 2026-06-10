import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DDG search with Dio + Chrome UA', () async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Referer': 'https://html.duckduckgo.com/html/',
        },
        followRedirects: true,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
        responseType: ResponseType.plain,
      ),
    );
    try {
      final response = await dio.get<String>(
        'https://html.duckduckgo.com/html/',
        queryParameters: {'q': 'python 2026'},
      );
      final body = response.data ?? '';
      print('Status: ${response.statusCode}');
      print('Body length: ${body.length}');

      final hasResult = body.contains('class="result"');
      final hasResultA = body.contains('class="result__a"');
      final hasWebResult = body.contains('web-result');
      final hasLinks = body.contains('result__url');
      print('Has class="result": $hasResult');
      print('Has class="result__a": $hasResultA');
      print('Has web-result: $hasWebResult');
      print('Has result__url: $hasLinks');

      // Show all unique class names containing "result"
      final regex = RegExp(r'class="([^"]*result[^"]*)"');
      final matches = regex.allMatches(body).take(20);
      final classes = matches.map((m) => m.group(1)).toSet();
      print('\nClasses with "result": $classes');

      // Find <a> tags
      final aRegex = RegExp(r'<a\s+[^>]*class="([^"]*)"[^>]*href="([^"]*)"');
      final aMatches = aRegex.allMatches(body).take(10);
      print('\n<a> tags:');
      for (final m in aMatches) {
        print('  class="${m.group(1)}" href="${m.group(2)}"');
      }

      // Show snippet of result area
      final bodyIdx = body.indexOf('<body');
      if (bodyIdx >= 0) {
        final bodyContent = body.substring(bodyIdx);
        print('\n=== Body content (first 3000 chars) ===');
        print(
          bodyContent.substring(
            0,
            bodyContent.length > 3000 ? 3000 : bodyContent.length,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      dio.close();
    }
  });
}
