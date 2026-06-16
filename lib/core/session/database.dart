import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'schema.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Events, Sessions, Messages, ToolResults, ContextEpochs])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  static Future<AppDatabase> create() async => createFileDatabase();

  /// Creates an in-memory database for testing.
  factory AppDatabase.inMemory() {
    return AppDatabase(NativeDatabase.memory());
  }

  /// Creates a file-based persistent database in the app documents directory.
  factory AppDatabase.file(String path) {
    return AppDatabase(NativeDatabase(File(path)));
  }
}

/// Top-level helper: creates a file-based [AppDatabase] at
/// `<documents>/chatorai_sessions.sqlite`.
Future<AppDatabase> createFileDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = '${dir.path}/chatorai_sessions.sqlite';
  return AppDatabase.file(dbPath);
}
