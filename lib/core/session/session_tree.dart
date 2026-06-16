import 'session_id.dart';

class SessionTreeNode {
  final SessionID id;
  final String title;
  final List<SessionTreeNode> children;

  const SessionTreeNode({
    required this.id,
    this.title = '',
    this.children = const [],
  });

  SessionTreeNode copyWith({List<SessionTreeNode>? children, String? title}) {
    return SessionTreeNode(
      id: id,
      title: title ?? this.title,
      children: children ?? this.children,
    );
  }
}

class SessionTree {
  final SessionID rootId;
  final Map<SessionID, SessionTreeNode> _nodes = {};
  final Map<SessionID, SessionID?> _parents = {};
  final Map<SessionID, List<SessionID>> _children = {};

  SessionTree(this.rootId);

  SessionTreeNode? getNode(SessionID id) => _nodes[id];

  SessionID? getParent(SessionID id) => _parents[id];

  List<SessionID> getChildren(SessionID id) => _children[id] ?? [];

  bool contains(SessionID id) => _nodes.containsKey(id);

  int get size => _nodes.length;

  void addNode(SessionID id, {SessionID? parentId, String title = ''}) {
    if (_nodes.containsKey(id)) {
      _nodes[id] = _nodes[id]!.copyWith(title: title);
      return;
    }
    _nodes[id] = SessionTreeNode(id: id, title: title);
    _parents[id] = parentId;
    if (parentId != null) {
      _children.putIfAbsent(parentId, () => []).add(id);
    }
  }

  void removeNode(SessionID id) {
    final descendants = _getAllDescendants(id);
    for (final d in [id, ...descendants]) {
      _nodes.remove(d);
      final parentId = _parents.remove(d);
      if (parentId != null) {
        _children[parentId]?.remove(d);
        if (_children[parentId]?.isEmpty ?? false) {
          _children.remove(parentId);
        }
      }
    }
  }

  List<SessionID> getAncestors(SessionID id) {
    final ancestors = <SessionID>[];
    SessionID? current = id;
    while (current != null && _nodes.containsKey(current)) {
      ancestors.insert(0, current);
      current = _parents[current];
    }
    return ancestors;
  }

  List<SessionID> getDescendants(SessionID id) {
    return _getAllDescendants(id);
  }

  void traverse(void Function(SessionID id, int depth) visit) {
    _traverseNode(rootId, 0, visit);
  }

  SessionID? findFirst(bool Function(SessionID id) predicate) {
    for (final id in _nodes.keys) {
      if (predicate(id)) return id;
    }
    return null;
  }

  int depthOf(SessionID id) {
    int depth = 0;
    SessionID? current = _parents[id];
    while (current != null) {
      depth++;
      current = _parents[current];
    }
    return depth;
  }

  List<SessionID> _getAllDescendants(SessionID id) {
    final result = <SessionID>[];
    final queue = List<SessionID>.from(_children[id] ?? []);
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);
      queue.addAll(_children[current] ?? []);
    }
    return result;
  }

  void _traverseNode(
    SessionID id,
    int depth,
    void Function(SessionID id, int depth) visit,
  ) {
    visit(id, depth);
    for (final child in _children[id] ?? []) {
      _traverseNode(child, depth + 1, visit);
    }
  }
}
