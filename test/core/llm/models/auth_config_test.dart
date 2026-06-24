import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/llm/models/auth_config.dart';

void main() {
  group('AuthConfig', () {
    test('apiKey factory creates correct config', () {
      final config = AuthConfig.apiKey(apiKey: 'sk-test123');
      expect(config.type, AuthType.apiKey);
      expect(config.apiKey, 'sk-test123');
      expect(config.apiKeyHeader, 'Authorization');
      expect(config.bearerPrefix, 'Bearer ');
    });

    test('apiKey factory with custom headers', () {
      final config = AuthConfig.apiKey(
        apiKey: 'test-key',
        apiKeyHeader: 'X-API-Key',
        bearerPrefix: '',
      );
      expect(config.apiKeyHeader, 'X-API-Key');
      expect(config.bearerPrefix, '');
    });

    test('none factory creates no-auth config', () {
      final config = AuthConfig.none();
      expect(config.type, AuthType.none);
      expect(config.apiKey, isNull);
    });

    test('buildHeaderValue returns correct format', () {
      final config = AuthConfig.apiKey(apiKey: 'sk-abc123');
      expect(config.buildHeaderValue(), 'Bearer sk-abc123');
    });

    test('buildHeaderValue returns null for none auth', () {
      final config = AuthConfig.none();
      expect(config.buildHeaderValue(), isNull);
    });

    test('buildHeaderValue returns null if apiKey is null', () {
      final config = AuthConfig.apiKey(
        apiKey: 'temp',
      ).copyWith(clearApiKey: true);
      expect(config.buildHeaderValue(), isNull);
    });

    test('copyWith modifies fields correctly', () {
      final original = AuthConfig.apiKey(apiKey: 'key1');
      final copied = original.copyWith(apiKey: 'key2');
      expect(copied.apiKey, 'key2');
      expect(copied.type, original.type);
      expect(copied.apiKeyHeader, original.apiKeyHeader);
    });

    test('equality works correctly', () {
      final config1 = AuthConfig.apiKey(apiKey: 'test');
      final config2 = AuthConfig.apiKey(apiKey: 'test');
      final config3 = AuthConfig.apiKey(apiKey: 'different');
      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('toJson and fromJson are symmetric', () {
      final original = AuthConfig.apiKey(
        apiKey: 'sk-12345',
        apiKeyHeader: 'X-API-Key',
        bearerPrefix: 'Token ',
      );
      final json = original.toJson();
      final restored = AuthConfig.fromJson(json);
      expect(restored, equals(original));
    });

    test('fromJson handles none type', () {
      final json = {'type': 'none'};
      final config = AuthConfig.fromJson(json);
      expect(config.type, AuthType.none);
      expect(config.apiKey, isNull);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = {'type': 'apiKey', 'apiKey': 'test-key'};
      final config = AuthConfig.fromJson(json);
      expect(config.apiKeyHeader, 'Authorization');
      expect(config.bearerPrefix, 'Bearer ');
    });

    test('toString does not expose apiKey', () {
      final config = AuthConfig.apiKey(apiKey: 'secret123');
      final str = config.toString();
      expect(str, contains('type: AuthType.apiKey'));
      expect(str, contains('apiKeyHeader: Authorization'));
      expect(str, isNot(contains('secret123')));
    });
  });
}
