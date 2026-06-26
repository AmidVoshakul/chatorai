import 'package:chatorai/core/tools/tool.dart';
import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;

/// Integration test context that auto-approves all permission requests.
///
/// This context is designed for integration tests that need to execute tools
/// without dealing with permission dialogs. It automatically grants any
/// permission requested by the tool.
///
/// Usage:
/// ```dart
/// final ctx = IntegrationTestContext(
///   toolCallId: 'test-call',
///   sessionId: 'test-session',
/// );
/// await tool.execute(input, ctx);
/// ```
class IntegrationTestContext implements ToolContext {
  @override
  final String toolCallId;

  @override
  final String? sessionId;

  @override
  final sdk.CancellationToken? abortSignal;

  @override
  final Future<void> Function({
    required String permission,
    required List<String> patterns,
    Map<String, dynamic>? metadata,
    List<String>? always,
  })
  ask;

  @override
  final Future<String> Function({
    required String question,
    List<String> options,
    bool multiple,
  })
  askQuestion;

  @override
  final void Function({String? title, Map<String, dynamic>? metadata})?
  onMetadata;

  const IntegrationTestContext({
    this.toolCallId = 'integration-test',
    this.sessionId,
    this.abortSignal,
    this.ask = _defaultAsk,
    this.askQuestion = _defaultAskQuestion,
    this.onMetadata,
  });

  /// Auto-approves all permission requests.
  ///
  /// In integration tests, we want to test the actual tool execution without
  /// permission friction. This function simply returns immediately, granting
  /// the requested permission.
  static Future<void> _defaultAsk({
    required String permission,
    required List<String> patterns,
    Map<String, dynamic>? metadata,
    List<String>? always,
  }) async {
    // No-op
    return;
  }

  /// Returns empty string for questions in integration tests.
  static Future<String> _defaultAskQuestion({
    required String question,
    List<String> options = const [],
    bool multiple = false,
  }) async {
    return '';
  }

  /// Dummy method not used by tools but required by spec.
  /// Returns PermissionResult.granted (simulate permission granted).
  PermissionResult checkPermission(String permission, String pattern) {
    return PermissionResult.granted;
  }

  /// Dummy method not used by tools but required by spec.
  /// Throws UnimplementedError as specified.
  void run() {
    throw UnimplementedError(
      'run() is not implemented in IntegrationTestContext',
    );
  }
}

/// Enum for permission results (used by checkPermission).
enum PermissionResult { granted, denied }
