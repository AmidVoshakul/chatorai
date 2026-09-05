import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/core/llm/providers/config_provider_parser.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSecureStorage extends SecureStorageService {
  final Map<String, String> backing;

  _FakeSecureStorage(this.backing);

  @override
  Future<String?> read({required String key}) async => backing[key];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected call: ${invocation.memberName}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // ensureCatalogService caches a process-wide instance; isolate-per-file
    // execution keeps tests independent.
  });

  group('catalog warm (catalogInitializationProvider body)', () {
    test('completes with empty prefs and pre-cached key; command section in '
        'config does not break provider application', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = _FakeSecureStorage({
        // Real prefix used by preloadApiKeys for built-in providers.
        'catalog_provider_api_key_deepseek': 'test-key-123',
      });

      final service = ensureCatalogService(prefs, storage);
      await service.migrateFromLegacySettings();
      await service.preloadApiKeys();

      expect(service.getApiKeySync('deepseek'), 'test-key-123');

      // chatorai.json now carries a top-level `command` section; applying
      // config providers must ignore it and still parse the provider
      // section without throwing (regression for "error loading provider").
      const config = ChatOrAIConfig(
        version: 1,
        permission: {},
        command: CommandSectionConfig(
          commands: {'smoke': CommandConfigEntry(template: 'hello')},
        ),
        provider: ProviderSectionConfig(
          providers: {
            'custom-llm': ProviderEntryConfig(
              name: 'Custom LLM',
              options: ProviderOptionsConfig(
                baseURL: 'https://example.invalid/v1',
                apiKey: '{env:MISSING_VAR}',
              ),
            ),
          },
        ),
      );

      final parser = const ConfigProviderParser();
      final parsed = parser.parse(config.provider);
      expect(parsed, isNotEmpty);

      service.applyConfigProviders(parsed);
    });
  });
}
