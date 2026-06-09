import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';

/// Converts raw message maps to SDK [ModelMessage] objects.
///
/// Handles text, multimodal (text + image), and tool-result content shapes.
class ChatMessageConverter {
  const ChatMessageConverter();

  /// Converts a list of raw message maps to [ModelMessage] list.
  List<ModelMessage> toModelMessages(List<Map<String, dynamic>> messages) {
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

  /// Filters out messages with empty content.
  ///
  /// Kept as a utility on the converter because it shares the same
  /// content-inspection logic as [_toModelMessage].
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
}
