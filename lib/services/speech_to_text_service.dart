import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import '../utils/logger.dart';

/// Сервис для работы с голосовым вводом
class SpeechToTextService {
  static final _logger = LogTags.speech;
  
  final SpeechToText _speech = SpeechToText();
  final void Function(String) onResult;
  final void Function(String) onError;
  final void Function(bool) onListeningChanged;
  
  bool _isInitialized = false;
  bool _isListening = false;
  Timer? _listenTimer;
  
  SpeechToTextService({
    required this.onResult,
    required this.onError,
    required this.onListeningChanged,
  });
  
  /// Проверка доступности микрофона
  Future<bool> checkAvailability() async {
    try {
      if (!_isInitialized) {
        _isInitialized = await _speech.initialize(
          onStatus: (status) {
            _logger.logDebug('Speech status: $status');
            if (status == 'listening') {
              _isListening = true;
              onListeningChanged(true);
            } else if (status == 'notListening') {
              _isListening = false;
              onListeningChanged(false);
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
    Duration pauseFor = const Duration(seconds: 5),
  }) async {
    try {
      final available = await checkAvailability();
      if (!available) {
        onError('Микрофон недоступен. Проверьте разрешения.');
        return false;
      }
      
      if (_isListening) {
        _logger.logWarning('Already listening');
        return false;
      }
      
      _logger.logDebug('Starting speech recognition...');
      
      final result = await _speech.listen(
        onResult: _handleSpeechResult,
        listenFor: timeout,
        pauseFor: pauseFor,
        localeId: 'ru_RU', // Поддержка русского языка
      );
      
      if (result) {
        _isListening = true;
        onListeningChanged(true);
        
        // Таймер для автоматической остановки
        _listenTimer?.cancel();
        _listenTimer = Timer(timeout, () {
          if (_isListening) {
            stopListening();
          }
        });
        
        return true;
      } else {
        onError('Не удалось запустить распознавание речи');
        return false;
      }
    } catch (e) {
      _logger.logError('Error starting listening: $e');
      onError('Ошибка запуска: $e');
      return false;
    }
  }
  
  /// Остановить прослушивание
  Future<void> stopListening() async {
    try {
      if (!_isListening) return;
      
      _logger.logDebug('Stopping speech recognition...');
      await _speech.stop();
      _isListening = false;
      _listenTimer?.cancel();
      onListeningChanged(false);
    } catch (e) {
      _logger.logError('Error stopping listening: $e');
      onError('Ошибка остановки: $e');
    }
  }
  
  /// Отменить прослушивание
  Future<void> cancelListening() async {
    try {
      if (!_isListening) return;
      
      _logger.logDebug('Canceling speech recognition...');
      await _speech.cancel();
      _isListening = false;
      _listenTimer?.cancel();
      onListeningChanged(false);
    } catch (e) {
      _logger.logError('Error canceling listening: $e');
    }
  }
  
  /// Обработка результата распознавания
  void _handleSpeechResult(SpeechRecognitionResult result) {
    _logger.logDebug('Speech result: ${result.recognizedWords}');
    
    if (result.finalResult) {
      final text = result.recognizedWords.trim();
      if (text.isNotEmpty) {
        onResult(text);
        stopListening();
      }
    } else {
      // Промежуточный результат - можно обновлять UI
      final text = result.recognizedWords.trim();
      if (text.isNotEmpty) {
        onResult(text);
      }
    }
  }
  
  /// Обработка ошибок
  void _handleError(SpeechRecognitionError error) {
    _logger.logError('Speech recognition error: ${error.errorMsg}');
    
    String errorMessage;
    switch (error.errorMsg) {
      case 'error_no_match':
        errorMessage = 'Не удалось распознать речь. Попробуйте еще раз.';
        break;
      case 'error_speech_timeout':
        errorMessage = 'Время ожидания истекло. Ничего не услышали.';
        break;
      case 'error_network':
        errorMessage = 'Ошибка сети. Проверьте подключение к интернету.';
        break;
      case 'error_not_authorized':
        errorMessage = 'Нет доступа к микрофону. Проверьте разрешения в настройках.';
        break;
      case 'error_server':
        errorMessage = 'Ошибка сервера распознавания. Попробуйте позже.';
        break;
      case 'error_too_many_requests':
        errorMessage = 'Слишком много запросов. Попробуйте позже.';
        break;
      default:
        errorMessage = 'Ошибка распознавания речи: ${error.errorMsg}';
    }
    
    onError(errorMessage);
    stopListening();
  }
  
  /// Проверка, слушает ли сейчас сервис
  bool get isListening => _isListening;
  
  /// Проверка доступности микрофона (синхронная)
  bool get isAvailable => _isInitialized;
  
  /// Очистка ресурсов
  void dispose() {
    _listenTimer?.cancel();
    if (_isListening) {
      _speech.stop();
    }
  }
}
