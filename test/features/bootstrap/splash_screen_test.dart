import 'package:chatorai/features/bootstrap/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SplashScreen renders animated title and no logo image', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: SplashScreen()));

    // Название рендерится (локализация недоступна в тесте → fallback).
    expect(find.text('ChatORAI'), findsOneWidget);

    // Картинка-логотип и спиннер больше не используются.
    expect(find.byType(Image), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
