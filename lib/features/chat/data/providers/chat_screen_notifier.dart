import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/markdown_parser.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';
import 'package:chatorai/features/chat/data/models/chat/todo_part.dart'
    show TodoItem;

class ChatScreenState {
  final bool isStreaming;
  final bool isSuggestionsLoading;
  final bool showSuggestions;
  final bool showWelcomeSuggestions;
  final List<String> continuationSuggestions;
  final List<String> welcomeSuggestions;
  final bool isSidebarCollapsed;
  final bool isNavigatorVisible;
  final List<MarkdownHeadingInfoWithKey> navigatorHeadings;
  final int activeHeadingIndex;
  final bool isRetrying;
  final double retryProgress;
  final String? retryMessage;
  final int retryAttempt;
  final List<AssistantContent> streamingParts;
  final String? streamingSessionId;

  const ChatScreenState({
    this.isStreaming = false,
    this.isSuggestionsLoading = false,
    this.showSuggestions = false,
    this.showWelcomeSuggestions = false,
    this.continuationSuggestions = const [],
    this.welcomeSuggestions = const [],
    this.isSidebarCollapsed = false,
    this.isNavigatorVisible = false,
    this.navigatorHeadings = const [],
    this.activeHeadingIndex = -1,
    this.isRetrying = false,
    this.retryProgress = 1.0,
    this.retryMessage,
    this.retryAttempt = 0,
    this.streamingParts = const [],
    this.streamingSessionId,
  });

  ChatScreenState copyWith({
    bool? isStreaming,
    bool? isSuggestionsLoading,
    bool? showSuggestions,
    bool? showWelcomeSuggestions,
    List<String>? continuationSuggestions,
    List<String>? welcomeSuggestions,
    bool? isSidebarCollapsed,
    bool? isNavigatorVisible,
    List<MarkdownHeadingInfoWithKey>? navigatorHeadings,
    int? activeHeadingIndex,
    bool? isRetrying,
    double? retryProgress,
    String? retryMessage,
    int? retryAttempt,
    List<AssistantContent>? streamingParts,
    String? streamingSessionId,
    bool clearStreamingSessionId = false,
  }) {
    return ChatScreenState(
      isStreaming: isStreaming ?? this.isStreaming,
      isSuggestionsLoading: isSuggestionsLoading ?? this.isSuggestionsLoading,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      showWelcomeSuggestions:
          showWelcomeSuggestions ?? this.showWelcomeSuggestions,
      continuationSuggestions:
          continuationSuggestions ?? this.continuationSuggestions,
      welcomeSuggestions: welcomeSuggestions ?? this.welcomeSuggestions,
      isSidebarCollapsed: isSidebarCollapsed ?? this.isSidebarCollapsed,
      isNavigatorVisible: isNavigatorVisible ?? this.isNavigatorVisible,
      navigatorHeadings: navigatorHeadings ?? this.navigatorHeadings,
      activeHeadingIndex: activeHeadingIndex ?? this.activeHeadingIndex,
      isRetrying: isRetrying ?? this.isRetrying,
      retryProgress: retryProgress ?? this.retryProgress,
      retryMessage: retryMessage ?? this.retryMessage,
      retryAttempt: retryAttempt ?? this.retryAttempt,
      streamingParts: streamingParts ?? this.streamingParts,
      streamingSessionId: clearStreamingSessionId
          ? null
          : streamingSessionId ?? this.streamingSessionId,
    );
  }
}

class ChatScreenNotifier extends Notifier<ChatScreenState> {
  bool _textBlockOpen = false;

  @override
  ChatScreenState build() => const ChatScreenState();

  void startStreaming(String sessionId) {
    _textBlockOpen = false;
    _seenToolEnds.clear();
    state = state.copyWith(
      isStreaming: true,
      streamingSessionId: sessionId,
      streamingParts: const [],
    );
  }

  void onChunk(
    String partId,
    String messageId,
    String sessionId,
    String delta,
  ) {
    var parts = List<AssistantContent>.from(state.streamingParts);

    final textIdx = parts.lastIndexWhere((p) => p is AssistantText);
    if (_textBlockOpen && textIdx >= 0) {
      final prev = parts[textIdx] as AssistantText;
      parts[textIdx] = AssistantText(
        id: prev.id ?? partId,
        sessionId: prev.sessionId ?? sessionId,
        messageId: prev.messageId ?? messageId,
        text: prev.text + delta,
        synthetic: prev.synthetic,
        ignored: prev.ignored,
        title: prev.title,
      );
    } else {
      parts.add(
        AssistantText(
          id: partId,
          sessionId: sessionId,
          messageId: messageId,
          text: delta,
        ),
      );
      _textBlockOpen = true;
    }

    state = state.copyWith(streamingParts: parts);
  }

  void onReasoning(
    String partId,
    String messageId,
    String sessionId,
    String delta,
  ) {
    var parts = List<AssistantContent>.from(state.streamingParts);

    final openIdx = parts.lastIndexWhere(
      (p) => p is AssistantReasoning && p.ended == null,
    );
    if (openIdx >= 0) {
      final prev = parts[openIdx] as AssistantReasoning;
      parts[openIdx] = AssistantReasoning(
        id: prev.id ?? partId,
        sessionId: prev.sessionId ?? sessionId,
        messageId: prev.messageId ?? messageId,
        text: prev.text + delta,
        started: prev.started,
        ended: null,
      );
    } else {
      parts.add(
        AssistantReasoning(
          id: partId,
          sessionId: sessionId,
          messageId: messageId,
          text: delta,
          started: DateTime.now(),
          ended: null,
        ),
      );
    }

    state = state.copyWith(streamingParts: parts);
  }

  void onToolCall(
    String partId,
    String callId,
    String messageId,
    String sessionId,
    String toolName,
    Map<String, dynamic> input,
  ) {
    var parts = List<AssistantContent>.from(state.streamingParts);
    if (parts.any((p) => p is AssistantTool && p.callId == callId)) return;
    parts = _interruptStreaming(parts);
    parts.add(
      AssistantTool(
        id: partId,
        sessionId: sessionId,
        messageId: messageId,
        callId: callId,
        tool: toolName,
        state: ToolState.running,
        input: input,
      ),
    );
    state = state.copyWith(streamingParts: parts);
  }

  final Set<String> _seenToolEnds = {};

  void onToolEnd(String callId, String toolName, String result) {
    var parts = List<AssistantContent>.from(state.streamingParts);
    if (_seenToolEnds.contains(callId)) return;
    _seenToolEnds.add(callId);
    final idx = parts.indexWhere(
      (p) => p is AssistantTool && p.callId == callId,
    );
    if (idx >= 0) {
      final tool = parts[idx] as AssistantTool;
      parts[idx] = tool.copyWith(state: ToolState.completed, output: result);
      state = state.copyWith(streamingParts: parts);
    }
  }

  void onToolError(String callId, String error) {
    var parts = List<AssistantContent>.from(state.streamingParts);
    final idx = parts.indexWhere(
      (p) => p is AssistantTool && p.callId == callId,
    );
    if (idx >= 0) {
      final tool = parts[idx] as AssistantTool;
      parts[idx] = tool.copyWith(state: ToolState.error, output: error);
      state = state.copyWith(streamingParts: parts);
    }
  }

  void onQuestion(
    String partId,
    String messageId,
    String sessionId,
    String questionText,
    List<QuestionOption> options,
    bool multiple,
  ) {
    var parts = List<AssistantContent>.from(state.streamingParts);
    parts = _interruptStreaming(parts);
    parts.add(
      AssistantQuestion(
        id: partId,
        sessionId: sessionId,
        messageId: messageId,
        question: questionText,
        options: options,
        multiple: multiple,
      ),
    );
    state = state.copyWith(streamingParts: parts);
  }

  void onQuestionEnd(String partId, String answer) {
    var parts = List<AssistantContent>.from(state.streamingParts);
    final idx = parts.indexWhere(
      (p) => p is AssistantQuestion && p.id == partId,
    );
    if (idx >= 0) {
      final q = parts[idx] as AssistantQuestion;
      parts[idx] = q.copyWith(answer: answer);
      state = state.copyWith(streamingParts: parts);
    }
  }

  void onTodo(
    String partId,
    String messageId,
    String sessionId,
    List<TodoItem> todos,
  ) {
    var parts = List<AssistantContent>.from(state.streamingParts);
    parts = _interruptStreaming(parts);
    parts.add(
      AssistantTodo(
        id: partId,
        sessionId: sessionId,
        messageId: messageId,
        todos: todos,
      ),
    );
    state = state.copyWith(streamingParts: parts);
  }

  void onTaskStart(
    String partId,
    String messageId,
    String sessionId,
    String desc,
    String agent, {
    String? taskSessionId,
  }) {
    var parts = List<AssistantContent>.from(state.streamingParts);
    if (parts.any((p) => p is AssistantTask && p.id == partId)) {
      LogTags.chatScreen.logInfo(
        '[TaskTrace] onTaskStart SKIP WHERE=notifier WHY=part already exists '
        'partId=$partId',
      );
      return;
    }
    LogTags.chatScreen.logInfo(
      '[TaskTrace] onTaskStart CREATE WHERE=notifier WHAT=add AssistantTask to streamingParts '
      'WHEN=${DateTime.now()} WHY=build task UI part partId=$partId sessionId=$sessionId '
      'desc=$desc agent=$agent partsBefore=${parts.length}',
    );
    parts = _interruptStreaming(parts);
    parts.add(
      AssistantTask(
        id: partId,
        sessionId: sessionId,
        messageId: messageId,
        description: desc,
        agent: agent,
        state: ToolState.running,
        taskSessionId: taskSessionId,
        startedAt: DateTime.now(),
      ),
    );
    state = state.copyWith(streamingParts: parts);
  }

  void onTaskToolExecuted(String partId, String toolName, String? toolTitle) {
    var parts = List<AssistantContent>.from(state.streamingParts);
    final idx = parts.indexWhere((p) => p is AssistantTask && p.id == partId);
    if (idx >= 0) {
      final task = parts[idx] as AssistantTask;
      // The delegated `task` tool call itself must not overwrite the live
      // sub-agent tool title that the widget reads from the child session —
      // otherwise the part would show a frozen "task" label. Only count it.
      final isDelegatedTask = toolName == 'task';
      parts[idx] = task.copyWith(
        currentTool: isDelegatedTask ? task.currentTool : toolName,
        currentToolTitle: isDelegatedTask ? task.currentToolTitle : toolTitle,
        toolCallsCount: task.toolCallsCount + 1,
      );
      state = state.copyWith(streamingParts: parts);
    }
  }

  /// Single source of truth for finishing a task part: sets the terminal
  /// state, error (if any), timestamps and duration. Reused by [onTaskEnd],
  /// [onTaskError] and [closeAllRunningTasks].
  AssistantTask _finalizeTask(AssistantTask task, ToolState state,
      {String? error}) {
    final now = DateTime.now();
    return task.copyWith(
      state: state,
      error: error,
      endedAt: now,
      durationMs: task.startedAt != null
          ? now.difference(task.startedAt!).inMilliseconds
          : null,
    );
  }

  void onTaskEnd(String partId) {
    var parts = List<AssistantContent>.from(state.streamingParts);
    final idx = parts.indexWhere((p) => p is AssistantTask && p.id == partId);
    if (idx >= 0) {
      final task = parts[idx] as AssistantTask;
      parts[idx] = _finalizeTask(task, ToolState.completed);
      state = state.copyWith(streamingParts: parts);
    }
  }

  void onTaskSessionIdResolved(String partId, String taskSessionId) {
    var parts = List<AssistantContent>.from(state.streamingParts);
    final idx = parts.indexWhere((p) => p is AssistantTask && p.id == partId);
    if (idx >= 0) {
      final task = parts[idx] as AssistantTask;
      LogTags.chatScreen.logInfo(
        '[TaskTrace] onTaskSessionIdResolved SET WHERE=notifier WHAT=write taskSessionId '
        'WHEN=${DateTime.now()} WHY=link TaskPart to child session so widget reads live tools '
        'partId=$partId child=$taskSessionId prevSessionId=${task.taskSessionId} '
        'changed=${task.taskSessionId != taskSessionId}',
      );
      if (task.taskSessionId != taskSessionId) {
        parts[idx] = task.copyWith(taskSessionId: taskSessionId);
        state = state.copyWith(streamingParts: parts);
      }
    } else {
      LogTags.chatScreen.logWarning(
        '[TaskTrace] onTaskSessionIdResolved NOT FOUND WHERE=notifier '
        'WHY=no AssistantTask with id=$partId in streamingParts → taskSessionId NOT set '
        'partsCount=${parts.length} partIds=${parts.whereType<AssistantTask>().map((t) => t.id).toList()}',
      );
    }
  }

  /// Marks every still-running task part as completed. Used when a stream is
  /// cancelled or finalized so no TaskPart widget is left showing a spinner.
  void closeAllRunningTasks() {
    var parts = List<AssistantContent>.from(state.streamingParts);
    var changed = false;
    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      if (p is AssistantTask && p.state == ToolState.running) {
        parts[i] = _finalizeTask(p, ToolState.completed);
        changed = true;
      }
    }
    if (changed) state = state.copyWith(streamingParts: parts);
  }

  void onTaskError(String partId, String error) {
    var parts = List<AssistantContent>.from(state.streamingParts);
    final idx = parts.indexWhere((p) => p is AssistantTask && p.id == partId);
    if (idx >= 0) {
      final task = parts[idx] as AssistantTask;
      parts[idx] = _finalizeTask(task, ToolState.error, error: error);
      state = state.copyWith(streamingParts: parts);
    }
  }

  List<AssistantContent> snapshotClosedStreamingParts() {
    var parts = List<AssistantContent>.from(state.streamingParts);
    parts = _closeOpenReasoning(parts);
    state = state.copyWith(streamingParts: parts);
    return List.unmodifiable(parts);
  }

  void finalizeStreaming() {
    _textBlockOpen = false;
    state = state.copyWith(
      isStreaming: false,
      clearStreamingSessionId: true,
      streamingParts: const [],
    );
  }

  void setStreaming(bool isStreaming) {
    state = state.copyWith(isStreaming: isStreaming);
  }

  void setSuggestionsLoading(bool loading) {
    state = state.copyWith(isSuggestionsLoading: loading);
  }

  void showContinuationSuggestions(List<String> suggestions) {
    state = state.copyWith(
      showSuggestions: suggestions.isNotEmpty,
      continuationSuggestions: suggestions,
    );
  }

  void hideSuggestions() {
    state = state.copyWith(showSuggestions: false, continuationSuggestions: []);
  }

  void showWelcomeSuggestions(List<String> suggestions) {
    state = state.copyWith(
      showWelcomeSuggestions: suggestions.isNotEmpty,
      welcomeSuggestions: suggestions,
      showSuggestions: false,
      continuationSuggestions: [],
    );
  }

  void hideWelcomeSuggestions() {
    state = state.copyWith(
      showWelcomeSuggestions: false,
      welcomeSuggestions: [],
    );
  }

  void hideAllSuggestions() {
    state = state.copyWith(
      showSuggestions: false,
      showWelcomeSuggestions: false,
      continuationSuggestions: [],
      welcomeSuggestions: [],
    );
  }

  void toggleSidebar() {
    state = state.copyWith(isSidebarCollapsed: !state.isSidebarCollapsed);
  }

  void setSidebarCollapsed(bool collapsed) {
    if (state.isSidebarCollapsed != collapsed) {
      state = state.copyWith(isSidebarCollapsed: collapsed);
    }
  }

  void toggleNavigator() {
    state = state.copyWith(isNavigatorVisible: !state.isNavigatorVisible);
  }

  void setNavigatorVisible(bool visible) {
    if (state.isNavigatorVisible != visible) {
      state = state.copyWith(isNavigatorVisible: visible);
    }
  }

  void setNavigatorHeadings(List<MarkdownHeadingInfoWithKey> headings) {
    state = state.copyWith(navigatorHeadings: headings);
  }

  void setActiveHeadingIndex(int index) {
    if (state.activeHeadingIndex != index) {
      state = state.copyWith(activeHeadingIndex: index);
    }
  }

  void clearNavigator() {
    state = state.copyWith(navigatorHeadings: [], activeHeadingIndex: -1);
  }

  void setRetrying(bool retrying) {
    if (state.isRetrying != retrying) {
      state = state.copyWith(isRetrying: retrying);
    }
  }

  void setRetryProgress(double progress) {
    if (state.retryProgress != progress) {
      state = state.copyWith(retryProgress: progress);
    }
  }

  void setRetryInfo({
    required bool isRetrying,
    String? retryMessage,
    int? retryAttempt,
  }) {
    state = state.copyWith(
      isRetrying: isRetrying,
      retryMessage: retryMessage,
      retryAttempt: retryAttempt,
    );
  }

  List<AssistantContent> _closeOpenReasoning(List<AssistantContent> parts) {
    final idx = parts.lastIndexWhere(
      (p) => p is AssistantReasoning && p.ended == null,
    );
    if (idx >= 0) {
      final last = parts[idx] as AssistantReasoning;
      final now = DateTime.now();
      return [
        ...parts.sublist(0, idx),
        AssistantReasoning(
          id: last.id!,
          sessionId: last.sessionId!,
          messageId: last.messageId!,
          text: last.text,
          started: last.started,
          ended: now,
        ),
        ...parts.sublist(idx + 1),
      ];
    }
    return parts;
  }

  List<AssistantContent> _interruptStreaming(List<AssistantContent> parts) {
    _textBlockOpen = false;
    return _closeOpenReasoning(parts);
  }
}

final chatScreenProvider =
    NotifierProvider<ChatScreenNotifier, ChatScreenState>(
      ChatScreenNotifier.new,
    );
