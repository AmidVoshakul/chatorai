// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:chatorai/core/cli/install_paths.dart';
import 'package:chatorai/core/cli/cli_style.dart';
import 'package:chatorai/core/cli/cli_spinner.dart';
import 'package:chatorai/shared/utils/xdg_paths_cli.dart' as xdg;
import 'package:chatorai/core/llm/providers/built_in_providers.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/core/llm/providers/config_provider_parser.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/config/config_manager.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/stats/stats_service.dart';
import 'package:chatorai/core/cli/app_version.dart';
import 'package:chatorai/core/cli/mcp_cli.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single entry point for all non-GUI (CLI) invocations of the `chatorai`
/// binary.
///
/// The compiled GUI binary also embeds this logic: `main.dart` calls
/// [runCliIfRequested] first and returns early when a CLI command is handled,
/// so the Flutter engine never initializes for CLI use.
///
/// Returns `true` when a CLI command was handled (caller must stop and not
/// launch the GUI), `false` otherwise (caller should start the GUI).
Future<bool> runCliIfRequested(List<String> args) async {
  if (args.isEmpty) return false;

  // Ensure user-data paths are resolved for uninstall/upgrade/stats.
  xdg.XdgPaths.init();

  final command = args.first;
  final commandArgs = args.skip(1).toList();

  switch (command) {
    case '--help':
    case '-h':
      _printMainHelp();
      return true;
    case '--version':
    case '-v':
      _printVersion();
      return true;
    case 'stats':
      await _runStats(commandArgs);
      return true;
    case 'models':
      await _runModels(commandArgs);
      return true;
    case 'upgrade':
      await _runUpgrade(commandArgs);
      return true;
    case 'uninstall':
      await _runUninstall(commandArgs);
      return true;
    case 'mcp':
      await runMcp(commandArgs);
      return true;
    default:
      print('Unknown command: $command');
      _printMainHelp();
      return true;
  }
}

// -----------------------------------------------------------------------------
// version
// -----------------------------------------------------------------------------

void _printVersion() {
  print('chatorai $appVersion');
}

// -----------------------------------------------------------------------------
// stats
// -----------------------------------------------------------------------------

Future<void> _runStats(List<String> args) async {
  final db = await createFileDatabase(dataDir: _dataHome);
  try {
    final aggregator = StatsAggregator(db);

    var showHelp = false;
    var daysFilter = 0;
    var toolsToShow = -1;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--help' || arg == '-h') {
        showHelp = true;
      } else if (arg == '--days' && i + 1 < args.length) {
        daysFilter = int.tryParse(args[++i]) ?? 0;
      } else if (arg == '--tools' && i + 1 < args.length) {
        toolsToShow = int.tryParse(args[++i]) ?? -1;
        if (toolsToShow == 0) toolsToShow = -1;
      }
    }

    if (showHelp) {
      _printStatsHelp();
      return;
    }

    final stats = await aggregator.aggregate(days: daysFilter);

    final toolStats = toolsToShow >= 0
        ? stats.toolUsage.take(toolsToShow).toList()
        : stats.toolUsage;

    final cost = stats.totalCost;
    final avgCostPerDay = stats.costPerDay;

    String fmtInt(int v) {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
      return _withCommas(v);
    }

    print('┌────────────────────────────────────────────────────────┐');
    print('│                       OVERVIEW                         │');
    print('├────────────────────────────────────────────────────────┤');
    print(_row('Sessions', stats.totalSessions.toString()));
    print(_row('Messages', fmtInt(stats.totalMessages)));
    print(_row('Days', stats.days.toString()));
    print('└────────────────────────────────────────────────────────┘');
    print('');
    print('┌────────────────────────────────────────────────────────┐');
    print('│                    COST & TOKENS                       │');
    print('├────────────────────────────────────────────────────────┤');
    print(_row('Total Cost', '\$${cost.toStringAsFixed(2)}'));
    print(_row('Avg Cost/Day', '\$${avgCostPerDay.toStringAsFixed(2)}'));
    print(
      _row('Avg Tokens/Session', stats.avgTokensPerSession.toStringAsFixed(1)),
    );
    print(
      _row(
        'Median Tokens/Session',
        stats.medianTokensPerSession.toStringAsFixed(1),
      ),
    );
    print(_row('Input', fmtInt(stats.totalTokens.input)));
    print(_row('Output', fmtInt(stats.totalTokens.output)));
    print(_row('Cache Read', fmtInt(stats.totalTokens.cacheRead)));
    print(_row('Cache Write', fmtInt(stats.totalTokens.cacheWrite)));
    print('└────────────────────────────────────────────────────────┘');

    final displayStats = toolStats;
    if (displayStats.isNotEmpty) {
      print('');
      print('┌────────────────────────────────────────────────────────┐');
      print('│                      TOOL USAGE                        │');
      print('├────────────────────────────────────────────────────────┤');
      final totalCalls = toolStats.fold<int>(0, (sum, t) => sum + t.count);
      final maxToolCount = displayStats
          .map((t) => t.count)
          .reduce((a, b) => a > b ? a : b);
      for (final t in displayStats) {
        final pct = totalCalls > 0 ? (t.count / totalCalls * 100) : 0.0;
        final pctStr = pct.toStringAsFixed(1);
        final barLen = (t.count / maxToolCount * 20).round();
        final bar = '█' * barLen;
        final rawName = t.toolName;
        final nameSlot =
            ' ${rawName.length > 18 ? '${rawName.substring(0, 16)}..' : rawName}'
                .padRight(17);
        final countPadded = t.count.toString().padLeft(4);
        final countArea = '$countPadded ($pctStr%)'.padRight(16);
        final inner = '$nameSlot ${bar.padRight(20)}$countArea';
        final padded = inner.length < 56 ? inner.padRight(56) : inner;
        print('│$padded│');
      }
      print('└────────────────────────────────────────────────────────┘');
    }
  } finally {
    await db.close();
  }
}

// -----------------------------------------------------------------------------
// models
// -----------------------------------------------------------------------------

Future<void> _runModels(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printModelsHelp();
    return;
  }

  // Optional provider filter: --provider <id> (or -p <id>).
  String? providerFilter;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if ((arg == '--provider' || arg == '-p') && i + 1 < args.length) {
      providerFilter = args[++i];
    } else if (arg.startsWith('--provider=')) {
      providerFilter = arg.substring('--provider='.length);
    } else if (arg.startsWith('-p=')) {
      providerFilter = arg.substring('-p='.length);
    }
  }

  // Use the live catalog (same source the GUI uses) so discovered, config and
  // built-in models all appear — not just the shared_preferences cache.
  final catalog = await _buildCatalog();
  final models = catalog.getAllModelsRaw();
  if (models.isEmpty) {
    print('No models found.');
    return;
  }

  final grouped = <String, List<ModelConfig>>{};
  for (final m in models) {
    if (providerFilter != null && m.providerId != providerFilter) continue;
    grouped.putIfAbsent(m.providerId, () => []).add(m);
  }

  if (grouped.isEmpty) {
    print(
      'No models found'
      "${providerFilter != null ? " for provider '$providerFilter'" : ''}.",
    );
    return;
  }

  final entries = grouped.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in entries) {
    final list = entry.value
      ..sort((a, b) => a.modelName.compareTo(b.modelName));
    print('${CliStyle.bold_(entry.key)} (${list.length})');
    for (final m in list) {
      print('  ${m.id}');
    }
    print('');
  }

  final total = grouped.values.fold<int>(0, (sum, l) => sum + l.length);
  print(
    'Total: ${grouped.length} providers, $total models'
    "${providerFilter != null ? " (filtered by '$providerFilter')" : ''}",
  );
}

/// Builds a [ProviderCatalogService] the same way the GUI does, so the CLI
/// sees the same models (built-in + discovered + config-providers from
/// chatorai.json).
Future<ProviderCatalogService> _buildCatalog() async {
  final prefs = await SharedPreferences.getInstance();
  final secureStorage = SecureStorageService();
  await SecureStorageService.init();
  final service = ProviderCatalogService(
    secureStorage: secureStorage,
    prefs: prefs,
    builtInProviders: builtInProviders(),
  );
  await service.migrateFromLegacySettings();
  await service.preloadApiKeys();

  final config = await ConfigManager.loadConfig();
  if (config.provider != null) {
    service.applyConfigProviders(
      const ConfigProviderParser().parse(config.provider),
    );
  }
  return service;
}

void _printModelsHelp() {
  print('chatorai models [options]');
  print('');
  print('List models available from the provider catalog.');
  print('');
  print('Options:');
  print('  -p, --provider <id>  show only models for the given provider');
  print('  -h, --help           show this help');
}

// -----------------------------------------------------------------------------
// upgrade
// -----------------------------------------------------------------------------

Future<void> _runUpgrade(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUpgradeHelp();
    return;
  }

  // Pick the release asset for this architecture.
  var tag = _upgradeTarget(args);
  if (tag == null) {
    tag = await _resolveLatestTag();
    if (tag == null) {
      CliStyle.panelStart('Upgrade');
      CliStyle.line(
        '${CliStyle.red_('✗')} Could not resolve the latest release '
        'version.',
      );
      CliStyle.line('Download a prebuilt release manually from:');
      CliStyle.line(
        CliStyle.cyan_('https://github.com/AmidVoshakul/chatorai/releases'),
      );
      CliStyle.panelEnd('Failed');
      exit(1);
    }
    // Check if already on latest version
    final currentVersion = appVersion;
    final targetVersion = tag.substring(1); // Remove 'v' prefix
    if (currentVersion == targetVersion) {
      CliStyle.panelStart('Upgrade');
      CliStyle.line(
        '${CliStyle.green_('✓')} Already on latest version: '
        '${CliStyle.bold_(currentVersion)}',
      );
      CliStyle.panelEnd('Done');
      return;
    }
  } else {
    // Check if user-specified version matches current
    final targetVersion = tag.substring(1);
    if (appVersion == targetVersion) {
      CliStyle.panelStart('Upgrade');
      CliStyle.line(
        '${CliStyle.green_('✓')} Already on version: '
        '${CliStyle.bold_(targetVersion)}',
      );
      CliStyle.panelEnd('Done');
      return;
    }
  }

  final asset = _releaseAssetName(tag);
  if (asset == null) {
    CliStyle.panelStart('Upgrade');
    CliStyle.line(
      '${CliStyle.red_('✗')} Unsupported platform/architecture: '
      '${Platform.operatingSystem} / ${_hostArch()}',
    );
    CliStyle.panelEnd('Failed');
    exit(1);
  }

  final force =
      args.contains('--force') ||
      args.contains('-f') ||
      args.contains('--yes') ||
      args.contains('--no-confirm');

  CliStyle.panelStart('Upgrade');
  CliStyle.line(
    '${CliStyle.cyan_('●')} '
    '${CliStyle.bold_('From')} ${CliStyle.gray_(appVersion)} '
    '${CliStyle.gray_('→')} ${CliStyle.bold_(tag.substring(1))}',
  );

  final url =
      'https://github.com/AmidVoshakul/chatorai/releases/'
      'download/$tag/$asset';

  final tmpDir = await Directory.systemTemp.createTemp('chatorai_upgrade_');
  final archive = p.join(tmpDir.path, asset);
  try {
    final dl = CliSpinner('Downloading release');
    dl.start();
    try {
      await _download(url, archive);
    } catch (e) {
      dl.fail('download failed');
      CliStyle.line('$e');
      CliStyle.panelEnd('Failed');
      exit(1);
    }
    dl.stop();

    // Extract to a staging directory.
    final stage = p.join(tmpDir.path, 'bundle');
    await Directory(stage).create(recursive: true);
    final ex = CliSpinner('Extracting');
    ex.start();
    final extractOk = await _extractArchive(archive, stage);
    if (!extractOk) {
      ex.fail('extraction failed');
      CliStyle.panelEnd('Failed');
      exit(1);
    }
    ex.stop();

    // Find the bundle root (the dir holding the executable / .app).
    final bundleRoot = await _findBundleRoot(stage);
    if (bundleRoot == null) {
      CliStyle.line(
        '${CliStyle.red_('✗')} Could not locate the ChatORAI '
        'bundle in the archive.',
      );
      CliStyle.panelEnd('Failed');
      exit(1);
    }

    // Confirm install location (no sudo needed — user directory).
    final target = InstallPaths.installDir;
    if (!force) {
      stdout.write(
        '${CliStyle.gray_('│')}  Install to '
        '${CliStyle.bold_(target)}? [y/N] ',
      );
      final confirm = stdin.readLineSync();
      if (confirm?.toLowerCase() != 'y') {
        CliStyle.line('Aborted.');
        CliStyle.panelEnd('Done');
        return;
      }
    }

    final ins = CliSpinner('Installing');
    ins.start();
    final ok = await _installBundle(bundleRoot, target);
    if (!ok) {
      ins.fail('install failed');
      CliStyle.panelEnd('Failed');
      exit(1);
    }
    ins.stop();

    CliStyle.line(
      '${CliStyle.cyan_('◇')} ${CliStyle.green_('Upgrade complete')}',
    );
    CliStyle.panelEnd('Done');
  } finally {
    await tmpDir.delete(recursive: true).catchError((_) => tmpDir);
  }
}

/// Extract [archive] into [stage] for the host platform. Returns true on
/// success.
Future<bool> _extractArchive(String archive, String stage) async {
  if (Platform.isLinux) {
    final tar = await Process.run('tar', ['-xzf', archive, '-C', stage]);
    if (tar.exitCode != 0) {
      stderr.writeln('${tar.stderr}');
      return false;
    }
    return true;
  }
  if (Platform.isWindows) {
    final ps =
        'Expand-Archive -Path "$archive" -DestinationPath "$stage" '
        '-Force';
    final zip = await Process.run('powershell', [
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      ps,
    ]);
    if (zip.exitCode != 0) {
      stderr.writeln('${zip.stderr}');
      return false;
    }
    return true;
  }
  if (Platform.isMacOS) {
    // macOS ships a .dmg: attach, copy the .app out, detach.
    final mount = p.join(p.dirname(stage), 'mount');
    await Directory(mount).create(recursive: true);
    final attach = await Process.run('hdiutil', [
      'attach',
      archive,
      '-nobrowse',
      '-mountpoint',
      mount,
    ]);
    if (attach.exitCode != 0) {
      stderr.writeln('${attach.stderr}');
      return false;
    }
    String? appPath;
    try {
      for (final e in Directory(mount).listSync()) {
        if (e is Directory && e.path.endsWith('.app')) {
          appPath = e.path;
          break;
        }
      }
    } catch (_) {
      appPath = null;
    }
    if (appPath == null) {
      await Process.run('hdiutil', ['detach', mount]);
      return false;
    }
    await Process.run('cp', ['-R', appPath, stage]);
    await Process.run('hdiutil', ['detach', mount]);
    return true;
  }
  return false;
}

/// Copy the extracted bundle into [target] (user directory, no elevation).
Future<bool> _installBundle(String bundleRoot, String target) async {
  try {
    final dir = Directory(target);
    if (await dir.exists()) await dir.delete(recursive: true);
    await Directory(target).create(recursive: true);
    // Copy contents recursively.
    await _copyDirectory(bundleRoot, target);
    // On Linux the launcher lives outside the install dir (on PATH); copy the
    // executable there. On macOS/Windows launcherPath is inside installDir.
    if (Platform.isLinux) {
      final launcher = InstallPaths.launcherPath;
      final launcherDir = p.dirname(launcher);
      await Directory(launcherDir).create(recursive: true);
      await File(p.join(target, 'chatorai')).copy(launcher);
      await Process.run('chmod', ['+x', launcher]);
    } else if (Platform.isMacOS) {
      final launcher = InstallPaths.launcherPath;
      if (await File(launcher).exists()) {
        await Process.run('chmod', ['+x', launcher]);
      }
    }
    return true;
  } catch (e) {
    stderr.writeln('$e');
    return false;
  }
}

/// Recursively copy [source] into [destination].
Future<void> _copyDirectory(String source, String destination) async {
  await for (final entity in Directory(source).list(followLinks: false)) {
    final name = p.basename(entity.path);
    final dest = p.join(destination, name);
    if (entity is Directory) {
      await Directory(dest).create(recursive: true);
      await _copyDirectory(entity.path, dest);
    } else if (entity is File) {
      await File(entity.path).copy(dest);
    }
  }
}

// -----------------------------------------------------------------------------
// uninstall
// -----------------------------------------------------------------------------

class _UninstallTarget {
  const _UninstallTarget({
    required this.label,
    required this.path,
    required this.keep,
  });

  final String label;
  final String path;
  final bool keep;

  bool get exists =>
      FileSystemEntity.typeSync(path, followLinks: false) !=
      FileSystemEntityType.notFound;
}

Future<void> _runUninstall(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUninstallHelp();
    return;
  }

  final keepConfig = args.contains('--keep-config') || args.contains('-c');
  final keepData = args.contains('--keep-data') || args.contains('-d');
  final dryRun = args.contains('--dry-run');
  final force =
      args.contains('--force') || args.contains('-f') || args.contains('--yes');

  // Collect removal targets.
  final targets = <_UninstallTarget>[];

  targets.add(
    _UninstallTarget(
      label: 'Application',
      path: InstallPaths.installDir,
      keep: false,
    ),
  );
  try {
    targets.add(
      _UninstallTarget(
        label: 'Launcher',
        path: InstallPaths.launcherPath,
        keep: false,
      ),
    );
  } on UnsupportedError {
    // platform without a separate launcher
  }
  try {
    targets.add(
      _UninstallTarget(
        label: 'Desktop entry',
        path: InstallPaths.desktopEntryPath,
        keep: false,
      ),
    );
  } on UnsupportedError {
    // not Linux
  }
  try {
    targets.add(
      _UninstallTarget(label: 'Icon', path: InstallPaths.iconPath, keep: false),
    );
  } on UnsupportedError {
    // not Linux
  }
  try {
    targets.add(
      _UninstallTarget(
        label: 'Start Menu shortcut',
        path: InstallPaths.startMenuShortcut,
        keep: false,
      ),
    );
    targets.add(
      _UninstallTarget(
        label: 'Desktop shortcut',
        path: InstallPaths.desktopShortcut,
        keep: false,
      ),
    );
  } on UnsupportedError {
    // not Windows
  }
  targets.add(_UninstallTarget(label: 'Data', path: _dataHome, keep: keepData));
  // SharedPreferences (settings, model cache, AES-encrypted API-key fallback)
  // live under `<dataHome>/com.chatorai.app`, separate from the session DB dir.
  targets.add(
    _UninstallTarget(
      label: 'Preferences',
      path: uninstallPreferencesDir,
      keep: keepData,
    ),
  );
  targets.add(
    _UninstallTarget(label: 'Config', path: _configHome, keep: keepConfig),
  );
  targets.add(_UninstallTarget(label: 'Cache', path: _cacheHome, keep: false));
  targets.add(_UninstallTarget(label: 'State', path: _stateHome, keep: false));

  final header = dryRun ? 'Uninstall (dry run)' : 'Uninstall';
  CliStyle.panelStart(header);

  // Dry run: only show what would be removed.
  if (dryRun) {
    for (final t in targets) {
      if (!t.exists) continue;
      final sizeStr = _formatSize(_directorySize(t.path));
      final mark = t.keep
          ? '${CliStyle.gray_('○')} (keeping)'
          : CliStyle.green_('✓');
      CliStyle.line(
        '$mark ${CliStyle.bold_(t.label)}: '
        '${CliStyle.gray_(t.path)} ${CliStyle.dim_('($sizeStr)')}',
      );
    }
    CliStyle.line(
      '${CliStyle.cyan_('◇')} ${CliStyle.yellow_('Dry run - no changes made')}',
    );
    CliStyle.panelEnd('Done');
    return;
  }

  if (!force) {
    stdout.write(
      '${CliStyle.gray_('│')} Remove ChatORAI and all selected '
      'items? [y/N] ',
    );
    final answer = stdin.readLineSync();
    if (answer?.toLowerCase() != 'y') {
      CliStyle.line('Aborted.');
      CliStyle.panelEnd('Done');
      return;
    }
  }

  final spinner = CliSpinner('Removing');
  spinner.start();
  var failed = false;
  for (final t in targets) {
    if (t.keep || !t.exists) continue;
    try {
      final entity = FileSystemEntity.typeSync(t.path, followLinks: false);
      if (entity == FileSystemEntityType.directory) {
        await Directory(t.path).delete(recursive: true);
      } else if (entity == FileSystemEntityType.file) {
        await File(t.path).delete();
      }
    } catch (e) {
      failed = true;
      stderr.writeln('\n⚠️  Failed to remove ${t.label}: $e');
    }
  }
  spinner.stop(failed ? 'completed with warnings' : 'removed');

  final kept = <String>[];
  if (keepConfig) kept.add('config');
  if (keepData) kept.add('data');
  CliStyle.line(
    '${CliStyle.cyan_('◇')} ${CliStyle.green_('Uninstall complete')}',
  );
  CliStyle.panelEnd(
    kept.isEmpty ? 'All data removed' : 'Kept: ${kept.join(', ')}',
  );
}

int _directorySize(String path) {
  try {
    var total = 0;
    final dir = Directory(path);
    if (!dir.existsSync()) return 0;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += entity.lengthSync();
      }
    }
    return total;
  } catch (_) {
    return 0;
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// Optional positional `target` version for `upgrade`, e.g. `0.1.0` or
/// `v0.1.0`. Ignores flags (anything starting with `-`). Returns the tag form
/// (`vX.Y.Z`) or `null` to mean "latest".
String? _upgradeTarget(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('-')) continue;
    final raw = arg.trim();
    if (raw.isEmpty) continue;
    return raw.startsWith('v') ? raw : 'v$raw';
  }
  return null;
}

/// Resolve the latest published release tag (e.g. `v0.1.0`) via the GitHub
/// API. Returns `null` if the request fails.
Future<String?> _resolveLatestTag() async {
  final client = HttpClient();
  try {
    final uri = Uri.parse(
      'https://api.github.com/repos/AmidVoshakul/chatorai/releases/latest',
    );
    final resp = await client
        .getUrl(uri)
        .then((req) => req.close())
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) return null;
    final body = await resp.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final tag = json['tag_name'] as String?;
    return (tag != null && tag.isNotEmpty) ? tag : null;
  } catch (_) {
    return null;
  } finally {
    client.close();
  }
}

String _hostArch() =>
    Platform.version.contains('arm64') ||
        Platform.environment['HOSTTYPE'] == 'aarch64'
    ? 'aarch64'
    : 'x64';

/// The release asset name for the host platform/architecture, or `null` if
/// unsupported. Only x64 is published today. [tag] is the release tag
/// (e.g. `v0.1.0`); the asset is named with the version for traceability.
String? _releaseAssetName(String tag) {
  final arch = _hostArch();
  if (arch != 'x64') return null;
  if (Platform.isLinux) return 'chatorai-linux-x64-$tag.tar.gz';
  if (Platform.isWindows) return 'chatorai-windows-x64-$tag.zip';
  if (Platform.isMacOS) return 'chatorai-macos-$tag.dmg';
  return null;
}

/// Download [url] to [dest], following redirects.
Future<void> _download(String url, String dest) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 15);
  client.idleTimeout = const Duration(minutes: 5);
  try {
    var uri = Uri.parse(url);
    HttpClientResponse response;
    var redirects = 0;
    while (true) {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      response = await request.close();
      final loc = response.headers.value(HttpHeaders.locationHeader);
      if (response.isRedirect && loc != null && redirects < 10) {
        redirects++;
        uri = uri.resolve(loc);
        await response.drain<void>();
        continue;
      }
      break;
    }
    if (response.statusCode != 200) {
      print('❌ Download failed (HTTP ${response.statusCode}) for $url');
      await response.drain<void>();
      exit(1);
    }
    final file = File(dest);
    final sink = file.openWrite();
    await response.pipe(sink);
  } finally {
    client.close(force: true);
  }
}

/// Walk [stage] to find the directory holding the ChatORAI bundle.
///
/// On macOS this is the `.app` directory (copied out of the mounted DMG);
/// on Linux/Windows it is the directory containing the `chatorai` executable.
Future<String?> _findBundleRoot(String stage) async {
  final dir = Directory(stage);
  if (Platform.isMacOS) {
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is Directory && entity.path.endsWith('.app')) {
        return entity.path;
      }
    }
  }
  final direct = File(p.join(stage, 'chatorai'));
  if (await direct.exists()) return stage;
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File && p.basename(entity.path) == 'chatorai') {
      return p.dirname(entity.path);
    }
  }
  return null;
}

// -----------------------------------------------------------------------------
// shared prefs / model loading
// -----------------------------------------------------------------------------

String get _dataHome => xdg.XdgPaths.dataHome;

/// Directory where `shared_preferences.json` (settings, model cache and the
/// AES-encrypted API-key fallback) is stored. Mirrors the path
/// `shared_preferences` itself uses (`<base>/com.chatorai.app`), which is a
/// sibling of the session DB directory, not a child of it.
String get uninstallPreferencesDir => xdg.XdgPaths.prefsHome;

// -----------------------------------------------------------------------------
// help / formatting
// -----------------------------------------------------------------------------

void _printUpgradeHelp() {
  print('chatorai upgrade [target]');
  print('');
  print('upgrade chatorai to the latest or a specific version');
  print('');
  print('Positionals:');
  print("  target  version to upgrade to, e.g. '0.1.0' or 'v0.1.0'  [string]");
  print('');
  print('Options:');
  print('  -f, --force, --yes  skip confirmation prompt');
  print('  -h, --help          show help');
}

void _printStatsHelp() {
  print('Usage: chatorai stats [options]');
  print('');
  print('show token usage and cost statistics');
  print('');
  print('Options:');
  print('  -h, --help        show help');
  print(
    '  --days <number>   show stats for the last N days (default: all time)',
  );
  print('  --tools <number>  number of tools to show (default: all)');
}

String _row(String label, String value) {
  final pad = 53 - value.length;
  final clamped = pad < 0 ? 0 : pad;
  return '│ ${label.padRight(clamped)} $value │';
}

String _withCommas(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  var count = 0;
  for (var i = s.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
    count++;
  }
  return buffer.toString().split('').reversed.join();
}

String get _configHome => xdg.XdgPaths.configHome;

String get _cacheHome => xdg.XdgPaths.cacheHome;

String get _stateHome => xdg.XdgPaths.stateHome;

void _printUninstallHelp() {
  print('chatorai uninstall [options]');
  print('');
  print('uninstall chatorai from the system and remove all related files');
  print('');
  print('Options:');
  print('  -c, --keep-config  keep configuration files');
  print('  -d, --keep-data    keep session data and snapshots');
  print('      --dry-run      show what would be removed without removing');
  print('  -f, --force, --yes skip confirmation prompts');
  print('  -h, --help         show help');
}

void _printMainHelp() {
  print('ChatORAI');
  print('');
  print('Usage: chatorai [command] [options]');
  print('');
  print('Commands:');
  print('  chatorai (no args)        launch the ChatORAI GUI');
  print('  chatorai stats            show token usage and cost statistics');
  print('  chatorai models           list models by provider');
  print(
    '  chatorai mcp              manage Model Context Protocol (MCP) servers',
  );
  print(
    '  chatorai upgrade [target] download and install the latest (or a specific) '
    'release',
  );
  print(
    '  chatorai uninstall        uninstall chatorai and remove all related files',
  );
  print('');
  print('  --version, -v    print version');
  print('  --help, -h       show this help');
  print('');
  print('Run `chatorai <command> --help` for more information.');
}
