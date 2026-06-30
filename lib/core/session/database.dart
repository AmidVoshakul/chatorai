import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'schema.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Events, Sessions, Messages, ToolResults, ContextEpochs])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

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
      },
    );
  }

  static Future<AppDatabase> create() async => createFileDatabase();

  /// Creates an in-memory database for testing.
  factory AppDatabase.inMemory() {
    return AppDatabase(NativeDatabase.memory());
  }

  /// Creates a file-based persistent database in the app data directory.
  factory AppDatabase.file(String path) {
    return AppDatabase(NativeDatabase(File(path)));
  }
}

/// Top-level helper: creates a file-based [AppDatabase] at
/// `<xdg-data>/chatorai_sessions.sqlite`.
Future<AppDatabase> createFileDatabase() async {
  final dataDir = await XdgPaths.dataHomeAsync;
  await XdgPaths.ensureDir(dataDir);
  final dbPath = '$dataDir/chatorai_sessions.sqlite';
  return AppDatabase.file(dbPath);
}
