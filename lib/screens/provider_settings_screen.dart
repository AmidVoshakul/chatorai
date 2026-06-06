import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/widgets/chat/chatorai_divider.dart';
import 'package:chatorai/widgets/settings/add_provider_dialog.dart';
import 'package:chatorai/widgets/settings/model_selection_dialog.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/utils/snackbar_utils.dart';

class ProviderSettingsScreen extends ConsumerWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsState = ref.watch(providerSettingsProvider);

    // Show providers that have:
    // 1. API key configured, OR
    // 2. Enabled without key (Ollama), OR
    // 3. Have selected models (were configured before, can be re-enabled)
    final configuredProviders = AiProviders.all.where((provider) {
      final settings = settingsState.getSettings(provider.id);
      return (settings.apiKey != null && settings.apiKey!.isNotEmpty) ||
          (!provider.requiresApiKey && settings.enabled) ||
          settings.selectedModelIds.isNotEmpty;
    }).toList();

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
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

                  // Add Provider button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _showAddProviderDialog(context, ref),
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

                  // Configured provider cards
                  if (configuredProviders.isEmpty)
                    _buildEmptyState(isDark, l10n)
                  else ...[
                    const ChatoraiDivider(),
                    const SizedBox(height: ChatoraiSpacing.lg),
                    ...configuredProviders.map((provider) {
                      final settings = settingsState.getSettings(provider.id);
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: ChatoraiSpacing.md,
                        ),
                        child: _buildProviderCard(
                          context: context,
                          ref: ref,
                          provider: provider,
                          settings: settings,
                          isDark: isDark,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  // =========================================================================
  // EMPTY STATE
  // =========================================================================

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

  // =========================================================================
  // PROVIDER CARD
  // =========================================================================

  Widget _buildProviderCard({
    required BuildContext context,
    required WidgetRef ref,
    required AiProvider provider,
    required ProviderSettings settings,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? ChatoraiColors.darkCard : ChatoraiColors.lightCard,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        border: Border.all(
          color: isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProviderIcon(provider, isDark),
              const SizedBox(width: ChatoraiSpacing.sm),
              Expanded(
                child: Text(
                  provider.name,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.lg,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ChatoraiColors.pureWhite
                        : ChatoraiColors.pureBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ChatoraiSpacing.sm),
          Text(
            settings.baseUrl ?? provider.baseUrl,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.caption,
              color: isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ChatoraiSpacing.md),
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    _toggleProvider(ref, provider.id, !settings.enabled),
                behavior: HitTestBehavior.opaque,
                child: Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: settings.enabled,
                    onChanged: (value) =>
                        _toggleProvider(ref, provider.id, value),
                    activeThumbColor: ChatoraiColors.orange,
                    activeTrackColor: ChatoraiColors.orange.withAlpha(150),
                    inactiveThumbColor: isDark
                        ? ChatoraiColors.toggleInactiveThumbDark
                        : ChatoraiColors.toggleInactiveThumbLight,
                    inactiveTrackColor: isDark
                        ? ChatoraiColors.toggleInactiveTrackDark
                        : ChatoraiColors.toggleInactiveTrackLight,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const Spacer(),
              _buildActionButton(
                icon: Icons.edit_outlined,
                isDark: isDark,
                onTap: () =>
                    _showEditProviderDialog(context, ref, provider, settings),
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              _buildActionButton(
                icon: Icons.model_training_outlined,
                isDark: isDark,
                onTap: () =>
                    _showModelSelectionDialog(context, ref, provider, settings),
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              _buildActionButton(
                icon: Icons.delete_outline,
                isDark: isDark,
                isDestructive: true,
                onTap: () => _deleteProvider(context, ref, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final color = onTap == null
        ? (isDark
              ? ChatoraiColors.darkSecondaryTextColor.withAlpha(80)
              : ChatoraiColors.secondaryTextColor.withAlpha(80))
        : isDestructive
        ? ChatoraiColors.error
        : (isDark
              ? ChatoraiColors.darkSecondaryTextColor
              : ChatoraiColors.secondaryTextColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(ChatoraiSpacing.xs + 2),
        child: Icon(icon, size: ChatoraiIconSizes.xl, color: color),
      ),
    );
  }

  Widget _buildProviderIcon(AiProvider provider, bool isDark) {
    final iconColor = isDark
        ? ChatoraiColors.pureWhite
        : ChatoraiColors.pureBlack;
    if (provider.iconPath != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        child: SvgPicture.asset(
          provider.iconPath!,
          width: ChatoraiIconSizes.xxl,
          height: ChatoraiIconSizes.xxl,
        ),
      );
    }
    return Icon(Icons.api, size: ChatoraiIconSizes.xxl, color: iconColor);
  }

  // =========================================================================
  // ACTIONS
  // =========================================================================

  Future<void> _toggleProvider(
    WidgetRef ref,
    String providerId,
    bool enabled,
  ) async {
    // If disabling, check if current model is from this provider
    if (!enabled) {
      final currentModel = ref.read(modelProvider).selectedModelId;
      final isFromThisProvider = _isModelFromProvider(
        currentModel,
        providerId,
        ref,
      );

      if (isFromThisProvider) {
        // Get all selected model IDs from all OTHER enabled providers
        final providerSettings = ref.read(providerSettingsProvider);
        final selectedModelIds = <String>[];
        for (final entry in providerSettings.providers.entries) {
          if (entry.key == providerId) {
            continue;
          }
          if (!entry.value.enabled) continue;
          selectedModelIds.addAll(entry.value.selectedModelIds);
        }

        if (selectedModelIds.isNotEmpty) {
          // Switch to first selected model from other enabled providers
          await ref
              .read(modelProvider.notifier)
              .setSelectedModel(selectedModelIds.first);
        } else {
          // No other selected models, clear selection
          await ref.read(modelProvider.notifier).setSelectedModel('');
        }
      }
    }

    await ref
        .read(providerSettingsProvider.notifier)
        .setProviderEnabled(providerId, enabled);

    await ref.read(modelProvider.notifier).resetAndReloadModels();
  }

  bool _isModelFromProvider(String modelId, String providerId, WidgetRef ref) {
    if (modelId.isEmpty) return false;
    // Check with prefix (e.g., "ollama/model") or without (e.g., "model")
    if (modelId.startsWith('$providerId/')) return true;
    // For Ollama models without prefix, check if it's in the provider's model list
    if (providerId == 'ollama') {
      final settings = ref.read(providerSettingsProvider).getSettings('ollama');
      return settings.selectedModelIds.contains(modelId);
    }
    return false;
  }

  Future<void> _deleteProvider(
    BuildContext context,
    WidgetRef ref,
    AiProvider provider,
  ) async {
    // Show confirmation dialog before deleting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${provider.name}?'),
          content: const Text(
            'This will remove the provider and all its settings. '
            'You will need to add it again to use its models.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final providerId = provider.id;

    // Check if current model was from this provider before deletion
    final currentModel = ref.read(modelProvider).selectedModelId;
    final wasFromThisProvider = currentModel.startsWith('$providerId/');

    await ref
        .read(providerSettingsProvider.notifier)
        .deleteProvider(provider.id);

    // If current model was from deleted provider, switch to another
    if (wasFromThisProvider) {
      final availableModels = ref.read(modelProvider).availableModels;
      if (availableModels.isNotEmpty) {
        await ref
            .read(modelProvider.notifier)
            .setSelectedModel(availableModels.first.id);
      }
    }

    // Reload models to reflect removed provider
    ref.read(modelProvider.notifier).resetAndReloadModels();
  }

  Future<void> _saveProviderConfig(
    WidgetRef ref,
    AiProvider provider,
    String baseUrl,
    String apiKey,
  ) async {
    final notifier = ref.read(providerSettingsProvider.notifier);
    await notifier.setProviderEnabled(provider.id, true);
    if (apiKey.isNotEmpty) await notifier.saveApiKey(provider.id, apiKey);
    if (baseUrl.isNotEmpty) await notifier.saveBaseUrl(provider.id, baseUrl);
    await ref.read(modelProvider.notifier).resetAndReloadModels();
  }

  // =========================================================================
  // DIALOGS
  // =========================================================================

  void _showAddProviderDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AddProviderDialog(
          onSave: (provider, baseUrl, apiKey) async {
            Navigator.pop(dialogContext);
            await _saveProviderConfig(ref, provider, baseUrl, apiKey);
            // Small delay to let state propagate
            await Future<void>.delayed(const Duration(milliseconds: 100));
            // Get fresh settings after save to include any existing selectedModelIds
            final settings = ref
                .read(providerSettingsProvider)
                .getSettings(provider.id);
            if (context.mounted) {
              _showModelSelectionDialog(context, ref, provider, settings);
            }
          },
        );
      },
    );
  }

  void _showEditProviderDialog(
    BuildContext context,
    WidgetRef ref,
    AiProvider provider,
    ProviderSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AddProviderDialog(
          initialProvider: provider,
          initialBaseUrl: settings.baseUrl ?? provider.baseUrl,
          initialApiKey: settings.apiKey,
          onSave: (prov, baseUrl, apiKey) {
            Navigator.pop(dialogContext);
            _saveProviderConfig(ref, prov, baseUrl, apiKey);
            SnackbarUtils.showSuccessSnackBar(
              context: context,
              message: '${prov.name} updated',
            );
          },
        );
      },
    );
  }

  void _showModelSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    AiProvider provider,
    ProviderSettings settings,
  ) {
    // Skip for providers that require API key but don't have it
    if (provider.requiresApiKey && (settings.apiKey?.isEmpty ?? true)) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'Please save an API key first',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return ModelSelectionDialog(
          providerId: provider.id,
          baseUrl: settings.baseUrl ?? provider.baseUrl,
          apiKey: settings.apiKey,
          initialSelectedIds: settings.selectedModelIds,
          onSave: (selectedIds) async {
            final scaffoldContext = context;
            Navigator.pop(dialogContext);
            SnackbarUtils.showSuccessSnackBar(
              context: scaffoldContext,
              message:
                  '${selectedIds.length} models selected for ${provider.name}',
            );
            final notifier = ref.read(providerSettingsProvider.notifier);
            await notifier.setProviderEnabled(provider.id, true);
            await notifier.saveSelectedModelIds(provider.id, selectedIds);
            await ref.read(modelProvider.notifier).resetAndReloadModels();
          },
        );
      },
    );
  }
}
