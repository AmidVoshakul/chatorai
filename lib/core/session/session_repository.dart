import 'package:drift/drift.dart';

import 'database.dart' hide ToolResult;
import 'event_store.dart';
import 'events.dart';
import 'projector.dart';
import 'session_id.dart';
import 'session_state.dart';
import 'session_tree.dart';

class SessionRepository {
  final AppDatabase _db;
  final EventStore _eventStore;
  final Map<SessionID, SessionState> _stateCache = {};

  SessionRepository(this._db) : _eventStore = EventStore(_db);

  EventStore get eventStore => _eventStore;

  Future<SessionState> createSession({
    SessionID? id,
    SessionID? parentId,
    String title = '',
    String agent = 'general',
    String? modelRef,
  }) async {
    final sessionId = id ?? SessionID.create();
    final event = SessionCreated(
      sessionId: sessionId,
      parentId: parentId,
      title: title,
      agent: agent,
      modelRef: modelRef,
      timestamp: DateTime.now(),
    );

    await _eventStore.append(event);
    await projectToDb(_db, event);

    final state = SessionState(
      id: sessionId,
      parentId: parentId,
      title: title,
      agent: agent,
      modelRef: modelRef,
      createdAt: event.timestamp,
      updatedAt: event.timestamp,
    );
    _stateCache[sessionId] = state;
    return state;
  }

  Future<SessionState?> loadSession(SessionID sessionId) async {
    final events = await _eventStore.getEvents(sessionId);
    if (events.isEmpty) return null;
    return replayEvents(events);
  }

  Future<SessionState?> getSessionMeta(SessionID sessionId) async {
    final cached = _stateCache[sessionId];
    if (cached != null) return cached;

    final row = await (_db.select(
      _db.sessions,
    )..where((s) => s.id.equals(sessionId.value))).getSingleOrNull();
    if (row == null) return null;
    final state = _rowToState(row);
    _stateCache[sessionId] = state;
    return state;
  }

  Stream<SessionState?> streamSession(SessionID sessionId) {
    return _eventStore.streamEvents(sessionId).map((events) {
      if (events.isEmpty) return null;
      return replayEvents(events);
    });
  }

  /// Returns all active (non-archived) sessions sorted by [updatedAt] descending.
  Future<List<SessionState>> findAll() async {
    final rows =
        await (_db.select(_db.sessions)
              ..where((s) => s.archivedAt.isNull())
              ..orderBy([
                (s) => OrderingTerm(
                  expression: s.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return rows.map(_rowToState).toList();
  }

  Future<List<SessionID>> listSessions({bool includeArchived = false}) async {
    final query = _db.select(_db.sessions)
      ..orderBy([
        (s) => OrderingTerm(expression: s.updatedAt, mode: OrderingMode.desc),
      ]);
    if (!includeArchived) {
      query.where((s) => s.archivedAt.isNull());
    }
    final rows = await query.get();
    return rows.map((r) => SessionID.fromString(r.id)).toList();
  }

  Future<SessionState> appendEvent(SessionEvent event) async {
    await _eventStore.append(event);
    await projectToDb(_db, event);

    final cached = _stateCache[event.sessionId];
    if (cached != null) {
      final newState = projectEvent(cached, event);
      _stateCache[event.sessionId] = newState;
      return newState;
    }

    final events = await _eventStore.getEvents(event.sessionId);
    final newState = replayEvents(events);
    _stateCache[event.sessionId] = newState;
    return newState;
  }

  Future<void> archiveSession(SessionID sessionId) async {
    final event = SessionArchived(
      sessionId: sessionId,
      timestamp: DateTime.now(),
    );
    await _eventStore.append(event);
    await projectToDb(_db, event);
  }

  Future<void> deleteSession(SessionID sessionId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.toolResults,
      )..where((t) => t.sessionId.equals(sessionId.value))).go();
      await (_db.delete(
        _db.messages,
      )..where((m) => m.sessionId.equals(sessionId.value))).go();
      await (_db.delete(
        _db.contextEpochs,
      )..where((c) => c.sessionId.equals(sessionId.value))).go();
      await _eventStore.deleteSessionEvents(sessionId);
      await (_db.delete(
        _db.sessions,
      )..where((s) => s.id.equals(sessionId.value))).go();
    });
  }

  Future<SessionTree> buildTree() async {
    final rows = await _db.select(_db.sessions).get();

    if (rows.isEmpty) {
      final id = SessionID.create();
      final tree = SessionTree(id);
      tree.addNode(id);
      return tree;
    }

    final orphans = rows.where((r) => r.parentId == null).toList();
    final rootId = orphans.isNotEmpty
        ? SessionID.fromString(orphans.first.id)
        : SessionID.fromString(rows.first.id);

    final tree = SessionTree(rootId);
    for (final row in rows) {
      tree.addNode(
        SessionID.fromString(row.id),
        parentId: row.parentId != null
            ? SessionID.fromString(row.parentId!)
            : null,
        title: row.title,
      );
    }

    return tree;
  }

  /// Creates a child session linked to [parentId] and publishes a
  /// [ChildSessionCreated] event on the *parent* session.
  ///
  /// The child inherits [agent] and [modelRef] from the parent unless
  /// explicitly overridden. The [title] defaults to the parent's title
  /// with a " → Sub-task" suffix.
  Future<SessionState> createChildSession(
    SessionID parentId, {
    String? agent,
    String? modelRef,
    String? title,
  }) async {
    // Load parent to inherit settings
    final parentState =
        await getSessionMeta(parentId) ?? await loadSession(parentId);
    final effectiveAgent = agent ?? parentState?.agent ?? 'general';
    final effectiveModelRef = modelRef ?? parentState?.modelRef;
    final effectiveTitle =
        title ??
        (parentState != null ? '${parentState.title} → Sub-task' : 'Sub-task');

    final childId = SessionID.create();
    final now = DateTime.now();

    // 1. Create the child session row via SessionCreated
    final createdEvent = SessionCreated(
      sessionId: childId,
      parentId: parentId,
      title: effectiveTitle,
      agent: effectiveAgent,
      modelRef: effectiveModelRef,
      timestamp: now,
    );
    await _eventStore.append(createdEvent);
    await projectToDb(_db, createdEvent);

    // 2. Publish ChildSessionCreated on the *parent* session
    final delegationEvent = ChildSessionCreated(
      sessionId: parentId,
      parentSessionId: parentId,
      childSessionId: childId,
      title: effectiveTitle,
      agent: effectiveAgent,
      modelRef: effectiveModelRef,
      timestamp: now,
    );
    await _eventStore.append(delegationEvent);
    await projectToDb(_db, delegationEvent);

    final state = SessionState(
      id: childId,
      parentId: parentId,
      title: effectiveTitle,
      agent: effectiveAgent,
      modelRef: effectiveModelRef,
      createdAt: now,
      updatedAt: now,
    );
    _stateCache[childId] = state;
    return state;
  }

  /// Propagates a child session's output back to the parent as a message.
  ///
  /// Publishes a [TaskCompleted] event on the parent session containing
  /// the child's output, so the parent's event stream reflects the
  /// delegation result.
  Future<void> propagateChildOutput({
    required SessionID parentSessionId,
    required SessionID childSessionId,
    required String output,
    String? taskId,
  }) async {
    final effectiveTaskId = taskId ?? 'task_${childSessionId.value}';
    final event = TaskCompleted(
      sessionId: parentSessionId,
      taskId: effectiveTaskId,
      output: output,
      timestamp: DateTime.now(),
    );
    await _eventStore.append(event);
    await projectToDb(_db, event);
  }

  Future<List<SessionState>> getChildSessions(SessionID parentId) async {
    final rows = await (_db.select(
      _db.sessions,
    )..where((s) => s.parentId.equals(parentId.value))).get();
    final result = <SessionState>[];
    for (final row in rows) {
      final events = await _eventStore.getEvents(SessionID.fromString(row.id));
      if (events.isNotEmpty) {
        result.add(replayEvents(events));
      }
    }
    return result;
  }

  Future<Map<String, int>> getAggregateUsage(SessionID sessionId) async {
    final tree = await buildTree();
    final descendants = tree.getDescendants(sessionId);
    final allIds = [sessionId, ...descendants];

    int totalInput = 0;
    int totalOutput = 0;
    int totalReasoning = 0;

    for (final id in allIds) {
      final row = await (_db.select(
        _db.sessions,
      )..where((s) => s.id.equals(id.value))).getSingleOrNull();
      if (row != null) {
        totalInput += row.tokensInput;
        totalOutput += row.tokensOutput;
        totalReasoning += row.tokensReasoning;
      }
    }

    return {
      'tokensInput': totalInput,
      'tokensOutput': totalOutput,
      'tokensReasoning': totalReasoning,
    };
  }

  SessionState _rowToState(Session row) {
    return SessionState(
      id: SessionID.fromString(row.id),
      parentId: row.parentId != null
          ? SessionID.fromString(row.parentId!)
          : null,
      title: row.title,
      agent: row.agent,
      modelRef: row.modelRef,
      cost: row.cost,
      tokensInput: row.tokensInput,
      tokensOutput: row.tokensOutput,
      tokensReasoning: row.tokensReasoning,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      archivedAt: row.archivedAt,
    );
  }
}
