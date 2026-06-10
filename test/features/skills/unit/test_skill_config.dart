import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillConfig', () {
    test('default constructor creates empty lists', () {
      final config = SkillConfig();

      expect(config.paths, isEmpty);
      expect(config.urls, isEmpty);
    });

    test('fromJson parses paths correctly', () {
      final json = {
        'paths': ['/path1', '/path2', '/path3'],
        'urls': [],
      };

      final config = SkillConfig.fromJson(json);

      expect(config.paths, ['/path1', '/path2', '/path3']);
      expect(config.urls, isEmpty);
    });

    test('fromJson parses urls as strings', () {
      final json = {
        'paths': [],
        'urls': ['https://example.com/skills'],
      };

      final config = SkillConfig.fromJson(json);

      expect(config.urls.length, 1);
      expect(config.urls.first['url'], 'https://example.com/skills');
    });

    test('fromJson parses urls as maps with full config', () {
      final json = {
        'paths': [],
        'urls': [
          {
            'url': 'https://example.com/skills',
            'cache_ttl': 7200,
            'api_key': 'secret123',
          },
        ],
      };

      final config = SkillConfig.fromJson(json);

      expect(config.urls.length, 1);
      expect(config.urls.first['url'], 'https://example.com/skills');
      expect(config.urls.first['cache_ttl'], 7200);
      expect(config.urls.first['api_key'], 'secret123');
    });

    test('fromJson handles mixed string and map url entries', () {
      final json = {
        'paths': [],
        'urls': [
          'https://simple.com/skills',
          {'url': 'https://full.com/skills', 'cache_ttl': 3600},
        ],
      };

      final config = SkillConfig.fromJson(json);

      expect(config.urls.length, 2);
      expect(config.urls.first['url'], 'https://simple.com/skills');
      expect(config.urls.last['url'], 'https://full.com/skills');
    });

    test('fromJson handles null or missing fields', () {
      final json1 = <String, dynamic>{};
      final config1 = SkillConfig.fromJson(json1);
      expect(config1.paths, isEmpty);
      expect(config1.urls, isEmpty);

      final json2 = <String, dynamic>{'paths': null};
      final config2 = SkillConfig.fromJson(json2);
      expect(config2.paths, isEmpty);

      final json3 = <String, dynamic>{'urls': null};
      final config3 = SkillConfig.fromJson(json3);
      expect(config3.urls, isEmpty);
    });

    test('fromJson ignores non-string items in paths', () {
      final json = <String, dynamic>{
        'paths': ['/valid', 123, null],
        'urls': [],
      };

      // The cast<String>() will throw if non-string, so we expect a TypeError
      expect(() => SkillConfig.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('toJson produces correct output with paths', () {
      final config = SkillConfig(paths: ['/path1', '/path2']);

      final json = config.toJson();

      expect(json['paths'], ['/path1', '/path2']);
      expect(json.containsKey('urls'), isFalse);
    });

    test('toJson produces correct output with urls', () {
      final config = SkillConfig(
        paths: [],
        urls: [
          {'url': 'https://example.com/skills'},
        ],
      );

      final json = config.toJson();

      expect(json['urls'], isA<List>());
      expect((json['urls'] as List).first['url'], 'https://example.com/skills');
    });

    test('toJson omits empty paths and urls', () {
      final config = SkillConfig();

      final json = config.toJson();

      expect(json.containsKey('paths'), isFalse);
      expect(json.containsKey('urls'), isFalse);
    });

    test('toJson roundtrip preserves data', () {
      final original = SkillConfig(
        paths: ['/path1', '/path2'],
        urls: [
          {'url': 'https://example.com', 'cache_ttl': 3600},
        ],
      );

      final json = original.toJson();
      final restored = SkillConfig.fromJson(json);

      expect(restored.paths, original.paths);
      expect(restored.urls.length, original.urls.length);
      expect(restored.urls.first['url'], original.urls.first['url']);
    });

    test('ChatOrAIConfig includes SkillConfig correctly', () {
      final skillConfig = SkillConfig(paths: ['/skills']);
      final config = ChatOrAIConfig(
        version: 1,
        permission: {},
        skills: skillConfig,
      );

      final json = config.toJson();

      expect(json.containsKey('skills'), isTrue);
      expect((json['skills'] as Map)['paths'], ['/skills']);
    });

    test('ChatOrAIConfig fromJson parses skills section', () {
      final json = <String, dynamic>{
        'version': 1,
        'permission': {},
        'skills': <String, dynamic>{
          'paths': ['/custom/skills'],
          'urls': [
            {'url': 'https://remote.com/skills'},
          ],
        },
      };

      final config = ChatOrAIConfig.fromJson(json);

      expect(config.skills, isNotNull);
      expect(config.skills!.paths, ['/custom/skills']);
      expect(config.skills!.urls.length, 1);
    });

    test('ChatOrAIConfig handles missing skills section', () {
      final json = <String, dynamic>{'version': 1, 'permission': {}};

      final config = ChatOrAIConfig.fromJson(json);

      expect(config.skills, isNull);
    });
  });
}
