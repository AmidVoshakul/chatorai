import 'package:path/path.dart' as p;
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/filesystem_boundary.dart';
import 'package:chatorai/core/workspace/workspace_runtime.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';

ToolDef createExternalDirectoryTool() {
  return ToolDef(
    id: 'external-directory',
    description:
        'Check and request permission for file access outside the project workspace',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {
          'type': 'string',
          'description':
              'Path to check. If blank, returns ok without permission check.',
        },
        'bypass': {
          'type': 'bool',
          'description':
              'When true, skip the external-directory permission gate.',
        },
      },
    },
    execute: (input, ctx) async {
      final target = input['path'] as String?;
      if (target == null || target.isEmpty) {
        return const ToolOutput('ok');
      }

      final bypass = input['bypass'] as bool? ?? false;
      final boundary = FilesystemBoundary(workspace: workspaceRuntimeCurrent);
      final resolution = boundary.resolve(target);

      if (!resolution.isExternal || bypass) {
        return const ToolOutput('ok');
      }

      final patterns = externalDirectoryGlobPatterns(
        p.dirname(resolution.path),
        workspacePath: workspaceRuntimeCurrent.path,
        fallback: resolution.path,
      );
      await ctx.ask(
        permission: 'external_directory',
        patterns: patterns,
        always: patterns,
        metadata: {
          'filepath': resolution.path,
          'parentDir': p.dirname(resolution.path),
          'rule': resolution.externalRule?.name,
        },
      );

      return ToolOutput('ok');
    },
  );
}
