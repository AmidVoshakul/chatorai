sealed class ChatError {
  final String message;
  const ChatError(this.message);
}

class RateLimitError extends ChatError {
  final Duration? retryAfter;
  const RateLimitError(super.message, {this.retryAfter});
}

class AuthFailureError extends ChatError {
  const AuthFailureError(super.message);
}

class ContextOverflowError extends ChatError {
  const ContextOverflowError(super.message);
}

class ServerError extends ChatError {
  final int? statusCode;
  const ServerError(super.message, {this.statusCode});
}

class NetworkError extends ChatError {
  const NetworkError(super.message);
}

class UnknownError extends ChatError {
  const UnknownError(super.message);
}
