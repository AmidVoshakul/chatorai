import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/tools/filesystem_boundary.dart';

class FileSnapshotService {
  final AppDatabase _db;
  final FilesystemBoundary? _boundaryOverride;

  FileSnapshotService(this._db, {FilesystemBoundary? boundary})
    : _boundaryOverride = boundary;

  FilesystemBoundary get _boundary =>
      _boundaryOverride ?? FilesystemBoundary(workspace: Directory.current);

  Future<FileSnapshot> capture({
    required String sessionId,
    required String filePath,
    required String content,
    String? stepId,
    String? toolName,
  }) async {
    final resolution = _boundary.resolve(filePath);
    if (resolution.isExternal) {
      throw ArgumentError('Cannot snapshot external path: $filePath');
    }
    final id = const Uuid().v4();
    final now = DateTime.now();
    final row = FileSnapshotsCompanion.insert(
      id: id,
      sessionId: sessionId,
      filePath: resolution.path,
      content: content,
      stepId: stepId == null ? const Value.absent() : Value(stepId),
      toolName: toolName == null ? const Value.absent() : Value(toolName),
      createdAt: now,
    );
    await _db.into(_db.fileSnapshots).insert(row);
    return FileSnapshot(
      id: id,
      sessionId: sessionId,
      filePath: resolution.path,
      content: content,
      stepId: stepId,
      toolName: toolName,
      createdAt: now,
    );
  }

  Future<FileSnapshot?> findById(String id) async {
    final row = await (_db.select(
      _db.fileSnapshots,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row;
  }

  Future<List<FileSnapshot>> listBySession(String sessionId) async {
    final rows =
        await (_db.select(_db.fileSnapshots)
              ..where((t) => t.sessionId.equals(sessionId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows;
  }

  Future<List<FileSnapshot>> listByStep(String sessionId, String stepId) async {
    final rows =
        await (_db.select(_db.fileSnapshots)
              ..where(
                (t) => t.sessionId.equals(sessionId) & t.stepId.equals(stepId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows;
  }

  Future<void> restore(String id) async {
    final snapshot = await findById(id);
    if (snapshot == null) {
      throw StateError('Snapshot not found: $id');
    }
    final resolution = _boundary.resolve(snapshot.filePath);
    if (resolution.isExternal) {
      throw StateError(
        'Cannot restore snapshot outside workspace: ${snapshot.filePath}',
      );
    }
    final file = File(resolution.path);
    await file.parent.create(recursive: true);
    await file.writeAsString(snapshot.content, encoding: utf8);
  }

  Future<void> restoreByStep(String sessionId, String stepId) async {
    final snapshots = await listByStep(sessionId, stepId);
    final dirs = <String>{};
    for (final s in snapshots) {
      final resolution = _boundary.resolve(s.filePath);
      if (!resolution.isExternal) {
        dirs.add(File(resolution.path).parent.path);
      }
    }
    for (final dir in dirs) {
      await Directory(dir).create(recursive: true);
    }
    final errors = <String, Exception>{};
    for (final s in snapshots) {
      try {
        await restore(s.id);
      } on Exception catch (e) {
        errors[s.filePath] = e;
      }
    }
    if (errors.isNotEmpty) {
      throw StateError('Failed to restore ${errors.length} file(s): $errors');
    }
  }

  Future<void> deleteBySession(String sessionId) async {
    await (_db.delete(
      _db.fileSnapshots,
    )..where((t) => t.sessionId.equals(sessionId))).go();
  }

  Future<void> deleteOlderThan(Duration age) async {
    final cutoff = DateTime.now().subtract(age);
    await (_db.delete(
      _db.fileSnapshots,
    )..where((t) => t.createdAt.isSmallerThanValue(cutoff))).go();
  }
}
