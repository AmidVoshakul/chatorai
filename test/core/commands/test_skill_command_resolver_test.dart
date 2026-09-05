import 'package:chatorai/core/commands/skill_command_resolver.dart';
import 'package:chatorai/core/skills/skill_info.dart';
import 'package:test/test.dart';

void main() {
  group('SkillCommandResolver', () {
    const skill = SkillInfo(
      name: 'test-skill',
      description: 'Test',
      directory: '/tmp/test-skill',
      content: 'Hello \$1',
    );

    test('resolve with empty args returns header', () {
      final result = SkillCommandResolver.resolve(skill, '');
      expect(result, '**Loaded skill: test-skill**\n\nHello \$1');
    });

    test('resolve with args renders template', () {
      final result = SkillCommandResolver.resolve(skill, 'world');
      expect(result, 'Hello world');
    });

    test('render delegates to SkillTemplateRenderer', () {
      final result = SkillCommandResolver.render('Hi \$1', 'there');
      expect(result, 'Hi there');
    });
  });
}
