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

  void _scrollToBottom({bool force = false}) {
    if (!_messageScrollController.hasClients) {
      return;
    }

    final position = _messageScrollController.position;
    if (!position.hasContentDimensions) {
      return;
    }

    final maxScroll = position.maxScrollExtent;
    final currentScroll = _messageScrollController.offset;
    final diff = (maxScroll - currentScroll).abs();

    // If not forcing and already near bottom (within 5px), skip
    if (!force && diff < 5) {
      return;
    }

    if (force) {
      // Smooth animation after sending a message
      _messageScrollController.animateTo(
        maxScroll,
        duration: ChatScreenConstants.scrollAnimationDuration,
        curve: Curves.easeOut,
      );
    } else {
      // Instant jump during streaming — no animation, because maxScrollExtent
      // changes every frame while new chunks arrive. animateTo would compete
      // with the growing content and cause visible jumping.
      _messageScrollController.jumpTo(maxScroll);
    }
  }

  void _handleHeadingSync() {
    final now = DateTime.now();
    if (_lastScrollUpdate != null &&
        now.difference(_lastScrollUpdate!) <
            _ChatScreenState._scrollThrottleDuration) {
      return;
    }
    _lastScrollUpdate = now;

    final uiState = ref.watch(chatScreenProvider);
    if (!_messageScrollController.hasClients ||
        uiState.navigatorHeadings.isEmpty) {
      return;
    }

    final currentOffset = _messageScrollController.offset;
    final viewportHeight = _messageScrollController.position.viewportDimension;
    final registry = HeadingAnchorRegistry();
    int newActiveIndex = -1;

    for (int i = 0; i < uiState.navigatorHeadings.length; i++) {
      final heading = uiState.navigatorHeadings[i];
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
        newActiveIndex = uiState.navigatorHeadings.length - 1;
      } else if (currentOffset < 100) {
        newActiveIndex = 0;
      }
    }

    if (newActiveIndex != -1 && newActiveIndex != uiState.activeHeadingIndex) {
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
