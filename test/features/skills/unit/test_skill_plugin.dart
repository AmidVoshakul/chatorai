import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:chatorai/features/skills/domain/services/skill_plugin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillPlugin', () {
    test('plugin has required properties', () {
      final plugin = TestSkillPlugin();

      expect(plugin.id, isNotEmpty);
      expect(plugin.name, isNotEmpty);
      expect(plugin.description, isNotEmpty);
      expect(plugin.skills, isList);
    });

    test('plugin skills are accessible', () {
      final plugin = TestSkillPlugin();

      expect(plugin.skills.length, 2);
      expect(plugin.skills[0].name, 'builtin-skill-1');
      expect(plugin.skills[1].name, 'builtin-skill-2');
    });

    test('initialize method can be overridden', () async {
      final plugin = TestSkillPlugin();
      expect(plugin.initCalled, isFalse);

      await plugin.initialize();

      expect(plugin.initCalled, isTrue);
    });

    test('multiple plugins can have different IDs', () {
      final plugin1 = TestSkillPlugin(id: 'plugin-1');
      final plugin2 = TestSkillPlugin(id: 'plugin-2');

      expect(plugin1.id, isNot(equals(plugin2.id)));
    });

    test('plugin skills are immutable', () {
      final plugin = TestSkillPlugin();
      final skills = plugin.skills;

      // Verify the list is unmodifiable
      expect(
        () => skills.add(
          SkillInfo(
            name: 'new',
            description: 'new',
            directory: '/new',
            content: '',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('plugin can provide empty skills list', () {
      final plugin = EmptySkillPlugin();

      expect(plugin.skills, isEmpty);
    });

    test('plugin ID uniqueness for registration', () {
      final plugins = <SkillPlugin>[
        TestSkillPlugin(id: 'plugin-a'),
        TestSkillPlugin(id: 'plugin-b'),
        TestSkillPlugin(id: 'plugin-c'),
      ];

      final ids = plugins.map((p) => p.id).toList();
      final uniqueIds = ids.toSet();

      expect(ids.length, uniqueIds.length);
    });
  });
}

/// Test implementation of SkillPlugin
class TestSkillPlugin extends SkillPlugin {
  @override
  final String id;

  @override
  final String name;

  @override
  final String description;

  @override
  final List<SkillInfo> skills;

  bool initCalled = false;

  TestSkillPlugin({
    this.id = 'test-plugin',
    this.name = 'Test Plugin',
    this.description = 'A test plugin for unit testing',
    List<SkillInfo>? skills,
  }) : skills =
           skills ??
           const [
             SkillInfo(
               name: 'builtin-skill-1',
               description: 'First built-in skill',
               directory: '/builtin/skill1',
               content: '# Skill 1',
             ),
             SkillInfo(
               name: 'builtin-skill-2',
               description: 'Second built-in skill',
               directory: '/builtin/skill2',
               content: '# Skill 2',
             ),
           ];

  @override
  Future<void> initialize() async {
    initCalled = true;
  }
}

/// Plugin that provides no skills
class EmptySkillPlugin extends SkillPlugin {
  @override
  final String id = 'empty-plugin';

  @override
  final String name = 'Empty Plugin';

  @override
  final String description = 'Provides no skills';

  @override
  final List<SkillInfo> skills = const [];
}
