import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/permission_storage.dart';
import 'package:chatorai/core/tools/tool_registry_factory.dart';
import 'package:test/test.dart';

void main() {
  group('createToolRegistry', () {
    test('builds registry with built-in tools from empty config', () async {
      final permissions = PermissionService(
        storage: const NoopPermissionStorage(),
      );
      final config = ChatOrAIConfig.fromJson(const {});
      final registry = await createToolRegistry(
        config,
        permissions: permissions,
      );
      expect(registry.contains('shell'), isTrue);
      expect(registry.contains('read'), isTrue);
      expect(registry.contains('grep'), isTrue);
    });

    test('applies agent rules to the registry', () async {
      await AgentRegistry().init();
      final agent = AgentRegistry().get('build');
      expect(agent, isNotNull);
      final permissions = PermissionService(
        storage: const NoopPermissionStorage(),
      );
      final config = ChatOrAIConfig.fromJson(const {});
      final registry = await createToolRegistry(
        config,
        permissions: permissions,
        initialAgentId: 'build',
      );
      expect(registry.agentRules, isNotNull);
      expect(
        registry.agentRules!.rules.map((r) => r.permission),
        containsAll(agent!.permissions.rules.map((r) => r.permission)),
      );
    });

    test('registers extra tool definitions when provided', () async {
      final permissions = PermissionService(
        storage: const NoopPermissionStorage(),
      );
      final config = ChatOrAIConfig.fromJson(const {});
      final registry = await createToolRegistry(
        config,
        permissions: permissions,
        extraTools: const [],
      );
      expect(registry.contains('shell'), isTrue);
    });
  });
}
