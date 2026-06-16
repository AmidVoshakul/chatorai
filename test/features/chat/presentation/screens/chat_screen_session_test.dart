import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/chat/data/providers/session_providers.dart';

/// A test widget that simulates the ChatScreen's session flow.
/// Watches the sessionRepositoryProvider and uses .when() to handle
/// AsyncValue states.
class TestSessionWidget extends ConsumerStatefulWidget {
  const TestSessionWidget({super.key});

  @override
  ConsumerState<TestSessionWidget> createState() => _TestSessionWidgetState();
}

class _TestSessionWidgetState extends ConsumerState<TestSessionWidget> {
  String? _statusMessage;
  String? _errorMessage;

  Future<void> _simulateSendMessage(String text) async {
    try {
      // Use requireValue since we've already confirmed hasValue is true
      final repo = ref.read(sessionRepositoryProvider).requireValue;

      // Create and initialize session (mirrors ChatScreen._handleAddMessagesAndStream)
      final sessionRunner = SessionRunner(repo);
      final runnerSession = sessionRunner.startSession(
        agent: 'general',
        modelRef: 'test-model',
      );
      await runnerSession.initialize();

      // Publish user message
      await runnerSession.publishUserMessage(
        content: text,
        messageId: 'test_msg_1',
      );

      runnerSession.dispose();

      setState(() {
        _statusMessage = 'Message sent';
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error';
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the FutureProvider to trigger rebuilds when it resolves
    final asyncRepo = ref.watch(sessionRepositoryProvider);

    return MaterialApp(
      home: Scaffold(
        body: asyncRepo.when(
          data: (repo) => Column(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _errorMessage!,
                    key: const ValueKey('error_text'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_statusMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _statusMessage!,
                    key: const ValueKey('status_text'),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Ready', key: ValueKey('ready_status')),
              ),
              ElevatedButton(
                key: const ValueKey('send_button'),
                onPressed: () => _simulateSendMessage('Hello from test'),
                child: const Text('Send'),
              ),
            ],
          ),
          loading: () => const Center(
            child: Text('Loading...', key: ValueKey('ready_status')),
          ),
          error: (error, stack) => Center(
            child: Text('Error: $error', key: ValueKey('error_text')),
          ),
        ),
      ),
    );
  }
}

void main() {
  group('ChatScreen → SessionRunner integration', () {
    late AppDatabase testDb;
    late SessionRepository repository;

    setUp(() {
      testDb = AppDatabase.inMemory();
      repository = SessionRepository(testDb);
    });

    tearDown(() async {
      await testDb.close();
    });

    testWidgets(
      'send a user message and verify MessageAdded event in EventStore',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            sessionDatabaseProvider.overrideWith(
              (ref) async => testDb,
            ),
            sessionRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const TestSessionWidget(),
          ),
        );

        // Wait for FutureProvider to resolve
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify the widget shows "Ready"
        expect(find.text('Ready'), findsOneWidget);

        // Tap the send button to simulate sending a message
        await tester.tap(find.byKey(const ValueKey('send_button')));
        await tester.pumpAndSettle();

        // Verify status message
        expect(find.text('Message sent'), findsOneWidget);

        // Verify events in the EventStore
        final allSessionIds = await repository.listSessions();
        expect(allSessionIds.length, 1);

        final events = await repository.eventStore.getEvents(
          allSessionIds.first,
        );

        // Should have: SessionCreated + MessageAdded
        expect(events.length, 2);
        expect(events[0], isA<SessionCreated>());
        expect(events[1], isA<MessageAdded>());

        final msgEvent = events[1] as MessageAdded;
        expect(msgEvent.content, 'Hello from test');
        expect(msgEvent.role, 'user');
        expect(msgEvent.messageId, 'test_msg_1');
      },
    );

    testWidgets(
      'SessionState.messages includes the user message after replay',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            sessionDatabaseProvider.overrideWith(
              (ref) async => testDb,
            ),
            sessionRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const TestSessionWidget(),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Ready'), findsOneWidget);

        // Send message
        await tester.tap(find.byKey(const ValueKey('send_button')));
        await tester.pumpAndSettle();

        // Load session and verify state
        final allSessionIds = await repository.listSessions();
        expect(allSessionIds.length, 1);

        final state = await repository.loadSession(allSessionIds.first);

        expect(state, isNotNull);
        expect(state!.messages.length, 1);
        expect(state.messages.first.content, 'Hello from test');
        expect(state.messages.first.role, const UserRole());
      },
    );

    testWidgets(
      'assistant placeholder creates TextStarted event via onChunk',
      (tester) async {
        // Create a session runner directly to simulate assistant streaming
        final sessionRunner = SessionRunner(repository);
        final runnerSession = sessionRunner.startSession(agent: 'general');
        await runnerSession.initialize();

        // Verify initial events: just SessionCreated
        var events = await repository.eventStore.getEvents(
          runnerSession.sessionId,
        );
        expect(events.length, 1);
        expect(events[0], isA<SessionCreated>());

        // Simulate assistant text streaming (triggers TextStarted)
        runnerSession.onChunk('Hello!');

        // Wait for async operations to complete
        await tester.pump(const Duration(milliseconds: 200));

        events = await repository.eventStore.getEvents(
          runnerSession.sessionId,
        );

        // SessionCreated + TextStarted (from onChunk)
        expect(events.length, greaterThanOrEqualTo(2));
        expect(events.any((e) => e is TextStarted), isTrue);

        runnerSession.dispose();
      },
    );
  });
}
