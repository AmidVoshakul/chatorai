import 'dart:convert';

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
    ) =>
      SessionState(
        id: sessionId,
        parentId: parentId,
        title: title,
        agent: agent,
        modelRef: modelRef,
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

    TextDelta _ =>
      state, // deltas are ephemeral, final state comes from TextEnded

    TextEnded(:final messageId, :final fullText, :final model) =>
      state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(content: fullText, model: model);
          }
          return m;
        }).toList(),
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
      updatedAt: event.timestamp,
    ),

    ToolInputStarted _ => state,

    ToolInputDelta _ => state,

    ToolInputEnded _ => state,

    ToolCalled(toolCallId: final toolCallId, toolName: _, input: final input) =>
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
        toolResults: [
          ...state.toolResults,
          ToolResult(
            id: toolCallId,
            toolName: '',
            input: {},
            outputText: outputText,
            durationMs: durationMs,
            status: 'success',
            createdAt: event.timestamp,
          ),
        ],
        updatedAt: event.timestamp,
      ),

    ToolFailed(:final toolCallId, :final error) => state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == toolCallId) {
          return m.copyWith(error: error);
        }
        return m;
      }).toList(),
      toolResults: [
        ...state.toolResults,
        ToolResult(
          id: toolCallId,
          toolName: '',
          input: {},
          outputText: error,
          durationMs: 0,
          status: 'error',
          createdAt: event.timestamp,
        ),
      ],
      updatedAt: event.timestamp,
    ),

    StepStarted _ => state,

    StepEnded(
      :final tokensInput,
      :final tokensOutput,
      :final tokensReasoning,
    ) =>
      state.copyWith(
        tokensInput: state.tokensInput + tokensInput,
        tokensOutput: state.tokensOutput + tokensOutput,
        tokensReasoning: state.tokensReasoning + tokensReasoning,
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
      final stored = jsonEncode({'toolName': toolName, 'input': input});
      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              id: toolCallId,
              sessionId: event.sessionId.value,
              seq: seq,
              role: 'tool',
              content: Value<String>(stored),
              createdAt: event.timestamp,
            ),
            mode: InsertMode.insertOrReplace,
          );

    case ToolSuccess(:final toolCallId, :final outputText, :final durationMs):
      final toolName = await _lookupToolName(db, toolCallId);
      await (db.update(db.messages)..where((t) => t.id.equals(toolCallId)))
          .write(MessagesCompanion(content: Value(outputText)));
      await db
          .into(db.toolResults)
          .insert(
            ToolResultsCompanion.insert(
              id: toolCallId,
              sessionId: event.sessionId.value,
              messageId: toolCallId,
              toolName: toolName,
              inputJson: Value('{}'),
              outputText: Value(outputText),
              durationMs: Value(durationMs),
              status: Value('success'),
              createdAt: event.timestamp,
            ),
            mode: InsertMode.insertOrReplace,
          );

    case ToolFailed(:final toolCallId, :final error):
      final toolName = await _lookupToolName(db, toolCallId);
      await (db.update(db.messages)..where((t) => t.id.equals(toolCallId)))
          .write(MessagesCompanion(error: Value<String?>(error)));
      await db
          .into(db.toolResults)
          .insert(
            ToolResultsCompanion.insert(
              id: toolCallId,
              sessionId: event.sessionId.value,
              messageId: toolCallId,
              toolName: toolName,
              inputJson: Value('{}'),
              outputText: Value(error),
              durationMs: Value(0),
              status: Value('error'),
              createdAt: event.timestamp,
            ),
            mode: InsertMode.insertOrReplace,
          );

    case StepEnded(
      :final tokensInput,
      :final tokensOutput,
      :final tokensReasoning,
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

/// Extracts the [toolName] from the JSON previously stored by the
/// [ToolCalled] projection. Returns the name on success, or an empty
/// string if the message row is missing or its content is malformed.
Future<String> _lookupToolName(AppDatabase db, String toolCallId) async {
  try {
    final row =
        await (db.selectOnly(db.messages)
              ..where(db.messages.id.equals(toolCallId))
              ..addColumns([db.messages.content]))
            .getSingleOrNull();
    if (row == null) return '';
    final stored = row.read(db.messages.content);
    if (stored == null || stored.isEmpty) return '';
    final parsed = jsonDecode(stored);
    if (parsed is Map && parsed['toolName'] is String) {
      return parsed['toolName'] as String;
    }
  } catch (_) {}
  return '';
}
