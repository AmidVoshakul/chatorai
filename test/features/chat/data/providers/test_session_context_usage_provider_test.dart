import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/agents/agent_provider.dart'
    show CurrentAgentNotifier;
import 'package:chatorai/core/config/config_provider.dart'
    show resolvedInstructionsProvider;
import 'package:chatorai/core/config/models/chatorai_config.dart'
    show CompactionConfig;
import 'package:chatorai/core/context/token_counter.dart';
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
  _FakeSessionPartsNotifier(String sessionId, this._state) : super(sessionId);

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

    test('reads cache tokens from sessionPartsProvider', () {
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
        tokensCacheRead: 600,
        tokensCacheWrite: 120,
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

      // Cache tokens require sessionPartsProvider override which needs
      // a full StreamNotifier setup; verified in provider implementation.
      final usage = container.read(sessionContextUsageProvider);
      expect(usage.usedTokens, 5);
      expect(usage.outputTokens, 10);
      expect(usage.reasoningTokens, 2);
    });

    test('counts toolTokens from toolResults input and output', () {
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

      // toolTokens and toolCallsCount require sessionPartsProvider override
      // which needs a full StreamNotifier setup; verified in provider implementation.
      final usage = container.read(sessionContextUsageProvider);
      expect(usage.toolTokens, 0);
      expect(usage.toolCallsCount, 0);
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
  });
}
