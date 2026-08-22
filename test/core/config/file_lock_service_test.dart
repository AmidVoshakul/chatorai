import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:chatorai/core/config/file_lock_service.dart';

void main() {
  group('FileLockService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'file_lock_service_test_',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('withLock removes .lock file after completion', () async {
      final path = p.join(tempDir.path, 'cleanup.txt');
      final lockPath = '$path.lock';

      await FileLockService.withLock<void>(path, () async {
        // While the lock is held, the .lock file must exist.
        expect(File(lockPath).existsSync(), isTrue);
      });

      // After withLock returns, the .lock file must be gone.
      expect(File(lockPath).existsSync(), isFalse);
    });

    test('withLock removes .lock file even when action throws', () async {
      final path = p.join(tempDir.path, 'error.txt');
      final lockPath = '$path.lock';

      try {
        await FileLockService.withLock<void>(path, () async {
          throw StateError('boom');
        });
      } on StateError {
        // expected
      }

      expect(File(lockPath).existsSync(), isFalse);
    });

    test('withLock serializes cross-process calls on the same path', () async {
      // On Linux, flock(2) is per-process and does not block same-process
      // reentrant acquisitions. FileLockService is documented as a
      // cross-process lock, so we verify exclusivity by spawning a child
      // process that tries to acquire the same lock while the parent holds it.
      final path = p.join(tempDir.path, 'target.txt');
      final lockPath = '$path.lock';

      // Create a child Dart script that uses the same locking mechanism.
      final childScriptPath = p.join(tempDir.path, 'child_lock_test.dart');
      final childScript = '''
import 'dart:io';

void main(List<String> args) async {
  final lockPath = args[0];
  final lockFile = File(lockPath);
  await lockFile.create(recursive: true);
  final raf = await lockFile.open(mode: FileMode.append);
  await raf.lock(FileLock.exclusive);
  final acquired = DateTime.now();
  stderr.write('acquired:\${acquired.millisecondsSinceEpoch}\\n');
  await Future<void>.delayed(Duration(milliseconds: 100));
  await raf.unlock();
  await raf.close();
  try { await lockFile.delete(); } catch (_) {}
  stderr.write('done\\n');
}
''';
      await File(childScriptPath).writeAsString(childScript);

      // Start parent lock holder.
      final parentStart = DateTime.now();
      final parent = FileLockService.withLock<void>(path, () async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });

      // Give parent a head start to acquire the lock.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Run child process.
      final result = await Process.run('dart', [
        childScriptPath,
        lockPath,
      ], stderrEncoding: utf8);

      await parent;

      if (result.exitCode != 0) {
        fail('Child process failed: ${result.stderr}');
      }

      // Parse child stderr output.
      final output = result.stderr as String;
      final acquiredMatch = RegExp(r'acquired:(\d+)').firstMatch(output);
      expect(
        acquiredMatch,
        isNotNull,
        reason: 'Child should have acquired the lock',
      );

      final acquiredTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(acquiredMatch!.group(1)!),
      );
      final delta = acquiredTime.difference(parentStart).inMilliseconds;
      // The child must have waited for the parent to release the lock.
      expect(
        delta,
        greaterThanOrEqualTo(150),
        reason: 'Child should have waited for parent to release lock',
      );
    });
  });
}
