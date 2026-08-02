import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart'
    show
        AssistantContent,
        AssistantReasoning,
        AssistantText,
        AssistantTool,
        AssistantTask;
import 'package:chatorai/features/chat/data/models/chat/message_part.dart'
    show ToolState;
import 'package:chatorai/features/chat/data/models/chat/message_converter.dart'
    show assistantContentToPartMaps;
import 'package:chatorai/features/chat/data/providers/chat_screen_notifier.dart';

void main() {
  group('ChatScreenNotifier streaming session id', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('initial state is not streaming and has no session id', () {
      final state = container.read(chatScreenProvider);
      expect(state.isStreaming, isFalse);
      expect(state.streamingSessionId, isNull);
    });

    test('startStreaming sets isStreaming and session id', () {
      container.read(chatScreenProvider.notifier).startStreaming('ses_abc');
      final state = container.read(chatScreenProvider);
      expect(state.isStreaming, isTrue);
      expect(state.streamingSessionId, 'ses_abc');
    });

    test('finalizeStreaming clears streaming state', () {
      final n = container.read(chatScreenProvider.notifier);
      n.startStreaming('ses_abc');
      n.finalizeStreaming();

      final state = container.read(chatScreenProvider);
      expect(state.isStreaming, isFalse);
      expect(state.streamingSessionId, isNull);
    });
  });

  group('ChatScreenState — screen-level fields', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

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
      expect(state.isRetrying, false);
      expect(state.retryProgress, 1.0);
      expect(state.retryMessage, isNull);
      expect(state.retryAttempt, 0);
    });

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

      test('hideSuggestions hides suggestions', () {
        container.read(chatScreenProvider.notifier).showContinuationSuggestions(
          ['test'],
        );
        container.read(chatScreenProvider.notifier).hideSuggestions();
        final state = container.read(chatScreenProvider);
        expect(state.showSuggestions, false);
        expect(state.continuationSuggestions, isEmpty);
      });

      test('showWelcomeSuggestions shows welcome suggestions', () {
        container.read(chatScreenProvider.notifier).showWelcomeSuggestions([
          'welcome 1',
        ]);
        final state = container.read(chatScreenProvider);
        expect(state.showWelcomeSuggestions, true);
        expect(state.welcomeSuggestions, ['welcome 1']);
        expect(state.showSuggestions, false);
      });

      test('hideWelcomeSuggestions hides welcome suggestions', () {
        container.read(chatScreenProvider.notifier).showWelcomeSuggestions([
          'test',
        ]);
        container.read(chatScreenProvider.notifier).hideWelcomeSuggestions();
        final state = container.read(chatScreenProvider);
        expect(state.showWelcomeSuggestions, false);
        expect(state.welcomeSuggestions, isEmpty);
      });

      test('hideAllSuggestions hides all suggestions', () {
        container.read(chatScreenProvider.notifier).showContinuationSuggestions(
          ['a'],
        );
        container.read(chatScreenProvider.notifier).showWelcomeSuggestions([
          'b',
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
      test('toggleSidebar toggles collapsed state', () {
        container.read(chatScreenProvider.notifier).toggleSidebar();
        expect(container.read(chatScreenProvider).isSidebarCollapsed, true);
        container.read(chatScreenProvider.notifier).toggleSidebar();
        expect(container.read(chatScreenProvider).isSidebarCollapsed, false);
      });

      test('setSidebarCollapsed sets state idempotently', () {
        container.read(chatScreenProvider.notifier).setSidebarCollapsed(true);
        expect(container.read(chatScreenProvider).isSidebarCollapsed, true);
        // Calling again with same value does not error
        container.read(chatScreenProvider.notifier).setSidebarCollapsed(true);
        expect(container.read(chatScreenProvider).isSidebarCollapsed, true);
      });
    });

    group('Navigator', () {
      test('toggleNavigator toggles navigator visibility', () {
        container.read(chatScreenProvider.notifier).toggleNavigator();
        expect(container.read(chatScreenProvider).isNavigatorVisible, true);
        container.read(chatScreenProvider.notifier).toggleNavigator();
        expect(container.read(chatScreenProvider).isNavigatorVisible, false);
      });
    });

    group('Retry info', () {
      test('setRetryInfo updates retry state', () {
        container
            .read(chatScreenProvider.notifier)
            .setRetryInfo(
              isRetrying: true,
              retryMessage: 'Error occurred',
              retryAttempt: 2,
            );
        final state = container.read(chatScreenProvider);
        expect(state.isRetrying, true);
        expect(state.retryMessage, 'Error occurred');
        expect(state.retryAttempt, 2);
      });

      test('setRetryInfo resets retry attempt and clears isRetrying', () {
        container
            .read(chatScreenProvider.notifier)
            .setRetryInfo(
              isRetrying: true,
              retryMessage: 'Error',
              retryAttempt: 1,
            );
        container
            .read(chatScreenProvider.notifier)
            .setRetryInfo(isRetrying: false, retryAttempt: 0);
        final state = container.read(chatScreenProvider);
        expect(state.isRetrying, false);
        expect(state.retryAttempt, 0);
      });
    });
  });

  group('assistantContentToPartMaps — JSON schema', () {
    test('reasoning serializes with content (not text) for round-trip', () {
      final closedReasoning = AssistantReasoning(
        id: 'p1',
        sessionId: 'ses_abc',
        messageId: 'm1',
        text: 'think',
        started: DateTime.now().subtract(const Duration(seconds: 2)),
        ended: DateTime.now(),
      );

      final json = assistantContentToPartMaps([closedReasoning]).first;
      expect(json['type'], 'reasoning');
      expect(
        json['content'],
        'think',
        reason: 'must use MessagePart schema "content" key (not "text")',
      );
      expect(
        json['startedAt'],
        isNotNull,
        reason: 'must use MessagePart schema "startedAt" key (not "started")',
      );
      expect(
        json['durationMs'],
        isA<int>(),
        reason: 'timing must be preserved when ended is set',
      );
    });

    test('tool serializes with toolName/toolCallId (not tool/callId)', () {
      final tool = AssistantTool(
        id: 'p1',
        sessionId: 'ses_abc',
        messageId: 'm1',
        callId: 'tc_1',
        tool: 'shell',
        state: ToolState.completed,
        input: {'cmd': 'ls'},
        output: 'file.txt',
      );

      final json = assistantContentToPartMaps([tool]).first;
      expect(
        json['type'],
        'tool_result',
        reason: 'schema uses tool_result, not tool',
      );
      expect(json['toolName'], 'shell', reason: 'schema uses toolName');
      expect(json['toolCallId'], 'tc_1', reason: 'schema uses toolCallId');
      expect(
        json['result'],
        'file.txt',
        reason: 'schema uses result, not output',
      );
    });

    test('task serializes with status (not state)', () {
      final task = AssistantTask(
        id: 'task_1',
        sessionId: 'ses_abc',
        messageId: 'm1',
        description: 'Do something',
        agent: 'explore',
        state: ToolState.completed,
        currentTool: 'shell',
        startedAt: DateTime.now().subtract(const Duration(seconds: 5)),
        endedAt: DateTime.now(),
      );

      final json = assistantContentToPartMaps([task]).first;
      expect(json['type'], 'task');
      expect(
        json['status'],
        'completed',
        reason:
            'schema uses status (not state) — critical to avoid default "running"',
      );
      expect(json['currentTool'], 'shell');
      expect(json['startedAt'], isNotNull);
    });

    test('final message round-trip preserves all part types', () {
      final parts = <AssistantContent>[
        AssistantReasoning(
          id: 'r1',
          sessionId: 'ses_abc',
          messageId: 'm1',
          text: 'thought',
          started: DateTime.now().subtract(const Duration(seconds: 3)),
          ended: DateTime.now(),
        ),
        AssistantText(
          id: 't1',
          sessionId: 'ses_abc',
          messageId: 'm1',
          text: 'answer',
        ),
        AssistantTool(
          id: 'tc1',
          sessionId: 'ses_abc',
          messageId: 'm1',
          callId: 'tc_1',
          tool: 'shell',
          state: ToolState.completed,
          input: {'cmd': 'ls'},
          output: 'file.txt',
        ),
      ];

      final json = assistantContentToPartMaps(parts);
      expect(json.length, 3, reason: '3 parts: reasoning, text, tool');
      expect(json[0]['type'], 'reasoning');
      expect(json[1]['type'], 'text');
      expect(json[2]['type'], 'tool_result');
    });
  });
}
