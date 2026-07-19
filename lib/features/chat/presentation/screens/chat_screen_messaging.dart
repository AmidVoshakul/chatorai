part of 'chat_screen.dart';

extension _ChatScreenMessagingExt on _ChatScreenState {
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
    const int maxHistoryMessages = 20;
    final recentMessages = chat.messages.length > maxHistoryMessages
        ? chat.messages.sublist(chat.messages.length - maxHistoryMessages)
        : chat.messages;

    final messages = recentMessages.where((m) => !m.isError).map((msg) {
      final result = <String, dynamic>{'role': msg.role.name};
      if (msg.imageData != null && msg.imageType != null) {
        result['content'] = [
          {'type': 'text', 'text': msg.content},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:${msg.imageType};base64,${msg.imageData}',
            },
          },
        ];
      } else {
        result['content'] = msg.content;
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

  Future<void> _initiateStream({
    required Chat chat,
    required List<Map<String, dynamic>> messages,
    required bool isContinuation,
    String? delegateAgentId,
    String? agentMention,
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

    final sessionRunner = SessionRunner(repo, toolRegistry);
    final runnerSession = await sessionRunner.startInitializedSession(
      agent: agentName,
      modelRef: selectedModelId,
      sessionId: _currentSessionId != null
          ? SessionID.fromString(_currentSessionId!)
          : null,
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
      final userMessages = chat.messages
          .where((m) => m.role == MessageRole.user)
          .toList();
      if (userMessages.isNotEmpty) {
        final lastUserMsg = userMessages.last;
        try {
          await runnerSession.publishUserMessage(
            content: lastUserMsg.content,
            messageId: lastUserMsg.id,
          );
        } catch (e) {
          LogTags.chatService.logError(
            'Failed to publish user message to session core',
            e,
          );
        }
      }
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
        await _handleStreamingError(e);
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
    }
  }

  Future<void> _handleSendMessage(MessageData messageData) async {
    ref.read(chatScreenProvider.notifier).hideAllSuggestions();

    Chat chat;
    if (currentChat == null) {
      _currentSessionId = null;
      chat = await ref.read(chatListProvider.notifier).createNewChat();
      ref.read(currentChatIdProvider.notifier).setChatId(chat.id);
    } else {
      chat = currentChat!;
    }

    final userMessage = _createUserMessage(
      messageData.text,
      base64Data: messageData.base64Data,
      imageType: messageData.imageType,
    );
    await _chatStorageService.addMessageToChat(chat.id, userMessage);
    var streamChat = await _chatStorageService.getChat(chat.id);
    if (streamChat == null) return;

    final agentName =
        AgentRegistry().get(messageData.delegateAgentId ?? '')?.name ??
        ref.read(currentAgentProvider).name;
    // For subagent mentions, keep the current agent (LLM will call task tool)
    final assistantAgentName = messageData.agentMention != null
        ? ref.read(currentAgentProvider).name
        : agentName;
    final assistantMessage = _createAssistantMessage(agent: assistantAgentName);
    await _chatStorageService.addMessageToChat(streamChat.id, assistantMessage);
    streamChat = await _chatStorageService.getChat(streamChat.id) ?? streamChat;
    ref.read(chatListProvider.notifier).updateChat(streamChat);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollEnabled = true;
      _scrollToBottom(force: true);
    });

    final messages = _buildApiMessages(
      streamChat,
      delegateAgentId: messageData.delegateAgentId,
      agentMention: messageData.agentMention,
    );
    LogTags.chatScreen.logInfo(
      '_handleSendMessage: sending to LLM messages=${messages.length} agentMention=${messageData.agentMention ?? "none"}',
    );
    await _initiateStream(
      chat: streamChat,
      messages: messages,
      isContinuation: false,
      delegateAgentId: messageData.delegateAgentId,
      agentMention: messageData.agentMention,
    );
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

    await _chatStorageService.updateMessageInChat(
      chat.id,
      updatedMessage.id,
      updatedMessage,
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
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      isComplete: true,
      imageData: base64Data,
      imageType: imageType,
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

    await Future<void>.delayed(const Duration(milliseconds: 50));

    final chat = currentChat;
    if (chat == null || chat.messages.isEmpty) {
      ref.read(chatScreenProvider.notifier).finalizeStreaming();
      ref
          .read(chatScreenProvider.notifier)
          .setRetryInfo(isRetrying: false, retryMessage: null, retryAttempt: 0);
      return;
    }

    final notifier = ref.read(chatScreenProvider.notifier);
    notifier.closeAllRunningTasks();
    final closedParts = notifier.snapshotClosedStreamingParts();

    final content = closedParts
        .whereType<AssistantText>()
        .map((p) => p.text)
        .join();
    final reasoning = closedParts
        .whereType<AssistantReasoning>()
        .map((p) => p.text)
        .join();
    final toolParts = closedParts
        .where(
          (p) =>
              p is AssistantTool ||
              p is AssistantTask ||
              p is AssistantQuestion ||
              p is AssistantTodo,
        )
        .toList();
    final partsJson = toolParts.isNotEmpty
        ? assistantContentToPartMaps(toolParts)
        : null;

    final lastMessage = chat.messages.last;
    Message completedMessage;
    List<Message> newMessages;

    if (lastMessage.role == MessageRole.assistant && !lastMessage.isComplete) {
      completedMessage = lastMessage.copyWith(
        content: content,
        reasoning: reasoning.isNotEmpty ? reasoning : null,
        isComplete: true,
        partsJson: partsJson,
        tokensInput: aiService.tokenCounter.totalTokens,
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
        tokensInput: aiService.tokenCounter.totalTokens,
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
    if (lastMessage.role == MessageRole.assistant && !lastMessage.isComplete) {
      await _chatStorageService.updateMessageInChat(
        newChat.id,
        lastMessage.id,
        completedMessage,
      );
    } else {
      await _chatStorageService.addMessageToChat(newChat.id, completedMessage);
    }

    notifier.finalizeStreaming();
  }

  void _refreshChatMessages() async {
    FocusScope.of(context).unfocus();
    if (currentChat != null) {
      final updatedChat = await _chatStorageService.getChat(currentChat!.id);
      if (updatedChat != null) {
        ref.read(chatListProvider.notifier).updateChat(updatedChat);
        ref.read(chatScreenProvider.notifier).hideSuggestions();
        if (updatedChat.messages.isEmpty) {
          ref.read(chatScreenProvider.notifier).hideAllSuggestions();
          _showWelcomeSuggestions();
        }
      }
    }
  }
}
