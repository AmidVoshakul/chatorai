import 'dart:convert';

import 'package:drift/drift.dart';
import 'database.dart';
import 'events.dart';
import 'session_id.dart';

/// Append-only event store that persists [SessionEvent]s to the `events`
/// SQLite table and allows replaying them via sequence-ordered queries.
class EventStore {
  final AppDatabase _db;

  EventStore(this._db);

  /// Append a single event inside a transaction to prevent
  /// race conditions on sequence number assignment.
  Future<int> append(SessionEvent event) async {
    return await _db.transaction(() async {
      final seq = await _nextSequence(event.sessionId);
      final data = _serialize(event);

      await _db
          .into(_db.events)
          .insert(
            EventsCompanion.insert(
              sessionId: event.sessionId.value,
              eventType: event.runtimeType.toString(),
              eventData: jsonEncode(data),
              sequence: seq,
              createdAt: event.timestamp,
            ),
          );

      return seq;
    });
  }

  /// Append multiple events atomically inside a single transaction.
  /// Returns the list of assigned sequence numbers in the same order.
  Future<List<int>> appendAll(List<SessionEvent> events) async {
    return await _db.transaction(() async {
      final seqs = <int>[];
      for (final event in events) {
        final seq = await _nextSequence(event.sessionId);
        final data = _serialize(event);
        await _db
            .into(_db.events)
            .insert(
              EventsCompanion.insert(
                sessionId: event.sessionId.value,
                eventType: event.runtimeType.toString(),
                eventData: jsonEncode(data),
                sequence: seq,
                createdAt: event.timestamp,
              ),
            );
        seqs.add(seq);
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

    return rows.map(_deserialize).toList();
  }

  /// Stream events for a session — emits the full ordered list on every
  /// insert/delete change that affects this session.
  Stream<List<SessionEvent>> streamEvents(SessionID sessionId) {
    return (_db.select(_db.events)
          ..where((e) => e.sessionId.equals(sessionId.value))
          ..orderBy([(e) => OrderingTerm(expression: e.sequence)]))
        .watch()
        .map((rows) => rows.map(_deserialize).toList());
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
      TextStarted e => {'type': 'TextStarted', 'messageId': e.messageId},
      TextDelta e => {
        'type': 'TextDelta',
        'messageId': e.messageId,
        'delta': e.delta,
      },
      TextEnded e => {
        'type': 'TextEnded',
        'messageId': e.messageId,
        'fullText': e.fullText,
        'model': e.model,
      },
      ReasoningStarted e => {
        'type': 'ReasoningStarted',
        'messageId': e.messageId,
      },
      ReasoningDelta e => {
        'type': 'ReasoningDelta',
        'messageId': e.messageId,
        'delta': e.delta,
      },
      ReasoningEnded e => {
        'type': 'ReasoningEnded',
        'messageId': e.messageId,
        'fullReasoning': e.fullReasoning,
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
        'durationMs': e.durationMs,
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
      CompactionEnded e => {'type': 'CompactionEnded', 'summary': e.summary},
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
    };
  }

  SessionEvent _deserialize(Event row) {
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
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TextDelta' => TextDelta(
        sessionId: sid,
        messageId: data['messageId'] as String,
        delta: data['delta'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'TextEnded' => TextEnded(
        sessionId: sid,
        messageId: data['messageId'] as String,
        fullText: data['fullText'] as String,
        model: data['model'] as String?,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ReasoningStarted' => ReasoningStarted(
        sessionId: sid,
        messageId: data['messageId'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ReasoningDelta' => ReasoningDelta(
        sessionId: sid,
        messageId: data['messageId'] as String,
        delta: data['delta'] as String,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ReasoningEnded' => ReasoningEnded(
        sessionId: sid,
        messageId: data['messageId'] as String,
        fullReasoning: data['fullReasoning'] as String,
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
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ToolSuccess' => ToolSuccess(
        sessionId: sid,
        toolCallId: data['toolCallId'] as String,
        outputText: data['outputText'] as String,
        durationMs: data['durationMs'] as int,
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ToolFailed' => ToolFailed(
        sessionId: sid,
        toolCallId: data['toolCallId'] as String,
        error: data['error'] as String,
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
        timestamp: row.createdAt,
        sequence: row.sequence,
      ),
      'ChildSessionCreated' => ChildSessionCreated(
        sessionId: sid,
        parentSessionId: SessionID.fromString(
          data['parentSessionId'] as String,
        ),
        childSessionId: SessionID.fromString(
          data['childSessionId'] as String,
        ),
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
      _ => throw ArgumentError('Unknown event type: $type'),
    };
  }

  /// Compute the next sequence number for a session by reading the current
  /// maximum and incrementing by one.
  Future<int> _nextSequence(SessionID sessionId) async {
    final latest = await getLatestSequence(sessionId);
    return latest + 1;
  }
}
