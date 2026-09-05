import 'package:chatorai/features/chat/presentation/widgets/chat_input/command_popup.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/slash_command_navigator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SlashCommandNavigator', () {
    final commands = const [
      SlashCommand('/a', 'A'),
      SlashCommand('/b', 'B'),
      SlashCommand('/c', 'C'),
    ];

    test('starts at index 0', () {
      final nav = SlashCommandNavigator(commands: commands);
      expect(nav.selectedIndex, 0);
      expect(nav.selected?.name, '/a');
    });

    test('navigate down cycles forward', () {
      final nav = SlashCommandNavigator(commands: commands);
      nav.navigate(true);
      expect(nav.selectedIndex, 1);
      expect(nav.selected?.name, '/b');
      nav.navigate(true);
      expect(nav.selectedIndex, 2);
      expect(nav.selected?.name, '/c');
      nav.navigate(true);
      expect(nav.selectedIndex, 0);
      expect(nav.selected?.name, '/a');
    });

    test('navigate up cycles backward', () {
      final nav = SlashCommandNavigator(commands: commands);
      nav.navigate(false);
      expect(nav.selectedIndex, 2);
      expect(nav.selected?.name, '/c');
      nav.navigate(false);
      expect(nav.selectedIndex, 1);
      expect(nav.selected?.name, '/b');
      nav.navigate(false);
      expect(nav.selectedIndex, 0);
      expect(nav.selected?.name, '/a');
    });

    test('mixed down/up cycles correctly', () {
      final nav = SlashCommandNavigator(commands: commands);
      nav.navigate(true);
      nav.navigate(true);
      expect(nav.selectedIndex, 2);
      nav.navigate(false);
      expect(nav.selectedIndex, 1);
      nav.navigate(false);
      nav.navigate(false);
      expect(nav.selectedIndex, 2);
      expect(nav.selected?.name, '/c');
    });

    test('does nothing on empty commands', () {
      final nav = SlashCommandNavigator(commands: const []);
      nav.navigate(true);
      nav.navigate(false);
      expect(nav.selectedIndex, 0);
      expect(nav.selected, isNull);
    });

    test('matchesSelection returns true for selected command', () {
      final nav = SlashCommandNavigator(commands: commands);
      expect(nav.matchesSelection('/a'), isTrue);
      expect(nav.matchesSelection('/b'), isFalse);
      nav.navigate(true);
      expect(nav.matchesSelection('/b'), isTrue);
    });
  });
}
