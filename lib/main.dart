import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/create_edit_url_screen.dart';
import 'screens/url_info_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/my_account_screen.dart';
import 'screens/forgot_pass_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NanoUrls',
      debugShowCheckedModeBanner: false,
      
      // Localizations Setup
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('pt'),
        Locale('es'),
        Locale('fr'),
      ],
      
      // Use the neon-dark theme mapped from the Tailwind WebApp
      theme: AppTheme.darkTheme,
      
      // Initial route starts with the pulsing logo Splash Screen
      initialRoute: '/',
      
      // Configure named routing table
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/create-edit': (context) => const CreateEditUrlScreen(),
        '/url-info': (context) => const UrlInfoScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/account': (context) => const MyAccountScreen(),
        '/forgot-password': (context) => const ForgotPassScreen(),
      },
      
      // Handle dynamic route arguments for detail view
      onGenerateRoute: (settings) {
        if (settings.name == '/details') {
          final shortCode = settings.arguments as String? ?? '';
          return MaterialPageRoute(
            builder: (context) => AnalyticsScreen(shortCode: shortCode),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
