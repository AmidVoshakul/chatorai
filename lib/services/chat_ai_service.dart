import 'dart:math';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/models/model_settings.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/utils/chat_error_utils.dart';

// ===========================================================================
// CHAT AI SERVICE
// ===========================================================================

class ChatAiService {
  final OpenRouterClient _client;

  // ===========================================================================
  // CONSTRUCTOR & GETTERS
  // ===========================================================================

  ChatAiService({OpenRouterClient? client})
    : _client = client ?? OpenRouterService();

  OpenRouterClient get client => _client;

  // ===========================================================================
  // MESSAGE CONVERSION
  // ===========================================================================

  Map<String, dynamic> convertMessageToOpenRouterFormat(Message msg) {
    if (msg.imageData != null && msg.imageType != null) {
      return {
        'role': msg.role.name,
        'content': [
          {'type': 'text', 'text': msg.content},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:${msg.imageType};base64,${msg.imageData}',
            },
          },
        ],
      };
    }
    return {'role': msg.role.name, 'content': msg.content};
  }

  List<Map<String, dynamic>> sanitizeMessages(
    List<Map<String, dynamic>> messages,
  ) {
    return ChatErrorUtils.sanitizeMessages(messages);
  }

  // ===========================================================================
  // CHAT COMPLETION
  // ===========================================================================

  Future<ChatCompletionResponse> getChatCompletionWithAdaptiveRollback({
    required String model,
    required List<Map<String, dynamic>> messages,
    required ModelSettings modelSettings,
    int defaultContextLength = 32000,
    int? modelContextLength,
  }) async {
    var attemptMsgs = sanitizeMessages(messages);

    final contextLength = modelContextLength ?? defaultContextLength;

    int currentMaxTokens = min(modelSettings.maxTokens, contextLength);
    final effectiveMinTokens = min(8000, contextLength ~/ 2);
    const reductionFactor = 0.97;
    const maxTokenReductionAttempts = 10;

    int tokenReductionAttempts = 0;

    while (true) {
      try {
        return await _client.getChatCompletion(
          model: model,
          messages: attemptMsgs,
          maxTokens: currentMaxTokens,
          temperature: modelSettings.temperature,
          topP: modelSettings.topP,
          frequencyPenalty: modelSettings.frequencyPenalty,
          presencePenalty: modelSettings.presencePenalty,
          includeReasoning: true,
        );
      } catch (e) {
        final err = e.toString();
        final isBadRequest =
            err.contains('400') ||
            err.toLowerCase().contains('bad response') ||
            err.toLowerCase().contains('client error') ||
            err.toLowerCase().contains('bad request');

        if (!isBadRequest) rethrow;

        if (tokenReductionAttempts < maxTokenReductionAttempts &&
            currentMaxTokens > effectiveMinTokens) {
          int newTokens = (currentMaxTokens * reductionFactor).floor();
          if (newTokens < effectiveMinTokens) newTokens = effectiveMinTokens;

          if (newTokens < currentMaxTokens) {
            tokenReductionAttempts++;
            currentMaxTokens = newTokens;
            continue;
          }
        }

        if (attemptMsgs.length <= 1) rethrow;

        int removedCount = 0;
        for (int i = 0; i < attemptMsgs.length && removedCount < 2; i++) {
          if (attemptMsgs[i]['role'] != 'system') {
            attemptMsgs.removeAt(i);
            removedCount++;
            i--;
          }
        }
        tokenReductionAttempts = 0;
      }
    }
  }

  // ===========================================================================
  // STREAMING
  // ===========================================================================

  Future<void> streamChatCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required int maxTokens,
    required double temperature,
    required double topP,
    required double frequencyPenalty,
    required double presencePenalty,
    required Function(String) onChunk,
    required Function(String) onReasoning,
    required Function(String) onCompletion,
  }) async {
    await _client.streamChatCompletion(
      messages: messages,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      includeReasoning: true,
      onChunk: onChunk,
      onReasoning: onReasoning,
      onCompletion: onCompletion,
    );
  }

  // ===========================================================================
  // ERROR HANDLING
  // ===========================================================================

  String formatError(Object error) => ChatErrorUtils.formatError(error);
}
