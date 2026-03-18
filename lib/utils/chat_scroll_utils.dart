import 'package:flutter/widgets.dart';

class ChatScrollUtils {
  final ScrollController scrollController;
  final Duration animationDuration;
  final Curve animationCurve;

  ChatScrollUtils({
    required this.scrollController,
    required this.animationDuration,
    required this.animationCurve,
  });

  Future<void> scrollToBottom() async {
    if (!scrollController.hasClients) return;

    try {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.offset;
      final scrollDifference = (maxScroll - currentScroll).abs();

      if (scrollDifference < 5) return;

      await scrollController.animateTo(
        maxScroll,
        duration: animationDuration,
        curve: animationCurve,
      );
    } catch (e) {
      // Тихий промах - скролл не критичен
    }
  }

  Future<void> scrollToIndicator() => scrollToBottom();
}
