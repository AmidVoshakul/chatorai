import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'events.dart';
import 'session_id.dart';

/// In-memory broadcast bus for session events.
///
/// `SessionRunnerSession` emits events after persisting them to the SQLite
/// event store. UI providers (`SessionPartsNotifier`, `ChatScreenNotifier`)
/// subscribe via [events()] or [forSession()] to receive live streaming
/// updates without polling the database.
///
/// This is the single source of live data — there is no separate path for
/// parent vs. child sessions.
class SessionEventBus {
  final StreamController<SessionEvent> _controller;

  /// Whether [dispose] has been called.
  bool _disposed = false;

  /// Creates a broadcast event bus.
  ///
  /// The [sync] parameter controls whether events are delivered synchronously
  /// within the [emit] call. Defaults to `false` (microtask delivery) to avoid
  /// re-entrant provider rebuilds inside the session runner's lock.
  SessionEventBus({bool sync = false})
    : _controller = StreamController<SessionEvent>.broadcast(sync: sync);

  /// Whether this bus has been disposed.
  bool get isDisposed => _disposed;

  /// Emits an event to all subscribers.
  void emit(SessionEvent event) {
    if (_disposed) return;
    _controller.add(event);
  }

  /// Returns a stream of ALL session events (no filtering).
  Stream<SessionEvent> events() {
    if (_disposed) return const Stream.empty();
    return _controller.stream;
  }

  /// Returns a stream filtered to events for the given [sessionId].
  ///
  /// This is a filtered view of the broadcast stream — only events whose
  /// `sessionId` matches are delivered to the returned stream.
  Stream<SessionEvent> forSession(SessionID sessionId) {
    if (_disposed) return const Stream.empty();
    return _controller.stream.where((event) => event.sessionId == sessionId);
  }

  /// Closes the bus. No further events will be delivered.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _controller.close();
  }
}

/// Singleton Riverpod provider for the global [SessionEventBus].
final sessionEventBusProvider = Provider<SessionEventBus>((ref) {
  final bus = SessionEventBus();
  ref.onDispose(() => bus.dispose());
  return bus;
});
