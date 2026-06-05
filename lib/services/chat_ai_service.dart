import 'dart:async';
import 'dart:math';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_openai/ai_sdk_openai.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:chatorai/core/ai/openrouter_config.dart';
import 'package:chatorai/core/context/overflow_detector.dart';
import 'package:chatorai/core/context/token_counter.dart';

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
  OpenAIProvider _provider;
  var _cancelToken = CancellationToken();
  Timer? _progressTimer;
  final _retryController = StreamController<double>.broadcast();
  final TokenCounter _tokenCounter = TokenCounter();
  final OverflowDetector _overflowDetector = const OverflowDetector(
    contextLimit: 200000,
    reservedBuffer: 20000,
  );

  ChatAiService({OpenAIProvider? provider})
    : _provider = provider ?? openRouterProvider(apiKey: '');

  OpenAIProvider get provider => _provider;
  set provider(OpenAIProvider value) => _provider = value;

  TokenCounter get tokenCounter => _tokenCounter;
  OverflowDetector get overflowDetector => _overflowDetector;
  int get totalTokens => _tokenCounter.totalTokens;
  bool get isOverflow =>
      _overflowDetector.isOverflow(_tokenCounter.totalTokens);

  void _startProgressTimer() {
    _progressTimer?.cancel();
    if (!_retryController.isClosed) {
      _retryController.add(1.0);
    }
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_retryController.isClosed && _progressTimer != null) {
        _retryController.add(1.0);
      }
    });
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

  /// Stream of retry progress: 1.0 → 0.0 during backoff wait.
  /// Emits 1.0 immediately when retry starts, counts down to 0.0.
  /// Cancels when user calls [cancelAllRequests()] or stream completes.
  Stream<double> get retryCountdown => _retryController.stream;

  /// Wraps [operation] with OpenCode-style unbounded exponential backoff retry.
  /// Retries on transient errors forever until success or cancellation.
  /// Emits progress via [retryCountdown] stream during backoff waits.
  Future<T> _retry<T>(
    Future<T> Function() operation, {
    Duration? baseDelay,
  }) async {
    final delay = baseDelay ?? _retryBaseDelay;
    final rng = Random();
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        if (!_isRetryableError(e)) rethrow;
        if (_cancelToken.isCancelled) {
          _retryController.close();
          throw Exception('cancelled');
        }
        _isRetrying = true;
        final currentDelay = _nextDelay(delay, attempt, rng);
        // Emit countdown progress (1.0 → 0.0 over the delay duration)
        final totalDuration = currentDelay.inMilliseconds.toDouble();
        final startTime = DateTime.now().millisecondsSinceEpoch;
        await for (final _ in Stream.periodic(
          const Duration(milliseconds: 50),
        )) {
          if (_cancelToken.isCancelled) {
            _retryController.close();
            throw Exception('cancelled');
          }
          final elapsed =
              (DateTime.now().millisecondsSinceEpoch - startTime) /
              totalDuration;
          final progress = 1.0 - elapsed.clamp(0.0, 1.0);
          if (!_retryController.isClosed) {
            _retryController.add(progress);
          }
          if (progress <= 0.0) break;
        }
        _isRetrying = false;
        attempt++;
      }
    }
  }

  bool _isRetryableError(Object e) {
    final errStr = e.toString().toLowerCase();
    // Retry: rate limit, service unavailable, network errors
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
    // Non-retryable: bad request, auth, forbidden, not found
    if (errStr.contains('400') ||
        errStr.contains('401') ||
        errStr.contains('403') ||
        errStr.contains('404') ||
        errStr.contains('422') ||
        errStr.contains('invalid')) {
      return false;
    }
    // Default: retry (conservative approach, user can cancel)
    return true;
  }

  Duration _nextDelay(Duration baseDelay, int attempt, Random rng) {
    final exponential = baseDelay * pow(_retryFactor, attempt);
    final capped = exponential > _retryMaxDelay ? _retryMaxDelay : exponential;
    // Jitter: random 0-30% of delay to prevent thundering herd
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
      final lm = _provider(model);
      final result = await streamText(
        model: lm,
        messages: _toModelMessages(messages),
        temperature: temperature,
        maxRetries: 0, // We handle retries ourselves
        headers: kOpenRouterHeaders,
        abortSignal: _cancelToken,
      );

      await for (final event in result.fullStream) {
        switch (event) {
          case StreamTextTextDeltaEvent(:final delta):
            onChunk(delta);
          case StreamTextReasoningDeltaEvent(:final delta):
            onReasoning(delta);
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
      final lm = _provider(model);
      return generateText(
        model: lm,
        messages: _toModelMessages(messages),
        temperature: temperature,
        maxRetries: 0, // We handle retries ourselves
        headers: kOpenRouterHeaders,
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
  _cancelToken.cancel();
  _cancelToken = CancellationToken();
}
}
