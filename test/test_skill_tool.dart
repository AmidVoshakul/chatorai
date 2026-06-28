import 'package:test/test.dart';
import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_service.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/skill.dart';

// --- Fake SkillService for testing ---

class FakeSkillService implements SkillService {
  final Map<String, SkillInfo> _skills;
  final bool _listAllThrows;

  FakeSkillService({Map<String, SkillInfo>? skills, bool listAllThrows = false})
    : _skills = skills ?? {},
      _listAllThrows = listAllThrows;

  @override
  Future<List<SkillInfo>> listAll() async {
    if (_listAllThrows) throw StateError('Discovery not initialized');
    return _skills.values.toList();
  }

  @override
  Future<SkillInfo?> getByName(String name) async {
    return _skills[name];
  }

  @override
  Future<List<SkillInfo>> availableForAgent(String agentName) async {
    return _skills.values.toList();
  }

  @override
  Future<void> refresh() async {}

  @override
  void dispose() {}

  @override
  Future<void> clearCache() async {}

  // Satisfy the interface — not used in tests
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// --- Helpers ---

ToolContext _mockCtx({
  List<String>? askedPermission,
  List<String>? askedPatterns,
}) {
  askedPermission;
  askedPatterns;
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: 'test-session',
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {
          askedPermission = [permission];
          askedPatterns = patterns;
        },
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
  );
}

void main() {
  group('skill tool', () {
    group('definition metadata', () {
      test('description is non-empty and lists available skills', () {
        final skills = [
          SkillInfo(
            name: 'code-review',
            description: 'Code review skill',
            directory: '/skills/code-review',
            content: '# Code Review',
          ),
        ];
        final service = FakeSkillService(skills: {'code-review': skills.first});
        final tool = createSkillTool(service, skills);

        expect(tool.description, isNotEmpty);
        expect(tool.description, contains('code-review'));
        expect(tool.description, contains('Code review skill'));
      });

      test('inputSchema has required name field', () {
        final service = FakeSkillService(skills: {});
        final tool = createSkillTool(service, []);
        final schema = tool.inputSchema;
        final properties = schema['properties'] as Map<String, dynamic>;
        expect(properties.containsKey('name'), isTrue);
        expect((schema['required'] as List).contains('name'), isTrue);
      });

      test('description is dynamic based on available skills', () {
        final skills = [
          SkillInfo(
            name: 'skill-a',
            description: 'First skill',
            directory: '/skills/a',
            content: 'content a',
          ),
          SkillInfo(
            name: 'skill-b',
            description: 'Second skill',
            directory: '/skills/b',
            content: 'content b',
          ),
        ];
        final service = FakeSkillService(
          skills: {'skill-a': skills[0], 'skill-b': skills[1]},
        );
        final tool = createSkillTool(service, skills);

        expect(tool.description, contains('skill-a'));
        expect(tool.description, contains('skill-b'));
      });

      test('description handles empty skills list', () {
        final service = FakeSkillService();
        final tool = createSkillTool(service, []);

        expect(tool.description, isNotEmpty);
        expect(tool.description, contains('Load a specialized skill'));
      });
    });

    group('missing name validation', () {
      test('execute with missing name returns error', () async {
        final service = FakeSkillService(skills: {});
        final tool = createSkillTool(service, []);
        final ctx = _mockCtx();
        final output = await tool.execute({}, ctx);

        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('name is required'));
      });

      test('execute with null name returns error', () async {
        final service = FakeSkillService(skills: {});
        final tool = createSkillTool(service, []);
        final ctx = _mockCtx();
        final output = await tool.execute({'name': null}, ctx);

        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('name is required'));
      });
    });

    group('skill not found', () {
      test('execute returns error when skill does not exist', () async {
        final service = FakeSkillService(skills: {});
        final tool = createSkillTool(service, []);
        final ctx = _mockCtx();
        final output = await tool.execute({'name': 'nonexistent'}, ctx);

        expect(output.metadata?['error'], isTrue);
        expect(output.metadata?['not_found'], isTrue);
        expect(output.output, contains('nonexistent'));
        expect(output.output, contains('not found'));
      });
    });

    group('permission call verification', () {
      test(
        'execute calls ctx.ask with correct permission and pattern',
        () async {
          final skill = SkillInfo(
            name: 'my-skill',
            description: 'A test skill',
            directory: '/skills/test',
            content: '# Test',
          );
          final service = FakeSkillService(skills: {'my-skill': skill});
          final skills = [skill];
          final tool = createSkillTool(service, skills);

          String? capturedPermission;
          List<String>? capturedPatterns;
          List<String>? capturedAlways;
          final ctx = ToolContext(
            toolCallId: 'test',
            sessionId: 'test',
            ask:
                ({
                  required String permission,
                  required List<String> patterns,
                  Map<String, dynamic>? metadata,
                  List<String>? always,
                }) async {
                  capturedPermission = permission;
                  capturedPatterns = patterns;
                  capturedAlways = always;
                },
            askQuestion:
                ({
                  required question,
                  options = const [],
                  multiple = false,
                }) async => '',
          );

          await tool.execute({'name': 'my-skill'}, ctx);

          expect(capturedPermission, equals('skill'));
          expect(capturedPatterns, isNotNull);
          expect(capturedPatterns!.first, contains('skill:name=my-skill'));
          expect(capturedAlways, isNotNull);
          expect(capturedAlways!.first, contains('skill:name=my-skill'));
        },
      );
    });

    group('output format verification (XML wrapping)', () {
      test('output wraps skill content in XML tags', () async {
        final skill = SkillInfo(
          name: 'formatter',
          description: 'Format skill',
          directory: '/skills/formatter',
          content: '# Skill Content\n\nInstructions here.',
        );
        final service = FakeSkillService(skills: {'formatter': skill});
        final tool = createSkillTool(service, [skill]);
        final ctx = _mockCtx();

        final output = await tool.execute({'name': 'formatter'}, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.metadata?['skill'], isTrue);
        expect(output.metadata?['name'], equals('formatter'));
        expect(output.output, contains('<skill_content name="formatter">'));
        expect(output.output, contains('# Skill Content'));
        expect(output.output, contains('</skill_content>'));
      });

      test('output includes base directory with file:// protocol', () async {
        final skill = SkillInfo(
          name: 'dir-skill',
          description: 'Directory test',
          directory: '/home/user/skills/dir-skill',
          content: 'Content',
        );
        final service = FakeSkillService(skills: {'dir-skill': skill});
        final tool = createSkillTool(service, [skill]);
        final ctx = _mockCtx();

        final output = await tool.execute({'name': 'dir-skill'}, ctx);

        expect(output.output, contains('file:///home/user/skills/dir-skill'));
      });

      test(
        'output includes <skill_files> section when files present',
        () async {
          final skill = SkillInfo(
            name: 'files-skill',
            description: 'Files test',
            directory: '/skills/files',
            content: 'Content',
            files: ['helpers.py', 'config.json', 'README.md'],
          );
          final service = FakeSkillService(skills: {'files-skill': skill});
          final tool = createSkillTool(service, [skill]);
          final ctx = _mockCtx();

          final output = await tool.execute({'name': 'files-skill'}, ctx);

          expect(output.output, contains('<skill_files>'));
          expect(output.output, contains('<file>helpers.py</file>'));
          expect(output.output, contains('<file>config.json</file>'));
          expect(output.output, contains('<file>README.md</file>'));
          expect(output.output, contains('</skill_files>'));
        },
      );

      test('output omits empty files section when no files', () async {
        final skill = SkillInfo(
          name: 'no-files',
          description: 'No files',
          directory: '/skills/no-files',
          content: 'Just content',
          files: [],
        );
        final service = FakeSkillService(skills: {'no-files': skill});
        final tool = createSkillTool(service, [skill]);
        final ctx = _mockCtx();

        final output = await tool.execute({'name': 'no-files'}, ctx);

        expect(output.output, contains('<skill_files>'));
        expect(output.output, contains('</skill_files>'));
        expect(output.output, isNot(contains('<file>')));
      });
    });

    group('edge cases', () {
      test('execute handles empty skill name string', () async {
        final service = FakeSkillService(skills: {});
        final tool = createSkillTool(service, []);
        final ctx = _mockCtx();

        final output = await tool.execute({'name': ''}, ctx);

        // Empty string is still a non-null String, but skill won't be found
        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('not found'));
      });

      test(
        'getByName returns null for missing skill (service integration)',
        () async {
          final service = FakeSkillService(skills: {});
          final result = await service.getByName('ghost-skill');
          expect(result, isNull);
        },
      );

      test(
        'getByName returns skill for existing name (service integration)',
        () async {
          final skill = SkillInfo(
            name: 'real-skill',
            description: 'Real',
            directory: '/skills/real',
            content: 'real content',
          );
          final service = FakeSkillService(skills: {'real-skill': skill});
          final result = await service.getByName('real-skill');
          expect(result, isNotNull);
          expect(result!.name, equals('real-skill'));
        },
      );
    });

    group('successful skill load with full context injection', () {
      test('full output structure matches expected format', () async {
        final skill = SkillInfo(
          name: 'full-test',
          description: 'Full context test',
          directory: '/skills/full',
          content:
              '# Full Skill\n\nThis skill provides:\n- Feature A\n- Feature B',
          files: ['scripts/run.sh', 'docs/api.md'],
        );
        final service = FakeSkillService(skills: {'full-test': skill});
        final tool = createSkillTool(service, [skill]);
        final ctx = _mockCtx();

        final output = await tool.execute({'name': 'full-test'}, ctx);

        // Verify overall structure
        expect(output.output, startsWith('<skill_content name="full-test">'));
        expect(output.output, endsWith('</skill_content>'));

        // Verify name section
        expect(output.output, contains('# Skill: full-test'));

        // Verify content is present
        expect(output.output, contains('# Full Skill'));
        expect(output.output, contains('- Feature A'));
        expect(output.output, contains('- Feature B'));

        // Verify base directory
        expect(
          output.output,
          contains('Base directory for this skill: file:///skills/full'),
        );

        // Verify files section
        expect(output.output, contains('<file>scripts/run.sh</file>'));
        expect(output.output, contains('<file>docs/api.md</file>'));

        // Verify metadata
        expect(output.metadata?['skill'], isTrue);
        expect(output.metadata?['name'], equals('full-test'));
        expect(output.metadata?['error'], isNull);
      });

      test('output preserves skill content as-is (no escaping)', () async {
        final skill = SkillInfo(
          name: 'raw-content',
          description: 'Raw content',
          directory: '/skills/raw',
          content: '<dart>final x = 1;</dart>',
        );
        final service = FakeSkillService(skills: {'raw-content': skill});
        final tool = createSkillTool(service, [skill]);
        final ctx = _mockCtx();

        final output = await tool.execute({'name': 'raw-content'}, ctx);

        expect(output.output, contains('<dart>final x = 1;</dart>'));
      });
    });
  });
}
