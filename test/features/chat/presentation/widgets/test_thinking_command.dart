import 'package:chatorai/core/commands/slash_command.dart';
import 'package:chatorai/core/commands/slash_command_navigator.dart';
import 'package:chatorai/gui/shared/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('/thinking command behavior', () {
    test('toggles expandReasoningByDefault via themeProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(themeProvider).expandReasoningByDefault;
      final toggled = !initial;

      container
          .read(themeProvider.notifier)
          .setExpandReasoningByDefault(toggled);
      expect(container.read(themeProvider).expandReasoningByDefault, toggled);

      container
          .read(themeProvider.notifier)
          .setExpandReasoningByDefault(initial);
      expect(container.read(themeProvider).expandReasoningByDefault, initial);
    });

    test('navigator selects /thinking command', () {
      final commands = const [SlashCommand('/thinking', 'Toggle reasoning')];
      final nav = SlashCommandNavigator(commands: commands);
      expect(nav.matchesSelection('/thinking'), isTrue);
    });
  });
}
