import 'dart:async';

import 'package:chatorai/core/agents/agent_provider.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/commands/command_providers.dart';
import 'package:chatorai/core/config/config_initializer.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/config_watcher.dart';
import 'package:chatorai/core/config/instructions_resolver.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/core/session/session_db_provider.dart';
import 'package:chatorai/core/tools/document_extractor_service.dart';
import 'package:chatorai/gui/features/chat/data/providers/tool_registry_provider.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/attachment_input_handler.dart'
    show AttachmentCleanup;
import 'package:chatorai/gui/features/models/providers/model_provider.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/core/workspace/workspace_runtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fast bootstrap: everything that MUST complete before the first chat frame
/// paints (theme/language are already applied by the widget tree itself).
///
/// This is intentionally tiny — only the cheap, synchronous-ish setup that the
/// UI depends on to render without crashing: config files, config load/validate,
/// instruction cache, secret-storage backend resolution, and constructing the
/// (cheap) catalog service singleton. `preloadApiKeys`, MCP connect, and model
/// preload are HEAVY and run in the background (see [appBootstrapHeavyProvider]),
/// so the Welcome widget and the whole ChatScreen render immediately.
///
/// Part of optimization #13: "Move init behind the first frame (splash +
/// FutureProvider)". The splash (native + [AppLoadingScreen]) is shown only for
/// the duration of THIS provider, not the heavy work.
final appBootstrapFastProvider = FutureProvider<void>((ref) async {
  // PDFium init is optional (PDF image rendering only). Moved out of main()
  // pre-runApp so the first Flutter frame draws fast and the native splash
  // hands off seamlessly to the app instead of blocking on a black window.
  try {
    pdfrxFlutterInitialize();
    await DocumentExtractorService.initPdfRx();
  } on Exception catch (_) {
    LogTags.skills.logWarning(
      'pdfrx: PDFium unavailable — PDF image rendering disabled',
    );
  }

  // XdgPaths.init() вызывается внутри ensureGlobalConfig(); он idempotent.
  await ConfigInitializer.ensureGlobalConfig();

  // Activate the config file watcher for live reloads.
  ref.watch(configWatcherProvider);

  // Hot-reload custom agents and commands from their config directories.
  ref.watch(agentHotReloadProvider);
  ref.watch(commandServiceProvider);

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
    cwd: workspaceRuntimeCurrent,
  );

  // Resolve the secret-storage backend (keyring vs encrypted SharedPreferences
  // fallback) before any API key is read, so a missing/locked keyring degrades
  // quietly instead of spamming KeyringLocked warnings.
  await SecureStorageService.init();

  // Construct the (cheap) catalog service singleton synchronously-available for
  // the first frame. Heavy preloadApiKeys happens in the background.
  final prefs = await SharedPreferences.getInstance();
  PreferencesHolder.prefs = prefs;
  ensureCatalogService(prefs, ref.watch(secureStorageServiceProvider));

  await AgentRegistry().init(config);

  // Pre-open the session database so ChatScreen's repository future resolves
  // before the first frame and ChatMessages renders immediately.
  try {
    await ref.read(sessionRepositoryProvider.future);
  } catch (e, st) {
    LogTags.config.logError(
      '[BOOTSTRAP] session repository init failed',
      e,
      st,
    );
  }

  // Kick off the heavy background work WITHOUT awaiting it — the UI is already
  // (or about to be) painted. MCP connect, model preload, and catalog key
  // preload all run here and update the UI via providers as they settle.
  unawaited(
    ref.read(appBootstrapHeavyProvider.future).catchError((
      Object e,
      StackTrace st,
    ) {
      LogTags.config.logError('[BOOTSTRAP] heavy bootstrap failed', e, st);
    }),
  );

  LogTags.config.logInfo('[BOOTSTRAP] fast bootstrap completed');
});

/// Heavy bootstrap: the slow work that must NOT block the first chat frame.
///
/// Runs in the background after [appBootstrapFastProvider]. It warms the catalog
/// (preloadApiKeys + config providers), pre-warms the tool registry (built-in
/// tools + background MCP connect), and preloads models/settings. All of this is
/// tolerant of errors so a single failure (e.g. a dead MCP server) never blocks
/// the already-visible UI.
///
/// The three main steps (catalog warm, tool registry, model reload) run in
/// parallel so startup is bounded by the single slowest step rather than the
/// sum of all three.
final appBootstrapHeavyProvider = FutureProvider<void>((ref) async {
  // Let this provider finish building before mutating any other provider.
  // ModelNotifier.reloadModels sets state synchronously, and Riverpod forbids
  // modifying a provider while another provider is still building.
  await null;

  final catalogWarm = ref.read(catalogInitializationProvider.future);
  final toolRegistryReady = ref.read(toolRegistryProvider.future);
  final modelReload = ref.read(modelProvider.notifier).reloadModels();

  try {
    await catalogWarm;
  } catch (e, st) {
    LogTags.config.logWarning('catalog preload failed: $e', e, st);
  }

  try {
    await toolRegistryReady;
  } catch (e) {
    LogTags.config.logWarning('toolRegistry init failed: $e');
  }

  try {
    await modelReload;
  } catch (e) {
    LogTags.config.logWarning('model preload failed: $e');
  }

  AttachmentCleanup().initialize();

  LogTags.config.logInfo('[BOOTSTRAP] heavy bootstrap completed');
});
