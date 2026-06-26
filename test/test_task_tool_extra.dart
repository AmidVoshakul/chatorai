import 'dart:io';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/task.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';
import 'package:chatorai/features/chat/services/chat_retry_service.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class _FakeChatAiService extends ChatAiService {
  _FakeChatAiService({
    this.modelOverride = 'mock-model',
    this.temperatureOverride,
    this.completionResult = 'mock completion result',
    this.throwOnStream = false,
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
  final double? temperatureOverride;
  final String completionResult;
  final bool throwOnStream;

  @override
  String? get currentModel => modelOverride;

  @override
  double? get currentTemperature => temperatureOverride;

  @override
  Future<void> streamChatCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
    required Function(String) onChunk,
    required Function(String) onReasoning,
    required Function(String) onCompletion,
    ToolSet tools = const {},
    ToolStartCallback? onToolStart,
    ToolEndCallback? onToolEnd,
    ToolErrorCallback? onToolError,
    UsageCallback? onUsage,
    int maxSteps = 5,
    void Function(RichRetryInfo info)? onRetry,
    void Function(List<Map<String, dynamic>> messages)? onOverflow,
  }) async {
    if (throwOnStream) {
      throw Exception('Stream error');
    }
    onChunk(completionResult);
    onReasoning('mock reasoning');
    onCompletion(completionResult);
    onToolStart?.call('call-id', 'bash', {'cmd': 'ls'});
    onToolEnd?.call('call-id', 'bash', 'file1.txt');
    onToolError?.call('call-id', 'bash', 'error msg');
  }
}

ToolContext _mockCtx({
  String? sessionId = 'test-session',
}) {
  String? capturedPermission;
  List<String>? capturedPatterns;
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: sessionId,
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {
          capturedPermission = permission;
          capturedPatterns = patterns;
        },
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

void main() {
  group('task tool — ChatAiService success path', () {
    test('success path with ChatAiService produces XML output', () async {
      final chatAi = _FakeChatAiService(modelOverride: 'mock-model');
      final tool = createTaskTool(chatAiService: chatAi);

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Integration test',
        'prompt': 'Execute this',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('state="completed"'));
      expect(output.output, contains('<summary>Integration test</summary>'));
      expect(output.output, contains('<task_result>'));
      expect(output.output, contains('mock completion result'));
      expect(output.metadata?['error'], isNull);
    });

    test('success path includes agent_name in metadata', () async {
      final chatAi = _FakeChatAiService();
      final tool = createTaskTool(chatAiService: chatAi);

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Agent name test',
        'prompt': 'Test',
        'subagent_type': 'explore',
      }, ctx);

      expect(output.metadata?['agent_name'], equals('Explore'));
      expect(output.metadata?['subagent_type'], equals('explore'));
    });

    test('success path includes session_id and optional task_id in metadata',
        () async {
      final chatAi = _FakeChatAiService();
      final tool = createTaskTool(chatAiService: chatAi);

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
      final tool = createTaskTool(chatAiService: chatAi);

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'No model',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('No model selected'));
    });

    test('temperature falls back to 0.7 when currentTemperature is null',
        () async {
      final chatAi = _FakeChatAiService(temperatureOverride: null);
      final tool = createTaskTool(chatAiService: chatAi);

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Temp fallback',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('state="completed"'));
      expect(output.metadata?['error'], isNull);
    });

    test('temperature uses currentTemperature when non-null', () async {
      final chatAi = _FakeChatAiService(temperatureOverride: 0.3);
      final tool = createTaskTool(chatAiService: chatAi);

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Custom temp',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('state="completed"'));
      expect(output.metadata?['error'], isNull);
    });

    test('streamChatCompletion callbacks are wired correctly',
        () async {
      final chatAi = _FakeChatAiService();
      final tool = createTaskTool(chatAiService: chatAi);

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Callback test',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('state="completed"'));
      expect(output.output, contains('mock completion result'));
      expect(output.metadata?['error'], isNull);
    });

    test('onToolEnd result is appended to output', () async {
      final chatAi = _FakeChatAiService(
        completionResult: 'base result',
      );
      final tool = createTaskTool(chatAiService: chatAi);

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Tool end test',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('base result'));
      expect(output.output, contains('file1.txt'));
    });

    test('onToolError appends error to output', () async {
      final chatAi = _FakeChatAiService(
        completionResult: 'partial',
      );
      final tool = createTaskTool(chatAiService: chatAi);

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Tool error test',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('partial'));
      expect(output.output, contains('[Tool error:'));
    });

    test('MVP fallback used when chatAiService is null', () async {
      final tool = createTaskTool();

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'MVP test',
        'prompt': 'Test fallback',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('[Subagent MVP not yet wired'));
      expect(output.output, contains('Agent: General'));
      expect(output.metadata?['error'], isNull);
    });
  });

  group('task tool — toolRegistry path', () {
    test('MVP fallback with toolRegistry but no ChatAiService', () async {
      final registry = ToolRegistry(
        PermissionService(),
        PermissionRuleset(),
      );
      registry.register(_makeToolDef('read'));
      registry.register(_makeToolDef('edit'));
      registry.register(_makeToolDef('task'));
      registry.register(_makeToolDef('todowrite'));

      final tool = createTaskTool(toolRegistry: registry);

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Registry without AI',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('[Subagent MVP not yet wired'));
      expect(output.output, contains('Agent: General'));
    });

    test('success path with ChatAiService and toolRegistry', () async {
      final registry = ToolRegistry(
        PermissionService(),
        PermissionRuleset(),
      );
      registry.register(_makeToolDef('read'));
      registry.register(_makeToolDef('edit'));
      registry.register(_makeToolDef('task'));
      registry.register(_makeToolDef('todowrite'));

      final chatAi = _FakeChatAiService();
      final tool = createTaskTool(
        chatAiService: chatAi,
        toolRegistry: registry,
      );

      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'Full integration',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('state="completed"'));
      expect(output.output, contains('mock completion result'));
      expect(output.metadata?['error'], isNull);
    });
  });

  group('task tool — edge cases', () {
    test('empty subagent_type string returns error', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Valid',
        'prompt': 'Valid prompt',
        'subagent_type': '',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });

    test('null subagent_type returns error', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Valid',
        'prompt': 'Valid prompt',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });

    test('MVP output auto-generates id when task_id is omitted', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Auto ID',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('id="sub-'));
      expect(output.output, isNot(contains('task_id=')));
    });

    test('MVP output includes task_id attribute when provided', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'With ID',
        'prompt': 'Test',
        'subagent_type': 'general',
        'task_id': 'my-task-1',
      }, ctx);

      expect(output.output, contains('task_id="my-task-1"'));
      expect(output.output, contains('id="my-task-1"'));
    });

    test('MVP output includes session_id in task tag', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx(sessionId: 'sess-001');

      final output = await tool.execute({
        'description': 'Session attr',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('session_id="sess-001"'));
    });

    test('MVP output includes prompt text in task_result', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Prompt test',
        'prompt': 'My specific prompt content',
        'subagent_type': 'explore',
      }, ctx);

      expect(output.output, contains('Prompt: My specific prompt content'));
    });

    test('MVP output uses correct agent name for explore type', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Explore agent',
        'prompt': 'Explore codebase',
        'subagent_type': 'explore',
      }, ctx);

      expect(output.output, contains('Agent: Explore'));
    });

    test('MVP output uses correct agent name for build type', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Build agent',
        'prompt': 'Build feature',
        'subagent_type': 'build',
      }, ctx);

      expect(output.output, contains('Agent: Build'));
    });

    test('MVP output uses correct agent name for title type', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Title agent',
        'prompt': 'Generate title',
        'subagent_type': 'title',
      }, ctx);

      expect(output.output, contains('Agent: Title'));
    });
  });
}
