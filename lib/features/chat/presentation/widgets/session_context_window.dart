import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/features/chat/data/models/chat/message_converter.dart'
    show sessionStateToChat;
import 'package:chatorai/features/chat/presentation/widgets/chat_messages.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_scroll_follow_controller.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart'
    show modelProvider, sessionPartsProvider, sessionRepositoryProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================

class SessionContextWindow extends ConsumerStatefulWidget {
  final String sessionId;
  final ScrollController? scrollController;
  final ChatScrollFollowController? followController;
  final void Function(String? taskSessionId)? onTaskTap;

  const SessionContextWindow({
    super.key,
    required this.sessionId,
    this.scrollController,
    this.followController,
    this.onTaskTap,
  });

  @override
  ConsumerState<SessionContextWindow> createState() =>
      _SessionContextWindowState();
}

class _SessionContextWindowState extends ConsumerState<SessionContextWindow> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final stateAsync = ref.watch(sessionPartsProvider(widget.sessionId));

    if (stateAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (stateAsync.hasError) {
      return Center(
        child: Text(
          localizations.noChatsYet,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
        ),
      );
    }

    final state = stateAsync.value;
    if (state == null) {
      return Center(
        child: Text(
          localizations.noChatsYet,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
        ),
      );
    }

    final chat = sessionStateToChat(state);

    if (chat.messages.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Text(
          localizations.noChatsYet,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      );
    }

    return FutureBuilder<SessionRepository>(
      future: ref.read(sessionRepositoryProvider.future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final SessionRepository sessionRepository = snapshot.data!;
        return ChatMessages(
          key: ValueKey(widget.sessionId),
          sessionRepository: sessionRepository,
          chat: chat,
          sessionId: widget.sessionId,
          agentName: state.agent,
          selectedModel: ref.watch(modelProvider).selectedModelId,
          isActiveSession: false,
          onSendMessage: (messageData) {},
          onMessageDeleted: () {},
          onMessageEdited: (_, _) {},
          onMessageEditAndSend: (_, _) {},
          onContinueResponse: (_) {},
          onRegenerateResponse: (_) {},
          scrollController: _scrollController,
          followController: widget.followController,
          onTaskTap: widget.onTaskTap,
        );
      },
    );
  }
}
