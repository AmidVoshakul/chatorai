import 'dart:async';

import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/tools/tool_registry.dart';

class TaskChildResult {
  final String output;
  final bool aborted;

  const TaskChildResult(this.output, {this.aborted = false});
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
    final event = SessionCreated(
      sessionId: SessionID.create(),
      parentId: parentSessionId != null
          ? SessionID.fromString(parentSessionId)
          : null,
      title: title ?? '',
      agent: agent,
      modelRef: modelRef,
      timestamp: DateTime.now(),
    );
    return SessionRunnerSession._(
      repository: repository,
      creationEvent: event,
      toolRegistry: toolRegistry,
    );
  }

  /// Creates a session that is immediately writable by appending the
  /// [SessionCreated] event to the store and setting [initialized] to true.
  /// Must be called once before any [onChunk]/[onReasoning]/[onTool*] calls.
  Future<SessionRunnerSession> startInitializedSession({
    required String agent,
    String? modelRef,
    String? title,
    String? parentSessionId,
  }) async {
    final session = startSession(
      agent: agent,
      modelRef: modelRef,
      title: title,
      parentSessionId: parentSessionId,
    );
    await session.initialize();
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
    sdk.CancellationToken? abortSignal,
  }) async {
    final childState = await repository.createChildSession(
      parentSessionId,
      agent: agent,
      modelRef: modelRef,
      title: title,
    );
    final childId = childState.id;

    await repository.appendEvent(
      TaskStarted(
        sessionId: parentSessionId,
        taskId: taskId ?? 'task_${childId.value}',
        description: taskPrompt,
        timestamp: DateTime.now(),
      ),
    );

    final childRunner = SessionRunnerSession._(
      repository: repository,
      creationEvent: SessionCreated(
        sessionId: childId,
        parentId: parentSessionId,
        title: childState.title,
        agent: childState.agent,
        modelRef: childState.modelRef,
        permission: childState.permission,
        timestamp: DateTime.now(),
      ),
      toolRegistry: toolRegistry,
    );
    // Session already persisted by createChildSession above — skip append.
    childRunner.initialized = true;

    String accumulateText = '';
    final completer = Completer<String>();

    childRunner._onChunk = (String text) {
      accumulateText += text;
      if (!completer.isCompleted) completer.complete(accumulateText);
    };

    Timer? abortTimer;
    final abortCompleter = Completer<void>();
    if (abortSignal != null) {
      abortTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (abortSignal.isCancelled && !abortCompleter.isCompleted) {
          abortCompleter.complete();
        }
      });
    }

    try {
      await Future.any([
        streamFn(childRunner),
        if (abortSignal != null) abortCompleter.future,
      ]);
      if (abortSignal?.isCancelled ?? false) {
        return TaskChildResult(accumulateText, aborted: true);
      }
      if (!completer.isCompleted) completer.complete(accumulateText);
      await childRunner.onCompletion(content: accumulateText);
      final result = await completer.future.timeout(
        const Duration(minutes: 30),
        onTimeout: () => accumulateText,
      );
      return TaskChildResult(result);
    } finally {
      abortTimer?.cancel();
      childRunner.dispose();
    }
  }
}

class SessionRunnerSession {
  final SessionRepository repository;
  final SessionCreated creationEvent;
  final ToolRegistry? toolRegistry;

  SessionID get sessionId => creationEvent.sessionId;

  bool initialized = false;
  bool textStarted = false;
  bool reasoningStarted = false;
  String? messageId;
  String fullText = '';
  String fullReasoning = '';
  String pendingText = '';
  String pendingReasoning = '';
  DateTime lastFlushTime = DateTime.now();
  void Function(String) _onChunk = (_) {};
  StreamSubscription<SessionEvent>? eventSubscription;

  SessionRunnerSession._({
    required this.repository,
    required this.creationEvent,
    this.toolRegistry,
  });

  /// Appends the [SessionCreated] event to the event store and marks
  /// this session as ready for streaming. Must be called once before
  /// any [onChunk], [onReasoning], or [onTool*] calls.
  Future<void> initialize() async {
    if (initialized) return;
    await repository.appendEvent(creationEvent);
    initialized = true;
  }

  Future<SessionState> onCompletion({
    required String content,
    String? reasoning,
    String? model,
    int tokensInput = 0,
    int tokensOutput = 0,
    int tokensReasoning = 0,
  }) async {
    final now = DateTime.now();
    await flushText(force: true);

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

  void Function(String) get onChunk => (content) {
    _handleChunk(content);
    _onChunk(content);
  };

  void _handleChunk(String content) {
    if (!initialized || content.isEmpty) return;

    if (!textStarted) {
      messageId = 'msg_${DateTime.now().microsecondsSinceEpoch}';
      textStarted = true;
      unawaited(
        repository.appendEvent(
          TextStarted(
            sessionId: sessionId,
            messageId: messageId!,
            timestamp: DateTime.now(),
          ),
        ),
      );
    }

    fullText += content;
    pendingText += content;
    unawaited(flushText());
  }

  void Function(String) get onReasoning => _onReasoning;

  void _onReasoning(String content) {
    if (!initialized || content.isEmpty) return;

    if (!textStarted) {
      messageId = 'msg_${DateTime.now().microsecondsSinceEpoch}';
      textStarted = true;
      unawaited(
        repository.appendEvent(
          TextStarted(
            sessionId: sessionId,
            messageId: messageId!,
            timestamp: DateTime.now(),
          ),
        ),
      );
    }

    if (!reasoningStarted) {
      reasoningStarted = true;
      unawaited(
        repository.appendEvent(
          ReasoningStarted(
            sessionId: sessionId,
            messageId: messageId!,
            timestamp: DateTime.now(),
          ),
        ),
      );
    }

    fullReasoning += content;
    pendingReasoning += content;
    unawaited(flushText());
  }

  void Function(String, String, Map<String, dynamic>) get onToolStart =>
      _onToolStart;

  void _onToolStart(
    String toolCallId,
    String toolName,
    Map<String, dynamic> input,
  ) {
    if (!initialized) return;
    unawaited(flushText(force: true));
    unawaited(
      repository.appendEvent(
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

  void Function(String, String, String) get onToolEnd => _onToolEnd;

  void _onToolEnd(String toolCallId, String toolName, String result) {
    if (!initialized) return;
    unawaited(
      repository.appendEvent(
        ToolSuccess(
          sessionId: sessionId,
          toolCallId: toolCallId,
          outputText: result,
          durationMs: 0,
          timestamp: DateTime.now(),
        ),
      ),
    );
  }

  void Function(String, String, String) get onToolError => _onToolError;

  void _onToolError(String toolCallId, String toolName, String error) {
    if (!initialized) return;
    unawaited(
      repository.appendEvent(
        ToolFailed(
          sessionId: sessionId,
          toolCallId: toolCallId,
          error: error,
          timestamp: DateTime.now(),
        ),
      ),
    );
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
