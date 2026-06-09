part of 'chat_screen.dart';

extension _ChatScreenNavigatorExt on _ChatScreenState {
  void _onHeadingsUpdated(List<MarkdownHeadingInfoWithKey> headings) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatScreenProvider.notifier).setNavigatorHeadings(headings);
      }
    });
  }

  void _toggleNavigator() {
    ref.read(chatScreenProvider.notifier).toggleNavigator();
  }

  void _onHeadingTap(String headingText, String messageId, int level) {
    final uiState = ref.watch(chatScreenProvider);
    final normalizedTapText = stripMarkdownFormatting(headingText);
    final headingIndex = uiState.navigatorHeadings.indexWhere(
      (h) =>
          h.messageId == messageId &&
          h.level == level &&
          stripMarkdownFormatting(h.text) == normalizedTapText,
    );

    if (headingIndex >= 0) {
      ref.read(chatScreenProvider.notifier).setActiveHeadingIndex(headingIndex);
      final heading = uiState.navigatorHeadings[headingIndex];
      final registry = HeadingAnchorRegistry();
      final normalizedText = stripMarkdownFormatting(headingText);
      final anchorId = '${messageId}_${level}_$normalizedText';
      final anchor = registry.getAnchor(anchorId);
      final ctx = anchor?.context ?? heading.context;

      void performScroll() {
        var scrollCtx = anchor?.context ?? heading.context;
        if (scrollCtx == null || !scrollCtx.mounted) {
          final reg = HeadingAnchorRegistry();
          for (final a in reg.allAnchors) {
            if (a.messageId == messageId &&
                a.context != null &&
                a.context!.mounted) {
              scrollCtx = a.context;
              break;
            }
          }
        }
        if (scrollCtx != null && scrollCtx.mounted) {
          Scrollable.ensureVisible(
            scrollCtx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return;
        }
        if (_messageScrollController.hasClients) {
          final chat = currentChat;
          if (chat != null) {
            final msgIndex = chat.messages.indexWhere((m) => m.id == messageId);
            if (msgIndex >= 0) {
              final viewportHeight =
                  _messageScrollController.position.viewportDimension;
              final maxScroll =
                  _messageScrollController.position.maxScrollExtent;
              final avgItemHeight =
                  viewportHeight > 0 && chat.messages.isNotEmpty
                  ? viewportHeight / min(chat.messages.length, 5)
                  : 150.0;
              final estimatedOffset = msgIndex * avgItemHeight;
              final targetOffset = estimatedOffset.clamp(0.0, maxScroll);
              _messageScrollController.animateTo(
                targetOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        }
      }

      if (ctx != null && ctx.mounted) {
        performScroll();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          performScroll();
        });
      }
    }
    ref.read(chatScreenProvider.notifier).setNavigatorVisible(false);
  }
}
