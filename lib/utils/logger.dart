import 'package:logger/logger.dart';

/// Centralized logging configuration for the entire application
/// Provides consistent logging across all modules with different log levels

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  
  factory AppLogger() => _instance;
  
  AppLogger._internal();
  
  late Logger _logger;
  
  /// Initialize logger with appropriate settings for development/production
  void init({bool isDebug = true}) {
    if (isDebug) {
      _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0, // Remove stack trace lines
          errorMethodCount: 0, // Remove error stack traces
          lineLength: 120,
          colors: true,
          printEmojis: true,
        ),
      );
    } else {
      _logger = Logger(
        printer: SimplePrinter(),
      );
    }
  }
  
  /// Log trace information (detailed debugging - replacement for verbose)
  void t(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t('[$tag] $message', error: error, stackTrace: stackTrace);
  }
  
  /// Log debug information (development only)
  void d(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d('[$tag] $message', error: error, stackTrace: stackTrace);
  }
  
  /// Log informational messages (important events)
  void i(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('[$tag] $message', error: error, stackTrace: stackTrace);
  }
  
  /// Log warnings (potential issues)
  void w(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w('[$tag] $message', error: error, stackTrace: stackTrace);
  }
  
  /// Log errors (critical issues)
  void e(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);
  }
}

/// Convenience extension for easier logging
extension LoggerExtensions on String {
  void logVerbose(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger().t(this, message, error, stackTrace);
  }
  
  void logDebug(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger().d(this, message, error, stackTrace);
  }
  
  void logInfo(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger().i(this, message, error, stackTrace);
  }
  
  void logWarning(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger().w(this, message, error, stackTrace);
  }
  
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger().e(this, message, error, stackTrace);
  }
}

/// Predefined log tags for different modules
class LogTags {
  static const String openRouter = 'OpenRouter';
  static const String chatService = 'ChatService';
  static const String storage = 'Storage';
  static const String ui = 'UI';
  static const String pagination = 'Pagination';
  static const String scroll = 'Scroll';
  static const String message = 'Message';
  static const String models = 'Models';
  static const String settings = 'Settings';
  static const String sidebar = 'Sidebar';
  static const String input = 'Input';
  static const String chatScreen = 'ChatScreen';
  static const String modelsScreen = 'ModelsScreen';
  static const String settingsScreen = 'SettingsScreen';
}

/// Initialize logger in main.dart
void initLogger() {
  AppLogger().init(isDebug: true);
}