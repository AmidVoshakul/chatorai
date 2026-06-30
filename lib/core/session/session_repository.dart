import 'dart:convert';

import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:drift/drift.dart';

import 'database.dart' as db show ToolResult;
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

  /// Derives a child session's [PermissionRuleset] from the parent's.
  ///
  /// Copied parent deny rules are preserved, and `task` and `todowrite`
  /// are unconditionally denied — matching OpenCode's
  /// [deriveSubagentSessionPermission] semantics so that subagents cannot
  /// delegate further or manage their own task metadata.
  static PermissionRuleset deriveChildPermissions(
    PermissionRuleset? parentRules,
  ) {
    final denies = <PermissionRule>[];

    if (parentRules != null) {
      denies.addAll(
        parentRules.rules.where((r) => r.action == PermissionAction.deny),
      );
    }

    denies.addAll(const [
      PermissionRule(
        permission: 'task',
        pattern: '*',
        action: PermissionAction.deny,
      ),
      PermissionRule(
        permission: 'todowrite',
        pattern: '*',
        action: PermissionAction.deny,
      ),
    ]);

    return PermissionRuleset(rules: denies);
  }

  Future<SessionState> createSession({
    SessionID? id,
    SessionID? parentId,
    String title = '',
    String agent = 'general',
    String? modelRef,
    PermissionRuleset? permission,
  }) async {
    final sessionId = id ?? SessionID.create();
    final event = SessionCreated(
      sessionId: sessionId,
      parentId: parentId,
      title: title,
      agent: agent,
      modelRef: modelRef,
      permission: permission,
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
      permission: permission,
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

  String _stripSesPrefix(String value) {
    if (value.startsWith('ses_')) return value;
    return 'ses_$value';
  }

  Future<SessionState?> getSessionMetaFromId(String sessionId) async {
    final stripped = _stripSesPrefix(sessionId);
    return getSessionMeta(SessionID.fromString(stripped));
  }

  Stream<SessionState?> streamSessionFromId(String sessionId) {
    final stripped = _stripSesPrefix(sessionId);
    return streamSession(SessionID.fromString(stripped));
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
    _stateCache.remove(sessionId);
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
  /// The child inherits [agent], [modelRef], and [permission] from the
  /// parent unless explicitly overridden. The [title] defaults to the
  /// parent's title with a " → Sub-task" suffix.
  ///
  /// Permission derivation follows [deriveChildPermissions]: parent deny
  /// rules are propagated, and `task` / `todowrite` are unconditionally
  /// denied so subagents cannot delegate further.
  Future<SessionState> createChildSession(
    SessionID parentId, {
    String? agent,
    String? modelRef,
    String? title,
    PermissionRuleset? permission,
  }) async {
    // Load parent to inherit settings
    final parentState =
        await getSessionMeta(parentId) ?? await loadSession(parentId);
    final effectiveAgent = agent ?? parentState?.agent ?? 'general';
    final effectiveModelRef = modelRef ?? parentState?.modelRef;
    final effectiveTitle =
        title ??
        (parentState != null ? '${parentState.title} → Sub-task' : 'Sub-task');

    // Derive permissions from parent unless explicitly overridden
    final childPermission =
        permission ?? deriveChildPermissions(parentState?.permission);

    final childId = SessionID.create();
    final now = DateTime.now();

    // 1. Create the child session row via SessionCreated
    final createdEvent = SessionCreated(
      sessionId: childId,
      parentId: parentId,
      title: effectiveTitle,
      agent: effectiveAgent,
      modelRef: effectiveModelRef,
      permission: childPermission,
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
      permission: childPermission,
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

  Future<List<SessionState>> getChildSessionsFromId(String parentId) async {
    final stripped = _stripSesPrefix(parentId);
    return getChildSessions(SessionID.fromString(stripped));
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

  Future<List<ToolResult>> getSessionToolResults(SessionID sessionId) async {
    final rows =
        await (_db.select(_db.toolResults)
              ..where((t) => t.sessionId.equals(sessionId.value))
              ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
            .get();
    return rows.map(_rowToToolResult).toList();
  }

  static ToolResult _rowToToolResult(db.ToolResult row) {
    Map<String, dynamic> input;
    try {
      input = jsonDecode(row.inputJson) as Map<String, dynamic>;
    } catch (_) {
      input = {};
    }
    return ToolResult(
      id: row.id,
      toolName: row.toolName,
      input: input,
      outputText: row.outputText,
      durationMs: row.durationMs,
      status: row.status,
      createdAt: row.createdAt,
    );
  }

  Future<List<SessionMessage>> getSessionMessages(SessionID sessionId) async {
    final rows =
        await (_db.select(_db.messages)
              ..where((m) => m.sessionId.equals(sessionId.value))
              ..orderBy([(m) => OrderingTerm(expression: m.seq)]))
            .get();
    return rows.map(_rowToSessionMessage).toList();
  }

  static SessionMessage _rowToSessionMessage(Message row) {
    return SessionMessage(
      id: row.id,
      role: MessageRole.values.firstWhere(
        (r) => r.name == row.role,
        orElse: () => MessageRole.user,
      ),
      content: row.content,
      seq: row.seq,
      model: row.model,
      reasoning: row.reasoning,
      error: row.error,
      createdAt: row.createdAt,
    );
  }

  Stream<List<SessionMessage>> watchSessionMessages(SessionID sessionId) {
    return _eventStore
        .watchMessages(sessionId)
        .map((rows) => rows.map(_rowToSessionMessage).toList());
  }

  Stream<List<ToolResult>> watchSessionToolResults(SessionID sessionId) {
    return _eventStore
        .watchToolResults(sessionId)
        .map((rows) => rows.map(_rowToToolResult).toList());
  }

  Future<SessionState> loadSessionState(SessionID sessionId) async {
    final events = await _eventStore.getEvents(sessionId);
    return replayEvents(events);
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
      permission: _deserializePermission(row.permissionRules),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      archivedAt: row.archivedAt,
    );
  }
}

PermissionRuleset? _deserializePermission(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final data = jsonDecode(raw) as Map<String, dynamic>;
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
  } catch (_) {
    return null;
  }
}
