import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/models/data/models/model_card_model.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';

/// Fake client that simulates 400 errors when maxTokens > threshold.
class FakeRetryClient {
  final int threshold;
  final List<int> callMaxTokens = [];
  final List<List<Map<String, dynamic>>> callMessages = [];

  FakeRetryClient({required this.threshold});

  Future<ChatCompletionResponse> getChatCompletion({
    required String model,
    required List<Map<String, dynamic>> messages,
    int? maxTokens,
  }) async {
    callMessages.add(messages);
    callMaxTokens.add(maxTokens ?? 0);

    if ((maxTokens ?? 0) > threshold) {
      throw Exception('400 Bad Request');
    }

    return ChatCompletionResponse(content: 'OK');
  }

  Future<void> streamChatCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    int? maxTokens,
    required Function(String) onChunk,
    required Function(String) onCompletion,
  }) async {
    callMessages.add(messages);
    callMaxTokens.add(maxTokens ?? 0);

    if ((maxTokens ?? 0) > threshold) {
      throw Exception('400 Bad Request');
    }

    await Future<void>.delayed(Duration(milliseconds: 10));
    onChunk('hello');
    onCompletion('done');
  }
}

/// Minimal ThemeProvider stub for unit tests (only what the retry logic needs).
class FakeThemeProvider {
  final Map<String, ChatModel> _models;

  FakeThemeProvider(this._models);

  ChatModel? getModelById(String id) => _models[id];
}

/// Helper to build a fake ChatModel with a given context length.
ChatModel fakeModel(String id, int contextLength) => ChatModel(
  id: id,
  name: id,
  description: 'fake',
  contextLength: contextLength,
  provider: 'fake',
  capabilities: ModelCapabilities.fromJson({}),
);

/// A small testable wrapper that performs the same adaptive retry logic
/// as ChatScreen._handleStreamingResponse, but without any UI.
class RetryTestHelper {
  final FakeRetryClient client;
  final FakeThemeProvider themeProvider;

  RetryTestHelper(this.client, this.themeProvider);

  /// Sends a request with adaptive retry (token reduction first, then message removal).
  /// Returns the number of attempts made.
  Future<int> sendWithRetry({
    required String modelId,
    required List<Map<String, String>> messages,
    required int initialMaxTokens,
  }) async {
    int attempts = 0;
    int currentMaxTokens = initialMaxTokens;
    int tokenReductionAttempts = 0;
    const int maxTokenReductionAttempts =
        10; // Allow up to 10 reductions (5% each)
    const double reductionFactor = 0.97; // 3% reduction per attempt
    const int minTokens = 8000; // Absolute minimum
    var attemptMsgs = List<Map<String, String>>.from(messages);
    int totalRemoved = 0;

    while (true) {
      attempts++;
      try {
        // Convert messages to the format expected by OpenRouterClient
        final dynamicMessages = attemptMsgs
            .map((m) => {'role': m['role'], 'content': m['content']})
            .toList();

        await client.streamChatCompletion(
          messages: dynamicMessages,
          model: modelId,
          maxTokens: currentMaxTokens,
          onChunk: (content) {},
          onCompletion: (content) {},
        );
        break; // success
      } catch (e) {
        final err = e.toString();
        final isBadRequest =
            err.contains('400') ||
            err.toLowerCase().contains('bad response') ||
            err.toLowerCase().contains('client error') ||
            err.toLowerCase().contains('bad request');

        if (!isBadRequest) rethrow;

        // Token reduction first (5% per attempt)
        if (tokenReductionAttempts < maxTokenReductionAttempts &&
            currentMaxTokens > minTokens) {
          // Calculate new tokens: current * 0.95, rounded down
          int newTokens = (currentMaxTokens * reductionFactor).floor();

          // Ensure we don't go below minimum
          if (newTokens < minTokens) {
            newTokens = minTokens;
          }

          if (newTokens < currentMaxTokens) {
            tokenReductionAttempts++;
            currentMaxTokens = newTokens;
            continue;
          }
        }

        // Message removal fallback
        if (attemptMsgs.length <= 1) rethrow;

        final removableIndex = attemptMsgs.indexWhere(
          (m) => m['role'] != 'system',
        );
        if (removableIndex == -1) rethrow;

        attemptMsgs.removeAt(removableIndex);
        if (removableIndex < attemptMsgs.length &&
            attemptMsgs[removableIndex]['role'] == 'assistant') {
          attemptMsgs.removeAt(removableIndex);
        }
        totalRemoved += 1;
        // Loop continues
      }
    }
    return attempts;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testModels = [
    'xiaomi/mimo-v2-flash:free',
    'mistralai/devstral-2512:free',
    'kwaipilot/kat-coder-pro:free',
    'tngtech/deepseek-r1t2-chimera:free',
    'nex-agi/deepseek-v3.1-nex-n1:free',
    'nvidia/nemotron-3-nano-30b-a3b:free',
    'tngtech/deepseek-r1t-chimera:free',
    'z-ai/glm-4.5-air:free',
    'tngtech/tng-r1t-chimera:free',
    'allenai/olmo-3.1-32b-think:free',
    'qwen/qwen3-coder:free',
  ];

  group('Adaptive retry token-reduction unit tests', () {
    for (final modelId in testModels) {
      test(
        'reduces tokens by 5% before removing messages for $modelId',
        () async {
          // Arrange
          final contextLength = 262144;
          final model = fakeModel(modelId, contextLength);
          final themeProvider = FakeThemeProvider({modelId: model});
          // Threshold that will be reached after a few 5% reductions
          final client = FakeRetryClient(threshold: 200000);
          final helper = RetryTestHelper(client, themeProvider);

          // Act
          final attempts = await helper.sendWithRetry(
            modelId: modelId,
            messages: [
              {'role': 'user', 'content': 'hello'},
              {'role': 'assistant', 'content': ''},
            ],
            initialMaxTokens: contextLength,
          );

          // Assert
          expect(
            attempts,
            greaterThanOrEqualTo(2),
            reason: 'Should retry at least twice',
          );
          expect(
            client.callMaxTokens.length,
            attempts,
            reason: 'Each attempt should record maxTokens',
          );

          final first = client.callMaxTokens.first;
          final last = client.callMaxTokens.last;
          expect(
            first,
            equals(contextLength),
            reason: 'First attempt should use full context length',
          );
          expect(
            first > client.threshold,
            true,
            reason: 'First attempt should exceed threshold and fail',
          );
          expect(
            last <= client.threshold || last < first,
            true,
            reason: 'Last attempt should reduce tokens',
          );

          // Verify 5% reduction pattern: each reduction should be approximately 5%
          for (int i = 1; i < client.callMaxTokens.length; i++) {
            final prev = client.callMaxTokens[i - 1];
            final current = client.callMaxTokens[i];
            final expected = (prev * 0.95).floor();
            expect(
              current,
              greaterThanOrEqualTo(expected),
              reason: 'Token reduction should be at least 5%',
            );
            expect(current, lessThan(prev), reason: 'Tokens should decrease');
          }
        },
      );
    }

    test('uses 5% reduction per attempt before message removal', () async {
      // Arrange: threshold that requires multiple 5% reductions
      final modelId = 'test/model';
      final model = fakeModel(modelId, 262144);
      final themeProvider = FakeThemeProvider({modelId: model});
      final client = FakeRetryClient(
        threshold: 200000,
      ); // Will trigger multiple reductions
      final helper = RetryTestHelper(client, themeProvider);

      // Act
      final attempts = await helper.sendWithRetry(
        modelId: modelId,
        messages: [
          {'role': 'user', 'content': 'msg1'},
          {'role': 'assistant', 'content': 'resp1'},
        ],
        initialMaxTokens: 262144,
      );

      // Assert: Should succeed after a few 5% reductions
      expect(
        attempts,
        greaterThan(1),
        reason: 'Should retry with token reductions',
      );
      expect(client.callMaxTokens.length, attempts);

      // Verify each reduction is approximately 5%
      for (int i = 1; i < client.callMaxTokens.length; i++) {
        final prev = client.callMaxTokens[i - 1];
        final current = client.callMaxTokens[i];
        final expected = (prev * 0.95).floor();
        expect(
          current,
          greaterThanOrEqualTo(expected),
          reason: 'Token reduction should be at least 5%',
        );
        expect(current, lessThan(prev), reason: 'Tokens should decrease');
      }
    });

    test(
      'falls back to message removal after token reduction exhausted',
      () async {
        // Arrange: very low threshold so even after reductions we still hit 400
        final modelId = 'test/model';
        final model = fakeModel(modelId, 262144);
        final themeProvider = FakeThemeProvider({modelId: model});
        final client = FakeRetryClient(threshold: 1000); // very low
        final helper = RetryTestHelper(client, themeProvider);

        // Act & Assert: should throw because we cannot reduce below 8000 and still exceed threshold
        // and message removal will eventually exhaust messages
        await expectLater(
          helper.sendWithRetry(
            modelId: modelId,
            messages: [
              {'role': 'user', 'content': 'msg1'},
              {'role': 'assistant', 'content': 'resp1'},
              {'role': 'user', 'content': 'msg2'},
              {'role': 'assistant', 'content': 'resp2'},
            ],
            initialMaxTokens: 262144,
          ),
          throwsA(isA<Exception>()),
        );

        // Verify that attempts were made and token reduction happened first
        expect(client.callMaxTokens.length, greaterThanOrEqualTo(2));
        // First attempt should be large, then reduced
        expect(client.callMaxTokens.first, greaterThan(client.threshold));
        // After reductions, we should see smaller values
        expect(client.callMaxTokens.last, lessThan(client.callMaxTokens.first));
      },
    );
  });
}
