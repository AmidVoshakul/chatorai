import 'dart:io';

import 'package:chatorai/core/config/config_manager.dart';
import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:nocterm/nocterm.dart';

/// Synchronously restores the terminal to a usable state.
///
/// This MUST be called before exiting when we want to guarantee the shell
/// remains responsive. nocterm's own `requestExit` flushes asynchronously,
/// which can lose the cleanup codes on some terminals. By running this sync
/// we ensure the codes hit the terminal before `exit()` terminates the process.
void restoreTerminalSync() {
  try {
    // Restore stdin first (raw mode disrupts echo/line mode)
    if (stdin.hasTerminal) {
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
    // Leave alternate screen buffer (ESC[?1049l)
    stdout.write('\x1b[?1049l');
    // Show cursor (ESC[?25h)
    stdout.write('\x1b[?25h');
    // Reset all attributes (ESC[0m)
    stdout.write('\x1b[0m');
    // Disable mouse tracking (ESC[?1000l, etc.)
    stdout.write('\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l');
    // Synchronous flush – blocks until the codes are written.
    stdout.flush();
  } catch (_) {
    // Best effort – ignore if stdout is already closed.
  }
}

/// Launches the full-screen interactive MCP management TUI.
///
/// Interactive counterpart of `chatorai mcp list`. It reads and reflects the
/// same `chatorai.json` that the GUI and the scriptable CLI subcommands use.
/// Server mutations (enable/disable) toggle the `enabled` flag in that file.
///
/// Pressing `q` or Escape triggers an immediate terminal restore via
/// [restoreTerminalSync] before exiting, so the shell remains usable.
Future<void> runMcpTui({String? configPath}) async {
  await runApp(McpTuiApp(configPath: configPath));
}

class McpTuiApp extends StatefulComponent {
  const McpTuiApp({super.key, this.configPath});

  final String? configPath;

  @override
  State<McpTuiApp> createState() => _McpTuiAppState();
}

class _McpTuiAppState extends State<McpTuiApp> {
  List<String> _serverNames = const [];
  Map<String, McpServerStatus> _statuses = const {};
  Map<String, List<String>> _tools = const {};
  Map<String, bool> _enabled = const {};
  int _selected = 0;
  bool _loading = true;
  bool _toggling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    McpClientService.instance.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final config = await ConfigManager.loadConfig(path: component.configPath);
      final mcp = config.mcp;
      if (mcp == null || mcp.servers.isEmpty) {
        if (!mounted) return;
        setState(() {
          _serverNames = const [];
          _statuses = const {};
          _tools = const {};
          _loading = false;
          _error = null;
          _selected = 0;
        });
        return;
      }
      // Re-read the live file on every refresh: reset the singleton so a
      // previously-initialized service does not serve stale statuses.
      await McpClientService.instance.dispose();
      await McpClientService.instance.initialize(mcp);
      final statuses = McpClientService.instance.getAllStatuses();
      final names = statuses.keys.toList()..sort();
      final enabled = <String, bool>{};
      for (final entry in mcp.servers.entries) {
        enabled[entry.key] = entry.value.enabled;
      }
      final tools = <String, List<String>>{};
      for (final name in names) {
        if (statuses[name]!.status == McpConnectionStatus.connected) {
          final discovered = await McpClientService.instance.listTools(name);
          tools[name] = discovered.map((t) => t.name).toList();
        }
      }
      if (!mounted) return;
      setState(() {
        _serverNames = names;
        _statuses = statuses;
        _tools = tools;
        _enabled = enabled;
        _loading = false;
        _error = null;
        _toggling = false;
        if (_selected >= names.length) _selected = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _marker(McpConnectionStatus status) => switch (status) {
    McpConnectionStatus.connected => '+',
    McpConnectionStatus.disabled => ' ',
    McpConnectionStatus.needsAuth => '~',
    McpConnectionStatus.needsClientRegistration => '~',
    McpConnectionStatus.failed => '!',
  };

  Future<void> _toggleSelected() async {
    if (_serverNames.isEmpty || _toggling) return;
    final name = _serverNames[_selected];
    final current = _enabled[name] ?? true;
    setState(() => _toggling = true);
    try {
      await ConfigWriter.setMcpEnabled(
        name,
        !current,
        configPath: component.configPath,
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _toggling = false;
        _error = e.toString();
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape ||
            event.matches(LogicalKey.keyQ, ctrl: true) ||
            event.character == 'q' ||
            (event.logicalKey == LogicalKey.keyC && event.isControlPressed)) {
          // Exit with synchronous terminal restoration to avoid leaving the shell
          // in a broken state (raw mode, alternate buffer, hidden cursor).
          restoreTerminalSync();
          exit(0);
        }
        if (event.character == 'r') {
          _refresh();
          return true;
        }
        if (event.logicalKey == LogicalKey.space || event.character == ' ') {
          _toggleSelected();
          return true;
        }
        if (_serverNames.isEmpty) return true;
        if (event.logicalKey == LogicalKey.arrowDown) {
          setState(() => _selected = (_selected + 1) % _serverNames.length);
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowUp) {
          setState(
            () => _selected =
                (_selected - 1 + _serverNames.length) % _serverNames.length,
          );
          return true;
        }
        return true;
      },
      child: Container(
        padding: const EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ChatORAI — MCP servers',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (_loading)
              const Text('Loading…')
            else if (_error != null)
              Text('Error: $_error')
            else if (_serverNames.isEmpty)
              const Text('No MCP servers configured.')
            else
              ..._serverNames.asMap().entries.map((entry) {
                final index = entry.key;
                final name = entry.value;
                final status = _statuses[name]!;
                final isSel = index == _selected;
                final tools = _tools[name] ?? const <String>[];
                final line =
                    ' [${_marker(status.status)}] $name'
                    '${status.status == McpConnectionStatus.failed && status.error != null ? '  (${status.error})' : ''}'
                    '${tools.isNotEmpty ? '  tools: ${tools.join(', ')}' : ''}';
                return Text(
                  line,
                  style: TextStyle(
                    reverse: isSel,
                    color: switch (status.status) {
                      McpConnectionStatus.connected => const Color(0x00FF00),
                      McpConnectionStatus.failed => const Color(0xFF0000),
                      _ => null,
                    },
                  ),
                );
              }),
            const Divider(),
            const Text(
              'up/down navigate   space toggle   r refresh   q quit',
              style: TextStyle(fontWeight: FontWeight.dim),
            ),
          ],
        ),
      ),
    );
  }
}
