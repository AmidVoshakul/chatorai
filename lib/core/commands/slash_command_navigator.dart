import 'package:chatorai/core/commands/slash_command.dart';

/// Cyclic navigation and selection helper for slash-command palettes.
///
/// Pure-Dart, shared by GUI and TUI. Extracted from presentation so
/// `core/tui` can reuse the same cycling logic without depending on Flutter
/// widgets.
class SlashCommandNavigator {
  final List<SlashCommand> commands;
  int selectedIndex;

  SlashCommandNavigator({required this.commands, this.selectedIndex = 0});

  SlashCommand? get selected =>
      commands.isEmpty ? null : commands[selectedIndex];

  void navigate(bool down) {
    if (commands.isEmpty) return;
    final len = commands.length;
    selectedIndex = down
        ? (selectedIndex + 1) % len
        : (selectedIndex - 1 + len) % len;
  }

  bool matchesSelection(String name) =>
      selected != null && selected!.name == name;
}
