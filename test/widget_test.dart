// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:nanourls/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Firebase.initializeApp();
  });

  testWidgets('App splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Wait for localizations delegate to load
    await tester.pump();

    // Verify that our brand name "NanoUrls" is shown.
    expect(find.text('NanoUrls'), findsOneWidget);
    expect(find.text('Shorten your links with style'), findsOneWidget);

    // Pump to complete the Splash Screen navigation timer
    await tester.pump(const Duration(milliseconds: 2600));
  });
}
