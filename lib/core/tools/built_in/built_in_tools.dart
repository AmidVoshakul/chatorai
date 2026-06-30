import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/lsp/lsp_service.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/skills/skill_service.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';

import 'apply_patch.dart';
import 'bash.dart';
import 'edit.dart';
import 'external_directory.dart';
import 'format.dart';
import 'glob.dart';
import 'grep.dart';
import 'invalid.dart';
import 'json_schema.dart';
import 'lsp.dart';
import 'plan.dart';
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
  LspService? lspService,
  FormatService? formatService,
  FormatterConfig? formatterConfig,
  SessionRunnerHolder? currentSessionRunner,
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
  registry.register(createExternalDirectoryTool());
  registry.register(createJsonSchemaTool());
  registry.register(createTodoWriteTool());
  // Task tool needs multiple services
  registry.register(
    createTaskTool(
      chatAiService: chatAiService,
      toolRegistry: toolRegistry,
      currentSessionRunner: currentSessionRunner,
    ),
  );

  // Register question tool
  registry.register(createQuestionTool());

  // Register plan exit tool
  registry.register(createPlanExitTool());

  // Register LSP analysis tool
  if (lspService != null) {
    registry.register(createLspTool(lspService));
  }

  if (formatService != null) {
    registry.register(createFormatTool(formatService, formatterConfig));
  }

  // Register skill tool if skillService is provided
  if (skillService != null) {
    final allSkills = await skillService.listAll();
    registry.register(createSkillTool(skillService, allSkills));
  }
}
