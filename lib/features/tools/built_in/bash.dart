import 'dart:io';

import 'package:chatorai/core/permission/arity.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';

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
      if (command == null) throw ArgumentError('command is required');

      final timeout = input['timeout'] as int? ?? 30000;
      final tokens = command.split(RegExp(r'\s+'));
      final prefix = bashPrefix(tokens);
      final pattern = '${prefix.join(' ')} *';

      await ctx.ask(
        permission: 'bash',
        patterns: [pattern],
        always: ['${prefix.join(' ')} *'],
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

        return ToolOutput(truncated, metadata: {'exit_code': exitCode});
      } catch (e) {
        return ToolOutput(
          'Error executing command: $e',
          metadata: {'error': true},
        );
      }
    },
  );
}

List<String> bashPrefix(List<String> tokens) {
  return prefix(tokens);
}
