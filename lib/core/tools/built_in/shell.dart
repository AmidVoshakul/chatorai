import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/tools/filesystem_boundary.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/truncation_service.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/core/permission/arity.dart' as arity;
import 'package:chatorai/core/workspace/workspace_runtime.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';
import 'package:command_shield/command_shield.dart';
import 'package:path/path.dart' as p;

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
};

const _defaultTimeoutMs = 60000;

final _shellValidator = CommandShield(
  defaultSyntax: CommandSyntax.bash,
  policy: PolicySet([
    // Layer 1 — argument-pattern defenses
    // Block numeric octal-mode chmod with special bits (SUID/SGID set) and
    // any three/four digit mode where world-writable (7) or group-writable (2/6/7)
    // bits are set. Covers chmod 4755, 755, 777, 666, 2755 etc.
    ArgumentPatternPolicy(
      pattern: RegExp(r'\bchmod\s+[0-7]{3,4}\b'),
      description: 'chmod with octal mode',
      onMatch: CommandDecision.review,
      level: SecurityLevel.highRisk,
      matchWholeCommand: true,
    ),
    ArgumentPatternPolicy(
      pattern: RegExp(r'(?:>|>>)\s*/+(?:etc|root|sys|proc)/'),
      description: 'redirect to system directory',
      onMatch: CommandDecision.review,
      level: SecurityLevel.critical,
      matchWholeCommand: true,
    ),
    ArgumentPatternPolicy(
      pattern: RegExp(
        r'\b(?:cat|less|more|head|tail|vi|vim|nvim|nano|tail)\s+.*\.env\b',
      ),
      description: 'read sensitive env file',
      onMatch: CommandDecision.review,
      level: SecurityLevel.highRisk,
      matchWholeCommand: true,
    ),

    // Layer 3 — executable blocklist
    // Denies executables that are always unsafe regardless of context or flags.
    // Curl/wget/nc are explicit downloaders / remote shells.
    // eval/exec/source allow arbitrary in-process execution.
    // ssh/scp/rsync open remote channels.
    // GUI browsers allow data exfiltration via opened pages.
    ExecutableBlockListPolicy(
      _blockedExecutables,
      onMatch: CommandDecision.review,
    ),

    // Layer 4 — go package manager (not in blocklist due to space in name)
    ArgumentPatternPolicy(
      pattern: RegExp(r'\bgo\s+(?:get|install)\b'),
      description: 'go get/install package manager',
      onMatch: CommandDecision.review,
      level: SecurityLevel.mediumRisk,
      matchWholeCommand: true,
    ),

    // Layer 5 — risk threshold (never deny, only review)
    _ReviewOnlyPolicy(),
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
  final analysis = _shellValidator.analyze(command);
  final decision = _shellValidator.validate(command).decision;

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

  // Skip /dev/null — harmless redirect target, not a real external access
  final normalized = p.normalize(resolved);
  if (normalized == '/dev/null') return;

  final parent = p.normalize(p.dirname(resolved));
  if (!seen.add(parent)) return;
  if (parent == boundary.workspace.path) return; // workspace-relative, skip

  if (boundary.resolve(parent).isExternal) {
    externalDirs.add(parent);
  }
}

/// Matches chmod octal modes like `755`, `4755`, `777`.
final _chmodModePattern = RegExp(r'^[0-7]{3,4}$');

/// Splits [command] into tokens respecting single/double quotes.
List<String> _tokenizeCommand(String command) {
  final tokens = <String>[];
  final buffer = StringBuffer();
  bool inQuotes = false;
  String quoteChar = '';

  for (var i = 0; i < command.length; i++) {
    final char = command[i];

    if (!inQuotes && (char == '"' || char == "'")) {
      inQuotes = true;
      quoteChar = char;
      buffer.write(char);
    } else if (inQuotes && char == quoteChar) {
      inQuotes = false;
      quoteChar = '';
      buffer.write(char);
    } else if (!inQuotes && char == ' ') {
      if (buffer.isNotEmpty) {
        tokens.add(buffer.toString().trim());
        buffer.clear();
      }
    } else {
      buffer.write(char);
    }
  }

  if (buffer.isNotEmpty) {
    tokens.add(buffer.toString().trim());
  }

  return tokens;
}

/// Returns an arity error message if the command violates the expected
/// argument count from [arity.shellArity], or null if the command is valid.
String? _checkCommandArity(String command) {
  final tokens = _tokenizeCommand(command);
  if (tokens.isEmpty) return null;

  for (var len = tokens.length; len > 0; len--) {
    final prefixStr = tokens.take(len).join(' ');
    final expected = arity.shellArity[prefixStr];
    if (expected != null && tokens.length < expected) {
      final need = expected - tokens.length;
      return 'Arity mismatch: "$prefixStr" expects at least $expected arguments (got ${tokens.length}, missing $need)';
    }
  }

  return null;
}

class _ReviewOnlyPolicy extends CommandPolicy {
  const _ReviewOnlyPolicy();

  @override
  String get name => '_ReviewOnlyPolicy';

  @override
  CommandResult evaluate(CommandAnalysis analysis) {
    // Check security level OR critical/high risk findings
    final hasCriticalFindings = analysis.findings.any(
      (f) => f.level.index >= SecurityLevel.highRisk.index,
    );
    if (analysis.securityLevel.index >= SecurityLevel.mediumRisk.index ||
        hasCriticalFindings) {
      return CommandResult(
        decision: CommandDecision.review,
        securityLevel: analysis.securityLevel,
        findings: analysis.findings,
      );
    }
    return allowResult;
  }
}

/// Rolling output accumulator for streaming shell execution.
///
/// Holds at most [_memoryLimit] bytes in RAM as a rolling preview for the UI.
/// Once total bytes exceed [_diskThreshold], further chunks are spooled to a
/// temp file on disk. The final output is run through [TruncationService] to
/// honour the 50KB truncation policy regardless of total process output size.
///
/// On every chunk, calls [ctx.onMetadata] with the current preview so the UI
/// can update live —  streaming terminal behaviour.
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
      '${Directory.systemTemp.path}/chatorai_shell_${DateTime.now().microsecondsSinceEpoch}.log',
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

ToolDef createShellTool() {
  return ToolDef(
    id: 'shell',
    description:
        'Execute a shell command in the project directory or specified '
        'working directory. Use when you need to run system commands, git '
        'operations, install dependencies, run tests, or perform OS-level '
        'tasks. Large output (>50KB) is truncated — use Read tool with '
        'offset/limit to inspect sections. Dangerous operators (pipes, '
        'redirects, command substitution, command chains) require user '
        'approval. Blocked executables (curl, wget, nc, …) and medium-risk '
        'operations (rm, chmod, npm install, …) prompt for permission; '
        'safe commands run without prompts.',
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

      final arityError = _checkCommandArity(command);
      if (arityError != null) {
        return ToolOutput(
          arityError,
          metadata: {'error': true, 'arity_mismatch': true},
        );
      }

      final timeoutMs = input['timeout'] as int? ?? _defaultTimeoutMs;
      final workingDir = input['working_dir'] as String?;
      final effectiveWorkingDir = workingDir ?? workspaceRuntimeCurrent.path;

      if (workingDir != null) {
        final boundary = FilesystemBoundary(workspace: workspaceRuntimeCurrent);
        final resolution = boundary.resolve(workingDir);
        if (resolution.isExternal) {
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
              'tool': 'shell',
            },
          );
        }
      }

      final preflight = await _analyzeCommand(command, effectiveWorkingDir);

      // External directories always require permission, regardless of decision
      if (preflight.externalDirs.isNotEmpty) {
        final patterns = preflight.externalDirs
            .expand(
              (d) => externalDirectoryGlobPatterns(
                d,
                workspacePath: workspaceRuntimeCurrent.path,
                fallback: d,
              ),
            )
            .toList();
        await ctx.ask(
          permission: 'external_directory',
          patterns: patterns,
          always: patterns,
          metadata: {'command': command, 'directories': preflight.externalDirs},
        );
      }

      final decision = preflight.decision;
      if (decision == CommandDecision.deny) {
        LogTags.permission.logWarning(
          'shellTool: command_shield returned deny, falling back to review',
        );
        // Never deny - convert to review
        final tokens = _tokenizeCommand(command);
        final prefixPattern = arity.prefix(tokens).join(' ');
        final alwaysPattern = '$prefixPattern *';
        try {
          await ctx.ask(
            permission: 'shell',
            patterns: [command],
            always: [alwaysPattern],
            metadata: {'security_level': preflight.decision.name},
          );
        } on PermissionRejectedError catch (_) {
          return ToolOutput(
            'Command rejected by user',
            metadata: {'error': true, 'rejected': true},
          );
        } on PermissionDeniedError catch (_) {
          return ToolOutput(
            'Command denied by permission policy',
            metadata: {'error': true, 'denied': true},
          );
        }
      }
      if (decision == CommandDecision.review) {
        final tokens = _tokenizeCommand(command);
        final prefixPattern = arity.prefix(tokens).join(' ');
        final alwaysPattern = '$prefixPattern *';
        try {
          await ctx.ask(
            permission: 'shell',
            patterns: [command],
            always: [alwaysPattern],
          );
        } on PermissionRejectedError catch (_) {
          return ToolOutput(
            'Command rejected by user',
            metadata: {'error': true, 'rejected': true},
          );
        } on PermissionDeniedError catch (_) {
          return ToolOutput(
            'Command denied by permission policy',
            metadata: {'error': true, 'denied': true},
          );
        }
      }

      if (ctx.abortSignal?.isCancelled ?? false) {
        return ToolOutput(
          'Command aborted before execution',
          metadata: {'error': true, 'aborted': true},
        );
      }

      final truncation = TruncationService.instance;

      LogTags.permission.logInfo(
        'shellTool: START command="$command" timeout=${timeoutMs}ms workingDir=$workingDir',
      );

      try {
        final process = await Process.start(
          'bash',
          ['-c', command],
          runInShell: true,
          workingDirectory: workingDir ?? workspaceRuntimeCurrent.path,
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
          'shellTool: DONE exitCode=$exitCode outputLen=${output.length}',
        );

        return ToolOutput(
          output,
          metadata: {'exit_code': exitCode, if (exitCode != 0) 'error': true},
          title: input['description'] as String?,
        );
      } catch (e) {
        LogTags.permission.logError('shellTool: ERROR $e');
        return ToolOutput(
          'Error executing command: $e',
          metadata: {'error': true},
        );
      }
    },
  );
}
