import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/features/settings/screens/provider_settings_actions.dart';
import 'package:chatorai/features/settings/screens/provider_settings_dialogs.dart';
import 'package:chatorai/features/settings/widgets/provider_card.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/chatorai_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProviderSettingsScreen extends ConsumerWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final configuredProvidersAsync = ref.watch(configuredProvidersProvider);

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
      body: configuredProvidersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text('Error loading providers')),
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
                      padding: const EdgeInsets.only(
                        bottom: ChatoraiSpacing.md,
                      ),
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
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(ChatoraiSpacing.xxl),
      decoration: BoxDecoration(
        color: isDark ? ChatoraiColors.darkCard : ChatoraiColors.lightCard,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        border: Border.all(
          color: isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder,
        ),
      ),
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
              'No providers configured',
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
              'Add a provider with an API key to get started',
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
