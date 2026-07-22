import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/diff_body.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

void main() {
  Widget createTestWidget({
    String? oldSource,
    String? newSource,
    bool displayFull = true,
    bool isError = false,
    String? filePath,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: DiffBody(
            theme: AppTheme.lightTheme,
            oldSource: oldSource,
            newSource: newSource,
            filePath: filePath ?? 'test.dart',
            displayFull: displayFull,
            isError: isError,
            onDiagnosticTap: (_) {},
          ),
        ),
      ),
    );
  }

  group('DiffBody Widget', () {
    testWidgets('expanded shows diff rows', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          oldSource: 'a\nb',
          newSource: 'a\nc',
          displayFull: true,
        ),
      );
      expect(find.text('a'), findsWidgets);
      expect(find.text('b'), findsOneWidget);
      expect(find.text('c'), findsOneWidget);
    });

    testWidgets('error state shows only red file path', (tester) async {
      await tester.pumpWidget(
        createTestWidget(isError: true, filePath: 'src/main.dart'),
      );
      expect(find.text('src/main.dart'), findsOneWidget);
    });

    testWidgets('no hunk header shown', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          oldSource: 'a\nb',
          newSource: 'a\nc',
          displayFull: true,
        ),
      );
      expect(find.textContaining('@@'), findsNothing);
    });

    testWidgets('wide layout shows two gutter columns', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: DiffBody(
                theme: AppTheme.lightTheme,
                oldSource: 'a',
                newSource: 'b',
                filePath: 'test.dart',
                displayFull: true,
                isError: false,
                onDiagnosticTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('collapsed shows nothing', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          oldSource: 'a\nb',
          newSource: 'a\nc',
          displayFull: false,
        ),
      );
      expect(find.text('b'), findsNothing);
      expect(find.text('c'), findsNothing);
    });
  });
}
