import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers.dart';

Future<void> toggleProvider({
  required WidgetRef ref,
  required String providerId,
  required bool enabled,
}) async {
  if (!enabled) {
    final currentModel = ref.read(modelProvider).selectedModelId;
    final isFromThisProvider = _isModelFromProvider(
      currentModel,
      providerId,
      ref,
    );

    if (isFromThisProvider) {
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
        await ref
            .read(modelProvider.notifier)
            .setSelectedModel(selectedModelIds.first);
      } else {
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
  if (modelId.startsWith('$providerId/')) return true;
  if (providerId == 'ollama') {
    final settings = ref.read(providerSettingsProvider).getSettings('ollama');
    return settings.selectedModelIds.contains(modelId);
  }
  return false;
}

Future<bool> deleteProvider({
  required BuildContext context,
  required WidgetRef ref,
  required AiProvider provider,
}) async {
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

  if (confirmed != true) return false;

  final providerId = provider.id;

  final currentModel = ref.read(modelProvider).selectedModelId;
  final wasFromThisProvider = currentModel.startsWith('$providerId/');

  await ref.read(providerSettingsProvider.notifier).deleteProvider(provider.id);

  if (wasFromThisProvider) {
    final availableModels = ref.read(modelProvider).availableModels;
    if (availableModels.isNotEmpty) {
      await ref
          .read(modelProvider.notifier)
          .setSelectedModel(availableModels.first.id);
    }
  }

  ref.read(modelProvider.notifier).resetAndReloadModels();
  return true;
}

Future<void> saveProviderConfig({
  required WidgetRef ref,
  required AiProvider provider,
  required String baseUrl,
  required String apiKey,
}) async {
  final notifier = ref.read(providerSettingsProvider.notifier);
  await notifier.setProviderEnabled(provider.id, true);
  if (apiKey.isNotEmpty) await notifier.saveApiKey(provider.id, apiKey);
  if (baseUrl.isNotEmpty) await notifier.saveBaseUrl(provider.id, baseUrl);
  await ref.read(modelProvider.notifier).resetAndReloadModels();
}
