import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';

void main() {
  late FormatService service;

  setUp(() {
    service = FormatService();
  });

  group('FormatService.status', () {
    test('returns all built-in formatters', () {
      final status = service.status(null);

      expect(status.length, greaterThan(0));
      expect(status.length, equals(26));
    });

    test('all status entries have required fields', () {
      final status = service.status(null);

      for (final entry in status) {
        expect(entry.containsKey('name'), isTrue);
        expect(entry.containsKey('extensions'), isTrue);
        expect(entry.containsKey('enabled'), isTrue);
        expect(entry.containsKey('disabledByConfig'), isTrue);
        expect(entry.containsKey('overridden'), isTrue);
      }
    });

    test('all formatters enabled by default', () {
      final status = service.status(null);

      for (final entry in status) {
        expect(
          entry['enabled'],
          isTrue,
          reason: '${entry['name']} should be enabled by default',
        );
        expect(entry['disabledByConfig'], isFalse);
        expect(entry['overridden'], isFalse);
      }
    });

    test('disabled formatter shows as disabled', () {
      final config = FormatterConfig(
        formatters: {'dart': const FormatterEntryConfig(disabled: true)},
      );

      final status = service.status(config);
      final dart = status.firstWhere((s) => s['name'] == 'dart');

      expect(dart['enabled'], isFalse);
      expect(dart['disabledByConfig'], isTrue);
    });

    test('formatter with custom command shows as overridden', () {
      final config = FormatterConfig(
        formatters: {
          'dart': const FormatterEntryConfig(command: ['custom-dart-format']),
        },
      );

      final status = service.status(config);
      final dart = status.firstWhere((s) => s['name'] == 'dart');

      expect(dart['overridden'], isTrue);
    });

    test('formatter with custom extensions shows updated extensions', () {
      final config = FormatterConfig(
        formatters: {
          'dart': const FormatterEntryConfig(extensions: ['.dart', '.custom']),
        },
      );

      final status = service.status(config);
      final dart = status.firstWhere((s) => s['name'] == 'dart');

      expect(dart['extensions'], equals(['.dart', '.custom']));
      expect(dart['overridden'], isTrue);
    });

    test('formatter with custom environment shows as overridden', () {
      final config = FormatterConfig(
        formatters: {
          'dart': const FormatterEntryConfig(environment: {'CUSTOM': '1'}),
        },
      );

      final status = service.status(config);
      final dart = status.firstWhere((s) => s['name'] == 'dart');

      expect(dart['overridden'], isTrue);
    });

    test('empty config does not affect status', () {
      final config = FormatterConfig(formatters: {});
      final status = service.status(config);

      for (final entry in status) {
        expect(entry['enabled'], isTrue);
        expect(entry['overridden'], isFalse);
      }
    });

    test('multiple disabled formatters', () {
      final config = FormatterConfig(
        formatters: {
          'dart': const FormatterEntryConfig(disabled: true),
          'gofmt': const FormatterEntryConfig(disabled: true),
          'rustfmt': const FormatterEntryConfig(disabled: true),
        },
      );

      final status = service.status(config);
      final disabled = status.where((s) => s['enabled'] == false).toList();

      expect(disabled.length, equals(3));
    });

    test('disabled ruff also disables uv in status', () {
      final config = FormatterConfig(
        formatters: {'ruff': const FormatterEntryConfig(disabled: true)},
      );

      final status = service.status(config);
      final ruff = status.firstWhere((s) => s['name'] == 'ruff');
      final uv = status.firstWhere((s) => s['name'] == 'uv');

      expect(ruff['enabled'], isFalse);
      expect(uv['enabled'], isFalse);
    });

    test('disabled uv also disables ruff in status', () {
      final config = FormatterConfig(
        formatters: {'uv': const FormatterEntryConfig(disabled: true)},
      );

      final status = service.status(config);
      final ruff = status.firstWhere((s) => s['name'] == 'ruff');
      final uv = status.firstWhere((s) => s['name'] == 'uv');

      expect(ruff['enabled'], isFalse);
      expect(uv['enabled'], isFalse);
    });
  });

  group('FormatResult', () {
    test('creates with required fields only', () {
      final result = FormatResult(
        formattedContent: 'formatted',
        formatter: 'dart',
      );

      expect(result.formattedContent, equals('formatted'));
      expect(result.formatter, equals('dart'));
      expect(result.changed, isFalse);
      expect(result.error, isNull);
      expect(result.originalContent, isNull);
    });

    test('creates with all fields', () {
      final result = FormatResult(
        originalContent: 'original',
        formattedContent: 'formatted',
        formatter: 'dart',
        changed: true,
        error: null,
      );

      expect(result.originalContent, equals('original'));
      expect(result.changed, isTrue);
    });

    test('defaults changed to false', () {
      final result = FormatResult(
        formattedContent: 'content',
        formatter: 'test',
      );

      expect(result.changed, isFalse);
    });

    test('can represent error result', () {
      final result = FormatResult(
        formattedContent: '',
        formatter: 'unknown',
        error: 'No suitable formatter found',
      );

      expect(result.error, isNotNull);
      expect(result.changed, isFalse);
    });

    test('can represent unchanged result', () {
      final result = FormatResult(
        originalContent: 'same',
        formattedContent: 'same',
        formatter: 'dart',
        changed: false,
      );

      expect(result.changed, isFalse);
      expect(result.originalContent, equals(result.formattedContent));
    });
  });

  group('FormatService.formatFile', () {
    test('returns no formatter for unsupported extension', () async {
      final dir = Directory.systemTemp.createTempSync();
      final file = File('${dir.path}/file.xyz');
      await file.writeAsString('hello');

      final result = await service.formatFile(file.path);

      expect(result.formatter, equals('none'));
      expect(result.error, contains('No suitable formatter'));
      expect(result.changed, isFalse);

      dir.delete(recursive: true);
    });

    test('non-existent file returns error', () async {
      final result = await service.formatFile(
        '/tmp/_not_a_real_file_98765.xyz',
      );
      expect(result.error, isNotNull);
      expect(result.formatter, equals('unknown'));
    });

    test('skips disabled preferred formatter', () async {
      final dir = Directory.systemTemp.createTempSync();
      final file = File('${dir.path}/script.py');
      await file.writeAsString('x=1');

      final result = await service.formatFile(
        file.path,
        preferredFormatter: 'ruff',
        formatterConfig: const FormatterConfig(
          formatters: {'ruff': FormatterEntryConfig(disabled: true)},
        ),
      );

      // When ruff is disabled, it should not be selected as the formatter.
      // The result should be 'none' since both ruff and uv are linked-disabled.
      // If the test environment has ruff installed, the code should still
      // respect the disabled flag and not use it.
      expect(result.formatter, isNot(equals('ruff')));

      dir.delete(recursive: true);
    });
  });

  group('FormatService.applyFix', () {
    test('throws on unreadable file', () async {
      expect(
        () => service.applyFix('/tmp/_not_a_real_file_apply_fix_.dart'),
        throwsA(isA<Exception>()),
      );
    });

    test('returns path when successful', () async {
      final dir = Directory.systemTemp.createTempSync();
      final file = File('${dir.path}/main.dart');
      await file.writeAsString('void main(){}');

      final resultPath = await service.applyFix(file.path);
      expect(resultPath, equals(file.path));

      dir.delete(recursive: true);
    });
  });

  group('FormatService singleton', () {
    test('instance returns same object', () {
      final a = FormatService.instance;
      final b = FormatService();
      expect(identical(a, b), isTrue);
    });

    test('instance has same hashCode as factory', () {
      final a = FormatService.instance;
      final b = FormatService();
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('FormatService.formatFile with custom command override', () {
    test(
      'uses custom command when override provided for matching extension',
      () async {
        // This test verifies that when a custom command is provided in the config
        // and the file extension matches, the override is used.
        // We use .dart extension and provide a custom command that always works.
        final dir = Directory.systemTemp.createTempSync();
        final file = File('${dir.path}/test.dart');
        await file.writeAsString('void main(){}');

        final result = await service.formatFile(
          file.path,
          formatterConfig: FormatterConfig(
            formatters: {
              'dart': const FormatterEntryConfig(
                command: ['echo', 'custom_output'],
              ),
            },
          ),
        );

        // The dart formatter is in the candidates, override command runs,
        // and since `echo` succeeds, the result should be 'custom_output'
        expect(result.formatter, equals('dart'));
        expect(result.formattedContent.trim(), equals('custom_output'));
        expect(result.changed, isTrue);
        expect(result.error, isNull);

        dir.delete(recursive: true);
      },
    );
  });

  group('FormatService.formatFile with preferred formatter', () {
    test('accepted valid preferred formatter', () async {
      final dir = Directory.systemTemp.createTempSync();
      final file = File('${dir.path}/test.txt');
      await file.writeAsString('hello');

      // 'unknown' is not a built-in formatter so it will not match,
      // but the preferredFormatter param just adds it to candidates first
      final result = await service.formatFile(
        file.path,
        preferredFormatter: 'nonexistent',
      );

      expect(result.error, contains('No suitable formatter'));

      dir.delete(recursive: true);
    });
  });
}
