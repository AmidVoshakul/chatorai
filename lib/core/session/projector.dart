import 'dart:convert';

import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart';
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

    TextStarted(:final messageId, :final partId) => state.copyWith(
      messages: state.messages.any((m) => m.id == messageId)
          ? state.messages
          : [
              ...state.messages,
              SessionMessage(
                id: messageId,
                role: MessageRole.assistant,
                content: '',
                seq: state.messages.length + 1,
                createdAt: event.timestamp,
              ),
            ],
      parts: [
        ..._closeOpenReasoning(state.parts, event.timestamp),
        AssistantText(
          id:
              partId ??
              'part_${event.timestamp.millisecondsSinceEpoch}_$messageId',
          sessionId: event.sessionId.value,
          messageId: messageId,
          text: '',
          synthetic: true,
        ),
      ],
      updatedAt: event.timestamp,
    ),

    TextDelta(:final messageId, :final delta, :final partId) => state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(content: (m.content + delta));
        }
        return m;
      }).toList(),
      parts: partId != null && partId.isNotEmpty
          ? _updatePartById<AssistantText>(
              state.parts,
              partId,
              (current) => AssistantText(
                id: current.id!,
                sessionId: current.sessionId!,
                messageId: current.messageId!,
                text: current.text + delta,
                synthetic: current.synthetic,
                ignored: current.ignored,
                title: current.title,
              ),
            )
          : _updateLastTextPart(state.parts, messageId, delta),
      updatedAt: event.timestamp,
    ),

    TextEnded(:final messageId, :final fullText, :final model, :final partId) =>
      state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(content: fullText, model: model);
          }
          return m;
        }).toList(),
        parts: partId != null && partId.isNotEmpty
            ? _updatePartById<AssistantText>(
                state.parts,
                partId,
                (current) => AssistantText(
                  id: current.id!,
                  sessionId: current.sessionId!,
                  messageId: current.messageId!,
                  text: fullText,
                  synthetic: current.synthetic,
                  ignored: current.ignored,
                  title: current.title,
                ),
              )
            : state.parts.map((p) {
                if (p is AssistantText && p.messageId == messageId) {
                  return AssistantText(
                    id: p.id!,
                    sessionId: p.sessionId!,
                    messageId: p.messageId!,
                    text: fullText,
                    synthetic: p.synthetic,
                    ignored: p.ignored,
                    title: p.title,
                  );
                }
                return p;
              }).toList(),
        updatedAt: event.timestamp,
      ),

    ReasoningStarted(:final messageId, :final partId) => state.copyWith(
      messages: state.messages.any((m) => m.id == messageId)
          ? state.messages
          : [
              ...state.messages,
              SessionMessage(
                id: messageId,
                role: MessageRole.assistant,
                content: '',
                seq: state.messages.length + 1,
                createdAt: event.timestamp,
              ),
            ],
      parts: [
        ...state.parts,
        AssistantReasoning(
          id:
              partId ??
              'part_${event.timestamp.millisecondsSinceEpoch}_$messageId',
          sessionId: event.sessionId.value,
          messageId: messageId,
          text: '',
          started: event.timestamp,
        ),
      ],
      updatedAt: event.timestamp,
    ),

    ReasoningDelta(:final messageId, :final delta, :final partId) =>
      state.copyWith(
        parts: partId != null && partId.isNotEmpty
            ? _updatePartById<AssistantReasoning>(
                state.parts,
                partId,
                (current) => AssistantReasoning(
                  id: current.id!,
                  sessionId: current.sessionId!,
                  messageId: current.messageId!,
                  text: current.text + delta,
                  started: current.started,
                  ended: current.ended,
                ),
              )
            : _updateLastReasoningPart(state.parts, messageId, delta),
        updatedAt: event.timestamp,
      ),

    ReasoningEnded(:final messageId, :final fullReasoning, :final partId) =>
      state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(reasoning: fullReasoning);
          }
          return m;
        }).toList(),
        parts: partId != null && partId.isNotEmpty
            ? _updatePartById<AssistantReasoning>(
                state.parts,
                partId,
                (current) => AssistantReasoning(
                  id: current.id!,
                  sessionId: current.sessionId!,
                  messageId: current.messageId!,
                  text: fullReasoning,
                  started: current.started,
                  ended: event.timestamp,
                ),
              )
            : _updateLastReasoningPart(
                state.parts,
                messageId,
                fullReasoning,
                ended: event.timestamp,
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
      partId: final partId,
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
          ..._closeOpenReasoning(state.parts, event.timestamp),
          AssistantTool(
            id:
                partId ??
                'part_${event.timestamp.millisecondsSinceEpoch}_$toolCallId',
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

    ToolSuccess(
      :final toolCallId,
      :final outputText,
      :final partId,
      :final durationMs,
      :final input,
    ) =>
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
            input: input ?? tr.input,
            outputText: outputText,
            durationMs: durationMs,
            status: 'success',
            createdAt: event.timestamp,
          ),
          () => ToolResult(
            id: toolCallId,
            toolName: '',
            input: input ?? const {},
            outputText: outputText,
            durationMs: durationMs,
            status: 'success',
            createdAt: event.timestamp,
          ),
        ),
        parts: partId != null && partId.isNotEmpty
            ? _updatePartById<AssistantTool>(
                state.parts,
                partId,
                (current) => current.copyWith(
                  state: ToolState.completed,
                  input: input ?? current.input,
                  output: outputText,
                  durationMs: durationMs,
                ),
              )
            : _updateToolPart(
                state.parts,
                toolCallId,
                ToolState.completed,
                outputText: outputText,
                durationMs: durationMs,
              ),
        updatedAt: event.timestamp,
      ),

    ToolFailed(
      :final toolCallId,
      :final error,
      :final partId,
      :final durationMs,
      :final input,
    ) =>
      state.copyWith(
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
            input: input ?? tr.input,
            outputText: error,
            durationMs: durationMs,
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
        parts: partId != null && partId.isNotEmpty
            ? _updatePartById<AssistantTool>(
                state.parts,
                partId,
                (current) => AssistantTool(
                  id: current.id!,
                  sessionId: current.sessionId!,
                  messageId: current.messageId!,
                  callId: current.callId,
                  tool: current.tool,
                  state: ToolState.error,
                  input: current.input,
                  output: error,
                ),
              )
            : _updateToolPart(
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

    TaskCompleted(:final taskId) => state.copyWith(
      parts: _updatePartById<AssistantTask>(
        state.parts,
        taskId,
        (current) => AssistantTask(
          id: current.id!,
          sessionId: current.sessionId!,
          messageId: current.messageId!,
          description: current.description,
          agent: current.agent,
          state: ToolState.completed,
          taskSessionId: current.taskSessionId,
          error: null,
          retryAttempt: current.retryAttempt,
          currentTool: null,
          currentToolTitle: null,
          toolCallsCount: current.toolCallsCount,
          durationMs: current.durationMs,
          startedAt: current.startedAt,
          endedAt: event.timestamp,
        ),
      ),
      updatedAt: event.timestamp,
    ),

    TaskPartStarted(
      :final partId,
      :final description,
      :final agent,
      :final taskSessionId,
    ) =>
      state.copyWith(
        parts: [
          ..._closeOpenReasoning(state.parts, event.timestamp),
          AssistantTask(
            id: partId,
            sessionId: event.sessionId.value,
            messageId: _lastAssistantMsgId(state),
            description: description,
            agent: agent,
            state: ToolState.running,
            taskSessionId: taskSessionId,
            startedAt: event.timestamp,
          ),
        ],
        updatedAt: event.timestamp,
      ),

    TaskPartCompleted(:final partId) => state.copyWith(
      parts: _updatePartById<AssistantTask>(
        state.parts,
        partId,
        (current) => AssistantTask(
          id: current.id!,
          sessionId: current.sessionId!,
          messageId: current.messageId!,
          description: current.description,
          agent: current.agent,
          state: ToolState.completed,
          taskSessionId: current.taskSessionId,
          error: null,
          retryAttempt: current.retryAttempt,
          currentTool: null,
          currentToolTitle: null,
          toolCallsCount: current.toolCallsCount,
          durationMs: current.durationMs,
          startedAt: current.startedAt,
          endedAt: event.timestamp,
        ),
      ),
      updatedAt: event.timestamp,
    ),

    TaskPartError(:final partId, :final error) => state.copyWith(
      parts: _updatePartById<AssistantTask>(
        state.parts,
        partId,
        (current) => AssistantTask(
          id: current.id!,
          sessionId: current.sessionId!,
          messageId: current.messageId!,
          description: current.description,
          agent: current.agent,
          state: ToolState.error,
          taskSessionId: current.taskSessionId,
          error: error,
          retryAttempt: current.retryAttempt,
          currentTool: null,
          currentToolTitle: null,
          toolCallsCount: current.toolCallsCount,
          durationMs: current.durationMs,
          startedAt: current.startedAt,
          endedAt: event.timestamp,
        ),
      ),
      updatedAt: event.timestamp,
    ),

    QuestionPartStarted(:final partId, :final questionText, :final options) =>
      state.copyWith(
        parts: [
          ..._closeOpenReasoning(state.parts, event.timestamp),
          AssistantQuestion(
            id: partId,
            sessionId: event.sessionId.value,
            messageId: _lastAssistantMsgId(state),
            question: questionText,
            options: options,
          ),
        ],
        updatedAt: event.timestamp,
      ),

    QuestionPartAnswered(:final partId, :final answer) => state.copyWith(
      parts: _updatePartById<AssistantQuestion>(
        state.parts,
        partId,
        (current) => AssistantQuestion(
          id: current.id!,
          sessionId: current.sessionId!,
          messageId: current.messageId!,
          question: current.question,
          options: current.options,
          answer: answer,
        ),
      ),
      updatedAt: event.timestamp,
    ),

    TodoPartStarted(:final partId, :final todos) => state.copyWith(
      parts: [
        ..._closeOpenReasoning(state.parts, event.timestamp),
        AssistantTodo(
          id: partId,
          sessionId: event.sessionId.value,
          messageId: _lastAssistantMsgId(state),
          todos: todos,
        ),
      ],
      updatedAt: event.timestamp,
    ),

    TodoPartCompleted _ => state,
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

    case ToolSuccess(
      :final toolCallId,
      :final outputText,
      :final durationMs,
      :final input,
    ):
      final toolName = await _lookupToolName(db, toolCallId);
      await (db.update(db.messages)..where((t) => t.id.equals(toolCallId)))
          .write(MessagesCompanion(content: Value(outputText)));
      final existingInput = await _lookupInputJson(db, toolCallId);
      final inputJson = input != null ? jsonEncode(input) : existingInput;
      await (db
          .into(db.toolResults)
          .insert(
            ToolResultsCompanion.insert(
              id: toolCallId,
              sessionId: event.sessionId.value,
              messageId: toolCallId,
              toolName: toolName,
              inputJson: inputJson != null
                  ? Value(inputJson)
                  : const Value.absent(),
              outputText: Value(outputText),
              durationMs: Value(durationMs),
              status: const Value('success'),
              createdAt: event.timestamp,
            ),
            mode: InsertMode.insertOrReplace,
          ));

    case ToolFailed(
      :final toolCallId,
      :final error,
      :final durationMs,
      :final input,
    ):
      final toolName = await _lookupToolName(db, toolCallId);
      await (db.update(db.messages)..where((t) => t.id.equals(toolCallId)))
          .write(MessagesCompanion(error: Value<String?>(error)));
      final existingInput = await _lookupInputJson(db, toolCallId);
      final inputJson = input != null ? jsonEncode(input) : existingInput;
      await (db
          .into(db.toolResults)
          .insert(
            ToolResultsCompanion.insert(
              id: toolCallId,
              sessionId: event.sessionId.value,
              messageId: toolCallId,
              toolName: toolName,
              inputJson: inputJson != null
                  ? Value(inputJson)
                  : const Value.absent(),
              outputText: Value(error),
              durationMs: Value(durationMs),
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
      await (db.update(
        db.sessions,
      )..where((s) => s.id.equals(event.sessionId.value))).write(
        SessionsCompanion.custom(
          tokensInput: CustomExpression<int>('tokens_input + $tokensInput'),
          tokensOutput: CustomExpression<int>('tokens_output + $tokensOutput'),
          tokensReasoning: CustomExpression<int>(
            'tokens_reasoning + $tokensReasoning',
          ),
          tokensCacheRead: CustomExpression<int>(
            'tokens_cache_read + $tokensCacheRead',
          ),
          tokensCacheWrite: CustomExpression<int>(
            'tokens_cache_write + $tokensCacheWrite',
          ),
          updatedAt: Constant(event.timestamp),
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

/// Updates the last [AssistantReasoning] part for [messageId] with new [text].
/// Optionally sets its [ended] timestamp.
/// Reasoning parts are kept before any text parts for the same messageId
/// so that the display order matches the parent window: thoughts → answer.
List<AssistantContent> _updateLastReasoningPart(
  List<AssistantContent> parts,
  String messageId,
  String text, {
  DateTime? ended,
}) {
  final idx = parts.lastIndexWhere(
    (p) =>
        p is AssistantReasoning && p.messageId == messageId && p.ended == null,
  );
  if (idx == -1) return parts;
  final existing = parts[idx] as AssistantReasoning;
  final updated = AssistantReasoning(
    id: existing.id!,
    sessionId: existing.sessionId!,
    messageId: existing.messageId!,
    text: text,
    started: existing.started,
    ended: ended,
  );
  final without = List<AssistantContent>.from(parts)..removeAt(idx);
  final textIdx = without.indexWhere(
    (p) => p is AssistantText && p.messageId == messageId,
  );
  if (textIdx == -1) return without..insert(idx, updated);
  return without..insert(textIdx, updated);
}

// ── Helper functions for typed AssistantContent parts ──────────────────────

/// Closes the last open AssistantReasoning (ended == null) by setting its
/// [ended] timestamp to [now]. This prevents subsequent ReasoningDelta events
/// from merging into a block that should be independent (e.g. separated by a
/// tool call, question, or task).
///
/// Mirror of ChatScreenNotifier._closeOpenReasoning — both must stay in sync.
List<AssistantContent> _closeOpenReasoning(
  List<AssistantContent> parts,
  DateTime now,
) {
  final idx = parts.lastIndexWhere(
    (p) => p is AssistantReasoning && p.ended == null,
  );
  if (idx == -1) return parts;
  final existing = parts[idx] as AssistantReasoning;
  return [
    ...parts.sublist(0, idx),
    AssistantReasoning(
      id: existing.id!,
      sessionId: existing.sessionId!,
      messageId: existing.messageId!,
      text: existing.text,
      started: existing.started,
      ended: now,
    ),
    ...parts.sublist(idx + 1),
  ];
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

List<AssistantContent> _updatePartById<T extends AssistantContent>(
  List<AssistantContent> parts,
  String partId,
  T Function(T current) update,
) {
  final idx = parts.indexWhere((p) => p.id == partId);
  if (idx == -1) return parts;
  final updated = List<AssistantContent>.from(parts);
  updated[idx] = update(updated[idx] as T);
  return updated;
}

List<AssistantContent> _updateLastTextPart(
  List<AssistantContent> parts,
  String messageId,
  String delta,
) {
  final idx = parts.lastIndexWhere(
    (p) => p is AssistantText && p.messageId == messageId,
  );
  if (idx == -1) return parts;
  final existing = parts[idx] as AssistantText;
  final updated = AssistantText(
    id: existing.id!,
    sessionId: existing.sessionId!,
    messageId: existing.messageId!,
    text: existing.text + delta,
    synthetic: existing.synthetic,
    ignored: existing.ignored,
    title: existing.title,
  );
  return [...parts.sublist(0, idx), updated, ...parts.sublist(idx + 1)];
}

/// Updates a tool part in the parts list by [toolCallId].
/// Sets [state] and adds optional [outputText].
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
    'system' => MessageRole.system,
    'tool' => MessageRole.tool,
    _ => MessageRole.user,
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

/// Fetches the existing input JSON from the tool_results table for the given
/// [toolCallId]. Returns null if no row exists.
Future<String?> _lookupInputJson(AppDatabase db, String toolCallId) async {
  if (toolCallId.isEmpty) return null;
  final row =
      await (db.selectOnly(db.toolResults)
            ..where(db.toolResults.id.equals(toolCallId))
            ..addColumns([db.toolResults.inputJson]))
          .getSingleOrNull();
  return row?.read(db.toolResults.inputJson);
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
