import 'dart:convert';

import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';

/// Encodes a list of [ChatMessage]s into a JSON string suitable for storage
/// in the `chat_snapshots` table.
String encodeChatSnapshot(List<ChatMessage> messages) {
  final payload = messages.map((m) => m.toJson()).toList();
  return jsonEncode(payload);
}

/// Decodes a JSON string produced by [encodeChatSnapshot] back into a list of
/// [ChatMessage]s.
///
/// Returns `null` if the JSON is malformed or contains an unknown message type,
/// allowing the caller to fall back to full event replay without crashing.
List<ChatMessage>? decodeChatSnapshot(String json) {
  try {
    final decoded = jsonDecode(json) as List<dynamic>;
    return decoded
        .map((e) => chatMessageFromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  } catch (_) {
    return null;
  }
}
