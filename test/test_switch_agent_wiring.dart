import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_execution.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/permission/rule.dart';

void main() {
  group('ToolRegistry.switchAgent', () {
    test('switchAgent is null by default', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());
      expect(registry.switchAgent, isNull);
    });

    test('switchAgent can be assigned and invoked', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());
      bool called = false;
      registry.switchAgent = (String agentId, {String? messageText}) {
        called = true;
      };
      expect(registry.switchAgent, isNotNull);
      registry.switchAgent?.call('plan');
      expect(called, isTrue);
    });

    test('switchAgent callback receives agentId and messageText', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      String? capturedAgentId;
      String? capturedMessageText;

      registry.switchAgent = (String agentId, {String? messageText}) {
        capturedAgentId = agentId;
        capturedMessageText = messageText;
      };

      registry.switchAgent?.call('build', messageText: 'Execute the plan');

      expect(capturedAgentId, 'build');
      expect(capturedMessageText, 'Execute the plan');
    });

    test('switchAgent stored on ToolRegistry is independent of executor', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      // The registry holds switchAgent independently from the executor.
      // The executor's switchAgent is a separate field that must be wired
      // explicitly by the caller (e.g. tool_registry_provider.dart).
      expect(registry.executor.switchAgent, isNull);

      registry.switchAgent = (String agentId, {String? messageText}) {};
      // Registry callback is set, but executor still has its own null field.
      expect(registry.executor.switchAgent, isNull);
    });

    test('tool execution does not crash when switchAgent is null', () async {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());
      // switchAgent is null by default

      final tool = ToolDef(
        id: 'test_null_switch',
        description: 'Test null switch agent',
        inputSchema: {'type': 'object', 'properties': {}, 'required': []},
        execute: (input, ctx) async {
          // Explicitly call switchAgent even though it's null
          ctx.switchAgent?.call('plan');
          return const ToolOutput('No crash');
        },
      );

      registry.register(tool);

      final result = await registry.executor.execute(
        tool,
        {},
        _FakeToolOptions(sessionId: null, experimentalContext: null),
      );

      expect(result['output'], 'No crash');
    });

    test('switchAgent is not called when not set', () async {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      final tool = ToolDef(
        id: 'test_no_switch',
        description: 'Test no switch agent',
        inputSchema: {'type': 'object', 'properties': {}, 'required': []},
        execute: (input, ctx) async {
          ctx.switchAgent?.call('build');
          return const ToolOutput('Done');
        },
      );

      registry.register(tool);

      final result = await registry.executor.execute(
        tool,
        {},
        _FakeToolOptions(sessionId: null, experimentalContext: null),
      );

      expect(result['output'], 'Done');
      // No crash even though switchAgent was not set
    });

    test('registry.available filters by agent rules', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      // Set agent rules that deny all tools
      registry.agentRules = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: '*',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );

      // Register a tool that would be denied by agent rules
      final tool = ToolDef(
        id: 'denied_tool',
        description: 'Denied tool',
        inputSchema: {'type': 'object'},
        execute: (input, ctx) async => const ToolOutput('denied'),
      );
      registry.register(tool);

      // `available` now respects agent rules in addition to default rules.
      final available = registry.available;
      expect(available.any((t) => t.id == 'denied_tool'), isFalse);
    });

    test('agent rules set on registry are forwarded to executor', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      // When agentRules is set on the registry, it forwards to the executor.
      final agentRules = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'question',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );

      registry.agentRules = agentRules;
      expect(registry.executor.agentRules, equals(agentRules));
    });
  });
}

class _FakeToolOptions {
  final String? sessionId;
  final Map<String, dynamic>? experimentalContext;

  _FakeToolOptions({this.sessionId, this.experimentalContext});

  Map<String, String>? get runtimeContext =>
      sessionId == null ? null : {'sessionId': sessionId!};
}
