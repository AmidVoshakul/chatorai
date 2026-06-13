import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:chatorai/features/skills/domain/services/skill_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillCache', () {
    late SkillCache cache;
    final skill1 = SkillInfo(
      name: 'skill1',
      description: 'Description 1',
      directory: '/dir1',
      content: 'Content 1',
    );
    final skill2 = SkillInfo(
      name: 'skill2',
      description: 'Description 2',
      directory: '/dir2',
      content: 'Content 2',
    );
    final skill3 = SkillInfo(
      name: 'skill3',
      description: 'Description 3',
      directory: '/dir3',
      content: 'Content 3',
    );

    setUp(() {
      cache = SkillCache();
    });

    group('set and get', () {
      test('set stores skills for a source', () {
        cache.set('source1', [skill1, skill2]);

        final result = cache.get('source1');
        expect(result, isNotNull);
        expect(result!.length, 2);
        expect(result, containsAll([skill1, skill2]));
      });

      test('get returns null for unknown source', () {
        final result = cache.get('unknown');
        expect(result, isNull);
      });

      test('set replaces existing entry for same source', () {
        cache.set('source1', [skill1]);
        cache.set('source1', [skill2, skill3]);

        final result = cache.get('source1');
        expect(result!.length, 2);
        expect(result, contains(skill2));
        expect(result, contains(skill3));
        expect(result, isNot(contains(skill1)));
      });

      test('stored lists are immutable', () {
        cache.set('source1', [skill1, skill2]);

        final result = cache.get('source1');
        expect(() => result!.add(skill3), throwsUnsupportedError);
      });
    });

    group('has', () {
      test('returns true for cached source', () {
        cache.set('source1', [skill1]);
        expect(cache.has('source1'), isTrue);
      });

      test('returns false for uncached source', () {
        expect(cache.has('source1'), isFalse);
      });
    });

    group('removeSource', () {
      test('removes and returns cached skills', () {
        cache.set('source1', [skill1, skill2]);

        final removed = cache.removeSource('source1');

        expect(removed, isNotNull);
        expect(removed!.length, 2);
        expect(removed, containsAll([skill1, skill2]));
        expect(cache.has('source1'), isFalse);
      });

      test('returns null for unknown source', () {
        final removed = cache.removeSource('unknown');
        expect(removed, isNull);
      });

      test('does not affect other sources', () {
        cache.set('source1', [skill1]);
        cache.set('source2', [skill2, skill3]);

        cache.removeSource('source1');

        expect(cache.has('source1'), isFalse);
        expect(cache.has('source2'), isTrue);
        expect(cache.get('source2')!.length, 2);
      });
    });

    group('clear', () {
      test('removes all cached sources', () {
        cache.set('source1', [skill1]);
        cache.set('source2', [skill2]);
        cache.set('source3', [skill3]);

        cache.clear();

        expect(cache.sourceCount, 0);
        expect(cache.has('source1'), isFalse);
        expect(cache.has('source2'), isFalse);
        expect(cache.has('source3'), isFalse);
      });
    });

    group('sourceCount', () {
      test('returns number of cached sources', () {
        expect(cache.sourceCount, 0);

        cache.set('source1', [skill1]);
        expect(cache.sourceCount, 1);

        cache.set('source2', [skill2]);
        expect(cache.sourceCount, 2);

        cache.set('source3', [skill3]);
        expect(cache.sourceCount, 3);

        cache.removeSource('source2');
        expect(cache.sourceCount, 2);
      });

      test('does not count same source multiple times', () {
        cache.set('source1', [skill1]);
        cache.set('source1', [skill2]); // Replace

        expect(cache.sourceCount, 1);
      });
    });

    group('immutability', () {
      test('cached lists cannot be modified from outside', () {
        cache.set('source1', [skill1, skill2]);

        final list = cache.get('source1');
        expect(() => list!.clear(), throwsUnsupportedError);
        expect(() => list!.add(skill3), throwsUnsupportedError);
      });
    });

    group('edge cases', () {
      test('handles empty skill lists', () {
        cache.set('source1', []);

        final result = cache.get('source1');
        expect(result, isNotNull);
        expect(result!.isEmpty, isTrue);
      });

      test('handles null skills gracefully', () {
        // set doesn't accept null, but let's verify we can't set null
        expect(
          () => cache.set('source1', null as List<SkillInfo>),
          throwsA(isA<TypeError>()),
        );
      });

      test('multiple sources with same skills', () {
        final sameSkill = SkillInfo(
          name: 'shared',
          description: 'Shared skill',
          directory: '/dir1',
          content: '',
        );
        cache.set('source1', [sameSkill]);
        cache.set('source2', [sameSkill]);

        expect(cache.sourceCount, 2);
        expect(cache.get('source1')!.first.name, 'shared');
        expect(cache.get('source2')!.first.name, 'shared');
      });
    });
  });
}
