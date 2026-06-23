import 'package:chatorai/features/chat/services/speech_to_text_service.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin SpeechInputHandler<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  SpeechToTextService? speechService;

  void Function(SpeechUiState, String)? get onSpeechStateChanged;
  void Function(double)? get onSoundLevelChanged;

  void initSpeechService() {
    final localizations = AppLocalizations.of(context)!;
    speechService = SpeechToTextService(
      onResult: (text) {
        if (mounted) {
          textController.text = text;
        }
      },
      onPartialResult: (text) {
        if (mounted) {
          textController.text = text;
        }
      },
      onStatusMessage: (message) {
        if (mounted) {
          ref.read(chatInputProvider.notifier).setSpeechStatusMessage(message);
          if (onSpeechStateChanged != null) {
            onSpeechStateChanged!(
              ref.read(chatInputProvider).speechUiState,
              message,
            );
          }
        }
      },
      onStateChanged: (state) {
        if (mounted) {
          ref.read(chatInputProvider.notifier).setSpeechUiState(state);
          if (state == SpeechUiState.idle) {
            ref.read(chatInputProvider.notifier).setSpeechStatusMessage('');
          }
          if (onSpeechStateChanged != null) {
            onSpeechStateChanged!(
              state,
              ref.read(chatInputProvider).speechStatusMessage,
            );
          }
        }
      },
      msgListening: localizations.speechListening,
      msgPhase2: localizations.speechPhase2,
      msgProcessing: localizations.speechProcessing,
      msgPreparing: localizations.speechPreparing,
      msgNoSpeech: localizations.micNoSpeechDetected,
      msgStartError: localizations.speechStartError,
      msgErrorNoMatch: localizations.speechErrorNoMatch,
      msgErrorTimeout: localizations.speechErrorTimeout,
      msgErrorNetwork: localizations.speechErrorNetwork,
      msgErrorNotAuthorized: localizations.speechErrorNotAuthorized,
      msgErrorServer: localizations.speechErrorServer,
      msgErrorTooManyRequests: localizations.speechErrorTooManyRequests,
      msgErrorUnknown: localizations.speechErrorUnknown,
      msgAutoRestart: localizations.micAutoRestart,
      onSoundLevelChange: onSoundLevelChanged,
    );
  }

  Future<void> startSpeechToText() async {
    if (ref.read(chatInputProvider).speechUiState == SpeechUiState.listening ||
        ref.read(chatInputProvider).speechUiState == SpeechUiState.preparing) {
      await speechService?.stopListening();
      return;
    }
    final localizations = AppLocalizations.of(context)!;
    final available = await speechService?.checkAvailability() ?? false;
    if (!available) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: localizations.micUnavailable,
          icon: Icons.mic_off,
          duration: const Duration(seconds: 4),
        );
      }
      return;
    }
    await speechService?.startListening(
      timeout: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      waitForSpeech: const Duration(seconds: 10),
    );
  }

  Future<void> handleMicrophoneAction() async {
    if (ref.read(chatInputProvider).speechUiState == SpeechUiState.listening ||
        ref.read(chatInputProvider).speechUiState == SpeechUiState.preparing) {
      await speechService?.stopListening();
      return;
    }
    if (ref.read(chatInputProvider).speechUiState == SpeechUiState.error ||
        ref.read(chatInputProvider).speechUiState == SpeechUiState.noSpeech) {
      await startSpeechToText();
      return;
    }
    final localizations = AppLocalizations.of(context)!;
    ref.read(chatInputProvider.notifier).setIsSending(true);
    try {
      final available = await speechService?.checkAvailability() ?? false;
      if (available && mounted) {
        ref.read(chatInputProvider.notifier).setIsSending(false);
        await startSpeechToText();
      } else if (mounted) {
        ref.read(chatInputProvider.notifier).setIsSending(false);
        if (ref.read(chatInputProvider).speechUiState == SpeechUiState.idle) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: localizations.micUnavailable,
            icon: Icons.mic_off,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(chatInputProvider.notifier).setIsSending(false);
        if (ref.read(chatInputProvider).speechUiState == SpeechUiState.idle) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: localizations.micStartFailed,
            icon: Icons.mic_off,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  void disposeSpeechService() {
    speechService?.dispose();
    speechService = null;
  }

  TextEditingController get textController;
}
