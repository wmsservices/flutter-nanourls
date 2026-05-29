// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:nanourls/main.dart';

void main() {
  testWidgets('App splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our brand name "NanoUrls" is shown.
    expect(find.text('NanoUrls'), findsOneWidget);
    expect(find.text('Encurte seus links com estilo'), findsOneWidget);

    // Pump to complete the Splash Screen navigation timer
    await tester.pump(const Duration(milliseconds: 2600));
  });
}
