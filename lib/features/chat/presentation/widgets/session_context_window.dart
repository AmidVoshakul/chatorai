import 'package:chatorai/core/session/session_state.dart'
    show SessionState;
import 'package:chatorai/features/chat/data/models/chat_models.dart'
    show Chat, Message, MessageRole;
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart'
    show AssistantContent, AssistantText, AssistantReasoning;
import 'package:chatorai/features/chat/data/models/chat/session_to_chat_converter.dart'
    show assistantContentToPartMaps;
import 'package:chatorai/features/chat/presentation/widgets/chat_messages.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================

class SessionContextWindow extends ConsumerStatefulWidget {
  final String sessionId;
  final ScrollController? scrollController;
  final void Function(String? taskSessionId)? onTaskTap;

  const SessionContextWindow({
    super.key,
    required this.sessionId,
    this.scrollController,
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

  Message? _buildAssistantMessageFromParts(List<AssistantContent> parts) {
    if (parts.isEmpty) return null;

    String? textContent;
    String? reasoningContent;

    for (final part in parts) {
      if (part is AssistantText) {
        textContent = part.text;
      } else if (part is AssistantReasoning) {
        reasoningContent = part.text;
      }
    }

    return Message(
      id: 'child_assistant_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: textContent ?? '',
      timestamp: DateTime.now(),
      reasoning: reasoningContent,
      isComplete: true,
      partsJson: assistantContentToPartMaps(parts),
    );
  }

  List<Message> _buildMessages(SessionState state) {
    final result = <Message>[];

    // Emit user messages first
    for (final m in state.messages) {
      final roleName = m.role.toString().split('.').last;
      if (roleName == 'user') {
        result.add(
          Message(
            id: m.id,
            role: MessageRole.user,
            content: m.content,
            timestamp: m.createdAt,
          ),
        );
      }
    }

    // All assistant parts (reasoning + text + tools) go into ONE message
    // This matches OpenCode's architecture where an assistant message contains
    // an array of parts, and matches ChatMessages expectation
    final assistantMessage = _buildAssistantMessageFromParts(state.parts);
    if (assistantMessage != null) {
      result.add(assistantMessage);
    }

    return result;
  }

  void _applySessionTokens(List<Message> messages, SessionState state) {
    if (state.tokensInput == 0 &&
        state.tokensOutput == 0 &&
        state.tokensReasoning == 0) {
      return;
    }
    final lastAsst = messages.lastIndexWhere(
      (m) => m.role == MessageRole.assistant,
    );
    if (lastAsst < 0) return;
    final m = messages[lastAsst];
    messages[lastAsst] = Message(
      id: m.id,
      role: m.role,
      content: m.content,
      timestamp: m.timestamp,
      model: m.model,
      reasoning: m.reasoning,
      partsJson: m.partsJson,
      isComplete: m.isComplete,
      tokensInput: state.tokensInput,
      tokensOutput: state.tokensOutput,
      tokensReasoning: state.tokensReasoning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final stateAsync = ref.watch(
      childSessionStateProvider(widget.sessionId),
    );

    if (stateAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (stateAsync.hasError) {
      return Center(
        child: Text(
          localizations.noChatsYet,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      );
    }

    final state = stateAsync.value;
    if (state == null) {
      return Center(
        child: Text(
          localizations.noChatsYet,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      );
    }

    final legacyMessages = _buildMessages(state);
    _applySessionTokens(legacyMessages, state);

    if (legacyMessages.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Text(
          localizations.noChatsYet,
          style:
              theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      );
    }

    final chat = Chat(
      id: widget.sessionId,
      title: '',
      messages: legacyMessages,
      createdAt: legacyMessages.first.timestamp,
      updatedAt: legacyMessages.last.timestamp,
    );

    return ProviderScope(
      overrides: [
        streamingMessageProvider.overrideWith(
          StreamingMessageNotifier.new,
        ),
      ],
      child: ChatMessages(
        key: ValueKey(widget.sessionId),
        chatStorageService: ref.read(chatStorageServiceProvider),
        chat: chat,
        agentName: state.agent,
        selectedModel: ref.watch(modelProvider).selectedModelId,
        onSendMessage: (messageData) {},
        onMessageDeleted: () {},
        onMessageEdited: (_, _) {},
        onMessageEditAndSend: (_, _) {},
        onContinueResponse: (_) {},
        onRegenerateResponse: (_) {},
        scrollController: _scrollController,
        onTaskTap: widget.onTaskTap,
      ),
    );
  }
}
