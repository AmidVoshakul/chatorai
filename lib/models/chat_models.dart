import 'package:flutter/material.dart';

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

  Message({
    String? id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isComplete = false,
    this.isError = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Message copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isComplete,
    bool? isError,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isComplete: isComplete ?? this.isComplete,
      isError: isError ?? this.isError,
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
