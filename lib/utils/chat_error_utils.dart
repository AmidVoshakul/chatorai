import 'dart:convert';

class ChatErrorUtils {
  ChatErrorUtils._();

  static const List<String> _errorPrefixes = [
    'DioException [bad response]: ',
    'DioException [connection error]: ',
    'SocketException: ',
    'HttpException: ',
  ];

  static const List<String> _errorPatterns = [
    'Exception',
    'DioException',
    'This exception was thrown',
    'Traceback',
    'stack trace',
    'status code',
    'RequestOptions',
    'Bad Request',
    'Client error',
    'SocketException',
    'HttpException',
  ];

  static const int maxMessageLen = 20000;

  static String formatError(Object error) {
    try {
      final errorString = error.toString();

      // Try to parse as JSON first
      try {
        final parsed = jsonDecode(errorString);
        if (parsed is Map<String, dynamic> && parsed.containsKey('error')) {
          final errorData = parsed['error'];
          if (errorData is Map<String, dynamic>) {
            final message = errorData['message'] ?? 'Unknown error';
            final code = errorData['code'] ?? '';
            return 'Error $code: $message';
          }
        }
      } catch (_) {
        // Not JSON, continue with string processing
      }

      // Clean up common error formatting
      String cleanedError = errorString
          .replaceAll('\\n', '\n')
          .replaceAll('\\t', ' ')
          .replaceAll('\\\\', '\\')
          .trim();

      // Remove common prefixes
      for (final prefix in _errorPrefixes) {
        if (cleanedError.startsWith(prefix)) {
          cleanedError = cleanedError.substring(prefix.length);
          break;
        }
      }

      // Truncate if too long
      if (cleanedError.length > 500) {
        cleanedError = '${cleanedError.substring(0, 500)}...';
      }

      return cleanedError;
    } catch (e) {
      return error.toString();
    }
  }

  static List<Map<String, dynamic>> sanitizeMessages(
    List<Map<String, dynamic>> messages,
  ) {
    final out = <Map<String, dynamic>>[];

    for (final m in messages) {
      var content = m['content'] ?? '';
      final role = m['role'] ?? 'user';

      // Skip assistant messages with error patterns
      final hasErrPattern = _errorPatterns.any((p) => content.contains(p));
      if (role == 'assistant' && hasErrPattern) {
        continue;
      }

      // Truncate very long messages
      if (content.length > maxMessageLen) {
        content = '${content.substring(0, maxMessageLen)}...[truncated]';
      }

      // Preserve multimodal structure (with images)
      if (m.containsKey('content') && m['content'] is List) {
        out.add(m);
      } else {
        out.add({'role': role, 'content': content});
      }
    }

    return out;
  }

  static bool isRateLimitError(Object error) {
    final err = error.toString();
    return err.contains('429') ||
        err.contains('Rate limit') ||
        err.contains('bad response');
  }

  static bool isBadRequestError(Object error) {
    final err = error.toString();
    return err.contains('400') ||
        err.toLowerCase().contains('bad response') ||
        err.toLowerCase().contains('client error') ||
        err.toLowerCase().contains('bad request');
  }
}
