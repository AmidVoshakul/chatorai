part of 'chat_screen.dart';

extension _ChatScreenStreamingExt on _ChatScreenState {
  Future<void> _handleStreamingResponse({
    required Chat chat,
    required List<Map<String, dynamic>> messages,
    required bool isContinuation,
    required String modelId,
    required ModelSettings modelSettings,
    required double temperature,
    required String? activeAgent,
    int maxSteps = 5,
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
      final compactedApiMessages = await _applyCompaction(attemptMsgs, chat);
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
        final systemChain = _buildSystemChain(
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
          _maybeAutoScrollDuringStreaming();
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
          _maybeAutoScrollDuringStreaming();
        },
        onToolError: (toolCallId, toolName, error) async {
          final errorStr = error.toString();

          if (toolName == 'document_extract' && mounted) {
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
          _maybeAutoScrollDuringStreaming();
        },
        onReasoning: (reasoning) async {
          if (reasoning.isEmpty) return;
          await runnerSession.onReasoning(reasoning);
          _maybeAutoScrollDuringStreaming();
        },
        onReasoningEnd: () => runnerSession.onReasoningEnd(),
        maxSteps: maxSteps,
        onCompletion: (sdkText) async {
          if (!mounted || _streamCancelled) return;
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
            completedMessage = _createAssistantMessage(
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
            _chatInputFocusNode.unfocus();
          });
          _showContinuationSuggestions(completedMessage);
          _maybeAutoScrollDuringStreaming();
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
      await _handleStreamingError(e, sessionId);
    } finally {
      toolInputs.clear();
      toolStartTimes.clear();
    }
  }

  Future<void> _handleStreamingError(Object error, String sessionId) async {
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
        currentChat;
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
}
