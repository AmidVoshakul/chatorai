import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input.dart'
    show MessageData;
import 'package:chatorai/features/chat/presentation/widgets/chat_messages.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_scroll_follow_controller.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_messages_suggestions.dart';
import 'package:chatorai/shared/utils/markdown_parser.dart';
import 'package:flutter/material.dart';

class ChatMessagesLoadingPlaceholder extends StatelessWidget {
  const ChatMessagesLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class ChatMessagesArea extends StatelessWidget {
  final Chat? chat;
  final Future<SessionRepository> sessionRepositoryFuture;
  final ScrollController scrollController;
  final ChatScrollFollowController followController;
  final String? selectedModel;
  final Function(MessageData) onSendMessage;
  final VoidCallback onMessageDeleted;
  final Function(String, String)? onMessageEdited;
  final Function(String, String)? onMessageEditAndSend;
  final Function(String)? onContinueResponse;
  final Function(String)? onRegenerateResponse;
  final List<String> continuationSuggestions;
  final bool showSuggestions;
  final bool isSuggestionsLoading;
  final VoidCallback? onSuggestionsClose;
  final VoidCallback? onSuggestionsRefresh;
  final List<String> welcomeSuggestions;
  final bool showWelcomeSuggestions;
  final VoidCallback? onWelcomeSuggestionsClose;
  final Function(List<MarkdownHeadingInfoWithKey>)? onHeadingsUpdated;
  final VoidCallback? onToggleNavigator;
  final Function(String, String)? onQuestionAnswer;
  final void Function(String?)? onTaskTap;
  final String? sessionId;
  final bool wrapWithGesture;
  final bool Function() hasHeadings;
  final VoidCallback toggleNavigator;

  const ChatMessagesArea({
    this.chat,
    required this.sessionRepositoryFuture,
    required this.scrollController,
    required this.followController,
    this.selectedModel,
    required this.onSendMessage,
    required this.onMessageDeleted,
    this.onMessageEdited,
    this.onMessageEditAndSend,
    this.onContinueResponse,
    this.onRegenerateResponse,
    this.continuationSuggestions = const [],
    this.showSuggestions = false,
    this.isSuggestionsLoading = false,
    this.onSuggestionsClose,
    this.onSuggestionsRefresh,
    this.welcomeSuggestions = const [],
    this.showWelcomeSuggestions = false,
    this.onWelcomeSuggestionsClose,
    this.onHeadingsUpdated,
    this.onToggleNavigator,
    this.onQuestionAnswer,
    this.onTaskTap,
    this.sessionId,
    this.wrapWithGesture = false,
    required this.hasHeadings,
    required this.toggleNavigator,
  });

  @override
  Widget build(BuildContext context) {
    final chatMessages = FutureBuilder<SessionRepository>(
      future: sessionRepositoryFuture,
      builder: (context, snapshot) {
        // Show Welcome questions immediately, without waiting for the session
        // repository (history) to load. The repository only backs message
        // history/tooling — the welcome layer needs none of it, so gating it
        // behind the future produced a black chat until startup settled.
        if (snapshot.hasError) {
          return Center(
            child: Text(
              AppLocalizations.of(
                context,
              )!.errorLoadingChat('${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          if (showWelcomeSuggestions && welcomeSuggestions.isNotEmpty) {
            final theme = Theme.of(context);
            return Container(
              color: theme.scaffoldBackgroundColor,
              child: Center(
                child: ChatMessagesWelcomeSuggestions(
                  suggestions: welcomeSuggestions,
                  parentContext: context,
                  onSuggestionTap: (suggestion) {
                    onSendMessage(MessageData(text: suggestion));
                  },
                  onClose: onWelcomeSuggestionsClose,
                ),
              ),
            );
          }
          return const ChatMessagesLoadingPlaceholder();
        }
        final sessionRepository = snapshot.data!;
        return ChatMessages(
          sessionRepository: sessionRepository,
          chat: chat,
          selectedModel: selectedModel,
          sessionId: sessionId,
          onSendMessage: onSendMessage,
          onMessageDeleted: onMessageDeleted,
          onMessageEdited: onMessageEdited,
          onMessageEditAndSend: onMessageEditAndSend,
          onContinueResponse: onContinueResponse,
          onRegenerateResponse: onRegenerateResponse,
          scrollController: scrollController,
          followController: followController,
          continuationSuggestions: continuationSuggestions,
          showSuggestions: showSuggestions,
          isSuggestionsLoading: isSuggestionsLoading,
          onSuggestionsClose: onSuggestionsClose,
          onSuggestionsRefresh: onSuggestionsRefresh,
          welcomeSuggestions: welcomeSuggestions,
          showWelcomeSuggestions: showWelcomeSuggestions,
          onWelcomeSuggestionsClose: onWelcomeSuggestionsClose,
          onHeadingsUpdated: onHeadingsUpdated,
          onToggleNavigator: onToggleNavigator,
          onQuestionAnswer: onQuestionAnswer,
          onTaskTap: onTaskTap,
        );
      },
    );

    if (wrapWithGesture) {
      return GestureDetector(
        onDoubleTap: () {
          if (hasHeadings()) toggleNavigator();
        },
        child: chatMessages,
      );
    }
    return chatMessages;
  }
}
