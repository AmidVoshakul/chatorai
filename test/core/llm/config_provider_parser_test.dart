import 'dart:io';

import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';
import 'package:chatorai/core/llm/providers/config_provider_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfigProviderParser', () {
    ProviderSectionConfig makeSection(Map<String, dynamic> json) =>
        ProviderSectionConfig.fromJson(json);

    test('parses openai-compatible provider with {env:VAR} apiKey', () {
      final parser = ConfigProviderParser(
        environment: {'OPENROUTER_API_KEY': 'live-key'},
      );
      final section = makeSection({
        'custom-openrouter': {
          'name': 'OpenRouter (custom)',
          'options': {
            'baseURL': 'https://openrouter.ai/api/v1',
            'apiKey': '{env:OPENROUTER_API_KEY}',
            'temperature': 0.1,
          },
          'models': {
            'openrouter/owl-alpha': {
              'name': 'Owl Alpha',
              'limit': {'context': 1048576, 'output': 262144},
            },
          },
        },
      });

      final providers = parser.parse(section);
      expect(providers, hasLength(1));
      final p = providers.single;
      expect(p.id, equals('custom-openrouter'));
      expect(p.name, equals('OpenRouter (custom)'));
      expect(p.sdk, equals('openai-compatible'));
      expect(p.baseUrl, equals('https://openrouter.ai/api/v1'));
      expect(p.auth.type, equals(AuthType.apiKey));
      expect(p.auth.apiKey, equals('live-key'));
      expect(p.models, hasLength(1));
      final m = p.models.single;
      expect(m.modelName, equals('openrouter/owl-alpha'));
      expect(m.displayName, equals('Owl Alpha'));
      expect(m.contextLength, equals(1048576));
      expect(m.defaultMaxTokens, equals(262144));
    });

    test('empty apiKey yields none auth and default baseUrl', () {
      final parser = const ConfigProviderParser();
      final section = makeSection({
        'local': {
          'models': {
            'm1': {'name': 'M1'},
          },
        },
      });
      final p = parser.parse(section).single;
      expect(p.auth.type, equals(AuthType.none));
      expect(p.baseUrl, equals('https://api.openai.com/v1'));
      expect(p.source, equals(ProviderSource.config));
    });

    test('"public" apiKey yields none auth', () {
      final parser = const ConfigProviderParser();
      final section = makeSection({
        'local': {
          'options': {'apiKey': 'public'},
          'models': {
            'm': {'name': 'M'},
          },
        },
      });
      final p = parser.parse(section).single;
      expect(p.auth.type, equals(AuthType.none));
    });

    test('plain literal apiKey is used as-is', () {
      final parser = const ConfigProviderParser();
      final section = makeSection({
        'p': {
          'options': {'apiKey': 'sk-literal'},
          'models': {
            'm': {'name': 'M'},
          },
        },
      });
      final p = parser.parse(section).single;
      expect(p.auth.type, equals(AuthType.apiKey));
      expect(p.auth.apiKey, equals('sk-literal'));
    });

    test('null section yields empty list', () {
      expect(const ConfigProviderParser().parse(null), isEmpty);
    });

    test('propagates temperature + extra into defaultBody', () {
      final parser = ConfigProviderParser(environment: {'K': 'v'});
      final section = makeSection({
        'p': {
          'options': {
            'baseURL': 'https://api.x/v1',
            'apiKey': '{env:K}',
            'temperature': 0.3,
            'top_p': 0.9,
          },
          'models': {
            'm': {'name': 'M'},
          },
        },
      });
      final p = parser.parse(section).single;
      expect(p.source, equals(ProviderSource.config));
      expect(p.defaultBody?['temperature'], equals(0.3));
      expect(p.defaultBody?['top_p'], equals(0.9));
    });

    test('{env:VAR} missing in env falls back to shell rc file', () {
      final dir = Directory.systemTemp.createTempSync('chatorai_rc_');
      final rc = File('${dir.path}/.profile');
      rc.writeAsStringSync('MY_RC_KEY=rc-secret\n');
      final parser = ConfigProviderParser(
        environment: {},
        homeDirectory: dir.path,
      );
      final providers = parser.parse(
        makeSection({
          'p': {
            'options': {
              'apiKey': '{env:MY_RC_KEY}',
              'baseURL': 'https://api.x/v1',
            },
            'models': {
              'm': {'name': 'M'},
            },
          },
        }),
      );
      final p = providers.single;
      expect(p.auth.type, equals(AuthType.apiKey));
      expect(p.auth.apiKey, equals('rc-secret'));
      dir.deleteSync(recursive: true);
    });

    test('rc fallback handles unquoted values', () {
      final dir = Directory.systemTemp.createTempSync('chatorai_rc_');
      final rc = File('${dir.path}/.profile');
      rc.writeAsStringSync('MY_PLAIN_KEY=plain-value\n');
      final parser = ConfigProviderParser(
        environment: {},
        homeDirectory: dir.path,
      );
      final providers = parser.parse(
        makeSection({
          'p': {
            'options': {
              'apiKey': '{env:MY_PLAIN_KEY}',
              'baseURL': 'https://api.x/v1',
            },
            'models': {
              'm': {'name': 'M'},
            },
          },
        }),
      );
      expect(providers.single.auth.apiKey, equals('plain-value'));
      dir.deleteSync(recursive: true);
    });
  });
}
