import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// ===========================================================================
// MESSAGE ROLE ENUM
// ===========================================================================

enum MessageRole {
  user,
  assistant,
  system,
  tool;

  Color get color {
    switch (this) {
      case MessageRole.user:
        return Colors.blue;
      case MessageRole.assistant:
        return Colors.green;
      case MessageRole.system:
        return Colors.orange;
      case MessageRole.tool:
        return Colors.purple;
    }
  }

  String get displayName {
    switch (this) {
      case MessageRole.user:
        return 'You';
      case MessageRole.assistant:
        return 'AI';
      case MessageRole.system:
        return 'System';
      case MessageRole.tool:
        return 'Tool';
    }
  }
}

// ===========================================================================
// MESSAGE CLASS
// ===========================================================================

class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isComplete;
  final bool isError;
  final String? model; // Model used for assistant messages
  final String? reasoning; // Model's reasoning/thoughts
  final String? imageData; // Base64 encoded image data
  final String? imageType; // Image MIME type (e.g., 'image/jpeg')
  final int? tokensInput;
  final int? tokensOutput;
  final int? tokensReasoning;
  final int? contextLength; // Model's context window length
  final List<Map<String, dynamic>>?
  partsJson; // Serialized MessageParts (tool calls, etc.)
  final String? agent; // Agent name who responded (for assistant messages)
  final bool synthetic;

  Message({
    String? id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isComplete = false,
    this.isError = false,
    this.model,
    this.reasoning,
    this.imageData,
    this.imageType,
    this.tokensInput,
    this.tokensOutput,
    this.tokensReasoning,
    this.contextLength,
    this.partsJson,
    this.agent,
    this.synthetic = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // ===========================================================================
  // COPY WITH
  // ===========================================================================

  Message copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isComplete,
    bool? isError,
    String? model,
    String? reasoning,
    String? imageData,
    String? imageType,
    int? tokensInput,
    int? tokensOutput,
    int? tokensReasoning,
    int? contextLength,
    List<Map<String, dynamic>>? partsJson,
    String? agent,
    bool? synthetic,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isComplete: isComplete ?? this.isComplete,
      isError: isError ?? this.isError,
      model: model ?? this.model,
      reasoning: reasoning ?? this.reasoning,
      imageData: imageData ?? this.imageData,
      imageType: imageType ?? this.imageType,
      tokensInput: tokensInput ?? this.tokensInput,
      tokensOutput: tokensOutput ?? this.tokensOutput,
      tokensReasoning: tokensReasoning ?? this.tokensReasoning,
      contextLength: contextLength ?? this.contextLength,
      partsJson: partsJson ?? this.partsJson,
      agent: agent ?? this.agent,
      synthetic: synthetic ?? this.synthetic,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.id == id &&
        other.role == role &&
        other.content == content &&
        other.timestamp == timestamp &&
        other.isComplete == isComplete &&
        other.isError == isError &&
        other.model == model &&
        other.agent == agent &&
        other.synthetic == synthetic &&
        other.tokensInput == tokensInput &&
        other.tokensOutput == tokensOutput &&
        other.tokensReasoning == tokensReasoning;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      role,
      content,
      timestamp,
      isComplete,
      isError,
      model,
      agent,
      synthetic,
      tokensInput,
      tokensOutput,
      tokensReasoning,
    );
  }

  // ===========================================================================
  // SERIALIZATION
  // ===========================================================================

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isComplete': isComplete,
      'isError': isError,
      'model': model,
      'reasoning': reasoning,
      'imageData': imageData,
      'imageType': imageType,
      'tokensInput': tokensInput,
      'tokensOutput': tokensOutput,
      'tokensReasoning': tokensReasoning,
      'contextLength': contextLength,
      'partsJson': partsJson,
      'agent': agent,
      'synthetic': synthetic,
    };

    return json;
  }

  static Message fromJson(Map<String, dynamic> json) {
    final reasoning = json['reasoning'];
    final imageData = json['imageData'];
    final imageType = json['imageType'];

    return Message(
      id: json['id'],
      role: MessageRole.values.firstWhere((r) => r.name == json['role']),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isComplete: json['isComplete'] ?? false,
      isError: json['isError'] ?? false,
      model: json['model'],
      reasoning: reasoning,
      imageData: imageData,
      imageType: imageType,
      tokensInput: json['tokensInput'] as int?,
      tokensOutput: json['tokensOutput'] as int?,
      tokensReasoning: json['tokensReasoning'] as int?,
      contextLength: json['contextLength'] as int?,
      partsJson: json['partsJson'] != null
          ? (json['partsJson'] as List<dynamic>).cast<Map<String, dynamic>>()
          : null,
      agent: json['agent'] as String?,
      synthetic: json['synthetic'] as bool? ?? false,
    );
  }
}

// ===========================================================================
// CHAT CLASS
// ===========================================================================

class Chat {
  final String id;
  String title; // Made mutable by removing 'final'
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Chat copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((message) => message.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static Chat fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List<dynamic>)
          .map((message) => Message.fromJson(message))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Chat &&
        other.id == id &&
        other.title == title &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        listEquals(other.messages, messages);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        Object.hashAll(messages);
  }
}
