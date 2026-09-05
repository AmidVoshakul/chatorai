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

    test(
      'OpenAI Responses: input_tokens_details.cached_tokens and cache_write_tokens',
      () {
        final usage = {
          'input_tokens_details': {
            'cached_tokens': 2000,
            'cache_write_tokens': 400,
          },
        };
        final result = extractCacheTokens(usage);
        expect(result.read, 2000);
        expect(result.write, 400);
      },
    );

    test('DeepSeek: prompt_cache_hit_tokens (miss tokens are not writes)', () {
      final usage = {
        'prompt_cache_hit_tokens': 1500,
        'prompt_cache_miss_tokens': 500,
      };
      final result = extractCacheTokens(usage);
      expect(result.read, 1500);
      expect(result.write, 0);
    });

    test(
      'Anthropic-style: cache_read_input_tokens and cache_creation_input_tokens',
      () {
        final usage = {
          'cache_read_input_tokens': 3000,
          'cache_creation_input_tokens': 200,
        };
        final result = extractCacheTokens(usage);
        expect(result.read, 3000);
        expect(result.write, 200);
      },
    );

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

    test('null rawUsage returns 0/0', () {
      final result = extractCacheTokens(null);
      expect(result.read, 0);
      expect(result.write, 0);
    });

    test('non-map rawUsage returns 0/0', () {
      final result = extractCacheTokens('not a map');
      expect(result.read, 0);
      expect(result.write, 0);
    });
  });

  group('extractReasoningTokens', () {
    test('kilo format: completion_tokens_details.reasoning_tokens', () {
      final usage = {
        'completion_tokens_details': {
          'reasoning_tokens': 27,
          'reasoning_tokens_estimated': true,
        },
      };
      expect(extractReasoningTokens(usage), 27);
    });

    test('top-level reasoning_tokens', () {
      final usage = {'reasoning_tokens': 42};
      expect(extractReasoningTokens(usage), 42);
    });

    test('null rawUsage returns 0', () {
      expect(extractReasoningTokens(null), 0);
    });

    test('non-map rawUsage returns 0', () {
      expect(extractReasoningTokens('not a map'), 0);
    });

    test('missing fields return 0', () {
      final usage = {'total_tokens': 100};
      expect(extractReasoningTokens(usage), 0);
    });

    test('string values are parsed safely', () {
      final usage = {
        'completion_tokens_details': {'reasoning_tokens': '15'},
      };
      expect(extractReasoningTokens(usage), 15);
    });
  });

  group('extractUsageRawData', () {
    test('kilo-style raw map extracts all fields', () {
      final usage = {
        'prompt_tokens': 13261,
        'completion_tokens': 100,
        'prompt_tokens_details': {'cached_tokens': 11520},
        'cache_creation_input_tokens': 0,
        'completion_tokens_details': {'reasoning_tokens': 27},
      };
      final result = extractUsageRawData(usage);
      expect(result.inputTotal, 13261);
      expect(result.outputTotal, 100);
      expect(result.cacheRead, 11520);
      expect(result.cacheWrite, 0);
      expect(result.reasoning, 27);
    });

    test('OpenRouter-style raw map with input_tokens/output_tokens', () {
      final usage = {
        'input_tokens': 5000,
        'output_tokens': 200,
        'input_tokens_details': {'cached_tokens': 3000},
        'completion_tokens_details': {'reasoning_tokens': 50},
      };
      final result = extractUsageRawData(usage);
      expect(result.inputTotal, 5000);
      expect(result.outputTotal, 200);
      expect(result.cacheRead, 3000);
      expect(result.cacheWrite, 0);
      expect(result.reasoning, 50);
    });

    test('empty map returns zeros', () {
      final result = extractUsageRawData(const {});
      expect(result.inputTotal, 0);
      expect(result.outputTotal, 0);
      expect(result.cacheRead, 0);
      expect(result.cacheWrite, 0);
      expect(result.reasoning, 0);
    });

    test('null rawUsage returns zeros', () {
      final result = extractUsageRawData(null);
      expect(result.inputTotal, 0);
      expect(result.outputTotal, 0);
      expect(result.cacheRead, 0);
      expect(result.cacheWrite, 0);
      expect(result.reasoning, 0);
    });

    test('non-map rawUsage returns zeros', () {
      final result = extractUsageRawData('not a map');
      expect(result.inputTotal, 0);
      expect(result.outputTotal, 0);
      expect(result.cacheRead, 0);
      expect(result.cacheWrite, 0);
      expect(result.reasoning, 0);
    });

    test('string token values are parsed safely', () {
      final usage = {
        'prompt_tokens': '1000',
        'completion_tokens': '200',
        'prompt_tokens_details': {'cached_tokens': '500'},
        'completion_tokens_details': {'reasoning_tokens': '30'},
      };
      final result = extractUsageRawData(usage);
      expect(result.inputTotal, 1000);
      expect(result.outputTotal, 200);
      expect(result.cacheRead, 500);
      expect(result.reasoning, 30);
    });

    test('OpenAI chat cached_tokens sets cacheIncludedInInput true', () {
      final usage = {
        'prompt_tokens': 1000,
        'completion_tokens': 200,
        'prompt_tokens_details': {'cached_tokens': 500},
      };
      final result = extractUsageRawData(usage);
      expect(result.cacheIncludedInInput, true);
    });

    test('DeepSeek prompt_cache_hit_tokens sets cacheIncludedInInput true', () {
      final usage = {
        'prompt_tokens': 1000,
        'completion_tokens': 200,
        'prompt_cache_hit_tokens': 500,
      };
      final result = extractUsageRawData(usage);
      expect(result.cacheIncludedInInput, true);
    });

    test(
      'Anthropic cache_read_input_tokens sets cacheIncludedInInput false',
      () {
        final usage = {
          'prompt_tokens': 1000,
          'completion_tokens': 200,
          'cache_read_input_tokens': 500,
          'cache_creation_input_tokens': 100,
        };
        final result = extractUsageRawData(usage);
        expect(result.cacheIncludedInInput, false);
      },
    );

    test('empty raw sets cacheIncludedInInput false', () {
      final result = extractUsageRawData(const {});
      expect(result.cacheIncludedInInput, false);
    });
  });
}
