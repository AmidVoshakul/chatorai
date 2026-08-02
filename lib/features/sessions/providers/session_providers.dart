import 'package:chatorai/core/session/session_db_provider.dart'
    show sessionRepositoryProvider;
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/session/session_stack.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:chatorai/core/session/session_db_provider.dart'
    show sessionDatabaseProvider, sessionRepositoryProvider;

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

  /// Maps a child session ID to its parent task part ID (concurrent routing).
  Map<String, String> get childToTaskPart =>
      _holder?.childToTaskPart ?? const {};

  /// Maps a parent task part ID to its child session ID.
  Map<String, String> get taskPartToChild =>
      _holder?.taskPartToChild ?? const {};

  /// Set child session resolved callback on the holder.
  void Function(String)? get onChildSessionResolved =>
      _holder?.onChildSessionResolved;
  set onChildSessionResolved(void Function(String)? callback) {
    _holder?.onChildSessionResolved = callback;
  }

  /// Set task-start callback on the holder.
  void Function(String, String, String)? get onTaskStart =>
      _holder?.onTaskStart;
  set onTaskStart(void Function(String, String, String)? callback) {
    _holder?.onTaskStart = callback;
  }

  /// Set task-end callback on the holder.
  void Function(String)? get onTaskEnd => _holder?.onTaskEnd;
  set onTaskEnd(void Function(String)? callback) {
    _holder?.onTaskEnd = callback;
  }

  /// Set child tool event callback on the holder.
  void Function(String, String, String?)? get onChildToolEvent =>
      _holder?.onChildToolEvent;
  set onChildToolEvent(void Function(String, String, String?)? callback) {
    _holder?.onChildToolEvent = callback;
  }

  void clear() {
    state = null;
    _holder?.runner = null;
    _holder?.parentSessionId = null;
  }

  void cancelAllChildren() {
    _holder?.cancelAllChildren();
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

/// Manages the navigation stack of sessions (parent → child → child).
/// The top of the stack is the currently viewed session.
///
/// Used for session hierarchy navigation: push child, pop to parent,
/// navigate between siblings.
final sessionStackProvider =
    NotifierProvider<SessionStackNotifier, SessionStackState>(
      SessionStackNotifier.new,
    );
