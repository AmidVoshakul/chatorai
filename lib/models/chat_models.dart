import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// ===========================================================================
// MESSAGE ROLE ENUM
// ===========================================================================

enum MessageRole {
  user,
  assistant,
  system;

  Color get color {
    switch (this) {
      case MessageRole.user:
        return Colors.blue;
      case MessageRole.assistant:
        return Colors.green;
      case MessageRole.system:
        return Colors.orange;
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
        other.isError == isError;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        role.hashCode ^
        content.hashCode ^
        timestamp.hashCode ^
        isComplete.hashCode ^
        isError.hashCode;
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
