import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Test different API error scenarios
  await testInvalidAPIKey();
  await testInvalidModel();
  await testInvalidRequest();
  await testRateLimit();
  await testServerErrors();
}

Future<void> testInvalidAPIKey() async {
  print('\n=== Testing Invalid API Key ===');

  final headers = {
    'Authorization': 'Bearer sk-or-v1-invalid-key',
    'Content-Type': 'application/json',
  };

  final body = {
    'model': 'amazon/nova-2-lite-v1:free',
    'messages': [
      {'role': 'user', 'content': 'Hello'}
    ],
    'max_tokens': 100
  };

  try {
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Status: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> testInvalidModel() async {
  print('\n=== Testing Invalid Model ===');

  final headers = {
    'Authorization': 'Bearer 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',
    'Content-Type': 'application/json',
  };

  final body = {
    'model': 'nonexistent/model:free',
    'messages': [
      {'role': 'user', 'content': 'Hello'}
    ],
    'max_tokens': 100
  };

  try {
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Status: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> testInvalidRequest() async {
  print('\n=== Testing Invalid Request ===');

  final headers = {
    'Authorization': 'Bearer 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',
    'Content-Type': 'application/json',
  };

  final body = {
    'model': 'amazon/nova-2-lite-v1:free',
    'messages': [], // Invalid - empty messages
    'max_tokens': 100
  };

  try {
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Status: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> testRateLimit() async {
  print('\n=== Testing Rate Limit (Multiple Requests) ===');

  final headers = {
    'Authorization': 'Bearer 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',
    'Content-Type': 'application/json',
  };

  final body = {
    'model': 'amazon/nova-2-lite-v1:free',
    'messages': [
      {'role': 'user', 'content': 'Hello'}
    ],
    'max_tokens': 100
  };

  // Make multiple rapid requests to trigger rate limiting
  for (int i = 0; i < 5; i++) {
    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Request $i - Status: ${response.statusCode}');
      if (response.statusCode == 429) {
        print('Rate limit hit!');
        break;
      }
    } catch (e) {
      print('Request $i - Error: $e');
    }
  }
}

Future<void> testServerErrors() async {
  print('\n=== Testing Server Errors ===');

  final headers = {
    'Authorization': 'Bearer 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',
    'Content-Type': 'application/json',
  };

  final body = {
    'model': 'amazon/nova-2-lite-v1:free',
    'messages': [
      {'role': 'user', 'content': 'Hello'}
    ],
    'max_tokens': 100
  };

  try {
    // Try with a different endpoint that might return server errors
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Status: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
