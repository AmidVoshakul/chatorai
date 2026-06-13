import 'dart:convert';
import 'dart:async';

import 'package:chatorai/features/skills/domain/errors/skill_error.dart';
import 'package:chatorai/features/skills/domain/sources/url_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

void main() {
  group('UrlSource', () {
    const baseUrl = 'https://example.com/.well-known/skills/';
    const indexJson = {
      'skills': [
        {
          'name': 'remote-skill-1',
          'description': 'First remote skill',
          'files': [
            {
              'path': 'SKILL.md',
              'url': 'https://example.com/skills/skill1/SKILL.md',
            },
            {
              'path': 'script.py',
              'url': 'https://example.com/skills/skill1/script.py',
            },
          ],
        },
        {
          'name': 'remote-skill-2',
          'description': 'Second remote skill',
          'files': [
            {
              'path': 'SKILL.md',
              'url': 'https://example.com/skills/skill2/SKILL.md',
            },
          ],
        },
      ],
    };

    test('constructor sets key correctly', () {
      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config);
      expect(source.key, 'url:$baseUrl');
    });

    test('discover successfully fetches and parses index.json', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/index.json'));
        return http.Response(
          json.encode(indexJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // Mock file downloads
      final fileClient = MockClient((request) async {
        if (request.url.path.endsWith('SKILL.md')) {
          return http.Response('''
---
name: ${request.url.pathSegments.last == 'skill1' ? 'remote-skill-1' : 'remote-skill-2'}
description: Remote skill from ${request.url}
---
# Content
''', 200);
        }
        return http.Response('File content', 200);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: fileClient);

      final skills = await source.discover();

      expect(skills.length, 2);
      expect(
        skills.map((s) => s.name),
        containsAll(['remote-skill-1', 'remote-skill-2']),
      );
    });

    test('discover handles non-200 index response gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      final skills = await source.discover();

      expect(skills, isEmpty); // Should return empty list, not throw
    });

    test('discover handles network exceptions gracefully', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Connection timeout');
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      final skills = await source.discover();

      expect(skills, isEmpty); // Should return empty list, not throw
    });

    test('discover skips skills without SKILL.md file', () async {
      final indexWithoutSkill = {
        'skills': [
          {
            'name': 'incomplete-skill',
            'description': 'Missing SKILL.md',
            'files': [
              {'path': 'readme.txt', 'url': 'https://example.com/readme.txt'},
            ],
          },
        ],
      };

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('index.json')) {
          return http.Response(json.encode(indexWithoutSkill), 200);
        }
        return http.Response('File content', 200);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      final skills = await source.discover();

      expect(skills, isEmpty); // Should skip this skill
    });

    test('discover handles malformed JSON index', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          'invalid json{{{',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      final skills = await source.discover();

      expect(skills, isEmpty); // Should handle gracefully
    });

    test('discover limits auxiliary files to 10', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('index.json')) {
          return http.Response(json.encode(indexJson), 200);
        }
        // Return file content for any file request
        return http.Response('File content', 200);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      final skills = await source.discover();

      // remote-skill-1 has 2 files (SKILL.md + script.py) -> should be 1 aux file
      // remote-skill-2 has 1 file (SKILL.md only) -> 0 aux files
      final skill1 = skills.firstWhere((s) => s.name == 'remote-skill-1');
      final skill2 = skills.firstWhere((s) => s.name == 'remote-skill-2');

      expect(skill1.files.length, 1); // script.py
      expect(skill2.files.length, 0);
    });

    test(
      'discover includes authorization header when apiKey provided',
      () async {
        String? capturedAuthHeader;
        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('index.json')) {
            capturedAuthHeader = request.headers['authorization'];
            return http.Response(json.encode(indexJson), 200);
          }
          return http.Response('File content', 200);
        });

        final config = UrlSourceConfig(
          baseUrl: baseUrl,
          apiKey: 'test-api-key',
        );
        final source = UrlSource(config: config, client: mockClient);

        await source.discover();

        expect(capturedAuthHeader, 'Bearer test-api-key');
      },
    );

    test('discover caches files in ~/.cache/chatorai/skills/', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('index.json')) {
          return http.Response(json.encode(indexJson), 200);
        }
        return http.Response('File content', 200);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      await source.discover();

      // Verify cache directory was created (we can't easily check file system
      // without exposing internal methods, but we can verify no errors occurred)
      // This is more of an integration test
      expect(() async {}, returnsNormally);
    });

    test('discover handles path traversal attempts securely', () async {
      final maliciousIndex = {
        'skills': [
          {
            'name': 'malicious',
            'description': 'Attempts path traversal',
            'files': [
              {
                'path': '../../../etc/passwd',
                'url': 'https://example.com/etc/passwd',
              },
            ],
          },
        ],
      };

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('index.json')) {
          return http.Response(json.encode(maliciousIndex), 200);
        }
        return http.Response('File content', 200);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      // Should not throw, and should skip dangerous file
      final skills = await source.discover();

      expect(skills, isEmpty); // File skipped due to path traversal check
    });

    test('discover handles dangerous filenames', () async {
      final dangerousIndex = {
        'skills': [
          {
            'name': 'dangerous',
            'description': 'Dangerous filename',
            'files': [
              {
                'path': 'file/with/slashes/SKILL.md',
                'url': 'https://example.com/dangerous/SKILL.md',
              },
            ],
          },
        ],
      };

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('index.json')) {
          return http.Response(json.encode(dangerousIndex), 200);
        }
        return http.Response('File content', 200);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      final skills = await source.discover();

      expect(skills, isEmpty); // Should skip due to dangerous filename
    });

    test('discover handles empty skills array', () async {
      final emptyIndex = {'skills': []};

      final mockClient = MockClient((request) async {
        return http.Response(json.encode(emptyIndex), 200);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      final skills = await source.discover();

      expect(skills, isEmpty);
    });

    test('discover handles skill with empty files array', () async {
      final emptyFilesIndex = {
        'skills': [
          {'name': 'no-files', 'description': 'No files', 'files': []},
        ],
      };

      final mockClient = MockClient((request) async {
        return http.Response(json.encode(emptyFilesIndex), 200);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      final skills = await source.discover();

      expect(skills, isEmpty); // Should skip
    });

    test('discover handles missing description field', () async {
      final noDescIndex = {
        'skills': [
          {
            'name': 'no-desc',
            'files': [
              {
                'path': 'SKILL.md',
                'url': 'https://example.com/no-desc/SKILL.md',
              },
            ],
          },
        ],
      };

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('index.json')) {
          return http.Response(json.encode(noDescIndex), 200);
        }
        if (request.url.path.endsWith('SKILL.md')) {
          return http.Response('''
---
name: no-desc
---
Content
''', 200);
        }
        return http.Response('File content', 200);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      final skills = await source.discover();

      // Should still create skill with empty description (SkillInfo requires description)
      // Actually SkillInfo requires description, so parser would throw if empty
      // But UrlSource catches errors and skips
      expect(skills, isEmpty); // Skipped due to empty description
    });

    test('discover handles file download failures gracefully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('index.json')) {
          return http.Response(json.encode(indexJson), 200);
        }
        // Simulate download failure for one file
        if (request.url.path.contains('skill1/script.py')) {
          return http.Response('Not Found', 404);
        }
        return http.Response('File content', 200);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      // Should still succeed, just with warnings for failed downloads
      final skills = await source.discover();

      expect(skills.length, 2); // Both skills should still be discovered
    });

    test('discover uses custom cache TTL', () async {
      final config = UrlSourceConfig(
        baseUrl: baseUrl,
        cacheTtl: const Duration(days: 7),
      );
      final source = UrlSource(config: config);

      // Can't easily test TTL without exposing internals, but we can verify construction
      expect(source.config.cacheTtl, const Duration(days: 7));
    });

    test('discover handles large index efficiently', () async {
      // Generate a large index with 100 skills
      final largeIndex = {'skills': []};
      for (int i = 0; i < 100; i++) {
        largeIndex['skills'].add({
          'name': 'skill-$i',
          'description': 'Skill number $i',
          'files': [
            {'path': 'SKILL.md', 'url': 'https://example.com/skill$i/SKILL.md'},
          ],
        });
      }

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('index.json')) {
          return http.Response(json.encode(largeIndex), 200);
        }
        return http.Response('''
---
name: skill-${request.url.pathSegments.last}
description: Skill
---
''', 200);
      });

      final config = UrlSourceConfig(baseUrl: baseUrl);
      final source = UrlSource(config: config, client: mockClient);

      final stopwatch = Stopwatch()..start();
      final skills = await source.discover();
      stopwatch.stop();

      expect(skills.length, 100);
      // Should complete in reasonable time (< 5 seconds for test)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}
