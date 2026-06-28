import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/format/formatter_definition.dart';

void main() {
  group('FormatContext', () {
    test('creates with required fields', () {
      const ctx = FormatContext(
        filePath: '/project/lib/main.dart',
        projectRoot: '/project',
      );

      expect(ctx.filePath, equals('/project/lib/main.dart'));
      expect(ctx.projectRoot, equals('/project'));
      expect(ctx.config, isEmpty);
    });

    test('creates with custom config', () {
      const ctx = FormatContext(
        filePath: '/project/lib/main.dart',
        projectRoot: '/project',
        config: {'lineLength': 120},
      );

      expect(ctx.config['lineLength'], equals(120));
    });

    test('supports equality comparison', () {
      const ctx1 = FormatContext(filePath: '/a/b.dart', projectRoot: '/a');
      const ctx2 = FormatContext(filePath: '/a/b.dart', projectRoot: '/a');

      expect(ctx1.filePath, equals(ctx2.filePath));
      expect(ctx1.projectRoot, equals(ctx2.projectRoot));
      expect(ctx1.config, equals(ctx2.config));
    });
  });

  group('FormatterDefinition', () {
    test('creates with all fields', () {
      Future<List<String>?> enable(FormatContext ctx) async => ['fmt'];

      final def = FormatterDefinition(
        name: 'myfmt',
        extensions: ['.dart', '.txt'],
        environment: {'PATH': '/usr/bin'},
        enabled: enable,
      );

      expect(def.name, equals('myfmt'));
      expect(def.extensions, equals(['.dart', '.txt']));
      expect(def.environment, equals({'PATH': '/usr/bin'}));
      expect(def.enabled, equals(enable));
    });

    test('creates without optional fields', () {
      Future<List<String>?> enable(FormatContext ctx) async => null;

      final def = FormatterDefinition(
        name: 'simple',
        extensions: ['.txt'],
        enabled: enable,
      );

      expect(def.name, equals('simple'));
      expect(def.extensions, equals(['.txt']));
      expect(def.environment, isNull);
    });

    test('works with const declarations', () {
      const def = FormatterDefinition(
        name: 'const_fmt',
        extensions: ['.md'],
        enabled: _stubEnable,
      );

      expect(def.name, equals('const_fmt'));
      expect(def.environment, isNull);
    });

    test('can be used in a map', () {
      const def1 = FormatterDefinition(
        name: 'fmt1',
        extensions: ['.a'],
        enabled: _stubEnable,
      );
      const def2 = FormatterDefinition(
        name: 'fmt2',
        extensions: ['.b'],
        enabled: _stubEnable,
      );

      final map = {'fmt1': def1, 'fmt2': def2};

      expect(map['fmt1']!.name, equals('fmt1'));
      expect(map['fmt2']!.extensions, equals(['.b']));
    });

    test('extensions list is accessible', () {
      const def = FormatterDefinition(
        name: 'multi',
        extensions: ['.a', '.b', '.c'],
        enabled: _stubEnable,
      );

      expect(def.extensions.length, equals(3));
      expect(def.extensions, contains('.a'));
      expect(def.extensions, contains('.b'));
      expect(def.extensions, contains('.c'));
    });

    test('environment map is mutable reference', () {
      final env = {'KEY': 'val'};
      final def = FormatterDefinition(
        name: 'envfmt',
        extensions: ['.x'],
        environment: env,
        enabled: _stubEnable,
      );

      expect(def.environment!['KEY'], equals('val'));
    });
  });

  group('FormatterEntry', () {
    test('creates with all fields', () {
      const entry = FormatterEntry(
        disabled: true,
        command: ['myfmt', '--write'],
        environment: {'FOO': 'bar'},
        extensions: ['.foo', '.bar'],
      );

      expect(entry.disabled, isTrue);
      expect(entry.command, equals(['myfmt', '--write']));
      expect(entry.environment, equals({'FOO': 'bar'}));
      expect(entry.extensions, equals(['.foo', '.bar']));
    });

    test('creates with no fields', () {
      const entry = FormatterEntry();

      expect(entry.disabled, isNull);
      expect(entry.command, isNull);
      expect(entry.environment, isNull);
      expect(entry.extensions, isNull);
    });

    test('creates with only disabled', () {
      const entry = FormatterEntry(disabled: false);

      expect(entry.disabled, isFalse);
      expect(entry.command, isNull);
      expect(entry.environment, isNull);
      expect(entry.extensions, isNull);
    });

    test('fromJson parses all fields', () {
      final json = {
        'disabled': true,
        'command': ['fmt', '-w'],
        'environment': {'PATH': '/bin'},
        'extensions': ['.py', '.pyi'],
      };

      final entry = FormatterEntry.fromJson(json);

      expect(entry.disabled, isTrue);
      expect(entry.command, equals(['fmt', '-w']));
      expect(entry.environment, equals({'PATH': '/bin'}));
      expect(entry.extensions, ['.py', '.pyi']);
    });

    test('fromJson handles partial fields', () {
      final json = {'disabled': false};

      final entry = FormatterEntry.fromJson(json);

      expect(entry.disabled, isFalse);
      expect(entry.command, isNull);
      expect(entry.environment, isNull);
      expect(entry.extensions, isNull);
    });

    test('fromJson handles empty map', () {
      final entry = FormatterEntry.fromJson({});

      expect(entry.disabled, isNull);
      expect(entry.command, isNull);
      expect(entry.environment, isNull);
      expect(entry.extensions, isNull);
    });

    test('toJson serializes all fields', () {
      const entry = FormatterEntry(
        disabled: true,
        command: ['fmt'],
        environment: {'A': '1'},
        extensions: ['.x'],
      );

      final json = entry.toJson();

      expect(json['disabled'], isTrue);
      expect(json['command'], equals(['fmt']));
      expect(json['environment'], equals({'A': '1'}));
      expect(json['extensions'], equals(['.x']));
    });

    test('toJson omits null fields', () {
      const entry = FormatterEntry(disabled: true);

      final json = entry.toJson();

      expect(json['disabled'], isTrue);
      expect(json.containsKey('command'), isFalse);
      expect(json.containsKey('environment'), isFalse);
      expect(json.containsKey('extensions'), isFalse);
    });

    test('toJson returns empty map when all null', () {
      const entry = FormatterEntry();

      final json = entry.toJson();

      expect(json, isEmpty);
    });

    test('fromJson/toJson roundtrip', () {
      const original = FormatterEntry(
        disabled: false,
        command: ['tool', '--flag'],
        environment: {'KEY': 'val'},
        extensions: ['.a', '.b'],
      );

      final json = original.toJson();
      final restored = FormatterEntry.fromJson(json);

      expect(restored.disabled, equals(original.disabled));
      expect(restored.command, equals(original.command));
      expect(restored.environment, equals(original.environment));
      expect(restored.extensions, equals(original.extensions));
    });

    test('fromJson handles list with mixed types gracefully', () {
      final json = {
        'command': ['cmd'],
        'extensions': ['ext'],
      };

      final entry = FormatterEntry.fromJson(json);

      expect(entry.command, equals(['cmd']));
      expect(entry.extensions, equals(['ext']));
    });

    test('fromJson handles command as non-null but empty list', () {
      final json = {'command': []};

      final entry = FormatterEntry.fromJson(json);

      expect(entry.command, isEmpty);
    });

    test('extensions list preserves order', () {
      final json = {
        'extensions': ['.z', '.a', '.m'],
      };

      final entry = FormatterEntry.fromJson(json);

      expect(entry.extensions, equals(['.z', '.a', '.m']));
    });
  });
}

Future<List<String>?> _stubEnable(FormatContext ctx) async => null;
