import 'dart:async';

import 'package:chatorai/core/mcp/mcp_status_provider.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input_status_bar.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/project_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';

Set<Color> _spanColors(WidgetTester tester) {
  final richText = tester.widget<RichText>(find.byType(RichText).first);
  final colors = <Color>{};
  void visit(InlineSpan span) {
    if (span is TextSpan && span.style?.color != null) {
      colors.add(span.style!.color!);
    }
    if (span is WidgetSpan) {
      Widget? child = span.child;
      if (child is Tooltip) child = child.child;
      if (child is Text && child.style?.color != null) {
        colors.add(child.style!.color!);
      }
    }
    if (span is TextSpan) {
      final children = span.children;
      if (children != null) {
        for (final child in children) {
          visit(child);
        }
      }
    }
  }

  visit(richText.text);
  return colors;
}

void main() {
  group('ChatInputStatusBar', () {
    testWidgets('shows cwd, branch and mcp count', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitBranchProvider.overrideWith((_) async => 'main'),
            mcpStatusesProvider.overrideWith(
              (_) async => {'s1': McpServerStatus.connected()},
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ChatInputStatusBar())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('MCP: 1/1'), findsOneWidget);
      expect(find.textContaining('⎇ main'), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText).first);
      expect(richText.text.toPlainText(), isNotEmpty);
    });

    testWidgets('hides mcp segment when no servers configured', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitBranchProvider.overrideWith((_) async => 'main'),
            mcpStatusesProvider.overrideWith((_) async => {}),
          ],
          child: const MaterialApp(home: Scaffold(body: ChatInputStatusBar())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('MCP:'), findsNothing);
    });

    testWidgets('hides branch segment when not in a git repo', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitBranchProvider.overrideWith((_) async => null),
            mcpStatusesProvider.overrideWith(
              (_) async => {'s1': McpServerStatus.connected()},
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ChatInputStatusBar())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('⎇'), findsNothing);
    });

    testWidgets('mcp segment is red when a server failed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitBranchProvider.overrideWith((_) async => null),
            mcpStatusesProvider.overrideWith(
              (_) async => {
                's1': McpServerStatus.connected(),
                's2': McpServerStatus.failed('boom'),
              },
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ChatInputStatusBar())),
        ),
      );
      await tester.pumpAndSettle();

      final colors = _spanColors(tester);
      expect(colors, contains(ChatoraiColors.error));
      expect(colors, isNot(contains(ChatoraiColors.success)));
    });

    testWidgets('mcp segment is red when a server needs auth', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitBranchProvider.overrideWith((_) async => null),
            mcpStatusesProvider.overrideWith(
              (_) async => {'s1': McpServerStatus.needsAuth()},
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ChatInputStatusBar())),
        ),
      );
      await tester.pumpAndSettle();

      expect(_spanColors(tester), contains(ChatoraiColors.error));
    });

    testWidgets('mcp segment is green when a server is connected', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitBranchProvider.overrideWith((_) async => null),
            mcpStatusesProvider.overrideWith(
              (_) async => {'s1': McpServerStatus.connected()},
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ChatInputStatusBar())),
        ),
      );
      await tester.pumpAndSettle();

      final colors = _spanColors(tester);
      expect(colors, contains(ChatoraiColors.success));
      expect(colors, isNot(contains(ChatoraiColors.error)));
    });

    testWidgets('mcp segment is gray when all servers are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitBranchProvider.overrideWith((_) async => null),
            mcpStatusesProvider.overrideWith(
              (_) async => {'s1': McpServerStatus.disabled()},
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ChatInputStatusBar())),
        ),
      );
      await tester.pumpAndSettle();

      final colors = _spanColors(tester);
      expect(colors, contains(ChatoraiColors.gray));
      expect(colors, isNot(contains(ChatoraiColors.error)));
      expect(colors, isNot(contains(ChatoraiColors.success)));
    });

    // Returns the list of per-server row RichTexts from the tooltip message.
    List<RichText> _tooltipRows(WidgetTester tester) {
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      final message = tooltip.richMessage as TextSpan;
      return message.children!
          .whereType<WidgetSpan>()
          .map((w) => (w.child as Padding).child as RichText)
          .toList();
    }

    (String name, Color dotColor, Color statusColor) _rowParts(
      RichText richText,
    ) {
      final children = (richText.text as TextSpan).children!;
      final nameSpan = children[1] as TextSpan;
      final statusSpan = children[2] as TextSpan;
      final dot = (children[0] as WidgetSpan).child as Container;
      return (
        nameSpan.toPlainText().replaceAll(': ', ''),
        (dot.decoration as BoxDecoration).color!,
        statusSpan.style!.color!,
      );
    }

    testWidgets('mcp segment tooltip lists server names and statuses', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitBranchProvider.overrideWith((_) async => null),
            mcpStatusesProvider.overrideWith(
              (_) async => {
                'alpha': McpServerStatus.connected(),
                'beta': McpServerStatus.failed('boom'),
              },
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ChatInputStatusBar())),
        ),
      );
      await tester.pumpAndSettle();

      final rows = _tooltipRows(tester);
      expect(rows, hasLength(2));
      final names = rows.map((r) => _rowParts(r).$1).toList();
      expect(names, contains('alpha'));
      expect(names, contains('beta'));
      // connected → green dot + gray status; failed → red dot + gray status
      final alpha = _rowParts(rows.first);
      final beta = _rowParts(rows.last);
      expect(alpha.$2, ChatoraiColors.success);
      expect(alpha.$3, ChatoraiColors.gray);
      expect(beta.$2, ChatoraiColors.error);
      expect(beta.$3, ChatoraiColors.gray);
    });

    testWidgets('status label "connected" is gray in tooltip', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitBranchProvider.overrideWith((_) async => null),
            mcpStatusesProvider.overrideWith(
              (_) async => {'alpha': McpServerStatus.connected()},
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ChatInputStatusBar())),
        ),
      );
      await tester.pumpAndSettle();

      final rows = _tooltipRows(tester);
      expect(rows, hasLength(1));
      final parts = _rowParts(rows.first);
      expect(parts.$1, 'alpha');
      expect(parts.$2, ChatoraiColors.success);
      expect(parts.$3, ChatoraiColors.gray);
    });

    testWidgets('shows spinner while mcp statuses are loading', (tester) async {
      final completer = Completer<Map<String, McpServerStatus>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitBranchProvider.overrideWith((_) async => null),
            mcpStatusesProvider.overrideWith((_) => completer.future),
          ],
          child: const MaterialApp(home: Scaffold(body: ChatInputStatusBar())),
        ),
      );
      await tester.pump();

      expect(find.byType(SpinKitCircle), findsOneWidget);
      expect(find.textContaining('MCP:'), findsNothing);

      completer.complete({'alpha': McpServerStatus.connected()});
      await tester.pumpAndSettle();

      expect(find.byType(SpinKitCircle), findsNothing);
      expect(find.textContaining('MCP: 1/1'), findsOneWidget);
    });
  });
}
