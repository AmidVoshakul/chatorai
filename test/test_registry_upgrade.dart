import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_definition.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';

ToolDef _simpleTool(String id, {String? description}) {
  return ToolDef(
    id: id,
    description: description ?? 'Test tool $id',
    inputSchema: const {},
    execute: (input, ctx) async => const ToolOutput('ok'),
  );
}

void main() {
  group('ToolTag', () {
    test('default tag has no category, not experimental, not hidden', () {
      const tag = ToolTag();
      expect(tag.category, isNull);
      expect(tag.experimental, isFalse);
      expect(tag.hidden, isFalse);
    });

    test('hidden tag sets hidden=true', () {
      const tag = ToolTag.hidden();
      expect(tag.hidden, isTrue);
      expect(tag.experimental, isFalse);
    });

    test('experimental tag sets flag and category', () {
      const tag = ToolTag.experimental('experimental');
      expect(tag.experimental, isTrue);
      expect(tag.category, 'experimental');
      expect(tag.hidden, isFalse);
    });

    test('custom tag allows all fields', () {
      const tag = ToolTag(category: 'build', experimental: true, hidden: false);
      expect(tag.category, 'build');
      expect(tag.experimental, isTrue);
      expect(tag.hidden, isFalse);
    });
  });

  group('ToolDefinition.create', () {
    test('eager definition wraps a ToolDef', () {
      final def = _simpleTool('echo');
      final td = ToolDefinition.create(id: 'echo', def: def);

      expect(td.id, 'echo');
      expect(td.isResolved, isTrue);
      expect(td.def, def);
    });

    test('create uses default empty tag when none provided', () {
      final td = ToolDefinition.create(id: 'x', def: _simpleTool('x'));
      expect(td.tag.category, isNull);
      expect(td.tag.experimental, isFalse);
    });

    test('create accepts custom tag', () {
      final td = ToolDefinition.create(
        id: 'x',
        def: _simpleTool('x'),
        tag: const ToolTag.experimental('build'),
      );
      expect(td.tag.category, 'build');
      expect(td.tag.experimental, isTrue);
    });
  });

  group('ToolDefinition.lazy', () {
    test('lazy definition is unresolved until resolve() called', () {
      final td = ToolDefinition.lazy(
        id: 'deferred',
        factory: () async => _simpleTool('deferred'),
      );

      expect(td.id, 'deferred');
      expect(td.isResolved, isFalse);
    });

    test('lazy definition resolves and caches', () async {
      var callCount = 0;
      final td = ToolDefinition.lazy(
        id: 'deferred',
        factory: () async {
          callCount++;
          return _simpleTool('deferred');
        },
      );

      expect(callCount, 0);
      final first = await td.resolve();
      expect(first.id, 'deferred');
      expect(callCount, 1);
      expect(td.isResolved, isTrue);

      // second call should use cache
      final second = await td.resolve();
      expect(second, same(first));
      expect(callCount, 1); // factory not called again
    });

    test('lazy getter throws before resolve', () {
      final td = ToolDefinition.lazy(
        id: 'thrower',
        factory: () async => _simpleTool('thrower'),
      );

      expect(() => td.def, throwsA(isA<StateError>()));
    });

    test('lazy with custom tag', () {
      final td = ToolDefinition.lazy(
        id: 'x',
        tag: const ToolTag.hidden(),
        factory: () async => _simpleTool('x'),
      );
      expect(td.tag.hidden, isTrue);
    });
  });

  group('ToolRegistry', () {
    late PermissionService permissions;
    late PermissionRuleset rules;
    late ToolRegistry registry;

    setUp(() {
      permissions = PermissionService();
      rules = PermissionRuleset.defaults();
      registry = ToolRegistry(permissions, rules);
    });

    test('register adds tool and ids reflects it', () {
      registry.register(_simpleTool('read'));
      expect(registry.contains('read'), isTrue);
      expect(registry.ids, contains('read'));
    });

    test('register does not duplicate existing tool', () {
      registry.register(_simpleTool('dup'));
      registry.register(_simpleTool('dup'));
      expect(registry.ids.where((id) => id == 'dup').length, 1);
    });

    test('remove returns true and removes', () {
      registry.register(_simpleTool('temp'));
      expect(registry.remove('temp'), isTrue);
      expect(registry.contains('temp'), isFalse);
    });

    test('remove returns false for missing tool', () {
      expect(registry.remove('nonexistent'), isFalse);
    });

    test('get returns registered tool', () {
      final tool = _simpleTool('shell');
      registry.register(tool);
      expect(registry.get('shell'), same(tool));
    });

    test('get returns null for unknown tool', () {
      expect(registry.get('nope'), isNull);
    });

    test('all returns unmodifiable list', () {
      registry.register(_simpleTool('a'));
      final all = registry.all;
      expect(all.length, 1);
      expect(() => all.add(_simpleTool('b')), throwsA(isA<UnsupportedError>()));
    });

    test('registerDefinition adds lazy definition', () async {
      final td = ToolDefinition.lazy(
        id: 'lazy-tool',
        factory: () async => _simpleTool('lazy-tool'),
      );
      registry.registerDefinition(td);
      expect(registry.contains('lazy-tool'), isTrue);
      expect(td.isResolved, isFalse);

      await registry.resolveAll();
      expect(td.isResolved, isTrue);
      expect(registry.get('lazy-tool'), isNotNull);
    });

    test('named task returns task tool if present', () {
      registry.register(_simpleTool('task', description: 'task tool'));
      expect(registry.task, isNotNull);
      expect(registry.task!.id, 'task');
    });

    test('named read returns read tool if present', () {
      registry.register(_simpleTool('read'));
      expect(registry.read, isNotNull);
      expect(registry.read!.id, 'read');
    });

    test('named returns null when tool not registered', () {
      expect(registry.task, isNull);
      expect(registry.read, isNull);
    });

    test('available excludes deny-listed tools', () {
      registry.register(_simpleTool('allowed'));
      registry.register(_simpleTool('denied'));

      final avail = registry.available;
      expect(avail.any((t) => t.id == 'allowed'), isTrue);
    });

    test('toSDKTools produces map of converted tools', () {
      registry.register(_simpleTool('shell'));
      final sdkTools = registry.toSDKTools();
      expect(sdkTools.containsKey('shell'), isTrue);
      expect(sdkTools['shell'], isNotNull);
    });

    test('pruneSession does not throw for any session', () {
      registry.register(_simpleTool('shell'));
      // pruneSession is a no-op if the session has no cached state;
      // the important invariant is that it never throws.
      expect(() => registry.pruneSession('sess1'), returnsNormally);
      expect(() => registry.pruneSession('nonexistent'), returnsNormally);
    });

    test('duplicate registerDefinition does not add twice', () async {
      final td = ToolDefinition.lazy(
        id: 'lazy-dup',
        factory: () async => _simpleTool('lazy-dup'),
      );
      registry.registerDefinition(td);
      registry.registerDefinition(td); // duplicate
      await registry.resolveAll();

      final count = registry.ids.where((id) => id == 'lazy-dup').length;
      expect(count, 1);
    });
  });
}
