import 'package:chatorai/gui/features/chat/presentation/widgets/continuation_suggestions.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/welcome_suggestions.dart';
import 'package:flutter/material.dart';

class ChatMessagesWelcomeSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final BuildContext parentContext;
  final void Function(String) onSuggestionTap;
  final VoidCallback? onClose;

  const ChatMessagesWelcomeSuggestions({
    super.key,
    required this.suggestions,
    required this.parentContext,
    required this.onSuggestionTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return WelcomeSuggestions(
      suggestions: suggestions,
      parentContext: parentContext,
      onSuggestionTap: onSuggestionTap,
      onClose: onClose,
    );
  }
}

class ChatMessagesContinuationSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final bool isLoading;
  final BuildContext parentContext;
  final void Function(String) onSuggestionTap;
  final VoidCallback? onClose;
  final VoidCallback? onRefresh;

  const ChatMessagesContinuationSuggestions({
    super.key,
    required this.suggestions,
    required this.isLoading,
    required this.parentContext,
    required this.onSuggestionTap,
    this.onClose,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ContinuationSuggestions(
      suggestions: suggestions,
      isLoading: isLoading,
      context: parentContext,
      onSuggestionTap: onSuggestionTap,
      onClose: onClose,
      onRefresh: onRefresh,
    );
  }
}
