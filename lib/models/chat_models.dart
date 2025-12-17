import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Import min function
import 'dart:math' show min;

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

class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isComplete;
  final bool isError;
  final String? model; // Model used for assistant messages
  final String? reasoning; // Model's reasoning/thoughts

  Message({
    String? id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isComplete = false,
    this.isError = false,
    this.model,
    this.reasoning,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Message copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isComplete,
    bool? isError,
    String? model,
    String? reasoning,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isComplete: isComplete ?? this.isComplete,
      isError: isError ?? this.isError,
      model: model ?? this.model,
      reasoning: reasoning ?? this.reasoning, // Preserve current reasoning if not provided
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
    return id.hashCode ^ role.hashCode ^ content.hashCode ^ timestamp.hashCode ^ isComplete.hashCode ^ isError.hashCode;
  }

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
    };
    
    // Log reasoning content during serialization
    if (reasoning != null && reasoning!.isNotEmpty) {
      print('[Message.toJson] Serializing reasoning: "${reasoning!.substring(0, min(50, reasoning!.length))}..."');
    } else {
      print('[Message.toJson] No reasoning to serialize');
    }
    
    return json;
  }

  static Message fromJson(Map<String, dynamic> json) {
    final reasoning = json['reasoning'];
    
    // Log reasoning content during deserialization
    if (reasoning != null && reasoning is String && reasoning.isNotEmpty) {
      print('[Message.fromJson] Deserializing reasoning: "${reasoning.substring(0, min(50, reasoning.length))}..."');
    } else {
      print('[Message.fromJson] No reasoning found in JSON: $reasoning');
    }
    
    return Message(
      id: json['id'],
      role: MessageRole.values.firstWhere((r) => r.name == json['role']),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isComplete: json['isComplete'] ?? false,
      isError: json['isError'] ?? false,
      model: json['model'],
      reasoning: reasoning,
    );
  }
}

class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastModified;
  final List<Message> messages;

  Conversation({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? lastModified,
    required this.messages,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now(),
       lastModified = lastModified ?? DateTime.now();

  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastModified,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      messages: messages ?? this.messages,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Conversation &&
           other.id == id &&
           other.title == title &&
           other.createdAt == createdAt &&
           other.lastModified == lastModified &&
           other.messages == messages;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ createdAt.hashCode ^ lastModified.hashCode ^ messages.hashCode;
  }
}

class Chat {
  final String id;
  final String title;
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
    return id.hashCode ^ title.hashCode ^ createdAt.hashCode ^ updatedAt.hashCode ^ Object.hashAll(messages);
  }
}

class Settings {
  final bool darkMode;
  final double fontSize;
  final bool reduceMotion;
  final bool highContrast;
  final String language;
  final bool enableSpeechToText;
  final bool enableMarkdown;
  final bool enableStreaming;
  final int maxMessageHistory;
  final bool enableNotifications;

  Settings({
    required this.darkMode,
    required this.fontSize,
    required this.reduceMotion,
    required this.highContrast,
    required this.language,
    required this.enableSpeechToText,
    required this.enableMarkdown,
    required this.enableStreaming,
    required this.maxMessageHistory,
    required this.enableNotifications,
  });

  factory Settings.fromInitial() {
    return Settings(
      darkMode: false,
      fontSize: 1.0,
      reduceMotion: false,
      highContrast: false,
      language: 'en',
      enableSpeechToText: true,
      enableMarkdown: true,
      enableStreaming: true,
      maxMessageHistory: 1000,
      enableNotifications: true,
    );
  }

  Settings copyWith({
    bool? darkMode,
    double? fontSize,
    bool? reduceMotion,
    bool? highContrast,
    String? language,
    bool? enableSpeechToText,
    bool? enableMarkdown,
    bool? enableStreaming,
    int? maxMessageHistory,
    bool? enableNotifications,
  }) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      fontSize: fontSize ?? this.fontSize,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      language: language ?? this.language,
      enableSpeechToText: enableSpeechToText ?? this.enableSpeechToText,
      enableMarkdown: enableMarkdown ?? this.enableMarkdown,
      enableStreaming: enableStreaming ?? this.enableStreaming,
      maxMessageHistory: maxMessageHistory ?? this.maxMessageHistory,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }
}
