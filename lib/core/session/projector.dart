import 'dart:convert';

import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:drift/drift.dart';

import 'database.dart' hide ToolResult;
import 'events.dart';
import 'session_id.dart';
import 'session_state.dart';

/// Pure function: applies a single event to SessionState and returns new state.
SessionState projectEvent(SessionState state, SessionEvent event) {
  return switch (event) {
    SessionCreated(
      :final sessionId,
      :final parentId,
      :final title,
      :final agent,
      :final modelRef,
      :final permission,
    ) =>
      SessionState(
        id: sessionId,
        parentId: parentId,
        title: title,
        agent: agent,
        modelRef: modelRef,
        permission: permission,
        createdAt: event.timestamp,
        updatedAt: event.timestamp,
      ),

    SessionArchived _ => state.copyWith(
      archivedAt: event.timestamp,
      updatedAt: event.timestamp,
    ),

    SessionAgentSwitched(:final agent) => state.copyWith(
      agent: agent,
      updatedAt: event.timestamp,
    ),

    SessionModelSwitched(:final modelRef) => state.copyWith(
      modelRef: modelRef,
      updatedAt: event.timestamp,
    ),

    MessageAdded(:final messageId, :final role, :final content) =>
      state.copyWith(
        messages: [
          ...state.messages,
          SessionMessage(
            id: messageId,
            role: _roleFromString(role),
            content: content,
            seq: state.messages.length + 1,
            createdAt: event.timestamp,
          ),
        ],
        updatedAt: event.timestamp,
      ),

    TextStarted(:final messageId) => state.copyWith(
      messages: [
        ...state.messages,
        SessionMessage(
          id: messageId,
          role: MessageRole.assistant,
          content: '',
          seq: state.messages.length + 1,
          createdAt: event.timestamp,
        ),
      ],
      updatedAt: event.timestamp,
    ),

    TextDelta(:final messageId, :final delta) => state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(content: (m.content + delta));
        }
        return m;
      }).toList(),
      updatedAt: event.timestamp,
    ),

    TextEnded(:final messageId, :final fullText, :final model) =>
      state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(content: fullText, model: model);
          }
          return m;
        }).toList(),
        parts: [
          ...state.parts,
          AssistantText(
            id: 'part_${event.timestamp.millisecondsSinceEpoch}',
            sessionId: event.sessionId.value,
            messageId: messageId,
            text: fullText,
          ),
        ],
        updatedAt: event.timestamp,
      ),

    ReasoningStarted _ => state,

    ReasoningDelta _ => state,

    ReasoningEnded(:final messageId, :final fullReasoning) => state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(reasoning: fullReasoning);
        }
        return m;
      }).toList(),
      parts: _appendReasoningPart(
        state.parts,
        fullReasoning,
        messageId,
        event.sessionId.value,
      ),
      updatedAt: event.timestamp,
    ),

    ToolInputStarted _ => state,

    ToolInputDelta _ => state,

    ToolInputEnded _ => state,

    ToolCalled(
      toolCallId: final toolCallId,
      toolName: final toolName,
      input: final input,
    ) =>
      state.copyWith(
        messages: [
          ...state.messages,
          SessionMessage(
            id: toolCallId,
            role: MessageRole.tool,
            content: jsonEncode(input),
            seq: state.messages.length + 1,
            createdAt: event.timestamp,
          ),
        ],
        toolResults: [
          ...state.toolResults,
          ToolResult(
            id: toolCallId,
            toolName: toolName,
            input: input,
            outputText: '',
            durationMs: 0,
            status: 'running',
            createdAt: event.timestamp,
          ),
        ],
        parts: [
          ...state.parts,
          AssistantTool(
            id: 'part_${event.timestamp.millisecondsSinceEpoch}',
            sessionId: event.sessionId.value,
            messageId: _lastAssistantMsgId(state),
            callId: toolCallId,
            tool: toolName,
            state: ToolState.running,
            input: input,
          ),
        ],
        updatedAt: event.timestamp,
      ),

    ToolSuccess(:final toolCallId, :final outputText, :final durationMs) =>
      state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == toolCallId) {
            return m.copyWith(content: outputText);
          }
          return m;
        }).toList(),
        toolResults: _updateToolResult(
          state.toolResults,
          toolCallId,
          (tr) => ToolResult(
            id: tr.id,
            toolName: tr.toolName,
            input: tr.input,
            outputText: outputText,
            durationMs: durationMs,
            status: 'success',
            createdAt: event.timestamp,
          ),
          () => ToolResult(
            id: toolCallId,
            toolName: '',
            input: {},
            outputText: outputText,
            durationMs: durationMs,
            status: 'success',
            createdAt: event.timestamp,
          ),
        ),
        parts: _updateToolPart(
          state.parts,
          toolCallId,
          ToolState.completed,
          outputText: outputText,
          durationMs: durationMs,
        ),
        updatedAt: event.timestamp,
      ),

    ToolFailed(:final toolCallId, :final error) => state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == toolCallId) {
          return m.copyWith(error: error);
        }
        return m;
      }).toList(),
      toolResults: _updateToolResult(
        state.toolResults,
        toolCallId,
        (tr) => ToolResult(
          id: tr.id,
          toolName: tr.toolName,
          input: tr.input,
          outputText: error,
          durationMs: 0,
          status: 'error',
          createdAt: event.timestamp,
        ),
        () => ToolResult(
          id: toolCallId,
          toolName: '',
          input: {},
          outputText: error,
          durationMs: 0,
          status: 'error',
          createdAt: event.timestamp,
        ),
      ),
      parts: _updateToolPart(
        state.parts,
        toolCallId,
        ToolState.error,
        outputText: error,
      ),
      updatedAt: event.timestamp,
    ),

    StepStarted _ => state,

    StepEnded(
      :final tokensInput,
      :final tokensOutput,
      :final tokensReasoning,
      :final tokensCacheRead,
      :final tokensCacheWrite,
    ) =>
      state.copyWith(
        tokensInput: state.tokensInput + tokensInput,
        tokensOutput: state.tokensOutput + tokensOutput,
        tokensReasoning: state.tokensReasoning + tokensReasoning,
        tokensCacheRead: state.tokensCacheRead + tokensCacheRead,
        tokensCacheWrite: state.tokensCacheWrite + tokensCacheWrite,
        updatedAt: event.timestamp,
      ),

    StepFailed _ => state.copyWith(updatedAt: event.timestamp),

    CompactionStarted _ => state,

    CompactionEnded _ => state.copyWith(updatedAt: event.timestamp),

    ChildSessionCreated _ => state.copyWith(updatedAt: event.timestamp),

    TaskStarted _ => state,

    TaskCompleted(:final taskId, :final output) => state.copyWith(
      messages: [
        ...state.messages,
        SessionMessage(
          id: taskId,
          role: MessageRole.assistant,
          content: output,
          seq: state.messages.length + 1,
          createdAt: event.timestamp,
        ),
      ],
      updatedAt: event.timestamp,
    ),
  };
}

/// Project an event into denormalized drift tables for fast querying.
Future<void> projectToDb(AppDatabase db, SessionEvent event) async {
  switch (event) {
    case SessionCreated(
      :final sessionId,
      :final parentId,
      :final title,
      :final agent,
      :final modelRef,
      :final permission,
    ):
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: sessionId.value,
              parentId: parentId != null
                  ? Value<String?>(parentId.value)
                  : const Value.absent(),
              title: Value(title),
              agent: Value(agent),
              modelRef: modelRef != null
                  ? Value<String?>(modelRef)
                  : const Value.absent(),
              permissionRules: permission != null
                  ? Value<String?>(jsonEncode(_serializePermission(permission)))
                  : const Value.absent(),
              createdAt: event.timestamp,
              updatedAt: event.timestamp,
            ),
          );

    case SessionArchived():
      await (db.update(
        db.sessions,
      )..where((s) => s.id.equals(event.sessionId.value))).write(
        SessionsCompanion(
          archivedAt: Value(event.timestamp),
          updatedAt: Value(event.timestamp),
        ),
      );

    case SessionAgentSwitched(:final agent):
      await (db.update(
        db.sessions,
      )..where((s) => s.id.equals(event.sessionId.value))).write(
        SessionsCompanion(
          agent: Value(agent),
          updatedAt: Value(event.timestamp),
        ),
      );

    case SessionModelSwitched(:final modelRef):
      await (db.update(
        db.sessions,
      )..where((s) => s.id.equals(event.sessionId.value))).write(
        SessionsCompanion(
          modelRef: Value<String?>(modelRef),
          updatedAt: Value(event.timestamp),
        ),
      );

    case MessageAdded(:final messageId, :final role, :final content):
      final seq = await _existingOrNextMessageSeq(
        db,
        event.sessionId,
        messageId,
      );
      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              id: messageId,
              sessionId: event.sessionId.value,
              seq: seq,
              role: role,
              content: Value<String>(content),
              createdAt: event.timestamp,
            ),
            mode: InsertMode.insertOrReplace,
          );

    case TextStarted(:final messageId):
      final seq = await _existingOrNextMessageSeq(
        db,
        event.sessionId,
        messageId,
      );
      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              id: messageId,
              sessionId: event.sessionId.value,
              seq: seq,
              role: 'assistant',
              content: const Value<String>(''),
              createdAt: event.timestamp,
            ),
            mode: InsertMode.insertOrReplace,
          );

    case TextEnded(:final messageId, :final fullText, :final model):
      await (db.update(
        db.messages,
      )..where((t) => t.id.equals(messageId))).write(
        MessagesCompanion(
          content: Value(fullText),
          model: Value<String?>(model),
        ),
      );

    case ReasoningEnded(:final messageId, :final fullReasoning):
      await (db.update(db.messages)..where((t) => t.id.equals(messageId)))
          .write(MessagesCompanion(reasoning: Value<String?>(fullReasoning)));

    case ToolCalled(
      toolCallId: final toolCallId,
      toolName: final toolName,
      input: final input,
    ):
      final seq = await _existingOrNextMessageSeq(
        db,
        event.sessionId,
        toolCallId,
      );
      final inputJson = jsonEncode(input);
      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              id: toolCallId,
              sessionId: event.sessionId.value,
              seq: seq,
              role: 'tool',
              content: Value<String>(inputJson),
              createdAt: event.timestamp,
            ),
            mode: InsertMode.insertOrReplace,
          );
      await db
          .into(db.toolResults)
          .insert(
            ToolResultsCompanion.insert(
              id: toolCallId,
              sessionId: event.sessionId.value,
              messageId: toolCallId,
              toolName: toolName,
              inputJson: Value(inputJson),
              outputText: Value(''),
              durationMs: const Value(0),
              status: const Value('running'),
              createdAt: event.timestamp,
            ),
            mode: InsertMode.insertOrReplace,
          );

    case ToolSuccess(:final toolCallId, :final outputText, :final durationMs):
      final toolName = await _lookupToolName(db, toolCallId);
      await (db.update(db.messages)..where((t) => t.id.equals(toolCallId)))
          .write(MessagesCompanion(content: Value(outputText)));
      await (db
          .into(db.toolResults)
          .insert(
            ToolResultsCompanion.insert(
              id: toolCallId,
              sessionId: event.sessionId.value,
              messageId: toolCallId,
              toolName: toolName,
              inputJson: const Value('{}'),
              outputText: Value(outputText),
              durationMs: Value(durationMs),
              status: const Value('success'),
              createdAt: event.timestamp,
            ),
            mode: InsertMode.insertOrReplace,
          ));

    case ToolFailed(:final toolCallId, :final error):
      final toolName = await _lookupToolName(db, toolCallId);
      await (db.update(db.messages)..where((t) => t.id.equals(toolCallId)))
          .write(MessagesCompanion(error: Value<String?>(error)));
      await (db
          .into(db.toolResults)
          .insert(
            ToolResultsCompanion.insert(
              id: toolCallId,
              sessionId: event.sessionId.value,
              messageId: toolCallId,
              toolName: toolName,
              inputJson: const Value('{}'),
              outputText: Value(error),
              durationMs: const Value(0),
              status: const Value('error'),
              createdAt: event.timestamp,
            ),
            mode: InsertMode.insertOrReplace,
          ));

    case StepEnded(
      :final tokensInput,
      :final tokensOutput,
      :final tokensReasoning,
      :final tokensCacheRead,
      :final tokensCacheWrite,
    ):
      final current = await (db.select(
        db.sessions,
      )..where((s) => s.id.equals(event.sessionId.value))).getSingle();
      await (db.update(
        db.sessions,
      )..where((s) => s.id.equals(event.sessionId.value))).write(
        SessionsCompanion(
          tokensInput: Value(current.tokensInput + tokensInput),
          tokensOutput: Value(current.tokensOutput + tokensOutput),
          tokensReasoning: Value(current.tokensReasoning + tokensReasoning),
          tokensCacheRead: Value(current.tokensCacheRead + tokensCacheRead),
          tokensCacheWrite: Value(current.tokensCacheWrite + tokensCacheWrite),
          updatedAt: Value(event.timestamp),
        ),
      );

    case ChildSessionCreated(
      childSessionId: _,
      parentSessionId: _,
      title: _,
      agent: _,
      modelRef: _,
    ):
      // Do not insert a new session row here — the child session is already
      // created via a preceding SessionCreated event. Instead update the
      // parent session's updatedAt to reflect the delegation.
      await (db.update(db.sessions)
            ..where((s) => s.id.equals(event.sessionId.value)))
          .write(SessionsCompanion(updatedAt: Value(event.timestamp)));
      break;

    default:
      break;
  }
}

/// Rebuild state by replaying all events from scratch.
SessionState replayEvents(Iterable<SessionEvent> events) {
  final firstEvent = events.first;
  var state = SessionState(
    id: firstEvent.sessionId,
    createdAt: firstEvent.timestamp,
    updatedAt: firstEvent.timestamp,
  );
  for (final event in events) {
    state = projectEvent(state, event);
  }
  return state;
}

/// Updates or appends a [ToolResult] in the list.
/// If [toolCallId] exists, applies [update]; otherwise appends via [create].
List<ToolResult> _updateToolResult(
  List<ToolResult> results,
  String toolCallId,
  ToolResult Function(ToolResult) update,
  ToolResult Function() create,
) {
  var found = false;
  final updated = results.map((tr) {
    if (tr.id == toolCallId) {
      found = true;
      return update(tr);
    }
    return tr;
  }).toList();
  if (!found) {
    updated.add(create());
  }
  return updated;
}

/// Finds the last assistant message ID from [state].
/// Used to associate tool calls with the assistant message that generated them.
String _lastAssistantMsgId(SessionState state) {
  for (var i = state.messages.length - 1; i >= 0; i--) {
    if (state.messages[i].role == MessageRole.assistant) {
      return state.messages[i].id;
    }
  }
  return '';
}

// ── Helper functions for typed AssistantContent parts ──────────────────────

/// Appends a reasoning part to the parts list.
/// Inserts before the last text part if present (ReasoningEnded often arrives
/// after TextEnded in the runner, but reasoning should display before text).
List<AssistantContent> _appendReasoningPart(
  List<AssistantContent> parts,
  String content,
  String messageId,
  String sessionId,
) {
  final reasoningPart = AssistantReasoning(
    id: 'part_${DateTime.now().microsecondsSinceEpoch}',
    sessionId: sessionId,
    messageId: messageId,
    text: content,
    started: DateTime.now(),
  );

  if (parts.isNotEmpty && parts.any((p) => p is AssistantText)) {
    final textIndex = parts.lastIndexWhere((p) => p is AssistantText);
    return [
      ...parts.sublist(0, textIndex),
      reasoningPart,
      ...parts.sublist(textIndex),
    ];
  }
  return [...parts, reasoningPart];
}

/// Updates a tool part in the parts list by [toolCallId].
/// Sets [state] and adds optional [outputText]/[durationMs].
List<AssistantContent> _updateToolPart(
  List<AssistantContent> parts,
  String toolCallId,
  ToolState newState, {
  String? outputText,
  int? durationMs,
}) {
  return parts.map((p) {
    if (p is AssistantTool && p.callId == toolCallId) {
      return p.copyWith(
        state: newState,
        output: outputText,
        durationMs: durationMs ?? p.durationMs,
      );
    }
    return p;
  }).toList();
}

// ── Legacy helpers kept for compatibility ───────────────────────────────────

// === Helpers ===

MessageRole _roleFromString(String role) {
  return switch (role) {
    'user' => MessageRole.user,
    'assistant' => MessageRole.assistant,
    'tool' => MessageRole.tool,
    _ => throw ArgumentError('Unknown role: $role'),
  };
}

Future<int> _nextMessageSeq(AppDatabase db, SessionID sessionId) async {
  final row =
      await (db.selectOnly(db.messages)
            ..where(db.messages.sessionId.equals(sessionId.value))
            ..addColumns([db.messages.seq.max()]))
          .getSingleOrNull();
  return ((row?.read(db.messages.seq.max()) ?? 0) + 1);
}

/// Returns the existing [seq] for [messageId] if it exists, otherwise
/// computes the next available sequence number for [sessionId].
/// Prevents [seq] inflation when [InsertMode.insertOrReplace] re-inserts
/// an already‑stored message (e.g. duplicate tool events).
Future<int> _existingOrNextMessageSeq(
  AppDatabase db,
  SessionID sessionId,
  String messageId,
) async {
  final row =
      await (db.selectOnly(db.messages)
            ..where(db.messages.id.equals(messageId))
            ..addColumns([db.messages.seq]))
          .getSingleOrNull();
  if (row != null) {
    final seq = row.read(db.messages.seq);
    if (seq != null) return seq;
  }
  return _nextMessageSeq(db, sessionId);
}

/// Extracts the [toolName] from the [toolResults] table previously stored
/// by the [ToolCalled] projection. Returns the name on success, or an empty
/// string if the row is missing.
Future<String> _lookupToolName(AppDatabase db, String toolCallId) async {
  if (toolCallId.isEmpty) return '';
  final row =
      await (db.selectOnly(db.toolResults)
            ..where(db.toolResults.id.equals(toolCallId))
            ..addColumns([db.toolResults.toolName]))
          .getSingleOrNull();
  if (row == null) return '';
  final name = row.read(db.toolResults.toolName);
  return name ?? '';
}

Map<String, dynamic>? _serializePermission(PermissionRuleset? pr) {
  if (pr == null) return null;
  if (pr.rules.isEmpty && pr.sessionApproved.isEmpty) return null;
  return {
    'rules': pr.rules
        .map(
          (r) => {
            'permission': r.permission,
            'pattern': r.pattern,
            'action': r.action.name,
          },
        )
        .toList(),
    'sessionApproved': pr.sessionApproved
        .map(
          (r) => {
            'permission': r.permission,
            'pattern': r.pattern,
            'action': r.action.name,
          },
        )
        .toList(),
  };
}
