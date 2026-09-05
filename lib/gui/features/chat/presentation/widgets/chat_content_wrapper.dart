import 'package:chatorai/core/constants/chat_constants.dart';
import 'package:flutter/material.dart';

class ChatContentWrapper extends StatelessWidget {
  final Widget child;
  final double screenWidth;
  final bool isNavigatorVisible;
  final bool wideScreenMode;
  final bool Function() hasHeadings;
  final VoidCallback toggleNavigator;

  const ChatContentWrapper({
    super.key,
    required this.child,
    required this.screenWidth,
    required this.isNavigatorVisible,
    required this.wideScreenMode,
    required this.hasHeadings,
    required this.toggleNavigator,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (hasHeadings() && !isNavigatorVisible) {
          if ((details.primaryDelta ?? 0) < -10 &&
              details.globalPosition.dx > screenWidth - 30) {
            toggleNavigator();
          }
        }
      },
      child: child,
    );

    if (screenWidth >= ChatScreenConstants.mobileBreakpoint) {
      if (wideScreenMode) return content;
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          width: screenWidth * 0.65,
          child: content,
        ),
      );
    }
    return content;
  }
}
