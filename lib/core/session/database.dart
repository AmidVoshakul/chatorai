import 'dart:io';

import 'package:chatorai/shared/utils/logger.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'schema.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Events,
    Sessions,
    Messages,
    ToolResults,
    ContextEpochs,
    SessionSnapshots,
    FileSnapshots,
    ChatSnapshots,
  ],
)
class AppDatabase extends _$AppDatabase {
  static bool _multipleDatabaseWarningSuppressed = false;

  AppDatabase(super.e);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (mgr) async {
        await mgr.createAll();
      },
      beforeOpen: (details) async {
        if (!details.wasCreated && (details.versionBefore ?? 0) < 3) {
          await customStatement(
            "DELETE FROM tool_results WHERE tool_name = '' OR tool_name IS NULL",
          );
        }
      },
      onUpgrade: (mgr, from, to) async {
        if (from < 2) {
          await mgr.addColumn(sessions, sessions.tokensCacheRead as dynamic);
          await mgr.addColumn(sessions, sessions.tokensCacheWrite as dynamic);
        }
        if (from < 4) {
          await mgr.createTable(sessionSnapshots);
        }
        if (from < 5) {
          // Secondary indexes added in v5 to avoid full scans on the
          // per-session queries (event load/stream, message load, etc.).
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_events_session_seq '
            'ON events(session_id, sequence)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_messages_session_seq '
            'ON messages(session_id, seq)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_tool_results_session '
            'ON tool_results(session_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_context_epochs_session '
            'ON context_epochs(session_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_session_snapshots_session '
            'ON session_snapshots(session_id)',
          );
        }
        if (from < 6) {
          await mgr.createTable(fileSnapshots);
        }
        if (from < 7) {
          await mgr.createTable(chatSnapshots);
        }
        if (from < 8) {
          await mgr.addColumn(messages, messages.tokensInput as dynamic);
          await mgr.addColumn(messages, messages.tokensOutput as dynamic);
          await mgr.addColumn(messages, messages.tokensReasoning as dynamic);
        }
        if (from < 9) {
          await mgr.addColumn(
            chatSnapshots,
            chatSnapshots.schemaVersion as dynamic,
          );
        }
      },
    );
  }

  /// Creates an in-memory database for testing.
  factory AppDatabase.inMemory() {
    if (!_multipleDatabaseWarningSuppressed) {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      _multipleDatabaseWarningSuppressed = true;
    }
    return AppDatabase(NativeDatabase.memory());
  }

  /// Creates a file-based persistent database at [path].
  factory AppDatabase.file(String path) {
    if (!_multipleDatabaseWarningSuppressed) {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      _multipleDatabaseWarningSuppressed = true;
    }
    return AppDatabase(NativeDatabase(File(path)));
  }
}

/// Top-level helper: creates a file-based [AppDatabase] at
/// `{dataDir}/chatorai_sessions.sqlite`.
Future<AppDatabase> createFileDatabase({required String dataDir}) async {
  LogTags.session.logInfo('createFileDatabase: start dataDir=$dataDir');
  final dir = Directory(dataDir);
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  LogTags.session.logInfo('createFileDatabase: dir ensured');
  final dbPath = p.join(dataDir, 'chatorai_sessions.sqlite');
  LogTags.session.logInfo('createFileDatabase: opening dbPath=$dbPath');
  final db = AppDatabase(NativeDatabase.createInBackground(File(dbPath)));
  LogTags.session.logInfo('createFileDatabase: done');
  return db;
}
