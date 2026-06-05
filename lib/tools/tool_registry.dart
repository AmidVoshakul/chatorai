import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tool.dart';

final toolRegistryProvider = Provider<ToolRegistry>((ref) => ToolRegistry());

class ToolRegistry {
  final Map<String, Tool> _tools = {};

  void register(Tool tool) => _tools[tool.name] = tool;

  Tool? get(String name) => _tools[name];

  List<Tool> get all => _tools.values.toList();

  Future<ToolResult> execute(String toolName, Map<String, dynamic> input) async {
    final tool = _tools[toolName];
    if (tool == null) throw ArgumentError('Unknown tool: $toolName');
    // Stub implementation — real tools added later
    return ToolResult(
      toolCallId: '',
      output: 'stub:$toolName',
      isError: false,
    );
  }
}
