sealed class ChatError {
  final String message;
  const ChatError(this.message);
}

class RateLimitError extends ChatError {
  final Duration? retryAfter;
  const RateLimitError(String message, {this.retryAfter}) : super(message);
}

class AuthFailureError extends ChatError {
  const AuthFailureError(String message) : super(message);
}

class ContextOverflowError extends ChatError {
  const ContextOverflowError(String message) : super(message);
}

class ServerError extends ChatError {
  final int? statusCode;
  const ServerError(String message, {this.statusCode}) : super(message);
}

class NetworkError extends ChatError {
  const NetworkError(String message) : super(message);
}

class UnknownError extends ChatError {
  const UnknownError(String message) : super(message);
}
