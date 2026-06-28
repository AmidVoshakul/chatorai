import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/tools/file_edit_guard.dart';

void main() {
  setUp(() {
    // Reset the static cached prefs BEFORE setting mock values
    FileEditGuard.resetForTest();
    SharedPreferences.setMockInitialValues({});
  });

  group('FileEditGuard.recordRead', () {
    test('records mtime for an existing file', () async {
      final dir = await Directory.systemTemp.createTemp('feg_test_');
      final file = File('${dir.path}/sample.txt');
      await file.writeAsString('hello');

      await FileEditGuard.recordRead(file.path);

      final stored = await FileEditGuard.getLastReadMtime(file.path);
      expect(stored, isNotNull);
      expect(
        stored,
        await file.stat().then((s) => s.modified.millisecondsSinceEpoch),
      );

      await dir.delete(recursive: true);
    });

    test('recordRead on file that throws does not crash', () async {
      // Use a path that cannot be stated (component too long for most filesystems).
      final invalidPath = '/tmp/${"x" * 1000}/impossible.txt';
      // Should not throw — the catch block in recordRead handles it gracefully.
      // We can't verify the key wasn't written (depends on filesystem behavior),
      // but we can verify no exception propagates.
      await FileEditGuard.recordRead(invalidPath);
      // No assertion on stored value — just verifying no crash.
    });

    test('overwrites previous mtime on second read', () async {
      final dir = await Directory.systemTemp.createTemp('feg_test_');
      final file = File('${dir.path}/sample.txt');
      await file.writeAsString('v1');

      await FileEditGuard.recordRead(file.path);
      final first = await FileEditGuard.getLastReadMtime(file.path);

      // Modify the file (new mtime)
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      await file.writeAsString('v2');

      await FileEditGuard.recordRead(file.path);
      final second = await FileEditGuard.getLastReadMtime(file.path);

      expect(second, isNotNull);
      expect(second, greaterThan(first!));

      await dir.delete(recursive: true);
    });
  });

  group('FileEditGuard.getLastReadMtime', () {
    test('returns null for path never recorded', () async {
      final result = await FileEditGuard.getLastReadMtime(
        '/tmp/never_recorded.txt',
      );
      expect(result, isNull);
    });
  });

  group('FileEditGuard.checkStale', () {
    test('returns null when no prior read was recorded', () async {
      final result = await FileEditGuard.checkStale('/tmp/unknown.txt');
      expect(result, isNull);
    });

    test('returns null when file unchanged since recordRead', () async {
      final dir = await Directory.systemTemp.createTemp('feg_test_');
      final file = File('${dir.path}/stable.txt');
      await file.writeAsString('content');

      await FileEditGuard.recordRead(file.path);
      final stale = await FileEditGuard.checkStale(file.path);
      expect(stale, isNull);

      await dir.delete(recursive: true);
    });

    test(
      'returns current mtime when file was modified after recordRead',
      () async {
        final dir = await Directory.systemTemp.createTemp('feg_test_');
        final file = File('${dir.path}/changing.txt');
        await file.writeAsString('v1');

        await FileEditGuard.recordRead(file.path);

        // Ensure mtime difference (filesystem resolution can be coarse)
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        await file.writeAsString('v2');

        final stale = await FileEditGuard.checkStale(file.path);
        expect(stale, isNotNull);
        expect(
          stale,
          await file.stat().then((s) => s.modified.millisecondsSinceEpoch),
        );

        await dir.delete(recursive: true);
      },
    );

    test('checkStale returns null when no prior read was recorded', () async {
      // A path that was never recorded should return null (not stale by definition)
      final uniquePath =
          '${Directory.systemTemp.path}/never_recorded_${DateTime.now().microsecondsSinceEpoch}.txt';
      final stale = await FileEditGuard.checkStale(uniquePath);
      expect(stale, isNull);
    });
  });

  group('FileEditGuard.clearAll', () {
    test('removes all recorded mtimes', () async {
      final dir = await Directory.systemTemp.createTemp('feg_test_');
      final f1 = File('${dir.path}/a.txt');
      final f2 = File('${dir.path}/b.txt');
      await f1.writeAsString('a');
      await f2.writeAsString('b');

      await FileEditGuard.recordRead(f1.path);
      await FileEditGuard.recordRead(f2.path);

      expect(await FileEditGuard.getLastReadMtime(f1.path), isNotNull);
      expect(await FileEditGuard.getLastReadMtime(f2.path), isNotNull);

      await FileEditGuard.clearAll();

      expect(await FileEditGuard.getLastReadMtime(f1.path), isNull);
      expect(await FileEditGuard.getLastReadMtime(f2.path), isNull);

      await dir.delete(recursive: true);
    });

    test('clearAll on empty store is a no-op', () async {
      await FileEditGuard.clearAll();
      // No throw
    });
  });
}
