import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/event_bus.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_db_provider.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/chat/chat/chat_message.dart';
import 'package:chatorai/core/chat/chat/message_converter.dart';
import 'package:chatorai/gui/features/sessions/providers/session_parts_provider.dart';
import 'package:chatorai/core/chat/chat/assistant_content.dart'
    show AssistantText;

void main() {
  group('SessionPartsProvider (StreamNotifier)', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionEventBus eventBus;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      eventBus = SessionEventBus();
    });

    tearDown(() async {
      await db.close();
    });

    /// Helper to create a [ProviderContainer] with test overrides.
    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(
            AsyncValue<SessionRepository>.data(repository),
          ),
          sessionEventBusProvider.overrideWithValue(eventBus),
        ],
      );
    }

    group('initial load from SQLite', () {
      test('empty store yields empty SessionState with matching id', () async {
        final sid = SessionID.create();
        final container = makeContainer();
        addTearDown(container.dispose);

        // Resolve the FutureProvider before creating the StreamNotifier,
        // so its build() does not suspend on ref.read(…future).
        await container.read(sessionRepositoryProvider.future);

        // Listen keeps the provider alive across async gaps.
        final values = <AsyncValue<SessionState>>[];
        container.listen(
          sessionPartsProvider(sid.value),
          (prev, next) => values.add(next),
          fireImmediately: true,
        );

        // Small delay for the initial state to propagate.
        await Future.delayed(const Duration(milliseconds: 100));

        expect(values.length, greaterThan(0));
        final last = values.last;
        expect(last.hasValue, isTrue);
        expect(last.requireValue.id, sid);
        expect(last.requireValue.parts, isEmpty);
      });

      test('loads and projects existing events', () async {
        final sid = SessionID.create();
        final now = DateTime.now();

        // Write a SessionCreated + TextStarted + TextDelta to the event store.
        await repository.appendEvent(
          SessionCreated(sessionId: sid, agent: 'general', timestamp: now),
        );
        await repository.appendEvent(
          TextStarted(
            sessionId: sid,
            messageId: 'msg_1',
            partId: 'part_text',
            timestamp: now,
          ),
        );
        await repository.appendEvent(
          TextDelta(
            sessionId: sid,
            messageId: 'msg_1',
            partId: 'part_text',
            delta: 'Hello ',
            timestamp: now,
          ),
        );
        await repository.appendEvent(
          TextDelta(
            sessionId: sid,
            messageId: 'msg_1',
            partId: 'part_text',
            delta: 'World!',
            timestamp: now,
          ),
        );

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(sessionRepositoryProvider.future);

        final values = <AsyncValue<SessionState>>[];
        container.listen(
          sessionPartsProvider(sid.value),
          (prev, next) => values.add(next),
          fireImmediately: true,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(values.length, greaterThan(0));
        final last = values.last;
        expect(last.hasValue, isTrue);
        expect(last.requireValue.parts, isNotEmpty);

        // TextDelta events should produce an AssistantText part.
        final textParts = last.requireValue.parts.whereType<AssistantText>();
        expect(textParts.length, 1);
        expect(textParts.first.text, 'Hello World!');
      });
    });

    group('EventBus live updates', () {
      test('emits updated state when EventBus delivers an event', () async {
        final sid = SessionID.create();
        final now = DateTime.now();

        // Pre-populate one event.
        await repository.appendEvent(
          SessionCreated(sessionId: sid, agent: 'general', timestamp: now),
        );

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(sessionRepositoryProvider.future);

        final values = <AsyncValue<SessionState>>[];
        container.listen(
          sessionPartsProvider(sid.value),
          (prev, next) => values.add(next),
          fireImmediately: true,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Sanity check: values collected.
        expect(values.length, greaterThan(0));

        // Emit streaming events via EventBus (simulating SessionRunnerSession).
        eventBus.emit(
          TextStarted(
            sessionId: sid,
            messageId: 'msg_1',
            partId: 'part_text',
            timestamp: now,
          ),
        );
        eventBus.emit(
          TextDelta(
            sessionId: sid,
            messageId: 'msg_1',
            partId: 'part_text',
            delta: 'Live update!',
            timestamp: now,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Should have at least one more value after the EventBus event.
        expect(values.length, greaterThanOrEqualTo(2));
        final last = values.last;
        expect(last.hasValue, isTrue);
        expect(last.requireValue.parts, isNotEmpty);

        final textParts = last.requireValue.parts.whereType<AssistantText>();
        expect(textParts.length, 1);
        expect(textParts.first.text, 'Live update!');
      });

      test('only receives events for its own session', () async {
        final sidA = SessionID.create();
        final sidB = SessionID.create();
        final now = DateTime.now();

        await repository.appendEvent(
          SessionCreated(sessionId: sidA, agent: 'general', timestamp: now),
        );
        await repository.appendEvent(
          SessionCreated(sessionId: sidB, agent: 'general', timestamp: now),
        );

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(sessionRepositoryProvider.future);

        final valuesA = <AsyncValue<SessionState>>[];
        final valuesB = <AsyncValue<SessionState>>[];
        container.listen(
          sessionPartsProvider(sidA.value),
          (prev, next) => valuesA.add(next),
          fireImmediately: true,
        );
        container.listen(
          sessionPartsProvider(sidB.value),
          (prev, next) => valuesB.add(next),
          fireImmediately: true,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Emit an event for sidA only.
        eventBus.emit(
          TextStarted(
            sessionId: sidA,
            messageId: 'msg_1',
            partId: 'part_text',
            timestamp: now,
          ),
        );
        eventBus.emit(
          TextDelta(
            sessionId: sidA,
            messageId: 'msg_1',
            partId: 'part_text',
            delta: 'Only A',
            timestamp: now,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Provider for sidA should have the delta.
        final lastA = valuesA.last;
        expect(lastA.requireValue.parts.whereType<AssistantText>().length, 1);

        // Provider for sidB should still be empty (only SessionCreated).
        final lastB = valuesB.last;
        expect(lastB.requireValue.parts.whereType<AssistantText>(), isEmpty);
      });
    });

    group('chat snapshot cache (repository)', () {
      test('write then read returns messages when counts match', () async {
        final sid = SessionID.create();
        final now = DateTime.now();

        await repository.appendEvent(
          SessionCreated(sessionId: sid, agent: 'general', timestamp: now),
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: sid,
            messageId: 'm1',
            role: 'user',
            content: 'snapshot test',
            timestamp: now,
          ),
        );

        // Build messages via repository state.
        final state = await repository.loadSessionState(sid);
        final chat = sessionStateToChat(state);
        final chatMessages = chat.messages
            .map((m) => messageToChatMessage(m))
            .toList();
        await repository.writeChatSnapshot(sid, chatMessages);

        final readBack = await repository.readChatSnapshot(sid);
        expect(readBack, isNotNull);
        expect(readBack!.length, 1);
        expect(readBack.single is UserMessage, isTrue);
        expect((readBack.single as UserMessage).content, 'snapshot test');

        // Verify the snapshot carries the current schema version.
        final row = await (db.select(
          db.chatSnapshots,
        )..where((s) => s.sessionId.equals(sid.value))).getSingle();
        expect(row.schemaVersion, 1);
      });

      test(
        'readChatSnapshot returns null when events_count mismatches',
        () async {
          final sid = SessionID.create();
          final now = DateTime.now();

          await repository.appendEvent(
            SessionCreated(sessionId: sid, agent: 'general', timestamp: now),
          );
          await repository.appendEvent(
            MessageAdded(
              sessionId: sid,
              messageId: 'm1',
              role: 'user',
              content: 'v1',
              timestamp: now,
            ),
          );

          final state = await repository.loadSessionState(sid);
          final chat = sessionStateToChat(state);
          await repository.writeChatSnapshot(
            sid,
            chat.messages.map((m) => messageToChatMessage(m)).toList(),
          );

          // Add another event after snapshot.
          await repository.appendEvent(
            MessageAdded(
              sessionId: sid,
              messageId: 'm2',
              role: 'user',
              content: 'v2',
              timestamp: now,
            ),
          );

          final readBack = await repository.readChatSnapshot(sid);
          expect(readBack, isNull);
        },
      );

      test(
        'readChatSnapshot returns null when snapshot schema version is stale',
        () async {
          final sid = SessionID.create();
          final now = DateTime.now();

          await repository.appendEvent(
            SessionCreated(sessionId: sid, agent: 'general', timestamp: now),
          );
          await repository.appendEvent(
            MessageAdded(
              sessionId: sid,
              messageId: 'm1',
              role: 'user',
              content: 'v1',
              timestamp: now,
            ),
          );

          final state = await repository.loadSessionState(sid);
          final chat = sessionStateToChat(state);
          await repository.writeChatSnapshot(
            sid,
            chat.messages.map((m) => messageToChatMessage(m)).toList(),
          );

          // Manually downgrade schema version to simulate stale snapshot.
          await db.customStatement(
            "UPDATE chat_snapshots SET schema_version = 0 WHERE session_id = '${sid.value}'",
          );

          final readBack = await repository.readChatSnapshot(sid);
          expect(readBack, isNull);
        },
      );

      test('deleteSession removes snapshot', () async {
        final sid = SessionID.create();
        final now = DateTime.now();

        await repository.appendEvent(
          SessionCreated(sessionId: sid, agent: 'general', timestamp: now),
        );
        await repository.appendEvent(
          MessageAdded(
            sessionId: sid,
            messageId: 'm1',
            role: 'user',
            content: 'delete me',
            timestamp: now,
          ),
        );

        final state = await repository.loadSessionState(sid);
        final chat = sessionStateToChat(state);
        await repository.writeChatSnapshot(
          sid,
          chat.messages.map((m) => messageToChatMessage(m)).toList(),
        );

        expect(await repository.readChatSnapshot(sid), isNotNull);

        await repository.deleteSession(sid);

        expect(await repository.readChatSnapshot(sid), isNull);
      });
    });
  });
}
