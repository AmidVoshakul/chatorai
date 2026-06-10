import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillCache', () {
    test('mergeAll deduplicates by name', () {
      final all = [
        SkillInfo(name: 'a', description: '1', directory: '/a', content: ''),
        SkillInfo(name: 'a', description: '2', directory: '/b', content: ''),
        SkillInfo(name: 'b', description: '3', directory: '/c', content: ''),
      ];
      final cache = SkillCache();
      final merged = cache.mergeAll([all]);
      expect(merged.length, 2);
      expect(merged.map((s) => s.name), containsAll(['a', 'b']));
    });
  });
}
