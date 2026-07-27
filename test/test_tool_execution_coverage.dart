import 'dart:async';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool_execution.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_error.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/permission/rule.dart';

ToolDef _tool(
  String id,
  Future<ToolOutput> Function(Map<String, dynamic>, dynamic) fn,
) => ToolDef(id: id, description: '', inputSchema: const {}, execute: fn);

dynamic _ctx(String? sessionId) {
  final map = <String, dynamic>{};
  if (sessionId != null) map['experimentalContext'] = {'sessionId': sessionId};
  return map;
}

PermissionRule r(String perm, String pattern, String action) => PermissionRule(
  permission: perm,
  pattern: pattern,
  action: PermissionAction.values.firstWhere((a) => a.name == action),
);

void main() {
  late PermissionService ps;
  late ToolExecutor ex;

  setUp(() {
    ps = PermissionService();
    ps.seedRules(
      PermissionRuleset(
        rules: [
          r('read', '*', 'allow'),
          r('write', '*', 'allow'),
          r('edit', '*', 'allow'),
          r('shell', '*', 'allow'),
          r('question', '*', 'allow'),
          r('doom_loop', '*', 'allow'),
        ],
      ),
    );
    ex = ToolExecutor(
      ps,
      PermissionRuleset(
        rules: [
          r('read', '*', 'allow'),
          r('write', '*', 'allow'),
          r('edit', '*', 'allow'),
          r('shell', '*', 'allow'),
          r('question', '*', 'allow'),
          r('doom_loop', '*', 'allow'),
        ],
      ),
    );
  });

  group('ToolExecutor — execute paths', () {
    test('non-Map input wrapped to {"raw": input}', () async {
      final tool = _tool(
        'echo',
        (input, ctx) async => ToolOutput(input['raw'].toString()),
      );
      final r = await ex.execute(tool, {'raw': 'hello'}, _ctx('s1'));
      expect(r['output'], 'hello');
    });

    test('ToolInvalidArgsError produces error JSON', () async {
      final tool = _tool(
        'bad',
        (input, ctx) async => throw ToolInvalidArgsError('bad', 'bad args'),
      );
      final r = await ex.execute(tool, {'a': 1}, _ctx('s1'));
      expect(r['error'], 'invalid_args');
      expect(r['toolName'], 'bad');
    });

    test('ToolOverflowError produces error JSON', () async {
      final tool = _tool(
        'big',
        (input, ctx) async => throw ToolOverflowError('big', 'too big'),
      );
      final r = await ex.execute(tool, {'a': 1}, _ctx('s1'));
      expect(r['error'], 'overflow');
      expect(r['toolName'], 'big');
    });

    test('unexpected StateError is rethrown', () async {
      final tool = _tool(
        'boom',
        (input, ctx) async => throw StateError('boom'),
      );
      expect(
        () => ex.execute(tool, {'a': 1}, _ctx('s1')),
        throwsA(isA<StateError>()),
      );
    });

    test('ToolOutput.metadata surfaced in result', () async {
      final tool = _tool(
        'meta',
        (input, ctx) async => ToolOutput('ok', metadata: {'tokens': 7}),
      );
      final r = await ex.execute(tool, {}, _ctx('s1'));
      expect(r['metadata']['tokens'], 7);
    });

    test('no metadata key when ToolOutput has none', () async {
      final tool = _tool('plain', (input, ctx) async => ToolOutput('ok'));
      final r = await ex.execute(tool, {}, _ctx('s1'));
      expect(r.containsKey('metadata'), isFalse);
    });

    test('identical same-session call returns cached output', () async {
      var count = 0;
      final tool = _tool(
        'cached',
        (input, ctx) async => ToolOutput('call-${++count}'),
      );

      final r1 = await ex.execute(tool, {'p': 'v'}, _ctx('s1'));
      expect(r1['output'], 'call-1');

      final r2 = await ex.execute(tool, {'p': 'v'}, _ctx('s1'));
      expect(r2['output'], 'call-1');
    });

    test('cross-session same input is not cached', () async {
      var count = 0;
      final tool = _tool(
        'cross',
        (input, ctx) async => ToolOutput('call-${++count}'),
      );

      await ex.execute(tool, {'p': 'v'}, _ctx('s1'));
      await ex.execute(tool, {'p': 'v'}, _ctx('s2'));

      expect(count, 2);
    });

    test('large output is truncated', () async {
      final tool = _tool('big', (input, ctx) async => ToolOutput('x' * 60000));
      final r = await ex.execute(tool, {}, _ctx('s1'));
      expect((r['output'] as String).length, lessThan(60000));
    });

    test('ctx.sessionId reflects session from options', () async {
      String? captured;
      final tool = _tool('sess', (input, ctx) async {
        captured = (ctx as dynamic).sessionId as String?;
        return ToolOutput('ok');
      });

      await ex.execute(tool, {}, _ctx('s42'));
      expect(captured, 's42');
    });
  });

  group('ToolExecutor — pruneSession', () {
    test('invocation does not throw', () async {
      final tool = _tool('warm', (input, ctx) async => ToolOutput('ok'));
      await ex.execute(tool, {'a': 1}, _ctx('warm-session'));
      expect(() => ex.pruneSession('warm-session'), returnsNormally);
    });

    test('pruning busts cache for pruned session', () async {
      var count = 0;
      final tool = _tool(
        'cold',
        (input, ctx) async => ToolOutput('call-${++count}'),
      );

      await ex.execute(tool, {'a': 1}, _ctx('cold-session'));
      expect(count, 1);

      ex.pruneSession('cold-session');

      await ex.execute(tool, {'a': 1}, _ctx('cold-session'));
      expect(count, 2);
    });
  });
}
