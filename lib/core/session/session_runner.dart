import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart'
    show AssistantText;
import 'package:synchronized/synchronized.dart';

/// Collects the results of concurrent delegated tasks ("the box") for a single
/// parent step. Each parallel `task` tool call starts an independent child
/// session; when a child finishes it drops its `agent` + `output` here. The
/// parent sees completions as they happen and only proceeds once every task in
/// the box has reported (allDone).
class TaskBatch {
  /// Number of tasks expected to run in this batch (incremented as each task
  /// starts). Known incrementally because the SDK invokes `execute` per call
  /// and does not announce the total up front.
  int started = 0;

  /// task part ID -> agent name, for labelling results.
  final Map<String, String> agentByPart = {};

  /// task part ID -> child output, filled as each child completes.
  final Map<String, String> resultsByPart = {};

  /// task part IDs that failed, so [allDone] still flips when a child errors
  /// instead of hanging forever waiting for a result that will never come.
  final Set<String> failed = {};

  /// Registers a task as started so [allDone] accounts for it.
  void add(String taskPartId, String agent) {
    started++;
    agentByPart[taskPartId] = agent;
  }

  /// Records a finished child's output. Returns true when every started task
  /// has now reported (succeeded or failed).
  bool complete(String taskPartId, String output) {
    resultsByPart[taskPartId] = output;
    failed.remove(taskPartId);
    return allDone;
  }

  /// Records a failed child. Returns true when every started task has now
  /// reported (succeeded or failed), so the batch never deadlocks.
  bool fail(String taskPartId) {
    failed.add(taskPartId);
    return allDone;
  }

  /// True once every started task has reported its result or failure.
  bool get allDone =>
      started > 0 && (resultsByPart.length + failed.length) == started;

  /// Aggregated, ordered result text (agent: output per task).
  String get aggregated {
    final buffer = StringBuffer();
    for (final entry in agentByPart.entries) {
      final agent = entry.value;
      final output = failed.contains(entry.key)
          ? '(task failed)'
          : (resultsByPart[entry.key] ?? '');
      buffer.writeln('<task agent="$agent">');
      buffer.writeln(output);
      buffer.writeln('</task>');
    }
    return buffer.toString();
  }

  void clear() {
    started = 0;
    agentByPart.clear();
    resultsByPart.clear();
    failed.clear();
  }
}

class SessionRunnerHolder {
  SessionRunner? runner;
  String? parentSessionId;

  /// Shared result collector ("the box") for tasks delegated within the
  /// current parent step. Lets concurrent child sessions aggregate their
  /// outputs before the parent proceeds.
  final TaskBatch batch = TaskBatch();

  /// Maps a child session ID to the parent task part ID so that concurrent
  /// tasks can be routed independently in the UI. Replaces the previous single
  /// [activeChildSessionId] slot, which broke parallel task tool display.
  final Map<String, String> childToTaskPart = {};

  /// Back-reference from task part ID to child session ID.
  final Map<String, String> taskPartToChild = {};

  /// Best-effort "most recent" child session ID, retained for callers that
  /// need a single active child (e.g. opening a task session). Does not gate
  /// routing — that uses [childToTaskPart].
  String? activeChildSessionId;

  /// Callback fired when a child tool starts executing during task delegation.
  /// Receives the child session ID so the parent can route the event to the
  /// correct TaskPart even when several tasks run concurrently.
  void Function(String childSessionId, String toolName, String? title)?
  onChildToolEvent;

  /// Callback fired as soon as the child session for a delegated task is
  /// created, carrying its session ID. The parent wires this to resolve the
  /// TaskPart's `taskSessionId` so the widget can read the child's live tool
  /// results (and render the sub-agent's current tool title dynamically).
  void Function(String childSessionId)? onChildSessionResolved;

  /// Callback that creates the visible TaskPart card for a delegated task
  /// (used by both the single `task` tool and the `task_container`). Fired
  /// from [runTaskInChild] once the child session is registered, so the chat
  /// shows the task card with its live tool title instead of a raw tool
  /// header.
  void Function(String taskPartId, String description, String agent)?
  onTaskStart;

  /// Callback that finalizes the visible TaskPart card for a delegated task
  /// (mirrors [onTaskStart]). Fired from [runTaskInChild] when the child
  /// session completes or errors, so the card stops showing a spinner.
  void Function(String taskPartId)? onTaskEnd;

  /// Registers the link between a child session and its parent task part.
  void registerChild(String childSessionId, String taskPartId) {
    childToTaskPart[childSessionId] = taskPartId;
    taskPartToChild[taskPartId] = childSessionId;
    activeChildSessionId = childSessionId;
  }

  /// Returns the parent task part ID for a child session, if registered.
  String? taskPartForChild(String childSessionId) =>
      childToTaskPart[childSessionId];

  /// Removes the link for a finished child session.
  void unregisterChild(String childSessionId) {
    final taskPartId = childToTaskPart.remove(childSessionId);
    if (taskPartId != null) taskPartToChild.remove(taskPartId);
  }

  SessionRunnerHolder(this.runner, {this.parentSessionId});
}

class TaskChildResult {
  final String output;
  final bool aborted;
  final SessionID sessionId;

  const TaskChildResult(
    this.output, {
    this.aborted = false,
    required this.sessionId,
  });
}

class SessionRunner {
  final SessionRepository repository;
  final ToolRegistry? toolRegistry;

  SessionRunner(this.repository, this.toolRegistry);

  SessionRunnerSession startSession({
    required String agent,
    String? modelRef,
    String? title,
    String? parentSessionId,
  }) {
    final sessionId = SessionID.create();
    // Note: Event persisted later via initialize() for backward compatibility.
    // Prefer startInitializedSession() for immediate persistence.
    return SessionRunnerSession(
      sessionId: sessionId,
      repository: repository,
      agent: agent,
      modelRef: modelRef,
      title: title,
      parentId: parentSessionId != null
          ? SessionID.fromString(parentSessionId)
          : null,
      toolRegistry: toolRegistry,
    );
  }

  /// Creates a session that is immediately writable by appending the
  /// [SessionCreated] event to the store and setting [initialized] to true.
  /// Must be called once before any [onChunk]/[onReasoning]/[onTool*] calls.
  ///
  /// When [sessionId] is provided (continuation), reuses the existing session
  /// without emitting a new [SessionCreated] event.
  Future<SessionRunnerSession> startInitializedSession({
    required String agent,
    String? modelRef,
    String? title,
    String? parentSessionId,
    SessionID? sessionId,
  }) async {
    if (sessionId != null) {
      return SessionRunnerSession.forExisting(
        repository: repository,
        sessionId: sessionId,
        toolRegistry: toolRegistry,
      );
    }
    final session = startSession(
      agent: agent,
      modelRef: modelRef,
      title: title,
      parentSessionId: parentSessionId,
    );
    await session.initialize(agent: agent, modelRef: modelRef, title: title);
    return session;
  }

  PermissionRuleset _deriveSubagentPermissions({
    required PermissionRuleset? parentRules,
    required AgentDefinition childAgent,
  }) {
    final base = <PermissionRule>[
      ...childAgent.permissions.rules,
      if (parentRules != null)
        ...parentRules.rules.where(
          (r) =>
              r.permission == 'external_directory' ||
              r.action == PermissionAction.deny,
        ),
    ];

    final hasTodo = base.any((r) => r.permission == 'todowrite');
    final hasTask = base.any((r) => r.permission == 'task');

    return PermissionRuleset(
      rules: [
        ...base,
        if (!hasTodo)
          const PermissionRule(
            permission: 'todowrite',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        if (!hasTask)
          const PermissionRule(
            permission: 'task',
            pattern: '*',
            action: PermissionAction.deny,
          ),
      ],
    );
  }

  Future<TaskChildResult> runTaskInChild({
    required SessionID parentSessionId,
    required String taskPrompt,
    required Future<void> Function(SessionRunnerSession child) streamFn,
    String? agent,
    String? modelRef,
    String? title,
    String? taskId,
    String? taskPartId,
    SessionRunnerHolder? holder,
    CancellationToken? abortSignal,
  }) async {
    final effectiveAgent = agent ?? 'general';
    final childAgent =
        AgentRegistry().get(effectiveAgent) ?? AgentRegistry().get('general');
    if (childAgent == null) {
      throw StateError('Agent not found: $effectiveAgent');
    }
    final parentState =
        await repository.getSessionMeta(parentSessionId) ??
        await repository.loadSession(parentSessionId);
    final effectivePermissions = _deriveSubagentPermissions(
      parentRules: parentState?.permission,
      childAgent: childAgent,
    );

    final effectiveModelRef =
        childAgent.model ?? modelRef ?? parentState?.modelRef;

    final childState = await repository.createChildSession(
      parentSessionId,
      agent: effectiveAgent,
      modelRef: effectiveModelRef,
      title: title,
      permission: effectivePermissions,
    );
    final childId = childState.id;

    final childSession = SessionRunnerSession.forExisting(
      repository: repository,
      sessionId: childId,
      immediate: true,
    );

    final effectivePartId = taskPartId ?? taskId ?? childId.value;
    holder?.registerChild(childId.value, effectivePartId);
    holder?.batch.add(effectivePartId, effectiveAgent);
    holder?.onChildSessionResolved?.call(childId.value);
    holder?.onTaskStart?.call(
      effectivePartId,
      title ?? taskPrompt,
      effectiveAgent,
    );

    // Persist user prompt as first message in child session (mirrors parent UX)
    await childSession.publishUserMessage(content: taskPrompt);

    try {
      await streamFn(childSession);
      final state = await repository.loadSession(childId);
      final fullText = state == null
          ? ''
          : state.parts.whereType<AssistantText>().map((p) => p.text).join();

      // Drop the child's output into the shared batch ("the box") and publish
      // it on the parent session so the parent sees completion as it happens.
      holder?.batch.complete(effectivePartId, fullText);
      await repository.propagateChildOutput(
        parentSessionId: parentSessionId,
        childSessionId: childId,
        output: fullText,
        taskId: taskId,
      );
      return TaskChildResult(fullText, sessionId: childId);
    } catch (e) {
      // A failed child must still be accounted for so the batch can finish
      // (allDone flips) and the parent session learns of the failure instead
      // of showing a phantom success.
      holder?.batch.fail(effectivePartId);
      await repository.propagateChildOutput(
        parentSessionId: parentSessionId,
        childSessionId: childId,
        output: '',
        taskId: taskId,
      );
      rethrow;
    } finally {
      holder?.unregisterChild(childId.value);
      holder?.onTaskEnd?.call(effectivePartId);
      childSession.dispose();
    }
  }
}

class SessionRunnerSession {
  final SessionRepository repository;
  final SessionID sessionId;
  final ToolRegistry? toolRegistry;
  final bool immediate;
  final String? _agent;
  final String? _modelRef;
  final String? _title;
  final SessionID? _parentId;

  bool initialized = false;
  bool _finalized = false;
  String? messageId;
  String? _openTextPartId;
  String? _openReasoningPartId;

  /// Streaming deltas are buffered in memory and flushed to the event store
  /// in batches (like opencode's `fragments`), so a long token stream does
  /// not open one database transaction — and emit one `streamEvents`
  /// notification — per token.
  static const int _flushThreshold = 128;
  final StringBuffer _pendingText = StringBuffer();
  final StringBuffer _pendingReasoning = StringBuffer();
  final StringBuffer _fullText = StringBuffer();
  final StringBuffer _fullReasoning = StringBuffer();

  final Map<String, String> _toolPartIds = {};
  final Set<String> _startedToolCalls = {};

  /// Serializes all per-session streaming mutations. The hot path
  /// (`onChunk`/`onReasoning`) is invoked `unawaited` per token, so without a
  /// lock two concurrent invocations could both pass the `_openTextPartId ==
  /// null` check and emit duplicate `TextStarted`/`ReasoningStarted` events, or
  /// run overlapping `appendEvents`/`appendAll` calls that read the same
  /// `max(sequence)` and produce duplicate (non-unique) sequence numbers.
  /// Internal helpers (`_flushTextDeltas`, `_flushReasoningDeltas`,
  /// `_closeReasoningIfOpen`) never re-acquire the lock, so a [BasicLock] is
  /// sufficient (no reentrant zone bookkeeping on the hot path).
  final Lock _lock = Lock();

  SessionRunnerSession({
    required this.repository,
    required this.sessionId,
    String? agent,
    String? modelRef,
    String? title,
    SessionID? parentId,
    this.toolRegistry,
    this.immediate = false,
  }) : _agent = agent,
       _modelRef = modelRef,
       _title = title,
       _parentId = parentId,
       initialized = false;

  /// Creates a session runner for an already-existing session (e.g. created by [SessionRepository.createChildSession]).
  /// The session is already initialized, so this constructor sets [initialized] to true.
  SessionRunnerSession.forExisting({
    required this.repository,
    required this.sessionId,
    this.toolRegistry,
    this.immediate = false,
  }) : _agent = null,
       _modelRef = null,
       _title = null,
       _parentId = null,
       initialized = true;

  String _genPartId(String suffix) =>
      'part_${DateTime.now().microsecondsSinceEpoch}_$suffix';
  String _genMessageId() => 'msg_${DateTime.now().microsecondsSinceEpoch}';

  /// Appends the [SessionCreated] event to the event store and marks
  /// this session as ready for streaming. Must be called once before
  /// any [onChunk], [onReasoning], or [onTool*] calls.
  Future<void> initialize({String? agent, String? modelRef, String? title}) =>
      _lock.synchronized(() async {
        if (initialized) return;
        final now = DateTime.now();
        await repository.appendEvent(
          SessionCreated(
            sessionId: sessionId,
            parentId: _parentId,
            agent: agent ?? _agent ?? 'general',
            modelRef: modelRef ?? _modelRef,
            title: title ?? _title ?? '',
            timestamp: now,
          ),
        );
        initialized = true;
      });

  Future<void> onChunk(String content) => _lock.synchronized(() async {
    if (!initialized || _finalized || content.isEmpty) return;
    if (_openTextPartId == null) {
      messageId ??= _genMessageId();
      await _closeReasoningIfOpen();
      _openTextPartId = _genPartId('text');
      await repository.appendEvent(
        TextStarted(
          sessionId: sessionId,
          messageId: messageId!,
          partId: _openTextPartId,
          timestamp: DateTime.now(),
        ),
      );
    }
    _pendingText.write(content);
    _fullText.write(content);
    if (_pendingText.length >= _flushThreshold) {
      await _flushTextDeltas();
    }
  });

  Future<void> onReasoning(String content) => _lock.synchronized(() async {
    if (!initialized || _finalized || content.isEmpty) return;
    _pendingReasoning.write(content);
    _fullReasoning.write(content);
    if (_openReasoningPartId == null) {
      messageId ??= _genMessageId();
      _openReasoningPartId = _genPartId('reasoning');
      await repository.appendEvent(
        ReasoningStarted(
          sessionId: sessionId,
          messageId: messageId!,
          partId: _openReasoningPartId!,
          timestamp: DateTime.now(),
        ),
      );
    }
    if (_pendingReasoning.length >= _flushThreshold) {
      await _flushReasoningDeltas();
    }
  });

  /// Flush buffered text deltas to the event store as a single batched event.
  /// Must only be called from within a [_lock.synchronized] section.
  Future<void> _flushTextDeltas() async {
    if (_pendingText.isEmpty || _openTextPartId == null || messageId == null) {
      return;
    }
    final delta = _pendingText.toString();
    _pendingText.clear();
    await repository.appendEvents([
      TextDelta(
        sessionId: sessionId,
        messageId: messageId!,
        partId: _openTextPartId!,
        delta: delta,
        timestamp: DateTime.now(),
      ),
    ]);
  }

  /// Flush buffered reasoning deltas to the event store as a single batched
  /// event. Must only be called from within a [_lock.synchronized] section.
  Future<void> _flushReasoningDeltas() async {
    if (_pendingReasoning.isEmpty ||
        _openReasoningPartId == null ||
        messageId == null) {
      return;
    }
    final delta = _pendingReasoning.toString();
    _pendingReasoning.clear();
    await repository.appendEvents([
      ReasoningDelta(
        sessionId: sessionId,
        messageId: messageId!,
        partId: _openReasoningPartId!,
        delta: delta,
        timestamp: DateTime.now(),
      ),
    ]);
  }

  Future<void> onToolStart(
    String toolCallId,
    String toolName,
    Map<String, dynamic> input,
  ) => _lock.synchronized(() async {
    if (!initialized) return;
    if (!_startedToolCalls.add(toolCallId)) return;
    final partId = _genPartId(toolCallId);
    _toolPartIds[toolCallId] = partId;
    await _closeReasoningIfOpen();
    await _flushTextDeltas();
    _openTextPartId = null;
    await repository.appendEvent(
      ToolCalled(
        sessionId: sessionId,
        toolCallId: toolCallId,
        toolName: toolName,
        input: input,
        partId: partId,
        timestamp: DateTime.now(),
      ),
    );
  });

  Future<void> onToolEnd(
    String toolCallId,
    String toolName,
    String result, {
    int durationMs = 0,
    Map<String, dynamic>? input,
  }) => _lock.synchronized(() async {
    if (!initialized) return;
    final partId = _toolPartIds[toolCallId];
    if (partId == null) return;
    await repository.appendEvent(
      ToolSuccess(
        sessionId: sessionId,
        toolCallId: toolCallId,
        outputText: result,
        partId: partId,
        durationMs: durationMs,
        input: input,
        timestamp: DateTime.now(),
      ),
    );
  });

  Future<void> onToolError(
    String toolCallId,
    String toolName,
    String error, {
    int durationMs = 0,
    Map<String, dynamic>? input,
  }) => _lock.synchronized(() async {
    if (!initialized) return;
    final partId = _toolPartIds[toolCallId];
    if (partId == null) return;
    await repository.appendEvent(
      ToolFailed(
        sessionId: sessionId,
        toolCallId: toolCallId,
        error: error,
        partId: partId,
        durationMs: durationMs,
        input: input,
        timestamp: DateTime.now(),
      ),
    );
  });

  /// Closes an open reasoning part. Must only be called from within a
  /// [_lock.synchronized] section.
  Future<void> _closeReasoningIfOpen() async {
    if (_openReasoningPartId == null || messageId == null) return;
    await _flushReasoningDeltas();
    await repository.appendEvent(
      ReasoningEnded(
        sessionId: sessionId,
        messageId: messageId!,
        fullReasoning: _fullReasoning.toString(),
        partId: _openReasoningPartId!,
        timestamp: DateTime.now(),
      ),
    );
    _openReasoningPartId = null;
    _pendingReasoning.clear();
    _fullReasoning.clear();
  }

  Future<SessionState> onCompletion({
    required String content,
    String? reasoning,
    String? model,
    int tokensInput = 0,
    int tokensOutput = 0,
    int tokensReasoning = 0,
    int tokensCacheRead = 0,
    int tokensCacheWrite = 0,
  }) => _lock.synchronized(() async {
    if (_finalized) {
      final loaded = await repository.loadSession(sessionId);
      final now = DateTime.now();
      return loaded ??
          SessionState(id: sessionId, createdAt: now, updatedAt: now);
    }
    _finalized = true;
    final now = DateTime.now();

    // Flush any buffered streaming deltas before finalizing.
    await _flushTextDeltas();
    await _flushReasoningDeltas();

    // Close any open text
    if (_openTextPartId != null && messageId != null) {
      final fullText = content.isNotEmpty ? content : _fullText.toString();
      await repository.appendEvent(
        TextEnded(
          sessionId: sessionId,
          messageId: messageId!,
          partId: _openTextPartId!,
          fullText: fullText,
          model: model,
          timestamp: now,
        ),
      );
      _openTextPartId = null;
      _fullText.clear();
    }

    // Close any open reasoning if there is reasoning content to close
    if (_openReasoningPartId != null && messageId != null) {
      final reasonText =
          reasoning ??
          (_fullReasoning.isEmpty ? '' : _fullReasoning.toString());
      await repository.appendEvent(
        ReasoningEnded(
          sessionId: sessionId,
          messageId: messageId!,
          partId: _openReasoningPartId!,
          fullReasoning: reasonText,
          timestamp: now,
        ),
      );
      _openReasoningPartId = null;
      _fullReasoning.clear();
    }

    await repository.appendEvent(
      StepEnded(
        sessionId: sessionId,
        stepNumber: 1,
        tokensInput: tokensInput,
        tokensOutput: tokensOutput,
        tokensReasoning: tokensReasoning,
        tokensCacheRead: tokensCacheRead,
        tokensCacheWrite: tokensCacheWrite,
        timestamp: now,
      ),
    );

    final loaded = await repository.loadSession(sessionId);
    return loaded ??
        SessionState(id: sessionId, createdAt: now, updatedAt: now);
  });

  /// Flush any buffered deltas and close open parts before recording the
  /// failure, so the event store never contains a part left open (no
  /// corresponding `*Ended` event) on the error path.
  Future<void> onError(Object error) => _lock.synchronized(() async {
    if (_finalized) return;
    _finalized = true;
    final now = DateTime.now();
    await _flushTextDeltas();
    if (_openTextPartId != null && messageId != null) {
      await repository.appendEvent(
        TextEnded(
          sessionId: sessionId,
          messageId: messageId!,
          partId: _openTextPartId!,
          fullText: _fullText.toString(),
          timestamp: now,
        ),
      );
      _openTextPartId = null;
      _fullText.clear();
    }
    await _flushReasoningDeltas();
    if (_openReasoningPartId != null && messageId != null) {
      await repository.appendEvent(
        ReasoningEnded(
          sessionId: sessionId,
          messageId: messageId!,
          partId: _openReasoningPartId!,
          fullReasoning: _fullReasoning.toString(),
          timestamp: now,
        ),
      );
      _openReasoningPartId = null;
      _fullReasoning.clear();
    }
    await repository.appendEvent(
      StepFailed(
        sessionId: sessionId,
        stepNumber: 1,
        error: error.toString(),
        timestamp: now,
      ),
    );
  });

  Future<void> publishUserMessage({
    required String content,
    String? messageId,
  }) => _lock.synchronized(() async {
    if (!initialized) return;
    final id = messageId ?? _genMessageId();
    await repository.appendEvent(
      MessageAdded(
        sessionId: sessionId,
        messageId: id,
        role: 'user',
        content: content,
        timestamp: DateTime.now(),
      ),
    );
  });

  Future<void> onTaskStart({
    required String partId,
    required String description,
    required String agent,
    String? sessionId,
  }) => _lock.synchronized(() async {
    if (!initialized) return;
    await repository.appendEvent(
      TaskPartStarted(
        sessionId: this.sessionId,
        partId: partId,
        description: description,
        agent: agent,
        taskSessionId: sessionId,
        timestamp: DateTime.now(),
      ),
    );
  });

  Future<void> onTaskEnd(String partId) => _lock.synchronized(() async {
    if (!initialized) return;
    await repository.appendEvent(
      TaskPartCompleted(
        sessionId: sessionId,
        partId: partId,
        timestamp: DateTime.now(),
      ),
    );
  });

  Future<void> onTaskError(String partId, String error) =>
      _lock.synchronized(() async {
        if (!initialized) return;
        await repository.appendEvent(
          TaskPartError(
            sessionId: sessionId,
            partId: partId,
            error: error,
            timestamp: DateTime.now(),
          ),
        );
      });

  void dispose() {
    _startedToolCalls.clear();
    toolRegistry?.pruneSession(sessionId.value);
  }
}
