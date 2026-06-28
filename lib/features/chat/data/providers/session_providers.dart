import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a file-based persistent [AppDatabase] instance for session event sourcing.
///
/// Uses SQLite in the app documents directory (`chatorai_sessions.sqlite`).
/// The database is created lazily on first access.
final sessionDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  return createFileDatabase();
});

/// Provides the [SessionRepository] backed by the file-based database.
///
/// This is a [FutureProvider] because the underlying database initialization
/// is asynchronous (file I/O on first access).
final sessionRepositoryProvider = FutureProvider<SessionRepository>((
  ref,
) async {
  final db = await ref.watch(sessionDatabaseProvider.future);
  return SessionRepository(db);
});

/// Provides all active (non-archived) sessions sorted by [SessionState.updatedAt]
/// descending.
///
/// Used by the sidebar to display the session list.
final sessionListProvider = FutureProvider<List<SessionState>>((ref) async {
  final repo = await ref.watch(sessionRepositoryProvider.future);
  return repo.findAll();
});

/// Holds the currently active [SessionRunner] during streaming.
///
/// The chat screen binds the active runner before streaming starts
/// and clears it when streaming ends. This allows tools like `task`
/// to access the current session for delegation.
class _CurrentRunnerNotifier extends Notifier<SessionRunner?> {
  @override
  SessionRunner? build() => null;

  void set(SessionRunner? runner) => state = runner;
  void clear() => state = null;
}

final currentSessionRunnerProvider =
    NotifierProvider<_CurrentRunnerNotifier, SessionRunner?>(
      _CurrentRunnerNotifier.new,
    );
