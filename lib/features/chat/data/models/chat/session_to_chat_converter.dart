// ── Converter: SessionState → ChatMessage ─────────────────────────────────────
// Bridges Session Core to Chat UI without legacy Message types.

import 'dart:convert';

import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';

/// Converts [SessionMessage] + [AssistantContent] parts to [ChatMessage].
ChatMessage? sessionMessageToChatMessage(
  SessionMessage sessionMsg,
  List<AssistantContent> parts,
) {
  final id = sessionMsg.id;
  final timestamp = sessionMsg.createdAt;

  switch (sessionMsg.role) {
    case MessageRole.user:
    case MessageRole.system:
      return UserMessage(
        id: id,
        content: sessionMsg.content,
        timestamp: timestamp,
      );

    case MessageRole.assistant:
    case MessageRole.tool:
      return AssistantMessage(
        id: id,
        parts: parts.map(assistantContentToMessagePart).toList(),
        model: sessionMsg.model,
        timestamp: timestamp,
      );
  }
}

/// Converts [AssistantContent] to legacy [MessagePart] for widget compatibility.
MessagePart assistantContentToMessagePart(AssistantContent content) {
  if (content is AssistantText) {
    return TextPart(content: content.text, isStreaming: content.synthetic);
  }
  if (content is AssistantReasoning) {
    return ReasoningPart(
      content: content.text,
      startedAt: content.started,
      durationMs: content.ended != null
          ? content.ended!.millisecondsSinceEpoch -
                content.started.millisecondsSinceEpoch
          : null,
      isStreaming: content.ended == null,
    );
  }
  if (content is AssistantTool) {
    final meta = <String, dynamic>{'session_id': content.sessionId};
    final files = _extractFileDiffMeta(content);
    if (files != null) {
      meta['files'] = files;
    }
    final output = content.output;
    final isErrorOutput =
        content.state == ToolState.error ||
        (output != null && output.startsWith('Error:'));
    return ToolResultPart(
      toolCallId: content.callId,
      toolName: content.tool,
      result: output,
      error: isErrorOutput ? output : null,
      state: content.state,
      input: content.input,
      metadata: meta,
    );
  }
  if (content is AssistantFile) {
    return TextPart(content: '[File: ${content.filename}]');
  }
  if (content is AssistantImage) {
    return TextPart(content: '[Image]');
  }
  if (content is AssistantAgent) {
    return TextPart(content: '[Agent: ${content.name}]');
  }
  if (content is AssistantTask) {
    final startedAt = content.startedAt;
    final endedAt = content.endedAt;
    final computedDuration = startedAt != null && endedAt != null
        ? endedAt.difference(startedAt).inMilliseconds
        : null;
    return TaskPart(
      description: content.description,
      agent: content.agent,
      status: switch (content.state) {
        ToolState.completed => TaskStatus.completed,
        ToolState.error => TaskStatus.error,
        _ => TaskStatus.running,
      },
      sessionId: content.taskSessionId,
      error: content.error,
      retryAttempt: content.retryAttempt,
      currentTool: content.currentTool,
      currentToolTitle: content.currentToolTitle,
      toolCallsCount: content.toolCallsCount,
      durationMs: content.durationMs ?? computedDuration,
      startedAt: startedAt,
    );
  }
  if (content is AssistantQuestion) {
    return QuestionPart(
      question: content.question,
      options: content.options,
      answer: content.answer,
      multiple: content.multiple,
    );
  }
  if (content is AssistantTodo) {
    return TodoPart(todos: content.todos);
  }
  if (content is RawText) {
    return TextPart(content: content.text);
  }
  if (content is RawReasoning) {
    return ReasoningPart(content: content.text, title: content.title);
  }
  return TextPart(content: '');
}

/// Converts `List<AssistantContent>` to `List<Map<String, dynamic>>` for legacy Message.
List<Map<String, dynamic>> assistantContentToPartMaps(
  List<AssistantContent> parts,
) {
  return parts
      .map(assistantContentToMessagePart)
      .map((p) => p.toJson())
      .toList();
}

/// Extracts text content from [AssistantContent] parts.
String extractTextFromParts(List<AssistantContent> parts) {
  return parts.whereType<AssistantText>().map((p) => p.text).join('\n');
}

/// Extracts reasoning content from [AssistantContent] parts.
String? extractReasoningFromParts(List<AssistantContent> parts) {
  return parts.whereType<AssistantReasoning>().firstOrNull?.text;
}

/// Filters parts belonging to a specific [messageId].
List<AssistantContent> filterPartsByMessage(
  List<AssistantContent> parts,
  String messageId,
) {
  return parts.where((p) => p.messageId == messageId).toList();
}

/// Groups [AssistantContent] parts by their messageId.
Map<String, List<AssistantContent>> groupPartsByMessage(
  List<AssistantContent> parts,
) {
  final result = <String, List<AssistantContent>>{};
  for (final part in parts) {
    if (part.messageId != null) {
      result.putIfAbsent(part.messageId!, () => []).add(part);
    }
  }
  return result;
}

/// Extracts per-file diff metadata from tool output for edit/apply_patch/write tools.
List<Map<String, dynamic>>? _extractFileDiffMeta(AssistantTool tool) {
  final toolName = tool.tool.toLowerCase();
  final output = tool.output;
  if (output == null || output.isEmpty) return null;

  final files = <Map<String, dynamic>>[];

  try {
    if (toolName == 'edit') {
      final parsed = _parseToolJson(output);
      if (parsed == null) return null;
      final patch = parsed['patch'] as String? ?? '';
      final path =
          tool.input['filePath'] as String? ??
          tool.input['file_path'] as String? ??
          '';
      files.add(_fileEntry(path, patch));
    } else if (toolName == 'apply_patch') {
      final parsed = _parseToolJson(output);
      if (parsed == null) return null;
      final patches = parsed['patches'] as List<dynamic>?;
      if (patches != null) {
        for (final p in patches) {
          final path = p['path'] as String? ?? '';
          final patch = p['patch'] as String? ?? '';
          files.add(_fileEntry(path, patch));
        }
      }
    } else if (toolName == 'write') {
      final path =
          tool.input['filePath'] as String? ??
          tool.input['file_path'] as String? ??
          '';
      files.add(_fileEntry(path, ''));
    }
  } catch (_) {
    return null;
  }

  return files.isNotEmpty ? files : null;
}

Map<String, dynamic>? _parseToolJson(String output) {
  final lspHeader = output.contains('\nLSP')
      ? output.indexOf('\nLSP')
      : output.length;
  final jsonPart = output.substring(0, lspHeader).trim();
  if (jsonPart.isEmpty) return null;
  try {
    return jsonDecode(jsonPart) as Map<String, dynamic>;
  } on FormatException {
    return null;
  }
}

Map<String, dynamic> _fileEntry(String path, String patch) {
  final lines = patch.isNotEmpty ? '\n'.allMatches(patch).length : 0;
  final additions = patch.isNotEmpty ? '+\n'.allMatches(patch).length : 0;
  final deletions = patch.isNotEmpty ? '-\n'.allMatches(patch).length : 0;
  return {
    'path': path,
    'patch_length': patch.length,
    if (lines > 0) 'lines': lines,
    if (additions > 0) 'additions': additions,
    if (deletions > 0) 'deletions': deletions,
  };
}
