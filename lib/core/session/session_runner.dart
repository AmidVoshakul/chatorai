import 'dart:async';

import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';

// ===========================================================================
// SESSION RUNNER
// ===========================================================================

/// Wraps the streaming lifecycle for a single session.
///
/// Creates/loads a session when streaming starts, publishes events to
/// the EventStore via SessionRepository during streaming, and finalizes
/// the session on completion.
class SessionRunner {
  final SessionRepository _repository;

  /// Active child session runners keyed by child [SessionID].
  ///
  /// Created by [runTaskInChild] and disposed when the child completes
  /// or when [disposeAllChildren] is called.
  final Map<SessionID, SessionRunnerSession> _childRunners = {};

  SessionRunner(this._repository);

  /// Returns an unmodifiable view of active child runners.
  Map<SessionID, SessionRunnerSession> get childRunners =>
      Map.unmodifiable(_childRunners);

  /// Start a new streaming session.
  ///
  /// Creates a new session and returns [SessionRunnerSession] with
  /// callbacks that should be wired into
  /// [ChatAiService.streamChatCompletion].
  SessionRunnerSession startSession({
    required String agent,
    String? modelRef,
    String? parentSessionId,
  }) {
    final event = SessionCreated(
      sessionId: SessionID.create(),
      parentId: parentSessionId != null
          ? SessionID.fromString(parentSessionId)
          : null,
      title: '',
      agent: agent,
      modelRef: modelRef,
      timestamp: DateTime.now(),
    );

    // We append later — first create the runner session, then
    // the caller must call [initialize] to persist the creation event.
    return SessionRunnerSession._(
      repository: _repository,
      creationEvent: event,
    );
  }

  /// Creates a child session under [parentSessionId] and runs [taskPrompt]
  /// within it.
  ///
  /// The child session inherits model/provider/system prompt from the
  /// parent unless overridden via [agent] / [modelRef].
  ///
  /// Returns a [Future<String>] that completes with the child's output
  /// when the task finishes. The output is also propagated back to the
  /// parent session as a [TaskCompleted] event.
  ///
  /// [taskPrompt] is the user message sent to the child session.
  /// [taskId] is an optional identifier; defaults to a generated value.
  /// [streamFn] is a callback that performs the actual AI streaming
  /// against the child runner. It receives the wired
  /// [SessionRunnerSession] and must complete when streaming is done.
  Future<String> runTaskInChild({
    required SessionID parentSessionId,
    required String taskPrompt,
    required Future<void> Function(SessionRunnerSession child) streamFn,
    String? agent,
    String? modelRef,
    String? title,
    String? taskId,
  }) async {
    // 1. Create child session linked to parent
    final childState = await _repository.createChildSession(
      parentSessionId,
      agent: agent,
      modelRef: modelRef,
      title: title,
    );
    final childId = childState.id;

    // 2. Publish TaskStarted on the parent session
    final effectiveTaskId = taskId ?? 'task_${childId.value}';
    await _repository.appendEvent(
      TaskStarted(
        sessionId: parentSessionId,
        taskId: effectiveTaskId,
        description: taskPrompt,
        timestamp: DateTime.now(),
      ),
    );

    // 3. Initialize child runner
    final childRunner = SessionRunnerSession._(
      repository: _repository,
      creationEvent: SessionCreated(
        sessionId: childId,
        parentId: parentSessionId,
        title: childState.title,
        agent: childState.agent,
        modelRef: childState.modelRef,
        timestamp: DateTime.now(),
      ),
    );
    _childRunners[childId] = childRunner;

    // 4. Mark child runner as initialized (SessionCreated already persisted by createChildSession)
    childRunner._initialized = true;

    // 5. Publish user message in child session
    await childRunner.publishUserMessage(content: taskPrompt);

    // 6. Prepare completer for child output
    final completer = Completer<String>();
    childRunner._onTaskCompleted = () {
      if (!completer.isCompleted) {
        // _fullText accumulates all chunks; use as final output
        completer.complete(childRunner._fullText);
      }
    };

    String childOutput;
    try {
      // 7. Run the streaming function — this blocks until AI completes
      await streamFn(childRunner);

      // 8. Wait for child completion (onCompletion callback fires)
      // Use a timeout to avoid hanging forever if callback never fires
      childOutput = await completer.future.timeout(
        const Duration(minutes: 30),
        onTimeout: () => childRunner._fullText,
      );
    } finally {
      // 9. Clean up child runner — always dispose, even on error
      childRunner.dispose();
      _childRunners.remove(childId);
    }

    // 10. Propagate output to parent (always, even if error occurred earlier)
    try {
      await _repository.propagateChildOutput(
        parentSessionId: parentSessionId,
        childSessionId: childId,
        output: childOutput.isNotEmpty ? childOutput : 'Task completed',
        taskId: effectiveTaskId,
      );
    } catch (_) {
      // ignore propagate failures to not mask upstream errors
    }

    return childOutput;
  }

  /// Disposes all active child runners and clears the tracking map.
  void disposeAllChildren() {
    for (final runner in _childRunners.values) {
      runner.dispose();
    }
    _childRunners.clear();
  }

  /// Disposes this runner and all active child runners.
  ///
  /// Cancels the event subscription first, then disposes all children
  /// to ensure pending child operations complete before resources are
  /// released.
  void dispose() {
    disposeAllChildren();
    // Note: _eventSubscription is per SessionRunnerSession, not SessionRunner.
    // SessionRunner itself has no subscription to cancel here.
  }
}

// ===========================================================================
// SESSION RUNNER SESSION
// ===========================================================================

/// A single streaming session with its lifecycle callbacks.
///
/// Usage:
/// ```dart
/// final runner = SessionRunner(repository);
/// final session = runner.startSession(agent: 'general');
///
/// await aiService.streamChatCompletion(
///   onChunk: session.onChunk,
///   onReasoning: session.onReasoning,
///   onToolStart: session.onToolStart,
///   onToolEnd: session.onToolEnd,
///   onToolError: session.onToolError,
///   onCompletion: (text) async {
///     await session.onCompletion(text, reasoning);
///   },
/// );
/// ```
class SessionRunnerSession {
  final SessionRepository _repository;
  final SessionCreated _creationEvent;

  SessionID get sessionId => _creationEvent.sessionId;

  bool _initialized = false;
  bool _textStarted = false;
  bool _reasoningStarted = false;
  String? _messageId;
  String _fullText = '';
  String _fullReasoning = '';
  String _pendingText = '';
  String _pendingReasoning = '';
  DateTime _lastFlushTime = DateTime.now();
  StreamSubscription<SessionEvent>? _eventSubscription;

  /// Optional callback invoked when the child task completes.
  ///
  /// Used by [SessionRunner.runTaskInChild] to signal that the child
  /// session's streaming is done and the output buffer can be collected.
  void Function()? _onTaskCompleted;

  static const int _flushIntervalMs = 250;

  SessionRunnerSession._({
    required SessionRepository repository,
    required SessionCreated creationEvent,
  }) : _repository = repository,
       _creationEvent = creationEvent;

  /// Initialize the session by persisting the creation event.
  ///
  /// Must be called once before using the callbacks.
  /// Returns the initial [SessionState].
  Future<SessionState> initialize() async {
    if (_initialized) {
      return _repository.createSession(
        id: _creationEvent.sessionId,
        parentId: _creationEvent.parentId,
        title: _creationEvent.title,
        agent: _creationEvent.agent,
        modelRef: _creationEvent.modelRef,
      );
    }
    _initialized = true;
    // Actually call createSession which publishes SessionCreated
    return _repository.createSession(
      id: _creationEvent.sessionId,
      parentId: _creationEvent.parentId,
      title: _creationEvent.title,
      agent: _creationEvent.agent,
      modelRef: _creationEvent.modelRef,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers: word boundary detection (mirrors chat_screen_streaming)
  // ---------------------------------------------------------------------------

  static bool _isWordBoundary(String text) {
    if (text.isEmpty) return false;
    final lastChar = text[text.length - 1];
    return lastChar == ' ' ||
        lastChar == '\n' ||
        lastChar == '.' ||
        lastChar == ',' ||
        lastChar == '!' ||
        lastChar == '?' ||
        lastChar == ';' ||
        lastChar == ':' ||
        lastChar == ')' ||
        lastChar == ']' ||
        lastChar == '}' ||
        lastChar == '"' ||
        lastChar == "'";
  }

  bool _shouldFlush({bool force = false}) {
    if (force) return true;
    final elapsed = DateTime.now().difference(_lastFlushTime).inMilliseconds;
    return elapsed >= _flushIntervalMs ||
        _isWordBoundary(_pendingText) ||
        _isWordBoundary(_pendingReasoning);
  }

  Future<void> _flushText({bool force = false}) async {
    if (!_shouldFlush(force: force)) return;
    if (_pendingText.isEmpty && _pendingReasoning.isEmpty) return;

    final now = DateTime.now();

    if (_pendingText.isNotEmpty) {
      final delta = _pendingText;
      _pendingText = '';
      await _repository.appendEvent(
        TextDelta(
          sessionId: sessionId,
          messageId: _messageId!,
          delta: delta,
          timestamp: now,
        ),
      );
    }

    if (_pendingReasoning.isNotEmpty) {
      final delta = _pendingReasoning;
      _pendingReasoning = '';
      await _repository.appendEvent(
        ReasoningDelta(
          sessionId: sessionId,
          messageId: _messageId!,
          delta: delta,
          timestamp: now,
        ),
      );
    }

    _lastFlushTime = now;
  }

  // ---------------------------------------------------------------------------
  // Callbacks
  // ---------------------------------------------------------------------------

  /// Handle a text chunk from the streaming response.
  void Function(String) get onChunk => _onChunk;

  void _onChunk(String content) {
    if (!_initialized) return;
    if (content.isEmpty) return;

    if (!_textStarted) {
      _messageId = 'msg_${DateTime.now().microsecondsSinceEpoch}';
      _textStarted = true;
      // Fire-and-forget: publish TextStarted immediately
      unawaited(
        _repository.appendEvent(
          TextStarted(
            sessionId: sessionId,
            messageId: _messageId!,
            timestamp: DateTime.now(),
          ),
        ),
      );
    }

    _fullText += content;
    _pendingText += content;
    unawaited(_flushText());
  }

  /// Handle a reasoning chunk from the streaming response.
  void Function(String) get onReasoning => _onReasoning;

  void _onReasoning(String content) {
    if (!_initialized) return;
    if (content.isEmpty) return;

    if (!_reasoningStarted) {
      if (!_textStarted) {
        // Reasoning can start before text — ensure message exists
        _messageId = 'msg_${DateTime.now().microsecondsSinceEpoch}';
        _textStarted = true;
        unawaited(
          _repository.appendEvent(
            TextStarted(
              sessionId: sessionId,
              messageId: _messageId!,
              timestamp: DateTime.now(),
            ),
          ),
        );
      }
      _reasoningStarted = true;
      unawaited(
        _repository.appendEvent(
          ReasoningStarted(
            sessionId: sessionId,
            messageId: _messageId!,
            timestamp: DateTime.now(),
          ),
        ),
      );
    }

    _fullReasoning += content;
    _pendingReasoning += content;
    unawaited(_flushText());
  }

  /// Handle tool start event.
  void Function(String toolCallId, String toolName, Map<String, dynamic> input)
  get onToolStart => _onToolStart;

  void _onToolStart(
    String toolCallId,
    String toolName,
    Map<String, dynamic> input,
  ) {
    if (!_initialized) return;
    // Flush any pending text before tool event
    unawaited(_flushText(force: true));
    unawaited(
      _repository.appendEvent(
        ToolCalled(
          sessionId: sessionId,
          toolCallId: toolCallId,
          toolName: toolName,
          input: input,
          timestamp: DateTime.now(),
        ),
      ),
    );
  }

  /// Handle tool end event.
  void Function(String toolCallId, String toolName, String result)
  get onToolEnd => _onToolEnd;

  void _onToolEnd(String toolCallId, String toolName, String result) {
    if (!_initialized) return;
    unawaited(
      _repository.appendEvent(
        ToolSuccess(
          sessionId: sessionId,
          toolCallId: toolCallId,
          outputText: result,
          durationMs: 0, // duration tracked by caller if needed
          timestamp: DateTime.now(),
        ),
      ),
    );
  }

  /// Handle tool error event.
  void Function(String toolCallId, String toolName, String error)
  get onToolError => _onToolError;

  void _onToolError(String toolCallId, String toolName, String error) {
    if (!_initialized) return;
    unawaited(
      _repository.appendEvent(
        ToolFailed(
          sessionId: sessionId,
          toolCallId: toolCallId,
          error: error,
          timestamp: DateTime.now(),
        ),
      ),
    );
  }

  /// Finalize the session on streaming completion.
  ///
  /// Publishes TextEnded, ReasoningEnded (if applicable), and StepEnded.
  /// Returns the final [SessionState].
  Future<SessionState> onCompletion({
    required String content,
    String? reasoning,
    String? model,
    int tokensInput = 0,
    int tokensOutput = 0,
    int tokensReasoning = 0,
  }) async {
    if (!_initialized) {
      return await _repository.loadSession(sessionId) ??
          SessionState(
            id: sessionId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
    }

    final now = DateTime.now();

    // Flush any remaining pending content
    await _flushText(force: true);

    // Publish TextEnded if text was streamed
    if (_textStarted && _messageId != null) {
      // Use the accumulated full content for completeness
      final finalText = content.isNotEmpty ? content : _fullText;
      await _repository.appendEvent(
        TextEnded(
          sessionId: sessionId,
          messageId: _messageId!,
          fullText: finalText,
          model: model,
          timestamp: now,
        ),
      );
    }

    // Publish ReasoningEnded if reasoning was streamed
    if (_reasoningStarted && _messageId != null) {
      final finalReasoning = (reasoning != null && reasoning.isNotEmpty)
          ? reasoning
          : _fullReasoning;
      await _repository.appendEvent(
        ReasoningEnded(
          sessionId: sessionId,
          messageId: _messageId!,
          fullReasoning: finalReasoning,
          timestamp: now,
        ),
      );
    }

    // Update session tokens and mark step completion
    await _repository.appendEvent(
      StepEnded(
        sessionId: sessionId,
        stepNumber: 1,
        tokensInput: tokensInput,
        tokensOutput: tokensOutput,
        tokensReasoning: tokensReasoning,
        timestamp: now,
      ),
    );

    // Signal task completion to the parent runner (for child lifecycle)
    _onTaskCompleted?.call();

    return await _repository.loadSession(sessionId) ??
        SessionState(id: sessionId, createdAt: now, updatedAt: now);
  }

  /// Mark the current step as failed on error.
  Future<void> onError(Object error) async {
    if (!_initialized) return;
    // Flush any pending text before recording the error
    await _flushText(force: true);
    await _repository.appendEvent(
      StepFailed(
        sessionId: sessionId,
        stepNumber: 1,
        error: error.toString(),
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Publish a user message event to the session.
  ///
  /// Call this when the user sends a message, before streaming starts.
  /// The [content] is the raw text entered by the user.
  /// If [messageId] is omitted, a timestamp-based ID is generated.
  Future<void> publishUserMessage({
    required String content,
    String? messageId,
  }) async {
    if (!_initialized) return; // Guard: don't publish before session created
    final id = messageId ?? 'msg_${DateTime.now().microsecondsSinceEpoch}';
    await _repository.appendEvent(
      MessageAdded(
        sessionId: sessionId,
        messageId: id,
        role: 'user',
        content: content,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Dispose of any held resources.
  void dispose() {
    _eventSubscription?.cancel();
  }
}
