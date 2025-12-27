import 'dart:async';
import 'package:flutter/services.dart'; // Для HapticFeedback
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import '../utils/logger.dart';

/// Состояния UI голосового ввода (Google-style)
enum SpeechUiState {
  idle,        // Ожидание
  preparing,   // Подготовка
  listening,   // Запись (с визуализацией)
  processing,  // Обработка
  error,       // Ошибка
  noSpeech,    // Не услышали
}

/// Сервис для работы с голосовым вводом
class SpeechToTextService {
  static final _logger = LogTags.speech;
  
  final SpeechToText _speech = SpeechToText();
  final void Function(String) onResult;
  final void Function(String) onStatusMessage;
  final void Function(SpeechUiState) onStateChanged;
  final void Function(String)? onPartialResult; // Опционально: для промежуточных результатов
  final void Function()? onAutoRestart; // Callback для авто-restart
  
  // Локализованные строки
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
  
  bool _isInitialized = false;
  bool _isListening = false;
  Timer? _listenTimer;
  Timer? _speechStartTimer;
  Timer? _partialDebounce; // Таймер для debounce промежуточных результатов
  String _lastRecognizedText = '';
  String _pendingPartialText = ''; // Текст для отложенной отправки
  
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
  });
  
  /// Проверка доступности микрофона
  Future<bool> checkAvailability() async {
    try {
      if (!_isInitialized) {
        _isInitialized = await _speech.initialize(
          onStatus: (status) {
            _logger.logDebug('Speech status: $status');
            
            if (status == 'listening') {
              // _isListening уже true (установлен в startListening)
              _speechStartTimer?.cancel();
              onStateChanged(SpeechUiState.listening);
              // Haptic feedback — короткая вибрация при старте
              HapticFeedback.lightImpact();
              onStatusMessage(msgListening);
              
              // Запускаем таймеры ожидания речи
              final waitForSpeech = const Duration(seconds: 10);
              final timeout = const Duration(seconds: 30);
              
              // Таймер для автоматической остановки (общий таймаут)
              _listenTimer = Timer(timeout, () {
                if (_isListening) {
                  _logger.logDebug('Total timeout reached, stopping');
                  _handleTimeout();
                }
              });
              
              // Таймер ожидания начала речи - Фаза 1: 10 секунд "Говорите..."
              _speechStartTimer = Timer(waitForSpeech, () {
                if (_isListening && _lastRecognizedText.isEmpty) {
                  _logger.logDebug('Phase 1 timeout: no speech detected');
                  // Фаза 2: "Я вас не слышу" - ждем еще 10 секунд
                  onStatusMessage(msgPhase2);
                  onStateChanged(SpeechUiState.noSpeech);
                  
                  // Второй таймер - еще 10 секунд
                  _speechStartTimer = Timer(waitForSpeech, () {
                    if (_isListening && _lastRecognizedText.isEmpty) {
                      _logger.logDebug('Phase 2 timeout: still no speech');
                      // Фаза 3: Останавливаем
                      _handleTimeout();
                    }
                  });
                }
              });
            } else if (status == 'notListening') {
              // Пользователь замолчал — проверяем текст
              if (_isListening) {
                if (_lastRecognizedText.isNotEmpty) {
                  // Есть текст - переходим в обработку
                  _isListening = false;
                  _speechStartTimer?.cancel();
                  _listenTimer?.cancel();
                  onStateChanged(SpeechUiState.processing);
                  onStatusMessage(msgProcessing);
                  
                  // Вибрация
                  HapticFeedback.mediumImpact();
                  
                  // Сброс через 1 сек
                  Future.delayed(const Duration(seconds: 1), () {
                    onStateChanged(SpeechUiState.idle);
                    onStatusMessage('');
                  });
                } else {
                  // Нет текста - таймеры обработают (или уже обработали)
                  // Если таймеры уже сработали, ничего не делаем
                  _logger.logDebug('notListening with no text, timers will handle');
                }
              }
            } else if (status == 'done') {
              // Завершение сессии
              _logger.logDebug('Speech status: done');
              _partialDebounce?.cancel();
              
              // Проверяем, нужно ли обработать остановку
              if (_isListening) {
                if (_lastRecognizedText.isNotEmpty) {
                  // Есть текст - обрабатываем
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
                  // Нет текста - таймеры должны были обработать
                  // Но если мы здесь, значит таймеры не сработали (например, ручная остановка)
                  _logger.logDebug('Done with no text, manual stop');
                  _isListening = false;
                  _speechStartTimer?.cancel();
                  _listenTimer?.cancel();
                  onStatusMessage(msgNoSpeech);
                  onStateChanged(SpeechUiState.noSpeech);
                  
                  // Сброс через 2 сек
                  Future.delayed(const Duration(seconds: 2), () {
                    onStateChanged(SpeechUiState.idle);
                    onStatusMessage('');
                  });
                }
              }
            }
          },
          onError: (error) {
            _logger.logError('Speech error: $error');
            _handleError(error);
          },
        );
      }
      return _isInitialized;
    } catch (e) {
      _logger.logError('Error checking availability: $e');
      return false;
    }
  }
  
  /// Начать прослушивание
  Future<bool> startListening({
    Duration timeout = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 30), // pauseFor = timeout
    Duration waitForSpeech = const Duration(seconds: 10),
    Duration debounceDuration = const Duration(milliseconds: 300),
  }) async {
    try {
      if (_isListening) {
        _logger.logWarning('Already listening');
        return false;
      }
      
      // Сброс всех таймеров и текстов
      _lastRecognizedText = '';
      _pendingPartialText = '';
      _partialDebounce?.cancel();
      _speechStartTimer?.cancel();
      _listenTimer?.cancel();
      
      // Устанавливаем флаг СРАЗУ при клике - пользователь хочет слушать
      _isListening = true;
      
      // Проверяем доступность (запрашивает разрешение)
      final available = await checkAvailability();
      if (!available) {
        _isListening = false;
        onStatusMessage(msgNoSpeech);
        onStateChanged(SpeechUiState.idle);
        return false;
      }
      
      // Если уже не слушаем (например, остановлено во время initialize)
      if (!_isListening) {
        _logger.logDebug('Stopped during initialization');
        return false;
      }
      
      // Показываем "Подготовка"
      onStateChanged(SpeechUiState.preparing);
      onStatusMessage(msgPreparing);
      
      _logger.logDebug('Starting speech recognition...');
      
      // Запускаем таймеры ПОСЛЕ того, как onStatus('listening') будет вызван
      // Таймеры будут запущены из onStatus callback
      
      final result = await _speech.listen(
        onResult: _handleSpeechResult,
        listenFor: timeout,
        pauseFor: const Duration(seconds: 60), // 60 секунд - отключаем внутренний таймаут плагина
        localeId: 'ru_RU',
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
  
  /// Обработка таймаута ожидания речи
  void _handleTimeout() {
    if (!_isListening) return;
    
    _logger.logDebug('Handling timeout, last text: $_lastRecognizedText');
    
    // СРАЗУ устанавливаем флаг, чтобы предотвратить гонку данных
    _isListening = false;
    _speechStartTimer?.cancel();
    _listenTimer?.cancel();
    
    if (_lastRecognizedText.isNotEmpty) {
      // Есть текст - переходим в обработку
      if (_pendingPartialText.isNotEmpty) {
        onResult(_pendingPartialText);
        _pendingPartialText = '';
      }
      onStateChanged(SpeechUiState.processing);
      onStatusMessage(msgProcessing);
      
      // Вибрация при успешном завершении
      HapticFeedback.mediumImpact();
      
      // Сброс после обработки
      Future.delayed(const Duration(seconds: 1), () {
        onStateChanged(SpeechUiState.idle);
        onStatusMessage('');
      });
    } else {
      // Нет текста - останавливаем
      cancelListening();
      onStatusMessage(msgNoSpeech);
      onStateChanged(SpeechUiState.noSpeech);
      
      // Сброс через 2 сек
      Future.delayed(const Duration(seconds: 2), () {
        onStateChanged(SpeechUiState.idle);
        onStatusMessage('');
      });
    }
  }
  
  /// Остановить прослушивание
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
  
  /// Отменить прослушивание
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
  
  /// Обработка результата распознавания
  void _handleSpeechResult(SpeechRecognitionResult result) {
    _logger.logDebug('Speech result: ${result.recognizedWords}');
    
    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;
    
    // Сохраняем последний текст для проверки таймера ожидания
    _lastRecognizedText = text;
    
    // Сбрасываем таймеры ожидания, так как голос обнаружен
    _speechStartTimer?.cancel();
    
    // Обновляем состояние на "слушаю" если еще не в этом состоянии
    if (_isListening) {
      onStateChanged(SpeechUiState.listening);
      onStatusMessage(msgListening);
    }
    
    if (result.finalResult) {
      // Финальный результат — отправляем сразу
      if (_pendingPartialText.isNotEmpty) {
        onResult(_pendingPartialText);
        _pendingPartialText = '';
      }
      onResult(text);
      _partialDebounce?.cancel();
    } else {
      // Промежуточный результат — с debounce
      _pendingPartialText = text;
      _partialDebounce?.cancel();
      _partialDebounce = Timer(const Duration(milliseconds: 300), () {
        if (_pendingPartialText.isNotEmpty) {
          if (onPartialResult != null) {
            onPartialResult!(_pendingPartialText);
          } else {
            onResult(_pendingPartialText); // Fallback
          }
          _pendingPartialText = '';
        }
      });
    }
  }
  
  /// Обработка ошибок
  void _handleError(SpeechRecognitionError error) {
    _logger.logError('Speech recognition error: ${error.errorMsg}');
    
    // Игнорируем некоторые ошибки если мы все еще слушаем
    // Например, если сработал pauseFor таймер, это не ошибка для нас
    if (_isListening && (
      error.errorMsg == 'error_speech_timeout' || 
      error.errorMsg == 'error_no_match' ||
      error.errorMsg == 'no-speech'
    )) {
      // Пусть таймеры обработают
      _logger.logDebug('Ignoring error $error.errorMsg, timers will handle');
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
    
    // Показываем ошибку
    onStatusMessage(errorMessage);
    onStateChanged(errorState);
    stopListening();
    
    // Вибрация при ошибке
    HapticFeedback.heavyImpact();
    
    // Авто-restart для повторяемых ошибок
    if (canAutoRestart && onAutoRestart != null) {
      _logger.logDebug('Auto-restart triggered for error: ${error.errorMsg}');
      onStatusMessage(msgAutoRestart);
      // Задержка перед авто-restart
      Future.delayed(const Duration(milliseconds: 1500), () {
        onAutoRestart!();
      });
    } else {
      // Возвращаем в idle через 2 сек если не авто-restart
      Future.delayed(const Duration(seconds: 2), () {
        onStateChanged(SpeechUiState.idle);
        onStatusMessage('');
      });
    }
  }
  
  /// Проверка, слушает ли сейчас сервис
  bool get isListening => _isListening;
  
  /// Проверка доступности микрофона (синхронная)
  bool get isAvailable => _isInitialized;
  
  /// Очистка ресурсов
  void dispose() {
    _listenTimer?.cancel();
    _speechStartTimer?.cancel();
    _partialDebounce?.cancel();
    if (_isListening) {
      _speech.stop();
      // onStatus обработает сброс состояния
    }
  }
}
