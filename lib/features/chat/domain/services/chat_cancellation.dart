import 'package:ai_sdk_dart/ai_sdk_dart.dart';

/// Manages cancellation token lifecycle for AI service requests.
///
/// Wraps [CancellationToken] reset semantics so that cancelling
/// invalidates the current token and immediately produces a fresh one
/// for the next request.
class ChatCancellation {
  var _token = CancellationToken();

  /// The current active cancellation token.
  CancellationToken get token => _token;

  /// Whether the current token has been cancelled.
  bool get isCancelled => _token.isCancelled;

  /// Cancels the current token and resets to a fresh one.
  void cancel() {
    _token.cancel();
    _token = CancellationToken();
  }
}
