import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/file_snapshot_service.dart';
import 'package:chatorai/core/tools/filesystem_boundary.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late FileSnapshotService service;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('fsnap_test_');
    db = AppDatabase.inMemory();
    service = FileSnapshotService(
      db,
      boundary: FilesystemBoundary(workspace: tempDir),
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  String p(String name) => '${tempDir.path}/$name';

  group('capture and findById', () {
    test('captures file content and retrieves by id', () async {
      final snapshot = await service.capture(
        sessionId: 'session-1',
        filePath: p('test.dart'),
        content: 'original content',
        stepId: 'step-1',
        toolName: 'edit',
      );

      expect(snapshot.id, isNotEmpty);
      expect(snapshot.sessionId, 'session-1');
      expect(snapshot.filePath, p('test.dart'));
      expect(snapshot.content, 'original content');
      expect(snapshot.stepId, 'step-1');
      expect(snapshot.toolName, 'edit');

      final found = await service.findById(snapshot.id);
      expect(found, isNotNull);
      expect(found!.content, 'original content');
    });

    test('findById returns null for missing snapshot', () async {
      final found = await service.findById('nonexistent');
      expect(found, isNull);
    });

    test('capture rejects external path', () async {
      expect(
        () => service.capture(
          sessionId: 's1',
          filePath: '/etc/passwd',
          content: 'x',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('listBySession', () {
    test('lists all snapshots for a session ordered by creation', () async {
      await service.capture(
        sessionId: 'session-1',
        filePath: p('a.dart'),
        content: 'a',
      );
      await service.capture(
        sessionId: 'session-1',
        filePath: p('b.dart'),
        content: 'b',
      );

      final snapshots = await service.listBySession('session-1');
      expect(snapshots.length, 2);
      expect(snapshots[0].content, 'a');
      expect(snapshots[1].content, 'b');
    });

    test('returns empty list for session with no snapshots', () async {
      final snapshots = await service.listBySession('empty-session');
      expect(snapshots, isEmpty);
    });
  });

  group('listByStep', () {
    test('lists only snapshots for a specific step', () async {
      await service.capture(
        sessionId: 'session-1',
        filePath: p('a.dart'),
        content: 'a',
        stepId: 'step-1',
      );
      await service.capture(
        sessionId: 'session-1',
        filePath: p('b.dart'),
        content: 'b',
        stepId: 'step-2',
      );

      final step1 = await service.listByStep('session-1', 'step-1');
      expect(step1.length, 1);
      expect(step1[0].content, 'a');

      final step2 = await service.listByStep('session-1', 'step-2');
      expect(step2.length, 1);
      expect(step2[0].content, 'b');
    });
  });

  group('restore', () {
    test('restores file content from a snapshot', () async {
      final testFile = File(p('test.dart'));
      await testFile.writeAsString('modified content');

      final snapshot = await service.capture(
        sessionId: 'session-1',
        filePath: p('test.dart'),
        content: 'original content',
      );

      await testFile.writeAsString('modified content');

      await service.restore(snapshot.id);

      expect(await testFile.readAsString(), 'original content');
    });

    test('restore throws on unknown id', () async {
      expect(() => service.restore('nonexistent'), throwsA(isA<StateError>()));
    });
  });

  group('restoreByStep', () {
    test('restores all files for a step', () async {
      final file1 = File(p('a.dart'));
      final file2 = File(p('b.dart'));
      await file1.writeAsString('modified a');
      await file2.writeAsString('modified b');

      await service.capture(
        sessionId: 'session-1',
        filePath: p('a.dart'),
        content: 'original a',
        stepId: 'step-1',
      );
      await service.capture(
        sessionId: 'session-1',
        filePath: p('b.dart'),
        content: 'original b',
        stepId: 'step-1',
      );

      await file1.writeAsString('changed a');
      await file2.writeAsString('changed b');

      await service.restoreByStep('session-1', 'step-1');

      expect(await file1.readAsString(), 'original a');
      expect(await file2.readAsString(), 'original b');
    });
  });

  group('deleteBySession', () {
    test('removes all snapshots for a session', () async {
      await service.capture(
        sessionId: 'session-1',
        filePath: p('a.dart'),
        content: 'a',
      );
      await service.capture(
        sessionId: 'session-1',
        filePath: p('b.dart'),
        content: 'b',
      );

      await service.deleteBySession('session-1');
      expect(await service.listBySession('session-1'), isEmpty);
    });
  });

  group('deleteOlderThan', () {
    test('removes snapshots older than cutoff', () async {
      await service.capture(
        sessionId: 'session-1',
        filePath: p('a.dart'),
        content: 'a',
      );
      final snapshots = await service.listBySession('session-1');
      final olderThan = snapshots[0].createdAt.add(const Duration(seconds: 1));

      await service.deleteOlderThan(DateTime.now().difference(olderThan));
      final remaining = await service.listBySession('session-1');
      expect(remaining, isEmpty);
    });

    test('preserves snapshots newer than cutoff', () async {
      await service.capture(
        sessionId: 'session-1',
        filePath: p('b.dart'),
        content: 'b',
      );

      await service.deleteOlderThan(const Duration(days: 365));

      final remaining = await service.listBySession('session-1');
      expect(remaining.length, 1);
      expect(remaining[0].content, 'b');
    });
  });
}
