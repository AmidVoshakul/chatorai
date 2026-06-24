import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;

class ToolContext {
  final String toolCallId;
  final sdk.CancellationToken? abortSignal;
  final String? sessionId;

  final Future<void> Function({
    required String permission,
    required List<String> patterns,
    Map<String, dynamic>? metadata,
    List<String>? always,
  })
  ask;

  final void Function({String? title, Map<String, dynamic>? metadata})?
  onMetadata;

  const ToolContext({
    required this.toolCallId,
    this.abortSignal,
    required this.sessionId,
    required this.ask,
    this.onMetadata,
  });
}

class ToolOutput {
  final String output;
  final Map<String, dynamic>? metadata;
  final String? title;

  const ToolOutput(this.output, {this.metadata, this.title});

  Map<String, dynamic> toJson() => {
    'output': output,
    if (title != null) 'title': title,
    if (metadata != null) 'metadata': metadata,
  };
}

class ToolDef {
  final String id;
  final String description;
  final Map<String, dynamic> inputSchema;
  final Future<ToolOutput> Function(Map<String, dynamic> input, ToolContext ctx)
  execute;

  const ToolDef({
    required this.id,
    required this.description,
    required this.inputSchema,
    required this.execute,
  });
}
