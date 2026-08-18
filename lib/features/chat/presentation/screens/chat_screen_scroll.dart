part of 'chat_screen.dart';

extension _ChatScreenScrollExt on _ChatScreenState {
  void _handleScroll() {
    if (!_messageScrollController.hasClients) return;

    final offset = _messageScrollController.offset;
    final max = _messageScrollController.position.maxScrollExtent;
    final distanceFromBottom = max - offset;
    final newAutoScroll = distanceFromBottom <= 150;

    // Update state only if changed to avoid unnecessary rebuilds
    if (_autoScrollEnabled != newAutoScroll) {
      _autoScrollEnabled = newAutoScroll;
    }
  }

  void _scrollToBottom({bool force = false, double? offset}) {
    if (!_messageScrollController.hasClients) {
      return;
    }

    final position = _messageScrollController.position;
    if (!position.hasContentDimensions) {
      return;
    }

    final maxScroll = position.maxScrollExtent;

    final targetScroll = offset != null
        ? (maxScroll - offset).clamp(0.0, maxScroll)
        : maxScroll;

    if (force) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_messageScrollController.hasClients) {
          _messageScrollController.jumpTo(targetScroll);
        }
      });
    } else {
      _messageScrollController.jumpTo(targetScroll);
    }
  }

  void _maybeAutoScrollDuringStreaming() {
    if (!mounted) return;
    if (!ref.read(themeProvider).autoScrollDuringStreaming) return;
    if (!_autoScrollEnabled) return;
    if (!_messageScrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottom(force: false);
    });
  }

  void _handleHeadingSync() {
    final now = DateTime.now();
    if (_lastScrollUpdate != null &&
        now.difference(_lastScrollUpdate!) <
            _ChatScreenState._scrollThrottleDuration) {
      return;
    }
    _lastScrollUpdate = now;

    final navigatorHeadings = ref.watch(
      chatScreenProvider.select((s) => s.navigatorHeadings),
    );
    if (!_messageScrollController.hasClients || navigatorHeadings.isEmpty) {
      return;
    }

    final currentOffset = _messageScrollController.offset;
    final viewportHeight = _messageScrollController.position.viewportDimension;
    final registry = HeadingAnchorRegistry();
    int newActiveIndex = -1;

    for (int i = 0; i < navigatorHeadings.length; i++) {
      final heading = navigatorHeadings[i];
      final anchorId = '${heading.messageId}_${heading.level}_${heading.text}';
      final anchor = registry.getAnchor(anchorId);
      final ctx = anchor?.context ?? heading.context;
      if (ctx == null || !ctx.mounted) continue;
      try {
        final RenderBox? box = ctx.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final position = box.localToGlobal(Offset.zero);
          if (position.dy < viewportHeight / 2 && position.dy > -50) {
            newActiveIndex = i;
            break;
          }
        }
      } catch (e) {
        // Ignore render errors
      }
    }

    if (newActiveIndex == -1) {
      final scrollMax = _messageScrollController.position.maxScrollExtent;
      if (currentOffset >= scrollMax - 100) {
        newActiveIndex = navigatorHeadings.length - 1;
      } else if (currentOffset < 100) {
        newActiveIndex = 0;
      }
    }

    final activeHeadingIndex = ref.watch(
      chatScreenProvider.select((s) => s.activeHeadingIndex),
    );
    if (newActiveIndex != -1 && newActiveIndex != activeHeadingIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && newActiveIndex != -1) {
          ref
              .read(chatScreenProvider.notifier)
              .setActiveHeadingIndex(newActiveIndex);
        }
      });
    }
  }
}
