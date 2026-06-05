class Tool {
  final String name;
  final String description;

  const Tool({
    required this.name,
    required this.description,
  });
}

class ToolCall {
  final String id;
  final String toolName;
  final Map<String, dynamic> input;

  const ToolCall({
    required this.id,
    required this.toolName,
    required this.input,
  });
}

class ToolResult {
  final String toolCallId;
  final String output;
  final bool isError;

  const ToolResult({
    required this.toolCallId,
    required this.output,
    this.isError = false,
  });
}
