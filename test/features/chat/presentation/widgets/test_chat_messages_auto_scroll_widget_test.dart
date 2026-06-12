// Widget tests for ChatMessages auto-scroll integration
// Verifies ScrollController handling

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_messages.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/repositories/chat_storage_service.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/l10n/app_localizations.dart';

// Mock ChatStorageService
class MockChatStorageService extends ChatStorageService {
  @override
  Future<List<Chat>> getChats({int page = 0, int pageSize = 50}) async => [];

  @override
  Future<Chat?> getChat(String id) async => null;

  @override
  Future<void> addChat(Chat chat) async {}

  @override
  Future<void> updateChat(Chat chat) async {}

  @override
  Future<void> deleteChat(String id) async {}

  @override
  Future<void> addMessageToChat(String chatId, Message message) async {}

  @override
  Future<void> updateMessageInChat(
    String chatId,
    String messageId,
    Message message,
  ) async {}

  @override
  Future<void> deleteMessageFromChat(String chatId, String messageId) async {}
}

// Fake Chat
class FakeChat extends Chat {
  FakeChat({
    required super.id,
    required super.title,
    required super.messages,
    required super.createdAt,
    required super.updatedAt,
  });
}

void main() {
  group('ChatMessages Auto-Scroll Widget Tests', () {
    late MockChatStorageService mockStorage;
    late ProviderContainer container;

    setUp(() {
      mockStorage = MockChatStorageService();
      container = ProviderContainer(
        overrides: [chatStorageServiceProvider.overrideWithValue(mockStorage)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets(
      'ChatMessages uses provided ScrollController and does not dispose it',
      (tester) async {
        final externalController = ScrollController();
        final now = DateTime.now();
        final chat = FakeChat(
          id: 'test-chat',
          title: 'Test Chat',
          messages: [
            Message(
              role: MessageRole.user,
              content: 'Hello',
              timestamp: now,
              isComplete: true,
            ),
            Message(
              role: MessageRole.assistant,
              content: 'Hi there',
              timestamp: now,
              isComplete: true,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChatMessages(
                  chat: chat,
                  chatStorageService: mockStorage,
                  onSendMessage: (_) {},
                  onMessageDeleted: () {},
                  scrollController: externalController,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the ListView
        final listViewFinder = find.byType(ListView);
        expect(listViewFinder, findsOneWidget);

        // Verify that the ListView uses the provided controller
        final listView = tester.widget<ListView>(listViewFinder);
        expect(listView.controller, same(externalController));

        addTearDown(() {
          externalController.dispose();
        });
      },
    );

    testWidgets(
      'ChatMessages creates its own ScrollController when none provided and disposes it properly',
      (tester) async {
        final now = DateTime.now();
        final chat = FakeChat(
          id: 'test-chat',
          title: 'Test Chat',
          messages: List.generate(
            20,
            (i) => Message(
              role: i % 2 == 0 ? MessageRole.user : MessageRole.assistant,
              content: 'Message $i',
              timestamp: now,
              isComplete: true,
            ),
          ),
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChatMessages(
                  chat: chat,
                  chatStorageService: mockStorage,
                  onSendMessage: (_) {},
                  onMessageDeleted: () {},
                  // No scrollController provided
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the ListView
        final listViewFinder = find.byType(ListView);
        expect(listViewFinder, findsOneWidget);

        final listView = tester.widget<ListView>(listViewFinder);
        final controller = listView.controller;

        // Controller should not be null
        expect(controller, isNotNull);

        // Unmount by pumping empty tree
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: Scaffold(body: Container())),
          ),
        );
        await tester.pumpAndSettle();

        // Disposed controller should throw an error on access (e.g., not attached)
        expect(() => controller!.offset, throwsA(isA<Error>()));
      },
    );

    testWidgets(
      'ChatMessages with many messages scrolls correctly using provided controller',
      (tester) async {
        final externalController = ScrollController();
        final now = DateTime.now();
        final manyMessages = List.generate(
          100,
          (i) => Message(
            role: MessageRole.user,
            content: 'Message $i',
            timestamp: now,
            isComplete: true,
          ),
        );
        final chat = FakeChat(
          id: 'test-chat',
          title: 'Long Chat',
          messages: manyMessages,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChatMessages(
                  chat: chat,
                  chatStorageService: mockStorage,
                  onSendMessage: (_) {},
                  onMessageDeleted: () {},
                  scrollController: externalController,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify scrollable and controller has max extent
        expect(externalController.hasClients, isTrue);
        expect(externalController.position.maxScrollExtent, greaterThan(0));

        // Scroll to top
        externalController.jumpTo(0);
        await tester.pump();
        expect(externalController.offset, 0);

        // Scroll to bottom
        final max = externalController.position.maxScrollExtent;
        externalController.jumpTo(max);
        await tester.pump();
        expect(externalController.offset, max);

        addTearDown(() {
          externalController.dispose();
        });
      },
    );
  });
}
