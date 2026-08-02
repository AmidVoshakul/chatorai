import 'dart:async';
import 'dart:io';

import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/config/config_initializer.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/instructions_resolver.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/core/tools/tool_registry_provider.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/attachment_input_handler.dart'
    show AttachmentCleanup;
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Выполняет всю тяжёлую инициализацию за первым кадром.
///
/// UI (ChatScreen) рендерится только после завершения (состояние data),
/// поэтому каталог к этому моменту уже готов — `preloadApiKeys` завершён,
/// и `providerCatalogServiceProvider` не бросит `StateError` при загрузке.
///
/// Часть плана оптимизации #13: «Вынести инициализацию за первый кадр
/// (splash + FutureProvider)».
final appBootstrapProvider = FutureProvider<void>((ref) async {
  // XdgPaths.init() вызывается внутри ensureGlobalConfig(); он idempotent.
  await ConfigInitializer.ensureGlobalConfig();

  // SSOT для конфига — configProvider валидирует по JSON-схеме.
  // При ошибке валидации chatorai.json продолжаем с null (MCP/overrides не
  // применяются), чтобы приложение не падало на кривом конфиге.
  ChatOrAIConfig? config;
  try {
    config = await ref.watch(configProvider.future);
  } catch (e, st) {
    LogTags.config.logError('Failed to load chatorai.json config', e, st);
  }

  // Seed the instruction resolver cache so both the GUI and non-UI consumers
  // (task tool, CLI) share a single resolution.
  InstructionsCache.instance.setRaw(
    config?.instructions ?? const [],
    cwd: Directory.current,
  );

  // Resolve the secret-storage backend (keyring vs encrypted SharedPreferences fallback)
  // before any API key is read, so a missing/locked keyring degrades quietly
  // instead of spamming KeyringLocked warnings.
  await SecureStorageService.init();

  await AgentRegistry().init(config);

  // Тяжёлый preloadApiKeys (+400мс–2с для ~40 провайдеров) — ждём здесь,
  // чтобы ChatScreen получил готовый каталог. Без этого первый вызов
  // providerCatalogServiceProvider бросит StateError при загрузке.
  //
  // MCP-серверы поднимаются лениво в toolRegistryProvider (единый владелец),
  // а не здесь — это устраняет двойной вызов initialize() и deadlock на
  // сбое подключения.
  await ref.watch(catalogInitializationProvider.future);

  // Pre-warm the tool registry (built-in tools, skills, LSP, MCP) during the
  // splash screen so the first user message doesn't pay the ~0.5–1s
  // registration cost on top of LLM latency. Errors are tolerated — the
  // registry is also loaded lazily inside _initiateStream if this fails.
  unawaited(
    ref
        .read(toolRegistryProvider.future)
        .then<void>(
          (_) {},
          onError: (Object e, StackTrace st) {
            LogTags.config.logWarning(
              'toolRegistry prewarm failed (will retry lazily): $e',
            );
          },
        ),
  );

  AttachmentCleanup().initialize();
});
