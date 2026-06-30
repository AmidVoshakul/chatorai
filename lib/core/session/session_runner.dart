import 'dart:async';

import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/shared/utils/logger.dart';

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

  const TaskChildResult(this.output, {this.aborted = false, required this.sessionId});
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
      // fullText is accumulated via onChunk callback
      return TaskChildResult(childSession.fullText, sessionId: childId);
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
  bool textStarted = false;
  bool reasoningStarted = false;
  String? messageId;
  String fullText = '';
  String fullReasoning = '';
  String pendingText = '';
  String pendingReasoning = '';
  DateTime lastFlushTime = DateTime.now();
  StreamSubscription<SessionEvent>? eventSubscription;

  SessionRunnerSession({
    required this.repository,
    required this.sessionId,
    String? agent,
    String? modelRef,
    String? title,
    SessionID? parentId,
    this.toolRegistry,
    this.immediate = false,
  })  : _agent = agent,
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
  })  : _agent = null,
        _modelRef = null,
        _title = null,
        _parentId = null,
        initialized = true;

  /// Backing event for backward compatibility with tests.
  SessionCreated get creationEvent => SessionCreated(
        sessionId: sessionId,
        parentId: _parentId,
        agent: _agent ?? 'general',
        modelRef: _modelRef,
        title: _title ?? '',
        timestamp: DateTime.now(),
      );

  /// Appends the [SessionCreated] event to the event store and marks
  /// this session as ready for streaming. Must be called once before
  /// any [onChunk], [onReasoning], or [onTool*] calls.
  Future<void> initialize({String? agent, String? modelRef, String? title}) async {
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
    await flushText(force: true);

    if (!textStarted && content.isNotEmpty) {
      messageId = 'msg_${DateTime.now().microsecondsSinceEpoch}';
      textStarted = true;
      await repository.appendEvent(
        TextStarted(
          sessionId: sessionId,
          messageId: messageId!,
          timestamp: now,
        ),
      );
    }

    if (textStarted && messageId != null) {
      final text = content.isNotEmpty ? content : fullText;
      await repository.appendEvent(
        TextEnded(
          sessionId: sessionId,
          messageId: messageId!,
          fullText: text,
          model: model,
          timestamp: now,
        ),
      );
    }

    if (reasoningStarted && messageId != null) {
      final r = (reasoning != null && reasoning.isNotEmpty)
          ? reasoning
          : fullReasoning;
      await repository.appendEvent(
        ReasoningEnded(
          sessionId: sessionId,
          messageId: messageId!,
          fullReasoning: r,
          timestamp: now,
        ),
      );
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
    await flushText(force: true);
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
    final id = messageId ?? 'msg_${DateTime.now().microsecondsSinceEpoch}';
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

  Future<void> flushText({bool force = false}) async {
    if (!force) {
      final elapsed = DateTime.now().difference(lastFlushTime).inMilliseconds;
      if (elapsed < 250 &&
          !_isWordBoundary(pendingText) &&
          !_isWordBoundary(pendingReasoning)) {
        return;
      }
    }
    if (pendingText.isEmpty && pendingReasoning.isEmpty) return;

    final now = DateTime.now();

    if (pendingText.isNotEmpty) {
      final delta = pendingText;
      pendingText = '';
      await repository.appendEvent(
        TextDelta(
          sessionId: sessionId,
          messageId: messageId!,
          delta: delta,
          timestamp: now,
        ),
      );
    }

    if (pendingReasoning.isNotEmpty) {
      final delta = pendingReasoning;
      pendingReasoning = '';
      await repository.appendEvent(
        ReasoningDelta(
          sessionId: sessionId,
          messageId: messageId!,
          delta: delta,
          timestamp: now,
        ),
      );
    }

    lastFlushTime = now;
  }

  Future<void> Function(String) get onChunk => _handleChunk;

  Future<void> Function(String) get onReasoning => _onReasoning;

  Future<void> Function(String, String, Map<String, dynamic>) get onToolStart =>
      _onToolStart;

  Future<void> Function(String, String, String) get onToolEnd => _onToolEnd;

  Future<void> Function(String, String, String) get onToolError => _onToolError;

  Future<void> _handleChunk(String content) async {
    if (!initialized || content.isEmpty) return;

    if (!textStarted) {
      messageId = 'msg_${DateTime.now().microsecondsSinceEpoch}';
      textStarted = true;
      try {
        await repository.appendEvent(
          TextStarted(
            sessionId: sessionId,
            messageId: messageId!,
            timestamp: DateTime.now(),
          ),
        );
      } catch (e) {
        LogTags.chatService.logError('TextStarted event failed', e);
        return;
      }
    }

    pendingText += content;
    fullText += content;

    try {
      await flushText(force: immediate);
    } catch (e) {
      LogTags.chatService.logError('flushText failed', e);
    }
  }

  Future<void> _onReasoning(String content) async {
    if (!initialized || content.isEmpty) return;

    if (!textStarted) {
      messageId = 'msg_${DateTime.now().microsecondsSinceEpoch}';
      textStarted = true;
      try {
        await repository.appendEvent(
          TextStarted(
            sessionId: sessionId,
            messageId: messageId!,
            timestamp: DateTime.now(),
          ),
        );
      } catch (e) {
        LogTags.chatService.logError('TextStarted (reasoning) event failed', e);
        return;
      }
    }

    if (!reasoningStarted) {
      reasoningStarted = true;
      try {
        await repository.appendEvent(
          ReasoningStarted(
            sessionId: sessionId,
            messageId: messageId!,
            timestamp: DateTime.now(),
          ),
        );
      } catch (e) {
        LogTags.chatService.logError('ReasoningStarted event failed', e);
      }
    }

    fullReasoning += content;
    pendingReasoning += content;
    try {
      await flushText();
    } catch (e) {
      LogTags.chatService.logError('flushText (reasoning) failed', e);
    }
  }

  Future<void> _onToolStart(
    String toolCallId,
    String toolName,
    Map<String, dynamic> input,
  ) async {
    if (!initialized) return;
    try {
      await flushText(force: true);
    } catch (e) {
      LogTags.chatService.logError('flushText (tool start) failed', e);
    }
    try {
      await repository.appendEvent(
        ToolCalled(
          sessionId: sessionId,
          toolCallId: toolCallId,
          toolName: toolName,
          input: input,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      LogTags.chatService
          .logError('ToolCalled event failed for $toolName', e);
    }
  }

  Future<void> _onToolEnd(
    String toolCallId,
    String toolName,
    String result,
  ) async {
    if (!initialized) return;
    try {
      await repository.appendEvent(
        ToolSuccess(
          sessionId: sessionId,
          toolCallId: toolCallId,
          outputText: result,
          durationMs: 0,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      LogTags.chatService
          .logError('ToolSuccess event failed for $toolName', e);
    }
  }

  Future<void> _onToolError(
    String toolCallId,
    String toolName,
    String error,
  ) async {
    if (!initialized) return;
    try {
      await repository.appendEvent(
        ToolFailed(
          sessionId: sessionId,
          toolCallId: toolCallId,
          error: error,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      LogTags.chatService
          .logError('ToolFailed event failed for $toolName', e);
    }
  }

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

  void dispose() {
    eventSubscription?.cancel();
    toolRegistry?.pruneSession(sessionId.value);
  }
}
