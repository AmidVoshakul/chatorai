import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart'
    show AssistantText;
import 'package:chatorai/core/tools/tool_registry.dart';

class SessionRunnerHolder {
  SessionRunner? runner;
  String? parentSessionId;

  /// Real child session ID set by task tool when child session is created.
  /// Only one task runs at a time per parent, so a single slot suffices.
  String? activeChildSessionId;

  /// Callback fired when a child tool starts executing during task delegation.
  /// Used to forward child tool events to the parent TaskPart UI.
  void Function(String toolName, String? title)? onChildToolEvent;

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

  Future<TaskChildResult> runTaskInChild({
    required SessionID parentSessionId,
    required String taskPrompt,
    required Future<void> Function(SessionRunnerSession child) streamFn,
    String? agent,
    String? modelRef,
    String? title,
    String? taskId,
    SessionRunnerHolder? holder,
  }) async {
    final childState = await repository.createChildSession(
      parentSessionId,
      agent: agent,
      modelRef: modelRef,
      title: title,
    );
    final childId = childState.id;

    final childSession = SessionRunnerSession.forExisting(
      repository: repository,
      sessionId: childId,
      immediate: true,
    );

    holder?.activeChildSessionId = childId.value;

    // Persist user prompt as first message in child session (mirrors parent UX)
    await childSession.publishUserMessage(content: taskPrompt);

    try {
      await streamFn(childSession);
      final state = await repository.loadSession(childId);
      final fullText = state == null
          ? ''
          : state.parts.whereType<AssistantText>().map((p) => p.text).join();
      return TaskChildResult(fullText, sessionId: childId);
    } finally {
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
  String? messageId;
  String? _openTextPartId;
  String? _openReasoningPartId;
  String _pendingReasoningText = '';
  final Map<String, String> _toolPartIds = {};
  final Set<String> _startedToolCalls = {};

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
  Future<void> initialize({
    String? agent,
    String? modelRef,
    String? title,
  }) async {
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
  }

  Future<void> onChunk(String content) async {
    if (!initialized || content.isEmpty) return;
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
    await repository.appendEvent(
      TextDelta(
        sessionId: sessionId,
        messageId: messageId!,
        partId: _openTextPartId!,
        delta: content,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> onReasoning(String content) async {
    if (!initialized || content.isEmpty) return;
    _pendingReasoningText += content;
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
    await repository.appendEvent(
      ReasoningDelta(
        sessionId: sessionId,
        messageId: messageId!,
        partId: _openReasoningPartId!,
        delta: content,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> onToolStart(
    String toolCallId,
    String toolName,
    Map<String, dynamic> input,
  ) async {
    if (!initialized) return;
    if (!_startedToolCalls.add(toolCallId)) return;
    final partId = _genPartId(toolCallId);
    _toolPartIds[toolCallId] = partId;
    await _closeReasoningIfOpen();
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
  }

  Future<void> onToolEnd(
    String toolCallId,
    String toolName,
    String result,
  ) async {
    if (!initialized) return;
    final partId = _toolPartIds[toolCallId];
    if (partId == null) return;
    await repository.appendEvent(
      ToolSuccess(
        sessionId: sessionId,
        toolCallId: toolCallId,
        outputText: result,
        partId: partId,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> onToolError(
    String toolCallId,
    String toolName,
    String error,
  ) async {
    if (!initialized) return;
    final partId = _toolPartIds[toolCallId];
    if (partId == null) return;
    await repository.appendEvent(
      ToolFailed(
        sessionId: sessionId,
        toolCallId: toolCallId,
        error: error,
        partId: partId,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _closeReasoningIfOpen() async {
    if (_openReasoningPartId == null || messageId == null) return;
    await repository.appendEvent(
      ReasoningEnded(
        sessionId: sessionId,
        messageId: messageId!,
        fullReasoning: _pendingReasoningText,
        partId: _openReasoningPartId!,
        timestamp: DateTime.now(),
      ),
    );
    _openReasoningPartId = null;
    _pendingReasoningText = '';
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
  }) async {
    final now = DateTime.now();

    // Close any open text
    if (_openTextPartId != null && messageId != null) {
      await repository.appendEvent(
        TextEnded(
          sessionId: sessionId,
          messageId: messageId!,
          partId: _openTextPartId!,
          fullText: content,
          model: model,
          timestamp: now,
        ),
      );
      _openTextPartId = null;
    }

    // Close any open reasoning if there is reasoning content to close
    if (_openReasoningPartId != null && messageId != null) {
      final reasonText = reasoning ?? _pendingReasoningText;
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
      _pendingReasoningText = '';
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
  }

  Future<void> onError(Object error) async {
    await repository.appendEvent(
      StepFailed(
        sessionId: sessionId,
        stepNumber: 1,
        error: error.toString(),
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> publishUserMessage({
    required String content,
    String? messageId,
  }) async {
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
  }

  Future<void> onTaskStart({
    required String partId,
    required String description,
    required String agent,
    String? sessionId,
  }) async {
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
  }

  Future<void> onTaskEnd(String partId) async {
    if (!initialized) return;
    await repository.appendEvent(
      TaskPartCompleted(
        sessionId: sessionId,
        partId: partId,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> onTaskError(String partId, String error) async {
    if (!initialized) return;
    await repository.appendEvent(
      TaskPartError(
        sessionId: sessionId,
        partId: partId,
        error: error,
        timestamp: DateTime.now(),
      ),
    );
  }

  void dispose() {
    _startedToolCalls.clear();
    toolRegistry?.pruneSession(sessionId.value);
  }
}
