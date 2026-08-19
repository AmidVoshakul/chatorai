import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart' show SessionState;
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart'
    show AssistantContent, AssistantText;
import 'package:chatorai/features/chat/data/models/chat/message_converter.dart'
    show assistantContentToPartMaps;
import 'package:chatorai/features/chat/data/models/chat_models.dart'
    show Chat, Message, MessageRole;
import 'package:chatorai/features/chat/presentation/widgets/chat_messages.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart'
    show
        modelProvider,
        sessionPartsProvider,
        sessionRepositoryProvider,
        themeProvider;
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
  bool _autoScrollEnabled = true;
  int _previousPartsLength = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final max = _scrollController.position.maxScrollExtent;
    final distanceFromBottom = max - offset;
    _autoScrollEnabled = distanceFromBottom <= 150;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    if (!ref.read(themeProvider).autoScrollDuringStreaming) return;
    if (!_autoScrollEnabled) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final diff = (maxScroll - currentScroll).abs();
    if (diff < 5) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Message? _buildAssistantMessageFromParts(
    List<AssistantContent> parts, {
    String? model,
  }) {
    if (parts.isEmpty) return null;

    String? textContent;

    for (final part in parts) {
      if (part is AssistantText) {
        textContent = (textContent ?? '') + part.text;
      }
    }

    return Message(
      id: 'child_assistant_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: textContent ?? '',
      timestamp: DateTime.now(),
      // FIX #1: Do NOT flatten reasoning — partsJson is the source of truth.
      reasoning: null,
      isComplete: true,
      partsJson: assistantContentToPartMaps(parts),
      // FIX #2: Set model from state when available.
      model: model,
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
    // This matches architecture where an assistant message contains
    // an array of parts, and matches ChatMessages expectation
    final assistantMessage = _buildAssistantMessageFromParts(
      state.parts,
      model: state.modelRef,
    );
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

    if (state.parts.length > _previousPartsLength) {
      _previousPartsLength = state.parts.length;
      _scrollToBottom();
    }

    final legacyMessages = _buildMessages(state);
    _applySessionTokens(legacyMessages, state);

    if (legacyMessages.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Text(
          localizations.noChatsYet,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
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
          onTaskTap: widget.onTaskTap,
        );
      },
    );
  }
}
