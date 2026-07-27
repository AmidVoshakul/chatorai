import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
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
  group('ToolRegistry — remove', () {
    test('remove returns true and removes existing tool', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());
      final tool = _fakeTool('remove_me');

      registry.register(tool);
      expect(registry.contains('remove_me'), isTrue);

      final result = registry.remove('remove_me');
      expect(result, isTrue);
      expect(registry.contains('remove_me'), isFalse);
      expect(registry.get('remove_me'), isNull);
    });

    test('remove returns false for non-existent tool', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      final result = registry.remove('does_not_exist');
      expect(result, isFalse);
    });

    test('remove leaves other tools intact', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());
      final toolA = _fakeTool('tool_a');
      final toolB = _fakeTool('tool_b');

      registry.register(toolA);
      registry.register(toolB);
      registry.remove('tool_a');

      expect(registry.contains('tool_a'), isFalse);
      expect(registry.contains('tool_b'), isTrue);
      expect(registry.get('tool_b'), equals(toolB));
    });
  });

  group('ToolRegistry — contains', () {
    test('contains returns true for registered tool', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());
      final tool = _fakeTool('existing_tool');

      registry.register(tool);
      expect(registry.contains('existing_tool'), isTrue);
    });

    test('contains returns false for unregistered tool', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      expect(registry.contains('never_registered'), isFalse);
    });

    test('contains returns false after tool is removed', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());
      final tool = _fakeTool('temp_tool');

      registry.register(tool);
      expect(registry.contains('temp_tool'), isTrue);
      registry.remove('temp_tool');
      expect(registry.contains('temp_tool'), isFalse);
    });
  });

  group('ToolRegistry — ids getter', () {
    test('ids returns empty list when no tools registered', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      expect(registry.ids, isEmpty);
    });

    test('ids returns all registered tool IDs', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      registry.register(_fakeTool('alpha'));
      registry.register(_fakeTool('beta'));
      registry.register(_fakeTool('gamma'));

      expect(registry.ids, containsAll(['alpha', 'beta', 'gamma']));
      expect(registry.ids.length, equals(3));
    });

    test('ids reflects removals', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      registry.register(_fakeTool('one'));
      registry.register(_fakeTool('two'));
      registry.remove('one');

      expect(registry.ids, equals(['two']));
    });
  });

  group('ToolRegistry — duplicate registration prevention', () {
    test('registering same id twice does not duplicate', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      final tool1 = _fakeTool('dup_tool', description: 'first');
      final tool2 = _fakeTool('dup_tool', description: 'second');

      registry.register(tool1);
      registry.register(tool2);

      expect(registry.all.length, equals(1));
      expect(registry.ids.where((id) => id == 'dup_tool').length, equals(1));
      // First registration wins
      expect(registry.get('dup_tool')!.description, equals('first'));
    });

    test('registering different ids adds both', () {
      final service = PermissionService();
      final registry = ToolRegistry(service, PermissionRuleset.defaults());

      registry.register(_fakeTool('tool_a'));
      registry.register(_fakeTool('tool_b'));

      expect(registry.all.length, equals(2));
      expect(registry.ids, containsAll(['tool_a', 'tool_b']));
    });
  });

  group('ToolRegistry — available with all tools denied', () {
    test('available returns empty list when all tools are denied', () {
      final service = PermissionService();
      final denyAllRuleset = PermissionRuleset(
        rules: [
          PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          PermissionRule(
            permission: 'write',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          PermissionRule(
            permission: 'glob',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          PermissionRule(
            permission: 'grep',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          PermissionRule(
            permission: 'task',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          PermissionRule(
            permission: 'question',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          PermissionRule(
            permission: 'webfetch',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          PermissionRule(
            permission: 'websearch',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      final registry = ToolRegistry(service, denyAllRuleset);

      registry.register(_fakeTool('shell', description: 'shell'));
      registry.register(_fakeTool('read', description: 'Read'));
      registry.register(_fakeTool('write', description: 'Write'));
      registry.register(_fakeTool('glob', description: 'Glob'));
      registry.register(_fakeTool('grep', description: 'Grep'));
      registry.register(_fakeTool('task', description: 'Task'));
      registry.register(_fakeTool('question', description: 'Question'));
      registry.register(_fakeTool('webfetch', description: 'Webfetch'));
      registry.register(_fakeTool('websearch', description: 'Websearch'));

      expect(registry.available, isEmpty);
    });
  });
}
