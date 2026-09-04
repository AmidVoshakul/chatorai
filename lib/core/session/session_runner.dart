import 'dart:async';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/session/event_bus.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/tools/built_in/task_shared.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart'
    show AssistantText, AssistantTool;
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

  /// Tracks all active child [SessionRunnerSession] instances so they can be
  /// cancelled atomically when the parent stream is aborted.
  final Map<String, SessionRunnerSession> _childSessions = {};

  void Function(String childSessionId)? onChildSessionResolved;
  void Function(String taskPartId, String description, String agent)?
  onTaskStart;
  void Function(String taskPartId)? onTaskEnd;
  void Function(String childSessionId, String toolName, String? title)?
  onChildToolEvent;

  SessionRunnerHolder(this.runner, {this.parentSessionId});

  /// Registers the link between a child session and its parent task part.
  void registerChild(String childSessionId, String taskPartId) {
    childToTaskPart[childSessionId] = taskPartId;
    taskPartToChild[taskPartId] = childSessionId;
    activeChildSessionId = childSessionId;
  }

  /// Tracks an active child session so it can be cancelled later.
  void registerChildSession(
    String childSessionId,
    SessionRunnerSession session,
  ) {
    _childSessions[childSessionId] = session;
  }

  /// Returns the parent task part ID for a child session, if registered.
  String? taskPartForChild(String childSessionId) =>
      childToTaskPart[childSessionId];

  /// Removes the link and session tracker for a finished child session.
  void unregisterChild(String childSessionId) {
    final taskPartId = childToTaskPart.remove(childSessionId);
    if (taskPartId != null) taskPartToChild.remove(taskPartId);
    _childSessions.remove(childSessionId);
  }

  /// Cancels all running child sessions. Safe to call multiple times.
  void cancelAllChildren() {
    for (final entry in _childSessions.entries) {
      try {
        entry.value.dispose();
      } on Object catch (_) {
        // ignore
      }
      final taskPartId = childToTaskPart[entry.key];
      if (taskPartId != null && parentSessionId != null) {
        final now = DateTime.now();
        final failedEvent = TaskPartError(
          sessionId: SessionID.fromString(parentSessionId!),
          partId: taskPartId,
          error: 'cancelled',
          timestamp: now,
        );
        unawaited(runner?.repository.appendEvent(failedEvent));
        runner?.eventBus?.emit(failedEvent);
      }
    }
    _childSessions.clear();
    childToTaskPart.clear();
    taskPartToChild.clear();
  }
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
  final SessionEventBus? eventBus;

  SessionRunner(this.repository, this.toolRegistry, {this.eventBus});

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
      eventBus: eventBus,
    );
  }

  /// Creates a session that is immediately writable by appending the
  /// [SessionCreated] event to the store and setting [initialized] to true.
  /// Must be called once before any [onChunk]/[onReasoning]/[onTool*] calls.
  ///
  /// When [sessionId] is provided (continuation), reuses the existing session
  /// without emitting a new [SessionCreated] event.
  ///
  /// [messageId] seeds the id of the assistant message being streamed. Pass it
  /// when the caller already appended an assistant placeholder via
  /// `MessageAdded` so `onChunk` writes into that same message (no duplicates).
  Future<SessionRunnerSession> startInitializedSession({
    required String agent,
    String? modelRef,
    String? title,
    String? parentSessionId,
    SessionID? sessionId,
    String? messageId,
  }) async {
    if (sessionId != null) {
      return SessionRunnerSession.forExisting(
        repository: repository,
        sessionId: sessionId,
        toolRegistry: toolRegistry,
        eventBus: eventBus,
        initialMessageId: messageId,
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
      eventBus: eventBus,
    );

    final effectivePartId = taskPartId ?? taskId ?? childId.value;
    holder?.registerChild(childId.value, effectivePartId);
    holder?.registerChildSession(childId.value, childSession);
    holder?.batch.add(effectivePartId, effectiveAgent);
    holder?.onChildSessionResolved?.call(childId.value);

    // Register the task part in the parent session so the projector creates
    // an AssistantTask and the parent UI can display it live.
    final now = DateTime.now();
    final startedEvent = TaskPartStarted(
      sessionId: parentSessionId,
      partId: effectivePartId,
      description: title ?? taskPrompt,
      agent: effectiveAgent,
      taskSessionId: childId.value,
      timestamp: now,
    );
    unawaited(repository.appendEvent(startedEvent));
    eventBus?.emit(startedEvent);

    // Persist user prompt as first message in child session (mirrors parent UX)
    await childSession.publishUserMessage(content: taskPrompt);

    try {
      await streamFn(childSession);
      final state = await repository.loadSession(childId);
      final fullText = state == null
          ? ''
          : state.parts.whereType<AssistantText>().map((p) => p.text).join();
      final toolCallsCount = state == null
          ? 0
          : state.parts.whereType<AssistantTool>().length;

      // Publish child completion on the parent session so the projector
      // updates the AssistantTask to completed.
      final completedEvent = TaskPartCompleted(
        sessionId: parentSessionId,
        partId: effectivePartId,
        toolCallsCount: toolCallsCount,
        timestamp: DateTime.now(),
      );
      unawaited(repository.appendEvent(completedEvent));
      eventBus?.emit(completedEvent);

      // Drop the child's output into the shared batch ("the box") and publish
      // it on the parent session so the parent sees completion as it happens.
      holder?.batch.complete(effectivePartId, fullText);
      await repository.propagateChildOutput(
        parentSessionId: parentSessionId,
        childSessionId: childId,
        output: fullText,
        taskId: effectivePartId,
      );
      return TaskChildResult(fullText, sessionId: childId);
    } catch (e) {
      // A failed child must still be accounted for so the batch can finish
      // (allDone flips) and the parent session learns of the failure instead
      // of showing a phantom success.
      holder?.batch.fail(effectivePartId);
      final childStateOnError = await repository.loadSession(childId);
      final toolCallsCountOnError = childStateOnError == null
          ? 0
          : childStateOnError.parts.whereType<AssistantTool>().length;
      final failedEvent = TaskPartError(
        sessionId: parentSessionId,
        partId: effectivePartId,
        error: e.toString(),
        toolCallsCount: toolCallsCountOnError,
        timestamp: DateTime.now(),
      );
      unawaited(repository.appendEvent(failedEvent));
      eventBus?.emit(failedEvent);
      await repository.propagateChildOutput(
        parentSessionId: parentSessionId,
        childSessionId: childId,
        output: '',
        taskId: effectivePartId,
      );
      rethrow;
    } finally {
      holder?.unregisterChild(childId.value);
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

  final StringBuffer _pendingText = StringBuffer();
  final StringBuffer _pendingReasoning = StringBuffer();
  final StringBuffer _fullText = StringBuffer();
  final StringBuffer _fullReasoning = StringBuffer();

  int _toolRunningCount = 0;
  final StringBuffer _bufferedReasoning = StringBuffer();

  final Map<String, String> _toolPartIds = {};
  final Set<String> _startedToolCalls = {};

  final SessionEventBus? eventBus;

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
    this.eventBus,
  }) : _agent = agent,
       _modelRef = modelRef,
       _title = title,
       _parentId = parentId,
       initialized = false;

  /// Creates a session runner for an already-existing session (e.g. created by [SessionRepository.createChildSession]).
  /// The session is already initialized, so this constructor sets [initialized] to true.
  ///
  /// When [initialMessageId] is provided (continuation of a chat that already
  /// appended an assistant placeholder via `MessageAdded`), the first
  /// `onChunk` will target that message id instead of generating a fresh
  /// `msg_…` id — otherwise the projector creates a second assistant message
  /// and the replayed chat list shows duplicate bubbles.
  SessionRunnerSession.forExisting({
    required this.repository,
    required this.sessionId,
    this.toolRegistry,
    this.immediate = false,
    this.eventBus,
    String? initialMessageId,
  }) : _agent = null,
       _modelRef = null,
       _title = null,
       _parentId = null,
       initialized = true,
       messageId = initialMessageId;

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
        final event = SessionCreated(
          sessionId: sessionId,
          parentId: _parentId,
          agent: agent ?? _agent ?? 'general',
          modelRef: modelRef ?? _modelRef,
          title: title ?? _title ?? '',
          timestamp: now,
        );
        await repository.appendEvent(event);
        eventBus?.emit(event);
        initialized = true;
      });

  Future<void> onChunk(String content) => _lock.synchronized(() async {
    if (!initialized || _finalized || content.isEmpty) return;
    if (_openTextPartId == null) {
      messageId ??= _genMessageId();
      await _closeReasoningIfOpen();
      _openTextPartId = _genPartId('text');
      final event = TextStarted(
        sessionId: sessionId,
        messageId: messageId!,
        partId: _openTextPartId,
        timestamp: DateTime.now(),
      );
      await repository.appendEvent(event);
      eventBus?.emit(event);
    }
    _pendingText.write(content);
    _fullText.write(content);
    await _flushTextDeltas();
  });

  Future<void> onReasoning(String content) => _lock.synchronized(() async {
    if (!initialized || _finalized || content.isEmpty) return;
    if (_toolRunningCount > 0) {
      _bufferedReasoning.write(content);
      return;
    }
    if (_openReasoningPartId == null) {
      messageId ??= _genMessageId();
      _openReasoningPartId = _genPartId('reasoning');
      final event = ReasoningStarted(
        sessionId: sessionId,
        messageId: messageId!,
        partId: _openReasoningPartId!,
        timestamp: DateTime.now(),
      );
      await repository.appendEvent(event);
      eventBus?.emit(event);
    }
    _pendingReasoning.write(content);
    _fullReasoning.write(content);
    await _flushReasoningDeltas();
  });

  Future<void> onReasoningEnd() => _lock.synchronized(() async {
    if (!initialized || _finalized) return;
    await _closeReasoningIfOpen();
  });

  /// Flush buffered text deltas to the event store as a single batched event.
  /// Must only be called from within a [_lock.synchronized] section.
  Future<void> _flushTextDeltas() async {
    if (_pendingText.isEmpty || _openTextPartId == null || messageId == null) {
      return;
    }
    final delta = _pendingText.toString();
    _pendingText.clear();
    final event = TextDelta(
      sessionId: sessionId,
      messageId: messageId!,
      partId: _openTextPartId!,
      delta: delta,
      timestamp: DateTime.now(),
    );
    await repository.appendEvents([event]);
    eventBus?.emit(event);
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
    final event = ReasoningDelta(
      sessionId: sessionId,
      messageId: messageId!,
      partId: _openReasoningPartId!,
      delta: delta,
      timestamp: DateTime.now(),
    );
    await repository.appendEvents([event]);
    eventBus?.emit(event);
  }

  /// Closes an open reasoning part. Must only be called from within a
  /// [_lock.synchronized] section.
  Future<void> _closeReasoningIfOpen() async {
    if (_openReasoningPartId == null || messageId == null) return;
    await _flushReasoningDeltas();
    final event = ReasoningEnded(
      sessionId: sessionId,
      messageId: messageId!,
      fullReasoning: _fullReasoning.toString(),
      partId: _openReasoningPartId!,
      timestamp: DateTime.now(),
    );
    await repository.appendEvent(event);
    eventBus?.emit(event);
    _openReasoningPartId = null;
    _pendingReasoning.clear();
    _fullReasoning.clear();
  }

   Future<void> _decrementToolRunning() async {
    _toolRunningCount--;
    if (_toolRunningCount <= 0) {
      _toolRunningCount = 0;
      await _flushBufferedReasoning();
    }
  }

  Future<void> _flushBufferedReasoning() async {
    if (_bufferedReasoning.isEmpty || messageId == null) return;
    final partId = _genPartId('reasoning');
    final now = DateTime.now();
    _openReasoningPartId = partId;
    _pendingReasoning.write(_bufferedReasoning.toString());
    _fullReasoning.write(_bufferedReasoning.toString());
    final startedEvent = ReasoningStarted(
      sessionId: sessionId,
      messageId: messageId!,
      partId: partId,
      timestamp: now,
    );
    await repository.appendEvent(startedEvent);
    eventBus?.emit(startedEvent);
    await _closeReasoningIfOpen();
    _bufferedReasoning.clear();
  }

  Future<void> onToolStart(
    String toolCallId,
    String toolName,
    Map<String, dynamic> input,
  ) => _lock.synchronized(() async {
    if (!initialized) return;
    if (isDelegatedTool(toolName)) return;
    if (!_startedToolCalls.add(toolCallId)) return;
    final partId = _genPartId(toolCallId);
    _toolPartIds[toolCallId] = partId;
    await _flushTextDeltas();
    await _closeReasoningIfOpen();
    _openTextPartId = null;
    _toolRunningCount++;
    await repository.appendEvent(
      ToolStarted(
        sessionId: sessionId,
        toolCallId: toolCallId,
        toolName: toolName,
        partId: partId,
        timestamp: DateTime.now(),
      ),
    );
    eventBus?.emit(
      ToolStarted(
        sessionId: sessionId,
        toolCallId: toolCallId,
        toolName: toolName,
        partId: partId,
        timestamp: DateTime.now(),
      ),
    );
    final event = ToolCalled(
      sessionId: sessionId,
      toolCallId: toolCallId,
      toolName: toolName,
      input: input,
      partId: partId,
      timestamp: DateTime.now(),
    );
    await repository.appendEvent(event);
    eventBus?.emit(event);
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
    final event = ToolSuccess(
      sessionId: sessionId,
      toolCallId: toolCallId,
      outputText: result,
      partId: partId,
      durationMs: durationMs,
      input: input,
      timestamp: DateTime.now(),
    );
    await repository.appendEvent(event);
    eventBus?.emit(event);
    _startedToolCalls.remove(toolCallId);
    await _decrementToolRunning();
  });

  Future<void> onToolError(
    String toolCallId,
    String toolName,
    String error, {
    int durationMs = 0,
    Map<String, dynamic>? input,
  }) => _lock.synchronized(() async {
    if (!initialized) return;
    var partId = _toolPartIds[toolCallId];
    if (partId == null) {
      if (!_startedToolCalls.add(toolCallId)) return;
      partId = _genPartId(toolCallId);
      _toolPartIds[toolCallId] = partId;
      _toolRunningCount++;
      final calledEvent = ToolCalled(
        sessionId: sessionId,
        toolCallId: toolCallId,
        toolName: toolName,
        input: input ?? const {},
        partId: partId,
        timestamp: DateTime.now(),
      );
      await repository.appendEvent(calledEvent);
      eventBus?.emit(calledEvent);
    }
    final event = ToolFailed(
      sessionId: sessionId,
      toolCallId: toolCallId,
      error: error,
      partId: partId,
      durationMs: durationMs,
      input: input,
      timestamp: DateTime.now(),
    );
    await repository.appendEvent(event);
    eventBus?.emit(event);
    _startedToolCalls.remove(toolCallId);
    await _decrementToolRunning();
  });

  /// Emits `ToolFailed` for every tool call that was started but never
  /// completed. Must only be called from within a [_lock.synchronized] section.
  Future<void> _finalizeRunningTools() async {
    final now = DateTime.now();
    for (final entry in _toolPartIds.entries) {
      final callId = entry.key;
      if (!_startedToolCalls.contains(callId)) continue;
      final partId = entry.value;
      final event = ToolFailed(
        sessionId: sessionId,
        toolCallId: callId,
        error: 'Tool execution aborted before completion.',
        partId: partId,
        timestamp: now,
      );
      await repository.appendEvent(event);
      eventBus?.emit(event);
    }
    _toolPartIds.clear();
    _startedToolCalls.clear();
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

    await _closeReasoningIfOpen();

    // Flush any buffered streaming deltas before finalizing.
    await _flushTextDeltas();
    await _flushReasoningDeltas();

    // Close any open text
    if (_openTextPartId != null && messageId != null) {
      final fullText = content.isNotEmpty ? content : _fullText.toString();
      final event = TextEnded(
        sessionId: sessionId,
        messageId: messageId!,
        partId: _openTextPartId!,
        fullText: fullText,
        model: model,
        timestamp: now,
      );
      await repository.appendEvent(event);
      eventBus?.emit(event);
      _openTextPartId = null;
      _fullText.clear();
    }

    // Close any open reasoning if there is reasoning content to close
    if (_openReasoningPartId != null && messageId != null) {
      final reasonText =
          reasoning ??
          (_fullReasoning.isEmpty ? '' : _fullReasoning.toString());
      final event = ReasoningEnded(
        sessionId: sessionId,
        messageId: messageId!,
        partId: _openReasoningPartId!,
        fullReasoning: reasonText,
        timestamp: now,
      );
      await repository.appendEvent(event);
      eventBus?.emit(event);
      _openReasoningPartId = null;
      _fullReasoning.clear();
    }

    await _flushBufferedReasoning();
    _toolRunningCount = 0;
    _bufferedReasoning.clear();

    await _finalizeRunningTools();

    final stepEvent = StepEnded(
      sessionId: sessionId,
      stepNumber: 1,
      tokensInput: tokensInput,
      tokensOutput: tokensOutput,
      tokensReasoning: tokensReasoning,
      tokensCacheRead: tokensCacheRead,
      tokensCacheWrite: tokensCacheWrite,
      timestamp: now,
    );
    await repository.appendEvent(stepEvent);
    eventBus?.emit(stepEvent);

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

    await _closeReasoningIfOpen();

    await _flushTextDeltas();
    if (_openTextPartId != null && messageId != null) {
      final event = TextEnded(
        sessionId: sessionId,
        messageId: messageId!,
        partId: _openTextPartId!,
        fullText: _fullText.toString(),
        timestamp: now,
      );
      await repository.appendEvent(event);
      eventBus?.emit(event);
      _openTextPartId = null;
      _fullText.clear();
    }
    await _flushReasoningDeltas();
    if (_openReasoningPartId != null && messageId != null) {
      final event = ReasoningEnded(
        sessionId: sessionId,
        messageId: messageId!,
        partId: _openReasoningPartId!,
        fullReasoning: _fullReasoning.toString(),
        timestamp: now,
      );
      await repository.appendEvent(event);
      eventBus?.emit(event);
      _openReasoningPartId = null;
      _fullReasoning.clear();
    }

    await _flushBufferedReasoning();
    _toolRunningCount = 0;
    _bufferedReasoning.clear();

    await _finalizeRunningTools();

    final stepEvent = StepFailed(
      sessionId: sessionId,
      stepNumber: 1,
      error: error.toString(),
      timestamp: now,
    );
    await repository.appendEvent(stepEvent);
    eventBus?.emit(stepEvent);
  });

  Future<void> publishUserMessage({
    required String content,
    String? messageId,
  }) => _lock.synchronized(() async {
    if (!initialized) return;
    final id = messageId ?? _genMessageId();
    final event = MessageAdded(
      sessionId: sessionId,
      messageId: id,
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
    await repository.appendEvent(event);
    eventBus?.emit(event);
  });

  Future<void> onTaskStart({
    required String partId,
    required String description,
    required String agent,
    String? sessionId,
  }) => _lock.synchronized(() async {
    if (!initialized) return;
    final event = TaskPartStarted(
      sessionId: this.sessionId,
      partId: partId,
      description: description,
      agent: agent,
      taskSessionId: sessionId,
      timestamp: DateTime.now(),
    );
    await repository.appendEvent(event);
    eventBus?.emit(event);
  });

  Future<void> onTaskEnd(String partId) => _lock.synchronized(() async {
    if (!initialized) return;
    final state = await repository.loadSessionState(sessionId);
    final toolCallsCount = state.parts.whereType<AssistantTool>().length;
    final event = TaskPartCompleted(
      sessionId: sessionId,
      partId: partId,
      toolCallsCount: toolCallsCount,
      timestamp: DateTime.now(),
    );
    await repository.appendEvent(event);
    eventBus?.emit(event);
  });

  Future<void> onTaskError(String partId, String error) =>
      _lock.synchronized(() async {
        if (!initialized) return;
        final state = await repository.loadSessionState(sessionId);
        final toolCallsCount = state.parts.whereType<AssistantTool>().length;
        final event = TaskPartError(
          sessionId: sessionId,
          partId: partId,
          error: error,
          toolCallsCount: toolCallsCount,
          timestamp: DateTime.now(),
        );
        await repository.appendEvent(event);
        eventBus?.emit(event);
      });

  void dispose() {
    _finalized = true;
    _startedToolCalls.clear();
    _toolPartIds.clear();
    _openTextPartId = null;
    _openReasoningPartId = null;
    _pendingText.clear();
    _pendingReasoning.clear();
    _fullText.clear();
    _fullReasoning.clear();
    _toolRunningCount = 0;
    _bufferedReasoning.clear();
    toolRegistry?.pruneSession(sessionId.value);
  }
}
