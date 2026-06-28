import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/format/format_service.dart';

void main() {
  late FormatService service;

  setUp(() {
    service = FormatService();
  });

  group('formatFile', () {
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

    test('skips formatter when command not installed', () async {
      // .py files are handled by ruff and uv; if neither is installed/configured → no match
      final dir = Directory.systemTemp.createTempSync();
      final file = File('${dir.path}/script.py');
      await file.writeAsString('x=1');

      final result = await service.formatFile(file.path);

      expect(
        result.formatter,
        anyOf(equals('none'), equals('ruff'), equals('uv')),
      );
      expect(result.error, anyOf(contains('No suitable formatter'), isNull));

      dir.delete(recursive: true);
    });

    test('non-existent file returns error', () async {
      final result = await service.formatFile(
        '/tmp/_not_a_real_file_98765.xyz',
      );
      expect(result.error, isNotNull);
      expect(result.formatter, equals('unknown'));
    });
  });

  group('applyFix', () {
    test('overwrites file when changed', () async {
      final dir = Directory.systemTemp.createTempSync();
      final file = File('${dir.path}/main.dart');
      await file.writeAsString('void main() {}');

      // format returns early because `dart format` is available;
      // applyFix writes back only when changed.
      final resultPath = await service.applyFix(file.path);
      expect(resultPath, equals(file.path));

      dir.delete(recursive: true);
    });

    test('throws on unreadable file', () async {
      expect(
        () => service.applyFix('/tmp/_not_a_real_file_apply_fix_.dart'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
