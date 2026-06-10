import 'package:chatorai/features/chat/domain/services/chat_ai_service.dart';
import 'package:chatorai/features/tools/data/models/tool_registry.dart';
import 'package:chatorai/features/skills/domain/services/skill_service.dart';
import 'bash.dart';
import 'read.dart';
import 'glob.dart';
import 'grep.dart';
import 'edit.dart';
import 'write.dart';
import 'webfetch.dart';
import 'websearch.dart';
import 'apply_patch.dart';
import 'task.dart';
import 'todo_write.dart';

void registerBuiltInTools(
  ToolRegistry registry, {
  ChatAiService? chatAiService,
  ToolRegistry? toolRegistry,
  SkillService? skillService,
}) {
  registry.register(createBashTool());
  registry.register(createReadTool());
  registry.register(createGlobTool());
  registry.register(createGrepTool());
  registry.register(createEditTool());
  registry.register(createWriteTool());
  registry.register(createWebfetchTool());
  registry.register(createWebsearchTool());
  registry.register(createApplyPatchTool());
  registry.register(createTodoWriteTool());
  // Task tool needs multiple services
  registry.register(
    createTaskTool(
      chatAiService: chatAiService,
      toolRegistry: toolRegistry,
      skillService: skillService,
    ),
  );
}
