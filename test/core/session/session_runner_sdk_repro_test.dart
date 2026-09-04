import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_openai_compatible/ai_sdk_openai_compatible.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/event_bus.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves canned kilo-style SSE bodies (one per HTTP request) through a real
/// Dio HttpClientAdapter so the REAL OpenAICompatibleChatLanguageModel parses
/// them — no mocked model, no mocked events.
class _SseAdapter implements HttpClientAdapter {
  _SseAdapter(this.bodies);

  final List<String> bodies;
  final List<String> requestBodies = [];
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = await requestStream?.fold<List<int>>(
      <int>[],
      (acc, chunk) => acc..addAll(chunk),
    );
    if (bytes != null) requestBodies.add(utf8.decode(bytes));
    final body = bodies[(calls++).clamp(0, bodies.length - 1)];
    return ResponseBody(
      Stream.value(Uint8List.fromList(utf8.encode(body))),
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
        Headers.acceptHeader: ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String _sse(List<Map<String, Object?>> chunks) =>
    chunks.map((c) => 'data: ${jsonEncode(c)}\n\n').join();

void main() {
  group('SDK→runner reproduction: kilo-style reasoning + tools', () {
    late AppDatabase db;
    late SessionRepository repository;
    late SessionRunner runner;
    late SessionRunnerSession session;

    setUp(() async {
      db = AppDatabase.inMemory();
      repository = SessionRepository(db);
      runner = SessionRunner(repository, null, eventBus: SessionEventBus());
      session = runner.startSession(agent: 'general', modelRef: 'kilo');
      await session.initialize();
    });

    tearDown(() async {
      await db.close();
    });

    test('interleaved post-tool reasoning stays a separate part', () async {
      final adapter = _SseAdapter([
        // ── Step 1: reasoning → tool_calls(websearch) → MORE reasoning → tool_calls(webfetch) → finish
        _sse([
          {
            'choices': [
              {
                'index': 0,
                'delta': {
                  'reasoning_content': 'Let me check the weather in Chernihiv.',
                },
              },
            ],
          },
          {
            'choices': [
              {
                'index': 0,
                'delta': {
                  'tool_calls': [
                    {
                      'index': 0,
                      'id': 'call_1',
                      'type': 'function',
                      'function': {'name': 'websearch', 'arguments': ''},
                    },
                  ],
                },
              },
            ],
          },
          {
            'choices': [
              {
                'index': 0,
                'delta': {
                  'tool_calls': [
                    {
                      'index': 0,
                      'function': {'arguments': '{"query":"погода Чернигов"}'},
                    },
                  ],
                },
              },
            ],
          },
          {
            'choices': [
              {
                'index': 0,
                'delta': {
                  'reasoning_content':
                      'Now let me fetch the details from the page.',
                },
              },
            ],
          },
          {
            'choices': [
              {
                'index': 0,
                'delta': {
                  'tool_calls': [
                    {
                      'index': 1,
                      'id': 'call_2',
                      'type': 'function',
                      'function': {'name': 'webfetch', 'arguments': ''},
                    },
                  ],
                },
              },
            ],
          },
          {
            'choices': [
              {
                'index': 0,
                'delta': {
                  'tool_calls': [
                    {
                      'index': 1,
                      'function': {
                        'arguments': '{"url":"https://pogoda.meta.ua"}',
                      },
                    },
                  ],
                },
              },
            ],
          },
          {
            'choices': [
              {'index': 0, 'delta': {}, 'finish_reason': 'tool_calls'},
            ],
            'usage': {
              'prompt_tokens': 100,
              'completion_tokens': 50,
              'total_tokens': 150,
            },
          },
        ]),
        // ── Step 2: reasoning → text → finish
        _sse([
          {
            'choices': [
              {
                'index': 0,
                'delta': {
                  'reasoning_content': 'The weather in Chernihiv today:',
                },
              },
            ],
          },
          {
            'choices': [
              {
                'index': 0,
                'delta': {
                  'content':
                      'Сегодня в Чернигове +18°C, переменная облачность.',
                },
              },
            ],
          },
          {
            'choices': [
              {'index': 0, 'delta': {}, 'finish_reason': 'stop'},
            ],
            'usage': {
              'prompt_tokens': 200,
              'completion_tokens': 30,
              'total_tokens': 230,
            },
          },
        ]),
      ]);

      final dio = Dio(BaseOptions(baseUrl: 'https://api.kilo.ai/api/gateway'))
        ..httpClientAdapter = adapter;
      final model = OpenAICompatibleChatLanguageModel(
        config: OpenAICompatibleConfig(
          provider: 'kilo',
          baseUrl: 'https://api.kilo.ai/api/gateway',
          headers: () async => {'Authorization': 'Bearer test'},
          client: dio,
          supportsTools: true,
        ),
        modelId: 'stepfun/step-3.7-flash:free',
      );

      final executed = <String>[];
      final tools = <String, Tool<dynamic, dynamic>>{
        'websearch': Tool<dynamic, dynamic>(
          inputSchema: Schema<dynamic>(
            jsonSchema: {'type': 'object'},
            fromJson: (m) => m,
          ),
          executeDynamic: (input, options) async {
            executed.add('websearch');
            return 'search-ok';
          },
        ),
        'webfetch': Tool<dynamic, dynamic>(
          inputSchema: Schema<dynamic>(
            jsonSchema: {'type': 'object'},
            fromJson: (m) => m,
          ),
          executeDynamic: (input, options) async {
            executed.add('webfetch');
            return 'fetch-ok';
          },
        ),
      };

      final result = await streamText(
        model: model,
        messages: [
          const ModelMessage(role: ModelMessageRole.user, content: 'Погода?'),
        ],
        tools: tools,
        maxSteps: 5,
        onInputAvailable: (event) async {
          await session.onToolStart(
            event.toolCallId,
            event.toolName,
            event.input as Map<String, dynamic>,
          );
        },
      );

      final reasoningDelta = <String>[];
      final toolInputs = <String, Map<String, dynamic>>{};
      await for (final event in result.fullStream) {
        switch (event) {
          case StreamTextReasoningDeltaEvent(:final delta):
            reasoningDelta.add(delta);
            await session.onReasoning(delta);
          case StreamTextReasoningEndEvent():
            await session.onReasoningEnd();
          case StreamTextTextDeltaEvent(:final delta):
            await session.onChunk(delta);
          case StreamTextToolInputEndEvent(:final toolCallId, :final input):
            if (input is Map<String, dynamic>) {
              toolInputs[toolCallId] = input;
            }
          case StreamTextToolResultEvent(:final toolResult, :final preliminary):
            if (!preliminary) {
              await session.onToolEnd(
                toolResult.toolCallId,
                toolResult.toolName,
                toolResult.output.toString(),
                input: toolInputs[toolResult.toolCallId],
              );
            }
          case StreamTextFinishEvent():
            break;
          default:
            break;
        }
      }
      await session.onCompletion(
        content: await result.text,
        model: 'kilo',
        tokensInput: 0,
        tokensOutput: 0,
        tokensReasoning: 0,
        tokensCacheRead: 0,
        tokensCacheWrite: 0,
      );

      expect(executed, ['websearch', 'webfetch']);
      expect(adapter.requestBodies.length, 2);

      final loaded = await repository.loadSession(session.sessionId);
      final parts = loaded!.parts;

      final reasoningParts = parts.whereType<AssistantReasoning>().toList();
      final textParts = parts.whereType<AssistantText>().toList();
      final toolParts = parts.whereType<AssistantTool>().toList();

      // Expected part order:
      //   R1 — pre-tool reasoning ("Let me check the weather...")
      //   T1, T2 — tool cards emitted immediately when tools start
      //   R2 — post-tool reasoning buffered during tool execution
      //         ("Now let me fetch the details from the page.")
      //   R3 — step-2 thought ("The weather in Chernihiv today:")
      //   Text — final answer
      final kinds = parts
          .map(
            (p) => p is AssistantReasoning
                ? 'R:${p.text.substring(0, p.text.length.clamp(0, 24))}'
                : p is AssistantTool
                ? 'T:${p.tool}'
                : p is AssistantText
                ? 'Text'
                : p.runtimeType.toString(),
          )
          .toList();

      expect(
        reasoningParts.length,
        3,
        reason:
            'pre-tool thought + post-tool buffered thought + step-2 thought '
            '= 3 separate parts. Actual kinds: $kinds',
      );
      expect(
        reasoningParts[0].text,
        contains('Let me check the weather'),
        reason: 'part 1 is the pre-tool thought',
      );
      expect(
        reasoningParts[1].text,
        contains('Now let me fetch'),
        reason:
            'part 2 is the post-tool buffered thought — it must NOT be merged '
            'into part 1. Actual: ${reasoningParts.map((p) => p.text).toList()}',
      );
      expect(
        reasoningParts[2].text,
        contains('The weather in Chernihiv today:'),
        reason:
            'part 3 is the step-2 thought, not a merged blob. '
            'Actual: ${reasoningParts.map((p) => p.text).toList()}',
      );
      expect(textParts.single.text, contains('+18°C'));
      expect(toolParts.length, 2);
      expect(
        toolParts.first.input,
        contains('query'),
        reason: 'completed tool card input must be the FULL input, not {}',
      );

      // Cards sit between pre-tool reasoning and post-tool buffered reasoning:
      //   thought → tools → buffered thought → step-2 thought.
      final firstToolIdx = parts.indexWhere((p) => p is AssistantTool);
      expect(
        firstToolIdx,
        1,
        reason:
            'tool cards must come right after the pre-tool thought part. '
            'Actual kinds: $kinds',
      );
    });
  });
}
