import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/features/chat/data/providers/models_provider.dart';
import 'package:chatorai/features/models/providers/model_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> toggleProvider({
  required WidgetRef ref,
  required String providerId,
  required bool enabled,
}) async {
  final catalog = ref.read(providerCatalogServiceProvider);

  if (!enabled) {
    final currentModel = ref.read(modelProvider).selectedModelId;
    final isFromThisProvider = _isModelFromProvider(
      currentModel,
      providerId,
      ref,
    );

    if (isFromThisProvider) {
      final allProviders = catalog.getAllProvidersRaw();
      final selectedModelIds = <String>[];
      for (final p in allProviders) {
        if (p.id == providerId) continue;
        if (!catalog.isProviderEnabled(p.id)) continue;
        selectedModelIds.addAll(catalog.getSelectedModelIds(p.id));
      }

      if (selectedModelIds.isNotEmpty) {
        await ref
            .read(modelProvider.notifier)
            .setSelectedModel(selectedModelIds.first);
      } else {
        await ref.read(modelProvider.notifier).setSelectedModel('');
      }
    }
  }

  await catalog.setProviderEnabled(providerId, enabled);
  await ref.read(modelProvider.notifier).resetAndReloadModels();
  ref.invalidate(configuredProvidersProvider);
  ref.invalidate(modelsScreenProvider);
}

bool _isModelFromProvider(String modelId, String providerId, WidgetRef ref) {
  if (modelId.isEmpty) return false;
  if (modelId.startsWith('$providerId/')) return true;
  if (providerId == 'ollama') {
    final catalog = ref.read(providerCatalogServiceProvider);
    return catalog.getSelectedModelIds('ollama').contains(modelId);
  }
  return false;
}

Future<bool> deleteProvider({
  required BuildContext context,
  required WidgetRef ref,
  required String providerId,
  required String providerName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Delete $providerName?'),
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

  if (confirmed != true) return false;

  final currentModel = ref.read(modelProvider).selectedModelId;
  final wasFromThisProvider = currentModel.startsWith('$providerId/');

  final catalog = ref.read(providerCatalogServiceProvider);
  await catalog.deleteApiKey(providerId);
  await catalog.clearSelectedModelIds(providerId);
  await catalog.setProviderEnabled(providerId, false);

  if (wasFromThisProvider) {
    final availableModels = ref.read(modelProvider).availableModels;
    if (availableModels.isNotEmpty) {
      await ref
          .read(modelProvider.notifier)
          .setSelectedModel(availableModels.first.id);
    }
  }

  ref.read(modelProvider.notifier).resetAndReloadModels();
  ref.invalidate(configuredProvidersProvider);
  ref.invalidate(modelsScreenProvider);
  return true;
}

Future<void> saveProviderConfig({
  required WidgetRef ref,
  required String providerId,
  required String baseUrl,
  required String apiKey,
}) async {
  final catalog = ref.read(providerCatalogServiceProvider);
  await catalog.setProviderEnabled(providerId, true);
  if (apiKey.isNotEmpty) await catalog.setApiKey(providerId, apiKey);
  if (baseUrl.isNotEmpty) await catalog.setCustomBaseUrl(providerId, baseUrl);

  await ref.read(modelProvider.notifier).resetAndReloadModels();
  ref.invalidate(configuredProvidersProvider);
  ref.invalidate(modelsScreenProvider);

  try {
    await catalog.discoverModels(providerId, forceRefresh: true);
  } catch (_) {}
}
