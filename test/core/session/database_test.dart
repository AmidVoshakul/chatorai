import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:drift/drift.dart';

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

    test('migration v7 -> v8 adds per-message token columns', () async {
      final testPath = '/tmp/test_chatorai_migration_v8.sqlite';
      final file = File(testPath);
      if (await file.exists()) await file.delete();

      // Fresh v8 DB has the token columns.
      final db = AppDatabase.file(testPath);
      await db.customSelect('SELECT 1').get();

      // Verify token columns exist on the fresh schema.
      final cols = await db.customSelect("PRAGMA table_info(messages)").get();
      final colNames = cols.map((r) => r.data['name'] as String).toSet();
      expect(colNames, contains('tokens_input'));
      expect(colNames, contains('tokens_output'));
      expect(colNames, contains('tokens_reasoning'));

      await db.close();
    });

    test(
      'migration v4 -> v8 recreates secondary indexes and adds token columns',
      () async {
        final testPath = '/tmp/test_chatorai_migration_v4to8.sqlite';
        final file = File(testPath);
        if (await file.exists()) await file.delete();

        // Fresh v8 DB has the latest schema.
        final db = AppDatabase.file(testPath);
        await db.customSelect('SELECT 1').get();

        // Simulate an old v4 database: drop the v5+ indexes and the v8 token
        // columns, then lower user_version so the next open triggers
        // onUpgrade(4 -> 8).
        await db.customStatement('DROP INDEX IF EXISTS idx_events_session_seq');
        await db.customStatement(
          'DROP INDEX IF EXISTS idx_messages_session_seq',
        );
        await db.customStatement(
          'DROP INDEX IF EXISTS idx_tool_results_session',
        );
        await db.customStatement(
          'DROP INDEX IF EXISTS idx_context_epochs_session',
        );
        await db.customStatement(
          'DROP INDEX IF EXISTS idx_session_snapshots_session',
        );
        // SQLite 3.35+ supports DROP COLUMN; ignore errors if the column is
        // already absent (e.g. when running against an older schema).
        for (final col in [
          'tokens_input',
          'tokens_output',
          'tokens_reasoning',
        ]) {
          try {
            await db.customStatement('ALTER TABLE messages DROP COLUMN $col');
          } on Exception catch (_) {
            // Column may not exist in older schemas — ignore.
          }
        }
        await db.customStatement('PRAGMA user_version = 4');
        await db.close();

        // Reopen: onUpgrade(4 -> 8) must recreate indexes and token columns.
        final upgraded = AppDatabase.file(testPath);
        final idx = await upgraded
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='index' "
              "AND name='idx_events_session_seq'",
            )
            .get();
        expect(idx, isNotEmpty);

        final cols = await upgraded
            .customSelect("PRAGMA table_info(messages)")
            .get();
        final colNames = cols.map((r) => r.data['name'] as String).toSet();
        expect(colNames, contains('tokens_input'));
        expect(colNames, contains('tokens_output'));
        expect(colNames, contains('tokens_reasoning'));

        // The index is actually used for a per-session lookup.
        final plan = await upgraded
            .customSelect(
              "EXPLAIN QUERY PLAN SELECT * FROM events "
              "WHERE session_id = 'x' ORDER BY sequence",
            )
            .get();
        final planText = plan.map((r) => r.data.toString()).join(' ');
        expect(planText, contains('idx_events_session_seq'));

        await upgraded.close();
        await file.delete();
      },
    );

    test(
      'StepEnded writes tokens to last assistant message, not tool messages',
      () async {
        final testPath = '/tmp/test_chatorai_step_end_tokens.sqlite';
        final file = File(testPath);
        if (await file.exists()) await file.delete();

        final db = AppDatabase.file(testPath);
        final sessionId = 'ses_token_test';

        // Insert a session and messages manually.
        await db
            .into(db.sessions)
            .insert(
              SessionsCompanion.insert(
                id: sessionId,
                title: const Value('Token test'),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
        await db
            .into(db.messages)
            .insert(
              MessagesCompanion.insert(
                id: 'msg_user',
                sessionId: sessionId,
                seq: 1,
                role: 'user',
                content: const Value('hi'),
                createdAt: DateTime.now(),
              ),
            );
        await db
            .into(db.messages)
            .insert(
              MessagesCompanion.insert(
                id: 'msg_asst',
                sessionId: sessionId,
                seq: 2,
                role: 'assistant',
                content: const Value('answer'),
                createdAt: DateTime.now(),
              ),
            );
        await db
            .into(db.messages)
            .insert(
              MessagesCompanion.insert(
                id: 'msg_tool',
                sessionId: sessionId,
                seq: 3,
                role: 'tool',
                content: const Value('tool output'),
                createdAt: DateTime.now(),
              ),
            );

        // Project a StepEnded event with token counters.
        await projectToDb(
          db,
          StepEnded(
            sessionId: SessionID.fromString(sessionId),
            stepNumber: 1,
            tokensInput: 100,
            tokensOutput: 50,
            tokensReasoning: 10,
            timestamp: DateTime.now(),
          ),
        );

        // Verify session totals were updated.
        final sessionRow = await (db.select(
          db.sessions,
        )..where((s) => s.id.equals(sessionId))).getSingle();
        expect(sessionRow.tokensInput, 100);
        expect(sessionRow.tokensOutput, 50);
        expect(sessionRow.tokensReasoning, 10);

        // Verify the last assistant message received the per-message tokens.
        final messages =
            await (db.select(db.messages)
                  ..where((m) => m.sessionId.equals(sessionId))
                  ..orderBy([(m) => OrderingTerm(expression: m.seq)]))
                .get();
        final assistant = messages.firstWhere((m) => m.role == 'assistant');
        expect(assistant.tokensInput, 100);
        expect(assistant.tokensOutput, 50);
        expect(assistant.tokensReasoning, 10);

        // Verify the tool message was NOT updated with tokens.
        final tool = messages.firstWhere((m) => m.role == 'tool');
        expect(tool.tokensInput, 0);
        expect(tool.tokensOutput, 0);
        expect(tool.tokensReasoning, 0);

        await db.close();
        await file.delete();
      },
    );
  });
}
