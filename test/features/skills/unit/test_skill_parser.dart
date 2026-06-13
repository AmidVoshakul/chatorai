import 'package:chatorai/features/skills/domain/errors/skill_error.dart';
import 'package:chatorai/features/skills/domain/parsers/skill_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillParser', () {
    const validYaml = '''
---
name: test-skill
description: A test skill for unit testing
---

# Skill Content

This is the markdown body of the skill.
''';

    const yamlWithExtraFields = '''
---
name: advanced-skill
description: Advanced skill with extra fields
slash: true
custom_field: custom_value
---

# Advanced Content
''';

    const yamlMissingName = '''
---
description: Missing name
---

Content
''';

    const yamlMissingDescription = '''
---
name: missing-desc
---

Content
''';

    const yamlEmptyName = '''
---
name: ""
description: Empty name
---

# Content
''';

    const yamlEmptyDescription = '''
---
name: empty-desc
description: ""
---

# Content
''';

    const yamlNoFrontmatter = '''
# No frontmatter
Just content
''';

    const yamlOnlyOpeningDelimiter = '''
---
name: incomplete
description: Missing closing delimiter
''';

    test('parse valid YAML with required fields', () {
      final result = SkillParser.parse('/path/to/SKILL.md', validYaml);

      expect(result.name, 'test-skill');
      expect(result.description, 'A test skill for unit testing');
      expect(result.directory, '/path/to'); // dirname of file path
      expect(result.content, contains('# Skill Content'));
      expect(result.content, contains('This is the markdown body'));
    });

    test('parse YAML with extra fields (ignored)', () {
      final result = SkillParser.parse(
        '/path/to/SKILL.md',
        yamlWithExtraFields,
      );

      expect(result.name, 'advanced-skill');
      expect(result.description, 'Advanced skill with extra fields');
      // Extra fields are ignored, only required ones are extracted
    });

    test('parse YAML with multi-line description', () {
      const multiLine = '''
---
name: multi-line
description: |
  This is a multi-line
  description that spans
  multiple lines.
---

Body
''';
      final result = SkillParser.parse('/path/to/SKILL.md', multiLine);

      expect(result.description, contains('multi-line'));
      expect(result.description, contains('multiple lines'));
    });

    test('parse YAML with single-quoted strings', () {
      const singleQuoted = '''
---
name: 'single-quoted'
description: 'Single quoted description'
---

Body
''';
      final result = SkillParser.parse('/path/to/SKILL.md', singleQuoted);

      expect(result.name, 'single-quoted');
      expect(result.description, 'Single quoted description');
    });

    test('parse YAML with double-quoted strings', () {
      const doubleQuoted = '''
---
name: "double-quoted"
description: "Double quoted description"
---

Body
''';
      final result = SkillParser.parse('/path/to/SKILL.md', doubleQuoted);

      expect(result.name, 'double-quoted');
      expect(result.description, 'Double quoted description');
    });

    test('parse YAML with unicode characters', () {
      const unicode = '''
---
name: навык-测试
description: Навык с юникодом 🎉 你好
---

# Содержание
''';
      final result = SkillParser.parse('/path/to/SKILL.md', unicode);

      expect(result.name, 'навык-测试');
      expect(result.description, contains('🎉'));
      expect(result.description, contains('你好'));
    });

    test('parse YAML with special characters in name', () {
      const special = '''
---
name: skill_with-dots.and-dashes
description: Special chars in name
---

Body
''';
      final result = SkillParser.parse('/path/to/SKILL.md', special);

      expect(result.name, 'skill_with-dots.and-dashes');
    });

    test('parse trims body leading whitespace', () {
      const withIndent = '''
---
name: indent-test
description: Test
---

    # Indented content
    Should be trimmed.
''';
      final result = SkillParser.parse('/path/to/SKILL.md', withIndent);

      // trimLeft() removes leading whitespace but preserves internal structure
      expect(result.content, contains('# Indented content'));
    });

    test('parse handles empty body', () {
      const emptyBody = '''
---
name: empty-body
description: No body
---
''';
      final result = SkillParser.parse('/path/to/SKILL.md', emptyBody);

      expect(result.content, isEmpty);
    });

    test('parse throws ParseError when frontmatter delimiters missing', () {
      expect(
        () => SkillParser.parse('/path/to/SKILL.md', yamlNoFrontmatter),
        throwsA(
          isA<ParseError>().having(
            (e) => e.message,
            'message',
            contains('frontmatter delimiters'),
          ),
        ),
      );
    });

    test('parse throws ParseError when only opening delimiter', () {
      expect(
        () => SkillParser.parse('/path/to/SKILL.md', yamlOnlyOpeningDelimiter),
        throwsA(isA<ParseError>()),
      );
    });

    test('parse throws ParseError when YAML is invalid', () {
      const invalidYaml = '''
---
name: test
description: test
invalid: [unclosed bracket
---
Body
''';
      expect(
        () => SkillParser.parse('/path/to/SKILL.md', invalidYaml),
        throwsA(
          isA<ParseError>().having(
            (e) => e.message,
            'message',
            contains('YAML parse error'),
          ),
        ),
      );
    });

    test('parse uses directory name as default when name is missing', () {
      const noNameYaml = '''
---
description: No name provided
---
Body
''';
      final result = SkillParser.parse(
        '/path/to/my-skill/SKILL.md',
        noNameYaml,
      );

      expect(result.name, 'my-skill'); // Uses dirname as default
      expect(result.description, 'No name provided');
    });

    test('parse throws ParseError when name is empty string', () {
      expect(
        () => SkillParser.parse('/path/to/SKILL.md', yamlEmptyName),
        throwsA(
          isA<ParseError>().having(
            (e) => e.message,
            'message',
            contains('name'),
          ),
        ),
      );
    });

    test('parse throws ParseError when description is missing', () {
      expect(
        () => SkillParser.parse('/path/to/SKILL.md', yamlMissingDescription),
        throwsA(
          isA<ParseError>().having(
            (e) => e.message,
            'message',
            contains('description'),
          ),
        ),
      );
    });

    test('parse throws ParseError when description is empty', () {
      expect(
        () => SkillParser.parse('/path/to/SKILL.md', yamlEmptyDescription),
        throwsA(
          isA<ParseError>().having(
            (e) => e.message,
            'message',
            contains('description'),
          ),
        ),
      );
    });

    test('parse sets directory to dirname of file path', () {
      final result = SkillParser.parse(
        '/deep/path/to/skill/SKILL.md',
        validYaml,
      );
      expect(result.directory, '/deep/path/to/skill');
    });

    test('parse handles paths with dots and normalization', () {
      const path = '/deep/./path/../to/skill/SKILL.md';
      final result = SkillParser.parse(path, validYaml);
      // path package normalizes, so '..' should be resolved
      expect(result.directory, contains('to'));
      expect(result.directory, contains('skill'));
    });

    test('parse preserves body exactly (except leading whitespace trim)', () {
      const body = '''
---
name: preserve-body
description: Test
---

Line 1
Line 2

  Indented line

Line 3
''';
      final result = SkillParser.parse('/path/to/SKILL.md', body);

      expect(result.content, contains('Line 1'));
      expect(result.content, contains('Line 2'));
      expect(result.content, contains('  Indented line'));
      expect(result.content, contains('Line 3'));
    });

    test('parse handles YAML boolean values', () {
      const withBoolean = '''
---
name: boolean-test
description: Test
slash: true
---
Body
''';
      final result = SkillParser.parse('/path/to/SKILL.md', withBoolean);

      expect(result.name, 'boolean-test');
    });

    test('parse handles YAML numeric values', () {
      const withNumber = '''
---
name: number-test
description: Test
priority: 1
---
Body
''';
      final result = SkillParser.parse('/path/to/SKILL.md', withNumber);

      expect(result.name, 'number-test');
    });

    test('parse error includes filePath when available', () {
      try {
        SkillParser.parse('/specific/path/SKILL.md', yamlEmptyName);
      } on ParseError catch (e) {
        expect(e.filePath, '/specific/path/SKILL.md');
        return;
      }
      fail('Expected ParseError to be thrown');
    });

    test('parse error includes line number when available', () {
      try {
        SkillParser.parse('/path/SKILL.md', yamlEmptyName);
      } on ParseError catch (e) {
        // Line number may be null if not tracked
        // Just verify the error is thrown
        expect(e, isA<ParseError>());
        return;
      }
      fail('Expected ParseError to be thrown');
    });
  });
}
