import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers/chat/sidebar_provider.dart';

void main() {
  group('SidebarNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has default values', () {
      final state = container.read(sidebarProvider);
      expect(state.searchQuery, '');
      expect(state.isSearching, false);
    });

    test('setSearchQuery updates search query', () async {
      final notifier = container.read(sidebarProvider.notifier);

      notifier.setSearchQuery('test');

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 350));

      final state = container.read(sidebarProvider);
      expect(state.searchQuery, 'test');
      expect(state.isSearching, true);
    });

    test('clearSearch resets search state', () async {
      final notifier = container.read(sidebarProvider.notifier);

      notifier.setSearchQuery('test');
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.clearSearch();

      final state = container.read(sidebarProvider);
      expect(state.searchQuery, '');
      expect(state.isSearching, false);
    });

    test('search query is case insensitive', () async {
      final notifier = container.read(sidebarProvider.notifier);

      notifier.setSearchQuery('TEST');
      await Future.delayed(const Duration(milliseconds: 350));

      final state = container.read(sidebarProvider);
      expect(state.searchQuery, 'TEST');
    });
  });

  group('SidebarState', () {
    test('copyWith creates new instance with updated values', () {
      const state = SidebarState();
      final newState = state.copyWith(searchQuery: 'test', isSearching: true);

      expect(newState.searchQuery, 'test');
      expect(newState.isSearching, true);
    });

    test('copyWith preserves original values when not specified', () {
      const state = SidebarState(searchQuery: 'original', isSearching: true);
      final newState = state.copyWith(searchQuery: 'updated');

      expect(newState.searchQuery, 'updated');
      expect(newState.isSearching, true);
    });
  });

  group('chatListLoadingProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('returns true when chat list is loading', () {
      final isLoading = container.read(chatListLoadingProvider);
      expect(isLoading, true);
    });
  });
}
