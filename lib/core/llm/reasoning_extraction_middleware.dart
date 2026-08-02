import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';

/// Corrected replacement for [extractReasoningMiddleware] that handles
/// `<think>` / `</think>` tags across chunk boundaries.
///
/// The upstream SDK version incorrectly looks for `</think>` as the open
/// tag while the interceptor writes `</think>`, causing reasoning text
/// to leak into text deltas.
LanguageModelMiddleware reasoningExtractionMiddleware({
  String tagName = 'think',
}) {
  return _ReasoningExtractionMiddleware(tagName: tagName);
}

class _ReasoningExtractionMiddleware extends LanguageModelMiddlewareBase {
  _ReasoningExtractionMiddleware({required this.tagName});

  final String tagName;

  @override
  Future<LanguageModelV3GenerateResult> wrapGenerate({
    required Future<LanguageModelV3GenerateResult> Function(
      LanguageModelV3CallOptions options,
    )
    doGenerate,
    required LanguageModelV3CallOptions options,
    required LanguageModelV3 model,
  }) async {
    final result = await doGenerate(options);
    final newContent = <LanguageModelV3ContentPart>[];
    for (final part in result.content) {
      if (part is LanguageModelV3TextPart) {
        final extracted = _extractReasoning(part.text, tagName);
        if (extracted.reasoning != null) {
          newContent.add(
            LanguageModelV3ReasoningPart(text: extracted.reasoning!),
          );
        }
        if (extracted.text.isNotEmpty) {
          newContent.add(LanguageModelV3TextPart(text: extracted.text));
        }
      } else {
        newContent.add(part);
      }
    }
    return LanguageModelV3GenerateResult(
      content: newContent,
      finishReason: result.finishReason,
      rawFinishReason: result.rawFinishReason,
      usage: result.usage,
      warnings: result.warnings,
      response: result.response,
      providerMetadata: result.providerMetadata,
    );
  }

  @override
  Future<LanguageModelV3StreamResult> wrapStream({
    required Future<LanguageModelV3StreamResult> Function(
      LanguageModelV3CallOptions options,
    )
    doStream,
    required LanguageModelV3CallOptions options,
    required LanguageModelV3 model,
  }) async {
    final result = await doStream(options);
    final transformedStream = _transformStream(result.stream);
    return LanguageModelV3StreamResult(stream: transformedStream);
  }

  Stream<LanguageModelV3StreamPart> _transformStream(
    Stream<LanguageModelV3StreamPart> source,
  ) async* {
    final openTag = '<$tagName>';
    final closeTag = '</$tagName>';
    final maxTagLen = openTag.length > closeTag.length
        ? openTag.length
        : closeTag.length;
    final buffer = StringBuffer();
    var inReasoning = false;

    await for (final part in source) {
      if (part is StreamPartTextDelta) {
        buffer.write(part.delta);
        var accumulated = buffer.toString();

        if (!inReasoning) {
          final start = accumulated.indexOf(openTag);
          if (start >= 0) {
            final before = accumulated.substring(0, start);
            if (before.isNotEmpty) {
              yield StreamPartTextDelta(id: part.id, delta: before);
            }
            buffer.clear();
            buffer.write(accumulated.substring(start + openTag.length));
            accumulated = buffer.toString();
            inReasoning = true;
          } else {
            final safeEnd = accumulated.length - (maxTagLen - 1);
            if (safeEnd > 0) {
              final safe = accumulated.substring(0, safeEnd);
              yield StreamPartTextDelta(id: part.id, delta: safe);
              buffer.clear();
              buffer.write(accumulated.substring(safeEnd));
            }
          }
        }

        if (inReasoning) {
          final end = accumulated.indexOf(closeTag);
          if (end >= 0) {
            final reasoningChunk = accumulated.substring(0, end);
            if (reasoningChunk.isNotEmpty) {
              yield StreamPartReasoningDelta(delta: reasoningChunk);
            }
            buffer.clear();
            buffer.write(accumulated.substring(end + closeTag.length));
            inReasoning = false;
          } else {
            final safeEnd = accumulated.length - (maxTagLen - 1);
            if (safeEnd > 0) {
              final safe = accumulated.substring(0, safeEnd);
              yield StreamPartReasoningDelta(delta: safe);
              buffer.clear();
              buffer.write(accumulated.substring(safeEnd));
            }
          }
        }
      } else {
        final remaining = buffer.toString();
        if (remaining.isNotEmpty) {
          buffer.clear();
          if (inReasoning) {
            yield StreamPartReasoningDelta(delta: remaining);
          } else {
            yield StreamPartTextDelta(id: 'mw-text', delta: remaining);
          }
        }
        yield part;
      }
    }

    final remaining = buffer.toString();
    if (remaining.isNotEmpty) {
      if (inReasoning) {
        yield StreamPartReasoningDelta(delta: remaining);
      } else {
        yield StreamPartTextDelta(id: 'mw-text', delta: remaining);
      }
    }
  }
}

({String? reasoning, String text}) _extractReasoning(
  String text,
  String tagName,
) {
  final openTag = '<$tagName>';
  final closeTag = '</$tagName>';
  final start = text.indexOf(openTag);
  final end = text.indexOf(closeTag);
  if (start >= 0 && end > start) {
    final reasoning = text.substring(start + openTag.length, end);
    final remaining =
        (text.substring(0, start) + text.substring(end + closeTag.length))
            .trim();
    return (reasoning: reasoning, text: remaining);
  }
  return (reasoning: null, text: text);
}
