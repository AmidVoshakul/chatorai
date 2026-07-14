import 'package:chatorai/core/session/database.dart';

class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._();
  factory DatabaseManager() => _instance;
  DatabaseManager._();

  AppDatabase? _db;

  Future<AppDatabase> getInstance(String dataDir) async {
    _db ??= await createFileDatabase(dataDir: dataDir);
    return _db!;
  }

  void reset() {
    _db?.close();
    _db = null;
  }
}
