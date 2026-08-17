import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран ошибки, показываемый если [`appBootstrapFastProvider`] упал
/// (жёсткий сбой инициализации, например `AgentRegistry.init`
/// или загрузка каталога).
class BootstrapErrorScreen extends ConsumerWidget {
  const BootstrapErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: ChatoraiColors.darkSurface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: ChatoraiColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.bootstrapErrorTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.bootstrapErrorBody,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // Сбрасываем и вышестоящие провайдеры, иначе
                  // appBootstrapFastProvider упадёт мгновенно с той же ошибкой.
                  ref.invalidate(catalogInitializationProvider);
                  ref.invalidate(configProvider);
                  ref.invalidate(appBootstrapFastProvider);
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
