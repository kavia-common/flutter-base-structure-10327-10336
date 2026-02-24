import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_frontend/main.dart';

void main() {
  testWidgets('App starts on Login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
  });

  testWidgets('Shows validation error on empty submit',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    expect(find.text('Please enter username and password.'), findsOneWidget);
  });

  testWidgets('Navigates to Calculator on non-empty credentials',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(find.byType(TextField).at(0), 'user');
    await tester.enterText(find.byType(TextField).at(1), 'pass');

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    // AppBar title
    expect(find.text('Calculator'), findsOneWidget);

    // Initial display should show 0.
    expect(find.text('0'), findsWidgets);

    // Verify a couple of buttons exist.
    expect(find.text('C'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('÷'), findsOneWidget);
    expect(find.text('×'), findsOneWidget);
  });
}
