// Integration test for chat auto-scroll
// Tests the interaction between ChatScreen state, ScrollController, and user actions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/presentation/screens/chat_screen.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/repositories/chat_storage_service.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/l10n/app_localizations.dart';

// Mock ScrollController
class MockScrollController extends ScrollController {
  bool animateToCalled = false;
  bool jumpToCalled = false;
  double? animateToTarget;
  double? jumpToTarget;
  Duration? animateToDuration;
  Curve? animateToCurve;

  @override
  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) async {
    animateToCalled = true;
    animateToTarget = offset;
    animateToDuration = duration;
    animateToCurve = curve;
    if (hasClients) {
      position.jumpTo(offset);
    }
  }

  @override
  void jumpTo(double value) {
    jumpToCalled = true;
    jumpToTarget = value;
    if (hasClients) {
      position.jumpTo(value);
    }
  }

  void reset() {
    animateToCalled = false;
    jumpToCalled = false;
    animateToTarget = null;
    jumpToTarget = null;
    animateToDuration = null;
    animateToCurve = null;
  }
}

// Mock ScrollPosition
class MockScrollPosition extends ScrollPositionWithSingleContext {
  MockScrollPosition({
    required double initialScrollOffset,
    required double viewportDimension,
    required double maxScrollExtent,
  }) : super(
         initialScrollOffset: initialScrollOffset,
         viewportDimension: viewportDimension,
         maxScrollExtent: maxScrollExtent,
         keepScrollOffset: false,
       );

  void goTo(double offset) {
    goToDouble(offset);
  }
}

// Minimal ChatStorageService mock
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
  group('Chat Auto-Scroll Integration', () {
    late MockScrollController mockController;
    late ProviderContainer container;
    late MockChatStorageService mockStorage;

    setUp(() {
      mockController = MockScrollController();
      mockStorage = MockChatStorageService();

      container = ProviderContainer(
        overrides: [
          chatStorageServiceProvider.overrideWithValue(mockStorage),
          // Override only what's needed; rely on defaults for others
          currentChatIdProvider.overrideWith((ref) => null),
          currentChatProvider.overrideWith((ref) => null),
          chatScreenProvider.overrideWith(
            (ref) => Provider<ChatScreenState>(
              (ref) => const ChatScreenState(
                isStreaming: false,
                navigatorHeadings: [],
                activeHeadingIndex: -1,
                isNavigatorVisible: false,
                welcomeSuggestions: [],
              ),
            ),
          ),
          streamingMessageProvider.overrideWith(
            (ref) => Provider<StreamingMessageState>(
              (ref) => const StreamingMessageState(),
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets(
      'Auto-scroll behavior: force=true animates, force=false jumps',
      (tester) async {
        final now = DateTime.now();
        final chat = FakeChat(
          id: 'test-chat',
          title: 'Test',
          messages: List.generate(
            20,
            (i) => Message(
              role: MessageRole.user,
              content: 'Msg $i',
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
                body: ChatScreen(
                  key: GlobalKey(),
                  testScrollController: mockController,
                ),
              ),
            ),
          ),
        );
        container.read(currentChatIdProvider.notifier).state = chat.id;
        container.read(currentChatProvider.notifier).state = chat;
        await tester.pumpAndSettle();

        final state =
            tester.state<ChatScreenState>(find.byType(ChatScreen)) as dynamic;

        // Attach mock position
        final position = MockScrollPosition(
          initialScrollOffset: 0,
          viewportDimension: 800,
          maxScrollExtent: 2000,
        );
        mockController.attach(position);

        // Test force=true
        position.goTo(0);
        mockController.reset();
        state._scrollToBottom(force: true);
        expect(mockController.animateToCalled, isTrue);
        expect(mockController.animateToTarget, 2000);
        expect(
          mockController.animateToDuration,
          const Duration(milliseconds: 300),
        );
        expect(mockController.animateToCurve, Curves.easeOut);

        // Test force=false
        position.goTo(0);
        mockController.reset();
        state._scrollToBottom(force: false);
        expect(mockController.jumpToCalled, isTrue);
        expect(mockController.jumpToTarget, 2000);

        // Test skip when near bottom
        position.goTo(1998);
        mockController.reset();
        state._scrollToBottom(force: false);
        expect(mockController.jumpToCalled, isFalse);
        expect(mockController.animateToCalled, isFalse);
      },
    );

    testWidgets('User scroll changes autoScrollEnabled state', (tester) async {
      final now = DateTime.now();
      final chat = FakeChat(
        id: 'test-chat',
        title: 'Test',
        messages: List.generate(
          20,
          (i) => Message(
            role: MessageRole.user,
            content: 'Msg $i',
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
              body: ChatScreen(
                key: GlobalKey(),
                testScrollController: mockController,
              ),
            ),
          ),
        ),
      );
      container.read(currentChatIdProvider.notifier).state = chat.id;
      container.read(currentChatProvider.notifier).state = chat;
      await tester.pumpAndSettle();

      final state =
          tester.state<ChatScreenState>(find.byType(ChatScreen)) as dynamic;
      final position = MockScrollPosition(
        initialScrollOffset: 0,
        viewportDimension: 800,
        maxScrollExtent: 2000,
      );
      mockController.attach(position);

      // At top -> autoScroll false
      position.goTo(0);
      state._handleScroll();
      expect(state.autoScrollEnabledForTest, isFalse);

      // Near bottom -> autoScroll true
      position.goTo(1900);
      state._handleScroll();
      expect(state.autoScrollEnabledForTest, isTrue);

      // At bottom -> autoScroll true
      position.goTo(2000);
      state._handleScroll();
      expect(state.autoScrollEnabledForTest, isTrue);
    });
  });
}
