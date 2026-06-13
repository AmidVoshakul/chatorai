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
import 'question.dart';
import 'skill.dart';

Future<void> registerBuiltInTools(
  ToolRegistry registry, {
  ChatAiService? chatAiService,
  ToolRegistry? toolRegistry,
  SkillService? skillService,
}) async {
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

  // Register question tool
  registry.register(createQuestionTool());

  // Register skill tool if skillService is provided
  if (skillService != null) {
    final allSkills = await skillService.listAll();
    registry.register(createSkillTool(skillService, allSkills));
  }
}
