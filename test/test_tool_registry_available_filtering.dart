import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/permission/rule.dart';

ToolDef _tool(String id) => ToolDef(
  id: id,
  description: '$id tool',
  inputSchema: {'type': 'object'},
  execute: (input, ctx) async => const ToolOutput('ok'),
);

void main() {
  group('ToolRegistry.available — agent rules filtering', () {
    test('hides tools denied by agentRules', () {
      final service = PermissionService();
      service.seedRules(PermissionRuleset.defaults());
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      registry.register(_tool('read'));
      registry.register(_tool('write'));
      registry.register(_tool('bash'));

      registry.agentRules = PermissionRuleset(
        rules: const [
          PermissionRule(
            permission: 'write',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );

      final available = registry.available.map((t) => t.id).toList();
      expect(available, contains('read'));
      expect(available, isNot(contains('write')));
      expect(available, isNot(contains('bash')));
    });

    test('shows tools allowed by agentRules overriding default deny', () {
      final service = PermissionService();
      service.seedRules(
        PermissionRuleset(
          rules: const [
            PermissionRule(
              permission: 'question',
              pattern: '*',
              action: PermissionAction.deny,
            ),
          ],
        ),
      );
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      registry.register(_tool('question'));

      registry.agentRules = PermissionRuleset(
        rules: const [
          PermissionRule(
            permission: 'question',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );

      expect(registry.available.any((t) => t.id == 'question'), isTrue);
    });

    test('combines defaultRules, agentRules, and sessionApproved', () async {
      final service = PermissionService();
      service.seedRules(PermissionRuleset.defaults());
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      registry.register(_tool('edit'));

      // Default: edit is ask. Agent denies edit.
      registry.agentRules = PermissionRuleset(
        rules: const [
          PermissionRule(
            permission: 'edit',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );

      expect(registry.available.any((t) => t.id == 'edit'), isFalse);

      // User approves edit for session — sessionApproved should override agentRules deny
      final req = PermissionRequest(
        id: 'req-edit',
        toolName: 'edit',
        permission: 'edit',
        patterns: ['*'],
        always: ['*'],
      );
      final future = service.ask(req, PermissionRuleset.defaults());
      service.reply('req-edit', PermissionReply.always);
      await future;

      // sessionApproved allow takes precedence over agentRules deny
      expect(registry.available.any((t) => t.id == 'edit'), isTrue);
    });

    test('toSDKTools returns only available tools', () {
      final service = PermissionService();
      service.seedRules(PermissionRuleset.defaults());
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      registry.register(_tool('read'));
      registry.register(_tool('write'));

      registry.agentRules = PermissionRuleset(
        rules: const [
          PermissionRule(
            permission: 'write',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );

      final sdkTools = registry.toSDKTools();
      expect(sdkTools.containsKey('read'), isTrue);
      expect(sdkTools.containsKey('write'), isFalse);
    });
  });
}
