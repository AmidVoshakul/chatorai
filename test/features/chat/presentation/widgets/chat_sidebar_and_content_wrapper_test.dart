import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_content_wrapper.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_sidebar_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The drawer caches its rendered widget and keys the cache on a hash of the
// chat list. The hash must include the title, otherwise renaming a chat leaves
// a stale Drawer on screen.
Chat _chat(String id, String title) => Chat(
  id: id,
  title: title,
  messages: const [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  group('ChatSidebarDrawer.chatListHash', () {
    test('includes the title so a rename changes the hash', () {
      final withAlpha = [_chat('c1', 'Alpha')];
      final withBeta = [_chat('c1', 'Beta')];

      expect(
        ChatSidebarDrawer.chatListHash(withAlpha),
        isNot(ChatSidebarDrawer.chatListHash(withBeta)),
        reason: 'title must participate in the cache key',
      );
    });

    test('stable for the same chats', () {
      final a = [_chat('c1', 'Alpha'), _chat('c2', 'Beta')];
      final b = [_chat('c1', 'Alpha'), _chat('c2', 'Beta')];

      expect(
        ChatSidebarDrawer.chatListHash(a),
        ChatSidebarDrawer.chatListHash(b),
      );
    });
  });

  group('ChatContentWrapper navigator gesture', () {
    testWidgets('onHorizontalDragUpdate handles null primaryDelta', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatContentWrapper(
            child: const SizedBox(),
            screenWidth: 400,
            isNavigatorVisible: false,
            wideScreenMode: false,
            hasHeadings: () => true,
            toggleNavigator: () {},
          ),
        ),
      );

      final detector = tester.firstWidget<GestureDetector>(
        find.byType(GestureDetector),
      );

      // A drag update with a null primaryDelta must not throw (was `!`).
      expect(
        () => detector.onHorizontalDragUpdate!(
          DragUpdateDetails(primaryDelta: null, globalPosition: Offset.zero),
        ),
        returnsNormally,
      );
    });
  });
}
