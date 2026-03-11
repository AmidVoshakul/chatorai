import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/utils/markdown_parser.dart';

// ===========================================================================
// CHAT SCREEN STATE (UNIFIED)
// ===========================================================================

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
    );
  }
}

// ===========================================================================
// CHAT SCREEN NOTIFIER (UNIFIED)
// ===========================================================================

class ChatScreenNotifier extends Notifier<ChatScreenState> {
  @override
  ChatScreenState build() => const ChatScreenState();

  // Streaming & Suggestions
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

  // Sidebar
  void toggleSidebar() {
    state = state.copyWith(isSidebarCollapsed: !state.isSidebarCollapsed);
  }

  void setSidebarCollapsed(bool collapsed) {
    if (state.isSidebarCollapsed != collapsed) {
      state = state.copyWith(isSidebarCollapsed: collapsed);
    }
  }

  // Navigator
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
}

// ===========================================================================
// PROVIDER
// ===========================================================================

final chatScreenProvider =
    NotifierProvider<ChatScreenNotifier, ChatScreenState>(
      ChatScreenNotifier.new,
    );
