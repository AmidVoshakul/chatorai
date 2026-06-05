import '../tool_registry.dart';
import 'web_search_tool.dart';
import 'file_read_tool.dart';

void registerBuiltInTools(ToolRegistry registry) {
  WebSearchTool.register(registry);
  FileReadTool.register(registry);
}
