import 'package:test/test.dart';
import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:chatorai/features/tools/data/models/tool_registry.dart';
import 'package:chatorai/features/tools/built_in/built_in_tools.dart';
import 'package:chatorai/features/skills/domain/services/skill_service.dart';
import 'package:chatorai/features/skills/data/models/skill_info.dart';

class MockToolRegistry implements ToolRegistry {
  final List<String> registered = [];
  @override
  void register(ToolDef tool) {
    registered.add(tool.id);
  }

  @override
  ToolDef? get(String id) => throw UnimplementedError();
  @override
  List<ToolDef> get all => throw UnimplementedError();
  @override
  ToolDef? remove(String id) => throw UnimplementedError();
  @override
  bool contains(String id) => throw UnimplementedError();
  @override
  List<ToolDef> get available => throw UnimplementedError();
  @override
  List<String> get ids => registered;
  @override
  Map<String, sdk.Tool<dynamic, dynamic>> toSDKTools() =>
      throw UnimplementedError();
}

class MockSkillService implements SkillService {
  @override
  Future<List<SkillInfo>> listAll() async => [
    SkillInfo(
      name: 'skill1',
      description: 'Test skill 1',
      directory: '/test/skill1',
      content: '# Skill 1\nTest content',
    ),
  ];
  @override
  Future<List<SkillInfo>> availableForAgent(String agentName) async => [];
  @override
  void clearCache() {}
  @override
  void dispose() {}
  @override
  Future<SkillInfo?> getByName(String name) async => null;
}

void main() {
  group('built_in_tools registration', () {
    test('registers all built-in tools without skillService', () async {
      final registry = MockToolRegistry();
      await registerBuiltInTools(registry);
      // Expect all tools except skill (which requires skillService)
      expect(
        registry.registered,
        containsAll([
          'bash',
          'read',
          'glob',
          'grep',
          'edit',
          'write',
          'webfetch',
          'websearch',
          'apply_patch',
          'todowrite',
          'task',
          'question',
        ]),
      );
      expect(registry.registered, isNot(contains('skill')));
    });

    test('registers skill tool when skillService provided', () async {
      final registry = MockToolRegistry();
      final skillService = MockSkillService();
      await registerBuiltInTools(registry, skillService: skillService);
      expect(registry.registered, contains('skill'));
    });
  });
}
