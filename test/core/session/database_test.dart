import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';

void main() {
  group('AppDatabase', () {
    test('inMemory() creates a working in-memory database', () async {
      final db = AppDatabase.inMemory();

      // Verify the database is functional by running a simple query
      final result = await db.customSelect('SELECT 1').get();
      expect(result.length, 1);

      await db.close();
    });

    test('file() creates a database at the specified path', () async {
      final testPath = '/tmp/test_chatorai_db.sqlite';
      final db = AppDatabase.file(testPath);

      // Verify the database is functional
      final result = await db.customSelect('SELECT 1').get();
      expect(result.length, 1);

      await db.close();

      // Clean up the test file
      final file = File(testPath);
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('file() creates the SQLite file on disk', () async {
      final testPath = '/tmp/test_chatorai_file_check.sqlite';
      final db = AppDatabase.file(testPath);

      // Force file creation
      await db.customSelect('SELECT 1').get();

      await db.close();

      // Verify the file exists on disk
      final file = File(testPath);
      expect(await file.exists(), isTrue);

      // Clean up
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('file() database has all schema tables', () async {
      final testPath = '/tmp/test_chatorai_schema.sqlite';
      final db = AppDatabase.file(testPath);

      await db.customSelect('SELECT 1').get();

      // Verify schema tables exist
      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      final tableNames = tables.map((r) => r.data['name'] as String).toSet();

      expect(tableNames.contains('sessions'), isTrue);
      expect(tableNames.contains('events'), isTrue);
      expect(tableNames.contains('messages'), isTrue);
      expect(tableNames.contains('tool_results'), isTrue);
      expect(tableNames.contains('context_epochs'), isTrue);

      await db.close();

      // Clean up
      final file = File(testPath);
      if (await file.exists()) {
        await file.delete();
      }
    });
  });
}
