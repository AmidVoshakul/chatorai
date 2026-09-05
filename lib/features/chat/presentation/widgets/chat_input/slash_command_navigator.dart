import 'package:chatorai/features/chat/presentation/widgets/chat_input/command_popup.dart';

/// Cyclic navigation and selection helper for slash command and skill popups.
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
