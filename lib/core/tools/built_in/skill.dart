import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_service.dart';
import 'package:chatorai/core/tools/tool.dart';

ToolDef createSkillTool(
  SkillService skillService,
  List<SkillInfo> availableSkills,
) {
  // Build dynamic description listing available skills
  final skillsList = availableSkills
      .map((s) => '- ${s.name}: ${s.description}')
      .join('\n');

  final description =
      '''Load a specialized skill when the task matches its description. The skill's content will be injected into the conversation history, guiding the model for subsequent tool calls.

Available skills:
$skillsList

To use a skill, provide its exact name in the "name" parameter.''';

  return ToolDef(
    id: 'skill',
    description: description,
    inputSchema: {
      'type': 'object',
      'properties': {
        'name': {
          'type': 'string',
          'description':
              'Name of the skill to load (must be one of the available skills listed above)',
        },
      },
      'required': ['name'],
    },
    execute: (input, ctx) async {
      final name = input['name'] as String?;
      if (name == null) {
        return ToolOutput(
          'Error: skill name is required',
          metadata: {'error': true},
        );
      }

      // Permission check: must have permission for this skill
      await ctx.ask(
        permission: 'skill',
        patterns: ['skill:name=$name'],
        always: ['skill:name=$name'],
      );

      final skill = await skillService.getByName(name);
      if (skill == null) {
        return ToolOutput(
          'Error: skill "$name" not found or access denied',
          metadata: {'error': true, 'not_found': true},
        );
      }

      final filesList = skill.files.isNotEmpty
          ? skill.files.map((f) => '<file>$f</file>').join('\n')
          : '';

      final output =
          '''<skill_content name="${skill.name}">
# Skill: ${skill.name}

${skill.content}

Base directory for this skill: file://${skill.directory}
Relative paths in this skill are relative to this base directory.
Note: file list is sampled (max 10).

<skill_files>
$filesList
</skill_files>
</skill_content>''';

      return ToolOutput(output, metadata: {'skill': true, 'name': skill.name});
    },
  );
}
