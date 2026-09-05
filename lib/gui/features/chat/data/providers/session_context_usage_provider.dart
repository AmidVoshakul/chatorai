import 'dart:convert';

import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/config/config_provider.dart'
    show resolvedInstructionsProvider;
import 'package:chatorai/core/context/overflow_detector.dart';
import 'package:chatorai/core/context/token_counter.dart';
import 'package:chatorai/core/llm/catalog_providers.dart'
    show catalogServiceProvider;
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/chat/chat/assistant_content.dart';
import 'package:chatorai/core/chat/chat_models.dart';
import 'package:chatorai/gui/features/models/providers/model_provider.dart'
    show modelProvider;
import 'package:chatorai/gui/features/settings/providers/model_settings_provider.dart'
    show modelSettingsProvider;
import 'package:chatorai/providers.dart'
    show
        currentChatProvider,
        compactionConfigProvider,
        currentAgentProvider,
        sessionPartsProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

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
  final double? spentUsd;

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
    this.spentUsd,
  });

  int get totalTokens =>
      usedTokens +
      outputTokens +
      reasoningTokens +
      cacheReadTokens +
      cacheWriteTokens;

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
    double? spentUsd,
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
      spentUsd: spentUsd ?? this.spentUsd,
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

  String? lastAssistantMsgId;
  int? lastMsgContextLength;

  int usedTokens = 0;
  int outputTokens = 0;
  int reasoningTokens = 0;
  int cacheReadTokens = 0;
  int cacheWriteTokens = 0;
  int toolTokens = 0;
  int toolCallsCount = 0;
  if (chat != null) {
    for (final message in chat.messages.reversed) {
      if (message.role != MessageRole.assistant) continue;
      if (message.tokensInput != null) usedTokens = message.tokensInput!;
      if (message.tokensOutput != null) outputTokens = message.tokensOutput!;
      if (message.tokensReasoning != null) {
        reasoningTokens = message.tokensReasoning!;
      }
      if (cacheReadTokens == 0 && cacheWriteTokens == 0) {
        cacheReadTokens = message.tokensCacheRead ?? 0;
        cacheWriteTokens = message.tokensCacheWrite ?? 0;
      }
      lastAssistantMsgId = message.id;
      lastMsgContextLength = message.contextLength;
      if (usedTokens > 0 || outputTokens > 0 || reasoningTokens > 0) break;
    }
    final sessionState = ref.watch(sessionPartsProvider(chat.id)).value;
    if (sessionState != null && lastAssistantMsgId != null) {
      for (final part in sessionState.parts) {
        if (part is AssistantTool && part.messageId == lastAssistantMsgId) {
          toolCallsCount++;
          toolTokens += TokenCounter.estimate(json.encode(part.input));
          if (part.output != null) {
            toolTokens += TokenCounter.estimate(part.output!);
          }
        }
      }
    }
  }

  final effectiveContextLength =
      lastMsgContextLength ?? selectedModel?.contextLength;
  final detector = OverflowDetector.forModel(
    effectiveContextLength,
    compactionBuffer: compactionConfig.buffer > 0
        ? compactionConfig.buffer
        : null,
  );

  final Map<String, ModelConfig> modelsById = {};
  final bool needsCatalog =
      chat != null &&
      chat.messages.any(
        (m) => m.role == MessageRole.assistant && m.model != null,
      );
  if (needsCatalog) {
    try {
      final catalog = ref.read(catalogServiceProvider);
      for (final m in catalog.getAllModels()) {
        modelsById[m.id] = m;
      }
    } on StateError {
      // catalogServiceProvider may be unavailable in tests or pre-bootstrap.
    }
  }

  double spent = 0;
  if (chat != null) {
    for (final message in chat.messages) {
      if (message.role != MessageRole.assistant) continue;
      if (message.tokensInput == null) continue;

      final pricing = message.model == null
          ? selectedModel?.pricing
          : modelsById.containsKey(message.model)
          ? modelsById[message.model]?.pricing
          : selectedModel?.pricing;

      if (pricing == null ||
          pricing.inputCostPer1k == null ||
          pricing.outputCostPer1k == null) {
        continue;
      }

      final billedInput = message.tokensCacheIncludedInInput == true
          ? message.tokensInput!
          : message.tokensInput! +
                (message.tokensCacheRead ?? 0) +
                (message.tokensCacheWrite ?? 0);
      spent +=
          (billedInput * pricing.inputCostPer1k! +
              ((message.tokensOutput ?? 0) + (message.tokensReasoning ?? 0)) *
                  pricing.outputCostPer1k!) /
          1000;
    }
  }
  final double? spentUsd = spent > 0 ? spent : null;

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
    spentUsd: spentUsd,
  );
});
