import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/format/format_utils.dart';

void main() {
  group('readJson', () {
    test('reads and parses valid JSON file', () async {
      final file = File(
        '/tmp/_test_read_json_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString('{"key": "value", "number": 42}');

      final result = await readJson(file.path);

      expect(result['key'], equals('value'));
      expect(result['number'], equals(42));

      await file.delete();
    });

    test('parses nested JSON objects', () async {
      final file = File(
        '/tmp/_test_read_json_nested_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString('{"outer": {"inner": "nested"}}');

      final result = await readJson(file.path);

      expect(result['outer']['inner'], equals('nested'));

      await file.delete();
    });

    test('parses JSON arrays', () async {
      final file = File(
        '/tmp/_test_read_json_array_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString('{"items": [1, 2, 3]}');

      final result = await readJson(file.path);

      expect(result['items'], equals([1, 2, 3]));

      await file.delete();
    });

    test('parses empty JSON object', () async {
      final file = File(
        '/tmp/_test_read_json_empty_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString('{}');

      final result = await readJson(file.path);

      expect(result, isEmpty);

      await file.delete();
    });

    test('throws on invalid JSON', () async {
      final file = File(
        '/tmp/_test_read_json_invalid_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString('{invalid json}');

      expect(() => readJson(file.path), throwsA(anything));

      await file.delete();
    });

    test('throws on missing file', () {
      expect(
        () => readJson('/tmp/_nonexistent_read_json_file.json'),
        throwsA(anything),
      );
    });

    test('handles JSON with unicode characters', () async {
      final file = File(
        '/tmp/_test_read_json_unicode_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString('{"emoji": "🎉", "japanese": "日本語"}');

      final result = await readJson(file.path);

      expect(result['emoji'], equals('🎉'));
      expect(result['japanese'], equals('日本語'));

      await file.delete();
    });

    test('handles JSON with null values', () async {
      final file = File(
        '/tmp/_test_read_json_null_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString('{"key": null}');

      final result = await readJson(file.path);

      expect(result.containsKey('key'), isTrue);
      expect(result['key'], isNull);

      await file.delete();
    });
  });

  group('ProcessTextResult', () {
    test('creates with text and code', () {
      const result = ProcessTextResult(text: 'output', code: 0);

      expect(result.text, equals('output'));
      expect(result.code, equals(0));
    });

    test('creates with empty text', () {
      const result = ProcessTextResult(text: '', code: -1);

      expect(result.text, equals(''));
      expect(result.code, equals(-1));
    });

    test('can be used to represent error', () {
      const result = ProcessTextResult(text: '', code: 1);

      expect(result.code, isNot(0));
    });

    test('can be used for timeout', () {
      const result = ProcessTextResult(text: '', code: -1);

      expect(result.code, equals(-1));
    });
  });

  group('processText edge cases', () {
    test('returns code 0 for successful command', () async {
      final result = await processText(['echo', 'test']);

      expect(result.code, equals(0));
      expect(result.text.trim(), equals('test'));
    });

    test('returns non-zero code for failing command', () async {
      final result = await processText(['ls', '/nonexistent_path_xyz_12345']);

      expect(result.code, isNot(0));
    });

    test('handles command with arguments', () async {
      final result = await processText(['echo', 'hello', 'world']);

      expect(result.code, equals(0));
      expect(result.text.trim(), equals('hello world'));
    });

    test('handles environment variables', () async {
      final result = await processText(
        ['env'],
        environment: {'CUSTOM_TEST_VAR': 'custom_value_123'},
      );

      expect(result.code, equals(0));
      expect(result.text, contains('CUSTOM_TEST_VAR=custom_value_123'));
    });

    test('returns empty text on timeout', () async {
      final result = await processText([
        'sleep',
        '10',
      ], timeout: const Duration(milliseconds: 50));

      expect(result.code, equals(-1));
      expect(result.text, equals(''));
    });
  });

  group('which edge cases', () {
    test('returns null for empty string command', () async {
      final result = await which('');
      expect(result, isNull);
    });

    test('returns null for command with spaces', () async {
      final result = await which('echo hello');
      expect(result, isNull);
    });

    test('returns null for path-based command that does not exist', () async {
      final result = await which('/nonexistent/binary');
      expect(result, isNull);
    });
  });

  group('findFilesUp edge cases', () {
    test('handles filename with special characters', () async {
      final tmp = Directory('/tmp').createTempSync('fmt_special_');
      final target = File('${tmp.path}/file with spaces.json');
      await target.writeAsString('{}');

      final result = await findFilesUp('file with spaces.json', tmp.path);
      expect(result, contains(target.path));

      tmp.delete(recursive: true);
    });

    test('finds closest file first when multiple exist', () async {
      final root = Directory('/tmp').createTempSync('fmt_multi_');
      final childDirPath = '${root.path}/sub';
      Directory(childDirPath).createSync();

      await File('${root.path}/config.json').writeAsString('{"level": "root"}');
      await File(
        '$childDirPath/config.json',
      ).writeAsString('{"level": "child"}');

      final result = await findFilesUp('config.json', childDirPath);

      // Should find both, with child's version first (closer)
      expect(result.length, greaterThanOrEqualTo(2));
      // The first result should be the child's config (closer to startDir)
      expect(result.first, contains('sub'));
      // The root config should also be found
      final hasRoot = result.any(
        (path) => path.endsWith('config.json') && !path.contains('/sub'),
      );
      expect(hasRoot, isTrue);

      root.delete(recursive: true);
    });

    test('handles startDir that does not exist', () async {
      // findFilesUp uses File().existsSync(), so non-existent dirs are handled
      final result = await findFilesUp('any.json', '/nonexistent/directory');
      expect(result, isEmpty);
    });
  });

  group('runWithTimeout edge cases', () {
    test('returns stdout for successful command', () async {
      final result = await runWithTimeout(['echo', 'hello']);

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString().trim(), equals('hello'));
    });

    test('returns stderr for failing command', () async {
      final result = await runWithTimeout(['ls', '/nonexistent_xyz']);

      expect(result.exitCode, isNot(0));
    });

    test('respects working directory', () async {
      final result = await runWithTimeout(['pwd'], workingDirectory: '/tmp');

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString().trim(), equals('/tmp'));
    });

    test('respects environment variables', () async {
      final result = await runWithTimeout(
        ['env'],
        environment: {'TEST_VAR': 'test_value'},
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('TEST_VAR=test_value'));
    });
  });
}
