import 'package:chatorai/core/stats/stats_service.dart';
import 'package:chatorai/gui/features/sessions/providers/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final statsProvider = FutureProvider<SessionStats>((ref) async {
  final db = await ref.watch(sessionDatabaseProvider.future);
  return StatsAggregator(db).aggregate();
});
