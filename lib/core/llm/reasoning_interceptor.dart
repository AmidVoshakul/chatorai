import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Dio interceptor that moves `reasoning` / `reasoning_content` /
/// `reasoning_details` from the SSE delta into the `content` field,
/// wrapped in `<think>` tags so [extractReasoningMiddleware] can extract them.
///
/// Without this interceptor the SDK drops non-standard delta fields and
/// streaming reasoning is never visible in the UI.
class ReasoningSseInterceptor extends Interceptor {
  ReasoningSseInterceptor({this.onUsageJson});

  /// Called with the raw `usage` object from the final SSE chunk when the
  /// provider reports one (the SDK's usage model strips provider-specific
  /// details such as cache tokens).
  final void Function(Map<String, dynamic> usage)? onUsageJson;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is ResponseBody) {
      final body = response.data as ResponseBody;
      response.data = ResponseBody(
        _transform(body.stream),
        body.statusCode,
        headers: body.headers,
      );
    }
    handler.next(response);
  }

  /// Reads the raw SSE byte stream and yields the same stream with
  /// reasoning deltas injected into the `content` field.
  Stream<Uint8List> _transform(Stream<Uint8List> source) async* {
    final buffer = BytesBuilder();
    final sseLines = <String>[];

    await for (final chunk in source) {
      buffer.add(chunk);
      final text = utf8.decode(buffer.takeBytes(), allowMalformed: true);
      final lines = const LineSplitter().convert(text);

      // Keep the last partial line in the buffer if needed.
      // We put back everything after the last newline so chunk
      // boundaries don't split multi-byte characters.
      if (text.endsWith('\n')) {
        buffer.clear();
      } else {
        final lastNewline = text.lastIndexOf('\n');
        if (lastNewline != -1) {
          final leftover = utf8.encode(text.substring(lastNewline + 1));
          buffer.clear();
          buffer.add(leftover);
        } else {
          buffer.clear();
          buffer.add(chunk);
          continue;
        }
      }

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.isEmpty) {
          if (sseLines.isNotEmpty) {
            yield _maybeTransform(sseLines.join('\n'));
            sseLines.clear();
          }
        } else {
          sseLines.add(line);
        }
      }
    }

    if (sseLines.isNotEmpty) {
      yield _maybeTransform(sseLines.join('\n'));
    }
  }

  /// Transform a single SSE event payload. The payload may contain
  /// multiple `data:` lines joined together.
  Uint8List _maybeTransform(String payload) {
    final lines = const LineSplitter().convert(payload);
    final result = <String>[];

    for (final line in lines) {
      if (!line.startsWith('data:')) {
        result.add(line);
        continue;
      }
      final data = line.substring(5).trim();
      if (data.isEmpty) {
        result.add(line);
        continue;
      }
      if (data == '[DONE]') {
        result.add(line);
        continue;
      }
      try {
        final decoded = jsonDecode(data);
        if (decoded is! Map<String, dynamic>) {
          result.add(line);
          continue;
        }
        final json = decoded;
        final usage = json['usage'];
        if (usage is Map<String, dynamic>) {
          onUsageJson?.call(usage);
        }
        final modified = _injectIntoContent(json);
        result.add(modified == null ? line : 'data: ${jsonEncode(modified)}');
      } on FormatException {
        result.add(line);
      }
    }

    return utf8.encode('${result.join('\n')}\n');
  }

  /// If [json] contains a reasoning delta, moves it into `content` wrapped
  /// in `<think>` tags. Returns `null` when nothing was modified.
  Map<String, dynamic>? _injectIntoContent(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final modifiedChoices = <dynamic>[];
    var changed = false;

    for (final choice in choices) {
      if (choice is! Map<String, dynamic>) {
        modifiedChoices.add(choice);
        continue;
      }
      final delta = choice['delta'];
      if (delta is! Map<String, dynamic>) {
        modifiedChoices.add(choice);
        continue;
      }

      final reasoningText = _firstReasoningText(delta);
      if (reasoningText == null) {
        modifiedChoices.add(choice);
        continue;
      }

      final modifiedDelta = Map<String, dynamic>.from(delta);
      modifiedDelta.remove('reasoning');
      modifiedDelta.remove('reasoning_content');
      modifiedDelta.remove('reasoning_details');

      final existingContent = _toNullableText(delta['content']) ?? '';
      modifiedDelta['content'] =
          '<think>$reasoningText</think>$existingContent';

      final modifiedChoice = Map<String, dynamic>.from(choice);
      modifiedChoice['delta'] = modifiedDelta;

      modifiedChoices.add(modifiedChoice);
      changed = true;
    }

    if (!changed) return null;

    final modifiedJson = Map<String, dynamic>.from(json);
    modifiedJson['choices'] = modifiedChoices;
    return modifiedJson;
  }

  String? _firstReasoningText(Map<String, dynamic> delta) {
    final candidates = <String?>[
      _toNullableText(delta['reasoning']),
      _toNullableText(delta['reasoning_content']),
      _toNullableText(delta['reasoning_details']),
    ];

    for (final text in candidates) {
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  String? _toNullableText(Object? value) {
    if (value is String) return value;
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => '$e').join();
    }
    return '$value';
  }
}
