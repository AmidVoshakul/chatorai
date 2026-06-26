import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/truncation_service.dart';
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
    // This is the primary injection barrier.
    const DangerousCharacterPolicy(
      onMatch: CommandDecision.deny,
      level: SecurityLevel.critical,
    ),

    // Layer 2 — argument-pattern defenses
    // Block numeric octal-mode chmod with special bits (SUID/SGID set) and
    // any three/four digit mode where world-writable (7) or group-writable (2/6/7)
    // bits are set. This covers chmod 4755, 755, 777, 666, 2755 etc.
    // Plain flags like +x/+r/-w and relative refs (+X) are not matched here.
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

CommandDecision _evaluate(String command) =>
    _bashValidator.validate(command).decision;

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

      // Fast-path: banned executables never reach the validator
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

      final decision = _evaluate(command);

      switch (decision) {
        case CommandDecision.deny:
          return ToolOutput(
            'Command blocked by security policy',
            metadata: {'error': true, 'blocked': true},
          );
        case CommandDecision.review:
          await ctx.ask(
            permission: 'bash',
            patterns: [command],
            always: [command],
          );
        case CommandDecision.allow:
          break;
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

        final stdout = StringBuffer();
        final stderr = StringBuffer();

        final stdoutFuture = process.stdout
            .transform(utf8.decoder)
            .forEach(stdout.write);
        final stderrFuture = process.stderr
            .transform(utf8.decoder)
            .forEach(stderr.write);

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
          return ToolOutput(
            'Command aborted',
            metadata: {'error': true, 'aborted': true},
          );
        }

        await stdoutFuture;
        await stderrFuture;

        final rawOutput =
            '${stdout.toString()}${stderr.toString().isNotEmpty ? "\n[stderr]\n${stderr.toString()}" : ""}';
        final output = truncation.truncate(rawOutput);

        LogTags.permission.logInfo(
          'BashTool: DONE exitCode=$exitCode outputLen=${output.length} truncated=${output != rawOutput}',
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
