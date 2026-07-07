import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/filesystem_boundary.dart';
import 'package:chatorai/core/permission/rule.dart';

class SecureFileService {
  final Directory workspace;
  final Map<String, PermissionAction> externalDirectoryRules;

  const SecureFileService({
    required this.workspace,
    this.externalDirectoryRules = const {},
  });

  PathResolution resolve(String userPath) {
    final boundary = FilesystemBoundary(
      workspace: workspace,
      externalDirectoryRules: externalDirectoryRules,
    );
    return boundary.resolve(userPath);
  }

  Future<String> resolveAndAuthorize(
    String userPath,
    ToolContext ctx, {
    String? tool,
  }) async {
    final resolution = resolve(userPath);
    if (resolution.isExternal) {
      await ctx.ask(
        permission: 'external_directory',
        patterns: [resolution.path],
        always: [resolution.path],
        metadata: {
          'filepath': resolution.path,
          'parentDir': p.dirname(resolution.path),
          'tool': ?tool,
        },
      );
    }
    return resolution.path;
  }

  Future<void> authorizeExternalDirs(List<String> dirs, ToolContext ctx) async {
    for (final dir in dirs) {
      final resolution = resolve(dir);
      if (resolution.isExternal) {
        await ctx.ask(
          permission: 'external_directory',
          patterns: [resolution.path],
          always: [resolution.path],
          metadata: {
            'filepath': resolution.path,
            'parentDir': p.dirname(resolution.path),
          },
        );
      }
    }
  }
}
