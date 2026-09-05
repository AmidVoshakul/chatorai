import 'dart:async';
import 'dart:convert';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:chatorai/core/context/completion_provider.dart';
import 'package:chatorai/core/context/overflow_detector.dart';
import 'package:chatorai/core/context/token_counter.dart';
import 'package:chatorai/core/error/error_classifier.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/usage_cache_mapper.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:uuid/uuid.dart';

import 'chat_cancellation.dart';
import 'chat_retry_service.dart';
import 'tool_call_tracker.dart';

bool isGenerationStillValid(int generation, int currentGeneration) {
  return generation == currentGeneration;
}

// Tool event callbacks surfaced to the chat UI layer.
typedef ToolStartCallback =
    Future<void> Function(
      String toolCallId,
      String toolName,
      Map<String, dynamic> input,
    );

typedef ToolEndCallback =
    Future<void> Function(String toolCallId, String toolName, String result);

typedef ToolErrorCallback =
    Future<void> Function(String toolCallId, String toolName, String error);

typedef UsageCallback =
    void Function(
      int input,
      int output,
      int cacheRead,
      int cacheWrite,
      int reasoning,
      bool cacheIncludedInInput,
    );

class ChatCompletionResponse {
  final String content;
  final String? reasoning;
  final String? model;
  final int? usageInputTokens;
  final int? usageOutputTokens;
  final String? finishReason;

  const ChatCompletionResponse({
    required this.content,
    this.reasoning,
    this.model,
    this.usageInputTokens,
    this.usageOutputTokens,
    this.finishReason,
  });
}

/// Core AI service for streaming and non‑streaming chat completions.
///
/// Uses [ModelResolver] from the catalog for model resolution and
/// LanguageModel creation. No legacy factory fallback.
///
/// **Cancellation semantics:**
/// - Every call to [streamChatCompletion] increments a generation counter.
/// - [cancelAllRequests] increments the counter, invalidating old generations.
/// - The retry loop checks `isStillValid` against the captured generation,
///   so a cancelled or superseded request stops retrying immediately.
/// - A running‑request guard prevents concurrent [streamChatCompletion] calls;
///   a new call cancels the previous and waits for it to fully stop.
class ChatAiService implements CompletionProvider {
  final ModelResolver _resolver;
  final Map<String, String> _headers;

  ModelResolver get resolver => _resolver;

  late final ChatRetryService _retryService;
  late final ChatCancellation _cancellation;
  final TokenCounter _tokenCounter = TokenCounter();
  late OverflowDetector _overflowDetector;
  int _modelContextLength = 200000;

  int _generation = 0;
  bool _isRunning = false;
  Completer<void>? _stopCompleter;

  /// Whether a request is currently in progress.
  bool get isRunning => _isRunning;

  /// Create with catalog‑based resolution.
  ///
  /// [resolver] is the [ModelResolver] from the catalog.
  /// [headers] are optional extra headers merged on top of per‑provider
  /// default headers from the catalog.
  ChatAiService({
    required ModelResolver resolver,
    Map<String, String> headers = const {},
    int? modelContextLength,
  }) : _resolver = resolver,
       _headers = headers {
    _modelContextLength = modelContextLength ?? 200000;
    _overflowDetector = OverflowDetector.forModel(_modelContextLength);
    _cancellation = ChatCancellation();
    _retryService = ChatRetryService(cancellation: _cancellation);
  }

  void updateModelContextLength(int contextLength, {int? compactionBuffer}) {
    _modelContextLength = contextLength;
    _overflowDetector = OverflowDetector.forModel(
      contextLength,
      compactionBuffer: compactionBuffer,
    );
  }

  TokenCounter get tokenCounter => _tokenCounter;
  OverflowDetector get overflowDetector => _overflowDetector;
  int get totalTokens => _tokenCounter.totalTokens;
  bool get isOverflow =>
      _overflowDetector.isOverflow(_tokenCounter.totalTokens);

  /// Estimate token cost of a message list without mutating the running counter.
  /// Resets, estimates, captures total, resets again — leaves counter unchanged.
  int estimatePromptTokens(List<Map<String, dynamic>> messages) {
    final local = TokenCounter();
    for (final m in messages) {
      final content = m['content'];
      if (m['role'] == 'system') {
        if (content is String) local.addSystem(content);
      } else {
        if (content is String) local.addMessage(content);
      }
    }
    return local.totalTokens;
  }

  /// Delegates to [ChatRetryService.retryCountdown].
  Stream<double> get retryCountdown => _retryService.retryCountdown;

  /// Emits the latest retry message each time a backoff begins.
  Stream<String> get retryMessageStream => _retryService.retryMessageStream;

  /// Whether a retry backoff is currently in progress.
  bool get isRetrying => _retryService.isRetrying;

  String? _currentModel;
  String? get currentModel => _currentModel;
  set currentModelForTesting(String? model) {
    _currentModel = model;
  }

  double? _currentTemperature;
  double? get currentTemperature => _currentTemperature;
  set currentTemperatureForTesting(double? temp) {
    _currentTemperature = temp;
  }

  void _startProgressTimer() {
    // no-op; kept for compatibility
  }

  void _stopProgressTimer() {
    // no-op; kept for compatibility
  }

  void _completeStopCompleter() {
    final stopCompleter = _stopCompleter;
    _stopCompleter = null;
    if (stopCompleter != null && !stopCompleter.isCompleted) {
      stopCompleter.complete();
    }
  }

  Future<void> _handleStreamToolResult({
    required String prefix,
    required LanguageModelV4ToolResultPart toolResult,
    required bool preliminary,
    required Set<String> seenToolResults,
    required Future<void> Function(String, String, String)? onToolEnd,
    ToolCallTracker? toolTracker,
    String? toolCallId,
  }) async {
    LogTags.chatService.logDebug(
      '$prefix: ToolResultEvent tool=${toolResult.toolName} '
      'callId=${toolResult.toolCallId} preliminary=$preliminary',
    );
    if (!preliminary && !seenToolResults.contains(toolResult.toolCallId)) {
      seenToolResults.add(toolResult.toolCallId);
      toolTracker?.markEnded(toolCallId ?? toolResult.toolCallId);
      final outputText = switch (toolResult.output) {
        ToolResultOutputText(:final text) => text,
        ToolResultOutputContent(:final parts) =>
          parts.map((p) => p.toString()).join(),
      };
      LogTags.chatService.logInfo(
        '$prefix: onToolEnd tool=${toolResult.toolName} '
        'outputLen=${outputText.length}',
      );
      await onToolEnd?.call(
        toolResult.toolCallId,
        toolResult.toolName,
        outputText,
      );
    } else if (!preliminary &&
        seenToolResults.contains(toolResult.toolCallId)) {
      // The SDK can emit the same non-preliminary tool result twice
      // (e.g. once from the raw stream part and once from tool execution).
      // Dedup is already handled by `seenToolResults`; log at debug to avoid
      // noise in production logs.
      LogTags.chatService.logDebug(
        '$prefix: duplicate ToolResultEvent '
        'tool=${toolResult.toolName} callId=${toolResult.toolCallId}',
      );
    }
  }

  // ===========================================================================
  // DANGLING TOOL FINALIZATION
  // ===========================================================================

  /// Emits a terminal [onToolError] for every tool that received `onToolStart`
  /// but never a terminal `onToolEnd`/`onToolError`.
  ///
  /// This restores the invariant broken by the underlying `ai_sdk_dart`
  /// `streamText` step loop, which executes a step's tool calls sequentially
  /// and rethrows when one throws — leaving sibling calls after it unexecuted
  /// and without any terminal event. Without this, those tools stay in
  /// `ToolState.running` forever (infinite spinner in the UI).
  void _finalizeDanglingTools(
    ToolCallTracker tracker,
    ToolErrorCallback? onToolError,
  ) {
    if (!tracker.hasDangling) return;
    tracker.finalizeDangling((toolCallId, toolName) {
      LogTags.chatService.logWarning(
        'finalizeDanglingTools: tool $toolName ($toolCallId) never '
        'received a terminal event — marking as aborted',
      );
      unawaited(
        onToolError?.call(
          toolCallId,
          toolName,
          'Tool execution aborted before completion.',
        ),
      );
    });
  }

  // ===========================================================================
  // MESSAGE CONVERSION
  // ===========================================================================
  List<ModelMessage> _toModelMessages(List<Map<String, dynamic>> messages) {
    return [for (final m in messages) _toModelMessage(m)];
  }

  ModelMessage _toModelMessage(Map<String, dynamic> m) {
    final role = switch (m['role'] as String?) {
      'system' => ModelMessageRole.system,
      'assistant' => ModelMessageRole.assistant,
      'tool' => ModelMessageRole.tool,
      _ => ModelMessageRole.user,
    };
    final content = m['content'];
    if (content is String) {
      return ModelMessage(role: role, content: content);
    }
    if (content is List) {
      final parts = <LanguageModelV4ContentPart>[];
      for (final part in content) {
        if (part is! Map) continue;
        switch (part['type'] as String?) {
          case 'text':
            final text = part['text'] as String?;
            if (text != null && text.isNotEmpty) {
              parts.add(LanguageModelV4TextPart(text: text));
            }
          case 'image_url':
            final imageUrl = part['image_url'];
            if (imageUrl is Map) {
              final url = imageUrl['url'] as String?;
              if (url != null && url.isNotEmpty) {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  parts.add(
                    LanguageModelV4ImagePart(image: DataContentUrl(uri)),
                  );
                }
              }
            }
          case 'tool_result':
            final rawToolCallId =
                part['tool_call_id'] as String? ??
                part['tool_callId'] as String?;
            final toolName =
                part['tool_name'] as String? ??
                part['toolName'] as String? ??
                '';
            // A missing tool_call_id must NOT collapse to '' — downstream dedup
            // keys tool results by `toolCallId` (seenToolResults Set), so '' would
            // merge every result without an id into a single entry and drop the
            // rest. Generate a unique id instead so each result is preserved.
            final toolCallId = rawToolCallId != null && rawToolCallId.isNotEmpty
                ? rawToolCallId
                : const Uuid().v4();
            if (rawToolCallId == null || rawToolCallId.isEmpty) {
              LogTags.chatService.logWarning(
                'tool_result without tool_call_id — generated unique id '
                '$toolCallId (toolName=$toolName)',
              );
            }
            final text = part['text'] as String? ?? '';
            parts.add(
              LanguageModelV4ToolResultPart(
                toolCallId: toolCallId,
                toolName: toolName,
                output: ToolResultOutputText(text),
              ),
            );
          default:
            break;
        }
      }
      if (parts.isEmpty) {
        return ModelMessage(role: role, content: '');
      }
      return ModelMessage.parts(role: role, parts: parts);
    }
    return ModelMessage(role: role, content: '');
  }

  // ===========================================================================
  // STREAMING
  // ===========================================================================
  /// Runs a chat completion with generation‑scoped cancellation.
  ///
  /// If another request is already running, this cancels it and waits for it
  /// to fully stop before proceeding (prevents overlapping state updates).
  Future<void> streamChatCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
    required Future<void> Function(String) onChunk,
    required Future<void> Function(String) onReasoning,
    Future<void> Function()? onReasoningEnd,
    required Future<void> Function(String) onCompletion,
    ToolSet tools = const {},
    ToolStartCallback? onToolStart,
    ToolEndCallback? onToolEnd,
    ToolErrorCallback? onToolError,
    UsageCallback? onUsage,
    int maxSteps = 5,
    void Function(RichRetryInfo info)? onRetry,
    void Function(List<Map<String, dynamic>> messages)? onOverflow,
    String? sessionId,
  }) async {
    // ── Running‑request guard ──────────────────────────────────────────
    if (_isRunning) {
      cancelAllRequests();
      await _stopCompleter?.future;
    }

    _isRunning = true;
    final requestStopCompleter = Completer<void>();
    _stopCompleter = requestStopCompleter;
    _currentModel = model;
    _currentTemperature = temperature;
    final gen = ++_generation;
    final toolTracker = ToolCallTracker();

    // ── Build LanguageModel once (before retry loop) ──────────────────────
    ModelConfig? resolvedConfig;
    late LanguageModelV4 lm;
    Map<String, String> activeHeaders = _headers;

    try {
      resolvedConfig = _resolver.resolve(model);
      activeHeaders = _resolver.getHeadersForModel(
        resolvedConfig,
        overrideHeaders: _headers,
      );
      lm = await _resolver.buildLanguageModel(resolvedConfig);
      LogTags.chatService.logDebug(
        'streamChatCompletion: catalog model ${resolvedConfig.id}',
      );
    } catch (e) {
      LogTags.chatService.logError(
        'streamChatCompletion: resolver failed for $model',
        e,
      );
      _isRunning = false;
      _completeStopCompleter();
      rethrow;
    }

    // Provider-declared defaults from chatorai.json (temperature / extra body).
    final providerParams = _providerCallParams(resolvedConfig);
    final providerTemp = providerParams.temperature;
    final providerOptions = providerParams.providerOptions;

    try {
      await _retryService.execute(
        ({void Function()? onChunkReceived}) async {
          final seenToolResults = <String>{};
          var completionHandled = false;
          LogTags.chatService.logDebug(
            'streamChatCompletion: calling streamText device=…',
          );
          final result = await streamText(
            model: lm,
            messages: _toModelMessages(messages),
            temperature: providerTemp ?? temperature,
            maxRetries: 0, // We handle retries ourselves
            headers: activeHeaders,
            providerOptions: providerOptions,
            abortSignal: _cancellation.token,
            tools: tools,
            maxSteps: maxSteps,
            includeRawChunks: true,
            runtimeContext: sessionId == null
                ? null
                : {'sessionId': sessionId, 'agentId': 'main'},
            onInputAvailable: (event) async {
              if (!isGenerationStillValid(gen, _generation)) return;
              final rawInput = event.input;
              final inputMap = rawInput is Map<String, dynamic>
                  ? rawInput
                  : <String, dynamic>{'raw': rawInput};
              toolTracker.markStarted(
                event.toolCallId,
                event.toolName,
                DateTime.now(),
              );
              await onToolStart?.call(
                event.toolCallId,
                event.toolName,
                inputMap,
              );
            },
          );
          LogTags.chatService.logDebug(
            'streamChatCompletion: streamText returned, consuming stream',
          );

          try {
            final capturedRawUsage = <String, dynamic>{};
            await for (final event in result.fullStream.handleError((
              Object error,
              StackTrace stack,
            ) {
              if (error is DioException || error is AiApiCallError) {
                LogTags.chatService.logDebug(
                  'streamChatCompletion: stream handleError swallowed transport error',
                );
                return;
              }
              throw error;
            })) {
              switch (event) {
                case StreamTextTextDeltaEvent(:final delta):
                  if (!isGenerationStillValid(gen, _generation)) return;
                  onChunkReceived?.call();
                  await onChunk(delta);
                case StreamTextReasoningDeltaEvent(:final delta):
                  if (!isGenerationStillValid(gen, _generation)) return;
                  onChunkReceived?.call();
                  await onReasoning(delta);
                case StreamTextToolResultEvent(
                  :final toolResult,
                  :final preliminary,
                ):
                  if (!isGenerationStillValid(gen, _generation)) return;
                  onChunkReceived?.call();
                  await _handleStreamToolResult(
                    prefix: 'streamChatCompletion',
                    toolResult: toolResult,
                    preliminary: preliminary,
                    seenToolResults: seenToolResults,
                    onToolEnd: onToolEnd,
                    toolTracker: toolTracker,
                    toolCallId: toolResult.toolCallId,
                  );
                case StreamTextToolErrorEvent(
                  :final toolCallId,
                  :final toolName,
                  :final error,
                ):
                  if (!isGenerationStillValid(gen, _generation)) return;
                  onChunkReceived?.call();
                  if (!seenToolResults.contains(toolCallId)) {
                    seenToolResults.add(toolCallId);
                    toolTracker.markErrored(toolCallId);
                    await onToolError?.call(
                      toolCallId,
                      toolName,
                      error.toString(),
                    );
                  }
                case StreamTextReasoningStartEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextReasoningEndEvent():
                  if (!isGenerationStillValid(gen, _generation)) return;
                  onChunkReceived?.call();
                  await onReasoningEnd?.call();
                  break;
                case StreamTextTextStartEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextTextEndEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextToolInputStartEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextToolInputDeltaEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextToolInputEndEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextUsageEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextSourceEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextFileEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextStartEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextStartStepEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextFinishStepEvent():
                  onChunkReceived?.call();
                  break;
                case StreamTextRawEvent(:final rawValue):
                  if (rawValue is Map<String, dynamic> &&
                      rawValue['usage'] is Map) {
                    capturedRawUsage
                      ..clear()
                      ..addAll(rawValue['usage'] as Map<String, dynamic>);
                  }
                  break;
                case StreamTextErrorEvent(:final error):
                  LogTags.chatService.logError(
                    'streamChatCompletion: StreamTextErrorEvent',
                    error,
                  );
                  if (error is AiNoSuchToolError) {
                    if (!isGenerationStillValid(gen, _generation)) return;
                    final toolName = _extractToolName(error.message);
                    final syntheticCallId =
                        'hallucinated_${DateTime.now().microsecondsSinceEpoch}';
                    onToolStart?.call(syntheticCallId, toolName, {});
                    onToolError?.call(syntheticCallId, toolName, error.message);
                    try {
                      await onCompletion('');
                    } catch (e) {
                      LogTags.chatService.logError(
                        'streamChatCompletion: onCompletion failed after AiNoSuchToolError',
                        e,
                      );
                    }
                    return;
                  }
                  throw error;
                case StreamTextFinishEvent(:final text, :final usage):
                  if (completionHandled) return;
                  if (!isGenerationStillValid(gen, _generation)) return;
                  onChunkReceived?.call();
                  completionHandled = true;
                  _finalizeDanglingTools(toolTracker, onToolError);
                  final resolved = resolveUsage(usage, capturedRawUsage);
                  LogTags.chatService.logDebug(
                    'streamChatCompletion: raw usage=${jsonEncode(capturedRawUsage.isNotEmpty ? capturedRawUsage : const <String, dynamic>{})}',
                  );
                  _tokenCounter.recordUsage(
                    promptTokens: resolved['inputTotal'],
                    completionTokens: resolved['outputTotal'],
                    cacheReadTokens: resolved['cacheRead'],
                    cacheWriteTokens: resolved['cacheWrite'],
                  );
                  onUsage?.call(
                    resolved['inputTotal'] ?? 0,
                    resolved['outputTotal'] ?? 0,
                    resolved['cacheRead'] ?? 0,
                    resolved['cacheWrite'] ?? 0,
                    resolved['reasoning'] ?? 0,
                    resolved['cacheIncludedInInput'] == true,
                  );
                  await onCompletion(text);
                  if (_overflowDetector.isOverflow(_tokenCounter.totalTokens)) {
                    onOverflow?.call(messages);
                  }
              }
            }
            LogTags.chatService.logDebug(
              'streamChatCompletion: stream consumed successfully',
            );
          } catch (e, s) {
            LogTags.chatService.logError(
              'streamChatCompletion: stream iteration threw (will propagate to retry)',
              e,
              s,
            );
            if (isGenerationStillValid(gen, _generation)) {
              _finalizeDanglingTools(toolTracker, onToolError);
            }
            rethrow;
          }
          return null;
        },
        onRetry: onRetry,
        isStillValid: () => gen == _generation,
      );
    } catch (e, s) {
      LogTags.chatService.logError(
        'streamChatCompletion: unhandled error (should not happen with retry)',
        e,
        s,
      );

      if (isGenerationStillValid(gen, _generation)) {
        _finalizeDanglingTools(toolTracker, onToolError);
      }

      // Route context overflow to compaction instead of failing silently
      final classified = ErrorClassifier().classify(e);
      if (classified is OverflowError) {
        LogTags.chatService.logWarning(
          'streamChatCompletion: overflow detected, routing to compaction',
        );
        onOverflow?.call(messages);
      }

      rethrow;
    } finally {
      if (gen == _generation) {
        _isRunning = false;
      }
      if (identical(_stopCompleter, requestStopCompleter)) {
        _completeStopCompleter();
      }
      _stopProgressTimer();
    }
  }

  // ===========================================================================
  // CHILD COMPLETION (no re‑entrancy guard)
  // ===========================================================================
  /// Runs an independent LLM completion for a task‑tool sub‑agent.
  ///
  /// Unlike [streamChatCompletion], this method does **not** check
  /// `_isRunning` and does **not** call `cancelAllRequests()`, so a child
  /// agent can safely run its own LLM cycle while the parent stream is still
  /// active. Uses the shared [retry] service so parent cancel stops child too.
  Future<void> runChildCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
    required Future<void> Function(String) onChunk,
    required Future<void> Function(String) onReasoning,
    Future<void> Function()? onReasoningEnd,
    required Future<void> Function(String) onCompletion,
    ToolSet tools = const {},
    ToolStartCallback? onToolStart,
    ToolEndCallback? onToolEnd,
    ToolErrorCallback? onToolError,
    UsageCallback? onUsage,
    int maxSteps = 5,
    String? sessionId,
    CancellationToken? abortSignal,
  }) async {
    // Bind the child to the parent task's abort signal when provided, so
    // cancelling the parent request also stops the delegated sub-agent.
    // Falls back to the shared service token otherwise.
    final effectiveAbort = abortSignal ?? _cancellation.token;
    ModelConfig? resolvedConfig;
    late LanguageModelV4 lm;
    Map<String, String> activeHeaders = _headers;

    try {
      resolvedConfig = _resolver.resolve(model);
      activeHeaders = _resolver.getHeadersForModel(
        resolvedConfig,
        overrideHeaders: _headers,
      );
      lm = await _resolver.buildLanguageModel(resolvedConfig);
    } catch (e) {
      rethrow;
    }

    final providerParams = _providerCallParams(resolvedConfig);
    final providerTemp = providerParams.temperature;
    final providerOptions = providerParams.providerOptions;

    try {
      await _retryService.execute(({void Function()? onChunkReceived}) async {
        final seenToolResults = <String>{};
        final toolTracker = ToolCallTracker();
        LogTags.chatService.logDebug(
          'runChildCompletion: calling streamText device=…',
        );
        final result = await streamText(
          model: lm,
          messages: _toModelMessages(messages),
          temperature: providerTemp ?? temperature,
          maxRetries: 0, // We handle retries ourselves
          headers: activeHeaders,
          providerOptions: providerOptions,
          abortSignal: effectiveAbort,
          tools: tools,
          maxSteps: maxSteps,
          includeRawChunks: true,
          runtimeContext: sessionId == null
              ? null
              : {'sessionId': sessionId, 'agentId': 'subagent'},
          onInputAvailable: (event) {
            final rawInput = event.input;
            final inputMap = rawInput is Map<String, dynamic>
                ? rawInput
                : <String, dynamic>{'raw': rawInput};
            toolTracker.markStarted(
              event.toolCallId,
              event.toolName,
              DateTime.now(),
            );
            onToolStart?.call(event.toolCallId, event.toolName, inputMap);
          },
        );
        LogTags.chatService.logDebug(
          'runChildCompletion: streamText returned, consuming stream',
        );

        try {
          final capturedRawUsage = <String, dynamic>{};
          await for (final event in result.fullStream.handleError((
            Object error,
            StackTrace stack,
          ) {
            if (error is DioException || error is AiApiCallError) return;
            throw error;
          })) {
            switch (event) {
              case StreamTextTextDeltaEvent(:final delta):
                onChunkReceived?.call();
                await onChunk(delta);
              case StreamTextReasoningDeltaEvent(:final delta):
                onChunkReceived?.call();
                await onReasoning(delta);
              case StreamTextToolResultEvent(
                :final toolResult,
                :final preliminary,
              ):
                onChunkReceived?.call();
                await _handleStreamToolResult(
                  prefix: 'runChildCompletion',
                  toolResult: toolResult,
                  preliminary: preliminary,
                  seenToolResults: seenToolResults,
                  onToolEnd: onToolEnd,
                  toolTracker: toolTracker,
                  toolCallId: toolResult.toolCallId,
                );
              case StreamTextToolErrorEvent(
                :final toolCallId,
                :final toolName,
                :final error,
              ):
                onChunkReceived?.call();
                if (!seenToolResults.contains(toolCallId)) {
                  seenToolResults.add(toolCallId);
                  toolTracker.markErrored(toolCallId);
                  await onToolError?.call(
                    toolCallId,
                    toolName,
                    error.toString(),
                  );
                }
              case StreamTextErrorEvent(:final error):
                LogTags.chatService.logError(
                  'runChildCompletion: StreamTextErrorEvent',
                  error,
                );
                if (error is AiNoSuchToolError) {
                  final toolName = _extractToolName(error.message);
                  final syntheticCallId =
                      'hallucinated_${DateTime.now().microsecondsSinceEpoch}';
                  onToolStart?.call(syntheticCallId, toolName, {});
                  onToolError?.call(syntheticCallId, toolName, error.message);
                  // Gracefully finalize — don't throw to avoid retry duplication.
                  await onCompletion('');
                } else {
                  throw error;
                }
              case StreamTextReasoningEndEvent():
                onChunkReceived?.call();
                await onReasoningEnd?.call();
                break;
              case StreamTextRawEvent(:final rawValue):
                if (rawValue is Map<String, dynamic> &&
                    rawValue['usage'] is Map) {
                  capturedRawUsage
                    ..clear()
                    ..addAll(rawValue['usage'] as Map<String, dynamic>);
                }
                break;
              case StreamTextFinishEvent(:final text, :final usage):
                onChunkReceived?.call();
                _finalizeDanglingTools(toolTracker, onToolError);
                final resolved = resolveUsage(usage, capturedRawUsage);
                LogTags.chatService.logDebug(
                  'runChildCompletion: raw usage=${jsonEncode(capturedRawUsage.isNotEmpty ? capturedRawUsage : const <String, dynamic>{})}',
                );
                onUsage?.call(
                  resolved['inputTotal'] ?? 0,
                  resolved['outputTotal'] ?? 0,
                  resolved['cacheRead'] ?? 0,
                  resolved['cacheWrite'] ?? 0,
                  resolved['reasoning'] ?? 0,
                  resolved['cacheIncludedInInput'] == true,
                );
                await onCompletion(text);
              default:
                onChunkReceived?.call();
                break;
            }
          }
        } catch (_) {
          _finalizeDanglingTools(toolTracker, onToolError);
          rethrow;
        }
      });
    } catch (_) {
      rethrow;
    }
  }

  /// Streams a delegated subagent completion into [child], wiring the standard
  /// child-session callbacks: chunk/reasoning passthrough, tool lifecycle
  /// (tool-start forwards an optional live title to [onChildToolTitle]), usage
  /// accounting and completion persistence on the child session.
  ///
  /// Both delegation entry points — the parent-driven `task` tool and a
  /// user-invoked slash-command subtask — share this wiring, so callback
  /// behavior can never drift between them.
  Future<void> runSubagentCompletion({
    required SessionRunnerSession child,
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
    required String sessionId,
    required ToolSet tools,
    required int maxSteps,
    CancellationToken? abortSignal,
    void Function(
      int tokensInput,
      int tokensOutput,
      int tokensCacheRead,
      int tokensCacheWrite,
      int tokensReasoning,
    )?
    onUsage,
    void Function(String childSessionId, String toolName, String? title)?
    onChildToolTitle,
  }) {
    var lastTokensInput = 0;
    var lastTokensOutput = 0;
    var lastTokensCacheRead = 0;
    var lastTokensCacheWrite = 0;
    var lastTokensReasoning = 0;
    return runChildCompletion(
      messages: messages,
      model: model,
      temperature: temperature,
      sessionId: sessionId,
      tools: tools,
      maxSteps: maxSteps,
      abortSignal: abortSignal,
      onUsage: (input, output, cacheRead, cacheWrite, reasoning, _) {
        lastTokensInput = input;
        lastTokensOutput = output;
        lastTokensCacheRead = cacheRead;
        lastTokensCacheWrite = cacheWrite;
        lastTokensReasoning = reasoning;
        onUsage?.call(
          lastTokensInput,
          lastTokensOutput,
          lastTokensCacheRead,
          lastTokensCacheWrite,
          lastTokensReasoning,
        );
      },
      onChunk: child.onChunk,
      onReasoning: child.onReasoning,
      onReasoningEnd: child.onReasoningEnd,
      onToolStart: (toolCallId, toolName, input) async {
        await child.onToolStart(toolCallId, toolName, input);
        final title =
            input['command'] as String? ??
            input['query'] as String? ??
            input['filePath'] as String? ??
            input['path'] as String?;
        onChildToolTitle?.call(child.sessionId.value, toolName, title);
      },
      onToolEnd: (toolCallId, toolName, result) async {
        await child.onToolEnd(toolCallId, toolName, result);
      },
      onToolError: (toolCallId, toolName, error) async {
        // Mark the tool as failed WITHOUT finalizing the child session, so
        // the subagent can recover and continue after a tool error.
        await child.onToolError(toolCallId, toolName, error);
      },
      onCompletion: (content) => child.onCompletion(
        content: content,
        reasoning: null,
        model: model,
        tokensInput: lastTokensInput,
        tokensOutput: lastTokensOutput,
        tokensCacheRead: lastTokensCacheRead,
        tokensCacheWrite: lastTokensCacheWrite,
        tokensReasoning: lastTokensReasoning,
      ),
    );
  }

  // ===========================================================================
  // NON-STREAMING COMPLETION
  // ===========================================================================
  @override
  Future<String> generateCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
  }) async {
    _startProgressTimer();

    // ── Build LanguageModel once (before retry loop) ──────────────────────
    ModelConfig? resolvedConfig;
    late LanguageModelV4 lm;
    Map<String, String> activeHeaders = _headers;

    try {
      resolvedConfig = _resolver.resolve(model);
      activeHeaders = _resolver.getHeadersForModel(
        resolvedConfig,
        overrideHeaders: _headers,
      );
      lm = await _resolver.buildLanguageModel(resolvedConfig);
    } catch (e) {
      LogTags.chatService.logError(
        'generateCompletion: resolver failed for $model',
        e,
      );
      rethrow;
    }

    final providerParams = _providerCallParams(resolvedConfig);
    final providerTemp = providerParams.temperature;
    final providerOptions = providerParams.providerOptions;

    try {
      final gen = _generation;
      final result = await _retryService.execute(({
        void Function()? onChunkReceived,
      }) async {
        if (gen != _generation) throw Exception('cancelled');
        return generateText(
          model: lm,
          messages: _toModelMessages(messages),
          temperature: providerTemp ?? temperature,
          maxRetries: 0,
          headers: activeHeaders,
          providerOptions: providerOptions,
        );
      }, isStillValid: () => gen == _generation);
      return result.text;
    } finally {
      _stopProgressTimer();
    }
  }

  // ===========================================================================
  // TITLE GENERATION
  // ===========================================================================

  /// Generates a concise session title from the first user message.
  ///
  /// Falls back to a truncated version of the user message when the model
  /// yields no usable title. This is a best-effort, fire-and-forget operation
  /// and must never throw.
  Future<String> generateSessionTitle({
    required String modelId,
    required String userMessage,
  }) async {
    try {
      final text = await generateCompletion(
        messages: [
          {
            'role': 'user',
            'content':
                'Generate a short conversation title (max 60 characters) for this user message. '
                'Reply with ONLY the title: no markdown, no quotes, no numbering, no explanations.\n'
                'User message: $userMessage',
          },
        ],
        model: modelId,
        temperature: 0.5,
      );
      final cleaned = _cleanSessionTitle(text);
      if (cleaned.isNotEmpty) return cleaned;
    } catch (_) {
      // Fall through to the user-message fallback.
    }
    return _truncateTitle(userMessage);
  }

  /// Truncates a title to at most 60 characters, keeping whole words.
  String _truncateTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.length <= 60) return trimmed;
    final cut = trimmed.substring(0, 57);
    final lastSpace = cut.lastIndexOf(' ');
    return lastSpace > 0 ? '${cut.substring(0, lastSpace)}...' : '$cut...';
  }

  /// Strips markdown formatting, template boilerplate and option lists from the
  /// model's title response, keeping only the first meaningful line.
  String _cleanSessionTitle(String text) {
    final withoutThink = text.replaceAll(
      RegExp(r'<think>[\s\S]*?<\/think>\s*'),
      '',
    );

    // Normalize bullet/numbered lists and markdown headings into plain lines.
    final lines = withoutThink
        .split('\n')
        .map((line) {
          var l = line.trim();
          // Strip leading markdown heading markers and list bullets.
          l = l.replaceFirst(RegExp(r'^#{1,6}\s*'), '');
          l = l.replaceFirst(RegExp(r'^[-*+]\s+'), '');
          l = l.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');
          // Strip common wrappers ("Title:", "Here are some options:", etc.).
          l = l.replaceFirst(
            RegExp(
              r'^(title|conversation title|chat title):\s*',
              caseSensitive: false,
            ),
            '',
          );
          return l;
        })
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return '';

    // Prefer the first non-template line: skip placeholder-looking lines that
    // describe the prompt itself (e.g. "Primary Versatile Title (works across
    // most use cases, ...)"-style boilerplate).
    String? picked;
    for (final line in lines) {
      final lower = line.toLowerCase();
      final isBoilerplate =
          lower.contains('versatile title') ||
          lower.contains('primary title') ||
          lower.contains('here are') ||
          lower.contains('some options') ||
          lower.contains('title options') ||
          lower.contains('works across most') ||
          lower.startsWith('example') ||
          lower.contains('use cases') && lower.length > 40;
      if (isBoilerplate) continue;
      picked = line;
      break;
    }
    final cleaned = (picked ?? lines.first).trim();
    if (cleaned.isEmpty) return '';
    return _truncateTitle(cleaned);
  }

  // ===========================================================================
  // UTILITIES
  // ===========================================================================
  List<Map<String, dynamic>> sanitizeMessages(
    List<Map<String, dynamic>> messages,
  ) {
    return messages.where((m) {
      final content = m['content'];
      if (content is String) return content.trim().isNotEmpty;
      if (content is List) return content.isNotEmpty;
      return false;
    }).toList();
  }

  /// Extract hallucinated tool name from AiNoSuchToolError message.
  ///
  /// Format: `"Step 0 called unknown tool \"folder_read\""` → `folder_read`
  static String _extractToolName(String message) {
    final match = RegExp(r'"([^"]+)"').firstMatch(message);
    return match?.group(1) ?? 'unknown';
  }

  /// Cancels all in‑flight requests and increments the generation counter.
  ///
  /// Any retry loop still running with an older generation will abort on its
  /// next `isStillValid` check. The cancellation token is also cancelled so
  /// the underlying HTTP request (if still in flight) can be aborted.
  void cancelAllRequests() {
    _generation++;
    _retryService.cancelRetry();
    _cancellation.cancel();
  }

  /// The current active cancellation token.
  CancellationToken get currentToken => _cancellation.token;

  /// Whether the current token has been cancelled.
  bool get isCancelled => _cancellation.isCancelled;

  /// Dispose resources.
  void dispose() {
    _cancellation.cancel();
    _retryService.dispose();
  }

  /// Resolves usage values from the finish event, preferring captured raw
  /// usage (from `StreamPartRaw` with `includeRawChunks: true`) over the
  /// SDK-bucketed `usage` on the finish event.
  ///
  /// Returns a map with keys: `inputTotal`, `outputTotal`, `cacheRead`,
  /// `cacheWrite`, `reasoning`, `cacheIncludedInInput`.
  Map<String, dynamic> resolveUsage(
    LanguageModelV4Usage? usage,
    Map<String, dynamic>? capturedRawUsage,
  ) {
    final raw = capturedRawUsage;
    if (raw != null && raw.isNotEmpty) {
      final rawData = extractUsageRawData(raw);
      return {
        'inputTotal': rawData.inputTotal,
        'outputTotal': rawData.outputTotal,
        'cacheRead': rawData.cacheRead,
        'cacheWrite': rawData.cacheWrite,
        'reasoning': rawData.reasoning,
        'cacheIncludedInInput': rawData.cacheIncludedInInput,
      };
    }
    final sdkCacheRead = usage?.inputTokens.cacheRead;
    final sdkCacheWrite = usage?.inputTokens.cacheWrite;
    final sdkReasoning = usage?.outputTokens.reasoning;
    final cache = usage != null
        ? extractCacheTokens(usage.raw)
        : const UsageCacheTokens();
    return {
      'inputTotal': usage?.inputTokens.total ?? 0,
      'outputTotal': usage?.outputTokens.total ?? 0,
      'cacheRead': (sdkCacheRead != null && sdkCacheRead > 0)
          ? sdkCacheRead
          : cache.read,
      'cacheWrite': (sdkCacheWrite != null && sdkCacheWrite > 0)
          ? sdkCacheWrite
          : cache.write,
      'reasoning': (sdkReasoning != null && sdkReasoning > 0)
          ? sdkReasoning
          : extractReasoningTokens(usage?.raw),
      'cacheIncludedInInput': usage != null
          ? extractUsageRawData(usage.raw).cacheIncludedInInput
          : false,
    };
  }

  /// Resolves provider-declared defaults from `chatorai.json` for a model call.
  ///
  /// Returns the effective sampling temperature (from the provider's
  /// `defaultBody['temperature']`) and the extra body fields (everything in
  /// `defaultBody` except `temperature`) wrapped under the provider's SDK key
  /// for forwarding as `providerOptions`. Either component may be `null`.
  ({double? temperature, Map<String, Map<String, dynamic>>? providerOptions})
  _providerCallParams(ModelConfig model) {
    final provider = _resolver.getProviderForModelConfig(model);
    final body = provider.defaultBody;
    if (body == null || body.isEmpty) {
      return (temperature: null, providerOptions: null);
    }
    final temperature = body['temperature'] is num
        ? (body['temperature'] as num).toDouble()
        : null;
    final extra = Map<String, dynamic>.from(body)
      ..removeWhere((k, _) => k == 'temperature');
    final providerOptions = extra.isNotEmpty ? {provider.sdk: extra} : null;
    return (temperature: temperature, providerOptions: providerOptions);
  }
}
