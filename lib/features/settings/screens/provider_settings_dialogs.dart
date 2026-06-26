import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/features/chat/data/providers/models_provider.dart'
    show modelsScreenProvider;
import 'package:chatorai/features/models/providers/model_provider.dart'
    show modelProvider;
import 'package:chatorai/features/settings/screens/provider_settings_actions.dart';
import 'package:chatorai/features/settings/widgets/add_provider_dialog.dart';
import 'package:chatorai/features/settings/widgets/model_selection_dialog.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showAddProviderDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AddProviderDialog(
        onSave: (providerId, baseUrl, apiKey, customConfig) async {
          Navigator.pop(dialogContext);

          // Register custom provider before saving config
          if (customConfig != null) {
            ref
                .read(providerCatalogServiceProvider)
                .addCustomProvider(customConfig);
          }

          await saveProviderConfig(
            ref: ref,
            providerId: providerId,
            baseUrl: baseUrl,
            apiKey: apiKey,
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
          // After saving config, show model selection
          if (context.mounted) {
            showModelSelectionDialog(
              context: context,
              ref: ref,
              providerId: providerId,
            );
          }
        },
      );
    },
  );
}

Future<void> showEditProviderDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String providerId,
  required String providerName,
  required String? baseUrl,
  String? apiKey,
}) async {
  // Fetch API key if not provided
  if (apiKey == null) {
    final catalog = ref.read(providerCatalogServiceProvider);
    apiKey = await catalog.getApiKey(providerId);
  }

  if (!context.mounted) return;

  final dialogContext = context;
  showDialog(
    context: context,
    builder: (builderContext) {
      return AddProviderDialog(
        initialProviderId: providerId,
        initialBaseUrl: baseUrl,
        initialApiKey: apiKey,
        onSave: (provId, newBaseUrl, newApiKey, customConfig) {
          Navigator.pop(builderContext);
          saveProviderConfig(
            ref: ref,
            providerId: provId,
            baseUrl: newBaseUrl,
            apiKey: newApiKey,
          );
          // Use the original context (dialogContext) which is still mounted
          if (dialogContext.mounted) {
            SnackbarUtils.showSuccessSnackBar(
              context: dialogContext,
              message: '$providerName updated',
            );
          }
        },
      );
    },
  );
}

Future<void> showModelSelectionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String providerId,
}) async {
  final catalog = ref.read(providerCatalogServiceProvider);
  final providerConfig = catalog.getProvider(providerId);
  final requiresApiKey = providerConfig?.auth.type != AuthType.none;

  // Check if API key exists
  final hasApiKey = catalog.getApiKeySync(providerId) != null;

  if (requiresApiKey && !hasApiKey) {
    if (context.mounted) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'Please save an API key first',
      );
    }
    return;
  }

  final providerName = providerConfig?.name ?? providerId;
  final baseUrl =
      catalog.getCustomBaseUrl(providerId) ?? providerConfig?.baseUrl ?? '';
  final apiKey = await catalog.getApiKey(providerId);
  final initialSelectedIds = catalog.getSelectedModelIds(providerId);

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return ModelSelectionDialog(
        providerId: providerId,
        baseUrl: baseUrl,
        apiKey: apiKey,
        initialSelectedIds: initialSelectedIds,
        onSave: (selectedIds) async {
          LogTags.settings.logInfo(
            '[ModelSelection] Saved: providerId=$providerId, '
            'selectedIds=[${selectedIds.join(', ')}]',
          );
          final scaffoldContext = context;
          Navigator.pop(dialogContext);
          if (scaffoldContext.mounted) {
            SnackbarUtils.showSuccessSnackBar(
              context: scaffoldContext,
              message:
                  '${selectedIds.length} models selected for $providerName',
            );
          }
          await catalog.setSelectedModelIds(providerId, selectedIds);
          LogTags.settings.logInfo(
            '[ModelSelection] Done setSelectedModelIds, now enabling provider and reloading',
          );
          await catalog.setProviderEnabled(providerId, true);
          await ref
              .read(modelProvider.notifier)
              .resetAndReloadModels(forceRefresh: true);
          ref.invalidate(modelsScreenProvider);
          LogTags.settings.logInfo('[ModelSelection] reloadModels complete');
        },
        catalog: catalog,
      );
    },
  );
}
