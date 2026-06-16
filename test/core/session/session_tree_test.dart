import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_tree.dart';

void main() {
  group('SessionTree', () {
    test('addNode and getNode', () {
      final root = SessionID.create();
      final tree = SessionTree(root);
      tree.addNode(root, title: 'Root');

      final node = tree.getNode(root);
      expect(node, isNotNull);
      expect(node!.title, 'Root');
    });

    test('parent-child relationships', () {
      final parent = SessionID.create();
      final child = SessionID.create();
      final tree = SessionTree(parent);

      tree.addNode(parent, title: 'Parent');
      tree.addNode(child, parentId: parent, title: 'Child');

      expect(tree.getParent(child), parent);
      expect(tree.getChildren(parent), [child]);
      expect(tree.contains(child), isTrue);
    });

    test('getAncestors returns path to root', () {
      final root = SessionID.create();
      final child1 = SessionID.create();
      final child2 = SessionID.create();
      final tree = SessionTree(root);

      tree.addNode(root, title: 'Root');
      tree.addNode(child1, parentId: root, title: 'Level 1');
      tree.addNode(child2, parentId: child1, title: 'Level 2');

      final ancestors = tree.getAncestors(child2);
      expect(ancestors, [root, child1, child2]);
    });

    test('getDescendants returns all children', () {
      final root = SessionID.create();
      final child1 = SessionID.create();
      final child2 = SessionID.create();
      final grandchild = SessionID.create();
      final tree = SessionTree(root);

      tree.addNode(root);
      tree.addNode(child1, parentId: root);
      tree.addNode(child2, parentId: root);
      tree.addNode(grandchild, parentId: child1);

      final descendants = tree.getDescendants(root);
      expect(descendants, containsAll([child1, child2, grandchild]));
      expect(descendants.length, 3);
    });

    test('depthOf returns correct depth', () {
      final root = SessionID.create();
      final child = SessionID.create();
      final grandchild = SessionID.create();
      final tree = SessionTree(root);

      tree.addNode(root);
      tree.addNode(child, parentId: root);
      tree.addNode(grandchild, parentId: child);

      expect(tree.depthOf(root), 0);
      expect(tree.depthOf(child), 1);
      expect(tree.depthOf(grandchild), 2);
    });

    test('removeNode removes node and descendants', () {
      final root = SessionID.create();
      final child = SessionID.create();
      final grandchild = SessionID.create();
      final tree = SessionTree(root);

      tree.addNode(root);
      tree.addNode(child, parentId: root);
      tree.addNode(grandchild, parentId: child);

      tree.removeNode(child);

      expect(tree.contains(child), isFalse);
      expect(tree.contains(grandchild), isFalse);
      expect(tree.contains(root), isTrue);
    });

    test('traverse visits all nodes root-to-leaves', () {
      final root = SessionID.create();
      final a = SessionID.create();
      final b = SessionID.create();
      final tree = SessionTree(root);

      tree.addNode(root);
      tree.addNode(a, parentId: root);
      tree.addNode(b, parentId: root);

      final visited = <SessionID>[];
      tree.traverse((id, depth) => visited.add(id));

      expect(visited, [root, a, b]);
    });

    test('findFirst finds matching node', () {
      final root = SessionID.create();
      final tree = SessionTree(root);
      tree.addNode(root);

      final found = tree.findFirst((id) => id == root);
      expect(found, root);
    });

    test('findFirst returns null when no match', () {
      final root = SessionID.create();
      final tree = SessionTree(root);

      final found = tree.findFirst((id) => false);
      expect(found, isNull);
    });

    test('size returns node count', () {
      final root = SessionID.create();
      final child = SessionID.create();
      final tree = SessionTree(root);

      tree.addNode(root);
      expect(tree.size, 1);

      tree.addNode(child, parentId: root);
      expect(tree.size, 2);
    });

    test('getChildren returns empty for leaf nodes', () {
      final root = SessionID.create();
      final tree = SessionTree(root);
      tree.addNode(root);

      expect(tree.getChildren(root), isEmpty);
    });
  });
}
