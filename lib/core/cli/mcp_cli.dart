// ignore_for_file: avoid_print

import 'dart:io';

// ANSI styling helpers for a premium CLI render (shared with other commands).
import 'package:chatorai/core/cli/cli_style.dart' as style;
import 'package:chatorai/core/cli/mcp_tui.dart';
import 'package:chatorai/core/config/config_loader.dart';
import 'package:chatorai/core/config/config_manager.dart';
import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:mcp_dart/mcp_dart.dart';

const _cReset = style.CliStyle.reset;
const _cGray = style.CliStyle.gray;

String _dim(String s) => style.CliStyle.dim_(s);
String _bold(String s) => style.CliStyle.bold_(s);
String _green(String s) => style.CliStyle.green_(s);
String _red(String s) => style.CliStyle.red_(s);
String _yellow(String s) => style.CliStyle.yellow_(s);
String _cyan(String s) => style.CliStyle.cyan_(s);
String _gray(String s) => style.CliStyle.gray_(s);

/// Entry point for `chatorai mcp <subcommand>`.
///
/// This is the scriptable surface of MCP management. The full-screen TUI
/// (added in a later stage) and the GUI pages all read/write the same
/// `chatorai.json`, so what is shown here always reflects that file.
Future<void> runMcp(List<String> args, {String? configPath}) async {
  if (args.isNotEmpty && (args.first == '--help' || args.first == '-h')) {
    _printMcpHelp();
    return;
  }

  final sub = args.isEmpty ? 'tui' : args.first;
  final subArgs = args.skip(1).toList();
  // By default the MCP SDK diagnostics are silenced so `list` stays scriptable.
  // `--print-log` re-enables full transport/protocol logging.
  final printLog = subArgs.contains('--print-log');
  if (!printLog) silenceMcpLogs();

  switch (sub) {
    case 'list':
      await _runList(subArgs, printLog: printLog, configPath: configPath);
    case 'add':
      await _runAdd(subArgs, configPath: configPath);
    case 'remove':
      await _runRemove(subArgs, configPath: configPath);
    case 'enable':
      await _runSetEnabled(subArgs, enabled: true, configPath: configPath);
    case 'disable':
      await _runSetEnabled(subArgs, enabled: false, configPath: configPath);
    case 'tui':
    case 'menu':
      await runMcpTui(configPath: configPath);
    case 'help':
      _printMcpHelp();
    default:
      print('Unknown mcp subcommand: $sub');
      _printMcpHelp();
      exit(1);
  }
}

/// Resolves the on-disk config path to mutate, falling back to the global
/// user config when no explicit [configPath] was supplied.
Future<String> _targetConfigPath({String? configPath}) async {
  if (configPath != null) return configPath;
  return ConfigWriter.resolveConfigPath(global: true);
}

Future<void> _runAdd(List<String> args, {String? configPath}) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printMcpAddHelp();
    return;
  }
  if (args.isEmpty) {
    print('❌ Missing server name.');
    _printMcpAddHelp();
    exit(1);
  }

  final name = args.first;
  final rest = args.skip(1).toList();
  final dashIndex = rest.indexOf('--');
  final flags = dashIndex < 0 ? rest : rest.sublist(0, dashIndex);
  final commandParts = dashIndex < 0 ? <String>[] : rest.sublist(dashIndex + 1);

  String? url;
  var enabled = true;
  int? timeout;
  for (var i = 0; i < flags.length; i++) {
    final flag = flags[i];
    if (flag == '--url' && i + 1 < flags.length) {
      url = flags[++i];
    } else if (flag == '--disabled') {
      enabled = false;
    } else if (flag == '--timeout' && i + 1 < flags.length) {
      timeout = int.tryParse(flags[++i]);
    } else if (flag.startsWith('--url=')) {
      url = flag.substring('--url='.length);
    } else if (flag.startsWith('--timeout=')) {
      timeout = int.tryParse(flag.substring('--timeout='.length));
    } else {
      print('❌ Unknown flag: $flag');
      _printMcpAddHelp();
      exit(1);
    }
  }

  final cfg = url != null
      ? McpServerConfig.remote(url: url, enabled: enabled, timeout: timeout)
      : McpServerConfig.local(
          command: commandParts.isNotEmpty ? commandParts.first : '',
          args: commandParts.skip(1).toList(),
          enabled: enabled,
          timeout: timeout,
        );

  if (cfg.isLocal && cfg.command.isEmpty) {
    print(
      '❌ A local server requires a command: `chatorai mcp add <name> -- <command> [args...]`',
    );
    exit(1);
  }
  if (cfg.isRemote && (cfg.url == null || cfg.url!.isEmpty)) {
    print('❌ A remote server requires --url <url>.');
    exit(1);
  }

  try {
    final path = await _targetConfigPath(configPath: configPath);
    await ConfigWriter.upsertMcpServer(name, cfg, configPath: path);
    print('✅ Added MCP server "$name" (${cfg.isLocal ? 'local' : 'remote'}).');
  } on ConfigValidationError catch (e) {
    print('❌ Invalid server configuration: ${e.message}');
    exit(1);
  }
}

Future<void> _runRemove(List<String> args, {String? configPath}) async {
  if (args.contains('--help') || args.contains('-h') || args.isEmpty) {
    _printMcpRemoveHelp();
    return;
  }
  final name = args.first;
  final path = await _targetConfigPath(configPath: configPath);
  try {
    await ConfigWriter.removeMcpServer(name, configPath: path);
    print('✅ Removed MCP server "$name".');
  } on ConfigValidationError catch (e) {
    print('❌ ${e.message}');
    exit(1);
  }
}

Future<void> _runSetEnabled(
  List<String> args, {
  required bool enabled,
  String? configPath,
}) async {
  if (args.contains('--help') || args.contains('-h') || args.isEmpty) {
    _printMcpEnableHelp(enabled);
    return;
  }
  final name = args.first;
  final path = await _targetConfigPath(configPath: configPath);
  try {
    await ConfigWriter.setMcpEnabled(name, enabled, configPath: path);
    print('✅ ${enabled ? 'Enabled' : 'Disabled'} MCP server "$name".');
  } on ConfigValidationError catch (e) {
    print('❌ ${e.message}');
    exit(1);
  }
}

Future<void> _runList(
  List<String> args, {
  bool printLog = false,
  String? configPath,
}) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printMcpListHelp();
    return;
  }
  if (printLog) {
    print('[mcp] verbose logging enabled');
  }

  ChatOrAIConfig config;
  try {
    config = await ConfigManager.loadConfig(path: configPath);
  } on ConfigValidationError catch (e) {
    print('❌ Invalid chatorai.json: ${e.message}');
    exit(1);
  } on ConfigReadError catch (e) {
    print('❌ Could not read config at ${e.path}: ${e.original}');
    exit(1);
  } catch (e) {
    print('❌ Failed to load config: $e');
    exit(1);
  }

  final mcp = config.mcp;
  if (mcp == null || mcp.servers.isEmpty) {
    print(_dim('No MCP servers configured.'));
    print('');
    print('Add one with:  chatorai mcp add <name> -- <command> [args...]');
    return;
  }

  await McpClientService.instance.initialize(mcp);
  try {
    final statuses = McpClientService.instance.getAllStatuses();
    final names = statuses.keys.toList()..sort();

    final lines = <String>[];
    for (final name in names) {
      final status = statuses[name]!;
      final cfg = mcp.servers[name];

      final (icon, color) = switch (status.status) {
        McpConnectionStatus.connected => ('✓', _green),
        McpConnectionStatus.failed => ('✗', _red),
        McpConnectionStatus.needsAuth => ('~', _yellow),
        McpConnectionStatus.needsClientRegistration => ('~', _yellow),
        McpConnectionStatus.disabled => ('○', _gray),
      };

      final label = cfg?.enabled ?? true ? _bold(name) : _gray(_bold(name));
      lines.add('${_cyan('●')}  ${color(icon)} $label');

      if (cfg != null) {
        final cmd = _commandString(cfg);
        lines.add('$_cGray│$_cReset     ${_dim(cmd)}');
      }

      if (status.status == McpConnectionStatus.failed && status.error != null) {
        lines.add('$_cGray│$_cReset     ${_red(status.error!)}');
      }

      if (status.status == McpConnectionStatus.connected) {
        final tools = await McpClientService.instance.listTools(name);
        if (tools.isNotEmpty) {
          final toolNames = tools.map((t) => _cyan(t.name)).join(', ');
          lines.add('$_cGray│$_cReset     ${_dim('tools:')} $toolNames');
        }
      }
    }

    final header = _bold(_cyan('MCP Servers'));
    final footer = _dim('${names.length} server(s)');
    print('');
    print('$_cGray┌$_cReset $header');
    print('$_cGray│$_cReset');
    for (final line in lines) {
      print(line);
    }
    print('$_cGray└$_cReset $_cGray$footer$_cReset');
    print('');
  } finally {
    await McpClientService.instance.dispose();
  }
}

/// Renders a server's launch command (command + args) as a single string.
String _commandString(McpServerConfig cfg) {
  final cmd = cfg.isLocal ? cfg.command : (cfg.url ?? '');
  if (cfg.isLocal && cfg.args.isNotEmpty) {
    return '$cmd ${cfg.args.join(' ')}';
  }
  return cmd;
}

void _printMcpHelp() {
  print('Usage: chatorai mcp [command] [options]');
  print('');
  print('Manage Model Context Protocol (MCP) servers.');
  print('');
  print('Commands:');
  print('  (no args)       launch the interactive TUI menu');
  print('  list            list configured MCP servers and their status');
  print('  add <name> ...  add a new MCP server');
  print('  remove <name>   remove a MCP server');
  print('  enable <name>   enable an MCP server');
  print('  disable <name>  disable an MCP server');
  print('  help            show this help');
  print('');
  print('Run `chatorai mcp <command> --help` for more information.');
}

void _printMcpListHelp() {
  print('Usage: chatorai mcp list');
  print('');
  print('List configured MCP servers, their connection status, and tools.');
  print('');
  print('Status markers:');
  print('  ✓  connected');
  print('  ~  needs authentication or client registration');
  print('  ✗  failed to start');
  print('  ○  disabled');
}

void _printMcpAddHelp() {
  print('Usage: chatorai mcp add <name> [flags] [-- <command> [args...]]');
  print('');
  print('Add a new MCP server to chatorai.json.');
  print('');
  print('For a local (stdio) server:');
  print('  chatorai mcp add mytool -- /usr/bin/mytool --flag value');
  print('');
  print('For a remote (HTTP/SSE) server:');
  print('  chatorai mcp add myserver --url https://example.com/mcp');
  print('');
  print('Flags:');
  print('  --url <url>        remote server URL (mutually exclusive with --)');
  print('  --disabled         add the server but leave it disabled');
  print('  --timeout <ms>     per-request timeout in milliseconds');
  print('  -h, --help         show this help');
}

void _printMcpRemoveHelp() {
  print('Usage: chatorai mcp remove <name>');
  print('');
  print('Remove the MCP server named <name> from chatorai.json.');
}

void _printMcpEnableHelp(bool enabled) {
  print('Usage: chatorai mcp ${enabled ? 'enable' : 'disable'} <name>');
  print('');
  print(
    '${enabled ? 'Enable' : 'Disable'} the MCP server named <name> '
    'in chatorai.json.',
  );
}
