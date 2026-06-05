import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanourls/screens/onboarding_screen.dart';
import 'package:nanourls/l10n/app_localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Enable testing mode to prevent infinite repeating loops in animations
    OnboardingScreen.isTesting = true;
  });

  Widget createTestWidget() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('pt'),
      ],
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const Scaffold(body: Text('Login Route')),
        '/home': (context) => const Scaffold(body: Text('Home Route')),
      },
      initialRoute: '/onboarding',
    );
  }

  testWidgets('Onboarding Screen renders first slide correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify first page titles and elements
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Shorten'), findsOneWidget);
    expect(find.text('Turn long URLs into sleek and tiny links'), findsOneWidget);

    // Verify presence of Next button icon
    expect(find.widgetWithIcon(ElevatedButton, Icons.arrow_forward_rounded), findsOneWidget);
  });

  testWidgets('Onboarding Screen navigates PageView when Next is clicked', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Click next page
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();

    // Verify second page content is displayed
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Search and sort your links instantly'), findsOneWidget);

    // Click next again to go to the third page
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();

    // Verify third page content using specific text size predicate to avoid matching mock labels
    final titleFinder = find.byWidgetPredicate((widget) =>
        widget is Text &&
        widget.data == 'Share' &&
        widget.style?.fontSize == 28.0);
    expect(titleFinder, findsOneWidget);
    expect(find.text('Generate QR codes and share anywhere'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Onboarding Screen completes onboarding and writes to SharedPreferences', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Click Skip button
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify it navigated to the login route (default target fallback)
    expect(find.text('Login Route'), findsOneWidget);

    // Verify SharedPreferences key has_seen_onboarding was written as true
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_onboarding'), isTrue);
  });
}
