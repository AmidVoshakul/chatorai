import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/session_runner.dart';

void main() {
  group('SessionRunnerHolder child→task routing', () {
    test('registerChild maps each child to its own task part', () {
      final holder = SessionRunnerHolder(null, parentSessionId: 'parent');
      holder.registerChild('child_a', 'part_a');
      holder.registerChild('child_b', 'part_b');

      expect(holder.childToTaskPart['child_a'], 'part_a');
      expect(holder.childToTaskPart['child_b'], 'part_b');
      expect(holder.taskPartForChild('child_a'), 'part_a');
      expect(holder.taskPartForChild('child_b'), 'part_b');
    });

    test('unregisterChild removes both directions', () {
      final holder = SessionRunnerHolder(null, parentSessionId: 'parent');
      holder.registerChild('child_a', 'part_a');
      holder.unregisterChild('child_a');

      expect(holder.childToTaskPart.containsKey('child_a'), isFalse);
      expect(holder.taskPartToChild.containsKey('part_a'), isFalse);
    });
  });
}
