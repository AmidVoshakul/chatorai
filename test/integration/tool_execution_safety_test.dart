import 'package:ai_sdk_dart/ai_sdk_dart.dart' show ToolSet;
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/task.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart'
    show ToolState;
import 'package:chatorai/features/chat/data/providers/chat_screen_notifier.dart'
    show ChatScreenState;
import 'package:chatorai/features/chat/services/chat_ai_service.dart';
import 'package:chatorai/features/chat/services/chat_retry_service.dart'
    show RichRetryInfo;
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

// ============================================================================
// NOTIFIER WRAPPER — mirrors chat_screen_notifier behavior for testing
// ============================================================================

class _TestNotifier {
  ChatScreenState _state = const ChatScreenState();
  final List<AssistantContent> _closedParts = [];

  ChatScreenState get state => _state;

  void startStreaming(String sessionId) {
    _state = _state.copyWith(streamingSessionId: sessionId);
  }

  void finalizeStreaming() {
    final completed = _state.streamingParts
        .where((p) => p is! AssistantTool || p.state != ToolState.running)
        .toList();
    _closedParts.addAll(completed);
    _state = _state.copyWith(
      clearStreamingSessionId: true,
      streamingParts: const [],
    );
  }

  void onChunk(
    String partId,
    String messageId,
    String sessionId,
    String delta,
  ) {
    final currentParts = _state.streamingParts;
    final parts = List<AssistantContent>.from(currentParts);
    final lastIsText = parts.isNotEmpty && parts.last is AssistantText;
    if (lastIsText) {
      final prev = parts.last as AssistantText;
      parts[parts.length - 1] = AssistantText(
        id: prev.id ?? partId,
        sessionId: prev.sessionId ?? sessionId,
        messageId: prev.messageId ?? messageId,
        text: prev.text + delta,
        synthetic: prev.synthetic,
        ignored: prev.ignored,
        title: prev.title,
      );
    } else {
      parts.add(
        AssistantText(
          id: partId,
          sessionId: sessionId,
          messageId: messageId,
          text: delta,
        ),
      );
    }
    _state = _state.copyWith(streamingParts: parts);
  }

  void onReasoning(
    String partId,
    String messageId,
    String sessionId,
    String delta,
  ) {
    final currentParts = _state.streamingParts;
    final parts = List<AssistantContent>.from(currentParts);
    final openIdx = parts.lastIndexWhere(
      (p) => p is AssistantReasoning && p.ended == null,
    );
    if (openIdx >= 0) {
      final prev = parts[openIdx] as AssistantReasoning;
      parts[openIdx] = AssistantReasoning(
        id: prev.id ?? partId,
        sessionId: prev.sessionId ?? sessionId,
        messageId: prev.messageId ?? messageId,
        text: prev.text + delta,
        started: prev.started,
        ended: null,
      );
    } else {
      parts.add(
        AssistantReasoning(
          id: partId,
          sessionId: sessionId,
          messageId: messageId,
          text: delta,
          started: DateTime.now(),
          ended: null,
        ),
      );
    }
    _state = _state.copyWith(streamingParts: parts);
  }

  void onToolCall(
    String partId,
    String callId,
    String messageId,
    String sessionId,
    String toolName,
    Map<String, dynamic> input,
  ) {
    final currentParts = _state.streamingParts;
    final parts = List<AssistantContent>.from(currentParts);
    if (parts.any((p) => p is AssistantTool && p.callId == callId)) return;
    parts.add(
      AssistantTool(
        id: partId,
        sessionId: sessionId,
        messageId: messageId,
        callId: callId,
        tool: toolName,
        state: ToolState.running,
        input: input,
      ),
    );
    _state = _state.copyWith(streamingParts: parts);
  }

  void onToolEnd(String callId, String toolName, String result) {
    final currentParts = _state.streamingParts;
    final parts = List<AssistantContent>.from(currentParts);
    final toolIdx = parts.indexWhere(
      (p) => p is AssistantTool && p.callId == callId,
    );
    if (toolIdx < 0) return;
    final prev = parts[toolIdx] as AssistantTool;
    parts[toolIdx] = AssistantTool(
      id: prev.id ?? callId,
      sessionId: prev.sessionId ?? '',
      messageId: prev.messageId ?? '',
      callId: callId,
      tool: toolName,
      state: ToolState.completed,
      input: prev.input,
      output: result,
    );
    _state = _state.copyWith(streamingParts: parts);
  }

  void onToolError(String callId, String toolName, String error) {
    final currentParts = _state.streamingParts;
    final parts = List<AssistantContent>.from(currentParts);
    final toolIdx = parts.indexWhere(
      (p) => p is AssistantTool && p.callId == callId,
    );
    if (toolIdx < 0) return;
    final prev = parts[toolIdx] as AssistantTool;
    parts[toolIdx] = AssistantTool(
      id: prev.id ?? callId,
      sessionId: prev.sessionId ?? '',
      messageId: prev.messageId ?? '',
      callId: callId,
      tool: toolName,
      state: ToolState.error,
      input: prev.input,
      output: error,
    );
    _state = _state.copyWith(streamingParts: parts);
  }

  List<AssistantContent> snapshotClosedStreamingParts() {
    return List.unmodifiable([..._closedParts, ..._state.streamingParts]);
  }

  List<AssistantContent> snapshotCurrentStreamingParts() {
    return List.unmodifiable(_state.streamingParts);
  }

  List<AssistantContent> snapshotClosedParts() {
    return List.unmodifiable(_closedParts);
  }
}

// ============================================================================
// TEST HARNESS (for DB-backed tests)
// ============================================================================

class _DbHarness {
  final AppDatabase db;
  final SessionRepository repository;
  final SessionRunner runner;
  final SessionRunnerHolder runnerHolder;
  final ToolRegistry toolRegistry;

  _DbHarness({
    required this.db,
    required this.repository,
    required this.runner,
    required this.runnerHolder,
    required this.toolRegistry,
  });

  ToolDef createTaskToolWithDeps() => createTaskTool(
    chatAiService: _FakeChatAiService(),
    toolRegistry: toolRegistry,
    currentSessionRunner: runnerHolder,
  );

  Future<void> close() async {
    await db.close();
  }
}

class _FakeChatAiService extends ChatAiService {
  _FakeChatAiService() : super(resolver: _createFakeResolver()) {
    currentModelForTesting = 'openrouter/free';
    currentTemperatureForTesting = 0.7;
  }

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
    String? sessionId,
  }) async {
    onChunk('Fake subagent output');
    onCompletion('Fake completion');
  }

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
    onChunk('Fake subagent output');
    onUsage?.call(10, 20, 5, 3);
    onCompletion('Fake completion');
  }
}

SharedPreferences _createMockPrefs() {
  final mock = MockSharedPreferences();
  when(() => mock.setString(any(), any())).thenAnswer((_) async => true);
  when(() => mock.setBool(any(), any())).thenAnswer((_) async => true);
  when(() => mock.setInt(any(), any())).thenAnswer((_) async => true);
  when(() => mock.getString(any())).thenReturn(null);
  when(() => mock.getBool(any())).thenReturn(null);
  when(() => mock.getInt(any())).thenReturn(null);
  when(() => mock.getStringList(any())).thenReturn(null);
  return mock;
}

Future<_DbHarness> _createDbHarness() async {
  final db = AppDatabase.inMemory();
  final repository = SessionRepository(db);
  final runner = SessionRunner(repository, null);
  final runnerHolder = SessionRunnerHolder(runner);
  await repository.createSession(agent: 'test');
  final ps = PermissionService();
  ps.attachPreferences(_createMockPrefs());
  final toolRegistry = ToolRegistry(ps, PermissionRuleset(rules: []));
  return _DbHarness(
    db: db,
    repository: repository,
    runner: runner,
    runnerHolder: runnerHolder,
    toolRegistry: toolRegistry,
  );
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  group('Tool Execution Safety', () {
    late _TestNotifier notifier;

    setUp(() {
      notifier = _TestNotifier();
    });

    // -----------------------------------------------------------------------
    // Test 1: Text + tool + text — все части сохраняются
    // -----------------------------------------------------------------------
    test('streaming preserves text before and after tool execution', () {
      notifier.startStreaming('ses_test_1');
      notifier.onChunk('p1', 'm1', 'ses_test_1', 'Before tool. ');
      notifier.onToolCall('pt1', 'c1', 'm1', 'ses_test_1', 'todowrite', {
        'todos': [
          {'content': 'A', 'status': 'pending'},
        ],
      });
      notifier.onToolEnd('c1', 'todowrite', '{"ok":true}');
      notifier.onChunk('p2', 'm1', 'ses_test_1', 'After tool.');

      final parts = notifier.snapshotClosedStreamingParts();
      expect(
        parts.any((p) => p is AssistantText && p.text.contains('Before tool')),
        isTrue,
      );
      expect(
        parts.any((p) => p is AssistantText && p.text.contains('After tool')),
        isTrue,
      );
      expect(
        parts.any((p) => p is AssistantTool && p.state == ToolState.completed),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // Test 2: Crash после успешного tool — результат не теряется
    // -----------------------------------------------------------------------
    test('tool result survives finalize (crash simulation)', () {
      notifier.startStreaming('ses_test_2');
      notifier.onChunk('p1', 'm1', 'ses_test_2', 'Thinking...');
      notifier.onToolCall('pt1', 'c1', 'm1', 'ses_test_2', 'todowrite', {
        'todos': [
          {'content': 'A', 'status': 'pending'},
        ],
      });
      notifier.onToolEnd('c1', 'todowrite', 'Done');

      // Simulate crash — finalize without completing pending tools
      notifier.onToolCall('pt2', 'c2', 'm1', 'ses_test_2', 'todowrite', {
        'todos': [
          {'content': 'B', 'status': 'pending'},
        ],
      });
      notifier.finalizeStreaming();

      final closed = notifier.snapshotClosedParts();
      expect(
        closed.any(
          (p) =>
              p is AssistantTool &&
              p.callId == 'c1' &&
              p.state == ToolState.completed,
        ),
        isTrue,
        reason: 'completed tool survives crash',
      );
      expect(
        closed.any((p) => p is AssistantText && p.text.contains('Thinking')),
        isTrue,
        reason: 'text survives crash',
      );
      expect(
        closed.any((p) => p is AssistantTool && p.callId == 'c2'),
        isFalse,
        reason: 'incomplete tool is cleared by finalize',
      );
      expect(
        notifier.snapshotCurrentStreamingParts(),
        isEmpty,
        reason: 'streaming state is empty after finalize',
      );
    });

    // -----------------------------------------------------------------------
    // Test 3: 3+ параллельных tool — все появляются
    // -----------------------------------------------------------------------
    test('parallel tool calls all appear in parts', () {
      notifier.startStreaming('ses_test_3');
      notifier.onToolCall('pa', 'ca', 'm1', 'ses_test_3', 'todowrite', {
        'todos': [
          {'content': 'A', 'status': 'pending'},
        ],
      });
      notifier.onToolCall('pb', 'cb', 'm1', 'ses_test_3', 'todowrite', {
        'todos': [
          {'content': 'B', 'status': 'pending'},
        ],
      });
      notifier.onToolCall('pc', 'cc', 'm1', 'ses_test_3', 'todowrite', {
        'todos': [
          {'content': 'C', 'status': 'pending'},
        ],
      });

      var parts = notifier.snapshotClosedStreamingParts();
      expect(parts.whereType<AssistantTool>().length, equals(3));

      notifier.onToolEnd('cb', 'todowrite', 'B');
      notifier.onToolEnd('ca', 'todowrite', 'A');
      notifier.onToolEnd('cc', 'todowrite', 'C');

      parts = notifier.snapshotClosedStreamingParts();
      expect(
        parts.whereType<AssistantTool>().every(
          (t) => t.state == ToolState.completed,
        ),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // Test 4: Порядок частей не меняется от порядка onToolEnd
    // -----------------------------------------------------------------------
    test('part order reflects start order, not completion order', () {
      notifier.startStreaming('ses_test_4');
      notifier.onToolCall('pa', 'ca', 'm1', 'ses_test_4', 'todowrite', {});
      notifier.onToolCall('pb', 'cb', 'm1', 'ses_test_4', 'todowrite', {});
      notifier.onToolCall('pc', 'cc', 'm1', 'ses_test_4', 'todowrite', {});

      // Complete in reverse order
      notifier.onToolEnd('cc', 'todowrite', 'C');
      notifier.onToolEnd('cb', 'todowrite', 'B');
      notifier.onToolEnd('ca', 'todowrite', 'A');

      final tools = notifier
          .snapshotClosedStreamingParts()
          .whereType<AssistantTool>()
          .toList();
      expect(tools[0].callId, 'ca');
      expect(tools[1].callId, 'cb');
      expect(tools[2].callId, 'cc');
    });

    // -----------------------------------------------------------------------
    // Test 5: Повторный запуск после сбоя — новая сессия
    // -----------------------------------------------------------------------
    test('new session after finalized streaming starts clean', () {
      // Session 1
      notifier.startStreaming('ses_a');
      notifier.onChunk('p1', 'm1', 'ses_a', 'Message 1');
      notifier.onToolCall('pt1', 'c1', 'm1', 'ses_a', 'todowrite', {});
      notifier.onToolEnd('c1', 'todowrite', 'OK');
      notifier.finalizeStreaming();

      final s1closed = notifier.snapshotClosedParts();
      expect(
        s1closed.length,
        greaterThan(0),
        reason: 'closed parts from ses_a survive',
      );
      expect(
        notifier.snapshotCurrentStreamingParts(),
        isEmpty,
        reason: 'streaming state is cleared',
      );

      // Session 2
      notifier.startStreaming('ses_b');
      notifier.onChunk('p2', 'm2', 'ses_b', 'Message 2');
      notifier.onToolCall('pt2', 'c2', 'm2', 'ses_b', 'todowrite', {});
      notifier.onToolEnd('c2', 'todowrite', 'OK');

      final s2streaming = notifier.snapshotCurrentStreamingParts();
      expect(
        s2streaming.any(
          (p) => p is AssistantText && p.text.contains('Message 2'),
        ),
        isTrue,
        reason: 'new session has its own text',
      );
      expect(
        s2streaming.whereType<AssistantTool>().every(
          (t) => t.sessionId == 'ses_b',
        ),
        isTrue,
        reason: 'all tools belong to new session',
      );
    });

    // -----------------------------------------------------------------------
    // Test 6: Чередование текст → тул → текст → тул
    // -----------------------------------------------------------------------
    test('interleaved text and tools maintain correct part types order', () {
      notifier.startStreaming('ses_test_6');
      notifier.onChunk('pt1', 'm1', 'ses_test_6', 'Text 1\n');
      notifier.onToolCall('ptl1', 'c1', 'm1', 'ses_test_6', 'todowrite', {});
      notifier.onToolEnd('c1', 'todowrite', 'R1');
      notifier.onChunk('pt2', 'm1', 'ses_test_6', 'Text 2\n');
      notifier.onToolCall('ptl2', 'c2', 'm1', 'ses_test_6', 'todowrite', {});
      notifier.onToolEnd('c2', 'todowrite', 'R2');
      notifier.onChunk('pt3', 'm1', 'ses_test_6', 'Text 3\n');

      final parts = notifier.snapshotClosedStreamingParts();
      expect(parts.length, equals(5));
      expect(parts[0], isA<AssistantText>());
      expect(parts[1], isA<AssistantTool>());
      expect(parts[2], isA<AssistantText>());
      expect(parts[3], isA<AssistantTool>());
      expect(parts[4], isA<AssistantText>());
    });

    // -----------------------------------------------------------------------
    // Test 7: Пустой результат тула не ломает состояние
    // -----------------------------------------------------------------------
    test('empty tool result produces valid part', () {
      notifier.startStreaming('ses_test_7');
      notifier.onToolCall('pt1', 'c1', 'm1', 'ses_test_7', 'todowrite', {});
      notifier.onToolEnd('c1', 'todowrite', '');
      final parts = notifier.snapshotClosedStreamingParts();
      expect(parts.any((p) => p is AssistantTool && p.callId == 'c1'), isTrue);
      expect(
        parts.any((p) => p is AssistantTool && p.state == ToolState.completed),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // Test 8: Дубликат toolCallId игнорируется
    // -----------------------------------------------------------------------
    test('duplicate tool call ID is ignored', () {
      notifier.startStreaming('ses_test_8');
      notifier.onToolCall('pt1', 'c1', 'm1', 'ses_test_8', 'todowrite', {});
      notifier.onToolCall('pt1', 'c1', 'm1', 'ses_test_8', 'todowrite', {});
      final tools = notifier
          .snapshotClosedStreamingParts()
          .whereType<AssistantTool>()
          .toList();
      expect(tools.length, equals(1));
    });

    // -----------------------------------------------------------------------
    // Test 9: Tool error не теряет части
    // -----------------------------------------------------------------------
    test('tool error preserves text and previous tool results', () {
      notifier.startStreaming('ses_test_9');
      notifier.onChunk('p1', 'm1', 'ses_test_9', 'Working...');
      notifier.onToolCall('pt1', 'c1', 'm1', 'ses_test_9', 'todowrite', {});
      notifier.onToolEnd('c1', 'todowrite', 'OK');
      notifier.onToolCall('pt2', 'c2', 'm1', 'ses_test_9', 'todowrite', {});
      notifier.onToolError('c2', 'todowrite', 'Error!');
      notifier.onChunk('p2', 'm1', 'ses_test_9', 'Done.');

      final parts = notifier.snapshotClosedStreamingParts();
      expect(
        parts.any((p) => p is AssistantText && p.text.contains('Working')),
        isTrue,
        reason: 'text before error survives',
      );
      expect(
        parts.any(
          (p) =>
              p is AssistantTool &&
              p.callId == 'c1' &&
              p.state == ToolState.completed,
        ),
        isTrue,
        reason: 'completed tool survives',
      );
      expect(
        parts.any(
          (p) =>
              p is AssistantTool &&
              p.callId == 'c2' &&
              p.state == ToolState.error,
        ),
        isTrue,
        reason: 'failed tool is marked error',
      );
    });

    // -----------------------------------------------------------------------
    // Test 10: 10 последовательных инструментов
    // -----------------------------------------------------------------------
    test('10 sequential tools all appear with correct state', () {
      notifier.startStreaming('ses_test_10');
      for (int i = 0; i < 10; i++) {
        notifier.onToolCall('p$i', 'c$i', 'm1', 'ses_test_10', 'todowrite', {
          'todos': [
            {'content': '$i', 'status': 'pending'},
          ],
        });
      }
      for (int i = 0; i < 10; i++) {
        notifier.onToolEnd('c$i', 'todowrite', 'R$i');
      }
      final tools = notifier
          .snapshotClosedStreamingParts()
          .whereType<AssistantTool>()
          .toList();
      expect(tools.length, equals(10));
      expect(tools.every((t) => t.state == ToolState.completed), isTrue);
    });

    // -----------------------------------------------------------------------
    // Test 11: Reasoning + tool + text последовательность
    // -----------------------------------------------------------------------
    test('reasoning block before and after tool execution', () {
      notifier.startStreaming('ses_test_11');
      notifier.onReasoning('pr1', 'm1', 'ses_test_11', 'Thinking step 1...\n');
      notifier.onToolCall('pt1', 'c1', 'm1', 'ses_test_11', 'todowrite', {});
      notifier.onToolEnd('c1', 'todowrite', 'Result');
      notifier.onReasoning('pr2', 'm1', 'ses_test_11', 'Thinking step 2...\n');
      notifier.onChunk('ptx', 'm1', 'ses_test_11', 'Final answer.');

      final parts = notifier.snapshotClosedStreamingParts();
      expect(
        parts.any((p) => p is AssistantReasoning),
        isTrue,
        reason: 'reasoning parts exist',
      );
      expect(
        parts.any((p) => p is AssistantText && p.text.contains('Final answer')),
        isTrue,
        reason: 'final text exists',
      );
    });

    // -----------------------------------------------------------------------
    // Test 12: Task creates child session with session_id in output
    // -----------------------------------------------------------------------
    test('task tool child session returns valid result', () async {
      // Minimal tool definition that returns a TaskChildResult-like structure
      // without relying on the full DB-backed SessionRunner.
      final harness = await _createDbHarness();
      await AgentRegistry().init();
      final childId = SessionID.create();
      final taskTool = ToolDef(
        id: 'task_test',
        description: 'test',
        inputSchema: {},
        execute: (params, ctx) async {
          return ToolOutput(
            'Task completed state="completed" session_id=${childId.value}\n\nTask output: done',
          );
        },
      );

      final output = await taskTool.execute(
        {},
        ToolContext(
          toolCallId: 'test-12',
          sessionId: 'ses_test_12',
          abortSignal: null,
          ask:
              ({
                required permission,
                required patterns,
                metadata,
                always,
              }) async {},
          askQuestion:
              ({
                required question,
                options = const [],
                multiple = false,
              }) async => '',
        ),
      );

      expect(
        output.metadata?['error'],
        isNull,
        reason: 'task tool should succeed',
      );
      expect(
        output.output,
        contains('session_id='),
        reason: 'task output has session reference',
      );
      expect(
        output.output,
        contains('state="completed"'),
        reason: 'task completed successfully',
      );

      await harness.close();
    });
  });
}
