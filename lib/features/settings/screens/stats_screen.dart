import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/core/stats/stats_service.dart';
import 'package:chatorai/features/sessions/providers/session_providers.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

class StatsScreen extends ConsumerWidget {
  final bool embedded;

  const StatsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = FutureBuilder<SessionStats>(
      future: _loadStats(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(localizations.statsError(snapshot.error.toString())),
          );
        }
        final stats = snapshot.data;
        if (stats == null) {
          return Center(child: Text(localizations.noStatsAvailable));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(ChatoraiSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatCardsRow(
                isDark: isDark,
                stats: stats,
                localizations: localizations,
              ),
              const SizedBox(height: ChatoraiSpacing.xl),
              _PremiumCard(
                isDark: isDark,
                title: localizations.totalTokens,
                child: _TokensSection(stats: stats, isDark: isDark),
              ),
              const SizedBox(height: ChatoraiSpacing.lg),
              if (stats.toolUsage.isNotEmpty)
                _PremiumCard(
                  isDark: isDark,
                  title: localizations.toolUsage,
                  child: _ToolUsageSection(stats: stats, isDark: isDark),
                ),
              if (stats.toolUsage.isNotEmpty)
                const SizedBox(height: ChatoraiSpacing.lg),
              if (stats.modelUsage.isNotEmpty)
                _PremiumCard(
                  isDark: isDark,
                  title: localizations.modelUsage,
                  child: _ModelUsageSection(
                    stats: stats,
                    isDark: isDark,
                    localizations: localizations,
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (embedded) return body;

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
      body: body,
    );
  }

  Future<SessionStats> _loadStats(WidgetRef ref) async {
    final db = await ref.read(sessionDatabaseProvider.future);
    return StatsAggregator(db).aggregate();
  }
}

class _StatCardsRow extends StatelessWidget {
  final bool isDark;
  final SessionStats stats;
  final AppLocalizations localizations;

  const _StatCardsRow({
    required this.isDark,
    required this.stats,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Row(
            children: [
              Expanded(
                child: _StatCard(
                  isDark: isDark,
                  icon: Icons.chat_bubble_outline,
                  label: localizations.totalSessions,
                  value: stats.totalSessions.toString(),
                ),
              ),
              const SizedBox(width: ChatoraiSpacing.md),
              Expanded(
                child: _StatCard(
                  isDark: isDark,
                  icon: Icons.message_outlined,
                  label: localizations.totalMessages,
                  value: _formatNumber(stats.totalMessages),
                ),
              ),
              const SizedBox(width: ChatoraiSpacing.md),
              Expanded(
                child: _StatCard(
                  isDark: isDark,
                  icon: Icons.calendar_today_outlined,
                  label: localizations.days,
                  value: stats.days.toString(),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    isDark: isDark,
                    icon: Icons.chat_bubble_outline,
                    label: localizations.totalSessions,
                    value: stats.totalSessions.toString(),
                  ),
                ),
                const SizedBox(width: ChatoraiSpacing.md),
                Expanded(
                  child: _StatCard(
                    isDark: isDark,
                    icon: Icons.message_outlined,
                    label: localizations.totalMessages,
                    value: _formatNumber(stats.totalMessages),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ChatoraiSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    isDark: isDark,
                    icon: Icons.calendar_today_outlined,
                    label: localizations.days,
                    value: stats.days.toString(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF262626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        border: Border.all(
          color: isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder,
        ),
        boxShadow: isDark
            ? ChatoraiShadows.darkShadow
            : ChatoraiShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: ChatoraiIconSizes.lg, color: ChatoraiColors.orange),
          const SizedBox(height: ChatoraiSpacing.md),
          Text(
            value,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.xxl,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? ChatoraiColors.pureWhite
                  : ChatoraiColors.pureBlack,
              height: 1.1,
            ),
          ),
          const SizedBox(height: ChatoraiSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.sm,
              color: isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget child;

  const _PremiumCard({
    required this.isDark,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : ChatoraiColors.lightCard,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        border: Border.all(
          color: isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder,
        ),
        boxShadow: isDark
            ? ChatoraiShadows.darkShadow
            : ChatoraiShadows.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(ChatoraiSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: ChatoraiFontSizes.lg,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? ChatoraiColors.pureWhite
                    : ChatoraiColors.pureBlack,
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _TokensSection extends StatelessWidget {
  final SessionStats stats;
  final bool isDark;

  const _TokensSection({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = stats.totalTokens;
    final rows = <_TokenRow>[
      _TokenRow(
        label: 'Input',
        value: tokens.input,
        color: const Color(0xFF4A90D9),
      ),
      _TokenRow(
        label: 'Output',
        value: tokens.output,
        color: ChatoraiColors.orange,
      ),
      _TokenRow(
        label: 'Reasoning',
        value: tokens.reasoning,
        color: const Color(0xFF9B59B6),
      ),
      _TokenRow(
        label: 'Cache Read',
        value: tokens.cacheRead,
        color: const Color(0xFF27AE60),
      ),
      _TokenRow(
        label: 'Cache Write',
        value: tokens.cacheWrite,
        color: const Color(0xFFF39C12),
      ),
    ];

    final maxValue = rows
        .map((r) => r.value)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: ChatoraiSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    r.label,
                    style: TextStyle(
                      fontSize: ChatoraiFontSizes.base,
                      color: isDark
                          ? ChatoraiColors.darkSecondaryTextColor
                          : ChatoraiColors.secondaryTextColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDark
                              ? ChatoraiColors.darkInputBorder
                              : ChatoraiColors.inputBorder.withValues(
                                  alpha: 0.3,
                                ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      if (maxValue > 0 && r.value > 0)
                        FractionallySizedBox(
                          widthFactor: (r.value / maxValue).clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  r.color,
                                  r.color.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: ChatoraiSpacing.md),
                SizedBox(
                  width: 80,
                  child: Text(
                    _formatNumber(r.value),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: ChatoraiFontSizes.sm,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? ChatoraiColors.pureWhite
                          : ChatoraiColors.pureBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.md),
        Container(
          height: ChatoraiBorderWidth.thin,
          color: isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder.withValues(alpha: 0.4),
        ),
        const SizedBox(height: ChatoraiSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontSize: ChatoraiFontSizes.base,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? ChatoraiColors.pureWhite
                    : ChatoraiColors.pureBlack,
              ),
            ),
            Text(
              _formatNumber(tokens.total),
              style: TextStyle(
                fontSize: ChatoraiFontSizes.base,
                fontWeight: FontWeight.w700,
                color: ChatoraiColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: ChatoraiSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Cost',
              style: TextStyle(
                fontSize: ChatoraiFontSizes.sm,
                color: isDark
                    ? ChatoraiColors.darkSecondaryTextColor
                    : ChatoraiColors.secondaryTextColor,
              ),
            ),
            Text(
              '\$${stats.totalCost.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: ChatoraiFontSizes.base,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? ChatoraiColors.pureWhite
                    : ChatoraiColors.pureBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: ChatoraiSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avg / day',
              style: TextStyle(
                fontSize: ChatoraiFontSizes.sm,
                color: isDark
                    ? ChatoraiColors.darkSecondaryTextColor
                    : ChatoraiColors.secondaryTextColor,
              ),
            ),
            Text(
              '\$${stats.costPerDay.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: ChatoraiFontSizes.sm,
                color: isDark
                    ? ChatoraiColors.pureWhite
                    : ChatoraiColors.pureBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: ChatoraiSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avg tokens / session',
              style: TextStyle(
                fontSize: ChatoraiFontSizes.sm,
                color: isDark
                    ? ChatoraiColors.darkSecondaryTextColor
                    : ChatoraiColors.secondaryTextColor,
              ),
            ),
            Text(
              _formatNumber(stats.avgTokensPerSession.round()),
              style: TextStyle(
                fontSize: ChatoraiFontSizes.sm,
                color: isDark
                    ? ChatoraiColors.pureWhite
                    : ChatoraiColors.pureBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: ChatoraiSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Median tokens / session',
              style: TextStyle(
                fontSize: ChatoraiFontSizes.sm,
                color: isDark
                    ? ChatoraiColors.darkSecondaryTextColor
                    : ChatoraiColors.secondaryTextColor,
              ),
            ),
            Text(
              _formatNumber(stats.medianTokensPerSession.round()),
              style: TextStyle(
                fontSize: ChatoraiFontSizes.sm,
                color: isDark
                    ? ChatoraiColors.pureWhite
                    : ChatoraiColors.pureBlack,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolUsageSection extends StatelessWidget {
  final SessionStats stats;
  final bool isDark;

  const _ToolUsageSection({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxCount = stats.toolUsage.first.count;
    return Column(
      children: stats.toolUsage.map((t) {
        final width = maxCount > 0 ? (t.count / maxCount) : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: ChatoraiSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  t.toolName,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.sm,
                    color: isDark
                        ? ChatoraiColors.darkSecondaryTextColor
                        : ChatoraiColors.secondaryTextColor,
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark
                            ? ChatoraiColors.darkInputBorder
                            : ChatoraiColors.inputBorder.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: width.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ChatoraiColors.orange, Color(0xFFF5A623)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ChatoraiSpacing.md),
              SizedBox(
                width: 60,
                child: Text(
                  t.count.toString(),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.sm,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ChatoraiColors.pureWhite
                        : ChatoraiColors.pureBlack,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ModelUsageSection extends StatelessWidget {
  final SessionStats stats;
  final bool isDark;
  final AppLocalizations localizations;

  const _ModelUsageSection({
    required this.stats,
    required this.isDark,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: stats.modelUsage.map((m) {
        return Container(
          margin: const EdgeInsets.only(bottom: ChatoraiSpacing.sm),
          padding: const EdgeInsets.all(ChatoraiSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? ChatoraiColors.premiumSurfaceRaised
                : ChatoraiColors.lightCard,
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
            border: Border.all(
              color: isDark
                  ? ChatoraiColors.premiumBorderSoft
                  : ChatoraiColors.inputBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.modelRef ?? 'unknown',
                      style: TextStyle(
                        fontSize: ChatoraiFontSizes.base,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ChatoraiColors.pureWhite
                            : ChatoraiColors.pureBlack,
                      ),
                    ),
                    const SizedBox(height: ChatoraiSpacing.xs),
                    Text(
                      '${_formatNumber(m.tokens.total)} tokens · ${m.messages} msgs · \$${m.cost.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: ChatoraiFontSizes.xs,
                        color: isDark
                            ? ChatoraiColors.darkSecondaryTextColor
                            : ChatoraiColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatNumber(m.tokens.total),
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.sm,
                  fontWeight: FontWeight.w600,
                  color: ChatoraiColors.orange,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TokenRow {
  final String label;
  final int value;
  final Color color;

  const _TokenRow({
    required this.label,
    required this.value,
    required this.color,
  });
}

String _formatNumber(num value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toString();
}
