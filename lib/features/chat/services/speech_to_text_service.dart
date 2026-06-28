import 'dart:async';

import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_error_handler.dart';
import 'speech_ui_state.dart';

export 'speech_ui_state.dart';

class SpeechToTextService {
  static final _logger = LogTags.speech;

  final SpeechToText _speech = SpeechToText();
  final void Function(String) onResult;
  final void Function(String) onStatusMessage;
  final void Function(SpeechUiState) onStateChanged;
  final void Function(String)? onPartialResult;
  final void Function()? onAutoRestart;
  final void Function(double)? onSoundLevelChange;

  final String msgListening;
  final String msgPhase2;
  final String msgProcessing;
  final String msgPreparing;
  final String msgNoSpeech;
  final String Function(Object) msgStartError;
  final String msgErrorNoMatch;
  final String msgErrorTimeout;
  final String msgErrorNetwork;
  final String msgErrorNotAuthorized;
  final String msgErrorServer;
  final String msgErrorTooManyRequests;
  final String msgErrorUnknown;
  final String msgAutoRestart;

  late final SpeechErrorHandler _errorHandler;

  bool _isInitialized = false;
  bool _isListening = false;
  Timer? _listenTimer;
  Timer? _speechStartTimer;
  Timer? _partialDebounce;
  String _lastRecognizedText = '';
  String _pendingPartialText = '';

  SpeechToTextService({
    required this.onResult,
    required this.onStatusMessage,
    required this.onStateChanged,
    required this.msgListening,
    required this.msgPhase2,
    required this.msgProcessing,
    required this.msgPreparing,
    required this.msgNoSpeech,
    required this.msgStartError,
    required this.msgErrorNoMatch,
    required this.msgErrorTimeout,
    required this.msgErrorNetwork,
    required this.msgErrorNotAuthorized,
    required this.msgErrorServer,
    required this.msgErrorTooManyRequests,
    required this.msgErrorUnknown,
    required this.msgAutoRestart,
    this.onPartialResult,
    this.onAutoRestart,
    this.onSoundLevelChange,
  }) {
    _errorHandler = SpeechErrorHandler(
      onStatusMessage: onStatusMessage,
      onStateChanged: onStateChanged,
      onStopListening: stopListening,
      msgErrorNoMatch: msgErrorNoMatch,
      msgErrorTimeout: msgErrorTimeout,
      msgErrorNetwork: msgErrorNetwork,
      msgErrorNotAuthorized: msgErrorNotAuthorized,
      msgErrorServer: msgErrorServer,
      msgErrorTooManyRequests: msgErrorTooManyRequests,
      msgErrorUnknown: msgErrorUnknown,
      msgAutoRestart: msgAutoRestart,
      logDebug: _logger.logDebug,
      logError: _logger.logError,
      onAutoRestart: onAutoRestart,
    );
  }

  Future<bool> checkAvailability() async {
    try {
      if (!_isInitialized) {
        _logger.logDebug('Initializing speech recognition...');
        _isInitialized = await _speech.initialize(
          debugLogging: true,
          options: [SpeechToText.androidIntentLookup],
          onStatus: _onSpeechStatus,
          onError: (error) {
            _logger.logError('Speech init error: $error');
            _errorHandler.handle(error, _isListening);
          },
        );

        if (!_isInitialized) {
          final perm = await _speech.hasPermission;
          final locale = await _speech.systemLocale();
          _logger.logWarning(
            'Speech init failed. '
            'hasPermission=$perm, '
            'systemLocale=$locale, '
            'isListening=$_isListening',
          );
          onStatusMessage(msgErrorNotAuthorized);
          onStateChanged(SpeechUiState.error);
          Future.delayed(const Duration(seconds: 2), () {
            onStateChanged(SpeechUiState.idle);
            onStatusMessage('');
          });
          return false;
        }
        _logger.logDebug('Speech recognition initialized successfully');
      }
      return _isInitialized;
    } catch (e) {
      _logger.logError('Error checking availability: $e');
      _isInitialized = false;
      return false;
    }
  }

  void _onSpeechStatus(String status) {
    _logger.logDebug('Speech status: $status');

    if (status == 'listening') {
      _speechStartTimer?.cancel();
      onStateChanged(SpeechUiState.listening);
      HapticFeedback.lightImpact();
      onStatusMessage(msgListening);

      final waitForSpeech = const Duration(seconds: 10);
      final timeout = const Duration(seconds: 30);

      _listenTimer = Timer(timeout, () {
        if (_isListening) {
          _logger.logDebug('Total timeout reached, stopping');
          _handleTimeout();
        }
      });

      _speechStartTimer = Timer(waitForSpeech, () {
        if (_isListening && _lastRecognizedText.isEmpty) {
          _logger.logDebug('Phase 1 timeout: no speech detected');
          onStatusMessage(msgPhase2);
          onStateChanged(SpeechUiState.noSpeech);

          _speechStartTimer = Timer(waitForSpeech, () {
            if (_isListening && _lastRecognizedText.isEmpty) {
              _logger.logDebug('Phase 2 timeout: still no speech');
              _handleTimeout();
            }
          });
        }
      });
    } else if (status == 'notListening') {
      if (_isListening) {
        if (_lastRecognizedText.isNotEmpty) {
          _isListening = false;
          _speechStartTimer?.cancel();
          _listenTimer?.cancel();
          onStateChanged(SpeechUiState.processing);
          onStatusMessage(msgProcessing);

          HapticFeedback.mediumImpact();

          Future.delayed(const Duration(seconds: 1), () {
            onStateChanged(SpeechUiState.idle);
            onStatusMessage('');
          });
        } else {
          _logger.logDebug('notListening with no text, timers will handle');
        }
      }
    } else if (status == 'done') {
      _logger.logDebug('Speech status: done');
      _partialDebounce?.cancel();

      if (_isListening) {
        if (_lastRecognizedText.isNotEmpty) {
          onStateChanged(SpeechUiState.processing);
          onStatusMessage(msgProcessing);
          _isListening = false;
          _speechStartTimer?.cancel();
          _listenTimer?.cancel();

          HapticFeedback.mediumImpact();

          Future.delayed(const Duration(seconds: 1), () {
            onStateChanged(SpeechUiState.idle);
            onStatusMessage('');
          });
        } else {
          _logger.logDebug('Done with no text, manual stop');
          _isListening = false;
          _speechStartTimer?.cancel();
          _listenTimer?.cancel();
          onStatusMessage(msgNoSpeech);
          onStateChanged(SpeechUiState.noSpeech);

          Future.delayed(const Duration(seconds: 2), () {
            onStateChanged(SpeechUiState.idle);
            onStatusMessage('');
          });
        }
      }
    }
  }

  Future<bool> startListening({
    Duration timeout = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 5),
    Duration waitForSpeech = const Duration(seconds: 10),
    Duration debounceDuration = const Duration(milliseconds: 300),
  }) async {
    try {
      if (_isListening) {
        _logger.logWarning('Already listening');
        return false;
      }

      _lastRecognizedText = '';
      _pendingPartialText = '';
      _partialDebounce?.cancel();
      _speechStartTimer?.cancel();
      _listenTimer?.cancel();

      _isListening = true;

      final available = await checkAvailability();
      if (!available) {
        _isListening = false;
        onStatusMessage(msgNoSpeech);
        onStateChanged(SpeechUiState.idle);
        return false;
      }

      if (!_isListening) {
        _logger.logDebug('Stopped during initialization');
        return false;
      }

      onStateChanged(SpeechUiState.preparing);
      onStatusMessage(msgPreparing);

      _logger.logDebug('Starting speech recognition...');

      final result = await _speech.listen(
        onResult: _handleSpeechResult,
        onSoundLevelChange: (level) {
          onSoundLevelChange?.call(level);
        },
        listenFor: timeout,
        pauseFor: pauseFor,
      );

      return result ?? false;
    } catch (e) {
      _logger.logError('Error starting listening: $e');
      onStatusMessage(msgStartError(e));
      onStateChanged(SpeechUiState.error);
      _isListening = false;
      Future.delayed(const Duration(seconds: 2), () {
        onStateChanged(SpeechUiState.idle);
        onStatusMessage('');
      });
      return false;
    }
  }

  void _handleTimeout() {
    if (!_isListening) return;

    _logger.logDebug('Handling timeout, last text: $_lastRecognizedText');

    _isListening = false;
    _speechStartTimer?.cancel();
    _listenTimer?.cancel();

    if (_lastRecognizedText.isNotEmpty) {
      if (_pendingPartialText.isNotEmpty) {
        onResult(_pendingPartialText);
        _pendingPartialText = '';
      }
      onStateChanged(SpeechUiState.processing);
      onStatusMessage(msgProcessing);

      HapticFeedback.mediumImpact();

      Future.delayed(const Duration(seconds: 1), () {
        onStateChanged(SpeechUiState.idle);
        onStatusMessage('');
      });
    } else {
      cancelListening();
      onStatusMessage(msgNoSpeech);
      onStateChanged(SpeechUiState.noSpeech);

      Future.delayed(const Duration(seconds: 2), () {
        onStateChanged(SpeechUiState.idle);
        onStatusMessage('');
      });
    }
  }

  Future<void> stopListening() async {
    try {
      if (!_isListening) return;

      _logger.logDebug('Stopping speech recognition...');
      await _speech.stop();
      _listenTimer?.cancel();
      _speechStartTimer?.cancel();
      _isListening = false;
    } catch (e) {
      _logger.logError('Error stopping listening: $e');
    }
  }

  Future<void> cancelListening() async {
    try {
      if (!_isListening) return;

      _logger.logDebug('Canceling speech recognition...');
      await _speech.cancel();
      _listenTimer?.cancel();
      _speechStartTimer?.cancel();
      _isListening = false;
    } catch (e) {
      _logger.logError('Error canceling listening: $e');
    }
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    _logger.logDebug('Speech result: ${result.recognizedWords}');

    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;

    _lastRecognizedText = text;

    _speechStartTimer?.cancel();

    if (_isListening) {
      onStateChanged(SpeechUiState.listening);
      onStatusMessage(msgListening);
    }

    if (result.finalResult) {
      if (_pendingPartialText.isNotEmpty) {
        onResult(_pendingPartialText);
        _pendingPartialText = '';
      }
      onResult(text);
      _partialDebounce?.cancel();
    } else {
      _pendingPartialText = text;
      _partialDebounce?.cancel();
      _partialDebounce = Timer(const Duration(milliseconds: 300), () {
        if (_pendingPartialText.isNotEmpty) {
          if (onPartialResult != null) {
            onPartialResult!(_pendingPartialText);
          } else {
            onResult(_pendingPartialText);
          }
          _pendingPartialText = '';
        }
      });
    }
  }

  bool get isListening => _isListening;

  bool get isAvailable => _isInitialized;

  void dispose() {
    _listenTimer?.cancel();
    _speechStartTimer?.cancel();
    _partialDebounce?.cancel();
    if (_isListening) {
      _speech.stop();
    }
  }
}
