import 'dart:math';

import 'package:chatorai/gui/features/chat/presentation/widgets/chat_shimmer_text.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

// ===========================================================================
// CHAT LOADING INDICATOR — shimmer text
// ===========================================================================

class ChatLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const ChatLoadingIndicator({
    super.key,
    this.size = ChatoraiSizes.chatLoadingIndicatorDefaultSize,
    this.color,
  });

  @override
  State<ChatLoadingIndicator> createState() => _ChatLoadingIndicatorState();
}

class _ChatLoadingIndicatorState extends State<ChatLoadingIndicator> {
  late final int _messageIndex;

  @override
  void initState() {
    super.initState();
    _messageIndex = Random().nextInt(5);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messages = [
      l10n.loadingMsg1,
      l10n.loadingMsg2,
      l10n.loadingMsg3,
      l10n.loadingMsg4,
      l10n.loadingMsg5,
    ];

    return ChatShimmerText(
      text: messages[_messageIndex],
      textSize: widget.size,
      color: widget.color,
    );
  }
}
