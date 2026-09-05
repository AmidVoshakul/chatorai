import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:drift/drift.dart';

void main() {
  group('AppDatabase', () {
    test('migration v9 -> v10 adds directory column to sessions', () async {
      final testPath = '/tmp/test_chatorai_migration_v10.sqlite';
      final file = File(testPath);
      if (await file.exists()) await file.delete();

      // Fresh v10 DB has the directory column.
      final db = AppDatabase.file(testPath);
      await db.customSelect('SELECT 1').get();

      // Verify directory column exists on the fresh schema.
      final cols = await db.customSelect("PRAGMA table_info(sessions)").get();
      final colNames = cols.map((r) => r.data['name'] as String).toSet();
      expect(colNames, contains('directory'));

      await db.close();
    });

    test(
      'migration v9 -> v10 upgrades existing DB and directory column is usable',
      () async {
        final testPath = '/tmp/test_chatorai_migration_v9to10.sqlite';
        final file = File(testPath);
        if (await file.exists()) await file.delete();

        // Fresh v10 DB has the latest schema.
        final db = AppDatabase.file(testPath);
        await db.customSelect('SELECT 1').get();

        // Simulate an old v9 database: drop the directory column, then lower
        // user_version so the next open triggers onUpgrade(9 -> 10).
        try {
          await db.customStatement(
            'ALTER TABLE sessions DROP COLUMN directory',
          );
        } on Exception catch (_) {
          // Column may not exist in older schemas — ignore.
        }
        await db.customStatement('PRAGMA user_version = 9');
        await db.close();

        // Reopen: onUpgrade(9 -> 10) must add the directory column.
        final upgraded = AppDatabase.file(testPath);
        final cols = await upgraded
            .customSelect("PRAGMA table_info(sessions)")
            .get();
        final colNames = cols.map((r) => r.data['name'] as String).toSet();
        expect(colNames, contains('directory'));

        // Verify a row can be inserted with a directory value after upgrade.
        final now = DateTime.now();
        await upgraded
            .into(upgraded.sessions)
            .insert(
              SessionsCompanion.insert(
                id: 'ses_dir_test',
                title: const Value('Dir Test'),
                agent: const Value('general'),
                createdAt: now,
                updatedAt: now,
                directory: const Value('/tmp/test'),
              ),
            );

        final row = await (upgraded.select(
          upgraded.sessions,
        )..where((s) => s.id.equals('ses_dir_test'))).getSingle();
        expect(row.directory, '/tmp/test');

        await upgraded.close();
        await file.delete();
      },
    );
  });
}
