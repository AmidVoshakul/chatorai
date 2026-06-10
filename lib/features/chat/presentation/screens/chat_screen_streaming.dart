part of 'chat_screen.dart';

extension _ChatScreenStreamingExt on _ChatScreenState {
  Future<void> _handleStreamingResponse({
    required Chat chat,
    required List<Map<String, dynamic>> messages,
    required bool isContinuation,
    required String modelId,
    required ModelSettings modelSettings,
  }) async {
    ref.read(chatScreenProvider.notifier).setStreaming(true);
    ref.read(streamingMessageProvider.notifier).startStreaming(chat.id);
    final StringBuffer pendingContent = StringBuffer();
    final StringBuffer fullContent = StringBuffer();
    final StringBuffer pendingReasoning = StringBuffer();
    final StringBuffer fullReasoning = StringBuffer();
    DateTime lastUpdateTime = DateTime.now();
    const updateIntervalMs = 250;

    bool isWordBoundary(String text) {
      if (text.isEmpty) return false;
      final lastChar = text[text.length - 1];
      return lastChar == ' ' ||
          lastChar == '\n' ||
          lastChar == '.' ||
          lastChar == ',' ||
          lastChar == '!' ||
          lastChar == '?' ||
          lastChar == ';' ||
          lastChar == ':' ||
          lastChar == ')' ||
          lastChar == ']' ||
          lastChar == '}' ||
          lastChar == '"' ||
          lastChar == "'";
    }

    void throttleUpdate({bool forceUpdate = false}) {
      final now = DateTime.now();
      final elapsed = now.difference(lastUpdateTime).inMilliseconds;
      final pendingContentStr = pendingContent.toString();
      final pendingReasoningStr = pendingReasoning.toString();
      final shouldUpdate =
          forceUpdate ||
          elapsed >= updateIntervalMs ||
          isWordBoundary(pendingContentStr) ||
          isWordBoundary(pendingReasoningStr);
      if (shouldUpdate) {
        if (mounted && chat.messages.isNotEmpty) {
          if (pendingContentStr.isNotEmpty) {
            ref
                .read(streamingMessageProvider.notifier)
                .onChunk(pendingContentStr);
          }
          if (pendingReasoningStr.isNotEmpty) {
            ref
                .read(streamingMessageProvider.notifier)
                .onReasoning(pendingReasoningStr);
          }
          fullContent.write(pendingContentStr);
          fullReasoning.write(pendingReasoningStr);
          pendingContent.clear();
          pendingReasoning.clear();
          lastUpdateTime = now;
        }
      }
    }

    void flushPendingUpdates() {
      final pendingContentStr = pendingContent.toString();
      final pendingReasoningStr = pendingReasoning.toString();
      if (pendingContentStr.isNotEmpty) {
        ref.read(streamingMessageProvider.notifier).onChunk(pendingContentStr);
        fullContent.write(pendingContentStr);
      }
      if (pendingReasoningStr.isNotEmpty) {
        ref
            .read(streamingMessageProvider.notifier)
            .onReasoning(pendingReasoningStr);
        fullReasoning.write(pendingReasoningStr);
      }
      pendingContent.clear();
      pendingReasoning.clear();
      lastUpdateTime = DateTime.now();
    }

    final toolRegistry = await ref.read(toolRegistryProvider.future);
    final aiService = ref.read(chatAiServiceProvider);
    final attemptMsgs = aiService.sanitizeMessages(messages);
    int latestCumulativeTokens = 0;
    final modelContextLength = ref.read(modelProvider).selectedModelObject?.contextLength;

    if (aiService.isOverflow && attemptMsgs.length > 4) {
      final compactionService = const CompactionService();
      final compactedApiMessages = await compactionService.compact(
        messages: attemptMsgs,
        aiService: aiService,
        model: modelId,
      );
      if (compactedApiMessages.isNotEmpty) {
        attemptMsgs.clear();
        attemptMsgs.addAll(compactedApiMessages);
        final chatMessages = compactedApiMessages.map((m) {
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
          );
        }).toList();
        final newChat = chat.copyWith(
          messages: chatMessages,
          updatedAt: DateTime.now(),
        );
        ref.read(chatListProvider.notifier).updateChat(newChat);
      }
    }
    try {
      if (modelContextLength != null) {
        aiService.updateModelContextLength(modelContextLength);
      }
      await aiService.streamChatCompletion(
        messages: attemptMsgs,
        model: modelId,
        temperature: modelSettings.temperature,
        tools: toolRegistry.toSDKTools(),
        onRetry: (attempt, error) {
          flushPendingUpdates();
          ref.read(streamingMessageProvider.notifier).startStreaming(chat.id);
        },
        onUsage: (input, output) {
          latestCumulativeTokens = aiService.tokenCounter.totalTokens;
        },
        onToolStart: (toolCallId, toolName, input) {
          ref
              .read(streamingMessageProvider.notifier)
              .onToolCall(toolCallId, toolName, input);
        },
        onToolEnd: (toolCallId, toolName, result) {
          ref
              .read(streamingMessageProvider.notifier)
              .onToolEnd(toolCallId, toolName, result.toString());
        },
        onToolError: (toolCallId, toolName, error) {
          ref
              .read(streamingMessageProvider.notifier)
              .onToolError(toolCallId, toolName, error.toString());
        },
        onChunk: (content) {
          if (content.isEmpty) return;
          pendingContent.write(content);
          throttleUpdate();
        },
        onReasoning: (reasoning) {
          if (reasoning.isEmpty) return;
          pendingReasoning.write(reasoning);
          throttleUpdate();
        },
        onCompletion: (sdkText) async {
          flushPendingUpdates();
          if (mounted) {
            final content = fullContent.isNotEmpty
                ? fullContent.toString()
                : sdkText;
            final reasoning = fullReasoning.isNotEmpty
                ? fullReasoning.toString()
                : null;
            final streamingState = ref.read(streamingMessageProvider);
            final allParts = streamingState.accumulatedParts;
            final toolParts = allParts
                .where(
                  (p) => p is ToolResultPart || p is TodoPart || p is TaskPart,
                )
                .toList();
            final partsJson = toolParts.isNotEmpty
                ? toolParts.map((p) => p.toJson()).toList()
                : null;
            final lastIsIncomplete =
                chat.messages.isNotEmpty &&
                chat.messages.last.role == MessageRole.assistant &&
                !chat.messages.last.isComplete;
            Message completedMessage;
            List<Message> newMessages;
            if (lastIsIncomplete) {
              final lastMsg = chat.messages.last;
               completedMessage = lastMsg.copyWith(
                 content: content,
                 reasoning: reasoning,
                 isComplete: true,
                 partsJson: partsJson,
                 cumulativeTokens: latestCumulativeTokens,
                 contextLength: modelContextLength ?? lastMsg.contextLength,
               );
              newMessages = [
                for (int i = 0; i < chat.messages.length - 1; i++)
                  chat.messages[i],
                completedMessage,
              ];
            } else {
               completedMessage = _createAssistantMessage(
                 content: content,
                 reasoning: reasoning,
                 isComplete: true,
                 cumulativeTokens: latestCumulativeTokens,
                 partsJson: partsJson,
                 contextLength: modelContextLength,
               );
              newMessages = [...chat.messages, completedMessage];
            }
            final newChat = chat.copyWith(
              messages: newMessages,
              updatedAt: DateTime.now(),
            );
            ref.read(chatListProvider.notifier).updateChat(newChat);
            ref.read(chatScreenProvider.notifier).setStreaming(false);
            await ref.read(streamingMessageProvider.notifier).stopStreaming();
            await _chatStorageService.updateMessageInChat(
              newChat.id,
              completedMessage.id,
              completedMessage,
            );
            _showContinuationSuggestions(completedMessage);
          }
        },
      );
    } catch (e) {
      ref.read(chatScreenProvider.notifier).setStreaming(false);
      ref.read(streamingMessageProvider.notifier).reset();
      await _handleStreamingError(e);
    }
  }

  Future<void> _handleStreamingError(Object error) async {
    final errorMessage = ChatErrorUtils.formatError(error);
    final chat = currentChat;
    if (chat != null && chat.messages.isNotEmpty) {
      final lastMessage = chat.messages.last;
      if (lastMessage.role == MessageRole.assistant) {
        final errorResponseMessage = lastMessage.copyWith(
          content: errorMessage,
          isComplete: true,
          isError: true,
        );
        await _chatStorageService.updateMessageInChat(
          chat.id,
          errorResponseMessage.id,
          errorResponseMessage,
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
}
