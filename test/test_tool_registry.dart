import 'package:test/test.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:chatorai/features/tools/data/models/tool_registry.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/permission/rule.dart';

ToolDef _fakeTool(String id, {String description = 'fake tool'}) {
  return ToolDef(
    id: id,
    description: description,
    inputSchema: {'type': 'object'},
    execute: (input, ctx) async => const ToolOutput('fake result'),
  );
}

void main() {
  group('ToolRegistry', () {
    test('register/get/all', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());
      final tool = _fakeTool('fake_tool', description: 'A fake tool');

      registry.register(tool);
      expect(registry.get('fake_tool'), equals(tool));
      expect(registry.all.length, equals(1));
    });

    test('toSDKTools returns a map with tool entries', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());
      final tool = _fakeTool('fake_tool');

      registry.register(tool);
      final sdkTools = registry.toSDKTools();

      expect(sdkTools.containsKey('fake_tool'), isTrue);
      expect(sdkTools['fake_tool'], isNotNull);
    });

    test(
      'disabled tool filtered (bash has deny-all rule → not in available)',
      () {
        final service = PermissionService();
        final denyRuleset = PermissionRuleset(
          rules: [
            PermissionRule(
              permission: 'bash',
              pattern: '*',
              action: PermissionAction.deny,
            ),
          ],
        );
        final registry = ToolRegistry(service, denyRuleset);
        final bashTool = _fakeTool('bash', description: 'Bash tool');
        final readTool = _fakeTool('read', description: 'Read tool');

        registry.register(bashTool);
        registry.register(readTool);

        final available = registry.available;
        expect(available.any((t) => t.id == 'bash'), isFalse);
        expect(available.any((t) => t.id == 'read'), isTrue);
      },
    );

    test('get returns null for unknown tool', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      expect(registry.get('nonexistent'), isNull);
    });
  });
}
