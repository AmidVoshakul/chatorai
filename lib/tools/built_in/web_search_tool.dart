import '../tool.dart';
import '../tool_registry.dart';

class WebSearchTool extends Tool {
  const WebSearchTool() : super(name: 'web_search', description: 'Search the web');

  static void register(ToolRegistry registry) {
    registry.register(const WebSearchTool());
  }
}
