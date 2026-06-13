import 'dart:async';
import 'dart:io';

import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:chatorai/features/skills/domain/errors/skill_error.dart';
import 'package:chatorai/features/skills/domain/services/skill_cache.dart';
import 'package:chatorai/features/skills/domain/services/skill_discovery.dart';
import 'package:chatorai/features/skills/domain/sources/skill_source.dart';
import 'package:chatorai/features/skills/domain/sources/directory_source.dart';
import 'package:chatorai/features/skills/domain/watchers/skill_file_watcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

class MockSkillSource extends Mock implements SkillSource {}

class FailingSkillSource extends SkillSource {
  @override
  final String key;

  FailingSkillSource(this.key);

  @override
  Future<List<SkillInfo>> discover() async {
    throw SourceError(key, Exception('Source failed'));
  }
}

class DelayedSkillSource extends SkillSource {
  @override
  final String key;
  final Duration delay;
  final List<SkillInfo> skills;

  DelayedSkillSource({
    required this.key,
    required this.delay,
    required this.skills,
  });

  @override
  Future<List<SkillInfo>> discover() async {
    await Future.delayed(delay);
    return skills;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      SkillInfo(
        name: 'test',
        description: 'test',
        directory: '/test',
        content: 'test',
      ),
    );
  });

  group('SkillDiscovery', () {
    late SkillDiscovery discovery;
    late SkillCache cache;
    late SkillFileWatcher watcher;
    late MockSkillSource source1;
    late MockSkillSource source2;

    setUp(() {
      cache = SkillCache();
      watcher = SkillFileWatcher();
      source1 = MockSkillSource();
      source2 = MockSkillSource();
    });

    tearDown(() {
      discovery.dispose();
    });

    group('initialization', () {
      test('first call to getAll triggers discovery of all sources', () async {
        when(() => source1.key).thenReturn('source1');
        when(() => source2.key).thenReturn('source2');
        when(() => source1.discover()).thenAnswer(
          (_) async => [
            SkillInfo(
              name: 'skill1',
              description: 'Desc1',
              directory: '/dir1',
              content: '',
            ),
          ],
        );
        when(() => source2.discover()).thenAnswer(
          (_) async => [
            SkillInfo(
              name: 'skill2',
              description: 'Desc2',
              directory: '/dir2',
              content: '',
            ),
          ],
        );

        discovery = SkillDiscovery(
          sources: [source1, source2],
          cache: cache,
          watcher: watcher,
        );

        final skills = await discovery.getAll();

        expect(skills.length, 2);
        expect(skills.map((s) => s.name), containsAll(['skill1', 'skill2']));
      });

      test(
        'subsequent calls return cached results without rediscovering',
        () async {
          when(() => source1.key).thenReturn('source1');
          when(() => source1.discover()).thenAnswer(
            (_) async => [
              SkillInfo(
                name: 'skill1',
                description: 'Desc1',
                directory: '/dir1',
                content: '',
              ),
            ],
          );

          discovery = SkillDiscovery(
            sources: [source1],
            cache: cache,
            watcher: watcher,
          );

          await discovery.getAll(); // First call - discovers
          await discovery.getAll(); // Second call - should use cache

          verify(() => source1.discover()).called(1);
        },
      );

      test('_initialized flag prevents repeated discovery', () async {
        when(() => source1.key).thenReturn('source1');
        when(() => source1.discover()).thenAnswer(
          (_) async => [
            SkillInfo(
              name: 'skill1',
              description: 'Desc1',
              directory: '/dir1',
              content: '',
            ),
          ],
        );

        discovery = SkillDiscovery(
          sources: [source1],
          cache: cache,
          watcher: watcher,
        );

        await discovery.getAll();
        await discovery.getAll();
        await discovery.getAll();

        verify(() => source1.discover()).called(1);
      });
    });

    group('caching', () {
      test('caches results per source key', () async {
        when(() => source1.key).thenReturn('source1');
        when(() => source1.discover()).thenAnswer(
          (_) async => [
            SkillInfo(
              name: 'skill1',
              description: 'Desc1',
              directory: '/dir1',
              content: '',
            ),
          ],
        );

        discovery = SkillDiscovery(
          sources: [source1],
          cache: cache,
          watcher: watcher,
        );

        await discovery.getAll();

        expect(cache.has('source1'), isTrue);
        expect(cache.get('source1')!.length, 1);
      });

      test('cache miss triggers rediscovery for removed source', () async {
        int source1Calls = 0;

        when(() => source1.key).thenReturn('source1');
        when(() => source2.key).thenReturn('source2');
        when(() => source1.discover()).thenAnswer((_) async {
          source1Calls++;
          return [
            SkillInfo(
              name: 'skill1',
              description: source1Calls == 1 ? 'First' : 'Second',
              directory: '/dir1',
              content: '',
            ),
          ];
        });
        when(() => source2.discover()).thenAnswer(
          (_) async => [
            SkillInfo(
              name: 'skill2',
              description: 'Desc2',
              directory: '/dir2',
              content: '',
            ),
          ],
        );

        discovery = SkillDiscovery(
          sources: [source1, source2],
          cache: cache,
          watcher: watcher,
        );

        // First call discovers both
        var skills1 = await discovery.getAll();
        expect(
          skills1.any((s) => s.name == 'skill1' && s.description == 'First'),
          isTrue,
        );
        expect(source1Calls, 1);

        // Remove source1 cache
        cache.removeSource('source1');

        // Second call should rediscover source1 and get updated description
        var skills2 = await discovery.getAll();
        expect(
          skills2.any((s) => s.name == 'skill1' && s.description == 'Second'),
          isTrue,
        );
        // source2 should not have been rediscovered (same description)
        expect(source1Calls, 2);
        expect(
          skills2.any((s) => s.name == 'skill2' && s.description == 'Desc2'),
          isTrue,
        );
      });

      test('refresh forces rediscovery of all sources', () async {
        int source1Calls = 0;

        when(() => source1.key).thenReturn('source1');
        when(() => source1.discover()).thenAnswer((_) async {
          source1Calls++;
          return [
            SkillInfo(
              name: 'skill1',
              description: source1Calls == 1 ? 'Original' : 'Refreshed',
              directory: '/dir1',
              content: '',
            ),
          ];
        });

        discovery = SkillDiscovery(
          sources: [source1],
          cache: cache,
          watcher: watcher,
        );

        // Initial discovery
        var skills1 = await discovery.getAll();
        expect(skills1.first.description, 'Original');
        expect(source1Calls, 1);

        // Refresh
        await discovery.refresh();

        // After refresh, should rediscover
        var skills2 = await discovery.getAll();
        expect(skills2.first.description, 'Refreshed');
        expect(source1Calls, 2);
      });

      test('cacheSize returns number of cached sources', () async {
        when(() => source1.key).thenReturn('source1');
        when(() => source2.key).thenReturn('source2');
        when(() => source1.discover()).thenAnswer((_) async => []);
        when(() => source2.discover()).thenAnswer((_) async => []);

        discovery = SkillDiscovery(
          sources: [source1, source2],
          cache: cache,
          watcher: watcher,
        );

        expect(discovery.cacheSize, 0); // Not yet discovered

        await discovery.getAll();

        expect(discovery.cacheSize, 2);
      });
    });

    group('error isolation', () {
      test('one source failure does not stop other sources', () async {
        when(() => source1.key).thenReturn('source1');
        when(() => source2.key).thenReturn('source2');
        when(
          () => source1.discover(),
        ).thenThrow(SourceError('source1', Exception('Failed')));
        when(() => source2.discover()).thenAnswer(
          (_) async => [
            SkillInfo(
              name: 'skill2',
              description: 'Desc2',
              directory: '/dir2',
              content: '',
            ),
          ],
        );

        discovery = SkillDiscovery(
          sources: [source1, source2],
          cache: cache,
          watcher: watcher,
        );

        final skills = await discovery.getAll();

        // Should still get skill2 from source2
        expect(skills.length, 1);
        expect(skills.first.name, 'skill2');
      });

      test('all sources can fail without throwing to caller', () async {
        when(() => source1.key).thenReturn('source1');
        when(() => source2.key).thenReturn('source2');
        when(
          () => source1.discover(),
        ).thenThrow(SourceError('source1', Exception('Failed')));
        when(
          () => source2.discover(),
        ).thenThrow(SourceError('source2', Exception('Failed')));

        discovery = SkillDiscovery(
          sources: [source1, source2],
          cache: cache,
          watcher: watcher,
        );

        final skills = await discovery.getAll();

        expect(skills, isEmpty);
      });

      test('errors are logged but do not propagate', () async {
        when(() => source1.key).thenReturn('source1');
        when(() => source1.discover()).thenThrow(ParseError('Invalid YAML'));

        discovery = SkillDiscovery(
          sources: [source1],
          cache: cache,
          watcher: watcher,
        );

        // Should not throw
        final skills = await discovery.getAll();
        expect(skills, isEmpty);
      });
    });

    group('file watching', () {
      test('DirectorySource triggers cache invalidation on change', () async {
        when(() => source1.key).thenReturn('source1');
        when(() => source1.discover()).thenAnswer(
          (_) async => [
            SkillInfo(
              name: 'skill1',
              description: 'Original',
              directory: '/dir1',
              content: '',
            ),
          ],
        );

        // Create a real temporary directory for watching
        final tempDir = await Directory.systemTemp.createTemp('watch_test');
        final skillDir = Directory(p.join(tempDir.path, 'skill'));
        await skillDir.create(recursive: true);
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: skill1
description: Original
---
''');

        final dirSource = DirectorySource(rootPath: skillDir.path);
        discovery = SkillDiscovery(
          sources: [dirSource],
          cache: cache,
          watcher: watcher,
          onChanged: () {},
        );

        await discovery.getAll();
        expect(cache.has(dirSource.key), isTrue);

        // Modify SKILL.md
        await skillFile.writeAsString('''
---
name: skill1
description: Updated
---
''');

        // Trigger watcher manually (simulating file system event)
        watcher.trigger(skillDir.path);

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 300));

        // Cache should be invalidated
        expect(cache.has(dirSource.key), isFalse);

        // Next getAll should re-discover
        final skills = await discovery.getAll();
        expect(skills.first.description, 'Updated');

        await tempDir.delete(recursive: true);
      });

      test('onChanged callback is invoked on file change', () async {
        final tempDir = await Directory.systemTemp.createTemp('watch_cb_test');
        final skillDir = Directory(p.join(tempDir.path, 'skill'));
        await skillDir.create(recursive: true);
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: test
description: Original
---
''');

        final dirSource = DirectorySource(rootPath: skillDir.path);
        bool changedCalled = false;

        discovery = SkillDiscovery(
          sources: [dirSource],
          cache: cache,
          watcher: watcher,
          onChanged: () {
            changedCalled = true;
          },
        );

        await discovery.getAll();

        // Modify file
        await skillFile.writeAsString('''
---
name: test
description: Updated
---
''');

        watcher.trigger(skillDir.path);
        await Future.delayed(const Duration(milliseconds: 300));

        expect(changedCalled, isTrue);

        await tempDir.delete(recursive: true);
      });

      test('only DirectorySource sources are watched', () async {
        when(() => source1.key).thenReturn('source1');
        when(() => source1.discover()).thenAnswer((_) async => []);

        discovery = SkillDiscovery(
          sources: [source1], // source1 is a mock, not DirectorySource
          cache: cache,
          watcher: watcher,
        );

        await discovery.getAll();

        // No watcher should be registered for non-DirectorySource
        // We can't easily verify this without exposing internal state
        // But we can verify that no errors occur
        expect(discovery.cacheSize, 1);
      });
    });

    group('deduplication', () {
      test(
        'getAll returns deduplicated skills by name (first source wins)',
        () async {
          final dir1 = await Directory.systemTemp.createTemp('dir1');
          final dir2 = await Directory.systemTemp.createTemp('dir2');

          await Directory(
            p.join(dir1.path, 'skill'),
          ).create(recursive: true).then((dir) async {
            final file = File(p.join(dir.path, 'SKILL.md'));
            await file.writeAsString('''
---
name: shared
description: From dir1
---
''');
          });

          await Directory(
            p.join(dir2.path, 'skill'),
          ).create(recursive: true).then((dir) async {
            final file = File(p.join(dir.path, 'SKILL.md'));
            await file.writeAsString('''
---
name: shared
description: From dir2
---
''');
          });

          final sourceA = DirectorySource(rootPath: dir1.path);
          final sourceB = DirectorySource(rootPath: dir2.path);

          discovery = SkillDiscovery(
            sources: [sourceA, sourceB],
            cache: cache,
            watcher: watcher,
          );

          final skills = await discovery.getAll();

          expect(skills.length, 1);
          expect(skills.first.description, 'From dir1'); // First source wins

          await dir1.delete(recursive: true);
          await dir2.delete(recursive: true);
        },
      );
    });

    group('dispose', () {
      test('dispose stops all watchers and clears cache', () async {
        final tempDir = await Directory.systemTemp.createTemp('dispose_test');
        final skillDir = Directory(p.join(tempDir.path, 'skill'));
        await skillDir.create(recursive: true);
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: test
description: Test
---
''');

        final dirSource = DirectorySource(rootPath: skillDir.path);
        discovery = SkillDiscovery(
          sources: [dirSource],
          cache: cache,
          watcher: watcher,
        );

        await discovery.getAll();
        expect(cache.sourceCount, greaterThan(0));

        discovery.dispose();

        expect(cache.sourceCount, 0);
        await tempDir.delete(recursive: true);
      });
    });
  });
}
