import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/settings/data/models/model_settings.dart';
import 'package:path/path.dart' as p;

/// Pure, testable service for building LLM API message contexts.
///
/// All methods are pure (no `ref`, no side effects) and can be unit-tested
/// without Riverpod or Flutter widget bindings.
class ChatContextBuilder {
  const ChatContextBuilder();

  /// Builds unified system message chain from agent prompt + user system prompt.
  ///
  /// Returns empty list if no prompts are provided, otherwise a single system
  /// message with prompts joined by `\n\n---\n\n`.
  List<Map<String, dynamic>> buildSystemChain({
    required AgentDefinition agent,
    String? userSystemPrompt,
    String? delegateAgentId,
    List<String> instructionBlocks = const [],
  }) {
    final prompts = <String>[];

    // 1. Agent prompt (only for primary agents, and only if explicitly set)
    if (delegateAgentId != null) {
      final delegateAgent = AgentRegistry().get(delegateAgentId);
      if (delegateAgent != null &&
          delegateAgent.mode == AgentMode.primary &&
          delegateAgent.systemPrompt != null &&
          delegateAgent.systemPrompt!.isNotEmpty) {
        prompts.add(delegateAgent.systemPrompt!);
      }
    } else if (agent.mode == AgentMode.primary &&
        agent.systemPrompt != null &&
        agent.systemPrompt!.isNotEmpty) {
      prompts.add(agent.systemPrompt!);
    }

    // 2. User's system prompt (always added if present)
    if (userSystemPrompt != null && userSystemPrompt.isNotEmpty) {
      prompts.add(userSystemPrompt);
    }

    // 3. Project/global instructions (resolved from chatorai.json)
    for (final block in instructionBlocks) {
      if (block.isNotEmpty) prompts.add(block);
    }

    // Return single combined system message or empty
    if (prompts.isEmpty) return [];
    return [
      {'role': 'system', 'content': prompts.join('\n\n---\n\n')},
    ];
  }

  /// Finds the compaction summary message (if any) in the visible [messages]
  /// history. The summary is the single source of truth for the model context;
  /// it is never duplicated into [Chat.compactedContext].
  Message? findSummaryMessage(List<Message> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isCompactionSummary) return messages[i];
    }
    return null;
  }

  /// Builds the pre-send model message list from a compacted [canonicalChat].
  ///
  /// `canonicalChat.compactedContext` is tail-only, so the summary is re-injected
  /// from the original [chat.messages] (single source of truth). Returns the
  /// unchanged [fallback] when there is no compacted context.
  List<Map<String, dynamic>> compactedApiMessagesWithSummary(
    Chat chat,
    Chat canonicalChat,
  ) {
    final compacted = canonicalChat.compactedContext;
    if (compacted == null || compacted.isEmpty) return [];
    final summary = findSummaryMessage(chat.messages);
    final result = <Map<String, dynamic>>[];
    if (summary != null) {
      result.add({
        'role': summary.role.name,
        'content': summary.content,
        if (summary.agent != null) 'agent': summary.agent,
        'isCompactionSummary': true,
      });
    }
    for (final m in compacted) {
      result.add({
        'role': m.role.name,
        'content': m.content,
        if (m.agent != null) 'agent': m.agent,
        if (m.isCompactionSummary) 'isCompactionSummary': true,
      });
    }
    return result;
  }

  /// Builds the API message list for a chat, applying history truncation,
  /// compaction summary re-injection, system chain injection, and subagent
  /// delegation instructions.
  List<Map<String, dynamic>> buildApiMessages(
    Chat chat, {
    required AgentDefinition currentAgent,
    ModelSettings? modelSettings,
    List<String> instructionBlocks = const [],
    String? delegateAgentId,
    String? agentMention,
  }) {
    // `compactedContext` is tail-only (summary lives in `messages` as a single
    // source of truth). Re-inject the summary from `messages` so the model
    // context is `[summary, ...tail]` — mirroring how assembles the
    // context per call rather than duplicating the summary in storage.
    final compactedSummary = chat.compactedContext != null
        ? findSummaryMessage(chat.messages)
        : null;
    final sourceMessages = [
      ?compactedSummary,
      ...(chat.compactedContext ?? chat.messages),
    ];
    const int maxHistoryMessages = 20;
    final recentMessages = sourceMessages.length > maxHistoryMessages
        ? sourceMessages.sublist(sourceMessages.length - maxHistoryMessages)
        : sourceMessages;

    final messages = recentMessages.where((m) => !m.isError).map((msg) {
      final result = <String, dynamic>{
        'role': msg.role.name,
        'isCompactionSummary': msg.isCompactionSummary,
      };
      if (msg.agent != null) result['agent'] = msg.agent;

      var content = msg.content;
      if (msg.attachedDocPath != null) {
        final safeName = p
            .basename(msg.attachedDocPath!)
            .replaceAll('"', '\\"');
        final safePath = msg.attachedDocPath!.replaceAll('"', '\\"');
        content +=
            '\n\n[Attached file: "$safeName". '
            'Use the document_extract tool with filePath: "$safePath" '
            'to read its contents.]';
      }

      if (msg.imageData != null && msg.imageType != null) {
        result['content'] = [
          {'type': 'text', 'text': content},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:${msg.imageType};base64,${msg.imageData}',
            },
          },
        ];
      } else {
        result['content'] = content;
      }
      return result;
    }).toList();

    // Inject system prompt chain at the beginning
    final settings = modelSettings;

    // Add agent system prompts (only for primary agents or no delegation)
    final systemChain = buildSystemChain(
      agent: currentAgent,
      userSystemPrompt: settings?.systemPrompt,
      // For subagents, pass null (they get their prompt in child session from task tool)
      delegateAgentId: agentMention != null ? null : delegateAgentId,
      instructionBlocks: instructionBlocks,
    );
    for (final sys in systemChain) {
      messages.insert(0, sys);
    }

    // Add agent delegation instruction for subagents
    if (agentMention != null) {
      final agent = AgentRegistry().get(agentMention);
      if (agent != null && agent.mode == AgentMode.subagent) {
        messages.insert(systemChain.length, {
          'role': 'system',
          'content':
              'Delegate to subagent $agentMention. '
              'Use the task tool with subagent_type: "$agentMention" to process this request.',
        });
      }
    }

    return messages;
  }
}
