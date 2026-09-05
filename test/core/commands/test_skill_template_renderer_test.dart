import 'package:chatorai/core/commands/skill_template_renderer.dart';
import 'package:test/test.dart';

void main() {
  group('SkillTemplateRenderer', () {
    test('substitutes \$1 and last arg gets remaining', () {
      const template = 'Hello \$1, you said \$2';
      final result = SkillTemplateRenderer.render(template, 'world foo bar');
      // \$1 = world, \$2 (last) = foo bar
      expect(result, 'Hello world, you said foo bar');
    });

    test('replaces \$ARGUMENTS with raw arguments', () {
      const template = 'Args: \$ARGUMENTS';
      final result = SkillTemplateRenderer.render(template, 'a b c');
      expect(result, 'Args: a b c');
    });

    test('handles quoted arguments', () {
      const template = 'First \$1 second \$2';
      final result = SkillTemplateRenderer.render(
        template,
        '"hello world" foo',
      );
      expect(result, 'First hello world second foo');
    });

    test('appends arguments when no placeholders', () {
      const template = 'Base content';
      final result = SkillTemplateRenderer.render(template, 'extra args');
      expect(result, 'Base content\n\nextra args');
    });

    test('returns template when no args and no placeholders', () {
      const template = 'Base content';
      final result = SkillTemplateRenderer.render(template, '');
      expect(result, 'Base content');
    });

    test('handles missing args as empty strings', () {
      const template = 'A \$1 B \$2 C \$3';
      final result = SkillTemplateRenderer.render(template, 'onlyOne');
      // \$1 = onlyOne, \$2 = "", \$3 (last) = "" -> trimmed, no trailing space
      expect(result, 'A onlyOne B  C');
    });

    test('handles [Image N] placeholder in args', () {
      const template = 'Image \$1';
      final result = SkillTemplateRenderer.render(
        template,
        '[Image 1] some text',
      );
      // \$1 is last placeholder, consumes all remaining args
      expect(result, 'Image [Image 1] some text');
    });

    test('trims result', () {
      const template = '  content \$1  ';
      final result = SkillTemplateRenderer.render(template, 'arg');
      expect(result, 'content arg');
    });
  });
}
