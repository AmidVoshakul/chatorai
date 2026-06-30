import 'package:chatorai/core/session/database.dart';

class StatsTokens {
  final int input;
  final int output;
  final int reasoning;
  final int cacheRead;
  final int cacheWrite;

  const StatsTokens({
    this.input = 0,
    this.output = 0,
    this.reasoning = 0,
    this.cacheRead = 0,
    this.cacheWrite = 0,
  });

  int get total => input + output + reasoning + cacheRead + cacheWrite;

  StatsTokens copyWith({
    int? input,
    int? output,
    int? reasoning,
    int? cacheRead,
    int? cacheWrite,
  }) => StatsTokens(
    input: input ?? this.input,
    output: output ?? this.output,
    reasoning: reasoning ?? this.reasoning,
    cacheRead: cacheRead ?? this.cacheRead,
    cacheWrite: cacheWrite ?? this.cacheWrite,
  );

  @override
  String toString() =>
      'StatsTokens(total: $total, input: $input, output: $output, reasoning: $reasoning, cacheRead: $cacheRead, cacheWrite: $cacheWrite)';
}

class ToolUsageStat {
  final String toolName;
  final int count;

  const ToolUsageStat({required this.toolName, required this.count});
}

class ModelUsageStat {
  final String? modelRef;
  final StatsTokens tokens;
  final double cost;
  final int messages;

  const ModelUsageStat({
    this.modelRef,
    this.tokens = const StatsTokens(),
    this.cost = 0.0,
    this.messages = 0,
  });
}

class SessionStats {
  final int totalSessions;
  final int totalMessages;
  final int days;
  final double totalCost;
  final double costPerDay;
  final double avgTokensPerSession;
  final double medianTokensPerSession;
  final StatsTokens totalTokens;
  final List<ToolUsageStat> toolUsage;
  final List<ModelUsageStat> modelUsage;

  const SessionStats({
    required this.totalSessions,
    required this.totalMessages,
    required this.days,
    required this.totalCost,
    required this.costPerDay,
    required this.avgTokensPerSession,
    required this.medianTokensPerSession,
    required this.totalTokens,
    required this.toolUsage,
    required this.modelUsage,
  });
}

class StatsAggregator {
  final AppDatabase _db;
  const StatsAggregator(this._db);

  Future<int> _count(String table) async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS c FROM $table')
        .getSingleOrNull();
    return row?.data['c'] ?? 0;
  }

  Future<({DateTime? min, DateTime? max})> _dateRange() async {
    final rows = await _db.select(_db.sessions).get();
    if (rows.isEmpty) return (min: null, max: null);
    final min = rows
        .map((r) => r.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final max = rows
        .map((r) => r.updatedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return (min: min, max: max);
  }

  Future<StatsTokens> _totalTokens() async {
    final rows = await _db.select(_db.sessions).get();
    int input = 0, output = 0, reasoning = 0, cacheRead = 0, cacheWrite = 0;
    for (final r in rows) {
      input += r.tokensInput;
      output += r.tokensOutput;
      reasoning += r.tokensReasoning;
      cacheRead += r.tokensCacheRead;
      cacheWrite += r.tokensCacheWrite;
    }
    return StatsTokens(
      input: input,
      output: output,
      reasoning: reasoning,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
    );
  }

  Future<double> _totalCost() async {
    final rows = await _db.select(_db.sessions).get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.cost);
  }

  Future<List<ToolUsageStat>> _toolUsage() async {
    final rows = await _db
        .customSelect(
          'SELECT tool_name, COUNT(*) AS cnt FROM tool_results GROUP BY tool_name ORDER BY cnt DESC',
        )
        .get();
    return rows
        .map(
          (r) => ToolUsageStat(
            toolName: r.data['tool_name'] as String,
            count: r.data['cnt'] as int,
          ),
        )
        .toList();
  }

  Future<List<ModelUsageStat>> _modelUsage() async {
    final rows = await _db.select(_db.sessions).get();
    final map = <String, ModelUsageStat>{};
    for (final r in rows) {
      final key = r.modelRef ?? 'unknown';
      final existing = map[key];
      final tokens = StatsTokens(
        input: (existing?.tokens.input ?? 0) + r.tokensInput,
        output: (existing?.tokens.output ?? 0) + r.tokensOutput,
        reasoning: (existing?.tokens.reasoning ?? 0) + r.tokensReasoning,
      );
      map[key] = ModelUsageStat(
        modelRef: key,
        tokens: tokens,
        cost: (existing?.cost ?? 0.0) + r.cost,
        messages: (existing?.messages ?? 0) + 1,
      );
    }
    return map.values.toList();
  }

  Future<List<int>> _tokensPerSession() async {
    final rows = await _db.select(_db.sessions).get();
    return rows
        .map((r) => r.tokensInput + r.tokensOutput + r.tokensReasoning)
        .toList();
  }

  double _median(List<int> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<int>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isEven) {
      return (sorted[mid - 1] + sorted[mid]) / 2.0;
    }
    return sorted[mid].toDouble();
  }

  Future<SessionStats> aggregate({int days = 0}) async {
    final sessions = await _count('sessions');
    final messages = await _count('messages');
    final dates = await _dateRange();
    final effectiveDays = dates.max != null && dates.min != null
        ? dates.max!.difference(dates.min!).inDays + 1
        : 1;
    final displayDays = days > 0 ? days : effectiveDays;
    final tokens = await _totalTokens();
    final cost = await _totalCost();
    final toolUsage = await _toolUsage();
    final modelUsage = await _modelUsage();
    final perSession = await _tokensPerSession();
    final avgTokens = sessions > 0 ? tokens.total / sessions : 0.0;
    final medianTokens = _median(perSession);
    final costPerDay = displayDays > 0 ? cost / displayDays : 0.0;

    return SessionStats(
      totalSessions: sessions,
      totalMessages: messages,
      days: displayDays,
      totalCost: cost,
      costPerDay: costPerDay,
      avgTokensPerSession: avgTokens,
      medianTokensPerSession: medianTokens,
      totalTokens: tokens,
      toolUsage: toolUsage,
      modelUsage: modelUsage,
    );
  }
}
