import 'package:chatorai/core/lsp/lsp_client.dart';
import 'package:chatorai/core/lsp/lsp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton LSP service provider.
///
/// Creates and manages the [LspService] instance. Calls [LspService.shutdownAll]
/// when the provider is disposed (app shutdown or hot reload).
final lspServiceProvider = FutureProvider.autoDispose<LspService>((ref) async {
  final service = LspService();
  ref.onDispose(service.shutdownAll);
  return service;
});

/// Provides a ready-to-use LSP client for a specific file.
///
/// The client is cached per workspace root and server type.
/// Automatically reconnects if the previous client was shut down.
final lspClientProvider = FutureProvider.autoDispose.family<LspClient?, String>(
  (ref, filePath) async {
    final service = await ref.watch(lspServiceProvider.future);
    return service.clientForFile(filePath);
  },
);
