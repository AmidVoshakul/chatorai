import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:dio/dio.dart';
import 'package:chatorai/core/context/overflow_detector.dart';
import 'package:chatorai/core/context/token_counter.dart';

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
  StreamController<double>? _retryController;
  bool _retryCancelled = false;
  final TokenCounter _tokenCounter = TokenCounter();
  final OverflowDetector _overflowDetector = const OverflowDetector(
    contextLimit: 200000,
    reservedBuffer: 20000,
  );

  StreamController<double> get _ensureRetryController {
    if (_retryController == null || _retryController!.isClosed) {
      _retryController = StreamController<double>.broadcast();
    }
    return _retryController!;
  }

  ChatAiService({
    required ModelFactory modelFactory,
    Map<String, String> headers = const {},
  }) : _modelFactory = modelFactory,
       _headers = headers;

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
  Future<T> _retry<T>(
    Future<T> Function() operation, {
    Duration? baseDelay,
  }) async {
    _retryCancelled = false;
    final delay = baseDelay ?? _retryBaseDelay;
    final rng = Random();
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        if (!_isRetryableError(e)) rethrow;
        if (_retryCancelled || _cancelToken.isCancelled) {
          _ensureRetryController.close();
          throw Exception('cancelled');
        }
        _stopProgressTimer();
        _isRetrying = true;
        final currentDelay = _nextDelay(delay, attempt, rng);
        final rc = _ensureRetryController;
        final totalDuration = currentDelay.inMilliseconds.toDouble();
        final startTime = DateTime.now().millisecondsSinceEpoch;
        await for (final _ in Stream.periodic(
          const Duration(milliseconds: 50),
        )) {
          if (_retryCancelled || _cancelToken.isCancelled) {
            _ensureRetryController.close();
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

  bool _isRetryableError(Object e) {
    // Check for DioException with retry-after headers
    if (e is DioException) {
      final response = e.response;
      if (response != null) {
        final headers = response.headers;
        final retryAfterMs = headers.value('retry-after-ms');
        if (retryAfterMs != null) {
          _lastRetryAfter = Duration(
            milliseconds:
                int.tryParse(retryAfterMs) ?? _retryBaseDelay.inMilliseconds,
          );
          return true;
        }
        final retryAfter = headers.value('retry-after');
        if (retryAfter != null) {
          _lastRetryAfter = _parseRetryAfter(retryAfter);
          return true;
        }
        final statusCode = response.statusCode;
        if (statusCode == 429 || statusCode == 503) return true;
        if (statusCode != null && statusCode < 500)
          return false; // 4xx non-retryable
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return true;
      }
      return false;
    }

    final errStr = e.toString().toLowerCase();
    if (errStr.contains('429') ||
        errStr.contains('rate limit') ||
        errStr.contains('503') ||
        errStr.contains('service unavailable') ||
        errStr.contains('timeout') ||
        errStr.contains('network') ||
        errStr.contains('connection reset') ||
        errStr.contains('socket') ||
        errStr.contains('econnreset') ||
        errStr.contains('etimedout')) {
      return true;
    }
    if (errStr.contains('400') ||
        errStr.contains('401') ||
        errStr.contains('403') ||
        errStr.contains('404') ||
        errStr.contains('422') ||
        errStr.contains('invalid')) {
      return false;
    }
    return true;
  }

  /// Parse Retry-After header: seconds (number) or HTTP-date.
  Duration _parseRetryAfter(String value) {
    final seconds = int.tryParse(value);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }
    try {
      final date = HttpDate.parse(value);
      final delta = date.difference(DateTime.now());
      return delta.isNegative ? Duration.zero : delta;
    } catch (_) {
      return _retryBaseDelay;
    }
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
    int maxSteps = 5,
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

    await _retry(() async {
      final apiModel = stripProviderPrefix(model);
      final lm = _modelFactory(apiModel);
      final result = await streamText(
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

      await for (final event in result.fullStream) {
        switch (event) {
          case StreamTextTextDeltaEvent(:final delta):
            onChunk(delta);
          case StreamTextReasoningDeltaEvent(:final delta):
            onReasoning(delta);
          case StreamTextToolResultEvent(:final toolResult, :final preliminary):
            if (!preliminary) {
              final text = switch (toolResult.output) {
                ToolResultOutputText(:final text) => text,
                ToolResultOutputContent(:final parts) =>
                  parts.map((p) => p.toString()).join(),
              };
              onToolEnd?.call(toolResult.toolCallId, toolResult.toolName, text);
            }
          case StreamTextToolErrorEvent(
            :final toolCallId,
            :final toolName,
            :final error,
          ):
            onToolError?.call(toolCallId, toolName, error.toString());
          case StreamTextFinishEvent(:final text, :final usage):
            _tokenCounter.recordUsage(
              promptTokens: usage?.inputTokens,
              completionTokens: usage?.outputTokens,
            );
            onCompletion(text);
          default:
            break;
        }
      }
      return null;
    });
    _stopProgressTimer();
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
