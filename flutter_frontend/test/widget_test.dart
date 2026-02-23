import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/main.dart';

void main() {
  testWidgets('renders hello world text', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hello World'), findsOneWidget);
  });

  testWidgets('app bar has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('flutter_frontend'), findsOneWidget);
  });
}
