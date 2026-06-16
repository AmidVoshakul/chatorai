import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/session/session_state.dart';

void main() {
  group('SessionRunner.publishUserMessage', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'publishUserMessage after initialize() appends MessageAdded event',
      () async {
        final session = runner.startSession(agent: 'general');
        await session.initialize();

        // Publish a user message
        await session.publishUserMessage(content: 'Hello, world!');

        // Verify events: SessionCreated + MessageAdded
        final events = await repository.eventStore.getEvents(session.sessionId);
        expect(events.length, 2);
        expect(events[0], isA<SessionCreated>());
        expect(events[1], isA<MessageAdded>());

        final msgEvent = events[1] as MessageAdded;
        expect(msgEvent.content, 'Hello, world!');
        expect(msgEvent.role, 'user');
      },
    );

    test(
      'publishUserMessage before initialize() does nothing (guard)',
      () async {
        final session = runner.startSession(agent: 'general');

        // Do NOT call initialize() — publishUserMessage should be a no-op
        await session.publishUserMessage(content: 'Should not appear');

        // No events should be stored (session was never created)
        final events = await repository.eventStore.getEvents(session.sessionId);
        expect(events, isEmpty);
      },
    );

    test(
      'full flow: startSession → initialize → publishUserMessage → '
      'replayEvents produces SessionState with one user message',
      () async {
        final session = runner.startSession(agent: 'general');
        await session.initialize();

        const userContent = 'What is Dart?';
        await session.publishUserMessage(content: userContent);

        // Replay all events to get the final state
        final events = await repository.eventStore.getEvents(session.sessionId);
        final state = replayEvents(events);

        // SessionCreated + MessageAdded → state should have 1 message
        expect(state.messages.length, 1);
        expect(state.messages.first.content, userContent);
        expect(state.messages.first.role, const UserRole());
        expect(state.messages.first.seq, 1);
      },
    );

    test(
      'publishUserMessage generates unique messageId if not provided',
      () async {
        final session = runner.startSession(agent: 'general');
        await session.initialize();

        // Publish without explicit messageId
        await session.publishUserMessage(content: 'First message');
        // Small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 5));
        await session.publishUserMessage(content: 'Second message');

        final events = await repository.eventStore.getEvents(session.sessionId);
        // SessionCreated + 2 MessageAdded
        expect(events.length, 3);

        final msg1 = events[1] as MessageAdded;
        final msg2 = events[2] as MessageAdded;

        // Both should have auto-generated IDs
        expect(msg1.messageId, isNotEmpty);
        expect(msg2.messageId, isNotEmpty);
        // IDs must be unique
        expect(msg1.messageId, isNot(equals(msg2.messageId)));
      },
    );

    test(
      'multiple publishUserMessage calls correctly append events in order',
      () async {
        final session = runner.startSession(agent: 'general');
        await session.initialize();

        final messages = [
          'First user message',
          'Second user message',
          'Third user message',
        ];

        for (final content in messages) {
          await session.publishUserMessage(content: content);
        }

        final events = await repository.eventStore.getEvents(session.sessionId);
        // SessionCreated + 3 MessageAdded
        expect(events.length, 4);
        expect(events[0], isA<SessionCreated>());

        // Verify order and content of MessageAdded events
        for (int i = 0; i < messages.length; i++) {
          final msgEvent = events[i + 1] as MessageAdded;
          expect(msgEvent.content, messages[i]);
          expect(msgEvent.role, 'user');
        }

        // Verify via replay
        final state = replayEvents(events);
        expect(state.messages.length, 3);
        for (int i = 0; i < messages.length; i++) {
          expect(state.messages[i].content, messages[i]);
          expect(state.messages[i].seq, i + 1);
        }
      },
    );
  });
}
