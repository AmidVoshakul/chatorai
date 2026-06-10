import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // for BytesBuilder

import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:chatorai/shared/utils/logger.dart';

ToolDef createWebfetchTool() {
  return ToolDef(
    id: 'webfetch',
    description: 'Fetch a URL and return its content',
    inputSchema: {
      'type': 'object',
      'properties': {
        'url': {'type': 'string', 'description': 'URL to fetch'},
        'max_chars': {
          'type': 'integer',
          'description': 'Maximum characters to return',
        },
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

      final maxChars = input['max_chars'] as int? ?? 50000;

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

      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        final request = await client
            .getUrl(uri)
            .timeout(const Duration(seconds: 10));
        final response = await request.close();
        final byteBuffer = BytesBuilder();
        await for (final chunk in response) {
          byteBuffer.add(chunk);
          if (byteBuffer.length >= maxChars * 2)
            break; // rough estimate for bytes
        }
        client.close();
        // Decode as UTF-8 to properly handle UTF-8 encoded content (Russian, Chinese, etc.)
        final text = utf8.decode(byteBuffer.takeBytes(), allowMalformed: true);
        LogTags.network.logInfo(
          'webfetch: Content fetched and decoded (${text.length} chars)',
        );
        return ToolOutput(text.substring(0, text.length.clamp(0, maxChars)));
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
