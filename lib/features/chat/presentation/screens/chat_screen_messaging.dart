part of 'chat_screen.dart';

extension _ChatScreenMessagingExt on _ChatScreenState {
  Future<List<Map<String, dynamic>>> _applyCompaction(
    List<Map<String, dynamic>> apiMessages,
    Chat chat,
  ) async {
    final modelId = ref.read(modelProvider).selectedModelId;
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
    final repo = await _sessionRepositoryFuture;
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
      return _compactedApiMessagesWithSummary(chat, canonicalChat);
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
    final apiMessages = _buildApiMessages(chat);
    await _applyCompaction(apiMessages, chat);
  }

  /// Builds unified system message chain from agent prompt + user system prompt.
  /// Returns empty list if no prompts, otherwise single system message.
  List<Map<String, dynamic>> _buildSystemChain({
    required AgentDefinition agent,
    String? userSystemPrompt,
    String? delegateAgentId,
    List<String> instructionBlocks = const [],
  }) {
    final prompts = <String>[];

    // 1. Agent prompt (only for primary agents, and only if explicitly set)
    if (delegateAgentId != null) {
      final delegateAgent = AgentRegistry().get(delegateAgentId);
      if (delegateAgent != null &&
          delegateAgent.mode == AgentMode.primary &&
          delegateAgent.systemPrompt != null &&
          delegateAgent.systemPrompt!.isNotEmpty) {
        prompts.add(delegateAgent.systemPrompt!);
      }
    } else if (agent.mode == AgentMode.primary &&
        agent.systemPrompt != null &&
        agent.systemPrompt!.isNotEmpty) {
      prompts.add(agent.systemPrompt!);
    }

    // 2. User's system prompt (always added if present)
    if (userSystemPrompt != null && userSystemPrompt.isNotEmpty) {
      prompts.add(userSystemPrompt);
    }

    // 3. Project/global instructions (resolved from chatorai.json)
    for (final block in instructionBlocks) {
      if (block.isNotEmpty) prompts.add(block);
    }

    // Return single combined system message or empty
    if (prompts.isEmpty) return [];
    return [
      {'role': 'system', 'content': prompts.join('\n\n---\n\n')},
    ];
  }

  List<Map<String, dynamic>> _buildApiMessages(
    Chat chat, {
    String? delegateAgentId,
    String? agentMention,
  }) {
    // `compactedContext` is tail-only (summary lives in `messages` as a single
    // source of truth). Re-inject the summary from `messages` so the model
    // context is `[summary, ...tail]` — mirroring how assembles the
    // context per call rather than duplicating the summary in storage.
    final compactedSummary = chat.compactedContext != null
        ? _findSummaryMessage(chat.messages)
        : null;
    final sourceMessages = [
      ?compactedSummary,
      ...(chat.compactedContext ?? chat.messages),
    ];
    const int maxHistoryMessages = 20;
    final recentMessages = sourceMessages.length > maxHistoryMessages
        ? sourceMessages.sublist(sourceMessages.length - maxHistoryMessages)
        : sourceMessages;

    final messages = recentMessages.where((m) => !m.isError).map((msg) {
      final result = <String, dynamic>{
        'role': msg.role.name,
        'isCompactionSummary': msg.isCompactionSummary,
      };
      if (msg.agent != null) result['agent'] = msg.agent;

      var content = msg.content;
      if (msg.attachedDocPath != null) {
        final safeName = p
            .basename(msg.attachedDocPath!)
            .replaceAll('"', '\\"');
        final safePath = msg.attachedDocPath!.replaceAll('"', '\\"');
        content +=
            '\n\n[Attached file: "$safeName". '
            'Use the document_extract tool with filePath: "$safePath" '
            'to read its contents.]';
      }

      if (msg.imageData != null && msg.imageType != null) {
        result['content'] = [
          {'type': 'text', 'text': content},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:${msg.imageType};base64,${msg.imageData}',
            },
          },
        ];
      } else {
        result['content'] = content;
      }
      return result;
    }).toList();

    // Inject system prompt chain at the beginning
    final currentAgent = ref.read(currentAgentProvider);
    final settings = ref.read(modelSettingsProvider).activeSettings;
    final instructionBlocks =
        ref.read(resolvedInstructionsProvider).value ?? const [];

    // Add agent system prompts (only for primary agents or no delegation)
    final systemChain = _buildSystemChain(
      agent: currentAgent,
      userSystemPrompt: settings?.systemPrompt,
      // For subagents, pass null (they get their prompt in child session from task tool)
      delegateAgentId: agentMention != null ? null : delegateAgentId,
      instructionBlocks: instructionBlocks,
    );
    for (final sys in systemChain) {
      messages.insert(0, sys);
    }

    // Add agent delegation instruction for subagents
    if (agentMention != null) {
      final agent = AgentRegistry().get(agentMention);
      if (agent != null && agent.mode == AgentMode.subagent) {
        messages.insert(systemChain.length, {
          'role': 'system',
          'content':
              'Delegate to subagent $agentMention. '
              'Use the task tool with subagent_type: "$agentMention" to process this request.',
        });
      }
    }

    return messages;
  }

  /// Finds the compaction summary message (if any) in the visible [messages]
  /// history. The summary is the single source of truth for the model context;
  /// it is never duplicated into [Chat.compactedContext].
  Message? _findSummaryMessage(List<Message> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isCompactionSummary) return messages[i];
    }
    return null;
  }

  /// Builds the pre-send model message list from a compacted [canonicalChat].
  ///
  /// `canonicalChat.compactedContext` is tail-only, so the summary is re-injected
  /// from the original [chat.messages] (single source of truth). Returns the
  /// unchanged [fallback] when there is no compacted context.
  List<Map<String, dynamic>> _compactedApiMessagesWithSummary(
    Chat chat,
    Chat canonicalChat,
  ) {
    final compacted = canonicalChat.compactedContext;
    if (compacted == null || compacted.isEmpty) return [];
    final summary = _findSummaryMessage(chat.messages);
    final result = <Map<String, dynamic>>[];
    if (summary != null) {
      result.add({
        'role': summary.role.name,
        'content': summary.content,
        if (summary.agent != null) 'agent': summary.agent,
        'isCompactionSummary': true,
      });
    }
    for (final m in compacted) {
      result.add({
        'role': m.role.name,
        'content': m.content,
        if (m.agent != null) 'agent': m.agent,
        if (m.isCompactionSummary) 'isCompactionSummary': true,
      });
    }
    return result;
  }

  Future<void> _initiateStream({
    required Chat chat,
    required List<Map<String, dynamic>> messages,
    required bool isContinuation,
    String? delegateAgentId,
    String? agentMention,
    String? pendingAssistantMessageId,
  }) async {
    LogTags.chatScreen.logInfo(
      '_initiateStream: enter model=$selectedModelId isContinuation=$isContinuation',
    );
    final repo = await _sessionRepositoryFuture;
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
      modelRef: selectedModelId,
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
    _pushSessionToStack(isNewSession: isNewSession);

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
      final settings = await modelSettingsNotifier.getSettings(selectedModelId);
      LogTags.chatScreen.logInfo('_initiateStream: settings ready');

      LogTags.chatScreen.logInfo(
        '_initiateStream: calling _handleStreamingResponse model=$selectedModelId',
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

      await _handleStreamingResponse(
        chat: chat,
        messages: messages,
        isContinuation: isContinuation,
        modelId: selectedModelId,
        modelSettings: settings,
        temperature: temperature,
        maxSteps: maxSteps,
        activeAgent: activeAgent,
      );
    } catch (e, s) {
      LogTags.chatScreen.logError('_initiateStream: streaming error $e');
      ref.read(chatScreenProvider.notifier).setStreaming(false);
      try {
        await _handleStreamingError(e, _currentSessionId ?? chat.id);
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

  Future<void> _handleSendMessage(MessageData messageData) async {
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
      if (currentChat == null) {
        _currentSessionId = null;
        ref.read(permissionServiceProvider).clearSession();
        chat = await ref.read(chatListProvider.notifier).createNewChat();
        ref.read(currentChatIdProvider.notifier).setChatId(chat.id);
      } else {
        final chatId = currentChat!.id;
        final loaded = await ref
            .read(chatListProvider.notifier)
            .ensureChatLoaded(chatId);
        final current = ref.read(currentChatProvider);
        if (current == null || current.id != chatId) return;
        chat = loaded ?? current;
      }

      final userMessage = _createUserMessage(
        messageData.text,
        base64Data: messageData.base64Data,
        imageType: messageData.imageType,
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
      if (mounted && streamChat.isDefaultTitle) {
        unawaited(_autoGenerateTitleIfNeeded(streamChat));
      }

      final agentName =
          AgentRegistry().get(messageData.delegateAgentId ?? '')?.name ??
          ref.read(currentAgentProvider).name;
      // For subagent mentions, keep the current agent (LLM will call task tool)
      final assistantAgentName = messageData.agentMention != null
          ? ref.read(currentAgentProvider).name
          : agentName;
      final messages = _buildApiMessages(
        streamChat,
        delegateAgentId: messageData.delegateAgentId,
        agentMention: messageData.agentMention,
      );
      LogTags.chatScreen.logInfo(
        '_handleSendMessage: sending to LLM messages=${messages.length} agentMention=${messageData.agentMention ?? "none"}',
      );
      // Appends the assistant placeholder, updates the chat list and starts
      // streaming into that exact message id (no duplicate bubbles on reload).
      await _startAssistantTurn(
        chat: streamChat,
        sessionId: sessionId.value,
        agentName: assistantAgentName,
        delegateAgentId: messageData.delegateAgentId,
        agentMention: messageData.agentMention,
        buildMessages: (withPlaceholder) => _buildApiMessages(
          withPlaceholder,
          delegateAgentId: messageData.delegateAgentId,
          agentMention: messageData.agentMention,
        ),
      );
    } finally {
      _isHandlingMessage = false;
    }
  }

  /// Push the current session onto the navigation stack.
  /// Only pushes on the first creation (when sessionId was null before).
  void _pushSessionToStack({required bool isNewSession}) {
    if (_currentSessionId != null && isNewSession) {
      ref
          .read(sessionStackProvider.notifier)
          .push(SessionID.fromString(_currentSessionId!));
    }
  }

  Future<void> _handleQuestionAnswer(String messageId, String answer) async {
    final chat = currentChat;
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
    await _handleSendMessage(MessageData(text: answer));
  }

  Message _createUserMessage(
    String content, {
    String? base64Data,
    String? imageType,
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
      attachedDocPath: attachedDocPath,
    );
  }

  Message _createAssistantMessage({
    String content = '',
    bool isComplete = false,
    String? model,
    String? reasoning,
    int? tokensInput,
    int? tokensOutput,
    int? tokensReasoning,
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
      model: model ?? selectedModelId,
      reasoning: reasoning,
      tokensInput: tokensInput,
      tokensOutput: tokensOutput,
      tokensReasoning: tokensReasoning,
      contextLength: contextLength,
      partsJson: partsJson,
      agent: agent ?? ref.read(currentAgentProvider).name,
    );
  }

  void _stopStreaming() async {
    _streamCancelled = true;
    final aiService = ref.read(chatAiServiceProvider);
    aiService.cancelAllRequests();

    final permissionService = ref.read(permissionServiceProvider);
    permissionService.cancelAllPendingRequests();

    ref.read(currentSessionRunnerProvider.notifier).cancelAllChildren();

    await Future<void>.delayed(const Duration(milliseconds: 100));

    final chat = currentChat;
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
      completedMessage = _createAssistantMessage(
        content: content,
        reasoning: reasoning.isNotEmpty ? reasoning : null,
        isComplete: true,
        partsJson: partsJson,
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

  void _refreshChatMessages() async {
    FocusScope.of(context).unfocus();
    if (currentChat != null) {
      final updatedChat = await ref
          .read(chatListProvider.notifier)
          .ensureChatLoaded(currentChat!.id, forceRefresh: true);
      if (updatedChat == null || !mounted) return;
      ref.read(chatScreenProvider.notifier).hideSuggestions();
      if (updatedChat.messages.isEmpty) {
        ref.read(chatScreenProvider.notifier).hideAllSuggestions();
        _showWelcomeSuggestions();
      }
    }
  }
}
