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

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SessionID && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
