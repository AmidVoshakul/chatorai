import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/core/stats/stats_service.dart';
import 'package:chatorai/features/chat/data/providers/session_providers.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.usageStatistics),
        centerTitle: true,
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<SessionStats>(
        future: _loadStats(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final stats = snapshot.data;
          if (stats == null) {
            return Center(child: Text(localizations.noStatsAvailable));
          }
          return ListView(
            padding: const EdgeInsets.all(ChatoraiSpacing.lg),
            children: [
              _buildOverviewCard(context, localizations, stats),
              const SizedBox(height: ChatoraiSpacing.lg),
              _buildTokensCard(context, localizations, stats),
              const SizedBox(height: ChatoraiSpacing.lg),
              if (stats.toolUsage.isNotEmpty) ...[
                _buildToolUsageCard(context, localizations, stats),
                const SizedBox(height: ChatoraiSpacing.lg),
              ],
              if (stats.modelUsage.isNotEmpty)
                _buildModelUsageCard(context, localizations, stats),
            ],
          );
        },
      ),
    );
  }

  Future<SessionStats> _loadStats(WidgetRef ref) async {
    final db = await ref.read(sessionDatabaseProvider.future);
    return StatsAggregator(db).aggregate();
  }

  Widget _buildOverviewCard(
    BuildContext context,
    AppLocalizations l10n,
    SessionStats stats,
  ) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.usageStatistics, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _statRow(
              context,
              l10n.totalSessions,
              stats.totalSessions.toString(),
            ),
            _statRow(
              context,
              l10n.totalMessages,
              _formatNumber(stats.totalMessages),
            ),
            _statRow(context, l10n.days, stats.days.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildTokensCard(
    BuildContext context,
    AppLocalizations l10n,
    SessionStats stats,
  ) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.totalTokens, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _statRow(
              context,
              l10n.inputTokens,
              _formatNumber(stats.totalTokens.input),
            ),
            _statRow(
              context,
              l10n.outputTokens,
              _formatNumber(stats.totalTokens.output),
            ),
            _statRow(
              context,
              l10n.reasoningTokens,
              _formatNumber(stats.totalTokens.reasoning),
            ),
            _statRow(
              context,
              l10n.cacheRead,
              _formatNumber(stats.totalTokens.cacheRead),
            ),
            _statRow(
              context,
              l10n.cacheWrite,
              _formatNumber(stats.totalTokens.cacheWrite),
            ),
            const Divider(),
            _statRow(
              context,
              'Total',
              _formatNumber(stats.totalTokens.total),
              bold: true,
            ),
            const SizedBox(height: 8),
            _statRow(
              context,
              l10n.totalCost,
              '\$${stats.totalCost.toStringAsFixed(2)}',
              bold: true,
            ),
            _statRow(
              context,
              l10n.avgCostPerDay,
              '\$${stats.costPerDay.toStringAsFixed(2)}',
            ),
            _statRow(
              context,
              l10n.avgTokensPerSession,
              _formatNumber(stats.avgTokensPerSession.round()),
            ),
            _statRow(
              context,
              l10n.medianTokensPerSession,
              _formatNumber(stats.medianTokensPerSession.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolUsageCard(
    BuildContext context,
    AppLocalizations l10n,
    SessionStats stats,
  ) {
    final theme = Theme.of(context);
    final maxCount = stats.toolUsage.first.count;
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.toolUsage, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...stats.toolUsage.map((t) {
              final width = maxCount > 0 ? (t.count / maxCount) : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        t.toolName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 16,
                            color: theme.dividerColor.withValues(alpha: 0.2),
                          ),
                          FractionallySizedBox(
                            widthFactor: width,
                            child: Container(
                              height: 16,
                              color: ChatoraiColors.orange.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(t.count.toString(), style: theme.textTheme.bodySmall),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModelUsageCard(
    BuildContext context,
    AppLocalizations l10n,
    SessionStats stats,
  ) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.modelUsage, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...stats.modelUsage.map((m) {
              return ListTile(
                dense: true,
                title: Text(m.modelRef ?? 'unknown'),
                subtitle: Text(
                  '${_formatNumber(m.tokens.total)} tokens · ${m.messages} msgs · \$${m.cost.toStringAsFixed(4)}',
                ),
                trailing: Text(
                  _formatNumber(m.tokens.total),
                  style: theme.textTheme.bodySmall,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _statRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}
