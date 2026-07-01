// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/stats/stats_service.dart';
import 'package:chatorai/core/llm/providers/built_in_providers.dart';
import 'package:chatorai/shared/utils/xdg_paths_cli.dart';

Future<void> main(List<String> args) async {
  XdgPaths.init();

  if (args.isEmpty) {
    _printMainHelp();
    return;
  }

  final command = args.first;
  final commandArgs = args.skip(1).toList();

  if (command == 'stats') {
    await _runStats(commandArgs);
  } else if (command == 'models') {
    await _runModels(commandArgs);
  } else if (command == '--help' || command == '-h') {
    _printMainHelp();
  } else {
    print('Unknown command: $command');
    _printMainHelp();
  }
}

Future<void> _runStats(List<String> args) async {
  final db = await createFileDatabase();
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

    final toolStats = toolsToShow >= 0 ? stats.toolUsage.take(toolsToShow).toList() : stats.toolUsage;

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
    print(_row('Avg Tokens/Session', stats.avgTokensPerSession.toStringAsFixed(1)));
    print(_row('Median Tokens/Session', stats.medianTokensPerSession.toStringAsFixed(1)));
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
      final maxToolCount =
          displayStats.map((t) => t.count).reduce((a, b) => a > b ? a : b);
      for (final t in displayStats) {
        final pct = totalCalls > 0 ? (t.count / totalCalls * 100) : 0.0;
        final pctStr = pct.toStringAsFixed(1);
        final barLen =
            (t.count / maxToolCount * 20).round();
        final bar = '█' * barLen;
        final rawName = t.toolName;
        final nameSlot = ' ${rawName.length > 18 ? '${rawName.substring(0, 16)}..' : rawName}'.padRight(17);
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


Future<void> _runModels(List<String> args) async {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--raw') continue;
  }

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

  final total = allModels.values.fold<int>(0, (sum, list) => sum + list.length);
  print('');
  print('Total: ${allModels.length} providers, $total models');
}

File? _findSharedPreferences() {
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '/tmp';
  final candidates = [
    File('$home/.local/share/com.chatorai.app/shared_preferences.json'),
    File('${XdgPaths.dataHome}/shared_preferences.json'),
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
      final providerId = key.substring('flutter.catalog_provider_models_'.length);
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
  } catch (_) {}
  return result;
}

Map<String, List<String>> _loadModelsFromBuiltIns() {
  final result = <String, List<String>>{};
  final providers = builtInProviders();
  for (final provider in providers) {
    final ids = provider.models.map((m) => m.id).where((id) => id.isNotEmpty).toList();
    if (ids.isNotEmpty) result[provider.id] = ids;
  }
  return result;
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
  print('  --models          show model statistics');
}

String _row(String label, String value) {
  return '│ ${label.padRight(53 - value.length)} $value │';
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
  print('ChatORAI CLI');
  print('');
  print('Usage: chatorai <command> [options]');
  print('');
  print('Commands:');
  print('  stats           show token usage and cost statistics');
  print('  models          list models by provider');
  print('');
  print('Run `chatorai <command> --help` for more information.');
}
