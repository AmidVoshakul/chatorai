import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/services/chat_context_builder.dart';
import 'package:chatorai/features/settings/data/models/model_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatContextBuilder', () {
    late ChatContextBuilder builder;

    setUpAll(() async {
      await AgentRegistry().init();
    });

    setUp(() {
      builder = const ChatContextBuilder();
    });

    group('buildSystemChain', () {
      test('returns only agent prompt for primary agent with systemPrompt', () {
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: 'You are a build agent.',
        );

        final result = builder.buildSystemChain(agent: agent);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'system');
        expect(result[0]['content'], 'You are a build agent.');
      });

      test('returns empty list when primary agent has no systemPrompt', () {
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: null,
        );

        final result = builder.buildSystemChain(agent: agent);

        expect(result, isEmpty);
      });

      test('returns empty list when nothing is provided', () {
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: null,
        );

        final result = builder.buildSystemChain(
          agent: agent,
          userSystemPrompt: null,
          instructionBlocks: const [],
        );

        expect(result, isEmpty);
      });

      test('returns only user prompt when agent has no systemPrompt', () {
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: null,
        );

        final result = builder.buildSystemChain(
          agent: agent,
          userSystemPrompt: 'You are a helpful assistant.',
        );

        expect(result, hasLength(1));
        expect(result[0]['role'], 'system');
        expect(result[0]['content'], 'You are a helpful assistant.');
      });

      test('returns only instruction blocks when no other prompts', () {
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: null,
        );

        final result = builder.buildSystemChain(
          agent: agent,
          instructionBlocks: const ['Rule 1', 'Rule 2'],
        );

        expect(result, hasLength(1));
        expect(result[0]['role'], 'system');
        expect(result[0]['content'], 'Rule 1\n\n---\n\nRule 2');
      });

      test('combines agent prompt, user prompt, and instruction blocks', () {
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: 'Agent prompt.',
        );

        final result = builder.buildSystemChain(
          agent: agent,
          userSystemPrompt: 'User prompt.',
          instructionBlocks: const ['Instruction 1', 'Instruction 2'],
        );

        expect(result, hasLength(1));
        expect(result[0]['role'], 'system');
        expect(
          result[0]['content'],
          'Agent prompt.\n\n---\n\nUser prompt.\n\n---\n\nInstruction 1\n\n---\n\nInstruction 2',
        );
      });

      test('uses delegate agent prompt when delegateAgentId is provided', () {
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: 'Primary prompt.',
        );

        final result = builder.buildSystemChain(
          agent: agent,
          delegateAgentId: 'plan',
        );

        expect(result, hasLength(1));
        expect(result[0]['role'], 'system');
        // plan is a built-in primary agent with a long system prompt
        expect(result[0]['content'], isNotEmpty);
        expect(result[0]['content'], contains('You are ChatORAI in PLAN mode'));
      });

      test(
        'returns empty when delegate agent is subagent (no primary prompt)',
        () {
          final agent = AgentDefinition(
            id: 'build',
            name: 'build',
            mode: AgentMode.primary,
            systemPrompt: 'Primary prompt.',
          );

          final result = builder.buildSystemChain(
            agent: agent,
            delegateAgentId: 'explore',
          );

          // explore is a subagent, so its prompt is not used for the system chain
          expect(result, isEmpty);
        },
      );

      test(
        'combines delegate agent prompt with user prompt when delegateAgentId is set',
        () {
          final agent = AgentDefinition(
            id: 'build',
            name: 'build',
            mode: AgentMode.primary,
            systemPrompt: 'Primary prompt.',
          );

          final result = builder.buildSystemChain(
            agent: agent,
            delegateAgentId: 'plan',
            userSystemPrompt: 'User prompt.',
          );

          expect(result, hasLength(1));
          // plan agent has a long system prompt
          expect(result[0]['content'], isNotEmpty);
          expect(
            result[0]['content'],
            contains('You are ChatORAI in PLAN mode'),
          );
          expect(result[0]['content'], contains('User prompt.'));
        },
      );
    });

    group('findSummaryMessage', () {
      test('returns the compaction summary message when present', () {
        final summary = Message(
          id: 'msg-summary',
          role: MessageRole.system,
          content: 'Summary of conversation.',
          timestamp: DateTime.now(),
          isCompactionSummary: true,
        );
        final regular = Message(
          id: 'msg-1',
          role: MessageRole.user,
          content: 'Hello',
          timestamp: DateTime.now(),
        );
        final messages = [regular, summary];

        final result = builder.findSummaryMessage(messages);

        expect(result, equals(summary));
      });

      test('returns null when no compaction summary is present', () {
        final messages = [
          Message(
            id: 'msg-1',
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
          ),
          Message(
            id: 'msg-2',
            role: MessageRole.assistant,
            content: 'Hi there',
            timestamp: DateTime.now(),
          ),
        ];

        final result = builder.findSummaryMessage(messages);

        expect(result, isNull);
      });

      test('returns the last compaction summary when multiple are present', () {
        final oldSummary = Message(
          id: 'msg-old',
          role: MessageRole.system,
          content: 'Old summary.',
          timestamp: DateTime.now(),
          isCompactionSummary: true,
        );
        final newSummary = Message(
          id: 'msg-new',
          role: MessageRole.system,
          content: 'New summary.',
          timestamp: DateTime.now(),
          isCompactionSummary: true,
        );
        final messages = [oldSummary, newSummary];

        final result = builder.findSummaryMessage(messages);

        expect(result, equals(newSummary));
      });
    });

    group('compactedApiMessagesWithSummary', () {
      test('returns empty list when compactedContext is null', () {
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          compactedContext: null,
        );

        final result = builder.compactedApiMessagesWithSummary(chat, chat);

        expect(result, isEmpty);
      });

      test('returns empty list when compactedContext is empty', () {
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          compactedContext: const [],
        );

        final result = builder.compactedApiMessagesWithSummary(chat, chat);

        expect(result, isEmpty);
      });

      test('returns [summary, ...tail] when summary is present', () {
        final summary = Message(
          id: 'msg-summary',
          role: MessageRole.system,
          content: 'Summary text.',
          timestamp: DateTime.now(),
          isCompactionSummary: true,
          agent: 'compaction',
        );
        final tailMessage = Message(
          id: 'msg-1',
          role: MessageRole.user,
          content: 'Hello',
          timestamp: DateTime.now(),
        );
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: [summary, tailMessage],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          compactedContext: [tailMessage],
        );

        final result = builder.compactedApiMessagesWithSummary(chat, chat);

        expect(result, hasLength(2));
        expect(result[0]['role'], 'system');
        expect(result[0]['content'], 'Summary text.');
        expect(result[0]['isCompactionSummary'], true);
        expect(result[0]['agent'], 'compaction');
        expect(result[1]['role'], 'user');
        expect(result[1]['content'], 'Hello');
      });

      test('returns [...tail] when no summary is present', () {
        final tailMessage = Message(
          id: 'msg-1',
          role: MessageRole.user,
          content: 'Hello',
          timestamp: DateTime.now(),
        );
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          compactedContext: [tailMessage],
        );

        final result = builder.compactedApiMessagesWithSummary(chat, chat);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'user');
        expect(result[0]['content'], 'Hello');
      });
    });

    group('buildApiMessages', () {
      test('truncates to last 20 messages', () {
        final messages = List.generate(
          25,
          (i) => Message(
            id: 'msg-$i',
            role: i % 2 == 0 ? MessageRole.user : MessageRole.assistant,
            content: 'Message $i',
            timestamp: DateTime.now(),
          ),
        );
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: messages,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: 'Agent prompt.',
        );

        final result = builder.buildApiMessages(chat, currentAgent: agent);

        // 20 messages + 1 system message = 21
        expect(result, hasLength(21));
        expect(result[0]['role'], 'system');
        expect(result.last['content'], 'Message 24');
      });

      test('injects attached doc path into content', () {
        final message = Message(
          id: 'msg-1',
          role: MessageRole.user,
          content: 'Read this file.',
          timestamp: DateTime.now(),
          attachedDocPath: '/path/to/my "special".pdf',
        );
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: [message],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: 'Agent prompt.',
        );

        final result = builder.buildApiMessages(chat, currentAgent: agent);

        expect(result, hasLength(2));
        expect(result[1]['content'], contains('[Attached file:'));
        expect(result[1]['content'], contains('Use the document_extract tool'));
      });

      test('produces content list for image messages', () {
        final message = Message(
          id: 'msg-1',
          role: MessageRole.user,
          content: 'What is this?',
          timestamp: DateTime.now(),
          imageData: 'base64data',
          imageType: 'image/jpeg',
        );
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: [message],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: 'Agent prompt.',
        );

        final result = builder.buildApiMessages(chat, currentAgent: agent);

        expect(result, hasLength(2));
        final content = result[1]['content'] as List;
        expect(content, hasLength(2));
        expect(content[0]['type'], 'text');
        expect(content[0]['text'], 'What is this?');
        expect(content[1]['type'], 'image_url');
        expect(
          content[1]['image_url']['url'],
          'data:image/jpeg;base64,base64data',
        );
      });

      test(
        'injects delegate agent prompt when delegateAgentId is provided',
        () {
          final message = Message(
            id: 'msg-1',
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
          );
          final chat = Chat(
            id: 'chat-1',
            title: 'Test',
            messages: [message],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          final agent = AgentDefinition(
            id: 'build',
            name: 'build',
            mode: AgentMode.primary,
            systemPrompt: 'Primary prompt.',
          );

          final result = builder.buildApiMessages(
            chat,
            currentAgent: agent,
            delegateAgentId: 'plan',
          );

          expect(result, hasLength(2));
          // plan is a built-in primary agent with a long system prompt
          expect(result[0]['content'], isNotEmpty);
          expect(
            result[0]['content'],
            contains('You are ChatORAI in PLAN mode'),
          );
        },
      );

      test(
        'injects subagent delegation instruction when agentMention is provided',
        () {
          final message = Message(
            id: 'msg-1',
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
          );
          final chat = Chat(
            id: 'chat-1',
            title: 'Test',
            messages: [message],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          final agent = AgentDefinition(
            id: 'build',
            name: 'build',
            mode: AgentMode.primary,
            systemPrompt: 'Primary prompt.',
          );

          final result = builder.buildApiMessages(
            chat,
            currentAgent: agent,
            agentMention: 'explore',
          );

          expect(result, hasLength(3));
          expect(result[0]['role'], 'system');
          expect(result[0]['content'], 'Primary prompt.');
          expect(result[1]['role'], 'system');
          expect(
            result[1]['content'],
            'Delegate to subagent explore. Use the task tool with subagent_type: "explore" to process this request.',
          );
          expect(result[2]['role'], 'user');
        },
      );

      test('system chain appears at index 0', () {
        final message = Message(
          id: 'msg-1',
          role: MessageRole.user,
          content: 'Hello',
          timestamp: DateTime.now(),
        );
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: [message],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: 'Agent prompt.',
        );

        final result = builder.buildApiMessages(chat, currentAgent: agent);

        expect(result.first['role'], 'system');
      });

      test('skips error messages', () {
        final message = Message(
          id: 'msg-1',
          role: MessageRole.assistant,
          content: 'Error occurred',
          timestamp: DateTime.now(),
          isError: true,
        );
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: [message],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final agent = AgentDefinition(
          id: 'build',
          name: 'build',
          mode: AgentMode.primary,
          systemPrompt: 'Agent prompt.',
        );

        final result = builder.buildApiMessages(chat, currentAgent: agent);

        expect(result, hasLength(1));
        expect(result[0]['role'], 'system');
      });

      test(
        're-injects compaction summary when compactedContext is present',
        () {
          final summary = Message(
            id: 'msg-summary',
            role: MessageRole.system,
            content: 'Summary text.',
            timestamp: DateTime.now(),
            isCompactionSummary: true,
          );
          final tailMessage = Message(
            id: 'msg-1',
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
          );
          final chat = Chat(
            id: 'chat-1',
            title: 'Test',
            messages: [summary, tailMessage],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            compactedContext: [tailMessage],
          );
          final agent = AgentDefinition(
            id: 'build',
            name: 'build',
            mode: AgentMode.primary,
            systemPrompt: 'Agent prompt.',
          );

          final result = builder.buildApiMessages(chat, currentAgent: agent);

          // system + summary + tail = 3
          expect(result, hasLength(3));
          expect(result[0]['role'], 'system');
          expect(result[1]['role'], 'system');
          expect(result[1]['isCompactionSummary'], true);
          expect(result[1]['content'], 'Summary text.');
          expect(result[2]['role'], 'user');
        },
      );
    });
  });
}
