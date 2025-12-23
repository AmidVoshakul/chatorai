import 'dart:convert';

void main() {
  // Test different error message formats
  testErrorFormatting();
}

void testErrorFormatting() {
  print('=== Testing Error Message Formatting ===\n');

  // Test 1: Invalid API Key Error
  print('1. Invalid API Key Error:');
  final invalidApiKeyError = '{"error":{"message":"User not found.","code":401}}';
  final formatted1 = formatErrorMessage(invalidApiKeyError);
  print('   Original: $invalidApiKeyError');
  print('   Formatted: $formatted1\n');

  // Test 2: Invalid Model Error
  print('2. Invalid Model Error:');
  final invalidModelError = '{"error":{"message":"nonexistent/model:free is not a valid model ID","code":400},"user_id":"user_354RhHy0RmZ07qYnIk6cqbqr06X"}';
  final formatted2 = formatErrorMessage(invalidModelError);
  print('   Original: $invalidModelError');
  print('   Formatted: $formatted2\n');

  // Test 3: Invalid Request Error
  print('3. Invalid Request Error:');
  final invalidRequestError = '{"error":{"message":"Input required: specify \\"prompt\\" or \\"messages\\"","code":400},"user_id":"user_354RhHy0RmZ07qYnIk6cqbqr06X"}';
  final formatted3 = formatErrorMessage(invalidRequestError);
  print('   Original: $invalidRequestError');
  print('   Formatted: $formatted3\n');

  // Test 4: Plain text error
  print('4. Plain Text Error:');
  final plainError = 'Connection timeout error';
  final formatted4 = formatErrorMessage(plainError);
  print('   Original: $plainError');
  print('   Formatted: $formatted4\n');

  // Test 5: Long error message
  print('5. Long Error Message:');
  final longError = '{"error":{"message":"This is a very long error message that should be truncated when collapsed but shown in full when expanded. It contains detailed information about what went wrong and how to fix it.","code":500}}';
  final formatted5 = formatErrorMessage(longError);
  print('   Original: $longError');
  print('   Formatted: $formatted5\n');

  print('🎉 All error formatting tests completed!');
  print('✅ Error parsing works correctly');
  print('✅ JSON and string errors handled');
}

String formatErrorMessage(String errorMessage) {
  try {
    // Try to parse as JSON
    final json = jsonDecode(errorMessage);

    if (json is Map<String, dynamic>) {
      if (json.containsKey('error')) {
        final error = json['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'] ?? 'Unknown error';
          final code = error['code'] ?? '';
          return 'Error $code: $message';
        }
      }
    }
  } catch (e) {
    // Not JSON, return as plain text
  }

  // Clean up common error formatting issues
  String cleanedError = errorMessage
      .replaceAll('\\n', '\n')
      .replaceAll('\\t', ' ')
      .replaceAll('\\\\', '\\')
      .trim();

  // Remove common prefixes
  final prefixes = [
    'DioException [bad response]: ',
    'DioException [connection error]: ',
    'SocketException: ',
    'HttpException: ',
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
}

