import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/format/format_utils.dart';

void main() {
  group('which', () {
    test('returns not null when cmd exists on PATH', () async {
      final result = await which('echo');
      expect(result, isNotNull);
      expect(result, equals('echo'));
    });

    test('returns null when cmd is unknown', () async {
      final result = await which('_notarealcmd_xyz');
      expect(result, isNull);
    });
  });

  group('findFilesUp', () {
    test('finds file in current directory', () async {
      final tmp = Directory('/tmp').createTempSync('fmt_');
      final target = File('${tmp.path}/cfg.json');
      await target.writeAsString('{}');

      final result = await findFilesUp('cfg.json', tmp.path);
      expect(result, contains(target.path));

      tmp.delete(recursive: true);
    });

    test('finds file in parent directory', () async {
      final root = Directory('/tmp').createTempSync('fmt_');
      final childDirPath = '${root.path}/sub';
      Directory(childDirPath).createSync();
      final target = File('${root.path}/cfg.json');
      await target.writeAsString('{}');

      final result = await findFilesUp('cfg.json', childDirPath);
      expect(result, contains(target.path));

      root.delete(recursive: true);
    });

    test('returns empty list when not found', () async {
      final tmp = Directory('/tmp').createTempSync('fmt_');
      final result = await findFilesUp('cfg_nope.json', tmp.path);
      expect(result, isEmpty);

      tmp.delete(recursive: true);
    });
  });

  group('readText', () {
    test('returns content of existing file', () async {
      final f = File('/tmp/rt_${DateTime.now().millisecondsSinceEpoch}.txt');
      await f.writeAsString('hello');
      final text = await readText(f.path);
      expect(text, equals('hello'));
      f.delete();
    });

    test('throws on missing file', () {
      expect(() => readText('/tmp/_missing_read_text_.txt'), throwsA(anything));
    });
  });

  group('processText', () {
    test('returns stdout for simple command', () async {
      final result = await processText(['echo', 'hello']);
      expect(result.code, 0);
      expect(result.text.trim(), equals('hello'));
    });

    test('returns negative code on failure', () async {
      final result = await processText(['false']);
      expect(result.code, isNot(0));
    });
  });

  group('runWithTimeout', () {
    test('runs simple command', () async {
      final result = await runWithTimeout(['echo', 'ok']);
      expect(result.exitCode, 0);
    });

    test('throws on timeout', () async {
      expect(
        runWithTimeout([
          'sleep',
          '1',
        ], timeout: const Duration(milliseconds: 50)),
        throwsA(isA<Exception>()),
      );
    });
  });
}
