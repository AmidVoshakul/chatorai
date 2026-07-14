import 'package:drift/drift.dart';
import 'package:chatorai/core/session/database.dart';

class SessionSnapshotService {
  final AppDatabase _db;

  SessionSnapshotService(this._db);

  Future<void> record({
    required String sessionId,
    required String stepNumber,
    required String request,
    required String response,
    String? toolCallId,
    String? toolName,
    int tokensInput = 0,
    int tokensOutput = 0,
  }) async {
    final id = 'snap_${DateTime.now().microsecondsSinceEpoch}_$stepNumber';
    await _db
        .into(_db.sessionSnapshots)
        .insert(
          SessionSnapshotsCompanion.insert(
            id: id,
            sessionId: sessionId,
            stepNumber: stepNumber,
            request: request,
            response: response,
            toolCallId: toolCallId == null
                ? const Value.absent()
                : Value(toolCallId),
            toolName: toolName == null ? const Value.absent() : Value(toolName),
            tokensInput: Value(tokensInput),
            tokensOutput: Value(tokensOutput),
            createdAt: DateTime.now(),
          ),
        );
  }
}
