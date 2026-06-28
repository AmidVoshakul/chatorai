import 'package:chatorai/features/chat/data/models/chat_models.dart';

import 'chat_message.dart';

// ── Conversion from legacy Message ───────────────────────────

/// Convert a legacy [Message] to the new typed [ChatMessage] hierarchy.
/// Preserves backward compatibility with the existing storage layer.
ChatMessage messageToChatMessage(Message message) {
  final id = message.id;
  final timestamp = message.timestamp;

  if (message.isError == true) {
    return ErrorMessage(
      id: id,
      content: message.content,
      code: null,
      type: null,
      timestamp: timestamp,
    );
  }

  switch (message.role.toString().split('.').last) {
    case 'user':
      final imageData = message.imageData;
      final files = <String>[];
      if (imageData != null && imageData.isNotEmpty) {
        files.add(
          imageData.length > 50
              ? '${imageData.substring(0, 47)}...'
              : imageData,
        );
      }
      return UserMessage(
        id: id,
        content: message.content,
        files: files,
        timestamp: timestamp,
      );

    case 'assistant':
      final content = message.content;
      final reasoning = message.reasoning;

      List<MessagePart> parts;
      if (message.partsJson != null && message.partsJson!.isNotEmpty) {
        parts = message.partsJson!.map((j) => partFromJson(j)).toList();
        final hasText = parts.any((p) => p is TextPart);
        final hasReasoning = parts.any((p) => p is ReasoningPart);
        if (!hasText && content.isNotEmpty) {
          parts.add(TextPart(content: content));
        }
        if (!hasReasoning && reasoning != null && reasoning.isNotEmpty) {
          parts.insert(0, ReasoningPart(content: reasoning));
        }
      } else {
        parts = <MessagePart>[];
        if (reasoning != null && reasoning.isNotEmpty) {
          parts.add(ReasoningPart(content: reasoning));
        }
        if (content.isNotEmpty) {
          parts.add(TextPart(content: content));
        }
      }

      return AssistantMessage(
        id: id,
        parts: parts,
        model: message.model,
        timestamp: timestamp,
        tokensInput: message.tokensInput,
        tokensOutput: message.tokensOutput,
        tokensReasoning: message.tokensReasoning,
        contextLength: message.contextLength,
      );

    case 'system':
      return SystemMessage(
        id: id,
        content: message.content,
        timestamp: timestamp,
      );

    default:
      return ErrorMessage(
        id: id,
        content: message.content,
        code: 'UNKNOWN_ROLE',
        type: message.role.toString(),
        timestamp: timestamp,
      );
  }
}
