import 'package:chatorai/core/tools/tool.dart';

/// Optional metadata attached to a tool definition at registration time.
class ToolTag {
  final String? category;
  final bool experimental;
  final bool hidden;

  const ToolTag({
    this.category,
    this.experimental = false,
    this.hidden = false,
  });

  const ToolTag.hidden() : category = null, experimental = false, hidden = true;

  const ToolTag.experimental(this.category)
    : experimental = true,
      hidden = false;
}

/// Wraps a [ToolDef] with optional lazy initialization and metadata.
///
/// Mirrors OpenCode's `define()` + `init()` pattern:
/// - `create()` — eager, already-initialized [ToolDef]
/// - `lazy()` — async factory for tools that need services at build time
class ToolDefinition {
  final String id;
  final ToolTag tag;

  ToolDefinition._({required this.id, required this.tag});

  /// Eager definition: the [def] is already fully initialized.
  factory ToolDefinition.create({
    required String id,
    ToolTag? tag,
    required ToolDef def,
  }) {
    return ToolDefinition._(id: id, tag: tag ?? const ToolTag())
      .._resolved = def;
  }

  /// Lazy definition: call [factory] when the registry resolves tools.
  /// Useful for tools that need injected services (e.g., ChatAiService).
  factory ToolDefinition.lazy({
    required String id,
    ToolTag? tag,
    required Future<ToolDef> Function() factory,
  }) {
    return ToolDefinition._(id: id, tag: tag ?? const ToolTag())
      .._factory = factory;
  }

  /// The resolved [ToolDef]. Throws if called on an unresolved lazy definition.
  ToolDef get def {
    final resolved = _resolved;
    if (resolved == null) {
      throw StateError(
        'ToolDefinition($id) has not been resolved. Call resolve() first.',
      );
    }
    return resolved;
  }

  bool get isResolved => _resolved != null;

  Future<ToolDef> resolve() async {
    if (_resolved != null) return _resolved!;
    if (_factory != null) {
      _resolved = await _factory!();
    }
    return _resolved!;
  }

  ToolDef? _resolved;
  Future<ToolDef> Function()? _factory;
}
