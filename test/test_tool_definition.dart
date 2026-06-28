import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/tool_definition.dart';
import 'package:chatorai/core/tools/tool.dart';

ToolDef _dummyDef() => ToolDef(
  id: 'dummy',
  description: 'dummy tool',
  inputSchema: {'type': 'object'},
  execute: (input, ctx) async => const ToolOutput('dummy'),
);

Future<ToolDef> _asyncDummyDef() async => _dummyDef();

void main() {
  group('ToolTag', () {
    test('default constructor: not experimental, not hidden, no category', () {
      const tag = ToolTag();
      expect(tag.category, isNull);
      expect(tag.experimental, isFalse);
      expect(tag.hidden, isFalse);
    });

    test('hidden named constructor sets hidden=true, rest defaults', () {
      const tag = ToolTag.hidden();
      expect(tag.hidden, isTrue);
      expect(tag.experimental, isFalse);
      expect(tag.category, isNull);
    });

    test(
      'experimental named constructor sets experimental=true, category set',
      () {
        const tag = ToolTag.experimental('nav');
        expect(tag.experimental, isTrue);
        expect(tag.category, 'nav');
        expect(tag.hidden, isFalse);
      },
    );

    test('experimental with null category', () {
      const tag = ToolTag.experimental(null);
      expect(tag.experimental, isTrue);
      expect(tag.category, isNull);
    });

    test('custom values via default constructor', () {
      const tag = ToolTag(category: 'io', experimental: true, hidden: true);
      expect(tag.category, 'io');
      expect(tag.experimental, isTrue);
      expect(tag.hidden, isTrue);
    });
  });

  group('ToolDefinition.create (eager)', () {
    test('isResolved is true immediately', () {
      final def = _dummyDef();
      final td = ToolDefinition.create(id: 'eager', def: def);
      expect(td.isResolved, isTrue);
      expect(td.id, 'eager');
    });

    test('def getter returns the provided ToolDef', () {
      final def = _dummyDef();
      final td = ToolDefinition.create(id: 'eager', def: def);
      expect(td.def, same(def));
    });

    test('resolve() returns the same def without re-calling factory', () async {
      final def = _dummyDef();
      final td = ToolDefinition.create(id: 'eager', def: def);
      final resolved = await td.resolve();
      expect(resolved, same(def));
    });

    test('default tag is used when none provided', () {
      final td = ToolDefinition.create(id: 'eager', def: _dummyDef());
      expect(td.tag.experimental, isFalse);
      expect(td.tag.hidden, isFalse);
      expect(td.tag.category, isNull);
    });

    test('custom tag is preserved', () {
      const tag = ToolTag.experimental('io');
      final td = ToolDefinition.create(id: 'eager', tag: tag, def: _dummyDef());
      expect(td.tag.experimental, isTrue);
      expect(td.tag.category, 'io');
    });
  });

  group('ToolDefinition.lazy', () {
    test('isResolved is false before resolve()', () {
      final td = ToolDefinition.lazy(id: 'lazy', factory: _asyncDummyDef);
      expect(td.isResolved, isFalse);
    });

    test('def getter throws StateError before resolve()', () {
      final td = ToolDefinition.lazy(id: 'lazy', factory: _asyncDummyDef);
      expect(() => td.def, throwsStateError);
    });

    test('resolve() calls factory and caches result', () async {
      var callCount = 0;
      final td = ToolDefinition.lazy(
        id: 'lazy',
        factory: () async {
          callCount++;
          return _asyncDummyDef();
        },
      );

      expect(td.isResolved, isFalse);
      final r1 = await td.resolve();
      final r2 = await td.resolve();
      expect(callCount, 1);
      expect(r1, same(r2));
      expect(td.isResolved, isTrue);
    });

    test('def getter works after resolve()', () async {
      final td = ToolDefinition.lazy(id: 'lazy', factory: _asyncDummyDef);
      await td.resolve();
      expect(() => td.def, returnsNormally);
    });

    test('factory exception propagates through resolve()', () async {
      final td = ToolDefinition.lazy(
        id: 'lazy',
        factory: () async {
          throw StateError('factory boom');
        },
      );
      expect(() => td.resolve(), throwsStateError);
    });

    test('default tag when none provided', () {
      final td = ToolDefinition.lazy(id: 'lazy', factory: _asyncDummyDef);
      expect(td.tag.experimental, isFalse);
      expect(td.tag.hidden, isFalse);
    });

    test('custom tag preserved on lazy definition', () {
      const tag = ToolTag.hidden();
      final td = ToolDefinition.lazy(
        id: 'lazy',
        tag: tag,
        factory: _asyncDummyDef,
      );
      expect(td.tag.hidden, isTrue);
    });
  });

  group('ToolDefinition.id', () {
    test('id is preserved on both eager and lazy', () {
      final eager = ToolDefinition.create(id: 'eager-id', def: _dummyDef());
      final lazy = ToolDefinition.lazy(id: 'lazy-id', factory: _asyncDummyDef);
      expect(eager.id, 'eager-id');
      expect(lazy.id, 'lazy-id');
    });
  });
}
