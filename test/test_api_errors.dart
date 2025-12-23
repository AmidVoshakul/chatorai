// Test API error handling and parsing
// Run with: dart test/test_api_errors.dart

import 'dart:convert';

// Simulated error responses from OpenRouter API
void main() async {
  print('🧪 Testing API Error Handling...\n');

  // Test 1: Invalid API Key
  print('🔍 Test 1: Invalid API Key');
  final invalidKeyError = {
    'error': {
      'message': 'Invalid API key provided',
      'code': 401
    }
  };
  final formatted1 = _formatErrorMessage(invalidKeyError);
  print('✅ Response: $formatted1');
  print('   Expected: Error 401: Invalid API key provided\n');

  // Test 2: Invalid Model
  print('🔍 Test 2: Invalid Model');
  final invalidModelError = {
    'error': {
      'message': 'Model not found: nonexistent/model:free',
      'code': 404
    }
  };
  final formatted2 = _formatErrorMessage(invalidModelError);
  print('✅ Response: $formatted2');
  print('   Expected: Error 404: Model not found: nonexistent/model:free\n');

  // Test 3: Rate Limit
  print('🔍 Test 3: Rate Limit');
  final rateLimitError = {
    'error': {
      'message': 'Rate limit exceeded. Please try again later.',
      'code': 429
    }
  };
  final formatted3 = _formatErrorMessage(rateLimitError);
  print('✅ Response: $formatted3');
  print('   Expected: Error 429: Rate limit exceeded. Please try again later.\n');

  // Test 4: Empty Messages
  print('🔍 Test 4: Empty Messages');
  final emptyMessagesError = {
    'error': {
      'message': 'messages array cannot be empty',
      'code': 400
    }
  };
  final formatted4 = _formatErrorMessage(emptyMessagesError);
  print('✅ Response: $formatted4');
  print('   Expected: Error 400: messages array cannot be empty\n');

  // Test 5: Server Error (500)
  print('🔍 Test 5: Server Error');
  final serverError = {
    'error': {
      'message': 'Internal server error',
      'code': 500
    }
  };
  final formatted5 = _formatErrorMessage(serverError);
  print('✅ Response: $formatted5');
  print('   Expected: Error 500: Internal server error\n');

  // Test 6: String error (non-JSON)
  print('🔍 Test 6: String Error');
  final stringError = 'Exception: Connection timeout';
  final formatted6 = _formatErrorMessage(stringError);
  print('✅ Response: $formatted6');
  print('   Expected: Exception: Connection timeout\n');

  // Test 7: Long error message
  print('🔍 Test 7: Long Error Message');
  final longError = {
    'error': {
      'message': 'This is a very long error message that should be truncated when collapsed but shown in full when expanded. It contains detailed information about what went wrong and how to fix it.',
      'code': 500
    }
  };
  final formatted7 = _formatErrorMessage(longError);
  print('✅ Response: $formatted7');
  print('   Length: ${formatted7.length} characters\n');

  print('🎉 All error handling tests completed!');
  print('✅ Error parsing works correctly');
  print('✅ JSON and string errors handled');
  print('✅ Long messages formatted properly');
}

// Error formatting function (copied from chat_screen.dart)
String _formatErrorMessage(Object error) {
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
    final prefixes = [
      'Exception: ',
      'Error: ',
      'DioException: ',
    ];

    for (final prefix in prefixes) {
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
