import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/core/keyboard/keyboard_shortcut.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KeybindingNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    ref.listen(configProvider, (previous, next) {
      final config = next.value;
      if (config != null) state = _parse(config.keybinding);
    });
    return _parse(ref.read(configProvider).value?.keybinding);
  }

  Map<String, String> _parse(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    return Map<String, String>.fromEntries(
      raw.entries
          .where((e) => e.value is String)
          .map((e) => MapEntry(e.key, e.value as String)),
    );
  }

  KeyActivator? activatorFor(String id) {
    final override = state[id];
    if (override == null) return null;
    return KeyActivator.fromString(override);
  }

  Future<void> setBinding(String id, String combo) async {
    final activator = KeyActivator.fromString(combo);
    final hasModifier =
        activator.ctrl || activator.shift || activator.alt || activator.meta;
    if (!hasModifier) {
      final isNonPrintable =
          activator.key == LogicalKeyboardKey.escape ||
          activator.key == LogicalKeyboardKey.tab ||
          activator.key == LogicalKeyboardKey.home ||
          activator.key == LogicalKeyboardKey.end ||
          activator.key == LogicalKeyboardKey.arrowLeft ||
          activator.key == LogicalKeyboardKey.arrowRight ||
          activator.key == LogicalKeyboardKey.arrowUp ||
          activator.key == LogicalKeyboardKey.arrowDown;
      if (!isNonPrintable) {
        throw FormatException(
          'Bare printable keys are not allowed as shortcuts',
        );
      }
    }
    final updated = Map<String, String>.from(state)..[id] = activator.format();
    await ConfigWriter.upsertKeybindingSection(updated);
    state = updated;
  }

  Future<void> resetToDefaults() async {
    await ConfigWriter.upsertKeybindingSection({});
    state = {};
  }

  Set<String> conflicts() {
    final comboToIds = <String, List<String>>{};
    for (final entry in state.entries) {
      final ids = comboToIds.putIfAbsent(entry.value, () => []);
      ids.add(entry.key);
    }
    final conflicts = <String>{};
    for (final ids in comboToIds.values) {
      if (ids.length > 1) conflicts.addAll(ids);
    }
    return conflicts;
  }
}

final keybindingProvider =
    NotifierProvider<KeybindingNotifier, Map<String, String>>(
      KeybindingNotifier.new,
    );
