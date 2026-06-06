import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import 'package:chatorai/tools/tool.dart';

class WebSearchTool {
  static const _liteUrl = 'https://lite.duckduckgo.com/lite/';
  static const _userAgent =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  ToolDef get definition => ToolDef(
    id: 'websearch',
    description:
        'Search the web using DuckDuckGo. Returns results with title, URL, and snippet.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'description': 'Search query'},
        'numResults': {
          'type': 'integer',
          'description': 'Max results (default 5, max 10)',
        },
      },
      'required': ['query'],
    },
    execute: (input, ctx) async {
      final query = input['query'] as String?;
      if (query == null || query.isEmpty) {
        return ToolOutput(
          'Error: query is required',
          metadata: {'error': true},
        );
      }

      int numResults;
      try {
        numResults = int.parse(
          input['numResults']?.toString() ?? '5',
        ).clamp(1, 10);
      } catch (_) {
        numResults = 5;
      }

      await ctx.ask(
        permission: 'websearch',
        patterns: [query],
        metadata: {'query': query, 'numResults': numResults},
      );

      try {
        final results = await _search(query, numResults);
        if (results.isEmpty) {
          return ToolOutput(
            'No results found for: $query',
            metadata: {
              'query': query,
              'provider': 'duckduckgo_lite',
              'count': 0,
              'results': <Map<String, dynamic>>[],
            },
          );
        }
        final formatted = results
            .map(
              (r) => 'Title: ${r.title}\nURL: ${r.url}\nSnippet: ${r.snippet}',
            )
            .join('\n---\n\n');
        return ToolOutput(
          'Search results for "$query":\n\n$formatted',
          metadata: {
            'query': query,
            'provider': 'duckduckgo_lite',
            'count': results.length,
            'results': results.map((r) => r.toJson()).toList(),
          },
        );
      } catch (e) {
        return ToolOutput(
          'Search failed: $e',
          metadata: {'error': true, 'query': query},
        );
      }
    },
  );

  Future<List<_SearchResult>> _search(String query, int count) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'User-Agent': _userAgent,
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Referer': _liteUrl,
        },
        followRedirects: true,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );
    try {
      final response = await dio.post(
        _liteUrl,
        data: {'q': query},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final htmlStr = response.data?.toString() ?? '';
      return _parseHtmlResults(htmlStr, count);
    } finally {
      dio.close();
    }
  }

  List<_SearchResult> _parseHtmlResults(String htmlStr, int count) {
    final results = <_SearchResult>[];
    final document = html.parse(htmlStr);

    final links = document.querySelectorAll('a.result-link');
    for (final a in links) {
      if (results.length >= count) break;

      final url = a.attributes['href'] ?? '';
      final title = a.text.trim();
      if (title.isEmpty || url.isEmpty) continue;

      final snippet = () {
        var next = a.parent?.parent?.parent;
        if (next == null) return '';
        var sib = next.nextElementSibling;
        if (sib == null) return '';
        final td = sib.querySelector('.result-snippet');
        return td?.text.trim() ?? '';
      }();

      results.add(
        _SearchResult(
          title: title,
          url: url,
          snippet: snippet.isEmpty ? 'No description available.' : snippet,
        ),
      );
    }

    return results;
  }
}

class _SearchResult {
  final String title, url, snippet;
  _SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
  });
  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'snippet': snippet,
  };
}

ToolDef createWebsearchTool() => WebSearchTool().definition;
