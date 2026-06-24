import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/truncation_service.dart';
import 'package:chatorai/shared/utils/logger.dart';

ToolDef createWebfetchTool() {
  return ToolDef(
    id: 'webfetch',
    description:
        'Fetch content from a URL and return it as text. '
        'Use for retrieving web pages, API responses, or any HTTP/HTTPS '
        'resource. Large responses are truncated and saved to disk.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'url': {'type': 'string', 'description': 'URL to fetch'},
      },
      'required': ['url'],
    },
    execute: (input, ctx) async {
      LogTags.permission.logInfo('webfetch.execute: START');
      final url = input['url'] as String?;
      if (url == null) throw ArgumentError('url is required');

      LogTags.permission.logInfo(
        'webfetch.execute: About to call ctx.ask for url=$url',
      );
      await ctx.ask(permission: 'webfetch', patterns: ['webfetch:url=$url']);
      LogTags.permission.logInfo(
        'webfetch.execute: ctx.ask returned, permission granted',
      );

      final uri = Uri.tryParse(url);
      if (uri == null || uri.host.isEmpty) {
        return ToolOutput(
          'Error: invalid URL: $url',
          metadata: {'error': true},
        );
      }
      if (!['http', 'https'].contains(uri.scheme)) {
        return ToolOutput(
          'Error: only http/https URLs are allowed',
          metadata: {'error': true},
        );
      }
      if (_isPrivateHost(uri.host)) {
        return ToolOutput(
          'Error: fetching from private/internal hosts is not allowed',
          metadata: {'error': true},
        );
      }

      final truncation = TruncationService.instance;

      try {
        final client = HttpClient()
          ..userAgent =
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
        client.connectionTimeout = const Duration(seconds: 10);
        final request = await client
            .getUrl(uri)
            .timeout(const Duration(seconds: 10));
        request.followRedirects = true;
        request.maxRedirects = 5;
        final response = await request.close();
        final text = await response.transform(utf8.decoder).join();
        client.close();
        LogTags.network.logInfo(
          'webfetch: Content fetched (${text.length} chars) from $url',
        );
        return ToolOutput(truncation.truncate(text));
      } on TimeoutException {
        return ToolOutput(
          'Error fetching $url: request timed out',
          metadata: {'error': true, 'timeout': true},
        );
      } catch (e, s) {
        LogTags.network.logError('webfetch: error fetching $url', e, s);
        return ToolOutput('Error fetching $url: $e', metadata: {'error': true});
      }
    },
  );
}

bool _isPrivateHost(String host) {
  final lower = host.toLowerCase();
  final parts = lower.split('.');
  if (parts.isEmpty) return true;

  final isLoopback = lower == 'localhost' || lower == '127.0.0.1';
  final isIPv6Loopback = lower == '::1';
  if (isLoopback || isIPv6Loopback) return true;

  if (parts.length == 4) {
    final octets = parts.map(int.tryParse).whereType<int>().toList();
    if (octets.length == 4) {
      if (octets[0] == 10) return true;
      if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) return true;
      if (octets[0] == 192 && octets[1] == 168) return true;
      if (octets[0] == 169 && octets[1] == 254) return true;
      if (octets[0] == 127) return true;
    }
  }

  if (lower.startsWith('localhost') || lower.endsWith('.local')) return true;
  return false;
}
