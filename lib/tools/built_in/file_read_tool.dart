import '../tool.dart';
import '../tool_registry.dart';

class FileReadTool extends Tool {
  const FileReadTool() : super(name: 'file_read', description: 'Read a file');

  static void register(ToolRegistry registry) {
    registry.register(const FileReadTool());
  }
}
