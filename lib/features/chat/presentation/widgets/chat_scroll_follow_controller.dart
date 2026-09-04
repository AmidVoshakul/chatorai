import 'package:flutter/material.dart';
import 'package:chatorai/core/constants/chat_messages_constants.dart';

class ChatScrollFollowController {
  ScrollController? _scroll;
  bool _autoScroll = true;
  bool _userAtBottom = true;
  bool _dragActive = false;
  bool _needsInitialScroll = false;
  int _snapRetries = 0;

  void attach(ScrollController controller) {
    _scroll = controller;
    _needsInitialScroll = true;
    _snapRetries = 0;
  }

  void dispose() {
    _scroll = null;
    _dragActive = false;
  }

  bool handleNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _dragActive = notification.dragDetails != null;
    }
    if (notification is ScrollEndNotification) {
      _dragActive = false;
    }
    return false;
  }

  void onScroll() {
    final c = _scroll;
    if (c == null || !c.hasClients) return;
    _userAtBottom = _isAtBottom(c);
    _needsInitialScroll = false;
  }

  void noteGrowth({required bool autoScroll}) {
    final c = _scroll;
    if (c == null || !c.hasClients) return;
    if (!c.position.hasContentDimensions) return;
    _autoScroll = autoScroll;
    _userAtBottom = _isAtBottom(c);
    if (_needsInitialScroll && _autoScroll && !_dragActive) {
      _needsInitialScroll = false;
      _jumpToBottom(c);
      return;
    }
    if (_autoScroll && _userAtBottom && !_dragActive) {
      _jumpToBottom(c);
    }
  }

  void snapToBottom() {
    _snapToBottomImpl();
  }

  void _snapToBottomImpl() {
    final c = _scroll;
    if (c == null) return;
    if (!c.hasClients || !c.position.hasContentDimensions) {
      if (_snapRetries < 3) {
        _snapRetries++;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _snapToBottomImpl(),
        );
      }
      return;
    }
    _jumpToBottom(c);
  }

  void _jumpToBottom(ScrollController controller) {
    final target = controller.position.maxScrollExtent;
    if ((controller.offset - target).abs() <= 1.0) return;
    controller.jumpTo(target);
  }

  bool _isAtBottom(ScrollController controller) {
    return controller.offset >=
        controller.position.maxScrollExtent - ChatMessagesConstants.followBand;
  }
}
