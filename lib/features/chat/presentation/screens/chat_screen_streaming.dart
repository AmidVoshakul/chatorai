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

    final toolOutputPersistence = ToolOutputPersistence.instance;
    final toolInputs = <String, Map<String, dynamic>>{};
    final toolStartTimes = <String, DateTime>{};
    final processedToolEndCalls = <String>{};
    String? activeTaskSessionId;

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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom(force: false);
            });
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
    int? latestTokensInput;
    int? latestTokensOutput;
    int? latestTokensCacheRead;
    int? latestTokensCacheWrite;
    final modelContextLength = ref
        .read(modelProvider)
        .selectedModelObject
        ?.contextLength;

    // Deduplication for question tool onToolStart (Bug 3)
    String? lastAddedQuestionText;
    DateTime? lastAddedQuestionTime;
    const questionDebounceMs = 500; // within 500ms consider duplicate

    // ── Session Runner (event sourcing) ──────────────────────────────────
    // Set by _initiateStream before calling this method
    final runnerSession = _sessionRunner;
    if (runnerSession == null) {
      throw StateError(
        'SessionRunner not initialized — call _initiateStream first',
      );
    }

    // Forward child tool events to parent TaskPart UI (task delegation)
    final holder = ref.read(currentSessionRunnerProvider.notifier);
    holder.onChildToolEvent = (toolName, title) {
      ref
          .read(streamingMessageProvider.notifier)
          .onTaskToolExecuted(toolName, title);
    };

    // ── Pre-send overflow check (OpenCode-style) ─────────────────────────
    // Estimate BEFORE sending to LLM; compact proactively if needed.
    final sessionId = runnerSession.sessionId.value;
    final estimatedTokens = aiService.estimatePromptTokens(attemptMsgs);
    final projectedTotal = estimatedTokens;
    final compactionConfig = ref.watch(compactionConfigProvider);
    if (projectedTotal >= aiService.overflowDetector.usable &&
        attemptMsgs.length > 4) {
      LogTags.chatScreen.logInfo(
        'Pre-send compaction triggered for $sessionId',
      );
      final compactionService = CompactionService.fromConfig(compactionConfig);
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
      // Fire-and-forget: persist compaction events to session store
      unawaited(() async {
        final repo = await _sessionRepositoryFuture;
        final orchestrator = CompactionOrchestrator(
          repo,
          completionProvider: aiService,
          compactionConfig: compactionConfig,
        );
        await orchestrator.compactSession(SessionID.fromString(sessionId));
      }());
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
        temperature: modelSettings.temperature,
        tools: toolRegistry.toSDKTools(),
        onRetry: (info) {
          flushPendingUpdates();
          ref
              .read(chatScreenProvider.notifier)
              .setRetryInfo(
                isRetrying: true,
                retryMessage: info.message,
                retryAttempt: info.attempt,
              );
          if (activeTaskSessionId != null) {
            ref
                .read(streamingMessageProvider.notifier)
                .onTaskError(info.message, info.attempt);
          }
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
        onUsage: (input, output, cacheRead, cacheWrite) {
          latestTokensInput = input;
          latestTokensOutput = output;
          latestTokensCacheRead = cacheRead;
          latestTokensCacheWrite = cacheWrite;
        },
        onToolStart: (toolCallId, toolName, input) async {
          toolInputs[toolCallId] = input;
          toolStartTimes[toolCallId] = DateTime.now();
          await runnerSession.onToolStart(toolCallId, toolName, input);

          if (toolName == 'task') {
            final description = input['description'] as String? ?? '';
            final subagentType = input['subagent_type'] as String? ?? 'general';
            final agent = AgentRegistry().get(subagentType);
            final agentName = agent?.name ?? subagentType;
            // Use toolCallId as fallback — LLM rarely provides task_id
            final childId = input['task_id'] as String? ?? 'task_$toolCallId';
            ref
                .read(streamingMessageProvider.notifier)
                .onTaskStart(
                  description: description,
                  agent: agentName,
                  sessionId: childId,
                );
            activeTaskSessionId = childId;
          } else if (activeTaskSessionId != null) {
            final toolTitle =
                input['command'] as String? ??
                input['query'] as String? ??
                input['filePath'] as String? ??
                input['path'] as String?;
            ref
                .read(streamingMessageProvider.notifier)
                .onTaskToolExecuted(toolName, toolTitle);
          }

          if (toolName == 'question') {
            // For question tool, create a QuestionPart in the streaming message
            final questionText = input['question'] as String? ?? '';
            final options = (input['options'] as List?)?.cast<String>() ?? [];

            // Deduplicate: skip if same question was added within debounce window
            final now = DateTime.now();
            final isDuplicate =
                lastAddedQuestionText == questionText &&
                lastAddedQuestionTime != null &&
                now.difference(lastAddedQuestionTime!).inMilliseconds <
                    questionDebounceMs;

            if (!isDuplicate) {
              ref
                  .read(streamingMessageProvider.notifier)
                  .onQuestion(
                    QuestionPart(question: questionText, options: options),
                  );
              lastAddedQuestionText = questionText;
              lastAddedQuestionTime = now;
              LogTags.chatScreen.logInfo(
                'onToolStart(question): added QuestionPart "$questionText"',
              );
            } else {
              LogTags.chatScreen.logInfo(
                'onToolStart(question): DUPLICATE skipped "$questionText"',
              );
            }
          } else if (toolName != 'task') {
            ref
                .read(streamingMessageProvider.notifier)
                .onToolCall(toolCallId, toolName, input);
          }
        },
        onToolEnd: (toolCallId, toolName, result) async {
          if (!processedToolEndCalls.add(toolCallId)) return;
          final resultStr = result.toString();
          await runnerSession.onToolEnd(toolCallId, toolName, resultStr);

          if (toolName == 'task' && activeTaskSessionId != null) {
            // Update TaskPart with real child session ID from the holder
            final realChildId = ref
                .read(currentSessionRunnerProvider.notifier)
                .activeChildSessionId;
            if (realChildId != null && realChildId.isNotEmpty) {
              ref
                  .read(streamingMessageProvider.notifier)
                  .updateTaskSessionId(realChildId);
            }
            ref.read(streamingMessageProvider.notifier).onTaskEnd();
            activeTaskSessionId = null;
            // Clear holder state
            ref
                    .read(currentSessionRunnerProvider.notifier)
                    .activeChildSessionId =
                null;
          } else if (activeTaskSessionId != null) {
            final toolInput = toolInputs[toolCallId];
            final title = toolInput != null
                ? (toolInput['command'] as String? ??
                      toolInput['query'] as String? ??
                      toolInput['filePath'] as String? ??
                      toolInput['path'] as String?)
                : null;
            ref
                .read(streamingMessageProvider.notifier)
                .onTaskToolExecuted(toolName, title);
          }

          if (toolName == 'question') {
            final streamingState = ref.read(streamingMessageProvider);
            for (final part in streamingState.accumulatedParts) {
              if (part is QuestionPart && part.answer == null) {
                ref
                    .read(streamingMessageProvider.notifier)
                    .onQuestion(
                      QuestionPart(
                        question: part.question,
                        options: part.options,
                        answer: resultStr,
                      ),
                    );
                break;
              }
            }
            LogTags.chatScreen.logInfo(
              'onToolEnd(question): answer="$resultStr"',
            );
          } else if (toolName != 'task') {
            ref
                .read(streamingMessageProvider.notifier)
                .onToolEnd(toolCallId, toolName, resultStr);
          }

          final startTime = toolStartTimes.remove(toolCallId);
          final durationMs = startTime != null
              ? DateTime.now().difference(startTime).inMilliseconds
              : 0;
          unawaited(
            toolOutputPersistence
                .saveResult(
                  toolCallId: toolCallId,
                  toolName: toolName,
                  input: toolInputs.remove(toolCallId),
                  output: resultStr,
                  sessionId: runnerSession.sessionId.value,
                  durationMs: durationMs,
                  status: ToolResultStatus.success,
                )
                .catchError((e) {
                  LogTags.chatService.logError('saveResult failed: $e');
                }),
          );
        },
        onToolError: (toolCallId, toolName, error) async {
          final errorStr = error.toString();
          await runnerSession.onToolError(toolCallId, toolName, errorStr);
          if (activeTaskSessionId != null) {
            ref
                .read(streamingMessageProvider.notifier)
                .onTaskError(errorStr, null);
          }
          if (toolName != 'task') {
            ref
                .read(streamingMessageProvider.notifier)
                .onToolError(toolCallId, toolName, errorStr);
          }
          final startTime = toolStartTimes.remove(toolCallId);
          final durationMs = startTime != null
              ? DateTime.now().difference(startTime).inMilliseconds
              : 0;
          unawaited(
            toolOutputPersistence
                .saveResult(
                  toolCallId: toolCallId,
                  toolName: toolName,
                  input: toolInputs.remove(toolCallId),
                  output: errorStr,
                  sessionId: runnerSession.sessionId.value,
                  durationMs: durationMs,
                  status: ToolResultStatus.error,
                )
                .catchError((e) {
                  LogTags.chatService.logError('saveResult failed: $e');
                }),
          );
          return;
        },
        onChunk: (content) async {
          if (content.isEmpty) return;
          await runnerSession.onChunk(content);
          pendingContent.write(content);
          throttleUpdate();
          return;
        },
        onReasoning: (reasoning) async {
          if (reasoning.isEmpty) return;
          await runnerSession.onReasoning(reasoning);
          pendingReasoning.write(reasoning);
          throttleUpdate();
          return;
        },
        onCompletion: (sdkText) async {
          flushPendingUpdates();
          if (!mounted) return;
          if (activeTaskSessionId != null) {
            ref.read(streamingMessageProvider.notifier).onTaskEnd();
            activeTaskSessionId = null;
          }
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
            tokensInput: latestTokensInput ?? 0,
            tokensOutput: latestTokensOutput ?? 0,
            tokensCacheRead: latestTokensCacheRead ?? 0,
            tokensCacheWrite: latestTokensCacheWrite ?? 0,
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

          final partsJson = allParts.isNotEmpty
              ? allParts.map((p) => p.toJson()).toList()
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
              tokensInput: latestTokensInput,
              tokensOutput: latestTokensOutput,
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
              tokensInput: latestTokensInput,
              tokensOutput: latestTokensOutput,
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
            'onCompletion: saving message id=${completedMessage.id}, partsCount=${allParts.length}',
          );
          ref.read(chatListProvider.notifier).updateChat(newChat);
          ref.read(chatScreenProvider.notifier).setStreaming(false);
          await ref.read(streamingMessageProvider.notifier).stopStreaming();
          // Clear child tool event callback
          holder.onChildToolEvent = null;
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
            // Restore focus to chat input after streaming completes (Bug 4)
            _chatInputFocusNode.requestFocus();
          });
          _showContinuationSuggestions(completedMessage);
        },
      );
    } catch (e) {
      ref.read(chatScreenProvider.notifier).setStreaming(false);
      ref.read(streamingMessageProvider.notifier).reset();
      holder.onChildToolEvent = null;
      // Mark session step as failed
      await runnerSession.onError(e);
      await _handleStreamingError(e);
    } finally {
      toolInputs.clear();
      toolStartTimes.clear();
    }
  }

  Future<void> _handleStreamingError(Object error) async {
    final errorMessage = ChatErrorUtils.formatError(error);
    final errorPrefix = '⚠️ $errorMessage';
    final chat = currentChat;
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
