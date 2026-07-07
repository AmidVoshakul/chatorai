import 'package:chatorai/core/session/projector.dart' show projectEvent;
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/session/session_db_provider.dart'
    show sessionRepositoryProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

/// Reactive stream of session parts (live streaming) for a session.
///
/// This is the unified provider for both parent and child sessions.
/// It watches the event store and projects events into SessionState,
/// giving live streaming updates to all UI subscribers.
final sessionPartsProvider = StreamProvider.family<SessionState, String>((
  ref,
  sessionIdRaw,
) async* {
  final repo = await ref.read(sessionRepositoryProvider.future);
  final sid = SessionID.fromString(sessionIdRaw);

  var state = SessionState(
    id: sid,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  var lastSeq = 0;

  final allEvents = await repo.eventStore.getEvents(sid);
  for (final event in allEvents) {
    state = projectEvent(state, event);
    lastSeq = max(lastSeq, event.sequence);
  }
  yield state;

  await for (final batch in repo.eventStore.streamEvents(sid)) {
    final newEvents = batch.where((e) => e.sequence > lastSeq).toList();
    if (newEvents.isEmpty) continue;

    for (final event in newEvents) {
      state = projectEvent(state, event);
      lastSeq = max(lastSeq, event.sequence);
    }
    yield state;
  }
});
