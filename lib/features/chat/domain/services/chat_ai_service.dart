import 'dart:async';
import 'dart:math';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:chatorai/core/context/overflow_detector.dart';
import 'package:chatorai/core/context/token_counter.dart';
import 'package:chatorai/core/error/error_classifier.dart';
import 'package:chatorai/shared/utils/logger.dart';

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

/// A function that creates a [LanguageModelV3] for the given model string.
typedef ModelFactory = LanguageModelV3 Function(String model);

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

class ChatAiService {
  final ModelFactory _modelFactory;
  final Map<String, String> _headers;
  var _cancelToken = CancellationToken();
  Timer? _progressTimer;
  final _retryController = StreamController<double>.broadcast();
  bool _retryCancelled = false;
  final TokenCounter _tokenCounter = TokenCounter();
  late OverflowDetector _overflowDetector;
  int _modelContextLength = 200000;

  ChatAiService({
    required ModelFactory modelFactory,
    Map<String, String> headers = const {},
    int? modelContextLength,
  }) : _modelFactory = modelFactory,
       _headers = headers {
    _modelContextLength = modelContextLength ?? 200000;
    _overflowDetector = OverflowDetector.forModel(_modelContextLength);
  }

  void updateModelContextLength(int contextLength) {
    _modelContextLength = contextLength;
    _overflowDetector = OverflowDetector.forModel(contextLength);
  }

  StreamController<double> get _ensureRetryController => _retryController;

  /// Strips the provider prefix from a model ID.
  /// Model IDs follow the format `{providerId}/{actualModelId}`.
  /// Example: `openrouter/openrouter/owl-alpha` → `openrouter/owl-alpha`
  ///          `openai/gpt-4o` → `openai/gpt-4o` (unchanged, no prefix)
  static String stripProviderPrefix(String modelId) {
    final firstSlash = modelId.indexOf('/');
    if (firstSlash == -1) return modelId;
    final afterFirstSlash = modelId.substring(firstSlash + 1);
    if (afterFirstSlash.contains('/')) return afterFirstSlash;
    return modelId;
  }

  TokenCounter get tokenCounter => _tokenCounter;
  OverflowDetector get overflowDetector => _overflowDetector;
  int get totalTokens => _tokenCounter.totalTokens;
  bool get isOverflow =>
      _overflowDetector.isOverflow(_tokenCounter.totalTokens);

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {});
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  // ===========================================================================
  // RETRY (OpenCode-style unbounded exponential backoff)
  // ===========================================================================
  static const _retryBaseDelay = Duration(milliseconds: 500);
  static const _retryMaxDelay = Duration(seconds: 30);
  static const _retryFactor = 1.5;

  bool _isRetrying = false;
  bool get isRetrying => _isRetrying;

  Duration? _lastRetryAfter;

  /// Stream of retry progress: 1.0 → 0.0 during backoff wait.
  /// Emits 1.0 immediately when retry starts, counts down to 0.0.
  /// Cancels when user calls [cancelAllRequests()] or stream completes.
  Stream<double> get retryCountdown => _ensureRetryController.stream;

  /// Wraps [operation] with OpenCode-style unbounded exponential backoff retry.
  /// Retries on transient errors forever until success or cancellation.
  /// Emits progress via [retryCountdown] stream during backoff waits.
  /// [onRetry] is called before each retry attempt (not before the first attempt).
  Future<T> _retry<T>(
    Future<T> Function() operation, {
    Duration? baseDelay,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    _retryCancelled = false;
    final delay = baseDelay ?? _retryBaseDelay;
    final rng = Random();
    int attempt = 0;
    while (true) {
      try {
        LogTags.chatService.logDebug('_retry attempt $attempt starting');
        final result = await operation();
        LogTags.chatService.logDebug('_retry attempt $attempt succeeded');
        return result;
      } catch (e) {
        LogTags.chatService.logWarning(
          '_retry attempt $attempt caught: ${e.runtimeType}: $e',
        );
        if (!_isRetryableError(e)) {
          LogTags.chatService.logWarning(
            '_retry attempt $attempt: error NOT retryable, rethrowing',
          );
          rethrow;
        }
        if (_retryCancelled || _cancelToken.isCancelled) {
          LogTags.chatService.logWarning(
            '_retry attempt $attempt: cancelled, aborting',
          );
          _isRetrying = false;
          throw Exception('cancelled');
        }
        _stopProgressTimer();
        _isRetrying = true;
        onRetry?.call(attempt, e);
        final currentDelay = _nextDelay(delay, attempt, rng);
        LogTags.chatService.logInfo(
          '_retry attempt $attempt: retrying after ${currentDelay.inMilliseconds}ms',
        );
        final rc = _ensureRetryController;
        final totalDuration = currentDelay.inMilliseconds.toDouble();
        final startTime = DateTime.now().millisecondsSinceEpoch;
        await for (final _ in Stream.periodic(
          const Duration(milliseconds: 50),
        )) {
          if (_retryCancelled || _cancelToken.isCancelled) {
            LogTags.chatService.logWarning(
              '_retry attempt $attempt: cancelled during wait',
            );
            _isRetrying = false;
            throw Exception('cancelled');
          }
          final elapsed =
              (DateTime.now().millisecondsSinceEpoch - startTime) /
              totalDuration;
          final progress = 1.0 - elapsed.clamp(0.0, 1.0);
          if (!rc.isClosed) {
            rc.add(progress);
          }
          if (progress <= 0.0) break;
        }
        _isRetrying = false;
        _startProgressTimer();
        attempt++;
      }
    }
  }

  static const _errorClassifier = ErrorClassifier();

  bool _isRetryableError(Object e) {
    final classified = _errorClassifier.classify(e);

    // Extract retry-after for RateLimitError to feed into backoff calculation.
    if (classified is RateLimitError && classified.retryAfter != null) {
      _lastRetryAfter = classified.retryAfter!;
    }

    LogTags.chatService.logDebug(
      '_isRetryableError: $e → ${classified.runtimeType} retryable=${classified.isRetryable}',
    );
    return classified.isRetryable;
  }

  Duration _nextDelay(Duration baseDelay, int attempt, Random rng) {
    if (_lastRetryAfter != null) {
      final d = _lastRetryAfter!;
      _lastRetryAfter = null;
      return d > _retryMaxDelay ? _retryMaxDelay : d;
    }
    final exponential = baseDelay * pow(_retryFactor, attempt);
    final capped = exponential > _retryMaxDelay ? _retryMaxDelay : exponential;
    final jitter = capped * rng.nextDouble() * 0.3;
    return Duration(
      milliseconds: (capped.inMilliseconds + jitter.inMilliseconds).round(),
    );
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
    void Function(int attempt, Object error)? onRetry,
    void Function(List<Map<String, dynamic>> messages)? onOverflow,
  }) async {
    _isRetrying = false;
    _startProgressTimer();
    for (final m in messages) {
      final content = m['content'];
      if (m['role'] == 'system') {
        if (content is String) _tokenCounter.addSystem(content);
      } else {
        if (content is String) _tokenCounter.addMessage(content);
      }
    }

    try {
      await _retry(() async {
        final apiModel = stripProviderPrefix(model);
        final lm = _modelFactory(apiModel);
        LogTags.chatService.logDebug(
          'streamChatCompletion: calling streamText model=$apiModel',
        );
        late StreamTextResult result;
        try {
          result = await streamText(
            model: lm,
            messages: _toModelMessages(messages),
            temperature: temperature,
            maxRetries: 0, // We handle retries ourselves
            headers: _headers,
            abortSignal: _cancelToken,
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
        } catch (e, s) {
          LogTags.chatService.logError(
            'streamChatCompletion: streamText threw',
            e,
            s,
          );
          rethrow;
        }

        try {
          await for (final event in result.fullStream) {
            switch (event) {
              case StreamTextTextDeltaEvent(:final delta):
                onChunk(delta);
              case StreamTextReasoningDeltaEvent(:final delta):
                onReasoning(delta);
              case StreamTextToolResultEvent(
                :final toolResult,
                :final preliminary,
              ):
                if (!preliminary) {
                  final outputText = switch (toolResult.output) {
                    ToolResultOutputText(:final text) => text,
                    ToolResultOutputContent(:final parts) =>
                      parts.map((p) => p.toString()).join(),
                  };
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
            'streamChatCompletion: stream iteration threw',
            e,
            s,
          );
          rethrow;
        }
        return null;
      }, onRetry: onRetry);
    } catch (e, s) {
      LogTags.chatService.logError(
        'streamChatCompletion: _retry threw (rethrow to caller)',
        e,
        s,
      );
      // Safety net: if _retry somehow doesn't catch the error (e.g. stream-level
      // DioException from AI SDK's internal _withRetry), rethrow so the caller
      // can handle it with _handleStreamingError.
      rethrow;
    } finally {
      _stopProgressTimer();
    }
  }

  // ===========================================================================
  // NON-STREAMING COMPLETION
  // ===========================================================================
  Future<String> generateCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
  }) async {
    _startProgressTimer();
    try {
      final result = await _retry(() async {
        final apiModel = stripProviderPrefix(model);
        final lm = _modelFactory(apiModel);
        return generateText(
          model: lm,
          messages: _toModelMessages(messages),
          temperature: temperature,
          maxRetries: 0, // We handle retries ourselves
          headers: _headers,
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
    _stopProgressTimer();
    _isRetrying = false;
    _retryCancelled = true;
    _cancelToken.cancel();
    _cancelToken = CancellationToken();
  }
}
