import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/agents/agent_provider.dart'
    show CurrentAgentNotifier;
import 'package:chatorai/core/config/config_provider.dart'
    show resolvedInstructionsProvider;
import 'package:chatorai/core/config/models/chatorai_config.dart'
    show CompactionConfig;
import 'package:chatorai/core/context/token_counter.dart';
import 'package:chatorai/core/llm/catalog_providers.dart'
    show catalogServiceProvider, PreferencesHolder;
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/core/llm/providers/built_in_providers.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_state.dart' as session_state;
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/providers/session_context_usage_provider.dart';
import 'package:chatorai/features/models/providers/model_provider.dart';
import 'package:chatorai/features/settings/data/models/model_settings.dart';
import 'package:chatorai/features/settings/providers/model_settings_provider.dart';
import 'package:chatorai/features/sessions/providers/session_parts_provider.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'dart:async';

import 'package:chatorai/providers.dart'
    show
        currentChatProvider,
        compactionConfigProvider,
        currentAgentProvider,
        modelSettingsProvider,
        modelProvider,
        sessionPartsProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockModelConfig extends Mock implements ModelConfig {}

class _TestModelNotifier extends ModelNotifier {
  final ModelState _state;
  _TestModelNotifier(this._state);

  @override
  ModelState build() => _state;
}

class _TestCurrentAgentNotifier extends CurrentAgentNotifier {
  final AgentDefinition _agent;
  _TestCurrentAgentNotifier(this._agent);

  @override
  AgentDefinition build() => _agent;
}

class _TestModelSettingsNotifier extends ModelSettingsNotifier {
  final ModelSettingsState _state;
  _TestModelSettingsNotifier(this._state);

  @override
  ModelSettingsState build() => _state;
}

class _FakeSessionPartsNotifier extends SessionPartsNotifier {
  final session_state.SessionState _state;
  _FakeSessionPartsNotifier(this._state) : super('fake-session-id');

  @override
  Stream<session_state.SessionState> build() async* {
    yield _state;
  }
}

void main() {
  group('SessionContextUsageProvider', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      container.dispose();
    });

    test('returns zero usage for empty chat', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(200000);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 20000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: 'You are a build agent.',
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.usedTokens, 0);
      expect(usage.contextLength, 200000);
      expect(usage.buffer, 20000);
      expect(usage.usable, 180000);
    });

    test('calculates used tokens from last assistant message only', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 10,
            tokensOutput: 0,
            tokensReasoning: 0,
          ),
          Message(
            id: 'm2',
            role: MessageRole.assistant,
            content: 'Hi there',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 5,
            tokensOutput: 15,
            tokensReasoning: 3,
          ),
          Message(
            id: 'm3',
            role: MessageRole.user,
            content: 'How are you?',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 8,
            tokensOutput: 0,
            tokensReasoning: 0,
          ),
          Message(
            id: 'm4',
            role: MessageRole.assistant,
            content: 'I am fine',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 4,
            tokensOutput: 10,
            tokensReasoning: 2,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: 'You are a build agent.',
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.usedTokens, 4);
      expect(usage.outputTokens, 10);
      expect(usage.reasoningTokens, 2);
      expect(usage.contextLength, 100000);
      expect(usage.buffer, 10000);
      expect(usage.usable, 90000);
    });

    test('falls back to 200000 when contextLength is null', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () =>
                _TestModelNotifier(const ModelState(selectedModelObject: null)),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 20000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: 'You are a build agent.',
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.contextLength, 200000);
      expect(usage.usable, 180000);
    });

    test(
      'falls back to min(20000, contextLength ~/ 10) when buffer is zero',
      () {
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final modelConfig = MockModelConfig();
        when(() => modelConfig.contextLength).thenReturn(50000);

        container = ProviderContainer(
          overrides: [
            currentChatProvider.overrideWithValue(chat),
            modelProvider.overrideWith(
              () => _TestModelNotifier(
                ModelState(selectedModelObject: modelConfig),
              ),
            ),
            compactionConfigProvider.overrideWithValue(
              const CompactionConfig(buffer: 0),
            ),
            resolvedInstructionsProvider.overrideWith(
              (ref) => Future.value(const <String>[]),
            ),
            currentAgentProvider.overrideWith(
              () => _TestCurrentAgentNotifier(
                AgentDefinition(
                  id: 'build',
                  name: 'Build',
                  mode: AgentMode.primary,
                  systemPrompt: 'You are a build agent.',
                ),
              ),
            ),
            modelSettingsProvider.overrideWith(
              () => _TestModelSettingsNotifier(
                const ModelSettingsState(
                  activeSettings: ModelSettings(modelId: 'test'),
                ),
              ),
            ),
          ],
        );

        final usage = container.read(sessionContextUsageProvider);
        expect(usage.buffer, 5000);
        expect(usage.usable, 45000);
      },
    );

    test('includes agent system prompt when mode is primary', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(200000);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 20000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: 'You are a build agent.',
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.sources.length, 1);
      expect(usage.sources.first.name, 'Build');
      expect(usage.sources.first.estimatedTokens, greaterThan(0));
    });

    test('excludes agent system prompt when mode is not primary', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(200000);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 20000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'sub',
                name: 'Sub',
                mode: AgentMode.subagent,
                systemPrompt: 'You are a subagent.',
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.sources.length, 0);
    });

    test('includes user system prompt when present', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(200000);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 20000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              ModelSettingsState(
                activeSettings: const ModelSettings(
                  modelId: 'test',
                  systemPrompt: 'You are a helpful assistant.',
                ),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.sources.length, 1);
      expect(usage.sources.first.name, 'User system prompt');
      expect(usage.sources.first.estimatedTokens, greaterThan(0));
    });

    test('includes instruction blocks from resolvedInstructionsProvider', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(200000);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 20000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => [
              'Instructions from: AGENTS.md\n# Project rules\n- Be concise',
              'Instructions from: /path/to/file.md\nSome instructions here',
            ],
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.sources.length, 2);
      expect(usage.sources[0].name, 'AGENTS.md');
      expect(usage.sources[1].name, 'file.md');
    });

    test('returns zero usage when currentChatProvider is null', () {
      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(null),
          modelProvider.overrideWith(
            () =>
                _TestModelNotifier(const ModelState(selectedModelObject: null)),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 20000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.usedTokens, 0);
      expect(usage.contextLength, 200000);
      expect(usage.usable, 180000);
    });

    test('returns zero usedTokens when no assistant messages', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 10,
            tokensOutput: 0,
            tokensReasoning: 0,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.usedTokens, 0);
      expect(usage.outputTokens, 0);
      expect(usage.reasoningTokens, 0);
    });

    test('reads cache tokens from last assistant message', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: 'Hi',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 5,
            tokensOutput: 10,
            tokensReasoning: 2,
            tokensCacheRead: 600,
            tokensCacheWrite: 120,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.usedTokens, 5);
      expect(usage.outputTokens, 10);
      expect(usage.reasoningTokens, 2);
      expect(usage.cacheReadTokens, 600);
      expect(usage.cacheWriteTokens, 120);
      expect(usage.totalTokens, 5 + 10 + 2 + 600 + 120);
    });

    test('counts toolTokens from current message tool parts', () async {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: 'Hi',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 5,
            tokensOutput: 10,
            tokensReasoning: 2,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);

      final sessionState = session_state.SessionState(
        id: SessionID.fromString('ses_chat-1'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parts: [
          AssistantTool(
            id: 'at1',
            sessionId: 'ses_chat-1',
            messageId: 'm1',
            callId: 'tc1',
            tool: 'test_tool',
            state: ToolState.completed,
            input: const {'key': 'value'},
            output: 'result',
            durationMs: 100,
          ),
          AssistantTool(
            id: 'at2',
            sessionId: 'ses_chat-1',
            messageId: 'm_other',
            callId: 'tc2',
            tool: 'other_tool',
            state: ToolState.completed,
            input: const {},
            output: 'other',
            durationMs: 50,
          ),
        ],
      );

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
          sessionPartsProvider.overrideWith(
            () => _FakeSessionPartsNotifier(sessionState),
          ),
        ],
      );

      final completer = Completer<void>();
      final sub = container.listen<AsyncValue<session_state.SessionState>>(
        sessionPartsProvider(chat.id),
        (_, next) {
          if (next.hasValue && !completer.isCompleted) completer.complete();
        },
      );
      await completer.future;
      sub.close();

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.toolTokens, greaterThan(0));
      expect(usage.toolCallsCount, 1);
    });

    test('toolCallsCount is zero when no AssistantTool parts', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: 'Hi',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 5,
            tokensOutput: 10,
            tokensReasoning: 2,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.toolCallsCount, 0);
      expect(usage.toolTokens, 0);
    });

    test('totalTokens sums used, output, reasoning, cacheRead, cacheWrite', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: 'Hi',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 5,
            tokensOutput: 10,
            tokensReasoning: 2,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.totalTokens, 5 + 10 + 2);
    });

    test('spentUsd is calculated from model pricing', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: 'Hi',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 1000,
            tokensOutput: 500,
            tokensReasoning: 200,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);
      when(() => modelConfig.pricing).thenReturn(
        const ModelPricing(inputCostPer1k: 1.0, outputCostPer1k: 2.0),
      );

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.spentUsd, isNotNull);
      expect(usage.spentUsd, closeTo(2.4, 0.001));
    });

    test('spentUsd is null when model pricing is unavailable', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: 'Hi',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 1000,
            tokensOutput: 500,
            tokensReasoning: 200,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);
      when(() => modelConfig.pricing).thenReturn(null);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.spentUsd, isNull);
    });

    test(
      'spentUsd uses message model pricing when message.model set',
      () async {
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: [
            Message(
              id: 'm1',
              role: MessageRole.assistant,
              content: 'Hi',
              timestamp: DateTime.now(),
              isComplete: true,
              model: 'openrouter/override-model',
              tokensInput: 1000,
              tokensOutput: 500,
              tokensReasoning: 200,
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final selectedModelConfig = MockModelConfig();
        when(() => selectedModelConfig.contextLength).thenReturn(100000);
        when(() => selectedModelConfig.pricing).thenReturn(
          const ModelPricing(inputCostPer1k: 1.0, outputCostPer1k: 2.0),
        );

        final overrideModelConfig = ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'override-model',
          displayName: 'Override Model',
          contextLength: 200000,
          pricing: const ModelPricing(
            inputCostPer1k: 0.5,
            outputCostPer1k: 1.0,
          ),
        );

        SharedPreferences.setMockInitialValues({
          'catalog_provider_enabled_openrouter': true,
        });
        final prefs = await SharedPreferences.getInstance();
        PreferencesHolder.prefs = prefs;
        final catalogInstance = ProviderCatalogService(
          secureStorage: SecureStorageService(),
          prefs: prefs,
          builtInProviders: builtInProviders(),
        );
        await catalogInstance.updateProviderModels('openrouter', [
          overrideModelConfig,
        ]);

        container = ProviderContainer(
          overrides: [
            currentChatProvider.overrideWithValue(chat),
            modelProvider.overrideWith(
              () => _TestModelNotifier(
                ModelState(selectedModelObject: selectedModelConfig),
              ),
            ),
            compactionConfigProvider.overrideWithValue(
              const CompactionConfig(buffer: 10000),
            ),
            resolvedInstructionsProvider.overrideWith(
              (ref) => Future.value(const <String>[]),
            ),
            currentAgentProvider.overrideWith(
              () => _TestCurrentAgentNotifier(
                AgentDefinition(
                  id: 'build',
                  name: 'Build',
                  mode: AgentMode.primary,
                  systemPrompt: null,
                ),
              ),
            ),
            modelSettingsProvider.overrideWith(
              () => _TestModelSettingsNotifier(
                const ModelSettingsState(
                  activeSettings: ModelSettings(modelId: 'test'),
                ),
              ),
            ),
            catalogServiceProvider.overrideWithValue(catalogInstance),
          ],
        );

        final usage = container.read(sessionContextUsageProvider);
        expect(usage.spentUsd, isNotNull);
        expect(usage.spentUsd, closeTo(1.2, 0.001));
      },
    );

    test('spentUsd treats catalog models without pricing as free', () async {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: 'Free response',
            timestamp: DateTime.now(),
            isComplete: true,
            model: 'openrouter/free-model',
            tokensInput: 1000,
            tokensOutput: 500,
            tokensReasoning: 200,
          ),
          Message(
            id: 'm2',
            role: MessageRole.assistant,
            content: 'Paid response',
            timestamp: DateTime.now(),
            isComplete: true,
            model: 'openrouter/paid-model',
            tokensInput: 1000,
            tokensOutput: 500,
            tokensReasoning: 200,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final selectedModelConfig = MockModelConfig();
      when(() => selectedModelConfig.contextLength).thenReturn(100000);
      when(() => selectedModelConfig.pricing).thenReturn(
        const ModelPricing(inputCostPer1k: 1.0, outputCostPer1k: 2.0),
      );

      final freeModelConfig = ModelConfig.basic(
        providerId: 'openrouter',
        modelName: 'free-model',
        displayName: 'Free Model',
        contextLength: 200000,
      );
      final paidModelConfig = ModelConfig.basic(
        providerId: 'openrouter',
        modelName: 'paid-model',
        displayName: 'Paid Model',
        contextLength: 200000,
        pricing: const ModelPricing(inputCostPer1k: 0.5, outputCostPer1k: 1.0),
      );

      SharedPreferences.setMockInitialValues({
        'catalog_provider_enabled_openrouter': true,
      });
      final prefs = await SharedPreferences.getInstance();
      PreferencesHolder.prefs = prefs;
      final catalogInstance = ProviderCatalogService(
        secureStorage: SecureStorageService(),
        prefs: prefs,
        builtInProviders: builtInProviders(),
      );
      await catalogInstance.updateProviderModels('openrouter', [
        freeModelConfig,
        paidModelConfig,
      ]);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: selectedModelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
          catalogServiceProvider.overrideWithValue(catalogInstance),
        ],
      );

      // m1 (free model, no pricing in catalog): contributes 0
      // m2 (paid model 0.5/1.0): (1000*0.5 + (500+200)*1.0)/1000 = 1.2
      final usage = container.read(sessionContextUsageProvider);
      expect(usage.spentUsd, isNotNull);
      expect(usage.spentUsd, closeTo(1.2, 0.001));
    });

    test('spentUsd does not double-count cache when cacheIncludedInInput', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: 'Hi',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 1000,
            tokensOutput: 500,
            tokensReasoning: 200,
            tokensCacheRead: 300,
            tokensCacheWrite: 100,
            tokensCacheIncludedInInput: true,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);
      when(() => modelConfig.pricing).thenReturn(
        const ModelPricing(inputCostPer1k: 1.0, outputCostPer1k: 2.0),
      );

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.spentUsd, isNotNull);
      expect(usage.spentUsd, closeTo(2.4, 0.001));
    });

    test('spentUsd sums cost across multiple assistant messages', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
            isComplete: true,
          ),
          Message(
            id: 'm2',
            role: MessageRole.assistant,
            content: 'First response',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 1000,
            tokensOutput: 500,
            tokensReasoning: 200,
          ),
          Message(
            id: 'm3',
            role: MessageRole.user,
            content: 'Follow up',
            timestamp: DateTime.now(),
            isComplete: true,
          ),
          Message(
            id: 'm4',
            role: MessageRole.assistant,
            content: 'Second response',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 800,
            tokensOutput: 400,
            tokensReasoning: 100,
          ),
          Message(
            id: 'm5',
            role: MessageRole.assistant,
            content: 'Third response (free/old)',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: null,
            tokensOutput: 50,
            tokensReasoning: 10,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);
      when(() => modelConfig.pricing).thenReturn(
        const ModelPricing(inputCostPer1k: 1.0, outputCostPer1k: 2.0),
      );

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      // m2: (1000 * 1.0 + (500 + 200) * 2.0) / 1000 = (1000 + 1400) / 1000 = 2.4
      // m4: (800 * 1.0 + (400 + 100) * 2.0) / 1000 = (800 + 1000) / 1000 = 1.8
      // m5: tokensInput is null → contributes 0
      // total = 2.4 + 1.8 = 4.2
      final usage = container.read(sessionContextUsageProvider);
      expect(usage.spentUsd, isNotNull);
      expect(usage.spentUsd, closeTo(4.2, 0.001));
    });

    test('spentUsd returns null when no message has recorded tokens', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: 'Hi',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: null,
            tokensOutput: 50,
            tokensReasoning: 10,
          ),
          Message(
            id: 'm2',
            role: MessageRole.assistant,
            content: 'Bye',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: null,
            tokensOutput: 30,
            tokensReasoning: 5,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);
      when(() => modelConfig.pricing).thenReturn(
        const ModelPricing(inputCostPer1k: 1.0, outputCostPer1k: 2.0),
      );

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.spentUsd, isNull);
    });

    test('contextLength falls back to message contextLength', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: 'Hi',
            timestamp: DateTime.now(),
            isComplete: true,
            contextLength: 50000,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
        ],
      );

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.contextLength, 50000);
    });

    test('toolCallsCount counts only current message tool parts', () async {
      final chat = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: 'Hi',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 5,
            tokensOutput: 10,
            tokensReasoning: 2,
          ),
          Message(
            id: 'm2',
            role: MessageRole.assistant,
            content: 'Bye',
            timestamp: DateTime.now(),
            isComplete: true,
            tokensInput: 3,
            tokensOutput: 7,
            tokensReasoning: 1,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modelConfig = MockModelConfig();
      when(() => modelConfig.contextLength).thenReturn(100000);

      final sessionState = session_state.SessionState(
        id: SessionID.fromString('ses_chat-1'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parts: [
          AssistantTool(
            id: 'at1',
            sessionId: 'ses_chat-1',
            messageId: 'm1',
            callId: 'tc1',
            tool: 'tool_a',
            state: ToolState.completed,
            input: const {'tool': 'a'},
            output: 'Result of tool a execution',
            durationMs: 100,
          ),
          AssistantTool(
            id: 'at2',
            sessionId: 'ses_chat-1',
            messageId: 'm2',
            callId: 'tc2',
            tool: 'tool_b',
            state: ToolState.completed,
            input: const {'tool': 'b'},
            output: 'Result of tool b execution',
            durationMs: 100,
          ),
          AssistantTool(
            id: 'at3',
            sessionId: 'ses_chat-1',
            messageId: 'm2',
            callId: 'tc3',
            tool: 'tool_c',
            state: ToolState.completed,
            input: const {'tool': 'c'},
            output: 'Result of tool c execution',
            durationMs: 100,
          ),
        ],
      );

      container = ProviderContainer(
        overrides: [
          currentChatProvider.overrideWithValue(chat),
          modelProvider.overrideWith(
            () => _TestModelNotifier(
              ModelState(selectedModelObject: modelConfig),
            ),
          ),
          compactionConfigProvider.overrideWithValue(
            const CompactionConfig(buffer: 10000),
          ),
          resolvedInstructionsProvider.overrideWith(
            (ref) => Future.value(const <String>[]),
          ),
          currentAgentProvider.overrideWith(
            () => _TestCurrentAgentNotifier(
              AgentDefinition(
                id: 'build',
                name: 'Build',
                mode: AgentMode.primary,
                systemPrompt: null,
              ),
            ),
          ),
          modelSettingsProvider.overrideWith(
            () => _TestModelSettingsNotifier(
              const ModelSettingsState(
                activeSettings: ModelSettings(modelId: 'test'),
              ),
            ),
          ),
          sessionPartsProvider.overrideWith(
            () => _FakeSessionPartsNotifier(sessionState),
          ),
        ],
      );

      final completer = Completer<void>();
      final sub = container.listen<AsyncValue<session_state.SessionState>>(
        sessionPartsProvider(chat.id),
        (_, next) {
          if (next.hasValue && !completer.isCompleted) completer.complete();
        },
      );
      await completer.future;
      sub.close();

      final sessionParts = container.read(sessionPartsProvider(chat.id));
      expect(sessionParts.value, isNotNull);
      expect(sessionParts.value?.parts.length, 3);

      final usage = container.read(sessionContextUsageProvider);
      expect(usage.toolCallsCount, 2);
      expect(usage.toolTokens, greaterThan(0));
    });
  });
}
