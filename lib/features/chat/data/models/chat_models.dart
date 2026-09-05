import 'package:chatorai/core/session/session_id.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  final String? imageName; // Display name of the attached image file
  final String? attachedDocPath; // Path to attached document file
  final int? tokensInput;
  final int? tokensOutput;
  final int? tokensReasoning;
  final int? tokensCacheRead;
  final int? tokensCacheWrite;
  final bool? tokensCacheIncludedInInput;
  final int? contextLength; // Model's context window length
  final List<Map<String, dynamic>>?
  partsJson; // Serialized MessageParts (tool calls, etc.)
  final String? agent; // Agent name who responded (for assistant messages)
  final bool
  isCompactionSummary; // True for compaction summaries (agent 'compaction')
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
    this.imageName,
    this.attachedDocPath,
    this.tokensInput,
    this.tokensOutput,
    this.tokensReasoning,
    this.tokensCacheRead,
    this.tokensCacheWrite,
    this.tokensCacheIncludedInInput,
    this.contextLength,
    this.partsJson,
    this.agent,
    this.isCompactionSummary = false,
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
    String? imageName,
    String? attachedDocPath,
    int? tokensInput,
    int? tokensOutput,
    int? tokensReasoning,
    int? tokensCacheRead,
    int? tokensCacheWrite,
    bool? tokensCacheIncludedInInput,
    int? contextLength,
    List<Map<String, dynamic>>? partsJson,
    String? agent,
    bool? isCompactionSummary,
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
      imageName: imageName ?? this.imageName,
      attachedDocPath: attachedDocPath ?? this.attachedDocPath,
      tokensInput: tokensInput ?? this.tokensInput,
      tokensOutput: tokensOutput ?? this.tokensOutput,
      tokensReasoning: tokensReasoning ?? this.tokensReasoning,
      tokensCacheRead: tokensCacheRead ?? this.tokensCacheRead,
      tokensCacheWrite: tokensCacheWrite ?? this.tokensCacheWrite,
      tokensCacheIncludedInInput:
          tokensCacheIncludedInInput ?? this.tokensCacheIncludedInInput,
      contextLength: contextLength ?? this.contextLength,
      partsJson: partsJson ?? this.partsJson,
      agent: agent ?? this.agent,
      isCompactionSummary: isCompactionSummary ?? this.isCompactionSummary,
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
        other.isCompactionSummary == isCompactionSummary &&
        other.synthetic == synthetic &&
        other.tokensInput == tokensInput &&
        other.tokensOutput == tokensOutput &&
        other.tokensReasoning == tokensReasoning &&
        other.tokensCacheRead == tokensCacheRead &&
        other.tokensCacheWrite == tokensCacheWrite &&
        other.tokensCacheIncludedInInput == tokensCacheIncludedInInput;
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
      isCompactionSummary,
      synthetic,
      tokensInput,
      tokensOutput,
      tokensReasoning,
      tokensCacheRead,
      tokensCacheWrite,
      tokensCacheIncludedInInput,
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
      'imageName': imageName,
      'attachedDocPath': attachedDocPath,
      'tokensInput': tokensInput,
      'tokensOutput': tokensOutput,
      'tokensReasoning': tokensReasoning,
      'tokensCacheRead': tokensCacheRead,
      'tokensCacheWrite': tokensCacheWrite,
      'tokensCacheIncludedInInput': tokensCacheIncludedInInput,
      'contextLength': contextLength,
      'partsJson': partsJson,
      'agent': agent,
      'isCompactionSummary': isCompactionSummary,
      'synthetic': synthetic,
    };

    return json;
  }

  static Message fromJson(Map<String, dynamic> json) {
    final reasoning = json['reasoning'];
    final imageData = json['imageData'];
    final imageType = json['imageType'];
    final imageName = json['imageName'];
    final attachedDocPath = json['attachedDocPath'];

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
      imageName: imageName,
      attachedDocPath: attachedDocPath,
      tokensInput: json['tokensInput'] as int?,
      tokensOutput: json['tokensOutput'] as int?,
      tokensReasoning: json['tokensReasoning'] as int?,
      tokensCacheRead: json['tokensCacheRead'] as int?,
      tokensCacheWrite: json['tokensCacheWrite'] as int?,
      tokensCacheIncludedInInput: json['tokensCacheIncludedInInput'] as bool?,
      contextLength: json['contextLength'] as int?,
      partsJson: json['partsJson'] != null
          ? (json['partsJson'] as List<dynamic>).cast<Map<String, dynamic>>()
          : null,
      agent: json['agent'] as String?,
      isCompactionSummary: json['isCompactionSummary'] as bool? ?? false,
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
  final List<Message>? compactedContext;

  Chat({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.compactedContext,
  });

  bool get isDefaultTitle => title.isEmpty;

  SessionID toSessionId() {
    return SessionID.fromRaw(id);
  }

  Chat copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? compactedContext,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      compactedContext: compactedContext ?? this.compactedContext,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((message) => message.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (compactedContext != null)
        'compactedContext': compactedContext!
            .map((message) => message.toJson())
            .toList(),
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
      compactedContext: (json['compactedContext'] as List<dynamic>?)
          ?.map((message) => Message.fromJson(message))
          .toList(),
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
        listEquals(other.messages, messages) &&
        listEquals(other.compactedContext, compactedContext);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        Object.hashAll(messages) ^
        Object.hashAll(compactedContext ?? const []);
  }
}
