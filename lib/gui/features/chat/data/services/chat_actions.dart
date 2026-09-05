import 'dart:async';

import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/commands/command_parser.dart';
import 'package:chatorai/core/config/config_provider.dart'
    show resolvedInstructionsProvider;
import 'package:chatorai/core/context/compaction_orchestrator.dart';
import 'package:chatorai/core/context/compaction_service.dart';
import 'package:chatorai/core/session/event_bus.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/tools/built_in/task_shared.dart';
import 'package:chatorai/core/chat/chat/assistant_content.dart';
import 'package:chatorai/core/chat/chat/chat_message.dart';
import 'package:chatorai/core/chat/chat/message_converter.dart'
    show assistantContentToPartMaps, filterPartsByMessage, sessionStateToChat;
import 'package:chatorai/core/chat/chat/question_option.dart';
import 'package:chatorai/core/chat/chat_models.dart';
import 'package:chatorai/gui/features/chat/data/services/chat_context_builder.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/message_data.dart';
import 'package:chatorai/gui/features/chat/services/continuation_suggestion_service.dart';
import 'package:chatorai/gui/features/settings/data/models/model_settings.dart';
import 'package:chatorai/gui/shared/utils/message_dialogs.dart';
import 'package:chatorai/gui/shared/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart'
    show
        themeProvider,
        modelProvider,
        modelSettingsProvider,
        chatListProvider,
        chatAiServiceProvider,
        currentChatIdProvider,
        currentChatProvider,
        chatScreenProvider,
        toolRegistryProvider,
        currentAgentProvider,
        compactionConfigProvider,
        currentSessionRunnerProvider,
        sessionRepositoryProvider,
        sessionStackProvider,
        permissionServiceProvider,
        sessionPartsProvider;
import 'package:chatorai/shared/utils/chat_error_utils.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatActions {
  ChatActions(this.ref);
  final WidgetRef ref;

  // ── Run/session coordination state (was private on _ChatScreenState) ──
  SessionRunnerSession? _sessionRunner;
  bool _streamCancelled = false;
  String? _currentSessionId;
  bool _isHandlingMessage = false;
  String? _pendingSelectChatId;

  String? get currentSessionId => _currentSessionId;

  /// Releases the active [SessionRunner] if the screen is disposed while a
  /// stream is still in flight, so its event-bus subscriptions and timers
  /// don't leak after the chat is popped.
  void dispose() {
    _sessionRunner?.dispose();
    _sessionRunner = null;
  }

  /// Executes a command marked with subtask semantics: runs the expanded
  /// prompt in a child session bound to [messageData.agentMention], shows a
  /// live task card in the parent session, and skips any parent LLM turn.
  ///
  /// Returns true when the subtask was started (caller must skip the normal
  /// flow). On failure it logs a warning and returns false so the caller can
  /// degrade gracefully to an inline message instead of losing user input.
  Future<void> _runCommandSubtask({
    required MessageData messageData,
    required Chat chat,
    required SessionID sessionId,
    required BuildContext context,
    required FocusNode chatInputFocusNode,
    required ScrollController scrollController,
    required bool Function() isMounted,
    required VoidCallback scrollToBottom,
  }) async {
    final aiService = ref.read(chatAiServiceProvider);

    // The runner cannot rely on UI bindings: nothing has bound a streaming
    // session yet at command-send time. Build it from the same providers the
    // normal assistant turn uses.
    try {
      final repo = await ref.read(sessionRepositoryProvider.future);
      final registry = await ref.read(toolRegistryProvider.future);
      final eventBus = ref.read(sessionEventBusProvider);
      final runner = SessionRunner(repo, registry, eventBus: eventBus);
      final holder = ref.read(currentSessionRunnerProvider.notifier).holder;

      final agentId = messageData.agentMention!;
      final agent = AgentRegistry().get(agentId);
      final systemContent =
          agent?.systemPrompt ?? 'You are a helpful assistant.';
      // Model source must match a normal turn: the user's selected model id
      // from modelProvider. aiService.currentModel is only populated DURING a
      // stream, so it is null when a command is the very first message —
      // which made the resolver throw "Model not found in catalog: ".
      final model = agent?.model ?? _selectedModelId;

      // initiateStream wires task callbacks against this session runner.
      // Dispose the previous turn's session first: initiateStream overwrites
      // this field with its own runner and would otherwise leak the timers
      // and buffered parts held by the abandoned session.
      _sessionRunner?.dispose();
      _sessionRunner = SessionRunnerSession.forExisting(
        repository: repo,
        sessionId: sessionId,
        immediate: true,
        eventBus: eventBus,
      );
      // Continue the EXISTING parent session — a fresh session must not be
      // created for the continuation turn.
      _currentSessionId = sessionId.value;

      LogTags.chatScreen.logInfo(
        '_runCommandSubtask: agent=$agentId session=${sessionId.value}',
      );

      // The projector anchors a TaskPart to the LAST assistant message; the
      // task tool path always has one (the turn placeholder). A command
      // subtask has none, so create it explicitly — otherwise the projected
      // part is orphaned on a synthetic message and never renders in chat.
      // Bubble owner is the PARENT agent (it writes the final answer); the
      // task card carries its own agent=general label via AssistantTask.
      final assistantMessage = createAssistantMessage(
        agent: ref.read(currentAgentProvider).name,
      );
      final placeholderEvent = MessageAdded(
        sessionId: sessionId,
        messageId: assistantMessage.id,
        role: assistantMessage.role.name,
        content: '',
        timestamp: assistantMessage.timestamp,
      );
      await repo.appendEvent(placeholderEvent);
      eventBus.emit(placeholderEvent);
      ref
          .read(chatListProvider.notifier)
          .updateChat(
            chat.copyWith(
              messages: [...chat.messages, assistantMessage],
              updatedAt: assistantMessage.timestamp,
            ),
          );

      ref.read(chatScreenProvider.notifier).startStreaming(sessionId.value);
      try {
        final taskResult = await runner.runTaskInChild(
          parentSessionId: sessionId,
          taskPrompt: messageData.taskPrompt!,
          agent: agentId,
          modelRef: model,
          title: messageData.taskTitle,
          holder: holder,
          streamFn: (child) => aiService.runSubagentCompletion(
            child: child,
            messages: [
              {'role': 'system', 'content': systemContent},
              {'role': 'user', 'content': messageData.taskPrompt!},
            ],
            model: model,
            temperature: aiService.currentTemperature ?? 0.7,
            sessionId: sessionId.value,
            tools: deriveSubagentTools(registry),
            maxSteps: agent?.maxSteps ?? unlimitedMaxSteps,
          ),
        );

        // Refresh the chat from the canonical projection so the placeholder
        // message now carries the completed AssistantTask part — without this
        // the card disappears the moment live part-merging stops.
        final parentState = await repo.loadSession(sessionId);
        Chat chatAfterTask = chat;
        if (parentState != null) {
          final canonical = sessionStateToChat(parentState);
          // Projection marks every message complete; the placeholder must stay
          // incomplete so the continuation streams INTO it (same bubble)
          // instead of appending a duplicate one.
          chatAfterTask = canonical.copyWith(
            messages: [
              for (final m in canonical.messages)
                if (m.id == assistantMessage.id)
                  m.copyWith(
                    isComplete: false,
                    // MessageAdded carries no model/agent, so the projection
                    // drops them; restore from the in-memory placeholder or
                    // the ActionRow loses the model chip for this bubble.
                    model: assistantMessage.model,
                    agent: assistantMessage.agent,
                  )
                else
                  m,
            ],
          );
          ref.read(chatListProvider.notifier).updateChat(chatAfterTask);
        }

        // Reference semantics: after the subtask finishes, the PARENT agent
        // continues answering in the same assistant bubble, with the child's
        // full output injected into the model context only.
        final childOutput = taskResult.output.trim();
        if (childOutput.isEmpty) {
          LogTags.chatScreen.logWarning(
            '_runCommandSubtask: child produced empty output; nothing to continue with',
          );
          // This early return bypasses the continuation's own finalize, so
          // clear the streaming state here or the UI hangs in "streaming".
          ref.read(chatScreenProvider.notifier).finalizeStreaming();
          return;
        }
        final note = buildSubtaskResultNote(
          agentName: agent?.name ?? agentId,
          taskTitle: messageData.taskTitle ?? 'Subtask',
          output: childOutput,
        );
        final apiMessages = const ChatContextBuilder().buildApiMessages(
          chatAfterTask,
          currentAgent: ref.read(currentAgentProvider),
          modelSettings: ref.read(modelSettingsProvider).activeSettings,
          instructionBlocks:
              ref.read(resolvedInstructionsProvider).value ?? const [],
        );
        await initiateStream(
          chat: chatAfterTask,
          messages: [
            ...apiMessages,
            {'role': 'user', 'content': note},
          ],
          isContinuation: false,
          pendingAssistantMessageId: assistantMessage.id,
          context: context,
          scrollController: scrollController,
          chatInputFocusNode: chatInputFocusNode,
          isMounted: isMounted,
          scrollToBottom: scrollToBottom,
        );
      } catch (e, st) {
        LogTags.chatScreen.logWarning(
          'runAsSubtask failed: ${e.toString().substring(0, e.toString().length.clamp(0, 160))}…',
          e,
          st,
        );
        await _markPlaceholderFailed(
          sessionId: sessionId,
          errorMessage: e.toString(),
        );
        ref.read(chatScreenProvider.notifier).finalizeStreaming();
      }
    } catch (e, st) {
      LogTags.chatScreen.logWarning(
        'runAsSubtask failed before child start: ${e.toString().substring(0, e.toString().length.clamp(0, 160))}…',
        e,
        st,
      );
      await _markPlaceholderFailed(
        sessionId: sessionId,
        errorMessage: e.toString(),
      );
      ref.read(chatScreenProvider.notifier).finalizeStreaming();
    }
  }

  /// Marks the assistant placeholder of a command subtask as errored so the
  /// bubble never hangs in a "running" state when the child cannot start.
  Future<void> _markPlaceholderFailed({
    required SessionID sessionId,
    required String errorMessage,
  }) async {
    try {
      final repo = await ref.read(sessionRepositoryProvider.future);
      final eventBus = ref.read(sessionEventBusProvider);
      final state = await repo.loadSession(sessionId);
      final placeholder = state?.messages.lastWhere(
        (m) => m.role == MessageRole.assistant && m.content.isEmpty,
      );
      if (placeholder == null) return;
      final event = MessageUpdated(
        sessionId: sessionId,
        messageId: placeholder.id,
        error: errorMessage,
        timestamp: DateTime.now(),
      );
      await repo.appendEvent(event);
      eventBus.emit(event);
    } catch (_) {
      // Best-effort only — the warning above already captured the cause.
    }
  }

  Chat? get _currentChat => ref.read(currentChatProvider);
  String get _selectedModelId => ref.read(modelProvider).selectedModelId;

  // ── Messaging / send ────────────────────────────────────────────────

  Future<void> handleSendMessage(
    MessageData messageData, {
    required BuildContext context,
    required ScrollController scrollController,
    required FocusNode chatInputFocusNode,
    required bool Function() isMounted,
    required VoidCallback showWelcomeSuggestions,
    required VoidCallback scrollToBottom,
  }) async {
    ref.read(chatScreenProvider.notifier).hideAllSuggestions();

    // Reject concurrent sends — second call cancels first, but only
    // after the first finishes awaiting toolRegistry / compact.
    if (_isHandlingMessage) return;

    // Cancel any in-progress streaming before starting a new one.
    // Two rapid sends each wait for toolRegistry (30s+), then both
    // create a SessionRunner and stream on the same session.
    if (_sessionRunner != null || ref.read(chatScreenProvider).isStreaming) {
      _streamCancelled = true;
      ref.read(chatAiServiceProvider).cancelAllRequests();
      ref.read(permissionServiceProvider).cancelAllPendingRequests();
      ref.read(currentSessionRunnerProvider.notifier).cancelAllChildren();
      _sessionRunner = null;
      ref.read(chatScreenProvider.notifier).finalizeStreaming();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      _streamCancelled = false;
    }

    _isHandlingMessage = true;
    try {
      Chat chat;
      if (_currentChat == null) {
        _currentSessionId = null;
        ref.read(permissionServiceProvider).clearSession();
        chat = await ref.read(chatListProvider.notifier).createNewChat();
        ref.read(currentChatIdProvider.notifier).setChatId(chat.id);
      } else {
        final chatId = _currentChat!.id;
        final loaded = await ref
            .read(chatListProvider.notifier)
            .ensureChatLoaded(chatId);
        final current = ref.read(currentChatProvider);
        if (current == null || current.id != chatId) return;
        chat = loaded ?? current;
      }

      // Manual delegation (slash command with subtask semantics): the user
      // hands the prompt straight to the subagent. Nothing of the command is
      // rendered or persisted as a user message — the parent only ever sees
      // the subtask result note injected into its context.
      if (messageData.runAsSubtask &&
          messageData.agentMention != null &&
          messageData.taskPrompt != null) {
        await _runCommandSubtask(
          messageData: messageData,
          chat: chat,
          sessionId: chat.toSessionId(),
          context: context,
          chatInputFocusNode: chatInputFocusNode,
          scrollController: scrollController,
          isMounted: isMounted,
          scrollToBottom: scrollToBottom,
        );
        return;
      }

      final userMessage = createUserMessage(
        messageData.text,
        base64Data: messageData.base64Data,
        imageType: messageData.imageType,
        imageName: messageData.imageName,
        attachedDocPath: messageData.attachedDocPath,
      );
      final sessionRepository = await ref.read(
        sessionRepositoryProvider.future,
      );
      final sessionId = chat.toSessionId();
      await sessionRepository.appendEvent(
        MessageAdded(
          sessionId: sessionId,
          messageId: userMessage.id,
          role: userMessage.role.name,
          content: userMessage.content,
          timestamp: userMessage.timestamp,
        ),
      );

      // Append the user message to the in-memory chat immediately: it must be
      // visible in the UI and included in _buildApiMessages (LLM context).
      // Previously the message was persisted but never added to the chat, so
      // it disappeared from the UI and the model never saw it.
      final streamChat = chat.copyWith(
        messages: [...chat.messages, userMessage],
        updatedAt: DateTime.now(),
      );
      // Show the user message in the UI immediately (before the assistant
      // placeholder is appended by _startAssistantTurn).
      ref.read(chatListProvider.notifier).updateChat(streamChat);

      // Generate the session title in the background — it performs a separate
      // LLM call (up to ~14s) and must NOT block the start of the response
      // stream. _autoGenerateTitleIfNeeded updates the chat list itself.
      if (isMounted() && streamChat.isDefaultTitle) {
        unawaited(autoGenerateTitleIfNeeded(streamChat));
      }

      final agentName =
          AgentRegistry().get(messageData.delegateAgentId ?? '')?.name ??
          ref.read(currentAgentProvider).name;
      // For subagent mentions, keep the current agent (LLM will call task tool)
      final assistantAgentName = messageData.agentMention != null
          ? ref.read(currentAgentProvider).name
          : agentName;
      final messages = const ChatContextBuilder().buildApiMessages(
        streamChat,
        currentAgent: ref.read(currentAgentProvider),
        modelSettings: ref.read(modelSettingsProvider).activeSettings,
        instructionBlocks:
            ref.read(resolvedInstructionsProvider).value ?? const [],
        delegateAgentId: messageData.delegateAgentId,
        agentMention: messageData.agentMention,
      );
      LogTags.chatScreen.logInfo(
        '_handleSendMessage: sending to LLM messages=${messages.length} agentMention=${messageData.agentMention ?? "none"}',
      );
      // Appends the assistant placeholder, updates the chat list and starts
      // streaming into that exact message id (no duplicate bubbles on reload).
      await startAssistantTurn(
        chat: streamChat,
        sessionId: sessionId.value,
        agentName: assistantAgentName,
        delegateAgentId: messageData.delegateAgentId,
        agentMention: messageData.agentMention,
        buildMessages: (withPlaceholder) =>
            const ChatContextBuilder().buildApiMessages(
              withPlaceholder,
              currentAgent: ref.read(currentAgentProvider),
              modelSettings: ref.read(modelSettingsProvider).activeSettings,
              instructionBlocks:
                  ref.read(resolvedInstructionsProvider).value ?? const [],
              delegateAgentId: messageData.delegateAgentId,
              agentMention: messageData.agentMention,
            ),
        context: context,
        scrollController: scrollController,
        chatInputFocusNode: chatInputFocusNode,
        isMounted: isMounted,
        scrollToBottom: scrollToBottom,
      );
    } finally {
      _isHandlingMessage = false;
    }
  }

  // ── Question / answer ───────────────────────────────────────────────

  Future<void> handleQuestionAnswer(
    String messageId,
    String answer, {
    required BuildContext context,
    required ScrollController scrollController,
    required FocusNode chatInputFocusNode,
    required bool Function() isMounted,
    required VoidCallback showWelcomeSuggestions,
    required VoidCallback scrollToBottom,
  }) async {
    final chat = _currentChat;
    if (chat == null) return;
    final messageIndex = chat.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    final message = chat.messages[messageIndex];

    // Only assistant messages can have QuestionPart
    if (message.role != MessageRole.assistant) return;

    // Deserialize parts from partsJson
    List<MessagePart> parts = [];
    if (message.partsJson != null && message.partsJson!.isNotEmpty) {
      parts = message.partsJson!.map((j) => partFromJson(j)).toList();
    }

    // Find the first unanswered QuestionPart
    bool found = false;
    for (int i = 0; i < parts.length; i++) {
      if (parts[i] is QuestionPart) {
        final qp = parts[i] as QuestionPart;
        if (qp.answer == null) {
          parts[i] = qp.copyWith(answer: answer);
          found = true;
          break;
        }
      }
    }
    if (!found) return;

    // Serialize back
    final updatedPartsJson = parts.map((p) => p.toJson()).toList();

    // Update storage message
    final updatedMessage = message.copyWith(
      partsJson: updatedPartsJson,
      timestamp: DateTime.now(),
    );

    final sessionRepository = await ref.read(sessionRepositoryProvider.future);
    final sessionId = chat.toSessionId();
    await sessionRepository.appendEvent(
      MessageUpdated(
        sessionId: sessionId,
        messageId: updatedMessage.id,
        content: updatedMessage.content,
        reasoning: updatedMessage.reasoning,
        model: updatedMessage.model,
        error: updatedMessage.isError ? updatedMessage.content : null,
        timestamp: updatedMessage.timestamp,
      ),
    );

    // Update provider
    final updatedChat = chat.copyWith(
      messages: List.of(chat.messages)..[messageIndex] = updatedMessage,
      updatedAt: DateTime.now(),
    );
    ref.read(chatListProvider.notifier).updateChat(updatedChat);

    // Send answer as a new user message
    await handleSendMessage(
      MessageData(text: answer),
      context: context,
      scrollController: scrollController,
      chatInputFocusNode: chatInputFocusNode,
      isMounted: isMounted,
      showWelcomeSuggestions: showWelcomeSuggestions,
      scrollToBottom: scrollToBottom,
    );
  }

  // ── Message factories ───────────────────────────────────────────────

  Message createUserMessage(
    String content, {
    String? base64Data,
    String? imageType,
    String? imageName,
    String? attachedDocPath,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      isComplete: true,
      imageData: base64Data,
      imageType: imageType,
      imageName: imageName,
      attachedDocPath: attachedDocPath,
    );
  }

  Message createAssistantMessage({
    String content = '',
    bool isComplete = false,
    String? model,
    String? reasoning,
    int? tokensInput,
    int? tokensOutput,
    int? tokensReasoning,
    int? tokensCacheRead,
    int? tokensCacheWrite,
    bool? tokensCacheIncludedInInput,
    int? contextLength,
    List<Map<String, dynamic>>? partsJson,
    String? agent,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      isComplete: isComplete,
      model: model ?? _selectedModelId,
      reasoning: reasoning,
      tokensInput: tokensInput,
      tokensOutput: tokensOutput,
      tokensReasoning: tokensReasoning,
      tokensCacheRead: tokensCacheRead,
      tokensCacheWrite: tokensCacheWrite,
      tokensCacheIncludedInInput: tokensCacheIncludedInInput,
      contextLength: contextLength,
      partsJson: partsJson,
      agent: agent ?? ref.read(currentAgentProvider).name,
    );
  }

  // ── Streaming control ───────────────────────────────────────────────

  Future<void> stopStreaming({
    required BuildContext context,
    required bool Function() isMounted,
  }) async {
    _streamCancelled = true;
    final aiService = ref.read(chatAiServiceProvider);
    aiService.cancelAllRequests();

    final permissionService = ref.read(permissionServiceProvider);
    permissionService.cancelAllPendingRequests();

    ref.read(currentSessionRunnerProvider.notifier).cancelAllChildren();

    await Future<void>.delayed(const Duration(milliseconds: 100));

    final chat = _currentChat;
    if (chat == null || chat.messages.isEmpty) {
      ref.read(chatScreenProvider.notifier).finalizeStreaming();
      ref
          .read(chatScreenProvider.notifier)
          .setRetryInfo(isRetrying: false, retryMessage: null, retryAttempt: 0);
      return;
    }

    final sessionId = ref.read(chatScreenProvider).streamingSessionId;
    final List<AssistantContent> closedParts;
    if (sessionId != null) {
      final sessionAsyncState = ref.read(sessionPartsProvider(sessionId));
      final sessionState = sessionAsyncState.value;
      closedParts = sessionState != null
          ? List<AssistantContent>.from(sessionState.parts)
          : const [];
    } else {
      closedParts = const [];
    }

    final lastMessage = chat.messages.last;
    final targetMessageId =
        lastMessage.role == MessageRole.assistant && !lastMessage.isComplete
        ? lastMessage.id
        : closedParts.isEmpty
        ? null
        : closedParts.last.messageId;
    final messageParts = targetMessageId != null
        ? filterPartsByMessage(closedParts, targetMessageId)
        : closedParts;

    final content = messageParts
        .whereType<AssistantText>()
        .map((p) => p.text)
        .join();
    final reasoning = messageParts
        .whereType<AssistantReasoning>()
        .map((p) => p.text)
        .join();
    // Persist ALL parts (reasoning, tools, text) in their original order so
    // the completed message keeps separate reasoning blocks (pre-tool and
    // post-tool thoughts must not collapse into one merged block).
    final partsJson = messageParts.isNotEmpty
        ? assistantContentToPartMaps(messageParts)
        : null;

    Message completedMessage;
    List<Message> newMessages;

    if (lastMessage.role == MessageRole.assistant && !lastMessage.isComplete) {
      completedMessage = lastMessage.copyWith(
        content: content,
        reasoning: reasoning.isNotEmpty ? reasoning : null,
        isComplete: true,
        partsJson: partsJson,
        tokensCacheRead: null,
        tokensCacheWrite: null,
        tokensCacheIncludedInInput: null,
        contextLength: ref
            .read(modelProvider)
            .selectedModelObject
            ?.contextLength,
      );
      newMessages = [
        for (int i = 0; i < chat.messages.length - 1; i++) chat.messages[i],
        completedMessage,
      ];
    } else {
      completedMessage = createAssistantMessage(
        content: content,
        reasoning: reasoning.isNotEmpty ? reasoning : null,
        isComplete: true,
        partsJson: partsJson,
        tokensCacheRead: null,
        tokensCacheWrite: null,
        tokensCacheIncludedInInput: null,
        contextLength: ref
            .read(modelProvider)
            .selectedModelObject
            ?.contextLength,
        agent: lastMessage.agent ?? ref.read(currentAgentProvider).name,
      );
      newMessages = [...chat.messages, completedMessage];
    }

    final newChat = chat.copyWith(
      messages: newMessages,
      updatedAt: DateTime.now(),
    );
    ref.read(chatListProvider.notifier).updateChat(newChat);
    final sessionRepository = await ref.read(sessionRepositoryProvider.future);
    final completionSessionId = newChat.toSessionId();
    if (lastMessage.role == MessageRole.assistant && !lastMessage.isComplete) {
      await sessionRepository.appendEvent(
        MessageUpdated(
          sessionId: completionSessionId,
          messageId: completedMessage.id,
          content: completedMessage.content,
          reasoning: completedMessage.reasoning,
          model: completedMessage.model,
          error: completedMessage.isError ? completedMessage.content : null,
          timestamp: completedMessage.timestamp,
        ),
      );
    } else {
      await sessionRepository.appendEvent(
        MessageAdded(
          sessionId: completionSessionId,
          messageId: completedMessage.id,
          role: completedMessage.role.name,
          content: completedMessage.content,
          timestamp: completedMessage.timestamp,
        ),
      );
    }

    ref.read(chatScreenProvider.notifier).finalizeStreaming();
  }

  Future<void> refreshChatMessages({
    required BuildContext context,
    required bool Function() isMounted,
    required VoidCallback showWelcomeSuggestions,
  }) async {
    FocusScope.of(context).unfocus();
    if (_currentChat != null) {
      final updatedChat = await ref
          .read(chatListProvider.notifier)
          .ensureChatLoaded(_currentChat!.id, forceRefresh: true);
      if (updatedChat == null || !isMounted()) return;
      ref.read(chatScreenProvider.notifier).hideSuggestions();
      if (updatedChat.messages.isEmpty) {
        ref.read(chatScreenProvider.notifier).hideAllSuggestions();
        showWelcomeSuggestions();
      }
    }
  }

  // ── Session / stream orchestration ──────────────────────────────────

  Future<void> initiateStream({
    required Chat chat,
    required List<Map<String, dynamic>> messages,
    required bool isContinuation,
    String? delegateAgentId,
    String? agentMention,
    String? pendingAssistantMessageId,
    required BuildContext context,
    required ScrollController scrollController,
    required FocusNode chatInputFocusNode,
    required bool Function() isMounted,
    required VoidCallback scrollToBottom,
  }) async {
    LogTags.chatScreen.logInfo(
      '_initiateStream: enter model=$_selectedModelId isContinuation=$isContinuation',
    );
    final repo = await ref.read(sessionRepositoryProvider.future);
    LogTags.chatScreen.logInfo('_initiateStream: repo ready');
    final toolRegistry = await ref.read(toolRegistryProvider.future);
    LogTags.chatScreen.logInfo('_initiateStream: toolRegistry ready');

    String agentName = ref.read(currentAgentProvider).name;
    // For subagent mentions, keep the current agent (LLM will call task tool)
    if (delegateAgentId != null && agentMention == null) {
      final delegateAgent = AgentRegistry().get(delegateAgentId);
      if (delegateAgent != null) {
        agentName = delegateAgent.name;
      }
    }

    final eventBus = ref.read(sessionEventBusProvider);
    final sessionRunner = SessionRunner(repo, toolRegistry, eventBus: eventBus);
    final runnerSession = await sessionRunner.startInitializedSession(
      agent: agentName,
      modelRef: _selectedModelId,
      sessionId: _currentSessionId != null
          ? SessionID.fromString(_currentSessionId!)
          : null,
      // Reuse the assistant placeholder message id so `onChunk` streams into
      // the message already appended via MessageAdded — otherwise a second
      // assistant message with a fresh `msg_…` id is created and the chat
      // shows duplicate bubbles after reload.
      messageId: pendingAssistantMessageId,
    );
    LogTags.chatScreen.logInfo(
      '_initiateStream: session ready id=${runnerSession.sessionId.value}',
    );
    final isNewSession = _currentSessionId == null;
    _currentSessionId ??= runnerSession.sessionId.value;
    _sessionRunner = runnerSession;
    ref
        .read(currentSessionRunnerProvider.notifier)
        .set(sessionRunner, runnerSession.sessionId.value);
    pushSessionToStack(isNewSession: isNewSession);

    if (!isContinuation) {
      // The user message is already persisted via MessageAdded by the caller
      // (_handleSendMessage / _handleMessageEditAndSend / _regenerateResponse).
      // Calling publishUserMessage here would append a SECOND MessageAdded with
      // the same id, which the projector replays as a duplicate user bubble
      // after restart. This block existed when the UI appended only the
      // assistant placeholder; the user message must be added exactly once.
      LogTags.chatScreen.logDebug(
        '_initiateStream: user message already persisted, skipping publishUserMessage',
      );
    }

    try {
      final modelSettingsNotifier = ref.read(modelSettingsProvider.notifier);
      final settings = await modelSettingsNotifier.getSettings(
        _selectedModelId,
      );
      LogTags.chatScreen.logInfo('_initiateStream: settings ready');

      LogTags.chatScreen.logInfo(
        '_initiateStream: calling _handleStreamingResponse model=$_selectedModelId',
      );

      // Resolve delegate agent first (for both maxSteps and activeAgent)
      final delegateAgent = delegateAgentId != null
          ? AgentRegistry().get(delegateAgentId)
          : null;
      final activeAgent =
          delegateAgent?.name ?? ref.read(currentAgentProvider).name;

      // Get maxSteps from the effective agent
      final int maxSteps =
          delegateAgent?.maxSteps ??
          ref.read(currentAgentProvider).maxSteps ??
          unlimitedMaxSteps;

      // Resolve temperature: delegate agent > primary agent > model settings > 1.0
      final double temperature =
          delegateAgent?.temperature ??
          ref.read(currentAgentProvider).temperature ??
          settings.temperature;

      await handleStreamingResponse(
        chat: chat,
        messages: messages,
        isContinuation: isContinuation,
        modelId: _selectedModelId,
        modelSettings: settings,
        temperature: temperature,
        maxSteps: maxSteps,
        activeAgent: activeAgent,
        context: context,
        scrollController: scrollController,
        chatInputFocusNode: chatInputFocusNode,
        isMounted: isMounted,
        suggestionService: ContinuationSuggestionService(),
      );
    } catch (e, s) {
      LogTags.chatScreen.logError('_initiateStream: streaming error $e');
      ref.read(chatScreenProvider.notifier).setStreaming(false);
      try {
        await handleStreamingError(
          e,
          _currentSessionId ?? chat.id,
          context: context,
        );
      } catch (e2) {
        LogTags.chatService.logError(
          '_handleStreamingError threw after main exception',
          e2,
          s,
        );
      }
    } finally {
      runnerSession.dispose();
      if (_sessionRunner == runnerSession) {
        _sessionRunner = null;
      }
      ref.read(currentSessionRunnerProvider.notifier).clear();
      _currentSessionId = null;
    }
  }

  void pushSessionToStack({required bool isNewSession}) {
    if (_currentSessionId != null && isNewSession) {
      ref
          .read(sessionStackProvider.notifier)
          .push(SessionID.fromString(_currentSessionId!));
    }
  }

  // ── AI actions (regenerate / continue) ──────────────────────────────

  Future<void> regenerateResponse(
    String messageId, {
    required BuildContext context,
    required bool Function() isMounted,
    required VoidCallback showWelcomeSuggestions,
    required VoidCallback scrollToBottom,
    required ScrollController scrollController,
    required FocusNode chatInputFocusNode,
  }) async {
    final chat = _currentChat;
    if (chat == null || chat.messages.isEmpty) return;
    ref.read(chatScreenProvider.notifier).hideSuggestions();

    final messageIndex = chat.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    final targetMessage = chat.messages[messageIndex];
    if (targetMessage.role != MessageRole.assistant) return;

    int userMessageIndex = -1;
    for (int i = messageIndex - 1; i >= 0; i--) {
      if (chat.messages[i].role == MessageRole.user) {
        userMessageIndex = i;
        break;
      }
    }
    if (userMessageIndex == -1) return;

    final messagesToDelete = chat.messages
        .sublist(messageIndex)
        .map((m) => m.id)
        .toList();
    final sessionRepository = await ref.read(sessionRepositoryProvider.future);
    final sessionId = chat.toSessionId();
    for (final msgId in messagesToDelete) {
      await sessionRepository.appendEvent(
        MessageDeleted(
          sessionId: sessionId,
          messageId: msgId,
          timestamp: DateTime.now(),
        ),
      );
    }

    final chatAfterDelete = chat.copyWith(
      messages: chat.messages.sublist(0, messageIndex),
      updatedAt: DateTime.now(),
    );

    // Auto-generate session title from the first user message when the chat
    // still carries the localized default title.
    if (isMounted()) {
      if (chatAfterDelete.isDefaultTitle) {
        await autoGenerateTitleIfNeeded(chatAfterDelete);
      }
    }

    // Appends the assistant placeholder and streams the regenerated response
    // into the same session as the deleted messages (no duplicate session).
    await startAssistantTurn(
      chat: chatAfterDelete,
      sessionId: sessionId.value,
      agentName: ref.read(currentAgentProvider).name,
      buildMessages: (withPlaceholder) =>
          const ChatContextBuilder().buildApiMessages(
            withPlaceholder,
            currentAgent: ref.read(currentAgentProvider),
            modelSettings: ref.read(modelSettingsProvider).activeSettings,
            instructionBlocks:
                ref.read(resolvedInstructionsProvider).value ?? const [],
          ),
      context: context,
      scrollController: scrollController,
      chatInputFocusNode: chatInputFocusNode,
      isMounted: isMounted,
      scrollToBottom: scrollToBottom,
    );
  }

  Future<void> continueAIResponse(
    String lastMessageId, {
    required BuildContext context,
    required bool Function() isMounted,
    required VoidCallback showWelcomeSuggestions,
    required VoidCallback scrollToBottom,
    required ScrollController scrollController,
    required FocusNode chatInputFocusNode,
  }) async {
    if (_currentChat == null) return;
    ref.read(chatScreenProvider.notifier).hideSuggestions();

    final lastMessage = _currentChat!.messages.lastWhere(
      (msg) => msg.role == MessageRole.assistant && msg.id == lastMessageId,
      orElse: () => _currentChat!.messages.first,
    );
    if (lastMessage.content.isEmpty) return;

    final sessionId = _currentChat!.toSessionId();

    // Auto-generate session title from the first user message when the chat
    // still carries the localized default title.
    if (isMounted()) {
      final chatToCheck = _currentChat;
      if (chatToCheck != null && chatToCheck.isDefaultTitle) {
        unawaited(autoGenerateTitleIfNeeded(chatToCheck));
      }
    }

    final chatFromStorage = _currentChat;
    if (chatFromStorage == null) return;

    // Appends the continuation placeholder and streams into it, reusing the
    // placeholder id so no second assistant message is created on reload.
    await startAssistantTurn(
      chat: chatFromStorage,
      sessionId: sessionId.value,
      agentName: ref.read(currentAgentProvider).name,
      isContinuation: true,
      buildMessages: (withPlaceholder) {
        final continuationPrompt = const ChatContextBuilder().buildApiMessages(
          withPlaceholder,
          currentAgent: ref.read(currentAgentProvider),
          modelSettings: ref.read(modelSettingsProvider).activeSettings,
          instructionBlocks:
              ref.read(resolvedInstructionsProvider).value ?? const [],
        );
        // Replace last assistant content with continue instruction
        if (continuationPrompt.isNotEmpty) {
          continuationPrompt[continuationPrompt.length - 1] = {
            'role': 'user',
            'content': 'Please continue your previous response.',
          };
        } else {
          continuationPrompt.addAll([
            {
              'role': 'user',
              'content': 'Please continue your previous response.',
            },
            {'role': 'assistant', 'content': lastMessage.content},
            {'role': 'user', 'content': 'Continue from where you left off.'},
          ]);
        }
        return continuationPrompt;
      },
      context: context,
      scrollController: scrollController,
      chatInputFocusNode: chatInputFocusNode,
      isMounted: isMounted,
      scrollToBottom: scrollToBottom,
    );
  }

  // ── Message edits ───────────────────────────────────────────────────

  Future<void> handleMessageEdited(
    String messageId,
    String newContent, {
    required BuildContext context,
    required bool Function() isMounted,
    required VoidCallback showWelcomeSuggestions,
  }) async {
    if (_currentChat == null) return;

    // If streaming is in progress, cancel it so the edit is not later
    // overwritten by the stream's completion.
    if (_sessionRunner != null || ref.read(chatScreenProvider).isStreaming) {
      _streamCancelled = true;
      ref.read(chatAiServiceProvider).cancelAllRequests();
      ref.read(permissionServiceProvider).cancelAllPendingRequests();
      ref.read(currentSessionRunnerProvider.notifier).cancelAllChildren();
      _sessionRunner = null;
      ref.read(chatScreenProvider.notifier).finalizeStreaming();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      _streamCancelled = false;
    }

    final messages = _currentChat!.messages;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final editedMessage = messages[messageIndex].copyWith(content: newContent);
    final sessionRepository = await ref.read(sessionRepositoryProvider.future);
    final sessionId = _currentChat!.toSessionId();
    await sessionRepository.appendEvent(
      MessageUpdated(
        sessionId: sessionId,
        messageId: messageId,
        content: editedMessage.content,
        reasoning: editedMessage.reasoning,
        model: editedMessage.model,
        error: editedMessage.isError ? editedMessage.content : null,
        timestamp: editedMessage.timestamp,
      ),
    );
    final updatedMessages = List<Message>.from(messages)
      ..[messageIndex] = editedMessage;
    final updatedChat = _currentChat!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
    ref.read(chatListProvider.notifier).updateChat(updatedChat);

    if (!isMounted()) return;
    final localizations = AppLocalizations.of(context)!;
    SnackbarUtils.showSuccessSnackBar(
      context: context,
      message: localizations.messageEditedSuccessfully,
      icon: Icons.edit,
    );
  }

  Future<void> handleMessageEditAndSend(
    String messageId,
    String newContent, {
    required BuildContext context,
    required bool Function() isMounted,
    required VoidCallback showWelcomeSuggestions,
    required VoidCallback scrollToBottom,
    required ScrollController scrollController,
    required FocusNode chatInputFocusNode,
  }) async {
    if (_currentChat == null) return;
    ref.read(chatScreenProvider.notifier).hideSuggestions();

    // Cancel any in-progress streaming before starting a new turn.
    if (_sessionRunner != null || ref.read(chatScreenProvider).isStreaming) {
      _streamCancelled = true;
      ref.read(chatAiServiceProvider).cancelAllRequests();
      ref.read(permissionServiceProvider).cancelAllPendingRequests();
      ref.read(currentSessionRunnerProvider.notifier).cancelAllChildren();
      _sessionRunner = null;
      ref.read(chatScreenProvider.notifier).finalizeStreaming();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      _streamCancelled = false;
    }

    final messages = _currentChat!.messages;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final editedUserMessage = messages[messageIndex].copyWith(
      content: newContent,
    );
    final sessionRepository = await ref.read(sessionRepositoryProvider.future);
    final sessionId = _currentChat!.toSessionId();
    await sessionRepository.appendEvent(
      MessageUpdated(
        sessionId: sessionId,
        messageId: messageId,
        content: editedUserMessage.content,
        reasoning: editedUserMessage.reasoning,
        model: editedUserMessage.model,
        error: editedUserMessage.isError ? editedUserMessage.content : null,
        timestamp: editedUserMessage.timestamp,
      ),
    );

    for (int i = messages.length - 1; i > messageIndex; i--) {
      await sessionRepository.appendEvent(
        MessageDeleted(
          sessionId: sessionId,
          messageId: messages[i].id,
          timestamp: DateTime.now(),
        ),
      );
    }

    final messagesBeforeEdit = messages.sublist(0, messageIndex + 1);
    messagesBeforeEdit[messageIndex] = editedUserMessage;
    final updatedChat = _currentChat!.copyWith(
      messages: messagesBeforeEdit,
      updatedAt: DateTime.now(),
    );

    // Appends the assistant placeholder, updates the chat list and streams
    // into that exact message id (no duplicate bubbles on reload).
    await startAssistantTurn(
      chat: updatedChat,
      sessionId: sessionId.value,
      agentName: ref.read(currentAgentProvider).name,
      buildMessages: (withPlaceholder) =>
          const ChatContextBuilder().buildApiMessages(
            withPlaceholder,
            currentAgent: ref.read(currentAgentProvider),
            modelSettings: ref.read(modelSettingsProvider).activeSettings,
            instructionBlocks:
                ref.read(resolvedInstructionsProvider).value ?? const [],
          ),
      context: context,
      scrollController: scrollController,
      chatInputFocusNode: chatInputFocusNode,
      isMounted: isMounted,
      scrollToBottom: scrollToBottom,
    );

    if (!isMounted()) return;
    final localizations = AppLocalizations.of(context)!;
    SnackbarUtils.showSuccessSnackBar(
      context: context,
      message: localizations.messageEditedAndResponseRegenerated,
      icon: Icons.refresh,
    );
  }

  // ── Chat management ─────────────────────────────────────────────────

  Future<void> createNewChat({
    required VoidCallback showWelcomeSuggestions,
  }) async {
    final newChat = await ref.read(chatListProvider.notifier).createNewChat();
    ref.read(currentChatIdProvider.notifier).setChatId(newChat.id);
    ref.read(permissionServiceProvider).clearSession();
    showWelcomeSuggestions();
  }

  Future<void> selectChat(
    String chatId, {
    required bool Function() isMounted,
    required VoidCallback showWelcomeSuggestions,
    required VoidCallback scrollToBottom,
  }) async {
    _pendingSelectChatId = chatId;
    final chat = await ref
        .read(chatListProvider.notifier)
        .ensureChatLoaded(chatId);
    if (chat == null || !isMounted() || _pendingSelectChatId != chatId) {
      _pendingSelectChatId = null;
      return;
    }
    _pendingSelectChatId = null;
    ref.read(currentChatIdProvider.notifier).setChatId(chatId);
    if (chat.isDefaultTitle && chat.messages.isEmpty) {
      showWelcomeSuggestions();
    } else {
      ref.read(chatScreenProvider.notifier).hideAllSuggestions();
    }
    scrollToBottom();
  }

  Future<void> deleteChat(
    String chatId, {
    required BuildContext context,
    required bool Function() isMounted,
    required VoidCallback showWelcomeSuggestions,
  }) async {
    final chatListAsync = ref.read(chatListProvider);
    final chat = chatListAsync.whenOrNull(
      data: (chats) => chats.firstWhere((c) => c.id == chatId),
    );
    if (chat == null) return;

    final localizations = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => KeyboardHandlerDialog(
        onEnter: () => Navigator.pop(dialogContext, true),
        onEscape: () => Navigator.pop(dialogContext, false),
        child: AlertDialog(
          title: Text(localizations.deleteChat),
          content: Text(localizations.confirmDeleteMessage(chat.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                localizations.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete == true) {
      final wasCurrentChat = _currentChat != null && _currentChat!.id == chatId;
      await ref.read(chatListProvider.notifier).deleteChat(chatId);
      if (wasCurrentChat && isMounted()) {
        ref.read(currentChatIdProvider.notifier).setChatId(null);
        showWelcomeSuggestions();
      }
    }
  }

  // ── Streaming response ──────────────────────────────────────────────

  Future<void> handleStreamingResponse({
    required Chat chat,
    required List<Map<String, dynamic>> messages,
    required bool isContinuation,
    required String modelId,
    required ModelSettings modelSettings,
    required double temperature,
    required String? activeAgent,
    int maxSteps = 5,
    required BuildContext context,
    required ScrollController scrollController,
    required FocusNode chatInputFocusNode,
    required bool Function() isMounted,
    required ContinuationSuggestionService suggestionService,
  }) async {
    LogTags.chatScreen.logInfo(
      '_handleStreamingResponse START: chatId=${chat.id}, model=$modelId, isContinuation=$isContinuation',
    );
    _streamCancelled = false;
    final sessionId = _sessionRunner?.sessionId.value ?? chat.id;
    final notifier = ref.read(chatScreenProvider.notifier);
    notifier.startStreaming(sessionId);

    final toolInputs = <String, Map<String, dynamic>>{};
    final toolStartTimes = <String, DateTime>{};
    final fullContent = StringBuffer();
    final questionPartIds = <String, String>{};
    String? lastAddedQuestionText;
    DateTime? lastAddedQuestionTime;
    const questionDebounceMs = 500;

    final toolRegistry = await ref.read(toolRegistryProvider.future);
    if (_streamCancelled) return;
    final aiService = ref.read(chatAiServiceProvider);
    final attemptMsgs = aiService.sanitizeMessages(messages);
    int? latestTokensInput;
    int? latestTokensOutput;
    int? latestTokensReasoning;
    int? latestTokensCacheRead;
    int? latestTokensCacheWrite;
    bool? latestTokensCacheIncludedInInput;
    final modelContextLength = ref
        .read(modelProvider)
        .selectedModelObject
        ?.contextLength;

    final runnerSession = _sessionRunner;
    if (runnerSession == null) {
      throw StateError(
        'SessionRunner not initialized — call _initiateStream first',
      );
    }

    final holder = ref.read(currentSessionRunnerProvider.notifier);
    holder.onTaskStart = (taskPartId, desc, agent) {
      final event = TaskPartStarted(
        sessionId: SessionID.fromString(sessionId),
        partId: taskPartId,
        description: desc,
        agent: agent,
        timestamp: DateTime.now(),
      );
      unawaited(runnerSession.repository.appendEvent(event));
      runnerSession.eventBus?.emit(event);
    };
    holder.onTaskEnd = (taskPartId) {
      final event = TaskPartCompleted(
        sessionId: SessionID.fromString(sessionId),
        partId: taskPartId,
        toolCallsCount: 0,
        timestamp: DateTime.now(),
      );
      unawaited(runnerSession.repository.appendEvent(event));
      runnerSession.eventBus?.emit(event);
    };
    holder.onChildToolEvent = (childSessionId, toolName, title) {
      final taskPartId = holder.childToTaskPart[childSessionId];
      if (taskPartId != null) {
        final sessionAsyncState = ref.read(sessionPartsProvider(sessionId));
        final sessionState = sessionAsyncState.value;
        final taskIdx = sessionState?.parts.indexWhere(
          (p) => p is AssistantTask && p.id == taskPartId,
        );
        if (taskIdx != null && taskIdx >= 0 && sessionState != null) {
          final parts = List<AssistantContent>.from(sessionState.parts);
          final task = parts[taskIdx] as AssistantTask;
          final isDelegatedTask = toolName == 'task';
          parts[taskIdx] = task.copyWith(
            currentTool: isDelegatedTask ? task.currentTool : toolName,
            currentToolTitle: isDelegatedTask ? task.currentToolTitle : title,
            toolCallsCount: task.toolCallsCount + 1,
          );
          final event = MessageUpdated(
            sessionId: SessionID.fromString(sessionId),
            messageId: task.messageId ?? '',
            content: null,
            reasoning: null,
            model: null,
            error: null,
            timestamp: DateTime.now(),
          );
          unawaited(runnerSession.repository.appendEvent(event));
          runnerSession.eventBus?.emit(event);
        }
      }
    };

    final estimatedTokens = aiService.estimatePromptTokens(attemptMsgs);
    final projectedTotal = estimatedTokens;
    final compactionConfig = ref.watch(compactionConfigProvider);
    if (compactionConfig.auto &&
        projectedTotal >= aiService.overflowDetector.usable &&
        attemptMsgs.length > 4) {
      LogTags.chatScreen.logInfo(
        'Pre-send compaction triggered for $sessionId',
      );
      // Capture the ephemeral system prompt chain (agent prompt, user system
      // prompt, project instructions) injected by `_buildApiMessages` so it
      // can be re-applied after compaction — system prompts are passed
      // separately from conversation messages and are never consumed by
      // compaction.
      final compactedApiMessages = await applyCompaction(attemptMsgs, chat);
      if (_streamCancelled) return;
      // _applyCompaction returns the original list when no compaction occurs,
      // so identity check here is sufficient to detect a real compaction.
      if (compactedApiMessages != attemptMsgs) {
        attemptMsgs
          ..clear()
          ..addAll(compactedApiMessages);
        // Compaction strips the ephemeral system prompt chain (agent prompt,
        // user system prompt, project instructions). Re-inject it at the head
        // of the context, mirroring how `_buildApiMessages` assembles the
        // system chain per API call. System prompts are never persisted in the
        // compacted history and must be re-applied on every model request.
        final currentAgent = ref.read(currentAgentProvider);
        final settings = ref.read(modelSettingsProvider).activeSettings;
        final instructionBlocks =
            ref.read(resolvedInstructionsProvider).value ?? const [];
        final systemChain = const ChatContextBuilder().buildSystemChain(
          agent: currentAgent,
          userSystemPrompt: settings?.systemPrompt,
          instructionBlocks: instructionBlocks,
        );
        for (final sys in systemChain) {
          attemptMsgs.insert(0, sys);
        }
      }
    }
    try {
      if (modelContextLength != null) {
        aiService.updateModelContextLength(
          modelContextLength,
          compactionBuffer: compactionConfig.buffer,
        );
      }
      await aiService.streamChatCompletion(
        messages: attemptMsgs,
        model: modelId,
        temperature: temperature,
        sessionId: sessionId,
        tools: toolRegistry.toSDKTools(),
        onRetry: (info) {
          final partialText = fullContent.toString();
          if (partialText.isNotEmpty) {
            if (attemptMsgs.isNotEmpty &&
                attemptMsgs.last['role'] == 'assistant') {
              attemptMsgs.removeLast();
            }
            attemptMsgs.add({'role': 'assistant', 'content': partialText});
          }
          notifier.setRetryInfo(
            isRetrying: true,
            retryMessage: info.message,
            retryAttempt: info.attempt,
          );
        },
        onUsage:
            (
              input,
              output,
              cacheRead,
              cacheWrite,
              reasoning,
              cacheIncludedInInput,
            ) {
              latestTokensInput = input;
              latestTokensOutput = output;
              latestTokensCacheRead = cacheRead;
              latestTokensCacheWrite = cacheWrite;
              latestTokensReasoning = reasoning;
              latestTokensCacheIncludedInInput = cacheIncludedInInput;
            },
        onToolStart: (toolCallId, toolName, input) async {
          toolInputs[toolCallId] = input;
          toolStartTimes[toolCallId] = DateTime.now();

          if (toolName == 'question') {
            final questionText = input['question'] as String? ?? '';

            final now = DateTime.now();
            final isDuplicate =
                lastAddedQuestionText == questionText &&
                lastAddedQuestionTime != null &&
                now.difference(lastAddedQuestionTime!).inMilliseconds <
                    questionDebounceMs;

            if (!isDuplicate) {
              lastAddedQuestionText = questionText;
              lastAddedQuestionTime = now;
              final options =
                  (input['options'] as List?)
                      ?.map(QuestionOption.fromJson)
                      .toList() ??
                  const [];
              final multiple = input['multiple'] as bool? ?? false;
              final qPartId = 'question_${now.microsecondsSinceEpoch}';
              final event = QuestionPartStarted(
                sessionId: SessionID.fromString(sessionId),
                partId: qPartId,
                questionText: questionText,
                options: options,
                multiple: multiple,
                timestamp: now,
              );
              unawaited(runnerSession.repository.appendEvent(event));
              runnerSession.eventBus?.emit(event);
              questionPartIds[toolCallId] = qPartId;
              LogTags.chatScreen.logInfo(
                'onToolStart(question): emitted QuestionPartStarted "$questionText"',
              );
            }
          }

          unawaited(runnerSession.onToolStart(toolCallId, toolName, input));
        },
        onToolEnd: (toolCallId, toolName, result) async {
          final resultStr = result.toString();

          if (toolName == 'question') {
            final partId = questionPartIds.remove(toolCallId);
            if (partId != null) {
              final answerEvent = QuestionPartAnswered(
                sessionId: SessionID.fromString(sessionId),
                partId: partId,
                answer: resultStr,
                timestamp: DateTime.now(),
              );
              unawaited(runnerSession.repository.appendEvent(answerEvent));
              runnerSession.eventBus?.emit(answerEvent);
            }
            LogTags.chatScreen.logInfo(
              'onToolEnd(question): answer="$resultStr"',
            );
          }

          final startTime = toolStartTimes.remove(toolCallId);
          final durationMs = startTime != null
              ? DateTime.now().difference(startTime).inMilliseconds
              : 0;

          unawaited(
            runnerSession.onToolEnd(
              toolCallId,
              toolName,
              resultStr,
              durationMs: durationMs,
              input: toolInputs.remove(toolCallId),
            ),
          );
        },
        onToolError: (toolCallId, toolName, error) async {
          final errorStr = error.toString();

          if (toolName == 'document_extract' && isMounted()) {
            final displayMsg = errorStr.length > 120
                ? '${errorStr.substring(0, 120)}…'
                : errorStr;
            SnackbarUtils.showErrorSnackBar(
              context: context,
              message: 'document_extract: $displayMsg',
              icon: Icons.description,
              duration: const Duration(seconds: 6),
            );
          }

          final startTime = toolStartTimes.remove(toolCallId);
          final durationMs = startTime != null
              ? DateTime.now().difference(startTime).inMilliseconds
              : 0;

          unawaited(
            runnerSession.onToolError(
              toolCallId,
              toolName,
              errorStr,
              durationMs: durationMs,
              input: toolInputs.remove(toolCallId),
            ),
          );
        },
        onChunk: (content) async {
          if (content.isEmpty) return;
          fullContent.write(content);
          await runnerSession.onChunk(content);
        },
        onReasoning: (reasoning) async {
          if (reasoning.isEmpty) return;
          await runnerSession.onReasoning(reasoning);
        },
        onReasoningEnd: () => runnerSession.onReasoningEnd(),
        maxSteps: maxSteps,
        onCompletion: (sdkText) async {
          if (!isMounted() || _streamCancelled) return;
          final currentSessionId = ref
              .read(chatScreenProvider)
              .streamingSessionId;
          if (currentSessionId != null && currentSessionId != sessionId) {
            return;
          }
          notifier.setRetryInfo(
            isRetrying: false,
            retryMessage: null,
            retryAttempt: 0,
          );

          final streamedChat =
              ref
                  .read(chatListProvider)
                  .whenOrNull(
                    data: (chats) =>
                        chats.where((c) => c.id == sessionId).firstOrNull,
                  ) ??
              chat;

          // Close open parts via the runner session and get the final
          // SessionState with all parts.  This avoids a race with the
          // async sessionPartsProvider stream.
          final finalState = await runnerSession.onCompletion(
            content: sdkText,
            model: modelId,
            tokensInput: latestTokensInput ?? 0,
            tokensOutput: latestTokensOutput ?? 0,
            tokensReasoning: latestTokensReasoning ?? 0,
            tokensCacheRead: latestTokensCacheRead ?? 0,
            tokensCacheWrite: latestTokensCacheWrite ?? 0,
          );
          // Only keep parts belonging to the current message — every part
          // (AssistantText, AssistantTool, etc.) carries a messageId, but the
          // session state accumulates parts across ALL messages. Without this
          // filter the completed message would inherit old tool calls/results
          // and concatenate previous text, making it look like the response
          // was duplicated.
          final currentMsgId = runnerSession.messageId;
          final closedParts = currentMsgId != null
              ? finalState.parts
                    .where((p) => p.messageId == currentMsgId)
                    .toList()
              : finalState.parts;

          final textBuffer = StringBuffer();
          final reasoningBuffer = StringBuffer();
          for (final part in closedParts) {
            if (part is AssistantText) {
              textBuffer.write(part.text);
            } else if (part is AssistantReasoning) {
              reasoningBuffer.write(part.text);
            }
          }
          final content = textBuffer.toString().isNotEmpty
              ? textBuffer.toString()
              : (sdkText.isNotEmpty ? sdkText : reasoningBuffer.toString());
          final reasoningRaw = reasoningBuffer.toString();
          final reasoning = reasoningRaw.trim().isNotEmpty
              ? reasoningRaw
              : null;

          if (content.isEmpty && reasoningRaw.isNotEmpty) {
            LogTags.chatScreen.logWarning(
              'onCompletion: model returned zero text parts, using reasoning as content fallback (len=${reasoningRaw.length})',
            );
          } else if (content.isEmpty) {
            LogTags.chatScreen.logWarning(
              'onCompletion: model returned zero text and zero reasoning parts (sdkText empty)',
            );
          }

          LogTags.chatScreen.logDebug(
            'onCompletion: extracted contentLen=${content.length}, reasoningLen=${reasoning?.length ?? 0} raw=${reasoningRaw.length}',
          );

          final lastIsIncomplete =
              streamedChat.messages.isNotEmpty &&
              streamedChat.messages.last.role == MessageRole.assistant &&
              !streamedChat.messages.last.isComplete;

          final partsJson = closedParts.isNotEmpty
              ? assistantContentToPartMaps(closedParts)
              : null;

          Message completedMessage;
          List<Message> newMessages;
          if (lastIsIncomplete) {
            final lastMsg = streamedChat.messages.last;
            completedMessage = lastMsg.copyWith(
              content: content,
              reasoning: reasoning,
              isComplete: true,
              partsJson: partsJson,
              tokensInput: latestTokensInput,
              tokensOutput: latestTokensOutput,
              tokensReasoning: latestTokensReasoning,
              tokensCacheRead: latestTokensCacheRead,
              tokensCacheWrite: latestTokensCacheWrite,
              tokensCacheIncludedInInput: latestTokensCacheIncludedInInput,
              contextLength: modelContextLength ?? lastMsg.contextLength,
            );
            newMessages = [
              for (int i = 0; i < streamedChat.messages.length - 1; i++)
                streamedChat.messages[i],
              completedMessage,
            ];
          } else {
            completedMessage = createAssistantMessage(
              content: content,
              reasoning: reasoning,
              isComplete: true,
              partsJson: partsJson,
              tokensInput: latestTokensInput,
              tokensOutput: latestTokensOutput,
              tokensReasoning: latestTokensReasoning,
              tokensCacheRead: latestTokensCacheRead,
              tokensCacheWrite: latestTokensCacheWrite,
              tokensCacheIncludedInInput: latestTokensCacheIncludedInInput,
              contextLength: modelContextLength,
              agent: activeAgent,
            );
            newMessages = [...streamedChat.messages, completedMessage];
          }
          final newChat = streamedChat.copyWith(
            messages: newMessages,
            updatedAt: DateTime.now(),
          );
          LogTags.chatScreen.logInfo(
            'onCompletion: saving message id=${completedMessage.id}, partsCount=${closedParts.length}',
          );
          notifier.finalizeStreaming();
          ref.read(chatListProvider.notifier).updateChat(newChat);
          final streamSessionRepository = await ref.read(
            sessionRepositoryProvider.future,
          );
          final streamCompletionSessionId = newChat.toSessionId();
          await streamSessionRepository.appendEvent(
            MessageUpdated(
              sessionId: streamCompletionSessionId,
              messageId: completedMessage.id,
              content: completedMessage.content,
              reasoning: completedMessage.reasoning,
              model: completedMessage.model,
              error: completedMessage.isError ? completedMessage.content : null,
              timestamp: completedMessage.timestamp,
            ),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            chatInputFocusNode.unfocus();
          });
          await showContinuationSuggestions(
            completedMessage,
            context: context,
            isMounted: isMounted,
            suggestionService: suggestionService,
          );
        },
      );
    } catch (e) {
      if (_streamCancelled) return;
      notifier.finalizeStreaming();
      notifier.setRetryInfo(
        isRetrying: false,
        retryMessage: null,
        retryAttempt: 0,
      );
      if (_streamCancelled) return;
      unawaited(runnerSession.onError(e));
      await handleStreamingError(e, sessionId, context: context);
    } finally {
      toolInputs.clear();
      toolStartTimes.clear();
    }
  }

  Future<void> handleStreamingError(
    Object error,
    String sessionId, {
    required BuildContext context,
  }) async {
    if (_streamCancelled) return;
    LogTags.chatScreen.logError(
      '_handleStreamingError: type=${error.runtimeType} error=$error',
    );
    final errorMessage = ChatErrorUtils.formatError(error);
    final errorPrefix = '⚠️ $errorMessage';
    final streamedChat =
        ref
            .read(chatListProvider)
            .whenOrNull(
              data: (chats) =>
                  chats.where((c) => c.id == sessionId).firstOrNull,
            ) ??
        _currentChat;
    final chat = streamedChat;
    if (chat != null && chat.messages.isNotEmpty) {
      final lastMessage = chat.messages.last;
      if (lastMessage.role == MessageRole.assistant) {
        final partial = lastMessage.content.isEmpty
            ? errorPrefix
            : '${lastMessage.content}\n\n$errorPrefix';
        final errorResponseMessage = lastMessage.copyWith(
          content: partial,
          isComplete: true,
          isError: true,
        );
        final sessionRepository = await ref.read(
          sessionRepositoryProvider.future,
        );
        final sessionId = chat.toSessionId();
        await sessionRepository.appendEvent(
          MessageUpdated(
            sessionId: sessionId,
            messageId: errorResponseMessage.id,
            content: errorResponseMessage.content,
            reasoning: errorResponseMessage.reasoning,
            model: errorResponseMessage.model,
            error: errorResponseMessage.isError
                ? errorResponseMessage.content
                : null,
            timestamp: errorResponseMessage.timestamp,
          ),
        );
        final newMessages = [
          ...chat.messages.take(chat.messages.length - 1),
          errorResponseMessage,
        ];
        ref
            .read(chatListProvider.notifier)
            .updateChat(
              chat.copyWith(messages: newMessages, updatedAt: DateTime.now()),
            );
      }
    }
  }

  // ── Compaction ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> applyCompaction(
    List<Map<String, dynamic>> apiMessages,
    Chat chat,
  ) async {
    final modelId = _selectedModelId;
    if (modelId.isEmpty) return apiMessages;
    final compactionConfig = ref.read(compactionConfigProvider);
    final compactionService = CompactionService.fromConfig(compactionConfig);
    final aiService = ref.read(chatAiServiceProvider);
    final compacted = await compactionService.compact(
      messages: apiMessages,
      aiService: aiService,
      model: modelId,
    );
    if (compacted.isEmpty) return apiMessages;
    final repo = await ref.read(sessionRepositoryProvider.future);
    final orchestrator = CompactionOrchestrator(
      repo,
      completionProvider: aiService,
    );
    final updatedState = await orchestrator.compactSessionFromResult(
      SessionID.fromString(chat.id),
      compacted,
      model: modelId,
    );
    if (updatedState != null) {
      final canonicalChat = sessionStateToChat(updatedState);
      ref.read(chatListProvider.notifier).updateChat(canonicalChat);
      // `compactedContext` is tail-only (summary lives in `messages`). Re-inject
      // the single summary from `chat.messages` so the model context is
      // `[summary, ...tail]` without duplicating the summary.
      return const ChatContextBuilder().compactedApiMessagesWithSummary(
        chat,
        canonicalChat,
      );
    }
    final updatedMessages = compacted.map((m) {
      final roleName = m['role'] as String? ?? 'system';
      final content = m['content'] as String? ?? '';
      return Message(
        role: MessageRole.values.firstWhere(
          (r) => r.name == roleName,
          orElse: () => MessageRole.system,
        ),
        content: content,
        timestamp: DateTime.now(),
        isComplete: true,
        agent: m['agent'] as String?,
        isCompactionSummary: m['isCompactionSummary'] == true,
      );
    }).toList();
    final updatedChat = chat.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
    ref.read(chatListProvider.notifier).updateChat(updatedChat);
    return compacted;
  }

  Future<void> runCompaction(Chat chat) async {
    final apiMessages = const ChatContextBuilder().buildApiMessages(
      chat,
      currentAgent: ref.read(currentAgentProvider),
      modelSettings: ref.read(modelSettingsProvider).activeSettings,
      instructionBlocks:
          ref.read(resolvedInstructionsProvider).value ?? const [],
    );
    await applyCompaction(apiMessages, chat);
  }

  // ── Private helpers ─────────────────────────────────────────────────

  Future<void> showContinuationSuggestions(
    Message message, {
    required BuildContext context,
    required bool Function() isMounted,
    required ContinuationSuggestionService suggestionService,
  }) async {
    final theme = ref.read(themeProvider);
    if (!theme.showContinuationSuggestions) return;
    await suggestionService.showSuggestions(
      ref: ref,
      context: context,
      messageContent: message.content,
      selectedModelId: _selectedModelId,
      mounted: isMounted(),
    );
  }

  // ── Start assistant turn ────────────────────────────────────────────

  Future<Chat> startAssistantTurn({
    required Chat chat,
    required String sessionId,
    required String agentName,
    String? delegateAgentId,
    String? agentMention,
    bool isContinuation = false,
    required List<Map<String, dynamic>> Function(Chat withPlaceholder)
    buildMessages,
    required BuildContext context,
    required ScrollController scrollController,
    required FocusNode chatInputFocusNode,
    required bool Function() isMounted,
    required VoidCallback scrollToBottom,
  }) async {
    final assistantMessage = createAssistantMessage(agent: agentName);
    final chatWithPlaceholder = chat.copyWith(
      messages: [...chat.messages, assistantMessage],
      updatedAt: DateTime.now(),
    );
    final sessionRepository = await ref.read(sessionRepositoryProvider.future);
    await sessionRepository.appendEvent(
      MessageAdded(
        sessionId: SessionID.fromString(sessionId),
        messageId: assistantMessage.id,
        role: assistantMessage.role.name,
        content: assistantMessage.content,
        timestamp: assistantMessage.timestamp,
      ),
    );
    ref.read(chatListProvider.notifier).updateChat(chatWithPlaceholder);
    // One-shot, always-on scroll: starting a turn (send / retry / continue /
    // edit-and-send) brings the user back to the live tail no matter where in
    // the history they were reading. This is intentionally independent from
    // the streaming-follow setting, which only governs per-chunk following.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted()) return;
      scrollToBottom();
    });
    // Prevent _initiateStream from creating a duplicate session.
    _currentSessionId = sessionId;
    await initiateStream(
      chat: chatWithPlaceholder,
      messages: buildMessages(chatWithPlaceholder),
      isContinuation: isContinuation,
      delegateAgentId: delegateAgentId,
      agentMention: agentMention,
      pendingAssistantMessageId: assistantMessage.id,
      context: context,
      scrollController: scrollController,
      chatInputFocusNode: chatInputFocusNode,
      isMounted: isMounted,
      scrollToBottom: scrollToBottom,
    );
    return chatWithPlaceholder;
  }

  // ── Title generation ────────────────────────────────────────────────

  Future<void> autoGenerateTitleIfNeeded(Chat chat) async {
    if (!chat.isDefaultTitle) return;
    final userMessage = chat.messages
        .where((m) => m.role == MessageRole.user)
        .firstOrNull;
    if (userMessage == null || userMessage.content.trim().isEmpty) return;
    try {
      final aiService = ref.read(chatAiServiceProvider);
      final generatedTitle = await aiService.generateSessionTitle(
        modelId: _selectedModelId,
        userMessage: userMessage.content,
      );
      if (generatedTitle.isNotEmpty) {
        await ref
            .read(chatListProvider.notifier)
            .renameChat(chat.id, generatedTitle);
        ref.read(currentChatIdProvider.notifier).setChatId(chat.id);
      }
    } catch (e, st) {
      LogTags.chatScreen.logWarning('Title generation failed', e, st);
    }
  }
}
