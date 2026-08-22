import 'dart:io';

import 'package:path/path.dart' as p;

/// Cross-process file lock for atomic config writes.
///
/// Uses a sibling `.lock` file with an exclusive `RandomAccessFile` lock so
/// concurrent writers (including other processes) serialize their writes and
/// never clobber each other's temp-file renames. The lock file is cleaned up
/// on release so no `.lock` garbage is left behind.
class FileLockService {
  static Future<T> withLock<T>(String path, Future<T> Function() action) async {
    final lockFile = File('$path.lock');
    final lockDir = Directory(p.dirname(lockFile.path));
    if (!await lockDir.exists()) {
      await lockDir.create(recursive: true);
    }
    RandomAccessFile? raf;
    try {
      await lockFile.create(recursive: true);
      raf = await lockFile.open(mode: FileMode.append);
      await raf.lock(FileLock.exclusive);
      return await action();
    } finally {
      try {
        await raf?.unlock();
      } catch (_) {}
      await raf?.close();
      try {
        await lockFile.delete();
      } catch (_) {}
    }
  }
}
