import 'dart:ui';

import 'package:chatorai/gui/features/chat/presentation/widgets/welcome_questions_data.dart';
import 'package:chatorai/gui/shared/utils/markdown_parser.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen-level UI state for the chat screen.
///
/// Contains only flags and metadata — streaming *content* (text, reasoning,
/// tools, tasks) lives in [SessionState.parts] via [sessionPartsProvider].
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
    String? streamingSessionId,
    bool clearStreamingSessionId = false,
    bool clearRetryMessage = false,
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
      retryMessage: clearRetryMessage
          ? null
          : retryMessage ?? this.retryMessage,
      retryAttempt: retryAttempt ?? this.retryAttempt,
      streamingSessionId: clearStreamingSessionId
          ? null
          : streamingSessionId ?? this.streamingSessionId,
    );
  }
}

/// Pure screen-level notifier for the chat screen.
///
/// This notifier manages **only** UI flags (streaming state, suggestions,
/// sidebar, navigator, retry info). Streaming *content* (AssistantText,
/// AssistantReasoning, tools, tasks) is read from [sessionPartsProvider].
///
/// Methods that were previously on this notifier (onChunk, onReasoning,
/// onToolCall, onTaskStart, etc.) have been removed — they are handled
/// by the EventBus → SessionPartsNotifier pipeline.
class ChatScreenNotifier extends Notifier<ChatScreenState> {
  @override
  ChatScreenState build() {
    // Seed welcome questions on the first build so the very first frame shows
    // them (no post-frame dependency). Refresh later is handled by ChatScreen.
    final language = ref.watch(languageProvider).selectedLanguage;
    final questions = WelcomeQuestionsData.getRandomQuestionsForLocale(
      lookupAppLocalizations(Locale(language)),
    );
    return ChatScreenState(
      welcomeSuggestions: questions,
      showWelcomeSuggestions: questions.isNotEmpty,
    );
  }

  // ── Streaming lifecycle ───────────────────────────────────────────────

  /// Marks the screen as streaming for [sessionId].
  void startStreaming(String sessionId) {
    state = state.copyWith(isStreaming: true, streamingSessionId: sessionId);
  }

  /// Clears the streaming flag and session id.
  void finalizeStreaming() {
    state = state.copyWith(isStreaming: false, clearStreamingSessionId: true);
  }

  /// Sets the streaming flag without touching the session id.
  void setStreaming(bool isStreaming) {
    state = state.copyWith(isStreaming: isStreaming);
  }

  // ── Suggestions ───────────────────────────────────────────────────────

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

  // ── Sidebar ───────────────────────────────────────────────────────────

  void toggleSidebar() {
    state = state.copyWith(isSidebarCollapsed: !state.isSidebarCollapsed);
  }

  void setSidebarCollapsed(bool collapsed) {
    if (state.isSidebarCollapsed != collapsed) {
      state = state.copyWith(isSidebarCollapsed: collapsed);
    }
  }

  // ── Navigator ─────────────────────────────────────────────────────────

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

  // ── Retry info ────────────────────────────────────────────────────────

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
      // When the caller sets isRetrying=false without a message, clear it.
      clearRetryMessage: retryMessage == null && !isRetrying,
    );
  }
}

final chatScreenProvider =
    NotifierProvider<ChatScreenNotifier, ChatScreenState>(
      ChatScreenNotifier.new,
    );
