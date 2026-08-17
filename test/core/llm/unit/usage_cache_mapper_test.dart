import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/llm/usage_cache_mapper.dart';

void main() {
  group('extractCacheTokens', () {
    test('OpenAI Chat Completions: prompt_tokens_details.cached_tokens', () {
      final usage = {
        'prompt_tokens_details': {'cached_tokens': 1920},
      };
      final result = extractCacheTokens(usage);
      expect(result.read, 1920);
      expect(result.write, 0);
    });

    test('OpenAI Responses: input_tokens_details.cached_tokens and cache_write_tokens',
        () {
      final usage = {
        'input_tokens_details': {'cached_tokens': 2000, 'cache_write_tokens': 400},
      };
      final result = extractCacheTokens(usage);
      expect(result.read, 2000);
      expect(result.write, 400);
    });

    test('DeepSeek: prompt_cache_hit_tokens (miss tokens are not writes)', () {
      final usage = {
        'prompt_cache_hit_tokens': 1500,
        'prompt_cache_miss_tokens': 500,
      };
      final result = extractCacheTokens(usage);
      expect(result.read, 1500);
      expect(result.write, 0);
    });

    test('Anthropic-style: cache_read_input_tokens and cache_creation_input_tokens',
        () {
      final usage = {
        'cache_read_input_tokens': 3000,
        'cache_creation_input_tokens': 200,
      };
      final result = extractCacheTokens(usage);
      expect(result.read, 3000);
      expect(result.write, 200);
    });

    test('empty map returns 0/0', () {
      final result = extractCacheTokens(const {});
      expect(result.read, 0);
      expect(result.write, 0);
    });

    test('missing fields return 0/0', () {
      final usage = {'total_tokens': 100};
      final result = extractCacheTokens(usage);
      expect(result.read, 0);
      expect(result.write, 0);
    });

    test('string values are parsed safely', () {
      final usage = {
        'prompt_tokens_details': {'cached_tokens': '1920'},
      };
      final result = extractCacheTokens(usage);
      expect(result.read, 1920);
      expect(result.write, 0);
    });

    test('null values do not crash', () {
      final usage = {
        'prompt_tokens_details': {'cached_tokens': null},
      };
      final result = extractCacheTokens(usage);
      expect(result.read, 0);
      expect(result.write, 0);
    });

    test('read priority: first non-zero wins', () {
      final usage = {
        'prompt_tokens_details': {'cached_tokens': 0},
        'input_tokens_details': {'cached_tokens': 100},
        'prompt_cache_hit_tokens': 200,
        'cache_read_input_tokens': 300,
      };
      final result = extractCacheTokens(usage);
      expect(result.read, 100);
    });

    test('write priority: first non-zero wins', () {
      final usage = {
        'cache_creation_input_tokens': 0,
        'input_tokens_details': {'cache_write_tokens': 50},
      };
      final result = extractCacheTokens(usage);
      expect(result.write, 50);
    });
  });
}
