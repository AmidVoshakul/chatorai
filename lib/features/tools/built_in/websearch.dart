import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:ddgs/ddgs.dart';

class WebSearchTool {
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
      LogTags.permission.logInfo('websearch.execute: START');
      final query = input['query'] as String?;
      if (query == null || query.trim().isEmpty) {
        LogTags.network.logWarning('websearch: empty query');
        return ToolOutput(
          'Error: query is required and cannot be empty',
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

      LogTags.network.logInfo(
        'websearch: searching for "$query" (max $numResults)',
      );
      LogTags.permission.logInfo('websearch.execute: About to call ctx.ask');
      await ctx.ask(
        permission: 'websearch',
        patterns: ['websearch:query=$query'],
        metadata: {'query': query, 'numResults': numResults},
      );
      LogTags.permission.logInfo(
        'websearch.execute: ctx.ask returned, permission granted',
      );

      try {
        final client = DDGS(timeout: const Duration(seconds: 10));
        LogTags.network.logInfo(
          'websearch: Created DDGS client with 10s timeout',
        );

        // Add comprehensive logging for debugging
        LogTags.network.logInfo(
          'websearch: Starting search for query: $query with $numResults results',
        );
        final raw = await client
            .text(query, maxResults: numResults, backend: 'duckduckgo')
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                LogTags.network.logWarning('websearch: timeout for "$query"');
                LogTags.network.logInfo(
                  'websearch: Closing client due to timeout',
                );
                client.close();
                throw TimeoutException('Search timed out after 15s');
              },
            );
        LogTags.network.logInfo(
          'websearch: Search completed successfully with ${raw.length} results',
        );
        client.close();
        LogTags.network.logInfo(
          'websearch: Got ${raw.length} results for query: $query',
        );
        LogTags.network.logInfo(
          'websearch: Search completed successfully with ${raw.length} results for "$query"',
        );
        if (raw.isEmpty) {
          return ToolOutput(
            'No results found for: $query',
            metadata: {
              'query': query,
              'provider': 'duckduckgo',
              'count': 0,
              'results': <Map<String, dynamic>>[],
            },
          );
        }
        final results = raw
            .map((r) {
              var url = (r['href'] as String?) ?? '';
              if (url.isNotEmpty &&
                  !url.startsWith('http://') &&
                  !url.startsWith('https://')) {
                url = 'https://$url';
              }
              return _SearchResult(
                title: (r['title'] as String?) ?? '',
                url: url,
                snippet: (r['body'] as String?) ?? 'No description available.',
              );
            })
            .where((r) => r.title.isNotEmpty && r.url.isNotEmpty)
            .toList();

        final formatted = results
            .asMap()
            .entries
            .map((e) {
              final i = e.key + 1;
              final r = e.value;
              return '$i. ${r.title}\n'
                  '   URL: ${r.url}\n'
                  '   ${r.snippet}';
            })
            .join('\n\n');
        return ToolOutput(
          'Search results for "$query":\n\n$formatted',
          metadata: {
            'query': query,
            'provider': 'duckduckgo',
            'count': results.length,
            'results': results.map((r) => r.toJson()).toList(),
          },
        );
      } catch (e, s) {
        LogTags.network.logError('websearch: search failed for "$query"', e, s);
        return ToolOutput(
          'Search failed: $e',
          metadata: {'error': true, 'query': query},
        );
      }
    },
  );

  void dispose() {
    // No need to dispose since we're creating a new client for each request
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
