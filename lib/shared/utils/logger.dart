import 'dart:developer' as developer;

/// Enum representing different log levels
enum LogLevel { verbose, debug, info, warning, error }

/// Extension to add log level comparison methods
extension LogLevelExtensions on LogLevel {
  bool operator >(LogLevel other) => index > other.index;
  bool operator >=(LogLevel other) => index >= other.index;
  bool operator <(LogLevel other) => index < other.index;
  bool operator <=(LogLevel other) => index <= other.index;
}

/// Configuration for logging
class LogConfig {
  static LogLevel minimumLevel = LogLevel.debug;
  static bool enabled = true;
}

/// Logger class for structured logging
class Logger {
  final String tag;
  final LogLevel minimumLevel;

  Logger(this.tag, {LogLevel? minimumLevel})
    : minimumLevel = minimumLevel ?? LogConfig.minimumLevel;

  void logVerbose(String message, [Object? error, StackTrace? stackTrace]) {
    if (!LogConfig.enabled || minimumLevel > LogLevel.verbose) return;
    _log(LogLevel.verbose, message, error: error, stackTrace: stackTrace);
  }

  void logDebug(String message, [Object? error, StackTrace? stackTrace]) {
    if (!LogConfig.enabled || minimumLevel > LogLevel.debug) return;
    _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }

  void logInfo(String message, [Object? error, StackTrace? stackTrace]) {
    if (!LogConfig.enabled || minimumLevel > LogLevel.info) return;
    _log(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }

  void logWarning(String message, [Object? error, StackTrace? stackTrace]) {
    if (!LogConfig.enabled || minimumLevel > LogLevel.warning) return;
    _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }

  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (!LogConfig.enabled || minimumLevel > LogLevel.error) return;
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final fullMessage = '[$timestamp] $levelStr [$tag] $message';

    switch (level) {
      case LogLevel.verbose:
        developer.log(fullMessage, name: tag);
        break;
      case LogLevel.debug:
        developer.log(fullMessage, name: tag);
        break;
      case LogLevel.info:
        developer.log(fullMessage, name: tag);
        break;
      case LogLevel.warning:
        developer.log(fullMessage, name: tag, error: error);
        break;
      case LogLevel.error:
        developer.log(
          fullMessage,
          name: tag,
          error: error,
          stackTrace: stackTrace,
        );
        break;
    }
  }
}

/// Log tags for different parts of the application
class LogTags {
  static final Logger openRouter = Logger('OpenRouter');
  static final Logger chat = Logger('Chat');
  static final Logger storage = Logger('Storage');
  static final Logger ui = Logger('UI');
  static final Logger app = Logger('App');
  static final Logger network = Logger('Network');
  static final Logger speech = Logger('Speech');
  static final Logger pagination = Logger('Pagination');
  static final Logger settings = Logger('Settings');
  static final Logger chatScreen = Logger('ChatScreen');
  static final Logger scroll = Logger('Scroll');
  static final Logger message = Logger('Message');
  static final Logger chatService = Logger('ChatService');
  static final Logger sidebar = Logger('Sidebar');
  static final Logger errorMessage = Logger('ErrorMessage');
  static final Logger permission = Logger('Permission');
  static final Logger skills = Logger('Skills');
  static final Logger lsp = Logger('LSP');
  static final Logger format = Logger('Format');
  static final Logger mcp = Logger('MCP');
  static final Logger config = Logger('Config');
}
