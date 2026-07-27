/// Tests for tool error recovery in child/subagent sessions.
///
/// TDD: These tests define the EXPECTED behavior for:
///   1. `runChildCompletion` handling `StreamTextErrorEvent` (AiNoSuchToolError)
///   2. `task.dart` onToolError calling `child.onToolError` (not `child.onError`)
///   3. `task_container.dart` onToolError calling `child.onToolError` (not `child.onError`)
///
/// BUG: Currently both (2) and (3) call `child.onError()` which finalizes the
/// child session. After fix, they should call `child.onToolError()` which marks
/// the tool as failed WITHOUT killing the session.
import 'dart:io';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/core/tools/built_in/task.dart';
import 'package:chatorai/core/tools/built_in/task_shared.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';

// ─── Mocks ──────────────────────────────────────────────────────────────

class _MockSecureStorageService extends Mock implements SecureStorageService {}

class _MockSharedPreferences extends Mock implements SharedPreferences {}

// ─── Fake ChatAiService that calls onToolError during runChildCompletion ─

/// A fake that simulates a tool execution error inside the child session.
///
/// The key behavior: calls [onToolError] (triggering the bug path) and then
/// continues with [onCompletion] (agent recovers and produces output).
class _FakeChatAiServiceToolError extends ChatAiService {
  _FakeChatAiServiceToolError({
    bool simulateToolError = true,
    String toolErrorMessage = 'Step 1 called unknown tool "hallucinated_tool"',
  }) : _simulateToolError = simulateToolError,
       _toolErrorMessage = toolErrorMessage,
       super(resolver: _createFakeResolver()) {
    currentModelForTesting = 'openrouter/free';
    currentTemperatureForTesting = 0.7;
  }

  static ModelResolver _createFakeResolver() {
    final mockSecureStorage = _MockSecureStorageService();
    final mockPrefs = _MockSharedPreferences();

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

  /// Whether [runChildCompletion] should simulate a tool error.
  final bool _simulateToolError;

  /// The error message to pass to [onToolError].
  final String _toolErrorMessage;

  @override
  Future<void> runChildCompletion({
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
    String? sessionId,
    CancellationToken? abortSignal,
  }) async {
    if (_simulateToolError) {
      // Simulate: agent tries a tool, gets error, then recovers.
      final fakeCallId = 'call_hallucinated_123';
      final fakeToolName = 'hallucinated_tool';

      // 1) Agent attempts tool → onToolStart fires
      await onToolStart?.call(fakeCallId, fakeToolName, {'input': 'test'});

      // 2) Tool error occurs → onToolError fires
      //    BUG: task.dart currently calls child.onError() here (kills session)
      //    FIX: should call child.onToolError() (keeps session alive)
      await onToolError?.call(fakeCallId, fakeToolName, _toolErrorMessage);

      // 3) Agent recovers → produces output
      await onChunk('Recovered after tool error');
      onUsage?.call(10, 20, 5, 3);
      await onCompletion('Recovered after tool error');
    } else {
      await onChunk('Normal output');
      onUsage?.call(10, 20, 5, 3);
      await onCompletion('Normal output');
    }
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────

SharedPreferences _createMockPrefs() {
  final mock = _MockSharedPreferences();
  when(() => mock.setString(any(), any())).thenAnswer((_) async => true);
  when(() => mock.setBool(any(), any())).thenAnswer((_) async => true);
  when(() => mock.setInt(any(), any())).thenAnswer((_) async => true);
  when(() => mock.getString(any())).thenReturn(null);
  when(() => mock.getBool(any())).thenReturn(null);
  when(() => mock.getInt(any())).thenReturn(null);
  when(() => mock.getStringList(any())).thenReturn(null);
  return mock;
}

class _TestHarness {
  final AppDatabase db;
  final String dbPath;
  final SessionRepository repository;
  final SessionRunner runner;
  final SessionRunnerHolder runnerHolder;
  final ToolRegistry toolRegistry;
  final ChatAiService chatAiService;

  _TestHarness({
    required this.db,
    required this.dbPath,
    required this.repository,
    required this.runner,
    required this.runnerHolder,
    required this.toolRegistry,
    required this.chatAiService,
  });

  ToolDef createTaskToolWithDeps() => createTaskTool(
    chatAiService: chatAiService,
    toolRegistry: toolRegistry,
    currentSessionRunner: runnerHolder,
  );

  Future<void> close() => db.close();
}

Future<_TestHarness> _createHarness(ChatAiService chatService) async {
  final tempDir = Directory.systemTemp;
  final dbPath =
      '${tempDir.path}/chatorai_tool_error_test_${DateTime.now().microsecondsSinceEpoch}.db';
  final db = AppDatabase.file(dbPath);
  final repository = SessionRepository(db);
  final runner = SessionRunner(repository, null);
  final runnerHolder = SessionRunnerHolder(runner);

  final ps = PermissionService();
  ps.attachPreferences(_createMockPrefs());
  final toolRegistry = ToolRegistry(ps, PermissionRuleset(rules: []));

  return _TestHarness(
    db: db,
    dbPath: dbPath,
    repository: repository,
    runner: runner,
    runnerHolder: runnerHolder,
    toolRegistry: toolRegistry,
    chatAiService: chatService,
  );
}

ToolContext _mockCtx({String? sessionId}) {
  return ToolContext(
    toolCallId: 'test-tool-error-${DateTime.now().microsecondsSinceEpoch}',
    sessionId: sessionId ?? 'test-session',
    abortSignal: null,
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

/// Load the child session state.
Future<SessionState?> _loadChildState(
  SessionRepository repository,
  SessionID childId,
) async {
  return repository.loadSession(childId);
}

// ─── Tests ───────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    registerFallbackValue(SessionID.create());
    await AgentRegistry().init();
  });

  group('task tool — onToolError recovery', () {
    late _TestHarness harness;
    const defaultSessionId = 'ses_tool-error-test-001';

    setUp(() async {
      harness = await _createHarness(_FakeChatAiServiceToolError());
      await harness.repository.createSession(
        id: SessionID.fromString(defaultSessionId),
        agent: 'general',
      );
    });

    tearDown(() async {
      await harness.close();
      final file = File(harness.dbPath);
      if (await file.exists()) await file.delete();
    });

    test('child session stays alive after onToolError '
        '(task output is non-empty)', () async {
      final ctx = _mockCtx(sessionId: defaultSessionId);
      final output = await harness.createTaskToolWithDeps().execute({
        'description': 'Task with tool error',
        'prompt': 'Use hallucinated_tool',
        'subagent_type': 'general',
      }, ctx);

      // The task should complete successfully (not fail)
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Recovered after tool error'));

      // CRITICAL: The output is non-empty, proving the session stayed alive.
      // Before fix: onError() sets _finalized=true → onCompletion is a no-op
      // → task returns empty string and taskResult.output is empty.
      // After fix: onToolError() keeps session alive → onCompletion works.
      expect(output.output, isNotEmpty);
    });

    test(
      'child session produces output text after tool error recovery',
      () async {
        final ctx = _mockCtx(sessionId: defaultSessionId);
        final output = await harness.createTaskToolWithDeps().execute({
          'description': 'Task recovery',
          'prompt': 'Do something that fails then recover',
          'subagent_type': 'general',
        }, ctx);

        // Output should contain the recovery text
        expect(output.output, contains('Recovered after tool error'));
        expect(output.metadata?['error'], isNull);

        // The child session ID should be present in the result
        final childSessionId = output.metadata?['session_id'];
        expect(childSessionId, isNotNull);
      },
    );

    test('onToolError does not finalize child session '
        '(onCompletion still fires)', () async {
      final ctx = _mockCtx(sessionId: defaultSessionId);
      final output = await harness.createTaskToolWithDeps().execute({
        'description': 'Verify completion fires',
        'prompt': 'Test',
        'subagent_type': 'general',
      }, ctx);

      // The fact that output is non-empty proves onCompletion fired.
      // Before fix: onError() sets _finalized=true → subsequent
      // onCompletion would be a no-op → task returns empty string.
      // After fix: onToolError() does NOT finalize → onCompletion works.
      expect(output.output, isNotEmpty);
      expect(output.metadata?['error'], isNull);
    });
  });

  group('task tool — normal path (no error)', () {
    late _TestHarness harness;
    const defaultSessionId = 'ses_tool-normal-test-001';

    setUp(() async {
      harness = await _createHarness(
        _FakeChatAiServiceToolError(simulateToolError: false),
      );
      await harness.repository.createSession(
        id: SessionID.fromString(defaultSessionId),
        agent: 'general',
      );
    });

    tearDown(() async {
      await harness.close();
      final file = File(harness.dbPath);
      if (await file.exists()) await file.delete();
    });

    test('normal completion without errors works as before', () async {
      final ctx = _mockCtx(sessionId: defaultSessionId);
      final output = await harness.createTaskToolWithDeps().execute({
        'description': 'Normal task',
        'prompt': 'Do something',
        'subagent_type': 'general',
      }, ctx);

      expect(output.output, contains('Normal output'));
      expect(output.metadata?['error'], isNull);

      final childSessionId = output.metadata?['session_id'] as String?;
      final childState = await harness.repository.loadSession(
        SessionID.fromString(childSessionId!),
      );
      expect(childState, isNotNull);
      expect(
        childState!.toolResults.where((tr) => tr.status == 'error'),
        isEmpty,
      );
      expect(
        childState.parts.whereType<AssistantTool>().where(
          (t) => t.state == ToolState.error,
        ),
        isEmpty,
      );
    });
  });
}
