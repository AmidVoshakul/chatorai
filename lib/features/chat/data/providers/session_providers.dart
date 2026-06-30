import 'package:chatorai/core/session/database.dart' hide ToolResult;
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/session/projector.dart' show projectEvent;
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

/// Holds the currently active [SessionRunner] and session ID during streaming.
///
/// The chat screen binds the active runner before streaming starts
/// and clears it when streaming ends. This allows tools like `task`
/// to access the current session for delegation.
class _CurrentRunnerNotifier
    extends Notifier<({SessionRunner runner, String sessionId})?> {
  SessionRunnerHolder? _holder;

  @override
  ({SessionRunner runner, String sessionId})? build() => null;

  void set(SessionRunner runner, String sessionId) {
    state = (runner: runner, sessionId: sessionId);
    _holder?.runner = runner;
    _holder?.parentSessionId = sessionId;
  }

  void bindHolder(SessionRunnerHolder holder) {
    _holder = holder;
    if (state != null) {
      holder.runner = state!.runner;
      holder.parentSessionId = state!.sessionId;
    }
  }

  /// Real child session ID for the currently running task.
  /// Set by task tool when child session is created, cleared on task end.
  String? get activeChildSessionId => _holder?.activeChildSessionId;
  set activeChildSessionId(String? value) {
    _holder?.activeChildSessionId = value;
  }

  /// Set child tool event callback on the holder.
  // ignore: avoid_setters_without_getters
  set onChildToolEvent(void Function(String, String?)? callback) {
    _holder?.onChildToolEvent = callback;
  }

  void clear() {
    state = null;
    _holder?.runner = null;
    _holder?.parentSessionId = null;
  }
}

final currentSessionRunnerProvider =
    NotifierProvider<
      _CurrentRunnerNotifier,
      ({SessionRunner runner, String sessionId})?
    >(_CurrentRunnerNotifier.new);

/// Reactive stream of tool results for a session, keyed by session ID.
final childSessionToolResultsProvider =
    StreamProvider.family<List<ToolResult>, String>((ref, sessionIdRaw) async* {
  final repo = await ref.read(sessionRepositoryProvider.future);
  final sid = SessionID.fromString(sessionIdRaw);
  yield await repo.getSessionToolResults(sid);
  await for (final toolResults in repo.watchSessionToolResults(sid)) {
    yield toolResults;
  }
});

/// Reactive stream of session state (including messages) for a session,
/// keyed by session ID. Uses event stream + replay for true reactive streaming.
final childSessionStateProvider =
    StreamProvider.family<SessionState, String>((ref, sessionIdRaw) async* {
  final repo = await ref.read(sessionRepositoryProvider.future);
  final sid = SessionID.fromString(sessionIdRaw);

  // Emit initial empty state immediately to avoid isLoading deadlock
  var state = SessionState(
    id: sid,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  yield state;

  // Then stream and accumulate new events
  await for (final events in repo.eventStore.streamEvents(sid)) {
    for (final event in events) {
      state = projectEvent(state, event);
    }
    yield state;
  }
});
