import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:chatorai/shared/utils/logger.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

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
      },
    );
  }

  /// Creates an in-memory database for testing.
  factory AppDatabase.inMemory() {
    return AppDatabase(NativeDatabase.memory());
  }

  /// Creates a file-based persistent database at [path].
  factory AppDatabase.file(String path) {
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
  final db = AppDatabase.file(dbPath);
  LogTags.session.logInfo('createFileDatabase: done');
  return db;
}
