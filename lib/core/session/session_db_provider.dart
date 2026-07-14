import 'package:chatorai/core/session/database.dart' hide ToolResult;
import 'package:chatorai/core/session/database_manager.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a file-based persistent [AppDatabase] instance for session event sourcing.
final sessionDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final dataDir = await XdgPaths.dataHomeAsync;
  return DatabaseManager().getInstance(dataDir);
});

/// Provides the [SessionRepository] backed by the file-based database.
final sessionRepositoryProvider = FutureProvider<SessionRepository>((
  ref,
) async {
  final db = await ref.watch(sessionDatabaseProvider.future);
  return SessionRepository(db);
});
