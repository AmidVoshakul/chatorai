import 'package:test/test.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/permission/evaluator.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';

void main() {
  group('AgentRegistry permissions for plan tools', () {
    late AgentRegistry registry;

    setUpAll(() async {
      registry = AgentRegistry();
      await registry.init();
    });

    test('plan agent can execute plan_enter', () {
      final plan = registry.get('plan');
      expect(plan, isNotNull);

      final rule = evaluate('plan_enter', '*', [
        PermissionRuleset(rules: plan!.permissions.rules),
      ]);

      expect(rule.action, equals(PermissionAction.allow));
    });

    test('plan agent can execute plan_exit', () {
      final plan = registry.get('plan');
      expect(plan, isNotNull);

      final rule = evaluate('plan_exit', '*', [
        PermissionRuleset(rules: plan!.permissions.rules),
      ]);

      expect(rule.action, equals(PermissionAction.allow));
    });

    test('build agent can execute plan_enter via wildcard allow', () {
      final build = registry.get('build');
      expect(build, isNotNull);

      final rule = evaluate('plan_enter', '*', [
        PermissionRuleset(rules: build!.permissions.rules),
      ]);

      expect(rule.action, equals(PermissionAction.allow));
    });

    test('plan agent cannot execute arbitrary tools like write/edit', () {
      final plan = registry.get('plan');
      expect(plan, isNotNull);

      final writeRule = evaluate('write', '*', [
        PermissionRuleset(rules: plan!.permissions.rules),
      ]);
      expect(writeRule.action, equals(PermissionAction.deny));

      final editRule = evaluate('edit', '*', [
        PermissionRuleset(rules: plan!.permissions.rules),
      ]);
      expect(editRule.action, equals(PermissionAction.deny));
    });

    test('default rules deny plan_enter and plan_exit', () {
      final defaults = PermissionRuleset.defaults();

      final planEnterRule = evaluate('plan_enter', '*', [defaults]);
      expect(planEnterRule.action, equals(PermissionAction.deny));

      final planExitRule = evaluate('plan_exit', '*', [defaults]);
      expect(planExitRule.action, equals(PermissionAction.deny));
    });

    test('plan agent sees MCP tools without explicit allow rule', () {
      final plan = registry.get('plan');
      expect(plan, isNotNull);

      final mcpToolId = 'sequential_thinking__think';
      final rule = evaluate(mcpToolId, '*', [
        PermissionRuleset(rules: plan!.permissions.rules),
      ]);

      expect(rule.action, isNot(equals(PermissionAction.deny)));
    });
  });

  group('AgentRegistry per-agent tools overrides', () {
    test('tools: false adds deny rule for the tool', () {
      final agents = Map<String, AgentDefinition>.from(builtInAgents);
      final config = ChatOrAIConfig(
        version: 1,
        permission: const {},
        agent: AgentSectionConfig(
          agents: {
            'general': AgentConfig(tools: {'task': false}),
          },
        ),
      );

      AgentRegistry.applyOverrides(agents, config);
      final general = agents['general'];
      expect(general, isNotNull);

      final rule = evaluate('task', '*', [
        PermissionRuleset(rules: general!.permissions.rules),
      ]);
      expect(rule.action, equals(PermissionAction.deny));
    });

    test('tools: true adds allow rule for the tool', () {
      final agents = Map<String, AgentDefinition>.from(builtInAgents);
      final config = ChatOrAIConfig(
        version: 1,
        permission: const {},
        agent: AgentSectionConfig(
          agents: {
            'explore': AgentConfig(tools: {'task': true}),
          },
        ),
      );

      AgentRegistry.applyOverrides(agents, config);
      final explore = agents['explore'];
      expect(explore, isNotNull);

      final rule = evaluate('task', '*', [
        PermissionRuleset(rules: explore!.permissions.rules),
      ]);
      expect(rule.action, equals(PermissionAction.allow));
    });

    test('tools with string action values', () {
      final agents = Map<String, AgentDefinition>.from(builtInAgents);
      final config = ChatOrAIConfig(
        version: 1,
        permission: const {},
        agent: AgentSectionConfig(
          agents: {
            'plan': AgentConfig(tools: {'sequential_thinking__think': 'deny'}),
          },
        ),
      );

      AgentRegistry.applyOverrides(agents, config);
      final plan = agents['plan'];
      expect(plan, isNotNull);

      final rule = evaluate('sequential_thinking__think', '*', [
        PermissionRuleset(rules: plan!.permissions.rules),
      ]);
      expect(rule.action, equals(PermissionAction.deny));
    });
  });
}
