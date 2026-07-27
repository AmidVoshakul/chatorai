import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_definition.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/permission/rule.dart';

ToolDef _tool(String id) => ToolDef(
  id: id,
  description: 'Tool $id',
  inputSchema: {'type': 'object'},
  execute: (input, ctx) async => ToolOutput('output-$id'),
);

void main() {
  late PermissionService service;
  late PermissionRuleset rules;
  late ToolRegistry registry;

  setUp(() {
    service = PermissionService();
    rules = PermissionRuleset.defaults();
    registry = ToolRegistry(service, rules);
  });

  group('ToolRegistry — registerDefinition / resolveAll', () {
    test('registerDefinition adds unresolved lazy definition', () {
      final td = ToolDefinition.lazy(
        id: 'lazy-1',
        factory: () async => _tool('lazy-1'),
      );
      registry.registerDefinition(td);

      // Not yet resolved — get() should not find it in _tools
      expect(registry.contains('lazy-1'), isTrue);
      expect(td.isResolved, isFalse);
    });

    test('resolveAll resolves lazy definitions and adds to tools', () async {
      final td = ToolDefinition.lazy(
        id: 'lazy-1',
        factory: () async => _tool('lazy-1'),
      );
      registry.registerDefinition(td);

      await registry.resolveAll();

      expect(td.isResolved, isTrue);
      expect(registry.get('lazy-1'), isNotNull);
      expect(registry.get('lazy-1')!.id, 'lazy-1');
    });

    test('resolveAll skips already-resolved definitions', () async {
      var callCount = 0;
      final td = ToolDefinition.lazy(
        id: 'lazy-1',
        factory: () async {
          callCount++;
          return _tool('lazy-1');
        },
      );
      registry.registerDefinition(td);

      await registry.resolveAll();
      await registry.resolveAll();

      expect(callCount, 1);
    });

    test('resolveAll with eager definition is a no-op', () async {
      final td = ToolDefinition.create(id: 'eager-1', def: _tool('eager-1'));
      registry.registerDefinition(td);

      await registry.resolveAll();

      expect(registry.get('eager-1')!.id, 'eager-1');
    });

    test('resolveAll with multiple definitions', () async {
      final td1 = ToolDefinition.lazy(
        id: 'multi-1',
        factory: () async => _tool('multi-1'),
      );
      final td2 = ToolDefinition.lazy(
        id: 'multi-2',
        factory: () async => _tool('multi-2'),
      );
      registry.registerDefinition(td1);
      registry.registerDefinition(td2);

      await registry.resolveAll();

      expect(registry.ids, containsAll(['multi-1', 'multi-2']));
    });
  });

  group('ToolRegistry — named accessors', () {
    test('task getter returns task tool when registered', () {
      registry.register(_tool('task'));
      expect(registry.task, isNotNull);
      expect(registry.task!.id, 'task');
    });

    test('task getter returns null when not registered', () {
      expect(registry.task, isNull);
    });

    test('read getter returns read tool when registered', () {
      registry.register(_tool('read'));
      expect(registry.read, isNotNull);
      expect(registry.read!.id, 'read');
    });

    test('read getter returns null when not registered', () {
      expect(registry.read, isNull);
    });
  });

  group('ToolRegistry — get with lazy definitions', () {
    test('get returns resolved lazy definition', () async {
      final td = ToolDefinition.lazy(
        id: 'lazy-get',
        factory: () async => _tool('lazy-get'),
      );
      registry.registerDefinition(td);
      // Don't call resolveAll — get() checks isResolved
      expect(registry.get('lazy-get'), isNull);
    });

    test('get returns resolved lazy definition after resolveAll', () async {
      final td = ToolDefinition.lazy(
        id: 'lazy-get-2',
        factory: () async => _tool('lazy-get-2'),
      );
      registry.registerDefinition(td);
      await registry.resolveAll();
      expect(registry.get('lazy-get-2'), isNotNull);
    });
  });

  group('ToolRegistry — all getter', () {
    test('all returns unmodifiable list', () {
      registry.register(_tool('a'));
      final all = registry.all;
      expect(all.length, 1);
      expect(() => all.add(_tool('b')), throwsUnsupportedError);
    });

    test('all reflects tools after resolveAll', () async {
      registry.registerDefinition(
        ToolDefinition.lazy(
          id: 'lazy-all',
          factory: () async => _tool('lazy-all'),
        ),
      );
      await registry.resolveAll();
      expect(registry.all.any((t) => t.id == 'lazy-all'), isTrue);
    });
  });

  group('ToolRegistry — toSDKTools', () {
    test('toSDKTools returns map with all registered tools', () {
      registry.register(_tool('shell'));
      registry.register(_tool('read'));

      final sdkTools = registry.toSDKTools();
      expect(sdkTools.containsKey('shell'), isTrue);
      expect(sdkTools.containsKey('read'), isTrue);
      expect(sdkTools.length, 2);
    });

    test('toSDKTools returns empty map when no tools', () {
      final sdkTools = registry.toSDKTools();
      expect(sdkTools, isEmpty);
    });
  });

  group('ToolRegistry — executor access', () {
    test('executor getter returns ToolExecutor', () {
      final executor = registry.executor;
      expect(executor, isNotNull);
    });
  });

  group('ToolRegistry — pruneSession delegation', () {
    test('pruneSession delegates to executor', () {
      // Should not throw
      registry.pruneSession('test-session');
    });
  });

  group('ToolRegistry — available with mixed rules', () {
    test('available excludes denied tools but includes allowed', () {
      final mixedRules = PermissionRuleset(
        rules: [
          PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      final reg = ToolRegistry(PermissionService(), mixedRules);
      reg.register(_tool('shell'));
      reg.register(_tool('read'));
      reg.register(_tool('write'));

      final avail = reg.available;
      expect(avail.any((t) => t.id == 'shell'), isFalse);
      expect(avail.any((t) => t.id == 'read'), isTrue);
      expect(avail.any((t) => t.id == 'write'), isTrue);
    });
  });

  group('ToolRegistry — remove with definitions', () {
    test('remove works for registered definition', () {
      final td = ToolDefinition.create(id: 'rem-def', def: _tool('rem-def'));
      registry.registerDefinition(td);
      expect(registry.contains('rem-def'), isTrue);

      final result = registry.remove('rem-def');
      expect(result, isTrue);
      expect(registry.contains('rem-def'), isFalse);
    });

    test('remove returns false for non-existent definition', () {
      expect(registry.remove('ghost'), isFalse);
    });
  });

  group('ToolRegistry — duplicate definition registration', () {
    test('registerDefinition does not add duplicate id', () async {
      final td1 = ToolDefinition.create(id: 'dup', def: _tool('dup'));
      final td2 = ToolDefinition.create(id: 'dup', def: _tool('dup'));
      registry.registerDefinition(td1);
      registry.registerDefinition(td2);

      // Only one should be stored — resolveAll should produce exactly one tool
      await registry.resolveAll();
      expect(registry.ids.where((id) => id == 'dup').length, 1);
    });
  });
}
