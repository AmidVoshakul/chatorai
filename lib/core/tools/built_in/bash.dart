import 'dart:io';

import 'package:chatorai/core/tools/tool.dart';

ToolDef createBashTool() {
  return ToolDef(
    id: 'bash',
    description: 'Execute a shell command',
    inputSchema: {
      'type': 'object',
      'properties': {
        'command': {
          'type': 'string',
          'description': 'Shell command to execute',
        },
        'description': {
          'type': 'string',
          'description': 'Human-readable description',
        },
        'timeout': {
          'type': 'integer',
          'description': 'Timeout in milliseconds',
        },
      },
      'required': ['command'],
    },
    execute: (input, ctx) async {
      final command = input['command'] as String?;
      if (command == null || command.isEmpty) {
        return ToolOutput('command is required', metadata: {'error': true});
      }

      final timeout = input['timeout'] as int? ?? 30000;

      await ctx.ask(
        permission: 'bash',
        patterns: ['bash:command=$command'],
        always: ['bash:command=$command'],
      );

      try {
        final process = await Process.start(
          'bash',
          ['-c', command],
          runInShell: true,
          workingDirectory: Directory.current.path,
        );

        final stdout = StringBuffer();
        final stderr = StringBuffer();

        final stdoutFuture = process.stdout
            .transform(SystemEncoding().decoder)
            .forEach(stdout.write);
        final stderrFuture = process.stderr
            .transform(SystemEncoding().decoder)
            .forEach(stderr.write);

        final exitCode = await process.exitCode.timeout(
          Duration(milliseconds: timeout),
          onTimeout: () {
            process.kill(ProcessSignal.sigterm);
            return -1;
          },
        );

        await stdoutFuture;
        await stderrFuture;

        final output =
            '${stdout.toString()}${stderr.toString().isNotEmpty ? "\n[stderr]\n${stderr.toString()}" : ""}';
        final truncated = output.length > 50000
            ? '${output.substring(0, 50000)}\n... (truncated)'
            : output;

        return ToolOutput(
          truncated,
          metadata: {'exit_code': exitCode, if (exitCode != 0) 'error': true},
        );
      } catch (e) {
        return ToolOutput(
          'Error executing command: $e',
          metadata: {'error': true},
        );
      }
    },
  );
}
