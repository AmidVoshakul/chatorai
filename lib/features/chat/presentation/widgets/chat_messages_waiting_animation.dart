import 'package:flutter/material.dart';
import 'package:chatorai/core/constants/chat_messages_constants.dart';
import 'package:chatorai/features/chat/presentation/widgets/loading_indicator.dart';

class ChatMessagesWaitingAnimation extends StatelessWidget {
  final GlobalKey loadingIndicatorKey;

  const ChatMessagesWaitingAnimation({
    super.key,
    required this.loadingIndicatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ChatMessagesConstants.horizontalPadding,
        vertical: ChatMessagesConstants.messageSpacing,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ChatLoadingIndicator(
            key: loadingIndicatorKey,
            size: ChatMessagesConstants.loadingIndicatorSize,
          ),
        ],
      ),
    );
  }
}
