// Unit tests for ChatScreen auto-scroll logic
// Tests the scroll behavior in isolation using a test double

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

// ===========================================================================
// TEST DOUBLE: Mock ScrollController and ScrollPosition
// ===========================================================================

class MockScrollPosition {
  double _offset;
  final double viewportDimension;
  final double maxScrollExtent;
  bool hasContentDimensions = true;

  MockScrollPosition({
    required double initialScrollOffset,
    required this.viewportDimension,
    required this.maxScrollExtent,
  }) : _offset = initialScrollOffset;

  double get offset => _offset;

  void goTo(double newOffset) {
    _offset = newOffset.clamp(0.0, maxScrollExtent);
  }
}

class MockScrollController {
  bool _hasClients = false;
  MockScrollPosition? _position;

  bool get hasClients => _hasClients;

  MockScrollPosition get position {
    if (_position == null) {
      throw StateError('ScrollController has no attached position');
    }
    return _position!;
  }

  void attach(MockScrollPosition position) {
    _position = position;
    _hasClients = true;
  }

  void detach() {
    _hasClients = false;
    _position = null;
  }

  // Recording
  bool animateToCalled = false;
  bool jumpToCalled = false;
  double? animateToTarget;
  double? jumpToTarget;
  Duration? animateToDuration;
  Curve? animateToCurve;

  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) async {
    animateToCalled = true;
    animateToTarget = offset;
    animateToDuration = duration;
    animateToCurve = curve;
    if (_hasClients && _position != null) {
      _position!.goTo(offset);
    }
  }

  void jumpTo(double value) {
    jumpToCalled = true;
    jumpToTarget = value;
    if (_hasClients && _position != null) {
      _position!.goTo(value);
    }
  }

  void reset() {
    animateToCalled = false;
    jumpToCalled = false;
    animateToTarget = null;
    jumpToTarget = null;
    animateToDuration = null;
    animateToCurve = null;
  }
}

// ===========================================================================
// CLASS UNDER TEST: ScrollHandler (mirrors _ChatScreenState scroll logic)
// ===========================================================================

class ScrollHandler {
  final MockScrollController controller;
  bool autoScrollEnabled = true;

  ScrollHandler(this.controller);

  void handleScroll() {
    if (!controller.hasClients) return;

    final offset = controller.position.offset;
    final max = controller.position.maxScrollExtent;
    final distanceFromBottom = max - offset;
    final newAutoScroll = distanceFromBottom <= 150;

    if (autoScrollEnabled != newAutoScroll) {
      autoScrollEnabled = newAutoScroll;
    }
  }

  void scrollToBottom({bool force = false}) {
    if (!controller.hasClients) {
      return;
    }

    final position = controller.position;
    if (!position.hasContentDimensions) {
      return;
    }

    final maxScroll = position.maxScrollExtent;
    final currentScroll = controller.position.offset;
    final diff = (maxScroll - currentScroll).abs();

    if (!force && diff < 5) {
      return;
    }

    if (force) {
      controller.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      controller.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }
}

// ===========================================================================
// TESTS
// ===========================================================================

void main() {
  group('ScrollHandler Auto-Scroll Logic', () {
    late MockScrollController controller;
    late ScrollHandler handler;

    setUp(() {
      controller = MockScrollController();
      handler = ScrollHandler(controller);
    });

    test(
      'handleScroll: autoScrollEnabled = true when near bottom (<=150px)',
      () {
        final position = MockScrollPosition(
          initialScrollOffset: 0,
          viewportDimension: 800,
          maxScrollExtent: 2000,
        );
        controller.attach(position);

        // Start at top: distance = 2000 > 150
        position.goTo(0);
        handler.handleScroll();
        expect(handler.autoScrollEnabled, isFalse);

        // Move to 1900 (100 from bottom)
        position.goTo(1900);
        handler.handleScroll();
        expect(handler.autoScrollEnabled, isTrue);

        // Move to 2000 (0 from bottom)
        position.goTo(2000);
        handler.handleScroll();
        expect(handler.autoScrollEnabled, isTrue);
      },
    );

    test(
      'handleScroll: autoScrollEnabled = false when far from bottom (>150px)',
      () {
        final position = MockScrollPosition(
          initialScrollOffset: 0,
          viewportDimension: 800,
          maxScrollExtent: 2000,
        );
        controller.attach(position);

        position.goTo(500); // 1500 from bottom
        handler.handleScroll();
        expect(handler.autoScrollEnabled, isFalse);

        position.goTo(1000); // 1000 from bottom
        handler.handleScroll();
        expect(handler.autoScrollEnabled, isFalse);
      },
    );

    test('handleScroll: does not change state if value unchanged', () {
      final position = MockScrollPosition(
        initialScrollOffset: 0,
        viewportDimension: 800,
        maxScrollExtent: 2000,
      );
      controller.attach(position);

      position.goTo(1900);
      handler.handleScroll();
      expect(handler.autoScrollEnabled, isTrue);

      // Call again without moving
      handler.handleScroll();
      expect(handler.autoScrollEnabled, isTrue);

      // Move to top
      position.goTo(0);
      handler.handleScroll();
      expect(handler.autoScrollEnabled, isFalse);

      // Call again without moving
      handler.handleScroll();
      expect(handler.autoScrollEnabled, isFalse);
    });

    test('handleScroll: returns early if controller has no clients', () {
      // Do not attach any position
      handler.autoScrollEnabled = true;
      handler.handleScroll();
      // Should not throw and should remain true (no change)
      expect(handler.autoScrollEnabled, isTrue);
    });

    test('scrollToBottom: force=true calls animateTo with correct params', () {
      final position = MockScrollPosition(
        initialScrollOffset: 0,
        viewportDimension: 800,
        maxScrollExtent: 2000,
      );
      controller.attach(position);
      position.goTo(0);

      handler.scrollToBottom(force: true);

      expect(controller.animateToCalled, isTrue);
      expect(controller.animateToTarget, 2000);
      expect(controller.animateToDuration, const Duration(milliseconds: 300));
      expect(controller.animateToCurve, Curves.easeOut);
      expect(controller.jumpToCalled, isFalse);
      // Verify position updated
      expect(controller.position.offset, 2000);
    });

    test(
      'scrollToBottom: force=false calls animateTo with 150ms when far from bottom',
      () {
        final position = MockScrollPosition(
          initialScrollOffset: 0,
          viewportDimension: 800,
          maxScrollExtent: 2000,
        );
        controller.attach(position);
        position.goTo(0);

        controller.reset();
        handler.scrollToBottom(force: false);

        expect(controller.animateToCalled, isTrue);
        expect(controller.animateToTarget, 2000);
        expect(controller.animateToDuration, const Duration(milliseconds: 150));
        expect(controller.animateToCurve, Curves.easeOut);
        expect(controller.jumpToCalled, isFalse);
        // Position updated immediately in mock
        expect(controller.position.offset, 2000);
      },
    );

    test('scrollToBottom: force=false does nothing if diff < 5px', () {
      final position = MockScrollPosition(
        initialScrollOffset: 0,
        viewportDimension: 800,
        maxScrollExtent: 2000,
      );
      controller.attach(position);
      position.goTo(1998); // 2px from bottom

      controller.reset();
      handler.scrollToBottom(force: false);

      expect(controller.jumpToCalled, isFalse);
      expect(controller.animateToCalled, isFalse);
      // Position unchanged
      expect(controller.position.offset, 1998);
    });

    test('scrollToBottom: returns early if no clients', () {
      // Not attached
      handler.scrollToBottom(force: true);
      expect(controller.animateToCalled, isFalse);
    });

    test('scrollToBottom: returns early if no content dimensions', () {
      final position = MockScrollPosition(
        initialScrollOffset: 0,
        viewportDimension: 800,
        maxScrollExtent: 2000,
      );
      position.hasContentDimensions = false;
      controller.attach(position);
      position.goTo(0);

      handler.scrollToBottom(force: true);
      expect(controller.animateToCalled, isFalse);
    });
  });
}
