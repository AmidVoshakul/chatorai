import 'dart:async';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/truncation_service.dart';
import 'package:chatorai/core/tools/filesystem_boundary.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:command_shield/command_shield.dart';

const _blockedExecutables = <String>{
  // Downloaders / network clients — can exfiltrate data
  'curl',
  'curlie',
  'wget',
  'axel',
  'aria2c',
  // Raw network / remote shells
  'nc',
  'ncat',
  'telnet',
  'ssh',
  'scp',
  'sftp',
  'rsync',
  // Text-based browsers / HTTP clients
  'lynx',
  'w3m',
  'links',
  'httpie',
  'xh',
  'http-prompt',
  // GUI browsers (exfil via open page)
  'chrome',
  'firefox',
  'safari',
  // Aliases (bypass allowlists)
  'alias',
  'unalias',
  // Shell escapes / inline execution
  'eval',
  'exec',
  'source',
  // Package manager install operations (write arbitrary code to disk)
  'npm',
  'npx',
  'yarn',
  'pnpm',
  'pip',
  'pip3',
  'cargo',
  'go get',
};

const _defaultTimeoutMs = 60000;

final _bashValidator = CommandShield(
  defaultSyntax: CommandSyntax.bash,
  policy: PolicySet([
    // Layer 1 — raw structural defense
    // Denies commands containing shell control characters in raw text:
    // chains (; && ||), pipes (|), backgrounding (&), redirects (> < >>),
    // command substitution ($() ``), and embedded newlines.
    const DangerousCharacterPolicy(
      onMatch: CommandDecision.deny,
      level: SecurityLevel.critical,
    ),

    // Layer 2 — argument-pattern defenses
    // Block numeric octal-mode chmod with special bits (SUID/SGID set) and
    // any three/four digit mode where world-writable (7) or group-writable (2/6/7)
    // bits are set. Covers chmod 4755, 755, 777, 666, 2755 etc.
    ArgumentPatternPolicy(
      pattern: RegExp(r'\bchmod\s+[0-7]{3,4}\b'),
      description: 'chmod with octal mode',
      onMatch: CommandDecision.deny,
      level: SecurityLevel.highRisk,
      matchWholeCommand: true,
    ),
    ArgumentPatternPolicy(
      pattern: RegExp(r'(?:>|>>)\s+/(etc|root|sys|proc)/'),
      description: 'redirect to system directory',
      onMatch: CommandDecision.deny,
      level: SecurityLevel.critical,
      matchWholeCommand: true,
    ),

    // Layer 3 — executable blocklist
    // Denies executables that are always unsafe regardless of context or flags.
    // Curl/wget/nc are explicit downloaders / remote shells.
    // eval/exec/source allow arbitrary in-process execution.
    // ssh/scp/rsync open remote channels.
    // GUI browsers allow data exfiltration via opened pages.
    ExecutableBlockListPolicy(_blockedExecutables),

    // Layer 4 — risk threshold
    // Any command at mediumRisk or above requires explicit user approval.
    // Catches: rm -rf, chmod 755, mkfs, npm install, git push, etc.
    RiskThresholdPolicy(reviewAt: SecurityLevel.mediumRisk),
  ]),
);

/// Combined result of pre-flight analysis: command_shield policy decision
/// plus any external directories detected from AST path extraction.
class _PreFlightResult {
  final CommandDecision decision;
  final List<String> externalDirs;

  const _PreFlightResult({required this.decision, required this.externalDirs});
}

/// Runs `command_shield.analyze()` once for the AST, extracts file paths, and
/// applies the validator's authoritative policy decision in a single pass.
Future<_PreFlightResult> _analyzeCommand(
  String command,
  String workingDir,
) async {
  final analysis = _bashValidator.analyze(command);
  final decision = _bashValidator.validate(command).decision;

  final invocations = analysis.invocations;
  if (invocations.isEmpty) {
    return _PreFlightResult(decision: decision, externalDirs: const []);
  }

  final boundary = FilesystemBoundary(workspace: Directory(workingDir));
  final externalDirs = <String>{};
  final seen = <String>{};

  for (final inv in invocations) {
    for (final arg in inv.arguments) {
      if (arg.startsWith('-')) continue;
      if (inv.executable == 'chmod' && _chmodModePattern.hasMatch(arg)) {
        continue;
      }
      _scanPath(arg, workingDir, boundary, seen, externalDirs);
    }
    for (final redir in inv.redirections) {
      _scanPath(redir.target, workingDir, boundary, seen, externalDirs);
    }
  }

  return _PreFlightResult(
    decision: decision,
    externalDirs: externalDirs.toList(),
  );
}

/// Expands `$VAR`, `${VAR}`, and `~` in [path].
String _expandEnv(String path) {
  var result = path;
  for (final entry in Platform.environment.entries) {
    result = result.replaceAll('\$${entry.key}', entry.value);
    result = result.replaceAll('\${${entry.key}}', entry.value);
  }
  if (result.startsWith('~')) {
    final home = Platform.environment['HOME'] ?? '';
    result = p.join(home, result.substring(1));
  }
  return result;
}

/// Resolves [path] against [cwd], making it absolute.
String _resolvePath(String path, String cwd) {
  if (p.isAbsolute(path)) return p.normalize(path);
  return p.normalize(p.join(cwd, path));
}

/// Adds [raw] candidate's parent directory to [externalDirs] if external.
void _scanPath(
  String raw,
  String workingDir,
  FilesystemBoundary boundary,
  Set<String> seen,
  Set<String> externalDirs,
) {
  final expanded = _expandEnv(raw);
  if (expanded.isEmpty) return;
  final resolved = _resolvePath(expanded, workingDir);
  if (resolved.isEmpty) return;

  final parent = p.normalize(p.dirname(resolved));
  if (!seen.add(parent)) return;
  if (parent == boundary.workspace.path) return; // workspace-relative, skip

  if (boundary.resolve(parent).isExternal) {
    externalDirs.add(parent);
  }
}

/// Matches chmod octal modes like `755`, `4755`, `777`.
final _chmodModePattern = RegExp(r'^[0-7]{3,4}$');

/// Rolling output accumulator for streaming bash execution.
///
/// Holds at most [_memoryLimit] bytes in RAM as a rolling preview for the UI.
/// Once total bytes exceed [_diskThreshold], further chunks are spooled to a
/// temp file on disk. The final output is run through [TruncationService] to
/// honour the 50KB truncation policy regardless of total process output size.
///
/// On every chunk, calls [ctx.onMetadata] with the current preview so the UI
/// can update live — matching OpenCode's streaming terminal behaviour.
class _StreamingAccumulator {
  static const _diskThreshold = 52428800; // 50MB before disk spool

  final ToolContext ctx;
  final TruncationService truncation;

  final StringBuffer _preview = StringBuffer();
  int _totalBytes = 0;
  String? _tempPath;

  _StreamingAccumulator(this.ctx, this.truncation);

  /// Append a UTF-8 decoded [chunk] of stdout or stderr text.
  ///
  /// Under [_diskThreshold] bytes: accumulates in RAM for live preview.
  /// Beyond that: spools to a temp file to keep memory bounded.
  Future<void> addChunk(String chunk) async {
    _totalBytes += chunk.length;

    if (_tempPath != null) {
      await File(_tempPath!).writeAsString(chunk, mode: FileMode.append);
    } else if (_totalBytes > _diskThreshold) {
      await _startDiskSpool();
      await File(_tempPath!).writeAsString(_preview.toString());
      _preview.clear();
      await File(_tempPath!).writeAsString(chunk);
    } else {
      _preview.write(chunk);
    }

    ctx.onMetadata?.call(metadata: {'output': _preview.toString()});
  }

  Future<void> _startDiskSpool() async {
    final tempFile = File(
      '${Directory.systemTemp.path}/chatorai_bash_${DateTime.now().microsecondsSinceEpoch}.log',
    );
    await tempFile.create(recursive: true);
    _tempPath = tempFile.path;
  }

  /// Final output, applying truncation policy. Cleans up the temp file.
  Future<String> finish() async {
    if (_tempPath != null) {
      try {
        final raw = await File(_tempPath!).readAsString();
        await File(_tempPath!).delete();
        return truncation.truncate(raw);
      } on FileSystemException {
        return _preview.toString();
      }
    }
    return truncation.truncate(_preview.toString());
  }

  void dispose() {
    if (_tempPath != null) {
      File(_tempPath!).delete().ignore();
    }
  }
}

ToolDef createBashTool() {
  return ToolDef(
    id: 'bash',
    description:
        'Execute a shell command in the project directory or specified '
        'working directory. Use when you need to run system commands, git '
        'operations, install dependencies, run tests, or perform OS-level '
        'tasks. Large output (>50KB) is truncated — use Read tool with '
        'offset/limit to inspect sections. Dangerous operators (pipes, '
        'redirects, command substitution, command chains) are hard-blocked. '
        'Blocked executables (curl, wget, nc, …) are denied immediately. '
        'Medium-risk operations (rm, chmod, npm install, …) require '
        'permission; safe commands run without prompts.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'command': {
          'type': 'string',
          'description': 'Shell command to execute',
        },
        'description': {
          'type': 'string',
          'description': 'Human-readable description of the command',
        },
        'timeout': {
          'type': 'integer',
          'description': 'Timeout in milliseconds',
        },
        'working_dir': {
          'type': 'string',
          'description': 'Working directory (default: project root)',
        },
      },
      'required': ['command'],
    },
    execute: (input, ctx) async {
      final command = input['command'] as String?;
      if (command == null || command.isEmpty) {
        return ToolOutput('command is required', metadata: {'error': true});
      }

      if (ctx.abortSignal?.isCancelled ?? false) {
        return ToolOutput(
          'Command aborted before execution',
          metadata: {'error': true, 'aborted': true},
        );
      }

      final timeoutMs = input['timeout'] as int? ?? _defaultTimeoutMs;
      final workingDir = input['working_dir'] as String?;
      final effectiveWorkingDir = workingDir ?? Directory.current.path;

      if (workingDir != null) {
        final boundary = FilesystemBoundary(workspace: Directory.current);
        final resolution = boundary.resolve(workingDir);
        if (resolution.isExternal) {
          await ctx.ask(
            permission: 'external_directory',
            patterns: [resolution.path],
            always: [resolution.path],
            metadata: {
              'filepath': resolution.path,
              'parentDir': p.dirname(resolution.path),
              'tool': 'bash',
            },
          );
        }
      }

      final preflight = await _analyzeCommand(command, effectiveWorkingDir);

      {
        final firstWord = command
            .trim()
            .split(RegExp(r'\s+'))
            .first
            .toLowerCase();
        if (_blockedExecutables.contains(firstWord)) {
          return ToolOutput(
            "command '$firstWord' is not allowed for security reasons",
            metadata: {'error': true, 'blocked': true, 'banned': firstWord},
          );
        }
      }

      final decision = preflight.decision;
      if (decision == CommandDecision.deny) {
        return ToolOutput(
          'Command blocked by security policy',
          metadata: {'error': true, 'blocked': true},
        );
      }
      if (decision == CommandDecision.review) {
        if (preflight.externalDirs.isNotEmpty) {
          await ctx.ask(
            permission: 'external_directory',
            patterns: preflight.externalDirs,
            always: preflight.externalDirs,
            metadata: {
              'command': command,
              'directories': preflight.externalDirs,
            },
          );
        }
        await ctx.ask(
          permission: 'bash',
          patterns: [command],
          always: [command],
        );
      }

      if (ctx.abortSignal?.isCancelled ?? false) {
        return ToolOutput(
          'Command aborted before execution',
          metadata: {'error': true, 'aborted': true},
        );
      }

      final truncation = TruncationService.instance;

      LogTags.permission.logInfo(
        'BashTool: START command="$command" timeout=${timeoutMs}ms workingDir=$workingDir',
      );

      try {
        final process = await Process.start(
          'bash',
          ['-c', command],
          runInShell: true,
          workingDirectory: workingDir ?? Directory.current.path,
        );

        Timer? abortTimer;
        final abortCompleter = Completer<void>();
        if (ctx.abortSignal != null) {
          abortTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
            if (ctx.abortSignal!.isCancelled) {
              process.kill(ProcessSignal.sigterm);
              if (!abortCompleter.isCompleted) {
                abortCompleter.complete();
              }
            }
          });
        }

        final accumulator = _StreamingAccumulator(ctx, truncation);
        final stderrInserted = Completer<void>();

        final stdoutFuture = process.stdout
            .transform(utf8.decoder)
            .forEach(accumulator.addChunk);

        final stderrFuture = process.stderr.transform(utf8.decoder).forEach((
          chunk,
        ) async {
          if (!stderrInserted.isCompleted) {
            await accumulator.addChunk('\n[stderr]\n');
            stderrInserted.complete();
          }
          await accumulator.addChunk(chunk);
        });

        final exitCodeFuture = process.exitCode.timeout(
          Duration(milliseconds: timeoutMs),
          onTimeout: () {
            process.kill(ProcessSignal.sigterm);
            return -1;
          },
        );

        int exitCode;
        if (ctx.abortSignal != null) {
          final abortDone = abortCompleter.future.then((_) => -2);
          final result = await Future.any([exitCodeFuture, abortDone]);
          exitCode = result;
        } else {
          exitCode = await exitCodeFuture;
        }

        abortTimer?.cancel();

        if (ctx.abortSignal?.isCancelled ?? false) {
          accumulator.dispose();
          return ToolOutput(
            'Command aborted',
            metadata: {'error': true, 'aborted': true},
          );
        }

        await stdoutFuture;
        await stderrFuture;

        final output = await accumulator.finish();
        accumulator.dispose();

        LogTags.permission.logInfo(
          'BashTool: DONE exitCode=$exitCode outputLen=${output.length}',
        );

        return ToolOutput(
          output,
          metadata: {'exit_code': exitCode, if (exitCode != 0) 'error': true},
          title: input['description'] as String?,
        );
      } catch (e) {
        LogTags.permission.logError('BashTool: ERROR $e');
        return ToolOutput(
          'Error executing command: $e',
          metadata: {'error': true},
        );
      }
    },
  );
}
