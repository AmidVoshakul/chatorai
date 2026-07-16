import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/event_store.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';

void main() {
  late AppDatabase db;
  late EventStore store;
  late SessionID sid;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = EventStore(db);
    sid = SessionID.create();
  });

  tearDown(() async {
    await db.close();
  });

  group('EventStore', () {
    test('append and getEvents roundtrip', () async {
      await store.append(
        SessionCreated(sessionId: sid, timestamp: DateTime.now()),
      );

      final events = await store.getEvents(sid);
      expect(events.length, 1);
      expect(events.first, isA<SessionCreated>());
    });

    test('appendAll inserts multiple events atomically', () async {
      await store.appendAll([
        SessionCreated(sessionId: sid, timestamp: DateTime.now()),
        MessageAdded(
          sessionId: sid,
          messageId: 'm1',
          role: 'user',
          content: 'Hi',
          timestamp: DateTime.now(),
        ),
      ]);

      final events = await store.getEvents(sid);
      expect(events.length, 2);
    });

    test('sequence numbers increment per session', () async {
      final seq1 = await store.append(
        SessionCreated(sessionId: sid, timestamp: DateTime.now()),
      );
      final seq2 = await store.append(
        MessageAdded(
          sessionId: sid,
          messageId: 'm1',
          role: 'user',
          content: 'Hi',
          timestamp: DateTime.now(),
        ),
      );

      expect(seq2, seq1 + 1);
    });

    test('getLatestSequence returns 0 for empty session', () async {
      final seq = await store.getLatestSequence(sid);
      expect(seq, 0);
    });

    test('getLatestSequence returns highest value', () async {
      await store.append(
        SessionCreated(sessionId: sid, timestamp: DateTime.now()),
      );
      await store.append(
        MessageAdded(
          sessionId: sid,
          messageId: 'm1',
          role: 'user',
          content: 'Hi',
          timestamp: DateTime.now(),
        ),
      );

      final seq = await store.getLatestSequence(sid);
      expect(seq, 2);
    });

    test('deleteSessionEvents removes all events', () async {
      await store.append(
        SessionCreated(sessionId: sid, timestamp: DateTime.now()),
      );
      await store.deleteSessionEvents(sid);

      final events = await store.getEvents(sid);
      expect(events, isEmpty);
    });

    test('different sessions have independent sequences', () async {
      final sid2 = SessionID.create();

      await store.append(
        SessionCreated(sessionId: sid, timestamp: DateTime.now()),
      );
      await store.append(
        SessionCreated(sessionId: sid2, timestamp: DateTime.now()),
      );

      final seq1 = await store.getLatestSequence(sid);
      final seq2 = await store.getLatestSequence(sid2);

      expect(seq1, 1);
      expect(seq2, 1);
    });

    test('streamEvents emits after append', () async {
      // Drift's watch() emits the current (empty) snapshot immediately on
      // subscription, so wait for the first non-empty emission — the one
      // produced by the append below.
      final futureEvents = store
          .streamEvents(sid)
          .firstWhere((e) => e.isNotEmpty);
      await store.append(
        SessionCreated(sessionId: sid, timestamp: DateTime.now()),
      );

      final events = await futureEvents;
      expect(events.length, 1);
      expect(events.first, isA<SessionCreated>());
    });

    test('event ordering is preserved by sequence', () async {
      await store.appendAll([
        SessionCreated(sessionId: sid, timestamp: DateTime.now()),
        MessageAdded(
          sessionId: sid,
          messageId: 'm1',
          role: 'user',
          content: 'First',
          timestamp: DateTime.now(),
        ),
        MessageAdded(
          sessionId: sid,
          messageId: 'm2',
          role: 'user',
          content: 'Second',
          timestamp: DateTime.now(),
        ),
      ]);

      final events = await store.getEvents(sid);
      expect(events.length, 3);
      expect(events[0], isA<SessionCreated>());
      expect((events[1] as MessageAdded).content, 'First');
      expect((events[2] as MessageAdded).content, 'Second');
    });
  });
}
