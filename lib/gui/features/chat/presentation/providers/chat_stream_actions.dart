import 'package:chatorai/gui/features/chat/data/providers/chat_screen_notifier.dart';
import 'package:chatorai/gui/features/sessions/providers/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stops any active generation: cancels the session tree and finalizes
/// streaming state. Safe to call when nothing is streaming.
void stopActiveStreaming(WidgetRef ref) {
  ref.read(currentSessionRunnerProvider.notifier).cancelAllChildren();
  ref.read(chatScreenProvider.notifier).finalizeStreaming();
}
