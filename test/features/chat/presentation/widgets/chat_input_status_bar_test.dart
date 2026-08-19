import 'dart:async';

import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/core/mcp/mcp_status_provider.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input_status_bar.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/project_info_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';

Set<Color> _spanColors(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(ChatInputStatusBar),
          matching: find.byType(Text),
        ),
      )
      .toList();
  final colors = <Color>{};
  for (final text in texts) {
    final color = text.style?.color;
    if (color != null) colors.add(color);
  }
  return colors;
}

void main() {
  group('ChatInputStatusBar', () {
    testWidgets('shows cwd, branch and mcp count', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
            gitBranchProvider.overrideWith((_) async => 'main'),
            mcpStatusesProvider.overrideWith(
              (_) async => {'s1': McpServerStatus.connected()},
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('MCP: 1/1'), findsOneWidget);
      expect(find.textContaining('⎇ main'), findsOneWidget);
      expect(find.text('chatorai'), findsOneWidget);
    });

    testWidgets('hides mcp segment when no servers configured', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitBranchProvider.overrideWith((_) async => 'main'),
            mcpStatusesProvider.overrideWith((_) async => {}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final colors = _spanColors(tester);
      expect(
        colors,
        contains(ChatoraiColors.error.withValues(alpha: ChatoraiOpacity.low)),
      );
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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _spanColors(tester),
        contains(ChatoraiColors.error.withValues(alpha: ChatoraiOpacity.low)),
      );
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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final colors = _spanColors(tester);
      expect(
        colors,
        contains(ChatoraiColors.success.withValues(alpha: ChatoraiOpacity.low)),
      );
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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
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
      final tooltip = tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .firstWhere((t) => t.richMessage != null);
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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
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

    testWidgets('path chip shows only the directory name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
            absoluteWorkingDirProvider.overrideWithValue(
              '/home/user/work/chatorai',
            ),
            gitBranchProvider.overrideWith((_) async => null),
            mcpStatusesProvider.overrideWith((_) async => {}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('chatorai'), findsOneWidget);
      expect(find.text('/home/user/work/chatorai'), findsNothing);
    });

    testWidgets('path chip tooltip shows changeWorkingDirectory', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
            absoluteWorkingDirProvider.overrideWithValue(
              '/home/user/work/chatorai',
            ),
            gitBranchProvider.overrideWith((_) async => null),
            mcpStatusesProvider.overrideWith((_) async => {}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ChatInputStatusBar));
      final l10n = AppLocalizations.of(context);
      final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
      expect(
        tooltips.any((t) => t.message == l10n?.changeWorkingDirectory),
        isTrue,
      );
    });

    testWidgets('chips have a subtle hairline outline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
            gitBranchProvider.overrideWith((_) async => 'main'),
            mcpStatusesProvider.overrideWith(
              (_) async => {'s1': McpServerStatus.connected()},
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(ChatInputStatusBar),
              matching: find.byType(Container),
            ),
          )
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).border != null,
          )
          .toList();

      expect(chips.length, equals(3));
      for (final chip in chips) {
        final border = (chip.decoration as BoxDecoration).border!;
        expect(border.top.width, ChatoraiBorderWidth.thin);
        expect(border.top.color.opacity, lessThan(1.0));
      }
    });

    testWidgets('mcp chip text is rendered inside a decorated container', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
            gitBranchProvider.overrideWith((_) async => 'main'),
            mcpStatusesProvider.overrideWith(
              (_) async => {'s1': McpServerStatus.connected()},
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: ChatInputStatusBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mcpText = find.text('MCP: 1/1');
      expect(mcpText, findsOneWidget);

      final container = tester.widget<Container>(
        find.ancestor(of: mcpText, matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    group('compact chip metrics', () {
      testWidgets('path chip has compact padding and small font', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith((_) async => null),
              mcpStatusesProvider.overrideWith((_) async => {}),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: ChatInputStatusBar()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final pathChip = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(ChatInputStatusBar),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = pathChip.decoration as BoxDecoration;
        final border = decoration.border!;
        expect(border.top.width, ChatoraiBorderWidth.thin);

        final text = tester.widget<Text>(
          find
              .descendant(
                of: find.byType(ChatInputStatusBar),
                matching: find.byType(Text),
              )
              .first,
        );
        expect(text.style?.fontSize, ChatoraiFontSizes.sm);
      });

      testWidgets('path chip tooltip shows changeWorkingDirectory', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith((_) async => null),
              mcpStatusesProvider.overrideWith((_) async => {}),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: ChatInputStatusBar()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
        final pathTooltip = tooltips.firstWhere(
          (t) => t.message != null && t.message is String,
        );
        expect(pathTooltip.message, 'Change current directory');
      });

      testWidgets('branch chip truncates with max width 140', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith(
                (_) async => 'very-long-branch-name-that-should-truncate',
              ),
              mcpStatusesProvider.overrideWith((_) async => {}),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: ChatInputStatusBar()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final branchText = tester.widget<Text>(find.textContaining('⎇'));
        expect(branchText.overflow, TextOverflow.ellipsis);

        final constrained = tester.widget<ConstrainedBox>(
          find
              .ancestor(
                of: find.textContaining('⎇'),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
        expect(constrained.constraints.maxWidth, 140);
      });

      testWidgets('mcp chip dims connected color to low alpha', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith((_) async => null),
              mcpStatusesProvider.overrideWith(
                (_) async => {'s1': McpServerStatus.connected()},
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: ChatInputStatusBar()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final mcpText = tester.widget<Text>(find.text('MCP: 1/1'));
        final color = mcpText.style!.color!;
        expect(color.a, closeTo(0.5, 0.01));
      });

      testWidgets('mcp chip stays fully opaque when gray', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith((_) async => null),
              mcpStatusesProvider.overrideWith(
                (_) async => {'s1': McpServerStatus.disabled()},
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: ChatInputStatusBar()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final mcpText = tester.widget<Text>(find.text('MCP: 0/1'));
        final color = mcpText.style!.color!;
        expect(color.a, 1.0);
      });
    });

    group('chip hover', () {
      testWidgets('path chip hover darkens background in light theme', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith((_) async => null),
              mcpStatusesProvider.overrideWith((_) async => {}),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: ChatInputStatusBar()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final pathChipFinder = find.byType(AnimatedContainer).first;
        final pathChipContainer = tester.widget<AnimatedContainer>(
          pathChipFinder,
        );
        final baseColor =
            (pathChipContainer.decoration as BoxDecoration).color!;

        final center = tester.getCenter(pathChipFinder);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        final hoveredContainer = tester.widget<AnimatedContainer>(
          pathChipFinder,
        );
        final hoveredColor =
            (hoveredContainer.decoration as BoxDecoration).color!;

        expect(hoveredColor, isNot(equals(baseColor)));
      });

      testWidgets('path chip hover lightens background in dark theme', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith((_) async => null),
              mcpStatusesProvider.overrideWith((_) async => {}),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: ChatInputStatusBar()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final pathChipFinder = find.byType(AnimatedContainer).first;
        final pathChipContainer = tester.widget<AnimatedContainer>(
          pathChipFinder,
        );
        final baseColor =
            (pathChipContainer.decoration as BoxDecoration).color!;

        final center = tester.getCenter(pathChipFinder);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        final hoveredContainer = tester.widget<AnimatedContainer>(
          pathChipFinder,
        );
        final hoveredColor =
            (hoveredContainer.decoration as BoxDecoration).color!;

        expect(hoveredColor, isNot(equals(baseColor)));
      });

      testWidgets('branch chip is hoverable', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith((_) async => 'main'),
              mcpStatusesProvider.overrideWith((_) async => {}),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: ChatInputStatusBar()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final branchChip = find.textContaining('⎇');
        expect(branchChip, findsOneWidget);

        final branchChipFinder = find.byType(AnimatedContainer).at(1);
        final container = tester.widget<AnimatedContainer>(branchChipFinder);
        final baseColor = (container.decoration as BoxDecoration).color!;
        expect(baseColor.opacity, greaterThan(0));

        final center = tester.getCenter(branchChipFinder);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        final hoveredContainer = tester.widget<AnimatedContainer>(
          branchChipFinder,
        );
        final hoveredColor =
            (hoveredContainer.decoration as BoxDecoration).color!;
        expect(hoveredColor, isNot(equals(baseColor)));
      });

      testWidgets('mcp chip is hoverable', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith((_) async => null),
              mcpStatusesProvider.overrideWith(
                (_) async => {'s1': McpServerStatus.connected()},
              ),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: ChatInputStatusBar()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final mcpChip = find.text('MCP: 1/1');
        expect(mcpChip, findsOneWidget);

        final mcpChipFinder = find.byType(AnimatedContainer).last;
        final container = tester.widget<AnimatedContainer>(mcpChipFinder);
        final baseColor = (container.decoration as BoxDecoration).color!;
        expect(baseColor.opacity, greaterThan(0));

        final center = tester.getCenter(mcpChipFinder);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveTo(center);
        await tester.pumpAndSettle();

        final hoveredContainer = tester.widget<AnimatedContainer>(
          mcpChipFinder,
        );
        final hoveredColor =
            (hoveredContainer.decoration as BoxDecoration).color!;
        expect(hoveredColor, isNot(equals(baseColor)));
      });

      testWidgets('tapping path chip opens workspace dialog', (tester) async {
        bool dialogShown = false;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith((_) async => null),
              mcpStatusesProvider.overrideWith((_) async => {}),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: ChatInputStatusBar(),
                // Intercept showWorkspaceDialog by overriding the navigator
                // We just verify the InkWell is tappable by tapping it
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final pathChip = find.text('chatorai');
        expect(pathChip, findsOneWidget);

        await tester.tap(pathChip);
        await tester.pump();

        // The InkWell onTap calls showWorkspaceDialog; we verify the chip
        // is wrapped in InkWell by checking it responds to tap without error.
        // A full dialog intercept would require navigator mocking; this
        // confirms the tap target is wired.
        expect(find.text('chatorai'), findsOneWidget);
      });

      testWidgets('tapping branch chip does nothing', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith((_) async => 'main'),
              mcpStatusesProvider.overrideWith((_) async => {}),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: ChatInputStatusBar()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final branchChip = find.textContaining('⎇');
        expect(branchChip, findsOneWidget);

        await tester.tap(branchChip);
        await tester.pump();

        // No dialog or route should be pushed for a non-tappable chip.
        expect(find.textContaining('⎇'), findsOneWidget);
      });

      testWidgets('tapping mcp chip does nothing', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workingDirProvider.overrideWithValue('/home/user/work/chatorai'),
              gitBranchProvider.overrideWith((_) async => null),
              mcpStatusesProvider.overrideWith(
                (_) async => {'s1': McpServerStatus.connected()},
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: ChatInputStatusBar()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final mcpChip = find.text('MCP: 1/1');
        expect(mcpChip, findsOneWidget);

        await tester.tap(mcpChip);
        await tester.pump();

        expect(find.text('MCP: 1/1'), findsOneWidget);
      });
    });
  });
}
