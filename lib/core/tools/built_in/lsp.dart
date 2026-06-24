import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/truncation_service.dart';

const _defaultTimeout = Duration(seconds: 30);

ToolDef createLspTool() {
  return ToolDef(
    id: 'lsp',
    description:
        'Run Dart static analysis on source files using the Dart analyzer. '
        'Returns structured diagnostics (errors, warnings, hints) for the '
        'specified file or directory. Use when you need to check code quality, '
        'find compilation errors, or validate Dart source files.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'filePath': {
          'type': 'string',
          'description':
              'Path to the Dart file or directory to analyze (relative or absolute)',
        },
        'verbose': {
          'type': 'boolean',
          'description':
              'Include informational hints in output (default: false)',
        },
        'timeout': {
          'type': 'integer',
          'description': 'Timeout in milliseconds (default: 30000)',
        },
      },
      'required': ['filePath'],
    },
    execute: (input, ctx) async {
      final filePath = input['filePath'] as String?;
      if (filePath == null || filePath.isEmpty) {
        return ToolOutput('filePath is required', metadata: {'error': true});
      }

      if (ctx.abortSignal?.isCancelled ?? false) {
        return ToolOutput(
          'Analysis aborted before execution',
          metadata: {'error': true, 'aborted': true},
        );
      }

      final verbose = input['verbose'] as bool? ?? false;
      final timeoutMs =
          input['timeout'] as int? ?? _defaultTimeout.inMilliseconds;

      final entityType = await FileSystemEntity.type(filePath);
      if (entityType == FileSystemEntityType.notFound) {
        return ToolOutput(
          'Path not found: $filePath',
          metadata: {'error': true},
        );
      }

      final truncation = TruncationService.instance;

      try {
        final args = ['analyze', '--fatal-infos', filePath];
        if (verbose) {
          args.remove('--fatal-infos');
        }

        final process = await Process.start(
          'dart',
          args,
          runInShell: true,
          workingDirectory: Directory.current.path,
        );

        Timer? abortTimer;
        if (ctx.abortSignal != null) {
          abortTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
            if (ctx.abortSignal!.isCancelled) {
              process.kill(ProcessSignal.sigterm);
            }
          });
        }

        final stdoutBuffer = StringBuffer();
        final stderrBuffer = StringBuffer();

        await Future.wait([
          process.stdout.transform(utf8.decoder).forEach(stdoutBuffer.write),
          process.stderr.transform(utf8.decoder).forEach(stderrBuffer.write),
        ]);

        abortTimer?.cancel();

        final exitCode = await process.exitCode.timeout(
          Duration(milliseconds: timeoutMs),
          onTimeout: () {
            process.kill(ProcessSignal.sigterm);
            return -1;
          },
        );

        if (ctx.abortSignal?.isCancelled ?? false) {
          return ToolOutput(
            'Analysis aborted',
            metadata: {'error': true, 'aborted': true},
          );
        }

        final stdout = stdoutBuffer.toString();
        final stderr = stderrBuffer.toString();

        final issues = <Map<String, dynamic>>[];
        for (final line in stdout.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          final match = RegExp(
            r'^(.+?):(\d+):(\d+):\s+(error|warning|info)\s*[-–—]\s*(.+)$',
          ).firstMatch(trimmed);

          if (match != null) {
            issues.add({
              'file': match.group(1),
              'line': int.tryParse(match.group(2)!) ?? 0,
              'column': int.tryParse(match.group(3)!) ?? 0,
              'severity': match.group(4),
              'message': match.group(5),
            });
          }
        }

        final errorCount = issues.where((i) => i['severity'] == 'error').length;
        final warningCount = issues
            .where((i) => i['severity'] == 'warning')
            .length;
        final infoCount = issues.where((i) => i['severity'] == 'info').length;

        final result = {
          'exitCode': exitCode,
          'issues': issues,
          'summary': {
            'errors': errorCount,
            'warnings': warningCount,
            'infos': infoCount,
            'total': issues.length,
          },
          'rawOutput': truncation.truncate(stdout),
          if (stderr.isNotEmpty) 'stderr': truncation.truncate(stderr),
        };

        return ToolOutput(
          jsonEncode(result),
          metadata: {
            'filePath': filePath,
            'exitCode': exitCode,
            'errors': errorCount,
            'warnings': warningCount,
            if (exitCode != 0 && errorCount > 0) 'error': true,
          },
          title: 'dart analyze $filePath',
        );
      } catch (e) {
        return ToolOutput(
          'Error running dart analyze: $e',
          metadata: {'error': true},
        );
      }
    },
  );
}
