import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/features/settings/presentation/screens/provider_settings_actions.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:chatorai/features/settings/presentation/widgets/add_provider_dialog.dart';
import 'package:chatorai/features/settings/presentation/widgets/model_selection_dialog.dart';

void showAddProviderDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AddProviderDialog(
        onSave: (provider, baseUrl, apiKey) async {
          Navigator.pop(dialogContext);
          await saveProviderConfig(
            ref: ref,
            provider: provider,
            baseUrl: baseUrl,
            apiKey: apiKey,
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
          final settings = ref
              .read(providerSettingsProvider)
              .getSettings(provider.id);
          if (context.mounted) {
            showModelSelectionDialog(
              context: context,
              ref: ref,
              provider: provider,
              settings: settings,
            );
          }
        },
      );
    },
  );
}

void showEditProviderDialog({
  required BuildContext context,
  required WidgetRef ref,
  required AiProvider provider,
  required ProviderSettings settings,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AddProviderDialog(
        initialProvider: provider,
        initialBaseUrl: settings.baseUrl ?? provider.baseUrl,
        initialApiKey: settings.apiKey,
        onSave: (prov, baseUrl, apiKey) {
          Navigator.pop(dialogContext);
          saveProviderConfig(
            ref: ref,
            provider: prov,
            baseUrl: baseUrl,
            apiKey: apiKey,
          );
          SnackbarUtils.showSuccessSnackBar(
            context: context,
            message: '${prov.name} updated',
          );
        },
      );
    },
  );
}

void showModelSelectionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required AiProvider provider,
  required ProviderSettings settings,
}) {
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
