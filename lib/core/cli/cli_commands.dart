// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:chatorai/core/llm/providers/built_in_providers.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/stats/stats_service.dart';
import 'package:chatorai/core/cli/app_version.dart';

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
    print(_row('Avg Tokens/Session',
        stats.avgTokensPerSession.toStringAsFixed(1)));
    print(_row('Median Tokens/Session',
        stats.medianTokensPerSession.toStringAsFixed(1)));
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
      final totalCalls =
          toolStats.fold<int>(0, (sum, t) => sum + t.count);
      final maxToolCount = displayStats.map((t) => t.count).reduce(
            (a, b) => a > b ? a : b,
          );
      for (final t in displayStats) {
        final pct = totalCalls > 0 ? (t.count / totalCalls * 100) : 0.0;
        final pctStr = pct.toStringAsFixed(1);
        final barLen = (t.count / maxToolCount * 20).round();
        final bar = '█' * barLen;
        final rawName = t.toolName;
        final nameSlot = ' ${rawName.length > 18 ? '${rawName.substring(0, 16)}..' : rawName}'
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
  Map<String, List<String>> allModels;
  final prefsFile = _findSharedPreferences();
  if (prefsFile != null && prefsFile.existsSync()) {
    allModels = _loadModelsFromPrefs(prefsFile);
  } else {
    allModels = _loadModelsFromBuiltIns();
  }

  if (allModels.isEmpty) {
    print('No models found.');
    return;
  }

  final entries = allModels.entries.toList();
  entries.sort((a, b) => a.key.compareTo(b.key));
  for (final entry in entries) {
    final models = entry.value;
    models.sort();
    for (final model in models) {
      print(model);
    }
  }

  final total =
      allModels.values.fold<int>(0, (sum, list) => sum + list.length);
  print('');
  print('Total: ${allModels.length} providers, $total models');
}

// -----------------------------------------------------------------------------
// upgrade
// -----------------------------------------------------------------------------

Future<void> _runUpgrade(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUpgradeHelp();
    return;
  }

  if (!Platform.isLinux) {
    print('❌ `chatorai upgrade` is only supported on Linux.');
    print('   On Windows/macOS, re-run the installer or download the latest '
        'release from:');
    print('   https://github.com/AmidVoshakul/chatorai/releases/latest');
    exit(1);
  }

  // Pick the release asset for this architecture.
  var tag = _upgradeTarget(args);
  if (tag == null) {
    tag = await _resolveLatestTag();
    if (tag == null) {
      print('❌ Could not resolve the latest release version.');
      print('   Download a prebuilt release manually from:');
      print('   https://github.com/AmidVoshakul/chatorai/releases');
      exit(1);
    }
  }

  final asset = _linuxTarballName(tag);
  if (asset == null) {
    print('❌ Unsupported architecture: ${_hostArch()}');
    print('   Download a prebuilt release manually from:');
    print('   https://github.com/AmidVoshakul/chatorai/releases');
    exit(1);
  }

  final url = 'https://github.com/AmidVoshakul/chatorai/releases/'
      'download/$tag/$asset';

  print('Downloading $url ...');
  final tmpDir =
      await Directory.systemTemp.createTemp('chatorai_upgrade_');
  final tarball = p.join(tmpDir.path, asset);
  try {
    await _download(url, tarball);

    // Extract to a staging directory (as the current user — never root).
    final stage = p.join(tmpDir.path, 'bundle');
    await Directory(stage).create(recursive: true);
    print('Extracting ...');
    final tar = await Process.run(
      'tar',
      ['-xzf', tarball, '-C', stage],
    );
    if (tar.exitCode != 0) {
      print('❌ Extraction failed:\n${tar.stderr}');
      exit(1);
    }

    // The tarball contains the bundle contents directly; find the dir that
    // holds the `chatorai` executable.
    final bundleRoot = await _findBundleRoot(stage);
    if (bundleRoot == null) {
      print('❌ Could not locate the ChatORAI bundle in the downloaded '
          'archive.');
      exit(1);
    }

    // Install (requires root for the copy step only). Pass arguments directly
    // to sudo (no `bash -c`) to avoid shell expansion / injection.
    print('Installing to /usr/local/lib/chatorai ...');
    final rm =
        await Process.run('sudo', ['rm', '-rf', '/usr/local/lib/chatorai']);
    if (rm.exitCode != 0) {
      print('❌ Installation failed (sudo required):\n${rm.stderr}');
      exit(1);
    }
    final mkdir =
        await Process.run('sudo', ['mkdir', '-p', '/usr/local/lib/chatorai']);
    if (mkdir.exitCode != 0) {
      print('❌ Installation failed (sudo required):\n${mkdir.stderr}');
      exit(1);
    }
    final cp = await Process.run('sudo', [
      'cp',
      '-r',
      '$bundleRoot/.',
      '/usr/local/lib/chatorai/',
    ]);
    if (cp.exitCode != 0) {
      print('❌ Installation failed (sudo required):\n${cp.stderr}');
      exit(1);
    }

    print('✅ ChatORAI upgraded to $tag.');
  } finally {
    await tmpDir.delete(recursive: true).catchError((_) => tmpDir);
  }
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

String _hostArch() => Platform.version.contains('arm64') ||
        Platform.environment['HOSTTYPE'] == 'aarch64'
    ? 'aarch64'
    : 'x64';

/// The release tarball name for the host architecture, or `null` if
/// unsupported. Only x64 is published today. [tag] is the release tag
/// (e.g. `v0.1.0`); the asset is named with the version for traceability.
String? _linuxTarballName(String tag) {
  final arch = _hostArch();
  if (arch == 'x64') return 'chatorai-linux-x64-$tag.tar.gz';
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

/// Walk [stage] to find the directory containing the `chatorai` executable.
Future<String?> _findBundleRoot(String stage) async {
  final direct = File(p.join(stage, 'chatorai'));
  if (await direct.exists()) return stage;
  final dir = Directory(stage);
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

String get _dataHome {
  final home = Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '/tmp';
  // Must match XdgPaths.dataHome (lib/shared/utils/xdg_paths.dart): the GUI
  // stores session data under <xdg-data>/chatorai, where the dir name is the
  // pubspec `name` ("chatorai").
  final base = Platform.environment['XDG_DATA_HOME'] ??
      p.join(home, '.local', 'share');
  return p.join(base, 'chatorai');
}

File? _findSharedPreferences() {
  final home = Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '/tmp';
  final prefsBase = Platform.environment['XDG_DATA_HOME'] ??
      p.join(home, '.local', 'share');
  final candidates = [
    File('$prefsBase/com.chatorai.app/shared_preferences.json'),
  ];
  for (final f in candidates) {
    if (f.existsSync()) return f;
  }
  return null;
}

Map<String, List<String>> _loadModelsFromPrefs(File file) {
  final result = <String, List<String>>{};
  try {
    final raw = file.readAsStringSync();
    final Map<String, dynamic> data = jsonDecode(raw);
    for (final entry in data.entries) {
      final key = entry.key;
      if (!key.startsWith('flutter.catalog_provider_models_')) continue;
      final providerId =
          key.substring('flutter.catalog_provider_models_'.length);
      final value = entry.value;
      if (value is! String) continue;
      final List<dynamic> models = jsonDecode(value);
      final modelIds = <String>[];
      for (final m in models) {
        if (m is! Map<String, dynamic>) continue;
        final providerId = m['providerId'] as String?;
        final modelName = m['modelName'] as String?;
        if (providerId != null &&
            modelName != null &&
            providerId.isNotEmpty &&
            modelName.isNotEmpty) {
          modelIds.add('$providerId/$modelName');
        }
      }
      if (modelIds.isNotEmpty) {
        result[providerId] = modelIds;
      }
    }
  } catch (e) {
    print('Warning: failed to parse shared_preferences: $e');
  }
  return result;
}

Map<String, List<String>> _loadModelsFromBuiltIns() {
  final result = <String, List<String>>{};
  final providers = builtInProviders();
  for (final provider in providers) {
    final ids = provider.models
        .map((m) => m.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isNotEmpty) result[provider.id] = ids;
  }
  return result;
}

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
  print('  -h, --help  show help  [boolean]');
}

void _printStatsHelp() {
  print('Usage: chatorai stats [options]');
  print('');
  print('show token usage and cost statistics');
  print('');
  print('Options:');
  print('  -h, --help        show help');
  print('  --days <number>   show stats for the last N days (default: all time)');
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

void _printMainHelp() {
  print('ChatORAI');
  print('');
  print('Usage: chatorai [command] [options]');
  print('');
  print('Commands:');
  print('  (no args)        launch the ChatORAI GUI');
  print('  stats            show token usage and cost statistics');
  print('  models           list models by provider');
  print('  upgrade [target] download and install the latest (or a specific) '
      'release');
  print('  --version, -v    print version');
  print('  --help, -h       show this help');
  print('');
  print('Run `chatorai <command> --help` for more information.');
}
