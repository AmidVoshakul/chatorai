import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:ddgs/ddgs.dart';

class WebSearchTool {
  ToolDef get definition {
    final year = DateTime.now().year;
    return ToolDef(
      id: 'websearch',
      description:
          'Search the web using DuckDuckGo. Returns results with title, URL, and snippet.\n'
          'The current year is $year. You MUST use this year when searching for recent information or current events\n'
          '- Example: If the current year is $year and the user asks for "latest AI news", search for "AI news $year", NOT "AI news ${year - 1}"',
    inputSchema: {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'description': 'Search query'},
        'numResults': {
          'type': 'integer',
          'description': 'Max results (default 5, max 25)',
        },
        'region': {
          'type': 'string',
          'description':
              'Region for localized results (e.g. "us-en", "uk-en", "ru-ru", "de-de", "fr-fr", "jp-jp", "cn-zh"). Default: "us-en"',
        },
        'timeLimit': {
          'type': 'string',
          'description':
              'Time filter: "d" (past 24h), "w" (past week), "m" (past month), "y" (past year). Omit for all time.',
        },
        'safeSearch': {
          'type': 'string',
          'description':
              'Safe search level: "on" (strict), "moderate", "off". Default: "moderate"',
        },
        'contextMaxCharacters': {
          'type': 'integer',
          'description':
              'Truncate each result snippet to this many characters. Omit for full snippet.',
        },
        'detailLevel': {
          'type': 'string',
          'description':
              'Result detail level: "snippet" (default, title+URL+snippet), "title_only" (title+URL only, saves tokens).',
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
        ).clamp(1, 25);
      } catch (_) {
        numResults = 5;
      }

      final region = input['region'] as String? ?? 'us-en';
      final timeLimit = input['timeLimit'] as String?;
      final safeSearch = input['safeSearch'] as String? ?? 'moderate';
      final contextMaxChars = input['contextMaxCharacters'] as int?;
      final detailLevel = input['detailLevel'] as String? ?? 'snippet';

      LogTags.network.logInfo(
        'websearch: searching for "$query" (max $numResults, '
        'region=$region, timeLimit=$timeLimit, safeSearch=$safeSearch)',
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

        LogTags.network.logInfo(
          'websearch: Starting search for query: $query with $numResults results',
        );
        final raw = await client
            .text(
              query,
              maxResults: numResults,
              region: region,
              safesearch: safeSearch,
              timelimit: timeLimit,
              backend: 'duckduckgo',
            )
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
              var snippet =
                  (r['body'] as String?) ?? 'No description available.';
              if (contextMaxChars != null && snippet.length > contextMaxChars) {
                snippet = '${snippet.substring(0, contextMaxChars)}…';
              }
              return _SearchResult(
                title: (r['title'] as String?) ?? '',
                url: url,
                snippet: snippet,
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
              if (detailLevel == 'title_only') {
                return '$i. ${r.title}\n'
                    '   URL: ${r.url}';
              }
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
  }

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
