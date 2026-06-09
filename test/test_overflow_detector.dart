import 'package:chatorai/core/context/overflow_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverflowDetector', () {
    test('forModel uses provided context length', () {
      final detector = OverflowDetector.forModel(100000);
      expect(detector.contextLimit, 100000);
    });

    test(
      'forModel calculates reserved buffer as min(20000, contextLimit ~/ 10)',
      () {
        final detector = OverflowDetector.forModel(300000);
        expect(detector.reservedBuffer, 20000); // 300000~/10=30000, min=20000
        final detector2 = OverflowDetector.forModel(50000);
        expect(detector2.reservedBuffer, 5000); // 50000~/10=5000, min=5000
      },
    );

    test('usable returns contextLimit - reservedBuffer', () {
      final detector = OverflowDetector.forModel(100000);
      // 100000 ~/10 = 10000, min(20000,10000)=10000 -> usable 90000
      expect(detector.usable, 90000);
    });

    test('isOverflow returns true when totalTokens >= usable', () {
      final detector = OverflowDetector.forModel(100000);
      expect(detector.isOverflow(89999), false);
      expect(detector.isOverflow(90000), true);
      expect(detector.isOverflow(100000), true);
    });
  });
}
