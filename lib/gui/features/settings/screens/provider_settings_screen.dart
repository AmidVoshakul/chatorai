import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/gui/features/settings/screens/provider_settings_actions.dart';
import 'package:chatorai/gui/features/settings/screens/provider_settings_dialogs.dart';
import 'package:chatorai/gui/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/gui/features/settings/widgets/provider_card.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/gui/shared/theme/chatorai_divider.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProviderSettingsScreen extends ConsumerWidget {
  final bool embedded;
  final VoidCallback? onAddProvider;

  const ProviderSettingsScreen({
    super.key,
    this.embedded = false,
    this.onAddProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final configuredProvidersAsync = ref.watch(configuredProvidersProvider);

    final body = configuredProvidersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.errorLoadingProviders)),
      data: (configuredProviders) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(ChatoraiSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.openaiCompatibleApi,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.xxxl,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? ChatoraiColors.pureWhite
                      : ChatoraiColors.pureBlack,
                ),
              ),
              const SizedBox(height: ChatoraiSpacing.xs),
              Text(
                l10n.openaiCompatibleApiDescription,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.base,
                  color: isDark
                      ? ChatoraiColors.darkSecondaryTextColor
                      : ChatoraiColors.secondaryTextColor,
                ),
              ),
              const SizedBox(height: ChatoraiSpacing.xl),
              if (!embedded)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => showAddProviderDialog(context, ref),
                    style: FilledButton.styleFrom(
                      backgroundColor: ChatoraiColors.orange,
                      foregroundColor: ChatoraiColors.pureWhite,
                      padding: const EdgeInsets.symmetric(
                        vertical: ChatoraiSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ChatoraiBorderRadius.sm,
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.addProvider,
                      style: const TextStyle(
                        fontSize: ChatoraiFontSizes.lg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: ChatoraiSpacing.xl),
              if (configuredProviders.isEmpty)
                _buildEmptyState(isDark, l10n)
              else ...[
                const ChatoraiDivider(),
                const SizedBox(height: ChatoraiSpacing.lg),
                ...configuredProviders.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: ChatoraiSpacing.md),
                    child: ProviderCard(
                      providerId: p.id,
                      name: p.name,
                      iconPath: p.iconPath,
                      baseUrl: p.baseUrl,
                      enabled: p.enabled,
                      isDark: isDark,
                      onToggle: () => toggleProvider(
                        ref: ref,
                        providerId: p.id,
                        enabled: !p.enabled,
                      ),
                      onEdit: () => showEditProviderDialog(
                        context: context,
                        ref: ref,
                        providerId: p.id,
                        providerName: p.name,
                        baseUrl: p.baseUrl,
                        apiKey: null,
                      ),
                      onSelectModels: () => showModelSelectionDialog(
                        context: context,
                        ref: ref,
                        providerId: p.id,
                      ),
                      onDelete: () => deleteProvider(
                        context: context,
                        ref: ref,
                        providerId: p.id,
                        providerName: p.name,
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.providers),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(ChatoraiSpacing.xxl),
      decoration: premiumCard(isDark),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.api_outlined,
              size: 48,
              color: isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
            ),
            const SizedBox(height: ChatoraiSpacing.md),
            Text(
              l10n.noProvidersConfigured,
              style: TextStyle(
                fontSize: ChatoraiFontSizes.lg,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? ChatoraiColors.darkTextColor
                    : ChatoraiColors.lightTextColor,
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.xs),
            Text(
              l10n.addProviderToGetStarted,
              style: TextStyle(
                fontSize: ChatoraiFontSizes.base,
                color: isDark
                    ? ChatoraiColors.darkSecondaryTextColor
                    : ChatoraiColors.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
