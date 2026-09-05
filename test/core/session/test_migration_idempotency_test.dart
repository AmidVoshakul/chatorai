import 'package:chatorai/core/session/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// Reproduces the interrupted-migration crash loop: the production database
// was stuck at user_version=5 while the v6-v10 objects were already applied
// (previous run died before the version was written). Reopening must not
// throw `duplicate column` and must land on version 10.
void main() {
  test(
    'interrupted migration from v5 with v8 columns applied opens at v10',
    () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      // Seed the old schema via the executor setup callback, which runs on
      // the raw sqlite3 database before drift reads user_version and runs
      // onUpgrade. This keeps a single shared in-memory database.
      final executor = NativeDatabase.memory(
        setup: (raw) {
          // Manual v5 baseline: core tables only, without v6-v10 objects
          // (no snapshot tables, no messages.tokens_*,
          // no sessions.directory).
          raw.execute('''
CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_data TEXT NOT NULL,
  sequence INTEGER NOT NULL,
  created_at INTEGER NOT NULL
)''');
          raw.execute('''
CREATE TABLE sessions (
  id TEXT NOT NULL PRIMARY KEY,
  parent_id TEXT,
  title TEXT NOT NULL DEFAULT '',
  agent TEXT NOT NULL DEFAULT 'general',
  model_ref TEXT,
  cost REAL NOT NULL DEFAULT 0.0,
  tokens_input INTEGER NOT NULL DEFAULT 0,
  tokens_output INTEGER NOT NULL DEFAULT 0,
  tokens_reasoning INTEGER NOT NULL DEFAULT 0,
  permission_rules TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  archived_at INTEGER
)''');
          raw.execute('''
CREATE TABLE messages (
  id TEXT NOT NULL PRIMARY KEY,
  session_id TEXT NOT NULL,
  seq INTEGER NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  model TEXT,
  reasoning TEXT,
  error TEXT,
  created_at INTEGER NOT NULL
)''');
          raw.execute('''
CREATE TABLE tool_results (
  id TEXT NOT NULL PRIMARY KEY,
  session_id TEXT NOT NULL,
  message_id TEXT NOT NULL,
  tool_name TEXT NOT NULL,
  input_json TEXT NOT NULL DEFAULT '{}',
  output_text TEXT NOT NULL DEFAULT '',
  duration_ms INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'success',
  created_at INTEGER NOT NULL
)''');
          raw.execute('''
CREATE TABLE context_epochs (
  id TEXT NOT NULL PRIMARY KEY,
  session_id TEXT NOT NULL,
  revision INTEGER NOT NULL,
  prompt_text TEXT NOT NULL DEFAULT '',
  agent TEXT NOT NULL DEFAULT 'general',
  model_ref TEXT,
  created_at INTEGER NOT NULL
)''');

          // Simulate the partially executed migration: v8 columns are
          // already present on disk, but the version was never bumped
          // past 5.
          raw.execute(
            'ALTER TABLE messages '
            'ADD COLUMN tokens_input INTEGER NOT NULL DEFAULT 0',
          );
          raw.execute(
            'ALTER TABLE messages '
            'ADD COLUMN tokens_output INTEGER NOT NULL DEFAULT 0',
          );
          raw.execute(
            'ALTER TABLE messages '
            'ADD COLUMN tokens_reasoning INTEGER NOT NULL DEFAULT 0',
          );
          raw.execute('PRAGMA user_version = 5');
        },
      );

      final db = AppDatabase(executor);
      addTearDown(db.close);

      // Must not throw `duplicate column`.
      await db.customSelect('SELECT 1').get();

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data['user_version'], 10);
    },
  );
}
