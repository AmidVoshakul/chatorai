import 'package:chatorai/models/chat_error.dart';

class ErrorMapper {
  static ChatError map(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('401') || str.contains('unauthorized')) {
      return AuthFailureError(e.toString());
    }
    if (str.contains('403')) {
      return AuthFailureError(e.toString());
    }
    if (str.contains('429') || str.contains('rate limit')) {
      return RateLimitError(e.toString());
    }
    if (str.contains('503') || str.contains('service unavailable')) {
      return ServerError(e.toString());
    }
    if (str.contains('timeout') ||
        str.contains('network') ||
        str.contains('connection')) {
      return NetworkError(e.toString());
    }
    return UnknownError(e.toString());
  }
}
