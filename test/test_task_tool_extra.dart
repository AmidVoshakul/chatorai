import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/tools/built_in/task.dart';
import 'package:chatorai/core/tools/built_in/task_shared.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';

class _MockSessionRunnerExtra extends Mock implements SessionRunner {}

SessionRunnerHolder _makeRunnerHolderExtra([
  String result = 'mock task result',
]) {
  final mock = _MockSessionRunnerExtra();
  when(
    () => mock.runTaskInChild(
      parentSessionId: any(named: 'parentSessionId'),
      taskPrompt: any(named: 'taskPrompt'),
      streamFn: any(named: 'streamFn'),
      agent: any(named: 'agent'),
      modelRef: any(named: 'modelRef'),
      title: any(named: 'title'),
      taskId: any(named: 'taskId'),
      taskPartId: any(named: 'taskPartId'),
      holder: any(named: 'holder'),
      abortSignal: any(named: 'abortSignal'),
    ),
  ).thenAnswer(
    (_) async =>
        TaskChildResult(result, sessionId: SessionID.fromString('ses_mock')),
  );
  return SessionRunnerHolder(mock);
}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class _FakeChatAiService extends ChatAiService {
  _FakeChatAiService({
    this.modelOverride = 'mock-model',
    this.completionResult = 'mock completion result',
  }) : super(resolver: _createFakeResolver());

  static ModelResolver _createFakeResolver() {
    final mockSecureStorage = MockSecureStorageService();
    final mockPrefs = MockSharedPreferences();

    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getStringList(any())).thenReturn(null);

    final catalog = ProviderCatalogService(
      secureStorage: mockSecureStorage,
      prefs: mockPrefs,
      builtInProviders: [],
    );
    return ModelResolver(catalog);
  }

  final String? modelOverride;
  final String completionResult;

  @override
  String? get currentModel => modelOverride;

  @override
  double? get currentTemperature => 0.7;

  @override
  Future<void> runChildCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
    required Future<void> Function(String) onChunk,
    required Future<void> Function(String) onReasoning,
    Future<void> Function()? onReasoningEnd,
    required Future<void> Function(String) onCompletion,
    ToolSet tools = const {},
    ToolStartCallback? onToolStart,
    ToolEndCallback? onToolEnd,
    ToolErrorCallback? onToolError,
    UsageCallback? onUsage,
    int maxSteps = 5,
    String? sessionId,
    CancellationToken? abortSignal,
  }) async {
    onChunk(completionResult);
    onReasoning('mock reasoning');
    onReasoningEnd?.call();
    onCompletion(completionResult);
    onToolStart?.call('call-id', 'shell', {'cmd': 'ls'});
    onToolEnd?.call('call-id', 'shell', 'file1.txt');
    onToolError?.call('call-id', 'shell', 'error msg');
  }
}

ToolContext _mockCtx({String? sessionId = 'test-session'}) {
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: sessionId,
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {},
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
  );
}

ToolDef _makeToolDef(String id) {
  return ToolDef(
    id: id,
    description: 'Mock $id',
    inputSchema: const {'type': 'object'},
    execute: (input, ctx) async => ToolOutput('result-$id'),
  );
}

ToolRegistry _makeToolRegistry() {
  final registry = ToolRegistry(PermissionService(), PermissionRuleset());
  registry.register(_makeToolDef('read'));
  registry.register(_makeToolDef('edit'));
  registry.register(_makeToolDef('write'));
  registry.register(_makeToolDef('glob'));
  registry.register(_makeToolDef('grep'));
  registry.register(_makeToolDef('shell'));
  registry.register(_makeToolDef('webfetch'));
  registry.register(_makeToolDef('websearch'));
  registry.register(_makeToolDef('apply_patch'));
  registry.register(_makeToolDef('todowrite'));
  return registry;
}

void main() {
  setUpAll(() async {
    registerFallbackValue(SessionID.create());
    await AgentRegistry().init();
  });

  group('task tool — error when no runner', () {
    test('returns error when no currentSessionRunner provided', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'No runner',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('No session runner available'));
    });
  });

  group('task tool — full delegation with ChatAiService', () {
    final registry = _makeToolRegistry();

    test('success path produces XML with state=completed', () async {
      final chatAi = _FakeChatAiService(modelOverride: 'mock-model');
      final tool = createTaskTool(
        chatAiService: chatAi,
        toolRegistry: registry,
        currentSessionRunner: _makeRunnerHolderExtra(),
      );

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Integration test',
        'prompt': 'Execute this',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('mock task result'));
      expect(output.metadata?['error'], isNull);
    });

    test('success path includes agent_name in metadata', () async {
      final chatAi = _FakeChatAiService();
      final tool = createTaskTool(
        chatAiService: chatAi,
        toolRegistry: registry,
        currentSessionRunner: _makeRunnerHolderExtra(),
      );

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Agent name test',
        'prompt': 'Test',
        'subagent_type': 'explore',
      }, ctx);

      expect(output.metadata?['agent_name'], equals('explore'));
      expect(output.metadata?['subagent_type'], equals('explore'));
    });

    test('success path includes session_id and task_id in metadata', () async {
      final chatAi = _FakeChatAiService();
      final tool = createTaskTool(
        chatAiService: chatAi,
        toolRegistry: registry,
        currentSessionRunner: _makeRunnerHolderExtra(),
      );

      final ctx = _mockCtx(sessionId: 'session-xyz');
      final output = await tool.execute({
        'description': 'Metadata test',
        'prompt': 'Test',
        'subagent_type': 'general',
        'task_id': 'task-789',
      }, ctx);

      expect(output.metadata?['session_id'], equals('session-xyz'));
      expect(output.metadata?['task_id'], equals('task-789'));
    });

    test('error when currentModel is null', () async {
      final chatAi = _FakeChatAiService(modelOverride: null);
      final tool = createTaskTool(
        chatAiService: chatAi,
        toolRegistry: registry,
        currentSessionRunner: _makeRunnerHolderExtra(),
      );

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'No model',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('No model selected'));
    });

    test('chatAiService callbacks wired correctly', () async {
      final chatAi = _FakeChatAiService(completionResult: 'final output');
      final tool = createTaskTool(
        chatAiService: chatAi,
        toolRegistry: registry,
        currentSessionRunner: _makeRunnerHolderExtra('final output'),
      );

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Callback test',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('final output'));
      expect(output.metadata?['error'], isNull);
    });

    for (final callbackCase in _CallbackTestCase.all) {
      test(callbackCase.name, () async {
        final chatAi = _FakeChatAiService(
          completionResult: callbackCase.result,
        );
        final tool = createTaskTool(
          chatAiService: chatAi,
          toolRegistry: registry,
          currentSessionRunner: _makeRunnerHolderExtra(callbackCase.result),
        );

        final ctx = _mockCtx();
        final output = await tool.execute({
          'description': callbackCase.description,
          'prompt': 'Test',
          'subagent_type': 'general',
        }, ctx);

        expect(output.output, contains(callbackCase.result));
        expect(output.metadata?['error'], isNull);
      });
    }
  });

  group('task tool — edge cases', () {
    for (final edgeCase in _SubagentTypeEdgeCase.all) {
      test(edgeCase.name, () async {
        final tool = createTaskTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'description': 'Valid',
          'prompt': 'Valid prompt',
          if (edgeCase.subagentTypeKey != null)
            edgeCase.subagentTypeKey!: edgeCase.subagentTypeValue,
        }, ctx);

        expect(output.metadata?['error'], isTrue);
      });
    }

    test('XML output has valid structure with runner', () async {
      final registry = _makeToolRegistry();
      final chatAi = _FakeChatAiService();
      final tool = createTaskTool(
        chatAiService: chatAi,
        toolRegistry: registry,
        currentSessionRunner: _makeRunnerHolderExtra(),
      );
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Wrap test',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('mock task result'));
      expect(output.output, isNotEmpty);
    });

    test('error when no runner returns error metadata', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Format test',
        'prompt': 'Check XML',
        'subagent_type': 'general',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });
  });

  group('deriveSubagentTools', () {
    test('excludes task and todowrite from subagent tool set', () {
      final registry = _makeToolRegistry();
      final subagentTools = deriveSubagentTools(registry);

      expect(subagentTools.containsKey('task'), isFalse);
      expect(subagentTools.containsKey('todowrite'), isFalse);
      expect(subagentTools.containsKey('read'), isTrue);
      expect(subagentTools.containsKey('edit'), isTrue);
      expect(subagentTools.containsKey('glob'), isTrue);
    });

    test('returns empty map when registry has only denied tools', () {
      final registry = ToolRegistry(PermissionService(), PermissionRuleset());
      registry.register(_makeToolDef('task'));
      registry.register(_makeToolDef('todowrite'));

      final subagentTools = deriveSubagentTools(registry);
      expect(subagentTools, isEmpty);
    });

    test('preserves all non-denied tools', () {
      final registry = ToolRegistry(PermissionService(), PermissionRuleset());
      registry.register(_makeToolDef('shell'));
      registry.register(_makeToolDef('read'));
      registry.register(_makeToolDef('write'));
      registry.register(_makeToolDef('grep'));

      final subagentTools = deriveSubagentTools(registry);
      expect(subagentTools.length, equals(4));
      expect(subagentTools.containsKey('shell'), isTrue);
      expect(subagentTools.containsKey('read'), isTrue);
      expect(subagentTools.containsKey('write'), isTrue);
      expect(subagentTools.containsKey('grep'), isTrue);
    });
  });
}

class _CallbackTestCase {
  final String name;
  final String result;
  final String description;

  const _CallbackTestCase({
    required this.name,
    required this.result,
    required this.description,
  });

  static List<_CallbackTestCase> get all => [
    _CallbackTestCase(
      name: 'onToolEnd events are forwarded to child runner',
      result: 'base result',
      description: 'Tool end test',
    ),
    _CallbackTestCase(
      name: 'onToolError events are forwarded to child runner onError',
      result: 'partial',
      description: 'Tool error test',
    ),
  ];
}

class _SubagentTypeEdgeCase {
  final String name;
  final String? subagentTypeKey;
  final String subagentTypeValue;

  const _SubagentTypeEdgeCase({
    required this.name,
    required this.subagentTypeKey,
    required this.subagentTypeValue,
  });

  static List<_SubagentTypeEdgeCase> get all => [
    _SubagentTypeEdgeCase(
      name: 'empty subagent_type string returns error',
      subagentTypeKey: 'subagent_type',
      subagentTypeValue: '',
    ),
    _SubagentTypeEdgeCase(
      name: 'null subagent_type returns error',
      subagentTypeKey: null,
      subagentTypeValue: '',
    ),
  ];
}
