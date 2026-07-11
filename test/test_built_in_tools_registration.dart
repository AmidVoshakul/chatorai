import 'package:test/test.dart';
import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/core/tools/tool_execution.dart';
import 'package:chatorai/core/tools/tool_definition.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/tools/built_in/built_in_tools.dart';
import 'package:chatorai/core/skills/skill_service.dart';
import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_source.dart';
import 'package:chatorai/core/skills/skill_plugin.dart';

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
  bool remove(String id) => throw UnimplementedError();
  @override
  bool contains(String id) => throw UnimplementedError();
  @override
  List<ToolDef> get available => throw UnimplementedError();
  @override
  List<String> get ids => registered;
  @override
  Map<String, sdk.Tool<dynamic, dynamic>> toSDKTools() => {};
  @override
  void pruneSession(String sessionId) {}

  @override
  set agentRules(PermissionRuleset? rules) {}

  @override
  ToolExecutor get executor => throw UnimplementedError();

  @override
  ToolDef? get read => throw UnimplementedError();

  @override
  void registerDefinition(ToolDefinition definition) {
    // no-op for tests
  }

  @override
  Future<void> resolveAll() async {
    // no-op for tests
  }

  @override
  ToolDef? get task => throw UnimplementedError();

  @override
  void Function(String agentId, {String? messageText})? switchAgent;

  @override
  set switchAgentCallback(
    void Function(String agentId, {String? messageText})? callback,
  ) {
    switchAgent = callback;
  }
}

class MockSkillService implements SkillService {
  @override
  final List<SkillSource> sources = <SkillSource>[];
  @override
  final List<SkillPlugin> plugins = <SkillPlugin>[];

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
  Future<void> clearCache() async {}
  @override
  void dispose() {}
  @override
  Future<void> refresh() async {}
  @override
  Future<SkillInfo?> getByName(String name) async => null;
}

void main() {
  group('built_in_tools registration', () {
    test('registers all built-in tools without skillService', () async {
      final registry = MockToolRegistry();
      await registerBuiltInTools(registry);
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
          'plan_enter',
          'plan_exit',
        ]),
      );
      expect(registry.registered, isNot(contains('skill')));
      expect(registry.registered, isNot(contains('lsp')));
    });

    test('registers skill tool when skillService provided', () async {
      final registry = MockToolRegistry();
      final skillService = MockSkillService();
      await registerBuiltInTools(registry, skillService: skillService);
      expect(registry.registered, contains('skill'));
    });
  });
}
