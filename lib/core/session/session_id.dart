import 'package:uuid/uuid.dart';

class SessionID {
  final String value;
  const SessionID._(this.value);

  factory SessionID.create() => SessionID._('ses_${const Uuid().v4()}');

  factory SessionID.fromString(String value) {
    if (!value.startsWith('ses_')) {
      throw ArgumentError('SessionID must start with "ses_", got: $value');
    }
    return SessionID._(value);
  }

  /// Single source of truth for normalizing a raw id that may be missing the
  /// `ses_` prefix (e.g. legacy chat ids). Never throws; only prepends.
  factory SessionID.fromRaw(String value) {
    return SessionID._(value.startsWith('ses_') ? value : 'ses_$value');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SessionID && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
