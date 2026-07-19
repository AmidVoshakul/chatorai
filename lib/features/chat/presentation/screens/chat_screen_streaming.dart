part of 'chat_screen.dart';

extension _ChatScreenStreamingExt on _ChatScreenState {
  String _genPartId(String suffix) =>
      'part_${DateTime.now().microsecondsSinceEpoch}_$suffix';

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

    final StringBuffer pendingContent = StringBuffer();
    final StringBuffer fullContent = StringBuffer();
    final StringBuffer pendingReasoning = StringBuffer();
    final StringBuffer fullReasoning = StringBuffer();
    DateTime lastUpdateTime = DateTime.now();
    const updateIntervalMs = 200;

    final toolInputs = <String, Map<String, dynamic>>{};
    final toolStartTimes = <String, DateTime>{};
    final processedToolEndCalls = <String>{};
    final resolvedChildSessions = <String, String>{};
    final Set<String> activeTaskSessionIds = {};
    final Map<String, String> taskToolToPart = {};

    void resolveTaskChildSession(String taskPartId) {
      if (resolvedChildSessions.containsKey(taskPartId)) return;
      final childSessionId = ref
          .read(currentSessionRunnerProvider.notifier)
          .taskPartToChild[taskPartId];
      if (childSessionId != null) {
        notifier.onTaskSessionIdResolved(taskPartId, childSessionId);
        resolvedChildSessions[taskPartId] = childSessionId;
      }
    }

    String? currentMessageId;

    void flushPendingToNotifier() {
      final pendingText = pendingContent.toString();
      final pendingReason = pendingReasoning.toString();
      if (pendingText.isNotEmpty && currentMessageId != null) {
        fullContent.write(pendingText);
        notifier.onChunk(
          _genPartId('text'),
          currentMessageId!,
          sessionId,
          pendingText,
        );
        pendingContent.clear();
      }
      if (pendingReason.isNotEmpty && currentMessageId != null) {
        fullReasoning.write(pendingReason);
        notifier.onReasoning(
          _genPartId('reasoning'),
          currentMessageId!,
          sessionId,
          pendingReason,
        );
        pendingReasoning.clear();
      }
    }

    void throttleUpdate({bool forceUpdate = false}) {
      final now = DateTime.now();
      final elapsed = now.difference(lastUpdateTime).inMilliseconds;
      final shouldUpdate = forceUpdate || elapsed >= updateIntervalMs;
      if (shouldUpdate) {
        flushPendingToNotifier();
        lastUpdateTime = now;
        if (mounted &&
            _autoScrollEnabled &&
            ref.read(themeProvider).autoScrollDuringStreaming) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(force: false);
          });
        }
      }
    }

    void scrollOnContentAdd() {
      if (!mounted || !_autoScrollEnabled) return;
      if (!ref.read(themeProvider).autoScrollDuringStreaming) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(force: false);
      });
    }

    void flushPendingUpdates() {
      flushPendingToNotifier();
      lastUpdateTime = DateTime.now();
      scrollOnContentAdd();
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

    String? lastAddedQuestionText;
    DateTime? lastAddedQuestionTime;
    const questionDebounceMs = 500;

    final runnerSession = _sessionRunner;
    if (runnerSession == null) {
      throw StateError(
        'SessionRunner not initialized — call _initiateStream first',
      );
    }

    final holder = ref.read(currentSessionRunnerProvider.notifier);
    // Resolve the TaskPart's child session id as soon as the delegated child
    // session is created, so the widget can read the sub-agent's live tool
    // results and render its current tool title dynamically. Route by child
    // session id (not the single activeTaskSessionId) so concurrent tasks each
    // get their own live header.
    holder.onChildSessionResolved = (childSessionId) {
      final taskPartId = holder.childToTaskPart[childSessionId];
      LogTags.chatScreen.logInfo(
        '[TaskTrace] onChildSessionResolved WHAT=resolve child→part WHERE=streaming '
        'WHEN=${DateTime.now()} WHY=map child session to TaskPart.taskSessionId '
        'child=$childSessionId taskPartId=$taskPartId '
        'mapSize=${holder.childToTaskPart.length}',
      );
      if (taskPartId != null) {
        notifier.onTaskSessionIdResolved(taskPartId, childSessionId);
      } else {
        LogTags.chatScreen.logWarning(
          '[TaskTrace] onChildSessionResolved MISSING MAP ENTRY child=$childSessionId '
          'WHY=child not registered before event → TaskPart.taskSessionId will NOT be set',
        );
      }
    };
    holder.onChildToolEvent = (childSessionId, toolName, title) {
      final taskPartId = holder.childToTaskPart[childSessionId];
      LogTags.chatScreen.logInfo(
        '[TaskTrace] onChildToolEvent WHAT=child tool→update part WHERE=streaming '
        'WHEN=${DateTime.now()} WHY=route live tool title to TaskPart '
        'child=$childSessionId tool=$toolName title=${title ?? ''} taskPartId=$taskPartId',
      );
      if (taskPartId != null) {
        // Resolve the child session id as soon as the first tool event
        // arrives so the TaskPart can read live tool calls from the child
        // session (mirrors opencode, which sources the tool list from the
        // child session rather than from the parent task tool).
        notifier.onTaskSessionIdResolved(taskPartId, childSessionId);
        notifier.onTaskToolExecuted(taskPartId, toolName, title);
      } else {
        LogTags.chatScreen.logWarning(
          '[TaskTrace] onChildToolEvent MISSING MAP ENTRY child=$childSessionId '
          'WHY=child not registered → header will not update for this part',
        );
      }
    };

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
        temperature: temperature,
        tools: toolRegistry.toSDKTools(),
        onRetry: (info) {
          flushPendingUpdates();
          notifier.setRetryInfo(
            isRetrying: true,
            retryMessage: info.message,
            retryAttempt: info.attempt,
          );
          if (activeTaskSessionIds.isNotEmpty) {
            final id = activeTaskSessionIds.last;
            notifier.onTaskError(id, info.message);
            unawaited(runnerSession.onTaskError(id, info.message));
          }
          final partialText = fullContent.toString();
          if (partialText.isNotEmpty) {
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

          currentMessageId ??= 'msg_${DateTime.now().microsecondsSinceEpoch}';
          flushPendingUpdates();

          if (toolName == 'question') {
            final questionText = input['question'] as String? ?? '';
            final options =
                (input['options'] as List?)
                    ?.map(QuestionOption.fromJson)
                    .toList() ??
                const [];
            final multiple = input['multiple'] as bool? ?? false;

            final now = DateTime.now();
            final isDuplicate =
                lastAddedQuestionText == questionText &&
                lastAddedQuestionTime != null &&
                now.difference(lastAddedQuestionTime!).inMilliseconds <
                    questionDebounceMs;

            if (!isDuplicate) {
              final qPartId = 'question_${now.microsecondsSinceEpoch}';
              notifier.onQuestion(
                qPartId,
                currentMessageId!,
                sessionId,
                questionText,
                options,
                multiple,
              );
              lastAddedQuestionText = questionText;
              lastAddedQuestionTime = now;
              LogTags.chatScreen.logInfo(
                'onToolStart(question): added QuestionPart "$questionText"',
              );
            }
          } else {
            final partId = _genPartId(toolCallId);
            if (toolName != 'task' && activeTaskSessionIds.isEmpty) {
              notifier.onToolCall(
                partId,
                toolCallId,
                currentMessageId!,
                sessionId,
                toolName,
                input,
              );
            }

            if (toolName == 'task') {
              final description = input['description'] as String? ?? '';
              final subagentType =
                  input['subagent_type'] as String? ?? 'general';
              final agent = AgentRegistry().get(subagentType);
              final agentName = agent?.name ?? subagentType;
              final taskId = input['task_id'] as String?;
              final taskPartId = taskId ?? toolCallId;

              LogTags.chatScreen.logInfo(
                '[TaskTrace] onTaskStart(task) WHAT=create TaskPart WHERE=streaming.onToolStart '
                'WHEN=${DateTime.now()} WHY=parent received task tool-call → build UI part '
                'taskId=$taskId toolCallId=$toolCallId taskPartId=$taskPartId '
                'agent=$agentName desc=$description sessionId=$sessionId',
              );
              notifier.onTaskStart(
                taskPartId,
                currentMessageId!,
                sessionId,
                description,
                agentName,
              );
              activeTaskSessionIds.add(taskPartId);
              taskToolToPart[toolCallId] = taskPartId;
            } else if (activeTaskSessionIds.isNotEmpty) {
              final toolTitle =
                  input['command'] as String? ??
                  input['query'] as String? ??
                  input['filePath'] as String? ??
                  input['path'] as String?;
              notifier.onTaskToolExecuted(
                activeTaskSessionIds.last,
                toolName,
                toolTitle,
              );
            }
          }

          scrollOnContentAdd();
          unawaited(runnerSession.onToolStart(toolCallId, toolName, input));
        },
        onToolEnd: (toolCallId, toolName, result) async {
          if (!processedToolEndCalls.add(toolCallId)) return;
          final resultStr = result.toString();

          if (toolName != 'question') {
            notifier.onToolEnd(toolCallId, toolName, resultStr);
          }

          if (toolName == 'task') {
            final id = taskToolToPart.remove(toolCallId) ??
                activeTaskSessionIds.firstOrNull;
            LogTags.chatScreen.logInfo(
              '[TaskTrace] onToolEnd(task) WHAT=finish TaskPart WHERE=streaming.onToolEnd '
              'WHEN=${DateTime.now()} WHY=parent task tool-call completed → mark part done '
              'toolCallId=$toolCallId resolvedId=$id '
              'remainingActive=${activeTaskSessionIds.length}',
            );
            if (id != null) {
              activeTaskSessionIds.remove(id);
              resolveTaskChildSession(id);
              notifier.onTaskEnd(id);
            }
          } else if (activeTaskSessionIds.isNotEmpty) {
            final toolInput = toolInputs[toolCallId];
            final title = toolInput != null
                ? (toolInput['command'] as String? ??
                      toolInput['query'] as String? ??
                      toolInput['filePath'] as String? ??
                      toolInput['path'] as String?)
                : null;
            notifier.onTaskToolExecuted(
              activeTaskSessionIds.last,
              toolName,
              title,
            );
          }

          if (toolName == 'question') {
            final parts = ref.read(chatScreenProvider).streamingParts;
            final openQuestion = parts
                .whereType<AssistantQuestion>()
                .where((p) => p.answer == null)
                .lastOrNull;
            if (openQuestion != null) {
              notifier.onQuestionEnd(openQuestion.id!, resultStr);
            }
            LogTags.chatScreen.logInfo(
              'onToolEnd(question): answer="$resultStr"',
            );
          }

          scrollOnContentAdd();
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

          notifier.onToolError(toolCallId, errorStr);

          if (activeTaskSessionIds.isNotEmpty) {
            final id = activeTaskSessionIds.last;
            resolveTaskChildSession(id);
            notifier.onTaskError(id, errorStr);
            unawaited(runnerSession.onTaskError(id, errorStr));
          }

          scrollOnContentAdd();
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
          currentMessageId ??= 'msg_${DateTime.now().microsecondsSinceEpoch}';
          pendingContent.write(content);
          unawaited(runnerSession.onChunk(content));
          throttleUpdate();
        },
        onReasoning: (reasoning) async {
          if (reasoning.isEmpty) return;
          currentMessageId ??= 'msg_${DateTime.now().microsecondsSinceEpoch}';
          pendingReasoning.write(reasoning);
          unawaited(runnerSession.onReasoning(reasoning));
          throttleUpdate();
        },
        maxSteps: maxSteps,
        onCompletion: (sdkText) async {
          flushPendingUpdates();
          if (!mounted || _streamCancelled) return;
          if (activeTaskSessionIds.isNotEmpty) {
            final ids = List<String>.from(activeTaskSessionIds);
            activeTaskSessionIds.clear();
            for (final id in ids) {
              resolveTaskChildSession(id);
              notifier.onTaskEnd(id);
              unawaited(runnerSession.onTaskEnd(id));
            }
          }
          notifier.setRetryInfo(
            isRetrying: false,
            retryMessage: null,
            retryAttempt: 0,
          );

          final accumulatedText = fullContent.toString();
          final accumulatedReasoning = fullReasoning.toString();
          unawaited(
            runnerSession.onCompletion(
              content: accumulatedText.isNotEmpty ? accumulatedText : sdkText,
              reasoning: accumulatedReasoning.isNotEmpty
                  ? accumulatedReasoning
                  : null,
              model: modelId,
              tokensInput: latestTokensInput ?? 0,
              tokensOutput: latestTokensOutput ?? 0,
              tokensCacheRead: latestTokensCacheRead ?? 0,
              tokensCacheWrite: latestTokensCacheWrite ?? 0,
            ),
          );

          final streamingParts = ref.read(chatScreenProvider).streamingParts;

          final textBuffer = StringBuffer();
          final reasoningBuffer = StringBuffer();
          for (final part in streamingParts) {
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
              chat.messages.isNotEmpty &&
              chat.messages.last.role == MessageRole.assistant &&
              !chat.messages.last.isComplete;

          final closedParts = notifier.snapshotClosedStreamingParts();
          final partsJson = closedParts.isNotEmpty
              ? assistantContentToPartMaps(closedParts)
              : null;

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
              partsJson: partsJson,
              tokensInput: latestTokensInput,
              tokensOutput: latestTokensOutput,
              contextLength: modelContextLength,
              agent: activeAgent,
            );
            newMessages = [...chat.messages, completedMessage];
          }
          final newChat = chat.copyWith(
            messages: newMessages,
            updatedAt: DateTime.now(),
          );
          LogTags.chatScreen.logInfo(
            'onCompletion: saving message id=${completedMessage.id}, partsCount=${streamingParts.length}',
          );
          notifier.finalizeStreaming();
          ref.read(chatListProvider.notifier).updateChat(newChat);
          holder.onChildToolEvent = null;
          await _chatStorageService.updateMessageInChat(
            newChat.id,
            completedMessage.id,
            completedMessage,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _chatInputFocusNode.requestFocus();
          });
          _showContinuationSuggestions(completedMessage);
        },
      );
    } catch (e) {
      // Close any still-running task parts BEFORE finalizing the stream, so
      // their spinners do not persist in the saved message (root cause of the
      // "spinner never disappears on cancel" bug).
      notifier.closeAllRunningTasks();
      activeTaskSessionIds.clear();
      notifier.finalizeStreaming();
      notifier.setRetryInfo(
        isRetrying: false,
        retryMessage: null,
        retryAttempt: 0,
      );
      holder.onChildToolEvent = null;
      if (_streamCancelled) return;
      unawaited(runnerSession.onError(e));
      await _handleStreamingError(e);
    } finally {
      toolInputs.clear();
      toolStartTimes.clear();
    }
  }

  Future<void> _handleStreamingError(Object error) async {
    LogTags.chatScreen.logError(
      '_handleStreamingError: type=${error.runtimeType} error=$error',
    );
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
