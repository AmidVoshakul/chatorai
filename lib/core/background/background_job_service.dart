import 'dart:async';
import 'dart:isolate';

import 'package:synchronized/synchronized.dart';

/// Status of a background job.
enum BackgroundJobStatus { running, completed, error, cancelled }

/// Information about a background job.
class BackgroundJobInfo {
  final String id;
  final String type;
  final String? title;
  final BackgroundJobStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? output;
  final String? error;

  const BackgroundJobInfo({
    required this.id,
    required this.type,
    this.title,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.output,
    this.error,
  });
}

/// Internal job entry holding state and completer for wait().
class _Job {
  final String id;
  final String type;
  final String? title;
  final Map<String, dynamic>? metadata;
  BackgroundJobStatus status;
  final DateTime startedAt;
  DateTime? completedAt;
  String? output;
  String? error;
  int sequence;
  ReceivePort? _receivePort;
  Completer<BackgroundJobInfo>? _waitCompleter;
  Completer<BackgroundJobInfo>? _promotionCompleter;

  _Job({
    required this.id,
    required this.type,
    this.title,
    this.metadata,
    required this.status,
    required this.startedAt,
  }) : sequence = 0;

  BackgroundJobInfo toInfo() {
    return BackgroundJobInfo(
      id: id,
      type: type,
      title: title,
      status: status,
      startedAt: startedAt,
      completedAt: completedAt,
      output: output,
      error: error,
    );
  }
}

/// A registry for background jobs that run in isolates.
///
/// Provides thread-safe job management with support for starting,
/// extending, waiting, and cancelling jobs.
class BackgroundJobService {
  final Map<String, _Job> _jobs = {};
  final Lock _lock = Lock();

  /// Lists all jobs.
  Future<List<BackgroundJobInfo>> list() async {
    final result = <BackgroundJobInfo>[];
    for (final entry in _jobs.entries) {
      result.add(entry.value.toInfo());
    }
    return result;
  }

  /// Gets a job by id.
  Future<BackgroundJobInfo?> get(String id) async {
    final job = await _lock.synchronized(
      () => Map<String, _Job>.from(_jobs)[id],
    );
    return job?.toInfo();
  }

  /// Starts a new background job.
  ///
  /// Returns immediately with a job in `running` status.
  /// The [run] function is executed in a separate isolate.
  Future<BackgroundJobInfo> start({
    String? id,
    required String type,
    String? title,
    Map<String, dynamic>? metadata,
    required Future<String> Function() run,
  }) async {
    final jobId = id ?? 'job_${DateTime.now().millisecondsSinceEpoch}';
    final startedAt = DateTime.now();

    final job = _Job(
      id: jobId,
      type: type,
      title: title,
      metadata: _sanitizeMetadata(metadata),
      status: BackgroundJobStatus.running,
      startedAt: startedAt,
    );

    await _lock.synchronized(() {
      _jobs[jobId] = job;
    });

    final receivePort = ReceivePort();
    job._receivePort = receivePort;

    _runIsolate(receivePort.sendPort, run)
        .then((result) => _completeJob(jobId, result, null))
        .catchError((error) => _completeJob(jobId, null, error as Object));

    return job.toInfo();
  }

  /// Extends a running job by appending follow-up work.
  ///
  /// Returns true if the job was found and extended, false otherwise.
  Future<bool> extend({
    required String id,
    required Future<String> Function() run,
  }) async {
    return await _lock.synchronized<bool>(() {
      final job = _jobs[id];
      if (job == null || job.status != BackgroundJobStatus.running) {
        return false;
      }

      job.sequence += 1;

      final receivePort = ReceivePort();
      job._receivePort = receivePort;

      _runIsolate(receivePort.sendPort, run)
          .then((result) => _completeJob(id, result, null))
          .catchError((error) => _completeJob(id, null, error));

      return true;
    });
  }

  /// Waits for a job to complete.
  ///
  /// Returns a record with the final job info and whether it timed out.
  Future<({BackgroundJobInfo? info, bool timedOut})> wait({
    required String id,
    Duration? timeout,
  }) async {
    final job = await _lock.synchronized(() => _jobs[id]);
    if (job == null) {
      return (info: null, timedOut: false);
    }

    final completer = Completer<BackgroundJobInfo>();
    job._waitCompleter = completer;

    BackgroundJobInfo? result;
    bool timedOut = false;

    if (timeout != null) {
      try {
        result = await completer.future.timeout(timeout);
      } on TimeoutException {
        timedOut = true;
      }
    } else {
      result = await completer.future;
    }

    return (info: result, timedOut: timedOut);
  }

  /// Waits until a job is promoted from background.
  Future<BackgroundJobInfo> waitForPromotion(String id) async {
    final job = await _lock.synchronized(() => _jobs[id]);
    if (job == null) {
      throw ArgumentError('Job not found: $id');
    }

    final completer = Completer<BackgroundJobInfo>();
    job._promotionCompleter = completer;
    return completer.future;
  }

  /// Promotes a background job.
  Future<BackgroundJobInfo?> promote(String id) async {
    final job = await _lock.synchronized(() => _jobs[id]);
    if (job == null) return null;

    job.status = BackgroundJobStatus.completed;
    job._promotionCompleter?.complete(job.toInfo());
    job._waitCompleter?.complete(job.toInfo());

    return job.toInfo();
  }

  /// Cancels a job.
  Future<BackgroundJobInfo?> cancel(String id) async {
    final job = await _lock.synchronized(() => _jobs[id]);
    if (job == null) return null;

    job.status = BackgroundJobStatus.cancelled;
    job._receivePort?.close();
    job._waitCompleter?.complete(job.toInfo());
    job._promotionCompleter?.complete(job.toInfo());

    return job.toInfo();
  }

  /// Cleans up completed jobs older than the specified age.
  Future<void> prune({Duration olderThan = const Duration(hours: 1)}) async {
    final cutoff = DateTime.now().subtract(olderThan);
    await _lock.synchronized(() {
      final keys = <String>[];
      for (final entry in _jobs.entries) {
        if (entry.value.status != BackgroundJobStatus.running &&
            entry.value.startedAt.isBefore(cutoff)) {
          keys.add(entry.key);
        }
      }
      for (final key in keys) {
        _jobs.remove(key);
      }
    });
  }

  void _completeJob(String id, String? result, Object? error) {
    final job = _jobs[id];
    if (job == null) return;

    if (error != null) {
      job.status = BackgroundJobStatus.error;
      job.error = _sanitizeString(error.toString());
    } else {
      job.status = BackgroundJobStatus.completed;
      job.output = result != null ? _sanitizeString(result) : null;
    }
    job.completedAt = DateTime.now();
    job._waitCompleter?.complete(job.toInfo());
    job._promotionCompleter?.complete(job.toInfo());
  }

  static Map<String, dynamic>? _sanitizeMetadata(
    Map<String, dynamic>? metadata,
  ) {
    if (metadata == null) return null;
    final sanitized = <String, dynamic>{};
    for (final entry in metadata.entries) {
      sanitized[entry.key] = _sanitizeValue(entry.value);
    }
    return Map<String, dynamic>.from(sanitized);
  }

  static dynamic _sanitizeValue(dynamic value) {
    if (value is String) return _sanitizeString(value);
    if (value is Map) {
      return {for (final e in value.entries) e.key: _sanitizeValue(e.value)};
    }
    if (value is List) {
      return value.map(_sanitizeValue).toList();
    }
    return value;
  }

  static String _sanitizeString(String input) {
    final secrets = RegExp(
      r'(api[_-]?key|token|password|secret|bearer)\s*[=:]\s*\S+',
      caseSensitive: false,
    );
    return input.replaceAll(secrets, r'$1=***');
  }

  static Future<String> _runIsolate(
    SendPort sendPort,
    Future<String> Function() fn,
  ) async {
    final result = await fn();
    sendPort.send(result);
    return result;
  }
}
