import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/context/overflow_detector.dart';
import 'package:chatorai/core/context/token_counter.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/models/providers/model_provider.dart'
    show modelProvider;
import 'package:chatorai/features/settings/providers/model_settings_provider.dart'
    show modelSettingsProvider;
import 'package:chatorai/core/config/config_provider.dart'
    show resolvedInstructionsProvider;
import 'package:chatorai/providers.dart'
    show
        currentChatProvider,
        compactionConfigProvider,
        currentAgentProvider,
        sessionPartsProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';

class ContextInstructionSource {
  final String name;
  final int estimatedTokens;

  const ContextInstructionSource({
    required this.name,
    required this.estimatedTokens,
  });
}

class SessionContextUsage {
  final int usedTokens;
  final int contextLength;
  final int buffer;
  final int usable;
  final List<ContextInstructionSource> sources;
  final int outputTokens;
  final int reasoningTokens;
  final int cacheReadTokens;
  final int cacheWriteTokens;
  final int toolTokens;
  final int toolCallsCount;

  const SessionContextUsage({
    required this.usedTokens,
    required this.contextLength,
    required this.buffer,
    required this.usable,
    required this.sources,
    this.outputTokens = 0,
    this.reasoningTokens = 0,
    this.cacheReadTokens = 0,
    this.cacheWriteTokens = 0,
    this.toolTokens = 0,
    this.toolCallsCount = 0,
  });

  SessionContextUsage copyWith({
    int? usedTokens,
    int? contextLength,
    int? buffer,
    int? usable,
    List<ContextInstructionSource>? sources,
    int? outputTokens,
    int? reasoningTokens,
    int? cacheReadTokens,
    int? cacheWriteTokens,
    int? toolTokens,
    int? toolCallsCount,
  }) {
    return SessionContextUsage(
      usedTokens: usedTokens ?? this.usedTokens,
      contextLength: contextLength ?? this.contextLength,
      buffer: buffer ?? this.buffer,
      usable: usable ?? this.usable,
      sources: sources ?? this.sources,
      outputTokens: outputTokens ?? this.outputTokens,
      reasoningTokens: reasoningTokens ?? this.reasoningTokens,
      cacheReadTokens: cacheReadTokens ?? this.cacheReadTokens,
      cacheWriteTokens: cacheWriteTokens ?? this.cacheWriteTokens,
      toolTokens: toolTokens ?? this.toolTokens,
      toolCallsCount: toolCallsCount ?? this.toolCallsCount,
    );
  }
}

final sessionContextUsageProvider = Provider<SessionContextUsage>((ref) {
  final chat = ref.watch(currentChatProvider);
  final selectedModel = ref.watch(modelProvider).selectedModelObject;
  final compactionConfig = ref.watch(compactionConfigProvider);
  final instructionsAsync = ref.watch(resolvedInstructionsProvider);
  final currentAgent = ref.watch(currentAgentProvider);
  final modelSettings = ref.watch(modelSettingsProvider);

  final detector = OverflowDetector.forModel(
    selectedModel?.contextLength,
    compactionBuffer: compactionConfig.buffer > 0
        ? compactionConfig.buffer
        : null,
  );

  int usedTokens = 0;
  int outputTokens = 0;
  int reasoningTokens = 0;
  if (chat != null) {
    for (final message in chat.messages) {
      if (message.role == MessageRole.assistant) {
        usedTokens = message.tokensInput ?? 0;
        outputTokens = message.tokensOutput ?? 0;
        reasoningTokens = message.tokensReasoning ?? 0;
      }
    }
  }

  int cacheReadTokens = 0;
  int cacheWriteTokens = 0;
  int toolTokens = 0;
  int toolCallsCount = 0;
  if (chat != null) {
    final sessionState = ref.watch(sessionPartsProvider(chat.id)).value;
    if (sessionState != null) {
      cacheReadTokens = sessionState.tokensCacheRead;
      cacheWriteTokens = sessionState.tokensCacheWrite;
      for (final result in sessionState.toolResults) {
        toolTokens += TokenCounter.estimate(json.encode(result.input));
        toolTokens += TokenCounter.estimate(result.outputText);
      }
      toolCallsCount = sessionState.parts.whereType<AssistantTool>().length;
    }
  }

  final sources = <ContextInstructionSource>[];

  final agentSystemPrompt = currentAgent.systemPrompt;
  if (currentAgent.mode == AgentMode.primary &&
      agentSystemPrompt != null &&
      agentSystemPrompt.isNotEmpty) {
    sources.add(
      ContextInstructionSource(
        name: currentAgent.name,
        estimatedTokens: TokenCounter.estimate(agentSystemPrompt),
      ),
    );
  }

  final userSystemPrompt = modelSettings.activeSettings?.systemPrompt;
  if (userSystemPrompt != null && userSystemPrompt.isNotEmpty) {
    sources.add(
      ContextInstructionSource(
        name: 'User system prompt',
        estimatedTokens: TokenCounter.estimate(userSystemPrompt),
      ),
    );
  }

  if (instructionsAsync.hasValue) {
    final blocks = instructionsAsync.value ?? const [];
    for (final block in blocks) {
      final lines = block.split('\n');
      String name = 'Instruction';
      if (lines.isNotEmpty) {
        final firstLine = lines.first;
        if (firstLine.startsWith('Instructions from: ')) {
          name = p.basename(firstLine.substring('Instructions from: '.length));
        }
      }
      sources.add(
        ContextInstructionSource(
          name: name,
          estimatedTokens: TokenCounter.estimate(block),
        ),
      );
    }
  }

  return SessionContextUsage(
    usedTokens: usedTokens,
    contextLength: detector.contextLimit,
    buffer: detector.reservedBuffer,
    usable: detector.usable,
    sources: sources,
    outputTokens: outputTokens,
    reasoningTokens: reasoningTokens,
    cacheReadTokens: cacheReadTokens,
    cacheWriteTokens: cacheWriteTokens,
    toolTokens: toolTokens,
    toolCallsCount: toolCallsCount,
  );
});
