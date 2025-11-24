import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gen_ui_chat_ai/utils/chat_scroll_utils.dart';

void main() {
  group('ChatScrollUtils Auto-Scroll Tests', () {
    late ChatScrollUtils chatScrollUtils;
    late ScrollController scrollController;

    setUp(() {
      scrollController = ScrollController();
      chatScrollUtils = ChatScrollUtils(
        scrollController: scrollController,
        animationDuration: const Duration(milliseconds: 100),
      );
    });

    tearDown(() {
      scrollController.dispose();
    });

    test('should scroll to bottom when new messages added', () async {
      // Simulate scroll controller with content
      scrollController.jumpTo(100.0);
      
      // Trigger auto-scroll
      chatScrollUtils.onNewMessages();
      
      // Wait for animation
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Should be near bottom
      expect(
        scrollController.offset,
        greaterThan(scrollController.position.maxScrollExtent - 50.0),
      );
    });

    test('should aggressively scroll during streaming', () async {
      // Simulate user reading old messages
      scrollController.jumpTo(200.0);
      
      // Trigger streaming auto-scroll
      chatScrollUtils.onNewMessagesStreaming();
      
      // Wait for animation
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Should be at bottom despite user position
      expect(
        scrollController.offset,
        greaterThan(scrollController.position.maxScrollExtent - 10.0),
      );
    });

    test('should respect auto-scroll enabled/disabled', () {
      chatScrollUtils.setAutoScrollEnabled(false);
      
      // Should not scroll when disabled
      final initialPosition = scrollController.offset;
      chatScrollUtils.onNewMessages();
      
      expect(scrollController.offset, initialPosition);
    });
  });
}