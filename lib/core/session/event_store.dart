import 'dart:convert';

import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';
import 'package:chatorai/features/chat/data/models/chat/todo_part.dart';
import 'package:drift/drift.dart';

import 'database.dart' as db;
import 'events.dart';
import 'session_id.dart';

/// Append-only event store that persists [SessionEvent]s to the `events`
/// SQLite table and allows replaying them via sequence-ordered queries.
class EventStore {
  final db.AppDatabase _db;

  EventStore(this._db);

  /// Append a single event.
  Future<int> append(SessionEvent event) async {
    final seq = await _nextSequence(event.sessionId);
    final data = _serialize(event);

    return await _db
        .into(_db.events)
        .insert(
          db.EventsCompanion.insert(
            sessionId: event.sessionId.value,
            eventType: event.runtimeType.toString(),
            eventData: jsonEncode(data),
            sequence: seq,
            createdAt: event.timestamp,
          ),
        );
  }

  /// Append multiple events atomically inside a single transaction.
  /// Sequence numbers are assigned contiguously from a single base read,
  /// avoiding one `SELECT max` round-trip per event.
  /// Returns the list of assigned sequence numbers in the same order.
  ///
  /// All [events] must belong to the same session: a single base sequence is
  /// read and each event is assigned `base + i`, so mixed sessions would
  /// receive incorrect, non-monotonic sequence numbers.
  Future<List<int>> appendAll(List<SessionEvent> events) async {
    if (events.isEmpty) return const [];
    assert(
      events.every((e) => e.sessionId == events.first.sessionId),
      'appendAll requires all events to belong to the same session',
    );
    return await _db.transaction(() async {
      final base = await _nextSequence(events.first.sessionId);
      final seqs = <int>[];
      for (int i = 0; i < events.length; i++) {
        final event = events[i];
        final data = _serialize(event);
        await _db
            .into(_db.events)
            .insert(
              db.EventsCompanion.insert(
                sessionId: event.sessionId.value,
                eventType: event.runtimeType.toString(),
                eventData: jsonEncode(data),
                sequence: base + i,
                createdAt: event.timestamp,
              ),
            );
        seqs.add(base + i);
      }
      return seqs;
    });
  }

  /// Get all events for a session, ordered by sequence number ascending.
  Future<List<SessionEvent>> getEvents(SessionID sessionId) async {
    final rows =
        await (_db.select(_db.events)
              ..where((e) => e.sessionId.equals(sessionId.value))
              ..orderBy([(e) => OrderingTerm(expression: e.sequence)]))
            .get();

    return rows.map<SessionEvent>(_deserialize).toList();
  }

  /// Returns all events for the given [sessionIds] in a single query, ordered
  /// by [sequence]. Use to batch-replay several sessions without one query per
  /// session.
  Future<List<SessionEvent>> getEventsForSessions(
    List<SessionID> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return const [];
    final rows =
        await (_db.select(_db.events)
              ..where((e) => e.sessionId.isIn(sessionIds.map((s) => s.value)))
              ..orderBy([(e) => OrderingTerm(expression: e.sequence)]))
            .get();
    return rows.map<SessionEvent>(_deserialize).toList();
  }

  /// Stream events for a session — emits the full ordered list on every
  /// insert/delete change that affects this session.
  Stream<List<SessionEvent>> streamEvents(SessionID sessionId) {
    return (_db.select(_db.events)
          ..where((e) => e.sessionId.equals(sessionId.value))
          ..orderBy([(e) => OrderingTerm(expression: e.sequence)]))
        .watch()
        .map((rows) => rows.map<SessionEvent>(_deserialize).toList());
  }

  /// Same as [streamEvents] but filters out ephemeral delta events
  /// (TextDelta, ReasoningDelta, ToolInputDelta). Use for efficient replay
  /// when only the final `*Ended` values are needed (e.g. full state rebuild).
  Stream<List<SessionEvent>> streamDurableEvents(SessionID sessionId) {
    return streamEvents(
      sessionId,
    ).map((events) => events.where((e) => !isDeltaEvent(e)).toList());
  }

  /// Stream only events with [sequence] greater than [afterSeq] for a session.
  ///
  /// Unlike [streamEvents], the watched result set is bounded by the
  /// post-[afterSeq] tail rather than the full session history, so the
  /// deserialization cost per emit scales with the streaming tail instead of
  /// total history length. Note: Drift's [watch] re-emits the full tail on
  /// every insert, so the caller should still filter for `sequence > lastSeq`
  /// to process only newly-appended events. This keeps ephemeral delta events
  /// (needed for live streaming display).
  Stream<List<SessionEvent>> streamEventsSince(
    SessionID sessionId,
    int afterSeq,
  ) {
    return (_db.select(_db.events)
          ..where((e) => e.sessionId.equals(sessionId.value))
          ..where((e) => e.sequence.isBiggerThanValue(afterSeq))
          ..orderBy([(e) => OrderingTerm(expression: e.sequence)]))
        .watch()
        .map((rows) => rows.map<SessionEvent>(_deserialize).toList());
  }

  /// Returns all durable (non-delta) events for a session ordered by sequence.
  /// Skips ephemeral delta events — use for fast full replay.
  Future<List<SessionEvent>> getDurableEvents(SessionID sessionId) async {
    final all = await getEvents(sessionId);
    return all.where((e) => !isDeltaEvent(e)).toList();
  }

  /// Stream raw message rows for a session ordered by sequence.
  Stream<List<db.Message>> watchMessages(SessionID sessionId) {
    return (_db.select(_db.messages)
          ..where((m) => m.sessionId.equals(sessionId.value))
          ..orderBy([(m) => OrderingTerm(expression: m.seq)]))
        .watch();
  }

  /// Stream raw tool result rows for a session ordered by creation time.
  Stream<List<db.ToolResult>> watchToolResults(SessionID sessionId) {
    return (_db.select(_db.toolResults)
          ..where((t) => t.sessionId.equals(sessionId.value))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  /// Return the highest sequence number recorded for [sessionId],
  /// or `0` if the session has no events yet.
  Future<int> getLatestSequence(SessionID sessionId) async {
    final rows =
        await (_db.select(_db.events)
              ..where((e) => e.sessionId.equals(sessionId.value))
              ..orderBy([
                (e) => OrderingTerm(
                  expression: e.sequence,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .get();

    return rows.isEmpty ? 0 : rows.first.sequence;
  }

  /// Delete all events belonging to [sessionId].
  Future<void> deleteSessionEvents(SessionID sessionId) async {
    await (_db.delete(
      _db.events,
    )..where((e) => e.sessionId.equals(sessionId.value))).go();
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _serialize(SessionEvent event) {
    return switch (event) {
      SessionCreated e => {
        'type': 'SessionCreated',
        'parentId': e.parentId?.value,
        'title': e.title,
        'agent': e.agent,
        'modelRef': e.modelRef,
        'permission': _serializePermission(e.permission),
      },
      SessionArchived _ => {'type': 'SessionArchived'},
      SessionAgentSwitched e => {
        'type': 'SessionAgentSwitched',
        'agent': e.agent,
      },
      SessionModelSwitched e => {
        'type': 'SessionModelSwitched',
        'modelRef': e.modelRef,
      },
      MessageAdded e => {
        'type': 'MessageAdded',
        'messageId': e.messageId,
        'role': e.role,
        'content': e.content,
      },
      TextStarted e => {
        'type': 'TextStarted',
        'messageId': e.messageId,
        if (e.partId != null) 'partId': e.partId,
      },
      TextDelta e => {
        'type': 'TextDelta',
        'messageId': e.messageId,
        if (e.partId != null) 'partId': e.partId,
        'delta': e.delta,
      },
      TextEnded e => {
        'type': 'TextEnded',
        'messageId': e.messageId,
        'fullText': e.fullText,
        'model': e.model,
        if (e.partId != null) 'partId': e.partId,
      },
      ReasoningStarted e => {
        'type': 'ReasoningStarted',
        'messageId': e.messageId,
        if (e.partId != null) 'partId': e.partId,
      },
      ReasoningDelta e => {
        'type': 'ReasoningDelta',
        'messageId': e.messageId,
        if (e.partId != null) 'partId': e.partId,
        'delta': e.delta,
      },
      ReasoningEnded e => {
        'type': 'ReasoningEnded',
        'messageId': e.messageId,
        'fullReasoning': e.fullReasoning,
        if (e.partId != null) 'partId': e.partId,
      },
      ToolInputStarted e => {
        'type': 'ToolInputStarted',
        'toolCallId': e.toolCallId,
      },
      ToolInputDelta e => {
        'type': 'ToolInputDelta',
        'toolCallId': e.toolCallId,
        'delta': e.delta,
      },
      ToolInputEnded e => {
        'type': 'ToolInputEnded',
        'toolCallId': e.toolCallId,
        'fullInput': e.fullInput,
      },
      ToolCalled e => {
        'type': 'ToolCalled',
        'toolCallId': e.toolCallId,
        'toolName': e.toolName,
        'input': e.input,
      },
      ToolSuccess e => {
        'type': 'ToolSuccess',
        'toolCallId': e.toolCallId,
        'outputText': e.outputText,
      },
      ToolFailed e => {
        'type': 'ToolFailed',
        'toolCallId': e.toolCallId,
        'error': e.error,
      },
      StepStarted e => {'type': 'StepStarted', 'stepNumber': e.stepNumber},
      StepEnded e => {
        'type': 'StepEnded',
        'stepNumber': e.stepNumber,
        'tokensInput': e.tokensInput,
        'tokensOutput': e.tokensOutput,
        'tokensReasoning': e.tokensReasoning,
      },
      StepFailed e => {
        'type': 'StepFailed',
        'stepNumber': e.stepNumber,
        'error': e.error,
      },
      CompactionStarted _ => {'type': 'CompactionStarted'},
      CompactionEnded e => {
        'type': 'CompactionEnded',
        'summary': e.summary,
        'tailStartId': e.tailStartId,
        'compactedContext': e.compactedContext,
      },
      ChildSessionCreated e => {
        'type': 'ChildSessionCreated',
        'parentSessionId': e.parentSessionId.value,
        'childSessionId': e.childSessionId.value,
        'title': e.title,
        'agent': e.agent,
        'modelRef': e.modelRef,
      },
      TaskStarted e => {
        'type': 'TaskStarted',
        'taskId': e.taskId,
        'description': e.description,
      },
      TaskCompleted e => {
        'type': 'TaskCompleted',
        'taskId': e.taskId,
        'output': e.output,
      },
      TaskPartStarted e => {
        'type': 'TaskPartStarted',
        'partId': e.partId,
        'description': e.description,
        'agent': e.agent,
        'taskSessionId': e.taskSessionId,
      },
      TaskPartCompleted e => {
        'type': 'TaskPartCompleted',
        'partId': e.partId,
        'toolCallsCount': e.toolCallsCount,
      },
      TaskPartError e => {
        'type': 'TaskPartError',
        'partId': e.partId,
        'error': e.error,
        'toolCallsCount': e.toolCallsCount,
      },
      MessageUpdated e => {
        'type': 'MessageUpdated',
        'messageId': e.messageId,
        if (e.content != null) 'content': e.content,
        if (e.reasoning != null) 'reasoning': e.reasoning,
        if (e.model != null) 'model': e.model,
        if (e.error != null) 'error': e.error,
      },
      MessageDeleted e => {'type': 'MessageDeleted', 'messageId': e.messageId},
      SessionTitleUpdated e => {
        'type': 'SessionTitleUpdated',
        'title': e.title,
      },
      QuestionPartStarted e => {
        'type': 'QuestionPartStarted',
        'partId': e.partId,
        'questionText': e.questionText,
        'options': e.options,
      },
      QuestionPartAnswered e => {
        'type': 'QuestionPartAnswered',
        'partId': e.partId,
        'answer': e.answer,
      },
      TodoPartStarted e => {
        'type': 'TodoPartStarted',
        'partId': e.partId,
        'todos': e.todos,
      },
      TodoPartCompleted e => {'type': 'TodoPartCompleted', 'partId': e.partId},
    };
  }

  SessionEvent _deserialize(db.Event row) {
    final data = jsonDecode(row.eventData) as Map<String, dynamic>;
    final type = data['type'] as String;

    final sid = SessionID.fromString(row.sessionId);

    return switch (type) {
      'SessionCreated' => SessionCreated(
        sessionId: sid,
        parentId: data['parentId'] != null
            ? SessionID.fromString(data['parentId'] as String)
            : null,
        title: data['title'] as String? ?? '',
        agent: data['agent'] as String? ?? 'general',
        modelRef: data['modelRef'] as String?,
        permission: _deserializePermission(
          data['permission'] as Map<String, dynamic>?,
        ),
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'SessionArchived' => SessionArchived(
        sessionId: sid,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'SessionAgentSwitched' => SessionAgentSwitched(
        sessionId: sid,
        agent: data['agent'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'SessionModelSwitched' => SessionModelSwitched(
        sessionId: sid,
        modelRef: data['modelRef'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'MessageAdded' => MessageAdded(
        sessionId: sid,
        messageId: data['messageId'] as String,
        role: data['role'] as String,
        content: data['content'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TextStarted' => TextStarted(
        sessionId: sid,
        messageId: data['messageId'] as String,
        partId: data['partId'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TextDelta' => TextDelta(
        sessionId: sid,
        messageId: data['messageId'] as String,
        delta: data['delta'] as String,
        partId: data['partId'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TextEnded' => TextEnded(
        sessionId: sid,
        messageId: data['messageId'] as String,
        fullText: data['fullText'] as String,
        model: data['model'] as String?,
        partId: data['partId'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ReasoningStarted' => ReasoningStarted(
        sessionId: sid,
        messageId: data['messageId'] as String,
        partId: data['partId'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ReasoningDelta' => ReasoningDelta(
        sessionId: sid,
        messageId: data['messageId'] as String,
        delta: data['delta'] as String,
        partId: data['partId'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ReasoningEnded' => ReasoningEnded(
        sessionId: sid,
        messageId: data['messageId'] as String,
        fullReasoning: data['fullReasoning'] as String,
        partId: data['partId'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ToolInputStarted' => ToolInputStarted(
        sessionId: sid,
        toolCallId: data['toolCallId'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ToolInputDelta' => ToolInputDelta(
        sessionId: sid,
        toolCallId: data['toolCallId'] as String,
        delta: data['delta'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ToolInputEnded' => ToolInputEnded(
        sessionId: sid,
        toolCallId: data['toolCallId'] as String,
        fullInput: data['fullInput'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ToolCalled' => ToolCalled(
        sessionId: sid,
        toolCallId: data['toolCallId'] as String,
        toolName: data['toolName'] as String,
        input: Map<String, dynamic>.from(data['input'] as Map),
        partId: data['partId'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ToolSuccess' => ToolSuccess(
        sessionId: sid,
        toolCallId: data['toolCallId'] as String,
        outputText: data['outputText'] as String,
        partId: data['partId'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ToolFailed' => ToolFailed(
        sessionId: sid,
        toolCallId: data['toolCallId'] as String,
        error: data['error'] as String,
        partId: data['partId'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'StepStarted' => StepStarted(
        sessionId: sid,
        stepNumber: data['stepNumber'] as int,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'StepEnded' => StepEnded(
        sessionId: sid,
        stepNumber: data['stepNumber'] as int,
        tokensInput: data['tokensInput'] as int,
        tokensOutput: data['tokensOutput'] as int,
        tokensReasoning: data['tokensReasoning'] as int,
        tokensCacheRead: data['tokensCacheRead'] as int? ?? 0,
        tokensCacheWrite: data['tokensCacheWrite'] as int? ?? 0,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'StepFailed' => StepFailed(
        sessionId: sid,
        stepNumber: data['stepNumber'] as int,
        error: data['error'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'CompactionStarted' => CompactionStarted(
        sessionId: sid,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'CompactionEnded' => CompactionEnded(
        sessionId: sid,
        summary: data['summary'] as String,
        tailStartId: data['tailStartId'] as String?,
        compactedContext: (data['compactedContext'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>(),
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ChildSessionCreated' => ChildSessionCreated(
        sessionId: sid,
        parentSessionId: SessionID.fromString(
          data['parentSessionId'] as String,
        ),
        childSessionId: SessionID.fromString(data['childSessionId'] as String),
        title: data['title'] as String? ?? '',
        agent: data['agent'] as String? ?? 'general',
        modelRef: data['modelRef'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TaskStarted' => TaskStarted(
        sessionId: sid,
        taskId: data['taskId'] as String,
        description: data['description'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TaskCompleted' => TaskCompleted(
        sessionId: sid,
        taskId: data['taskId'] as String,
        output: data['output'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TaskPartStarted' => TaskPartStarted(
        sessionId: sid,
        partId: data['partId'] as String,
        description: data['description'] as String,
        agent: data['agent'] as String,
        taskSessionId: data['taskSessionId'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TaskPartCompleted' => TaskPartCompleted(
        sessionId: sid,
        partId: data['partId'] as String,
        toolCallsCount: data['toolCallsCount'] as int? ?? 0,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TaskPartError' => TaskPartError(
        sessionId: sid,
        partId: data['partId'] as String,
        error: data['error'] as String,
        toolCallsCount: data['toolCallsCount'] as int? ?? 0,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'MessageUpdated' => MessageUpdated(
        sessionId: sid,
        messageId: data['messageId'] as String,
        content: data['content'] as String?,
        reasoning: data['reasoning'] as String?,
        model: data['model'] as String?,
        error: data['error'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'MessageDeleted' => MessageDeleted(
        sessionId: sid,
        messageId: data['messageId'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'SessionTitleUpdated' => SessionTitleUpdated(
        sessionId: sid,
        title: data['title'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'QuestionPartStarted' => QuestionPartStarted(
        sessionId: sid,
        partId: data['partId'] as String,
        questionText: data['questionText'] as String,
        options:
            (data['options'] as List?)
                ?.map((e) => QuestionOption.fromJson(e))
                .toList() ??
            const [],
        multiple: data['multiple'] as bool? ?? false,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'QuestionPartAnswered' => QuestionPartAnswered(
        sessionId: sid,
        partId: data['partId'] as String,
        answer: data['answer'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TodoPartStarted' => TodoPartStarted(
        sessionId: sid,
        partId: data['partId'] as String,
        todos:
            (data['todos'] as List<dynamic>?)
                ?.map<TodoItem>(
                  (e) => TodoItem.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TodoPartCompleted' => TodoPartCompleted(
        sessionId: sid,
        partId: data['partId'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      _ => throw ArgumentError('Unknown event type: $type'),
    };
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

  PermissionRuleset? _deserializePermission(Map<String, dynamic>? data) {
    if (data == null) return null;
    return PermissionRuleset(
      rules:
          (data['rules'] as List<dynamic>?)
              ?.map(
                (r) => PermissionRule(
                  permission: r['permission'] as String,
                  pattern: r['pattern'] as String,
                  action: PermissionAction.values.byName(r['action'] as String),
                ),
              )
              .toList() ??
          [],
      sessionApproved:
          (data['sessionApproved'] as List<dynamic>?)
              ?.map(
                (r) => PermissionRule(
                  permission: r['permission'] as String,
                  pattern: r['pattern'] as String,
                  action: PermissionAction.values.byName(r['action'] as String),
                ),
              )
              .toList() ??
          [],
    );
  }

  /// Compute the next sequence number for a session by reading the current
  /// maximum and incrementing by one.
  Future<int> _nextSequence(SessionID sessionId) async {
    final latest = await getLatestSequence(sessionId);
    return latest + 1;
  }
}
