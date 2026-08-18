import 'dart:collection';
import 'dart:convert';

import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_snapshot_codec.dart';
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
  static const _stateCacheLimit = 200;
  static const _stateCacheTtl = Duration(hours: 24);
  static const int kChatSnapshotSchemaVersion = 1;
  final AppDatabase _db;
  final EventStore _eventStore;
  final LinkedHashMap<SessionID, SessionState> _stateCache =
      LinkedHashMap<SessionID, SessionState>();
  final Map<SessionID, DateTime> _stateCacheTimestamps = {};

  SessionRepository(this._db) : _eventStore = EventStore(_db);

  EventStore get eventStore => _eventStore;

  void _evictStateCacheIfNeeded() {
    final now = DateTime.now();

    final expiredKeys = _stateCacheTimestamps.entries
        .where((e) => now.difference(e.value) > _stateCacheTtl)
        .map((e) => e.key)
        .toList();
    for (final key in expiredKeys) {
      _stateCache.remove(key);
      _stateCacheTimestamps.remove(key);
    }

    if (_stateCache.length > _stateCacheLimit) {
      final keysToEvict = _stateCache.keys
          .take(_stateCache.length - _stateCacheLimit)
          .toList();
      for (final key in keysToEvict) {
        _stateCache.remove(key);
        _stateCacheTimestamps.remove(key);
      }
    }
  }

  /// Derives a child session's [PermissionRuleset] from the parent's.
  ///
  /// Copied parent deny rules are preserved, and `task` and `todowrite`
  /// are unconditionally denied — matching
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
    String? directory,
  }) async {
    final sessionId = id ?? SessionID.create();
    final event = SessionCreated(
      sessionId: sessionId,
      parentId: parentId,
      title: title,
      agent: agent,
      modelRef: modelRef,
      permission: permission,
      directory: directory,
      timestamp: DateTime.now(),
    );

    await _db.transaction(() async {
      await _eventStore.append(event);
      await projectToDb(_db, event);
    });

    final state = SessionState(
      id: sessionId,
      parentId: parentId,
      title: title,
      agent: agent,
      modelRef: modelRef,
      permission: permission,
      directory: directory,
      createdAt: event.timestamp,
      updatedAt: event.timestamp,
    );
    _stateCache[sessionId] = state;
    _stateCacheTimestamps[sessionId] = DateTime.now();
    _evictStateCacheIfNeeded();
    return state;
  }

  Future<SessionState?> loadSession(SessionID sessionId) async {
    final events = await _eventStore.getEvents(sessionId);
    if (events.isEmpty) return null;
    return replayEvents(events);
  }

  /// Batch raw event rows for many sessions in a single query (no decode).
  Future<List<Event>> getEventRowsForSessions(List<SessionID> sessionIds) {
    return _eventStore.getEventRowsForSessions(sessionIds);
  }

  Future<SessionState?> getSessionMeta(SessionID sessionId) async {
    final cached = _stateCache[sessionId];
    if (cached != null) {
      _stateCache.remove(sessionId);
      _stateCacheTimestamps.remove(sessionId);
      _stateCache[sessionId] = cached;
      _stateCacheTimestamps[sessionId] = DateTime.now();
      return cached;
    }

    final row = await (_db.select(
      _db.sessions,
    )..where((s) => s.id.equals(sessionId.value))).getSingleOrNull();
    if (row == null) return null;
    final state = _rowToState(row);
    _stateCache[sessionId] = state;
    _stateCacheTimestamps[sessionId] = DateTime.now();
    _evictStateCacheIfNeeded();
    return state;
  }

  Future<SessionState?> getSessionMetaFromId(String sessionId) async {
    return getSessionMeta(SessionID.fromRaw(sessionId));
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

  /// Parent (root) sessions created in [directory], newest first.
  Future<List<SessionState>> findSessionsByDirectory(String directory) async {
    final rows =
        await (_db.select(_db.sessions)
              ..where(
                (s) => s.parentId.isNull() & s.directory.equals(directory),
              )
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
    await _db.transaction(() async {
      await _eventStore.append(event);
      await projectToDb(_db, event);
    });

    final cached = _stateCache[event.sessionId];
    if (cached != null) {
      _stateCache.remove(event.sessionId);
      _stateCacheTimestamps.remove(event.sessionId);
      final newState = projectEvent(cached, event);
      _stateCache[event.sessionId] = newState;
      _stateCacheTimestamps[event.sessionId] = DateTime.now();
      _evictStateCacheIfNeeded();
      return newState;
    }

    final events = await _eventStore.getEvents(event.sessionId);
    final newState = replayEvents(events);
    _stateCache[event.sessionId] = newState;
    _stateCacheTimestamps[event.sessionId] = DateTime.now();
    _evictStateCacheIfNeeded();
    return newState;
  }

  /// Append multiple events inside a single transaction. Used to batch
  /// streaming deltas so that a long token stream does not produce one
  /// database transaction (and one `streamEvents` notification) per token.
  Future<SessionState> appendEvents(List<SessionEvent> events) async {
    if (events.isEmpty) {
      throw ArgumentError('appendEvents requires a non-empty list of events');
    }

    await _db.transaction(() async {
      await _eventStore.appendAll(events);
      for (final event in events) {
        await projectToDb(_db, event);
      }
    });

    final sessionId = events.first.sessionId;
    final cached = _stateCache[sessionId];
    if (cached != null) {
      _stateCache.remove(sessionId);
      _stateCacheTimestamps.remove(sessionId);
      var newState = cached;
      for (final event in events) {
        newState = projectEvent(newState, event);
      }
      _stateCache[sessionId] = newState;
      _stateCacheTimestamps[sessionId] = DateTime.now();
      _evictStateCacheIfNeeded();
      return newState;
    }

    final all = await _eventStore.getEvents(sessionId);
    final newState = replayEvents(all);
    _stateCache[sessionId] = newState;
    _stateCacheTimestamps[sessionId] = DateTime.now();
    _evictStateCacheIfNeeded();
    return newState;
  }

  Future<void> archiveSession(SessionID sessionId) async {
    final event = SessionArchived(
      sessionId: sessionId,
      timestamp: DateTime.now(),
    );
    await _db.transaction(() async {
      await _eventStore.append(event);
      await projectToDb(_db, event);
    });
  }

  /// Finds sessions with an empty title and zero messages, and deletes them.
  ///
  /// These "orphan" sessions are created as a side effect of a bug where
  /// [SessionRunner.startInitializedSession] creates a second session when
  /// no session ID is passed. Call this once at startup to clean up any
  /// such stale rows left over from previous versions.
  ///
  /// Returns the number of deleted sessions.
  Future<int> cleanupOrphanSessions() async {
    final emptyTitleRows = await (_db.select(
      _db.sessions,
    )..where((s) => s.title.equals(''))).get();

    if (emptyTitleRows.isEmpty) return 0;

    var deleted = 0;
    for (final row in emptyTitleRows) {
      final msgCount = await (_db.select(
        _db.messages,
      )..where((m) => m.sessionId.equals(row.id))).get().then((r) => r.length);

      if (msgCount == 0) {
        await deleteSession(SessionID.fromString(row.id));
        deleted++;
      }
    }
    return deleted;
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
      await (_db.delete(
        _db.chatSnapshots,
      )..where((s) => s.sessionId.equals(sessionId.value))).go();
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
  /// parent's title with a "Sub-task" suffix.
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
        (parentState != null ? '${parentState.title} Sub-task' : 'Sub-task');
    final effectiveDirectory = parentState?.directory;

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
      directory: effectiveDirectory,
      timestamp: now,
    );
    await _db.transaction(() async {
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
    });

    final state = SessionState(
      id: childId,
      parentId: parentId,
      title: effectiveTitle,
      agent: effectiveAgent,
      modelRef: effectiveModelRef,
      permission: childPermission,
      directory: effectiveDirectory,
      createdAt: now,
      updatedAt: now,
    );
    _stateCache[childId] = state;
    _stateCacheTimestamps[childId] = DateTime.now();
    _evictStateCacheIfNeeded();
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
    await _db.transaction(() async {
      await _eventStore.append(event);
      await projectToDb(_db, event);
    });
  }

  Future<List<SessionState>> getChildSessions(SessionID parentId) async {
    final rows = await (_db.select(
      _db.sessions,
    )..where((s) => s.parentId.equals(parentId.value))).get();
    if (rows.isEmpty) return const [];

    final childIds = rows.map((r) => SessionID.fromString(r.id)).toList();
    final allEvents = await _eventStore.getEventsForSessions(childIds);

    final eventsBySession = <String, List<SessionEvent>>{};
    for (final event in allEvents) {
      eventsBySession.putIfAbsent(event.sessionId.value, () => []).add(event);
    }

    final result = <SessionState>[];
    for (final row in rows) {
      final events = eventsBySession[row.id];
      if (events != null && events.isNotEmpty) {
        result.add(replayEvents(events));
      }
    }
    return result;
  }

  Future<List<SessionState>> getChildSessionsFromId(String parentId) async {
    return getChildSessions(SessionID.fromRaw(parentId));
  }

  Future<Map<String, int>> getAggregateUsage(SessionID sessionId) async {
    final tree = await buildTree();
    final allIds = [sessionId, ...tree.getDescendants(sessionId)];

    final inputSum = _db.sessions.tokensInput.sum();
    final outputSum = _db.sessions.tokensOutput.sum();
    final reasoningSum = _db.sessions.tokensReasoning.sum();

    final query = _db.selectOnly(_db.sessions)
      ..where(_db.sessions.id.isIn(allIds.map((e) => e.value)))
      ..addColumns([inputSum, outputSum, reasoningSum]);
    final row = await query.getSingle();

    return {
      'tokensInput': row.read(inputSum) ?? 0,
      'tokensOutput': row.read(outputSum) ?? 0,
      'tokensReasoning': row.read(reasoningSum) ?? 0,
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
      tokensInput: row.tokensInput,
      tokensOutput: row.tokensOutput,
      tokensReasoning: row.tokensReasoning,
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

  /// Loads a cached chat snapshot for [sessionId] if it exists and is still
  /// valid (its `events_count` matches the current number of events in the
  /// store). Returns `null` when there is no snapshot or it is stale, signaling
  /// the caller to replay events from scratch.
  Future<List<ChatMessage>?> readChatSnapshot(SessionID sessionId) async {
    final eventCount = await _eventStore.countEventsForSession(sessionId);
    final row = await (_db.select(
      _db.chatSnapshots,
    )..where((s) => s.sessionId.equals(sessionId.value))).getSingleOrNull();
    if (row == null) return null;
    if (row.eventsCount != eventCount) return null;
    if (row.schemaVersion != kChatSnapshotSchemaVersion) return null;
    return decodeChatSnapshot(row.chatJson);
  }

  /// Writes (upserts) a chat snapshot for [sessionId] with the current event
  /// count, so that subsequent loads can short-circuit when the history has
  /// not changed.
  Future<void> writeChatSnapshot(
    SessionID sessionId,
    List<ChatMessage> messages,
  ) async {
    final eventCount = await _eventStore.countEventsForSession(sessionId);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.chatSnapshots)
        .insert(
          ChatSnapshotsCompanion.insert(
            sessionId: sessionId.value,
            eventsCount: eventCount,
            chatJson: encodeChatSnapshot(messages),
            updatedAt: now,
            schemaVersion: const Value(kChatSnapshotSchemaVersion),
          ),
          mode: InsertMode.insertOrReplace,
        );
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
      directory: row.directory,
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
