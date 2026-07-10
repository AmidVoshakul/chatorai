import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:flutter/material.dart';

class SystemMessageBubble extends StatelessWidget {
  final SystemMessage message;

  const SystemMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message.content,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
