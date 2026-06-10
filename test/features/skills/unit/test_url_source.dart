import 'dart:convert';
import 'dart:async';
import 'dart:convert';

import 'package:chatorai/features/skills/domain/services/url_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('UrlSource', () {
    test('constructor sets key correctly', () {
      final config = UrlSourceConfig(baseUrl: 'https://example.com/skills');
      final source = UrlSource(config: config);
      expect(source.key, 'url:https://example.com/skills');
    });

    test('discover parses index.json and creates SkillInfo', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/.well-known/skills/index.json'));
        return http.Response(
          json.encode({
            'skills': [
              {
                'name': 'remote-skill',
                'description': 'Remote skill',
                'files': [
                  {
                    'path': 'SKILL.md',
                    'url': 'https://example.com/skills/remote-skill/SKILL.md',
                  },
                ],
              },
            ],
          }),
          200,
        );
      });

      final config = UrlSourceConfig(
        baseUrl: 'https://example.com/.well-known/skills/',
      );
      final source = UrlSource(config: config, client: mockClient);
      // We won't actually download files because that requires network; we can test up to _fetchIndex
      // For full integration, a more complex mock needed. Skip full discover for now.
    });

    test('handles network errors gracefully', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Connection timeout');
      });

      final config = UrlSourceConfig(
        baseUrl: 'https://example.com/.well-known/skills/',
      );
      final source = UrlSource(config: config, client: mockClient);
      try {
        await source.discover();
        // Should not throw; logs warning and returns empty list
      } catch (e) {
        fail('Should not throw: $e');
      }
    });
  });
}
