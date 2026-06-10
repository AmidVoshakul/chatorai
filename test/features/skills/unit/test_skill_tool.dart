import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:chatorai/features/skills/domain/services/skill_service.dart';
import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSkillService extends Mock implements SkillService {}

class MockToolContext extends Mock implements ToolContext {}

void main() {
  group('SkillTool', () {
    late MockSkillService mockSkillService;
    late MockToolContext mockCtx;

    setUp(() {
      mockSkillService = MockSkillService();
      mockCtx = MockToolContext();
    });

    test(
      'createSkillTool generates description with available skills',
      () async {
        final skills = [
          SkillInfo(
            name: 'review',
            description: 'Code review skill',
            directory: '/tmp/review',
            content: '# Review',
          ),
          SkillInfo(
            name: 'test',
            description: 'Testing skill',
            directory: '/tmp/test',
            content: '# Test',
          ),
        ];
        when(() => mockSkillService.listAll()).thenAnswer((_) async => skills);

        final tool = createSkillTool(mockSkillService);

        expect(tool.description, contains('Load a specialized skill'));
        expect(tool.description, contains('review: Code review'));
        expect(tool.description, contains('test: Testing skill'));
      },
    );

    test('execute returns skill content when found', () async {
      final skill = SkillInfo(
        name: 'example',
        description: 'Example skill',
        directory: '/tmp/example',
        content: '# Example\n\nSome content',
        files: ['script.sh'],
      );
      when(
        () => mockSkillService.getByName('example'),
      ).thenAnswer((_) async => skill);

      final tool = createSkillTool(mockSkillService);
      final result = await tool.execute({'name': 'example'}, mockCtx);

      expect(result.output, contains('<skill_content name="example">'));
      expect(result.output, contains('# Example'));
      expect(result.output, contains('Base directory'));
    });

    test('execute returns error when skill not found', () async {
      when(
        () => mockSkillService.getByName('missing'),
      ).thenAnswer((_) async => null);

      final tool = createSkillTool(mockSkillService);
      final result = await tool.execute({'name': 'missing'}, mockCtx);

      expect(result.output, contains('Error: skill "missing" not found'));
      expect(result.metadata?['error'], isTrue);
    });

    test('execute requires name parameter', () async {
      final tool = createSkillTool(mockSkillService);
      final result = await tool.execute({}, mockCtx);

      expect(result.output, contains('Error: skill name is required'));
    });
  });
}

class MockSkillService extends Mock implements SkillService {}

void main() {
  group('createSkillTool', () {
    late MockSkillService mockSkillService;
    late ToolDef tool;

    const skill1 = SkillInfo(
      name: 'skill1',
      description: 'First skill description',
      directory: '/dir1',
      content: '# Skill 1\n\nContent',
      files: ['script1.py'],
    );

    const skill2 = SkillInfo(
      name: 'skill2',
      description: 'Second skill description',
      directory: '/dir2',
      content: '# Skill 2\n\nContent',
      files: [],
    );

    setUp(() {
      mockSkillService = MockSkillService();
      tool = createSkillTool(mockSkillService, [skill1, skill2]);
    });

    test('tool has correct id', () {
      expect(tool.id, 'skill');
    });

    test('tool description includes available skills', () {
      expect(tool.description, contains('skill1: First skill description'));
      expect(tool.description, contains('skill2: Second skill description'));
    });

    test('tool description explains how to use', () {
      expect(
        tool.description,
        contains('Load a specialized skill when the task matches'),
      );
    });

    test('input schema requires name parameter', () {
      final schema = tool.inputSchema as Map<String, dynamic>;
      expect(schema['type'], 'object');
      expect(schema['required'], ['name']);
      expect((schema['properties'] as Map)['name'], isNotNull);
    });

    test('execute with null name returns error', () async {
      final result = await tool.execute(
        {'name': null},
        FakeToolContext(
          toolCallId: '1',
          sessionId: 'sess',
          ask:
              ({
                required permission,
                required patterns,
                metadata,
                always,
              }) async {},
        ),
      );

      expect(result.output, contains('Error: skill name is required'));
      expect(result.metadata?['error'], isTrue);
    });

    test('execute with empty name returns error (not found)', () async {
      when(() => mockSkillService.getByName('')).thenAnswer((_) async => null);

      final result = await tool.execute(
        {'name': ''},
        FakeToolContext(
          toolCallId: '1',
          sessionId: 'sess',
          ask:
              ({
                required permission,
                required patterns,
                metadata,
                always,
              }) async {},
        ),
      );

      expect(result.output, contains('Error: skill "" not found'));
      expect(result.metadata?['error'], isTrue);
      expect(result.metadata?['not_found'], isTrue);
    });

    test('execute with unknown skill name returns error', () async {
      when(
        () => mockSkillService.getByName('unknown'),
      ).thenAnswer((_) async => null);

      final result = await tool.execute(
        {'name': 'unknown'},
        FakeToolContext(
          toolCallId: '1',
          sessionId: 'sess',
          ask:
              ({
                required permission,
                required patterns,
                metadata,
                always,
              }) async {},
        ),
      );

      expect(result.output, contains('Error: skill "unknown" not found'));
      expect(result.metadata?['error'], isTrue);
      expect(result.metadata?['not_found'], isTrue);
    });

    test(
      'execute with valid skill returns skill content in XML format',
      () async {
        when(
          () => mockSkillService.getByName('skill1'),
        ).thenAnswer((_) async => skill1);

        final result = await tool.execute(
          {'name': 'skill1'},
          FakeToolContext(
            toolCallId: '1',
            sessionId: 'sess',
            ask:
                ({
                  required permission,
                  required patterns,
                  metadata,
                  always,
                }) async {},
          ),
        );

        expect(result.output, contains('<skill_content name="skill1">'));
        expect(result.output, contains('# Skill 1'));
        expect(result.output, contains('Content'));
        expect(
          result.output,
          contains('Base directory for this skill: file:///dir1'),
        );
        expect(result.output, contains('<skill_files>'));
        expect(result.output, contains('<file>script1.py</file>'));
        expect(result.output, contains('</skill_files>'));
        expect(result.output, contains('</skill_content>'));
        expect(result.metadata?['skill'], isTrue);
        expect(result.metadata?['name'], 'skill1');
      },
    );

    test(
      'execute includes empty skill_files section when no auxiliary files',
      () async {
        final skillNoFiles = SkillInfo(
          name: 'no-files',
          description: 'Skill without files',
          directory: '/dir',
          content: '# Content',
          files: [],
        );

        when(
          () => mockSkillService.getByName('no-files'),
        ).thenAnswer((_) async => skillNoFiles);

        final result = await tool.execute(
          {'name': 'no-files'},
          FakeToolContext(
            toolCallId: '1',
            sessionId: 'sess',
            ask:
                ({
                  required permission,
                  required patterns,
                  metadata,
                  always,
                }) async {},
          ),
        );

        expect(result.output, contains('<skill_files>'));
        expect(result.output, contains('</skill_files>'));
      },
    );

    test('execute calls permission check with correct pattern', () async {
      when(
        () => mockSkillService.getByName('skill1'),
      ).thenAnswer((_) async => skill1);

      bool askCalled = false;
      String? capturedPermission;
      List<String>? capturedPatterns;
      List<String>? capturedAlways;

      final context = FakeToolContext(
        toolCallId: '1',
        sessionId: 'sess',
        ask:
            ({required permission, required patterns, metadata, always}) async {
              askCalled = true;
              capturedPermission = permission;
              capturedPatterns = patterns;
              capturedAlways = always;
            },
      );

      await tool.execute({'name': 'skill1'}, context);

      expect(askCalled, isTrue);
      expect(capturedPermission, 'skill');
      expect(capturedPatterns, ['skill:name=skill1']);
      expect(capturedAlways, ['skill:name=skill1']);
    });

    test('execute propagates permission errors', () async {
      when(
        () => mockSkillService.getByName('skill1'),
      ).thenAnswer((_) async => skill1);

      final context = FakeToolContext(
        toolCallId: '1',
        sessionId: 'sess',
        ask:
            ({required permission, required patterns, metadata, always}) async {
              throw PermissionDeniedError('skill', 'skill:name=skill1');
            },
      );

      expect(
        () => tool.execute({'name': 'skill1'}, context),
        throwsA(isA<PermissionDeniedError>()),
      );
    });

    test('tool description updates when skills list changes', () {
      final newSkill = SkillInfo(
        name: 'new-skill',
        description: 'New skill',
        directory: '/new',
        content: '# New',
      );

      final updatedTool = createSkillTool(mockSkillService, [newSkill]);

      expect(updatedTool.description, contains('new-skill: New skill'));
      expect(updatedTool.description, isNot(contains('skill1')));
    });

    test('tool handles skill with special characters in content', () async {
      const specialContent = '''
# Skill with special chars: <>&"'

```dart
void main() {}
```
''';

      final specialSkill = SkillInfo(
        name: 'special',
        description: 'Special chars skill',
        directory: '/dir',
        content: specialContent,
        files: [],
      );

      when(
        () => mockSkillService.getByName('special'),
      ).thenAnswer((_) async => specialSkill);

      final result = await tool.execute(
        {'name': 'special'},
        FakeToolContext(
          toolCallId: '1',
          sessionId: 'sess',
          ask:
              ({
                required permission,
                required patterns,
                metadata,
                always,
              }) async {},
        ),
      );

      expect(result.output, contains(specialContent));
    });

    test('tool includes file list when multiple files present', () async {
      final skillWithManyFiles = SkillInfo(
        name: 'many-files',
        description: 'Many files',
        directory: '/dir',
        content: '# Content',
        files: ['a.txt', 'b.py', 'c.md', 'd.json', 'e.yaml'],
      );

      when(
        () => mockSkillService.getByName('many-files'),
      ).thenAnswer((_) async => skillWithManyFiles);

      final result = await tool.execute(
        {'name': 'many-files'},
        FakeToolContext(
          toolCallId: '1',
          sessionId: 'sess',
          ask:
              ({
                required permission,
                required patterns,
                metadata,
                always,
              }) async {},
        ),
      );

      for (final file in skillWithManyFiles.files) {
        expect(result.output, contains('<file>$file</file>'));
      }
    });
  });
}
