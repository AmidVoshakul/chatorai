import 'package:chatorai/core/skills/skill_service.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';

import 'apply_patch.dart';
import 'bash.dart';
import 'edit.dart';
import 'glob.dart';
import 'grep.dart';
import 'invalid.dart';
import 'lsp.dart';
import 'question.dart';
import 'read.dart';
import 'skill.dart';
import 'task.dart';
import 'todowrite.dart';
import 'webfetch.dart';
import 'websearch.dart';
import 'write.dart';

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
  registry.register(createInvalidTool());
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

  // Register LSP analysis tool
  registry.register(createLspTool());

  // Register skill tool if skillService is provided
  if (skillService != null) {
    final allSkills = await skillService.listAll();
    registry.register(createSkillTool(skillService, allSkills));
  }
}
