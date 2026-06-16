import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/llm/catalog/providers/built_in_providers.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

void main() {
  group('builtInProviders', () {
    final providers = builtInProviders();

    test('returns a non-empty list of providers', () {
      expect(providers, isNotEmpty);
    });

    test('contains openrouter, kilo, and nvidia providers', () {
      final ids = providers.map((p) => p.id).toList();
      expect(ids, contains('openrouter'));
      expect(ids, contains('kilo'));
      expect(ids, contains('nvidia'));
    });

    test('all providers have unique IDs', () {
      final ids = providers.map((p) => p.id).toList();
      final uniqueIds = ids.toSet();
      expect(uniqueIds.length, ids.length);
    });
  });

  group('OpenRouter provider', () {
    final openrouter = builtInProviders().firstWhere(
      (p) => p.id == 'openrouter',
    );

    test('has correct base configuration', () {
      expect(openrouter.name, 'OpenRouter');
      expect(openrouter.baseUrl, 'https://openrouter.ai/api/v1');
      expect(openrouter.sdk, 'openai-compatible');
    });

    test('is enabled by default', () {
      expect(openrouter.enabled, isTrue);
    });

    test('has correct auth configuration', () {
      expect(openrouter.auth.type, isNotNull);
    });
  });

  group('Kilo AI provider', () {
    final kilo = builtInProviders().firstWhere((p) => p.id == 'kilo');

    test('has correct base configuration', () {
      expect(kilo.name, 'Kilo AI');
      expect(kilo.baseUrl, 'https://api.kilo.ai/api/gateway');
      expect(kilo.sdk, 'openai-compatible');
    });

    test('is disabled by default', () {
      expect(kilo.enabled, isFalse);
    });

    test('has correct auth configuration', () {
      expect(kilo.auth.type, isNotNull);
    });
  });

  group('Nvidia NIM provider', () {
    final nvidia = builtInProviders().firstWhere((p) => p.id == 'nvidia');

    test('has correct base configuration', () {
      expect(nvidia.name, 'Nvidia NIM');
      expect(nvidia.baseUrl, 'https://integrate.api.nvidia.com/v1');
      expect(nvidia.sdk, 'openai-compatible');
    });

    test('is disabled by default', () {
      expect(nvidia.enabled, isFalse);
    });

    test('has correct auth configuration', () {
      expect(nvidia.auth.type, isNotNull);
    });
  });
}
