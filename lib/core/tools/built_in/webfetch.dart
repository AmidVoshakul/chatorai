import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

ToolDef createWebfetchTool({int defaultMaxChars = 50000}) {
  return ToolDef(
    id: 'webfetch',
    description: 'Fetch content from a URL and return it as text, '
        'markdown, or raw HTML. '
        'Use for retrieving web pages, API responses, or any HTTP/HTTPS '
        'resource. HTML pages are automatically converted to clean markdown '
        'by default. Large responses are truncated.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'url': {'type': 'string', 'description': 'URL to fetch'},
        'format': {
          'type': 'string',
          'enum': ['markdown', 'text', 'html'],
          'description':
              'Output format. "markdown" (default) converts HTML to clean '
              'markdown, "text" strips all HTML tags, "html" returns raw HTML',
        },
        'max_chars': {
          'type': 'integer',
          'description': 'Maximum characters to return (default: 50000)',
        },
        'timeout': {
          'type': 'integer',
          'description':
              'Request timeout in seconds (default: 30, min: 5, max: 120)',
        },
      },
      'required': ['url'],
    },
    execute: (input, ctx) async {
      LogTags.permission.logInfo('webfetch.execute: START');
      final url = input['url'] as String?;
      if (url == null) throw ArgumentError('url is required');

      final format = input['format'] as String? ?? 'markdown';
      final maxChars = input['max_chars'] as int? ?? defaultMaxChars;
      final timeoutSec = (input['timeout'] as int?)?.clamp(5, 120) ?? 30;
      const maxContentLength = 5 * 1024 * 1024; // 5MB

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

      // DNS resolution check – prevents SSRF via hostnames resolving to
      // private IPs (defense-in-depth, not a full rebinding guard).
      try {
        final privateIp = await _checkDnsForPrivateHost(uri.host);
        if (privateIp != null) {
          return ToolOutput(
            'Error: ${uri.host} resolves to private IP ($privateIp)',
            metadata: {'error': true},
          );
        }
      } on TimeoutException {
        return ToolOutput(
          'Error: DNS lookup timed out for ${uri.host}',
          metadata: {'error': true, 'timeout': true},
        );
      }

      try {
        final client = HttpClient()
          ..userAgent =
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
        client.connectionTimeout = Duration(seconds: timeoutSec);

        try {
          var currentUri = uri;
          for (var redirectCount = 0; redirectCount <= 5;
              redirectCount++) {
            final request = await client
                .getUrl(currentUri)
                .timeout(Duration(seconds: timeoutSec));
            request.followRedirects = false;

            if (currentUri == uri) {
              switch (format) {
                case 'markdown':
                  request.headers.set(
                    'Accept',
                    'text/html,application/xhtml+xml;q=0.9,*/*;q=0.8',
                  );
                case 'text':
                  request.headers.set(
                    'Accept',
                    'text/html,application/xhtml+xml;q=0.9,*/*;q=0.8',
                  );
                default:
                  request.headers.set('Accept', '*/*');
              }
            }

            final response = await request.close();

            final contentLength = response.contentLength;
            if (contentLength > maxContentLength) {
              await response.drain();
              return ToolOutput(
                'Error: response too large '
                '(${contentLength ~/ 1024 ~/ 1024}MB, max 5MB)',
                metadata: {'error': true, 'too_large': true},
              );
            }

            if (response.statusCode >= 300 &&
                response.statusCode < 400) {
              final location = response.headers.value('location');
              await response.drain();
              if (location == null || location.isEmpty) {
                return ToolOutput(
                  'Error: redirect without Location header',
                  metadata: {'error': true},
                );
              }
              final resolved = resolveRedirectUri(
                currentUri,
                location,
              );
              if (resolved == null) {
                return ToolOutput(
                  'Error: redirect to private/internal host is not '
                      'allowed',
                  metadata: {'error': true},
                );
              }
              currentUri = resolved;
              try {
                final dnsIp =
                    await _checkDnsForPrivateHost(currentUri.host);
                if (dnsIp != null) {
                  return ToolOutput(
                    'Error: redirect target ${currentUri.host} '
                        'resolves to private IP ($dnsIp)',
                    metadata: {'error': true},
                  );
                }
              } on TimeoutException {
                return ToolOutput(
                  'Error: DNS lookup timed out for redirect target '
                      '${currentUri.host}',
                  metadata: {'error': true, 'timeout': true},
                );
              }
              continue;
            }

            final bytes = <int>[];
            await for (final chunk in response) {
              bytes.addAll(chunk);
              if (bytes.length > maxContentLength) {
                await response.drain();
                return ToolOutput(
                  'Error: response exceeded 5MB limit',
                  metadata: {'error': true, 'too_large': true},
                );
              }
            }

            final contentType = response.headers
                    .value('content-type')
                    ?.toLowerCase() ??
                '';

            final raw = detectAndDecode(bytes, contentType);
            final isHtml = contentType.contains('text/html');

            String text;
            if (isHtml) {
              switch (format) {
                case 'markdown':
                  text = convertHtmlToMarkdown(raw);
                case 'text':
                  text = extractTextFromHtml(raw);
                default:
                  text = raw;
              }
            } else {
              text = raw;
            }

            LogTags.network.logInfo(
              'webfetch: Content fetched (${raw.length} raw chars, '
              '${text.length} converted chars) from $currentUri',
            );

            if (text.length <= maxChars) {
              return ToolOutput(text);
            }
            return ToolOutput(truncateContent(text, maxChars));
          }

          return ToolOutput(
            'Error: too many redirects',
            metadata: {'error': true},
          );
        } finally {
          client.close();
        }
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

/// Detects charset from Content-Type header or HTML meta tags and decodes bytes.
String detectAndDecode(List<int> bytes, String contentType) {
  String? detectedCharset;
  final charsetMatch =
      RegExp(r'''charset\s*=\s*([^\s;]+)''', caseSensitive: false)
          .firstMatch(contentType);
  if (charsetMatch != null) {
    detectedCharset = charsetMatch.group(1)!.trim();
  }

  final isHtml = contentType.contains('text/html');
  if (detectedCharset == null && isHtml) {
    final head = latin1.decode(bytes.take(4096).toList());
    final meta = RegExp(
      r'''<meta\s[^>]*charset\s*=\s*["']?\s*([^"'\s>/]+)''',
      caseSensitive: false,
    ).firstMatch(head);
    if (meta != null) {
      detectedCharset = meta.group(1)!.trim();
    } else {
      final httpEquiv = RegExp(
        r'''<meta\s[^>]*http-equiv\s*=\s*["']?\s*content-type\s*["']?[^>]*content\s*=\s*["'][^"']*charset=([^"'\s;]+)''',
        caseSensitive: false,
      ).firstMatch(head);
      if (httpEquiv != null) {
        detectedCharset = httpEquiv.group(1)!.trim();
      }
    }
  }

  late String raw;
  if (detectedCharset != null) {
    final encoding = Encoding.getByName(detectedCharset) ?? utf8;
    try {
      raw = encoding.decode(bytes);
    } catch (_) {
      raw = utf8.decode(bytes, allowMalformed: true);
    }
  } else {
    raw = utf8.decode(bytes, allowMalformed: true);
  }

  if (raw.isNotEmpty && raw.codeUnitAt(0) == 0xFEFF) {
    raw = raw.substring(1);
  }
  return raw;
}

/// Truncates text with a sentinel message if it exceeds [maxChars].
String truncateContent(String text, int maxChars) {
  if (text.length <= maxChars) return text;
  const sentinelEstimate = 40;
  final available = maxChars - sentinelEstimate;
  final headLen = available ~/ 2;
  final tailLen = available - headLen;
  final linesSkipped = '\n'.allMatches(
    text.substring(headLen, text.length - tailLen),
  ).length;
  final sentinel = '\n... [$linesSkipped lines truncated] ...\n';
  final tailStart = text.length - tailLen;
  return '${text.substring(0, headLen)}$sentinel${text.substring(tailStart)}';
}

/// Extracts visible text from HTML, stripping all tags.
/// Skips script, style, noscript, iframe, object, embed content.
String extractTextFromHtml(String html) {
  final document = html_parser.parse(html);
  final buffer = StringBuffer();
  if (document.body != null) _collectText(document.body!, buffer);
  final result = buffer.toString();
  return result.trim();
}

void _collectText(dom.Node node, StringBuffer buffer) {
  if (node is dom.Element) {
    final tag = node.localName?.toLowerCase() ?? '';
    if (['script', 'style', 'noscript', 'iframe', 'object', 'embed']
        .contains(tag)) {
      return;
    }

    // Add block-level spacing before block elements
    if (_isBlockElement(tag) && buffer.isNotEmpty) {
      final current = buffer.toString();
      if (!current.endsWith('\n')) {
        buffer.write('\n');
      }
    }

    for (final child in node.nodes) {
      _collectText(child, buffer);
    }

    if (_isBlockElement(tag)) {
      buffer.write('\n');
    }
  } else if (node is dom.Text) {
    final text = node.text;
    if (text.trim().isNotEmpty) {
      buffer.write(text);
    }
  }
}

bool _isBlockElement(String tag) {
  return [
    'p',
    'div',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'li',
    'blockquote',
    'pre',
    'hr',
    'section',
    'article',
    'header',
    'footer',
    'nav',
    'br',
    'table',
    'tr',
  ].contains(tag);
}

/// Converts HTML to clean Markdown.
String convertHtmlToMarkdown(String html) {
  final document = html_parser.parse(html);
  final buffer = StringBuffer();
  if (document.body != null) _convertNodeToMarkdown(document.body!, buffer, 0);
  return buffer.toString().trim();
}

void _convertNodeToMarkdown(dom.Node node, StringBuffer buffer, int depth) {
  if (node is dom.Element) {
    final tag = node.localName?.toLowerCase() ?? '';
    if (['script', 'style', 'noscript', 'iframe', 'object', 'embed', 'meta',
        'link']
        .contains(tag)) {
      return;
    }

    switch (tag) {
      case 'h1':
        _writeNewline(buffer, depth);
        buffer.write('# ');
        for (final child in node.nodes) {
          _convertInline(child, buffer);
        }
        buffer.write('\n\n');

      case 'h2':
        _writeNewline(buffer, depth);
        buffer.write('## ');
        for (final child in node.nodes) {
          _convertInline(child, buffer);
        }
        buffer.write('\n\n');

      case 'h3':
        _writeNewline(buffer, depth);
        buffer.write('### ');
        for (final child in node.nodes) {
          _convertInline(child, buffer);
        }
        buffer.write('\n\n');

      case 'h4':
        _writeNewline(buffer, depth);
        buffer.write('#### ');
        for (final child in node.nodes) {
          _convertInline(child, buffer);
        }
        buffer.write('\n\n');

      case 'h5':
        _writeNewline(buffer, depth);
        buffer.write('##### ');
        for (final child in node.nodes) {
          _convertInline(child, buffer);
        }
        buffer.write('\n\n');

      case 'h6':
        _writeNewline(buffer, depth);
        buffer.write('###### ');
        for (final child in node.nodes) {
          _convertInline(child, buffer);
        }
        buffer.write('\n\n');

      case 'p':
        _writeNewline(buffer, depth);
        for (final child in node.nodes) {
          _convertInline(child, buffer);
        }
        buffer.write('\n\n');

      case 'a': {
        String? href;
        try {
          href = node.attributes['href'];
        } catch (_) {}
        final text = StringBuffer();
        for (final child in node.nodes) {
          _convertInline(child, text);
        }
        final linkText = text.toString().trim();
        if (linkText.isNotEmpty && href != null && href.isNotEmpty) {
          buffer.write('[$linkText]($href)');
        } else if (linkText.isNotEmpty) {
          buffer.write(linkText);
        }
        break;
      }

      case 'strong':
      case 'b':
        buffer.write('**');
        for (final child in node.nodes) {
          _convertInline(child, buffer);
        }
        buffer.write('**');

      case 'em':
      case 'i':
        buffer.write('*');
        for (final child in node.nodes) {
          _convertInline(child, buffer);
        }
        buffer.write('*');

      case 'code':
        buffer.write('`');
        for (final child in node.nodes) {
          _convertInline(child, buffer);
        }
        buffer.write('`');

      case 'pre':
        _writeNewline(buffer, depth);
        // Detect language from code element inside pre
        String lang = '';
        for (final child in node.nodes) {
          if (child is dom.Element && child.localName?.toLowerCase() == 'code') {
            try {
              final cls = child.attributes['class'] ?? '';
              if (cls.startsWith('language-')) {
                lang = cls.substring(9);
              } else if (cls.startsWith('lang-')) {
                lang = cls.substring(5);
              }
            } catch (_) {}
            break;
          }
        }
        buffer.write('```$lang\n');
        buffer.write(_getCodeContent(node));
        if (!_getCodeContent(node).endsWith('\n')) {
          buffer.write('\n');
        }
        buffer.write('```\n\n');

      case 'ul':
        _writeNewline(buffer, depth);
        for (final child in node.nodes) {
          if (child is dom.Element &&
              child.localName?.toLowerCase() == 'li') {
            buffer.write('  ' * depth);
            buffer.write('- ');
            for (final liChild in child.nodes) {
              _convertNodeToMarkdown(liChild, buffer, depth + 1);
            }
            buffer.write('\n');
          }
        }
        buffer.write('\n');

      case 'ol':
        _writeNewline(buffer, depth);
        int index = 1;
        for (final child in node.nodes) {
          if (child is dom.Element &&
              child.localName?.toLowerCase() == 'li') {
            buffer.write('  ' * depth);
            buffer.write('$index. ');
            for (final liChild in child.nodes) {
              _convertNodeToMarkdown(liChild, buffer, depth + 1);
            }
            buffer.write('\n');
            index++;
          }
        }
        buffer.write('\n');

      case 'blockquote':
        _writeNewline(buffer, depth);
        final quote = StringBuffer();
        for (final child in node.nodes) {
          _convertNodeToMarkdown(child, quote, depth);
        }
        for (final line in quote.toString().split('\n')) {
          if (line.trim().isNotEmpty) {
            buffer.write('> ');
            buffer.write(line);
          }
          buffer.write('\n');
        }
        buffer.write('\n');

      case 'hr':
        _writeNewline(buffer, depth);
        buffer.write('---\n\n');

      case 'img': {
        String? src;
        String? alt;
        try {
          src = node.attributes['src'];
          alt = node.attributes['alt'] ?? '';
        } catch (_) {}
        if (src != null) {
          buffer.write('![$alt]($src)');
        }
        break;
      }

      case 'br':
        buffer.write('\n');

      default:
        // Inline elements: span, div, etc. — just recurse
        for (final child in node.nodes) {
          _convertNodeToMarkdown(child, buffer, depth);
        }
    }
  } else if (node is dom.Text) {
    final text = node.text;
    if (text.trim().isNotEmpty) {
      buffer.write(text);
    }
  }
}

void _convertInline(dom.Node node, StringBuffer buffer) {
  _convertNodeToMarkdown(node, buffer, 0);
}

String _getCodeContent(dom.Node node) {
  final buf = StringBuffer();
  for (final child in node.nodes) {
    if (child is dom.Text) {
      buf.write(child.text);
    } else if (child is dom.Element) {
      for (final c in child.nodes) {
        if (c is dom.Text) buf.write(c.text);
      }
    }
  }
  return buf.toString();
}

void _writeNewline(StringBuffer buffer, int depth) {
  if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) {
    buffer.write('\n');
  }
}

/// Resolves a redirect location relative to the current URI and validates
/// that the target is not a private/internal host.
/// Returns the resolved [Uri] if safe, or `null` if the target is blocked.
Uri? resolveRedirectUri(Uri current, String location) {
  final resolved = current.resolve(location);
  if (resolved.host.isEmpty) return null;
  if (_isPrivateHost(resolved.host)) return null;
  return resolved;
}

/// Resolves [host] via DNS and checks if it points to a private IP.
/// Returns the private IP string if any resolved address is private,
/// or `null` if all IPs are public (or host is a raw IP).
Future<String?> _checkDnsForPrivateHost(String host) async {
  if (InternetAddress.tryParse(host) != null) return null;
  try {
    final addresses = await InternetAddress.lookup(
      host,
      type: InternetAddressType.any,
    ).timeout(const Duration(seconds: 5));
    for (final addr in addresses) {
      if (_isPrivateHost(addr.address)) return addr.address;
    }
  } on TimeoutException {
    rethrow; // Caught by outer handler for a precise error message
  } on Exception {
    return null;
  }
  return null;
}

bool _isPrivateHost(String host) {
  final lower = host.toLowerCase();
  if (lower.isEmpty) return true;

  // hostname-based checks (localhost, .local suffix)
  if (lower == 'localhost' || lower.startsWith('localhost.')) return true;
  if (lower.endsWith('.local')) return true;

  // Try to parse as IP address – handles both IPv4 and IPv6
  final addr = InternetAddress.tryParse(lower);
  if (addr == null) return false; // not an IP, not a blocked hostname
  if (addr.type == InternetAddressType.IPv6) return _isPrivateIpv6(addr.address);
  // IPv4
  return _isPrivateIpv4(addr.address);
}

bool _isPrivateIpv4(String address) {
  final parts = address.split('.');
  if (parts.length != 4) return true;
  final octets = parts.map(int.tryParse).whereType<int>().toList();
  if (octets.length != 4) return true;
  if (octets[0] == 10) return true;
  if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) return true;
  if (octets[0] == 192 && octets[1] == 168) return true;
  if (octets[0] == 169 && octets[1] == 254) return true;
  if (octets[0] == 127) return true;
  return false;
}

bool _isPrivateIpv6(String address) {
  // ::1 loopback
  if (address == '::1') return true;

  // IPv4-mapped IPv6: ::ffff:x.x.x.x or ::ffff:0:x.x.x.x
  if (address.contains(':ffff:')) {
    final ipv4Part = address.split(':').last;
    if (_isPrivateIpv4(ipv4Part)) return true;
  }

  final firstHextet = address.split(':').first;
  if (firstHextet.isEmpty) return false;

  // fc00::/7 – unique-local (private equivalent of 10.0.0.0/8)
  if (firstHextet.startsWith('fc') || firstHextet.startsWith('fd')) {
    return true;
  }

  // fe80::/10 – link-local
  final hexVal = int.tryParse(firstHextet, radix: 16);
  if (hexVal != null && hexVal >= 0xfe80 && hexVal <= 0xfebf) {
    return true;
  }

  return false;
}
