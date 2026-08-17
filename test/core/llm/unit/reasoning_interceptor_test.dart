import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/llm/reasoning_interceptor.dart';

void main() {
  group('ReasoningSseInterceptor', () {
    Stream<Uint8List> _sseStream(List<String> events) {
      final data = '${events.join('\n\n')}\n\n';
      return Stream.value(Uint8List.fromList(utf8.encode(data)));
    }

    Future<Response> _process(ReasoningSseInterceptor interceptor, List<String> events) async {
      final body = ResponseBody(
        _sseStream(events),
        200,
        headers: {},
      );
      final response = Response(
        data: body,
        requestOptions: RequestOptions(path: '/test'),
      );
      final handler = ResponseInterceptorHandler();
      interceptor.onResponse(response, handler);
      final state = await handler.future;
      return state.data;
    }

    test('captures usage object from final SSE chunk', () async {
      Map<String, dynamic>? capturedUsage;
      final interceptor = ReasoningSseInterceptor(
        onUsageJson: (usage) => capturedUsage = usage,
      );

      final events = [
        'data: {"choices": [{"delta": {"content": "Hello"}}]}',
        'data: {"usage": {"prompt_tokens_details": {"cached_tokens": 1920}, "total_tokens": 100}, "choices": []}',
      ];

      final response = await _process(interceptor, events);
      final body = response.data as ResponseBody;
      final output = await body.stream.toList();
      final text = utf8.decode(output.expand((x) => x).toList());

      expect(capturedUsage, isNotNull);
      expect(capturedUsage!['prompt_tokens_details'], isNotNull);
      expect(capturedUsage!['prompt_tokens_details']['cached_tokens'], 1920);
      expect(text, contains('Hello'));
    });

    test('still transforms reasoning chunks', () async {
      final interceptor = ReasoningSseInterceptor();

      final events = [
        'data: {"choices": [{"delta": {"reasoning_content": "thinking", "content": "Hello"}}]}',
      ];

      final response = await _process(interceptor, events);
      final body = response.data as ResponseBody;
      final output = await body.stream.toList();
      final text = utf8.decode(output.expand((x) => x).toList());

      expect(text, contains('<think>thinking</think>Hello'));
    });

    test('usage chunk without choices passes through unchanged', () async {
      Map<String, dynamic>? capturedUsage;
      final interceptor = ReasoningSseInterceptor(
        onUsageJson: (usage) => capturedUsage = usage,
      );

      final events = [
        'data: {"usage": {"total_tokens": 50}, "choices": []}',
      ];

      final response = await _process(interceptor, events);
      final body = response.data as ResponseBody;
      final output = await body.stream.toList();
      final text = utf8.decode(output.expand((x) => x).toList());

      expect(capturedUsage, isNotNull);
      expect(capturedUsage!['total_tokens'], 50);
      expect(text, contains('"choices": []'));
    });

    test('does not crash on malformed JSON', () async {
      final interceptor = ReasoningSseInterceptor();

      final events = [
        'data: {invalid json',
        'data: {"choices": [{"delta": {"content": "ok"}}]}',
      ];

      final response = await _process(interceptor, events);
      final body = response.data as ResponseBody;
      final output = await body.stream.toList();
      final text = utf8.decode(output.expand((x) => x).toList());

      expect(text, contains('ok'));
    });
  });
}
