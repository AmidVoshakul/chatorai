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
  Function(String)? get onRecognizedText;

  String _textBeforeSpeech = '';

  void _applySpeechText(String text) {
    if (!mounted) return;
    final prefix = _textBeforeSpeech;
    final separator = prefix.isNotEmpty ? ' ' : '';
    textController.text = '$prefix$separator$text';
    textController.selection = TextSelection.collapsed(offset: textController.text.length);
    onRecognizedText?.call(text);
  }

  void initSpeechService() {
    final localizations = AppLocalizations.of(context)!;
    speechService = SpeechToTextService(
      onResult: (text) => _applySpeechText(text),
      onPartialResult: (text) => _applySpeechText(text),
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
    final currentState = ref.read(chatInputProvider).speechUiState;
    if (currentState == SpeechUiState.listening ||
        currentState == SpeechUiState.preparing) {
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
    _textBeforeSpeech = textController.text;
    await speechService?.startListening(
      timeout: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      waitForSpeech: const Duration(seconds: 10),
    );
  }

  Future<void> handleMicrophoneAction() async {
    final currentState = ref.read(chatInputProvider).speechUiState;
    if (currentState == SpeechUiState.listening ||
        currentState == SpeechUiState.preparing) {
      await speechService?.stopListening();
      return;
    }
    if (currentState == SpeechUiState.error ||
        currentState == SpeechUiState.noSpeech) {
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
