import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/session_id.dart';

void main() {
  group('SessionID', () {
    test('create generates valid ID', () {
      final id = SessionID.create();
      expect(id.value.startsWith('ses_'), isTrue);
    });

    test('create generates unique IDs', () {
      final id1 = SessionID.create();
      final id2 = SessionID.create();
      expect(id1.value, isNot(id2.value));
    });

    test('fromString parses valid ID', () {
      final id = SessionID.create();
      final parsed = SessionID.fromString(id.value);
      expect(parsed, id);
    });

    test('fromString throws on invalid prefix', () {
      expect(() => SessionID.fromString('invalid_prefix'), throwsArgumentError);
    });

    test('equality works', () {
      final id1 = SessionID.fromString('ses_abc');
      final id2 = SessionID.fromString('ses_abc');
      final id3 = SessionID.fromString('ses_def');

      expect(id1, id2);
      expect(id1, isNot(id3));
    });

    test('hashCode consistent with equality', () {
      final id1 = SessionID.fromString('ses_abc');
      final id2 = SessionID.fromString('ses_abc');

      expect(id1.hashCode, id2.hashCode);
    });

    test('toString returns value', () {
      final id = SessionID.fromString('ses_test');
      expect(id.toString(), 'ses_test');
    });
  });
}
