import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/core/stats/stats_service.dart';
import 'package:chatorai/features/settings/providers/stats_provider.dart';
import 'package:chatorai/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

class StatsScreen extends ConsumerWidget {
  final bool embedded;

  const StatsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = ref
        .watch(statsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text(localizations.statsError(error.toString()))),
          data: (stats) {
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
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.totalTokens,
                          style: TextStyle(
                            fontSize: ChatoraiFontSizes.lg,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? ChatoraiColors.pureWhite
                                : ChatoraiColors.pureBlack,
                          ),
                        ),
                        const SizedBox(height: ChatoraiSpacing.md),
                        _TokensSection(
                          stats: stats,
                          isDark: isDark,
                          localizations: localizations,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ChatoraiSpacing.lg),
                  if (stats.toolUsage.isNotEmpty)
                    PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.toolUsage,
                            style: TextStyle(
                              fontSize: ChatoraiFontSizes.lg,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? ChatoraiColors.pureWhite
                                  : ChatoraiColors.pureBlack,
                            ),
                          ),
                          const SizedBox(height: ChatoraiSpacing.md),
                          _ToolUsageSection(stats: stats, isDark: isDark),
                        ],
                      ),
                    ),
                  if (stats.toolUsage.isNotEmpty)
                    const SizedBox(height: ChatoraiSpacing.lg),
                  if (stats.modelUsage.isNotEmpty)
                    PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.modelUsage,
                            style: TextStyle(
                              fontSize: ChatoraiFontSizes.lg,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? ChatoraiColors.pureWhite
                                  : ChatoraiColors.pureBlack,
                            ),
                          ),
                          const SizedBox(height: ChatoraiSpacing.md),
                          _ModelUsageSection(
                            stats: stats,
                            isDark: isDark,
                            localizations: localizations,
                          ),
                        ],
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
    return CardGrid(
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: ChatoraiIconSizes.lg,
                color: ChatoraiColors.orange,
              ),
              const SizedBox(height: ChatoraiSpacing.md),
              Text(
                stats.totalSessions.toString(),
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
                localizations.totalSessions,
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
        ),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.message_outlined,
                size: ChatoraiIconSizes.lg,
                color: ChatoraiColors.orange,
              ),
              const SizedBox(height: ChatoraiSpacing.md),
              Text(
                _formatNumber(stats.totalMessages),
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
                localizations.totalMessages,
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
        ),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: ChatoraiIconSizes.lg,
                color: ChatoraiColors.orange,
              ),
              const SizedBox(height: ChatoraiSpacing.md),
              Text(
                stats.days.toString(),
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
                localizations.days,
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
        ),
      ],
    );
  }
}

class _TokensSection extends StatelessWidget {
  final SessionStats stats;
  final bool isDark;
  final AppLocalizations localizations;

  const _TokensSection({
    required this.stats,
    required this.isDark,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = stats.totalTokens;
    final rows = <_TokenRow>[
      _TokenRow(
        label: localizations.statsInput,
        value: tokens.input,
        color: const Color(0xFF4A90D9),
      ),
      _TokenRow(
        label: localizations.statsOutput,
        value: tokens.output,
        color: ChatoraiColors.orange,
      ),
      _TokenRow(
        label: localizations.statsCacheRead,
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
