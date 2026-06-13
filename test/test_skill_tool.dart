import 'package:test/test.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:chatorai/features/tools/built_in/skill.dart';
import 'package:chatorai/features/skills/domain/services/skill_service.dart';
import 'package:chatorai/features/skills/data/models/skill_info.dart';

// Mock SkillService for testing
class _MockSkillService implements SkillService {
  final Map<String, SkillInfo> _skills = {
    'test-skill': SkillInfo(
      name: 'test-skill',
      description: 'A test skill for unit testing',
      directory: '/test/dir',
      content: '# Test Skill\nThis is a test skill content',
      files: ['test_file.md'],
    ),
    'another-skill': SkillInfo(
      name: 'another-skill',
      description: 'Another test skill',
      directory: '/another/dir',
      content: '# Another Skill\nMore test content',
      files: ['readme.md', 'guide.md'],
    ),
  };

  @override
  Future<SkillInfo?> getByName(String name) async => _skills[name];

  @override
  Future<List<SkillInfo>> listAll() async => _skills.values.toList();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<List<SkillInfo>> availableForAgent(String agentName) async =>
      _skills.values.toList();

  @override
  void clearCache() {}
}

ToolContext _mockCtx({
  bool askResult = true,
  List<String>? askedPermission,
  List<String>? askedPatterns,
}) {
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
  );
}

// Helper mock for single-skill testing
class _SimpleMockSkillService implements SkillService {
  final SkillInfo _skill;
  _SimpleMockSkillService(this._skill);

  @override
  Future<SkillInfo?> getByName(String name) async =>
      name == _skill.name ? _skill : null;

  @override
  Future<List<SkillInfo>> listAll() async => [_skill];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<List<SkillInfo>> availableForAgent(String agentName) async => [_skill];

  @override
  void clearCache() {}
}

void main() {
  group('Skill Tool', () {
    late SkillService mockSkillService;
    late List<SkillInfo> availableSkills;

    setUp(() async {
      mockSkillService = _MockSkillService();
      availableSkills = await mockSkillService.listAll();
    });

    test('description includes available skills list', () {
      final tool = createSkillTool(mockSkillService, availableSkills);
      expect(tool.description, contains('A test skill'));
      expect(tool.description, contains('Another test skill'));
      expect(tool.description, contains('Available skills:'));
    });

    test('inputSchema has required name field', () {
      final tool = createSkillTool(mockSkillService, availableSkills);
      final schema = tool.inputSchema as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('name'), isTrue);
      expect((schema['required'] as List).contains('name'), isTrue);
    });

    test('execute with missing name returns error', () async {
      final tool = createSkillTool(mockSkillService, availableSkills);
      final ctx = _mockCtx();
      final output = await tool.execute({}, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('skill name is required'));
    });

    test('execute calls ctx.ask with skill permission and pattern', () async {
      final tool = createSkillTool(mockSkillService, availableSkills);
      String? capturedPermission;
      List<String>? capturedPatterns;
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
            },
      );
      await tool.execute({'name': 'test-skill'}, ctx);
      expect(capturedPermission, equals('skill'));
      expect(capturedPatterns, contains('skill:name=test-skill'));
    });

    test('execute returns skill content for valid skill', () async {
      final tool = createSkillTool(mockSkillService, availableSkills);
      final ctx = _mockCtx();
      final output = await tool.execute({'name': 'test-skill'}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('<skill_content name="test-skill">'));
      expect(output.output, contains('# Skill: test-skill'));
      expect(
        output.output,
        contains('# Test Skill'),
      ); // content starts with this
      expect(output.output, contains('This is a test skill content'));
      expect(output.metadata?['skill'], isTrue);
      expect(output.metadata?['name'], equals('test-skill'));
    });

    test('execute includes file list in skill content', () async {
      final tool = createSkillTool(mockSkillService, availableSkills);
      final ctx = _mockCtx();
      final output = await tool.execute({'name': 'another-skill'}, ctx);
      expect(output.output, contains('<skill_files>'));
      expect(output.output, contains('<file>readme.md</file>'));
      expect(output.output, contains('<file>guide.md</file>'));
    });

    test('execute returns error for non-existent skill', () async {
      final tool = createSkillTool(mockSkillService, availableSkills);
      final ctx = _mockCtx();
      final output = await tool.execute({'name': 'non-existent-skill'}, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.metadata?['not_found'], isTrue);
      expect(output.output, contains('not found or access denied'));
    });

    test('execute handles skill with no files', () async {
      final skillWithNoFiles = SkillInfo(
        name: 'no-files-skill',
        description: 'Skill without files',
        directory: '/no/files',
        content: '# No Files Skill\nNo associated files',
        files: [],
      );
      final tool = createSkillTool(_SimpleMockSkillService(skillWithNoFiles), [
        skillWithNoFiles,
      ]);
      final ctx = _mockCtx();
      final output = await tool.execute({'name': 'no-files-skill'}, ctx);
      expect(output.metadata?['error'], isNull);
      // With empty files list, we get <skill_files>\n\n</skill_files>
      expect(output.output, contains('<skill_files>'));
      expect(output.output, contains('</skill_files>'));
    });

    test('skill content includes base directory reference', () async {
      final tool = createSkillTool(mockSkillService, availableSkills);
      final ctx = _mockCtx();
      final output = await tool.execute({'name': 'test-skill'}, ctx);
      expect(output.output, contains('file:///test/dir'));
      expect(
        output.output,
        contains('Relative paths in this skill are relative'),
      );
    });
  });
}
