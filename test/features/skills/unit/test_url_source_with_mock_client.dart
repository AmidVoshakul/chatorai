import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/features/skills/domain/sources/url_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('UrlSource with MockClient', () {
    test('downloads index and skill files successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/.well-known/skills/index.json')) {
          return http.Response(
            json.encode({
              'skills': [
                {
                  'name': 'remote',
                  'description': 'Remote skill',
                  'files': [
                    {
                      'path': 'SKILL.md',
                      'url': 'https://example.com/skills/remote/SKILL.md',
                    },
                  ],
                },
              ],
            }),
            200,
          );
        } else if (request.url.path.endsWith('/remote/SKILL.md')) {
          return http.Response('# Remote Skill\n\nContent', 200);
        }
        return http.Response('Not found', 404);
      });

      final config = UrlSourceConfig(
        baseUrl: 'https://example.com/.well-known/skills/',
        cacheTtl: const Duration(hours: 1),
      );
      final source = UrlSource(config: config, client: mockClient);
      final skills = await source.discover();

      expect(skills, hasLength(1));
      expect(skills.first.name, 'remote');
      expect(skills.first.description, 'Remote skill');
      expect(skills.first.content, contains('# Remote Skill'));
    });

    test('handles missing SKILL.md in files', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/.well-known/skills/index.json')) {
          return http.Response(
            json.encode({
              'skills': [
                {
                  'name': 'bad',
                  'description': 'No SKILL.md',
                  'files': [
                    {
                      'path': 'README.md',
                      'url': 'https://example.com/bad/README.md',
                    },
                  ],
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final config = UrlSourceConfig(
        baseUrl: 'https://example.com/.well-known/skills/',
      );
      final source = UrlSource(config: config, client: mockClient);
      final skills = await source.discover();

      expect(skills, isEmpty);
    });
  });
}
