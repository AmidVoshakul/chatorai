import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'speech_ui_state.dart';

typedef SpeechErrorCallback = void Function();
typedef SpeechStatusCallback = void Function(String);
typedef SpeechStateChangeCallback = void Function(SpeechUiState);

class SpeechErrorHandler {
  final SpeechStatusCallback onStatusMessage;
  final SpeechStateChangeCallback onStateChanged;
  final SpeechErrorCallback onStopListening;
  final void Function()? onAutoRestart;
  final String msgErrorNoMatch;
  final String msgErrorTimeout;
  final String msgErrorNetwork;
  final String msgErrorNotAuthorized;
  final String msgErrorServer;
  final String msgErrorTooManyRequests;
  final String msgErrorUnknown;
  final String msgAutoRestart;
  final void Function(String) logDebug;
  final void Function(String) logError;

  SpeechErrorHandler({
    required this.onStatusMessage,
    required this.onStateChanged,
    required this.onStopListening,
    required this.msgErrorNoMatch,
    required this.msgErrorTimeout,
    required this.msgErrorNetwork,
    required this.msgErrorNotAuthorized,
    required this.msgErrorServer,
    required this.msgErrorTooManyRequests,
    required this.msgErrorUnknown,
    required this.msgAutoRestart,
    required this.logDebug,
    required this.logError,
    this.onAutoRestart,
  });

  void handle(SpeechRecognitionError error, bool isListening) {
    logError('Speech recognition error: ${error.errorMsg}');

    if (isListening &&
        (error.errorMsg == 'error_speech_timeout' ||
            error.errorMsg == 'error_no_match' ||
            error.errorMsg == 'no-speech')) {
      logDebug('Ignoring error $error.errorMsg, timers will handle');
      return;
    }

    String errorMessage;
    SpeechUiState errorState = SpeechUiState.error;
    bool canAutoRestart = false;

    switch (error.errorMsg) {
      case 'error_no_match':
        errorMessage = msgErrorNoMatch;
        canAutoRestart = true;
        errorState = SpeechUiState.noSpeech;
        break;
      case 'error_speech_timeout':
        errorMessage = msgErrorTimeout;
        canAutoRestart = true;
        errorState = SpeechUiState.noSpeech;
        break;
      case 'error_network':
        errorMessage = msgErrorNetwork;
        canAutoRestart = false;
        break;
      case 'error_not_authorized':
        errorMessage = msgErrorNotAuthorized;
        canAutoRestart = false;
        break;
      case 'error_server':
        errorMessage = msgErrorServer;
        canAutoRestart = true;
        break;
      case 'error_too_many_requests':
        errorMessage = msgErrorTooManyRequests;
        canAutoRestart = false;
        break;
      default:
        errorMessage = msgErrorUnknown;
        canAutoRestart = true;
    }

    onStatusMessage(errorMessage);
    onStateChanged(errorState);
    onStopListening();

    HapticFeedback.heavyImpact();

    if (canAutoRestart && onAutoRestart != null) {
      logDebug('Auto-restart triggered for error: ${error.errorMsg}');
      onStatusMessage(msgAutoRestart);
      Future.delayed(const Duration(milliseconds: 1500), () {
        onAutoRestart!();
      });
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        onStateChanged(SpeechUiState.idle);
        onStatusMessage('');
      });
    }
  }
}
