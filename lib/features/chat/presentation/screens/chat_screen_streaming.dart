part of 'chat_screen.dart';

extension _ChatScreenStreamingExt on _ChatScreenState {
  Future<void> _handleStreamingResponse({
    required Chat chat,
    required List<Map<String, dynamic>> messages,
    required bool isContinuation,
    required String modelId,
    required ModelSettings modelSettings,
  }) async {
    LogTags.chatScreen.logInfo(
      '_handleStreamingResponse START: chatId=${chat.id}, model=$modelId, isContinuation=$isContinuation',
    );
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

          // Auto-scroll during streaming if enabled
          if (mounted &&
              _autoScrollEnabled &&
              ref.read(themeProvider).autoScrollDuringStreaming) {
            LogTags.chatService.logInfo(
              'ChatScreen.throttleUpdate: streaming auto-scroll triggered (_autoScrollEnabled=$_autoScrollEnabled, setting=${ref.read(themeProvider).autoScrollDuringStreaming})',
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              LogTags.chatService.logInfo(
                'ChatScreen.throttleUpdate: calling scrollToBottom',
              );
              _scrollToBottom(force: false);
            });
          } else {
            LogTags.chatService.logInfo(
              'ChatScreen.throttleUpdate: streaming auto-scroll skipped (mounted=$mounted, _autoScrollEnabled=$_autoScrollEnabled, setting=${ref.read(themeProvider).autoScrollDuringStreaming})',
            );
          }
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
    final modelContextLength = ref
        .read(modelProvider)
        .selectedModelObject
        ?.contextLength;

     // ── Session Runner (event sourcing) ──────────────────────────────────
     // Runner already created and initialized in _handleAddMessagesAndStream
     final runnerSession = _sessionRunner;
     if (runnerSession == null) {
       throw StateError('SessionRunner not initialized — must call _handleAddMessagesAndStream first');
     }

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
        onRetry: (info) {
          flushPendingUpdates();
          // Show retry indicator under the last message
          ref
              .read(chatScreenProvider.notifier)
              .setRetryInfo(
                isRetrying: true,
                retryMessage: info.message,
                retryAttempt: info.attempt,
              );
          // Preserve accumulated text in the request to avoid restarting from scratch
          final streamingState = ref.read(streamingMessageProvider);
          final partialText = streamingState.accumulatedParts
              .whereType<TextPart>()
              .map((p) => p.content)
              .join();
          if (partialText.isNotEmpty) {
            // Replace any partial assistant message at the end
            if (attemptMsgs.isNotEmpty &&
                attemptMsgs.last['role'] == 'assistant') {
              attemptMsgs.removeLast();
            }
            attemptMsgs.add({'role': 'assistant', 'content': partialText});
          }
        },
        onUsage: (input, output) {
          latestCumulativeTokens = aiService.tokenCounter.totalTokens;
        },
        onToolStart: (toolCallId, toolName, input) {
          runnerSession.onToolStart(toolCallId, toolName, input);
          ref
              .read(streamingMessageProvider.notifier)
              .onToolCall(toolCallId, toolName, input);
        },
        onToolEnd: (toolCallId, toolName, result) {
          runnerSession.onToolEnd(toolCallId, toolName, result.toString());
          ref
              .read(streamingMessageProvider.notifier)
              .onToolEnd(toolCallId, toolName, result.toString());
        },
        onToolError: (toolCallId, toolName, error) {
          runnerSession.onToolError(toolCallId, toolName, error.toString());
          ref
              .read(streamingMessageProvider.notifier)
              .onToolError(toolCallId, toolName, error.toString());
        },
        onChunk: (content) {
          if (content.isEmpty) return;
          runnerSession.onChunk(content);
          pendingContent.write(content);
          throttleUpdate();
        },
        onReasoning: (reasoning) {
          if (reasoning.isEmpty) return;
          runnerSession.onReasoning(reasoning);
          pendingReasoning.write(reasoning);
          throttleUpdate();
        },
        onCompletion: (sdkText) async {
          flushPendingUpdates();
          if (!mounted) return;
          // Reset retry state on successful completion
          ref
              .read(chatScreenProvider.notifier)
              .setRetryInfo(
                isRetrying: false,
                retryMessage: null,
                retryAttempt: 0,
              );
          // Auto-scroll to bottom when streaming completes (if enabled)
          if (_autoScrollEnabled &&
              ref.read(themeProvider).autoScrollDuringStreaming) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom(force: false);
            });
          }

          // Extract text + reasoning from accumulated parts for session runner
          final streamingStateBeforeFinalize = ref.read(
            streamingMessageProvider,
          );
          final partsBeforeFinalize =
              streamingStateBeforeFinalize.accumulatedParts;
          final textBuf = StringBuffer();
          final reasoningBuf = StringBuffer();
          for (final part in partsBeforeFinalize) {
            if (part is TextPart) textBuf.write(part.content);
            if (part is ReasoningPart) reasoningBuf.write(part.content);
          }
          final accumulatedText = textBuf.toString();
          final accumulatedReasoning = reasoningBuf.toString();
          // Finalize session — publish TextEnded/ReasoningEnded/StepEnded
          await runnerSession.onCompletion(
            content: accumulatedText.isNotEmpty ? accumulatedText : sdkText,
            reasoning: accumulatedReasoning.isNotEmpty
                ? accumulatedReasoning
                : null,
            model: modelId,
            tokensInput: latestCumulativeTokens,
            tokensOutput: latestCumulativeTokens,
          );

          LogTags.chatScreen.logInfo(
            'onCompletion: flushing done, proceeding to finalize message',
          );
          final streamingState = ref.read(streamingMessageProvider);
          final allParts = streamingState.accumulatedParts;
          LogTags.chatScreen.logDebug(
            'onCompletion: totalParts=${allParts.length}, will extract text+reasoning',
          );

          // Extract text content from all TextParts
          final textBuffer = StringBuffer();
          final reasoningBuffer = StringBuffer();
          for (final part in allParts) {
            if (part is TextPart) {
              textBuffer.write(part.content);
            } else if (part is ReasoningPart) {
              reasoningBuffer.write(part.content);
            }
          }
          final content = textBuffer.toString().isNotEmpty
              ? textBuffer.toString()
              : sdkText;
          final reasoningRaw = reasoningBuffer.toString();
          final reasoning = reasoningRaw.trim().isNotEmpty
              ? reasoningRaw
              : null;

          LogTags.chatScreen.logDebug(
            'onCompletion: extracted contentLen=${content.length}, reasoningLen=${reasoning?.length ?? 0} raw=${reasoningRaw.length}',
          );

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
          LogTags.chatScreen.logInfo(
            'onCompletion: saving message id=${completedMessage.id}, partsCount=${toolParts.length}',
          );
          ref.read(chatListProvider.notifier).updateChat(newChat);
          ref.read(chatScreenProvider.notifier).setStreaming(false);
          await ref.read(streamingMessageProvider.notifier).stopStreaming();
          await _chatStorageService.updateMessageInChat(
            newChat.id,
            completedMessage.id,
            completedMessage,
          );
          LogTags.chatService.logInfo(
            'ChatScreen.onCompletion: message saved, scrolling to bottom',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            LogTags.chatService.logInfo(
              'ChatScreen.onCompletion: postFrame scrollToBottom call',
            );
            _scrollToBottom(force: true);
          });
          _showContinuationSuggestions(completedMessage);
        },
      );
    } catch (e) {
      ref.read(chatScreenProvider.notifier).setStreaming(false);
      ref.read(streamingMessageProvider.notifier).reset();
      // Mark session step as failed
      await runnerSession.onError(e);
      await _handleStreamingError(e);
    } finally {
      runnerSession.dispose();
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
