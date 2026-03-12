import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers/chat/chat_screen_notifier.dart';
import 'package:chatorai/utils/markdown_parser.dart';

void main() {
  group('ChatScreenNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has default values', () {
      final state = container.read(chatScreenProvider);
      expect(state.isStreaming, false);
      expect(state.isSuggestionsLoading, false);
      expect(state.showSuggestions, false);
      expect(state.showWelcomeSuggestions, false);
      expect(state.continuationSuggestions, isEmpty);
      expect(state.welcomeSuggestions, isEmpty);
      expect(state.isSidebarCollapsed, false);
      expect(state.isNavigatorVisible, false);
      expect(state.navigatorHeadings, isEmpty);
      expect(state.activeHeadingIndex, -1);
    });

    group('Streaming', () {
      test('setStreaming updates streaming state', () {
        container.read(chatScreenProvider.notifier).setStreaming(true);
        final state = container.read(chatScreenProvider);
        expect(state.isStreaming, true);
      });

      test('streaming state can be toggled off', () {
        container.read(chatScreenProvider.notifier).setStreaming(true);
        container.read(chatScreenProvider.notifier).setStreaming(false);
        final state = container.read(chatScreenProvider);
        expect(state.isStreaming, false);
      });
    });

    group('Suggestions', () {
      test('setSuggestionsLoading updates loading state', () {
        container.read(chatScreenProvider.notifier).setSuggestionsLoading(true);
        final state = container.read(chatScreenProvider);
        expect(state.isSuggestionsLoading, true);
      });

      test('showContinuationSuggestions shows suggestions with content', () {
        container.read(chatScreenProvider.notifier).showContinuationSuggestions(
          ['suggestion 1', 'suggestion 2'],
        );
        final state = container.read(chatScreenProvider);
        expect(state.showSuggestions, true);
        expect(state.continuationSuggestions, ['suggestion 1', 'suggestion 2']);
      });

      test('showContinuationSuggestions hides for empty list', () {
        container
            .read(chatScreenProvider.notifier)
            .showContinuationSuggestions([]);
        final state = container.read(chatScreenProvider);
        expect(state.showSuggestions, false);
      });

      test('hideSuggestions hides continuation suggestions', () {
        container.read(chatScreenProvider.notifier).showContinuationSuggestions(
          ['suggestion'],
        );
        container.read(chatScreenProvider.notifier).hideSuggestions();
        final state = container.read(chatScreenProvider);
        expect(state.showSuggestions, false);
        expect(state.continuationSuggestions, isEmpty);
      });

      test('showWelcomeSuggestions shows welcome suggestions', () {
        container.read(chatScreenProvider.notifier).showWelcomeSuggestions([
          'welcome 1',
          'welcome 2',
        ]);
        final state = container.read(chatScreenProvider);
        expect(state.showWelcomeSuggestions, true);
        expect(state.welcomeSuggestions, ['welcome 1', 'welcome 2']);
      });

      test('showWelcomeSuggestions hides continuation suggestions', () {
        container.read(chatScreenProvider.notifier).showContinuationSuggestions(
          ['suggestion'],
        );
        container.read(chatScreenProvider.notifier).showWelcomeSuggestions([
          'welcome',
        ]);
        final state = container.read(chatScreenProvider);
        expect(state.showSuggestions, false);
        expect(state.showWelcomeSuggestions, true);
      });

      test('hideWelcomeSuggestions hides welcome suggestions', () {
        container.read(chatScreenProvider.notifier).showWelcomeSuggestions([
          'welcome',
        ]);
        container.read(chatScreenProvider.notifier).hideWelcomeSuggestions();
        final state = container.read(chatScreenProvider);
        expect(state.showWelcomeSuggestions, false);
        expect(state.welcomeSuggestions, isEmpty);
      });

      test('hideAllSuggestions hides all suggestions', () {
        container.read(chatScreenProvider.notifier).showContinuationSuggestions(
          ['suggestion'],
        );
        container.read(chatScreenProvider.notifier).showWelcomeSuggestions([
          'welcome',
        ]);
        container.read(chatScreenProvider.notifier).hideAllSuggestions();
        final state = container.read(chatScreenProvider);
        expect(state.showSuggestions, false);
        expect(state.showWelcomeSuggestions, false);
        expect(state.continuationSuggestions, isEmpty);
        expect(state.welcomeSuggestions, isEmpty);
      });
    });

    group('Sidebar', () {
      test('toggleSidebar toggles sidebar state', () {
        container.read(chatScreenProvider.notifier).toggleSidebar();
        var state = container.read(chatScreenProvider);
        expect(state.isSidebarCollapsed, true);

        container.read(chatScreenProvider.notifier).toggleSidebar();
        state = container.read(chatScreenProvider);
        expect(state.isSidebarCollapsed, false);
      });

      test('setSidebarCollapsed sets specific state', () {
        container.read(chatScreenProvider.notifier).setSidebarCollapsed(true);
        final state = container.read(chatScreenProvider);
        expect(state.isSidebarCollapsed, true);
      });

      test('setSidebarCollapsed does nothing for same value', () {
        container.read(chatScreenProvider.notifier).setSidebarCollapsed(false);
        final state = container.read(chatScreenProvider);
        expect(state.isSidebarCollapsed, false);
      });
    });

    group('Navigator', () {
      test('toggleNavigator toggles navigator visibility', () {
        container.read(chatScreenProvider.notifier).toggleNavigator();
        var state = container.read(chatScreenProvider);
        expect(state.isNavigatorVisible, true);

        container.read(chatScreenProvider.notifier).toggleNavigator();
        state = container.read(chatScreenProvider);
        expect(state.isNavigatorVisible, false);
      });

      test('setNavigatorVisible sets specific state', () {
        container.read(chatScreenProvider.notifier).setNavigatorVisible(true);
        final state = container.read(chatScreenProvider);
        expect(state.isNavigatorVisible, true);
      });

      test('setNavigatorHeadings updates headings', () {
        final headings = [
          MarkdownHeadingInfoWithKey(
            text: 'Heading 1',
            level: 1,
            lineIndex: 0,
            rawLine: '# Heading 1',
            messageId: 'msg1',
          ),
          MarkdownHeadingInfoWithKey(
            text: 'Heading 2',
            level: 2,
            lineIndex: 1,
            rawLine: '## Heading 2',
            messageId: 'msg2',
          ),
        ];
        container
            .read(chatScreenProvider.notifier)
            .setNavigatorHeadings(headings);
        final state = container.read(chatScreenProvider);
        expect(state.navigatorHeadings.length, 2);
        expect(state.navigatorHeadings[0].text, 'Heading 1');
      });

      test('setActiveHeadingIndex updates active index', () {
        container.read(chatScreenProvider.notifier).setActiveHeadingIndex(2);
        final state = container.read(chatScreenProvider);
        expect(state.activeHeadingIndex, 2);
      });

      test('clearNavigator resets navigator state', () {
        final headings = [
          MarkdownHeadingInfoWithKey(
            text: 'Heading',
            level: 1,
            lineIndex: 0,
            rawLine: '# Heading',
            messageId: 'msg1',
          ),
        ];
        container
            .read(chatScreenProvider.notifier)
            .setNavigatorHeadings(headings);
        container.read(chatScreenProvider.notifier).setActiveHeadingIndex(0);
        container.read(chatScreenProvider.notifier).clearNavigator();
        final state = container.read(chatScreenProvider);
        expect(state.navigatorHeadings, isEmpty);
        expect(state.activeHeadingIndex, -1);
      });
    });
  });

  group('ChatScreenState', () {
    test('copyWith creates new instance with updated values', () {
      const state = ChatScreenState();
      final newState = state.copyWith(
        isStreaming: true,
        isSidebarCollapsed: true,
      );

      expect(newState.isStreaming, true);
      expect(newState.isSidebarCollapsed, true);
      expect(newState.showSuggestions, false);
    });

    test('copyWith preserves original values when not specified', () {
      const state = ChatScreenState(
        isStreaming: true,
        isSidebarCollapsed: true,
      );
      final newState = state.copyWith(isStreaming: false);

      expect(newState.isStreaming, false);
      expect(newState.isSidebarCollapsed, true);
    });
  });
}
