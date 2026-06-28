import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';

void main() {
  group('FormatterConfig model', () {
    test('roundtrips through toJson/fromJson', () {
      final config = FormatterConfig(
        formatters: {
          'myfmt': FormatterEntryConfig(
            disabled: true,
            command: ['myfmt', '--write', r'$FILE'],
            environment: {'FOO': 'bar'},
            extensions: ['.foo', '.bar'],
          ),
        },
      );

      final json = config.toJson();
      final restored = FormatterConfig.fromJson(json);

      final entry = restored.formatters['myfmt']!;
      expect(entry.disabled, true);
      expect(entry.command, equals(['myfmt', '--write', r'$FILE']));
      expect(entry.environment, equals({'FOO': 'bar'}));
      expect(entry.extensions, equals(['.foo', '.bar']));
    });

    test('omits empty/null fields in toJson', () {
      final config = const FormatterConfig();
      final json = config.toJson();
      expect(json, isEmpty);
    });
  });

  group('FormatService config override', () {
    test('disabled formatter is excluded from candidates', () async {
      final dir = Directory.systemTemp.createTempSync();
      final file = File('${dir.path}/script.py');
      await file.writeAsString('x=1');

      final service = FormatService();
      final withOverride = await service.formatFile(
        file.path,
        formatterConfig: const FormatterConfig(
          formatters: {'ruff': FormatterEntryConfig(disabled: true)},
        ),
      );

      expect(withOverride.formatter, isNot(equals('ruff')));

      dir.delete(recursive: true);
    });

    test('ruff/uv linked disable', () async {
      final config = FormatterConfig(
        formatters: {'ruff': const FormatterEntryConfig(disabled: true)},
      );
      final status = FormatService().status(config);

      final names = status.map((s) => s['name'] as String).toList();
      expect(names, contains('ruff'));
      expect(names, contains('uv')); // both listed but disabled

      final ruffStatus = status.firstWhere((s) => s['name'] == 'ruff');
      final uvStatus = status.firstWhere((s) => s['name'] == 'uv');
      expect(ruffStatus['enabled'], isFalse);
      expect(uvStatus['enabled'], isFalse);
    });

    test('status reflects override state', () {
      final config = FormatterConfig(
        formatters: {
          'prettier': const FormatterEntryConfig(
            disabled: true,
            extensions: ['.foo'],
          ),
        },
      );
      final status = FormatService().status(config);
      final prettier = status.firstWhere((s) => s['name'] == 'prettier');

      expect(prettier['enabled'], isFalse);
      expect(prettier['disabledByConfig'], isTrue);
      expect(prettier['extensions'], equals(['.foo']));
      expect(prettier['overridden'], isTrue);
    });
  });
}
