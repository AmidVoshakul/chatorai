import 'package:test/test.dart';
import 'package:chatorai/core/permission/arity.dart';

void main() {
  group('bashArity', () {
    test('git checkout main → 2 (git has arity 2)', () {
      expect(bashArity['git'], equals(2));
    });

    test('npm run dev → 3 (npm run has arity 3)', () {
      expect(bashArity['npm run'], equals(3));
    });

    test('cat foo → 1 (cat has arity 1)', () {
      expect(bashArity['cat'], equals(1));
    });

    test('docker run nginx → 2 (docker has arity 2)', () {
      expect(bashArity['docker'], equals(2));
    });

    test('aws s3 ls → 3 (aws has arity 3)', () {
      expect(bashArity['aws'], equals(3));
    });
  });
}
