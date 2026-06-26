import 'dart:async';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:chatorai/core/context/completion_provider.dart';
import 'package:chatorai/core/context/overflow_detector.dart';
import 'package:chatorai/core/context/token_counter.dart';
import 'package:chatorai/core/error/error_classifier.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:dio/dio.dart';

import 'chat_cancellation.dart';
import 'chat_retry_service.dart';

// Tool event callbacks surfaced to the chat UI layer.
typedef ToolStartCallback =
    void Function(
      String toolCallId,
      String toolName,
      Map<String, dynamic> input,
    );

typedef ToolEndCallback =
    void Function(String toolCallId, String toolName, String result);

typedef ToolErrorCallback =
    void Function(String toolCallId, String toolName, String error);

typedef UsageCallback = void Function(int input, int output);

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
/// LanguageModel creation (OpenCode‑style). No legacy factory fallback.
class ChatAiService implements CompletionProvider {
  final ModelResolver _resolver;
  final Map<String, String> _headers;

  late final ChatRetryService _retryService;
  late final ChatCancellation _cancellation;
  final TokenCounter _tokenCounter = TokenCounter();
  late OverflowDetector _overflowDetector;
  int _modelContextLength = 200000;

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
    _tokenCounter.reset();
    for (final m in messages) {
      final content = m['content'];
      if (m['role'] == 'system') {
        if (content is String) _tokenCounter.addSystem(content);
      } else {
        if (content is String) _tokenCounter.addMessage(content);
      }
    }
    final estimated = _tokenCounter.totalTokens;
    _tokenCounter.reset();
    return estimated;
  }

  /// Delegates to [ChatRetryService.retryCountdown].
  Stream<double> get retryCountdown => _retryService.retryCountdown;

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
      final parts = <LanguageModelV3ContentPart>[];
      for (final part in content) {
        if (part is! Map) continue;
        switch (part['type'] as String?) {
          case 'text':
            final text = part['text'] as String?;
            if (text != null && text.isNotEmpty) {
              parts.add(LanguageModelV3TextPart(text: text));
            }
          case 'image_url':
            final imageUrl = part['image_url'];
            if (imageUrl is Map) {
              final url = imageUrl['url'] as String?;
              if (url != null && url.isNotEmpty) {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  parts.add(
                    LanguageModelV3ImagePart(image: DataContentUrl(uri)),
                  );
                }
              }
            }
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
  Future<void> streamChatCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
    required Function(String) onChunk,
    required Function(String) onReasoning,
    required Function(String) onCompletion,
    ToolSet tools = const {},
    ToolStartCallback? onToolStart,
    ToolEndCallback? onToolEnd,
    ToolErrorCallback? onToolError,
    UsageCallback? onUsage,
    int maxSteps = 5,
    void Function(RichRetryInfo info)? onRetry,
    void Function(List<Map<String, dynamic>> messages)? onOverflow,
  }) async {
    _currentModel = model;
    _currentTemperature = temperature;
    // Cancel any previous retry cycle before starting a new one
    cancelAllRequests();
    for (final m in messages) {
      final content = m['content'];
      if (m['role'] == 'system') {
        if (content is String) _tokenCounter.addSystem(content);
      } else {
        if (content is String) _tokenCounter.addMessage(content);
      }
    }

    // ── Build LanguageModel once (before retry loop) ──────────────────────
    ModelConfig? resolvedConfig;
    late LanguageModelV3 lm;
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
      rethrow;
    }

    try {
      await _retryService.execute(() async {
        LogTags.chatService.logDebug(
          'streamChatCompletion: calling streamText device=…',
        );
        final result = await streamText(
          model: lm,
          messages: _toModelMessages(messages),
          temperature: temperature,
          maxRetries: 0, // We handle retries ourselves
          headers: activeHeaders,
          abortSignal: _cancellation.token,
          tools: tools,
          maxSteps: maxSteps,
          onInputAvailable: (event) {
            final rawInput = event.input;
            final inputMap = rawInput is Map<String, dynamic>
                ? rawInput
                : <String, dynamic>{'raw': rawInput};
            onToolStart?.call(event.toolCallId, event.toolName, inputMap);
          },
        );
        LogTags.chatService.logDebug(
          'streamChatCompletion: streamText returned, consuming stream',
        );

        try {
          await for (final event in result.fullStream.handleError((
            Object error,
            StackTrace stack,
          ) {
            // DioException escapes ai_sdk_dart's internal streams before
            // reaching our await-for.  Swallow here so it never reaches
            // the zone handler.  The corresponding StreamTextErrorEvent
            // data event carries the same error and drives the retry.
            if (error is DioException) {
              LogTags.chatService.logDebug(
                'stream handleError swallowed DioException',
              );
              return;
            }
            throw error;
          })) {
            switch (event) {
              case StreamTextTextDeltaEvent(:final delta):
                onChunk(delta);
              case StreamTextReasoningDeltaEvent(:final delta):
                onReasoning(delta);
              case StreamTextToolResultEvent(
                :final toolResult,
                :final preliminary,
              ):
                LogTags.chatService.logDebug(
                  'streamChatCompletion: ToolResultEvent tool=${toolResult.toolName} '
                  'callId=${toolResult.toolCallId} preliminary=$preliminary',
                );
                if (!preliminary) {
                  final outputText = switch (toolResult.output) {
                    ToolResultOutputText(:final text) => text,
                    ToolResultOutputContent(:final parts) =>
                      parts.map((p) => p.toString()).join(),
                  };
                  LogTags.chatService.logInfo(
                    'streamChatCompletion: onToolEnd tool=${toolResult.toolName} '
                    'outputLen=${outputText.length}',
                  );
                  onToolEnd?.call(
                    toolResult.toolCallId,
                    toolResult.toolName,
                    outputText,
                  );
                }
              case StreamTextToolErrorEvent(
                :final toolCallId,
                :final toolName,
                :final error,
              ):
                onToolError?.call(toolCallId, toolName, error.toString());
              case StreamTextReasoningStartEvent():
                break;
              case StreamTextReasoningEndEvent():
                break;
              case StreamTextTextStartEvent():
                break;
              case StreamTextTextEndEvent():
                break;
              case StreamTextToolInputStartEvent():
                break;
              case StreamTextToolInputDeltaEvent():
                break;
              case StreamTextToolInputEndEvent():
                break;
              case StreamTextUsageEvent():
                break;
              case StreamTextSourceEvent():
                break;
              case StreamTextFileEvent():
                break;
              case StreamTextStartEvent():
                break;
              case StreamTextStartStepEvent():
                break;
              case StreamTextFinishStepEvent():
                break;
              case StreamTextRawEvent():
                break;
              case StreamTextErrorEvent(:final error):
                LogTags.chatService.logError(
                  'streamChatCompletion: StreamTextErrorEvent',
                  error,
                );
                throw error;
              case StreamTextFinishEvent(:final text, :final usage):
                _tokenCounter.recordUsage(
                  promptTokens: usage?.inputTokens,
                  completionTokens: usage?.outputTokens,
                );
                onUsage?.call(
                  usage?.inputTokens ?? 0,
                  usage?.outputTokens ?? 0,
                );
                onCompletion(text);
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
          rethrow;
        }
        return null;
      }, onRetry: onRetry);
    } catch (e, s) {
      LogTags.chatService.logError(
        'streamChatCompletion: unhandled error (should not happen with retry)',
        e,
        s,
      );

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
      _stopProgressTimer();
    }
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
    late LanguageModelV3 lm;
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

    try {
      final result = await _retryService.execute(() async {
        return generateText(
          model: lm,
          messages: _toModelMessages(messages),
          temperature: temperature,
          maxRetries: 0,
          headers: activeHeaders,
        );
      });
      return result.text;
    } finally {
      _stopProgressTimer();
    }
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

  void cancelAllRequests() {
    _retryService.cancelRetry();
    _cancellation.cancel();
  }

  /// Dispose resources.
  void dispose() {
    _cancellation.cancel();
  }
}
