import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/utils/markdown_parser_with_keys.dart';

// ===========================================================================
// STATE
// ===========================================================================

class ChatScreenUIState {
  final bool isSidebarCollapsed;
  final bool isNavigatorVisible;
  final List<MarkdownHeadingInfoWithKey> navigatorHeadings;
  final int activeHeadingIndex;

  const ChatScreenUIState({
    this.isSidebarCollapsed = false,
    this.isNavigatorVisible = false,
    this.navigatorHeadings = const [],
    this.activeHeadingIndex = -1,
  });

  ChatScreenUIState copyWith({
    bool? isSidebarCollapsed,
    bool? isNavigatorVisible,
    List<MarkdownHeadingInfoWithKey>? navigatorHeadings,
    int? activeHeadingIndex,
  }) {
    return ChatScreenUIState(
      isSidebarCollapsed: isSidebarCollapsed ?? this.isSidebarCollapsed,
      isNavigatorVisible: isNavigatorVisible ?? this.isNavigatorVisible,
      navigatorHeadings: navigatorHeadings ?? this.navigatorHeadings,
      activeHeadingIndex: activeHeadingIndex ?? this.activeHeadingIndex,
    );
  }
}

// ===========================================================================
// NOTIFIER
// ===========================================================================

class ChatScreenUINotifier extends Notifier<ChatScreenUIState> {
  @override
  ChatScreenUIState build() {
    return const ChatScreenUIState();
  }

  void toggleSidebar() {
    state = state.copyWith(isSidebarCollapsed: !state.isSidebarCollapsed);
  }

  void setSidebarCollapsed(bool collapsed) {
    if (state.isSidebarCollapsed != collapsed) {
      state = state.copyWith(isSidebarCollapsed: collapsed);
    }
  }

  void setNavigatorVisible(bool visible) {
    if (state.isNavigatorVisible != visible) {
      state = state.copyWith(isNavigatorVisible: visible);
    }
  }

  void toggleNavigator() {
    state = state.copyWith(isNavigatorVisible: !state.isNavigatorVisible);
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

final chatScreenUIProvider =
    NotifierProvider<ChatScreenUINotifier, ChatScreenUIState>(
      ChatScreenUINotifier.new,
    );
