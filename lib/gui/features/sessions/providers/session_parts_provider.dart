import 'dart:async';

import 'package:chatorai/core/session/event_bus.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart' show projectEvent;
import 'package:chatorai/core/session/session_db_provider.dart'
    show sessionRepositoryProvider;
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = LogTags.session;

/// Notifier that provides reactive [SessionState] for a session.
///
/// Loads initial state from the SQLite event store, then subscribes to the
/// in-memory [SessionEventBus] for live streaming updates.  This gives UI
/// widgets real-time access to streaming parts without polling the database.
///
/// Use via:
/// ```dart
/// final asyncState = ref.watch(sessionPartsProvider(sessionId));
/// final state = asyncState.value; // SessionState
/// final parts = state.parts;      // List<AssistantContent>
/// ```
class SessionPartsNotifier extends StreamNotifier<SessionState> {
  /// The raw session id string (e.g. `"ses_abc123"`).
  final String sessionId;

  /// Creates a notifier for the given [sessionId].
  SessionPartsNotifier(this.sessionId);

  @override
  Stream<SessionState> build() async* {
    // 1. Subscribe to EventBus BEFORE any await to avoid losing events
    //    emitted during the async initialization below. A single-subscription
    //    StreamController buffers events internally even without a listener,
    //    so reasoning/text deltas emitted during DB loading are preserved.
    final eventBus = ref.read(sessionEventBusProvider);
    final sid = SessionID.fromString(sessionId);

    final eventController = StreamController<SessionEvent>();
    final busSub = eventBus.forSession(sid).listen(eventController.add);

    try {
      // 2. Now it's safe to do async initialization — any events emitted
      //    during these awaits are buffered in eventController.
      final repo = await ref.read(sessionRepositoryProvider.future);

      var state = SessionState(
        id: sid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final readStopwatch = Stopwatch()..start();
      final allEvents = await repo.eventStore.getEvents(sid);
      readStopwatch.stop();
      final replayStopwatch = Stopwatch()..start();
      for (final event in allEvents) {
        state = projectEvent(state, event);
      }
      replayStopwatch.stop();
      _logger.logDebug(
        '[SessionParts] session=$sessionId events=${allEvents.length} read=${readStopwatch.elapsedMilliseconds}ms replay=${replayStopwatch.elapsedMilliseconds}ms',
      );

      // 3. Yield the initial state (reconstructed from the event store).
      yield state;

      // 4. Process live events — drains any events that were buffered
      //    during step 2, then handles all subsequent events in real time.
      await for (final event in eventController.stream) {
        state = projectEvent(state, event);
        yield state;
      }
    } finally {
      busSub.cancel();
      await eventController.close();
    }
  }
}

/// Unified streaming provider for both parent and child sessions.
///
/// Yields [AsyncValue<SessionState>] — watch via:
/// ```dart
/// ref.watch(sessionPartsProvider(sessionId))
/// ```
///
/// For synchronous access to the current notifier (and its internal state):
/// ```dart
/// ref.read(sessionPartsProvider(sessionId).notifier)
/// ```
final sessionPartsProvider =
    StreamNotifierProvider.family<SessionPartsNotifier, SessionState, String>(
      (sessionId) => SessionPartsNotifier(sessionId),
    );
