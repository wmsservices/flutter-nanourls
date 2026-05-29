import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/link_details_screen.dart';
import 'screens/create_edit_url_screen.dart';
import 'screens/url_info_screen.dart';
import 'screens/sign_up_screen.dart';

void main() {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NanoUrls',
      debugShowCheckedModeBanner: false,
      
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
      },
      
      // Handle dynamic route arguments for detail view
      onGenerateRoute: (settings) {
        if (settings.name == '/details') {
          final shortCode = settings.arguments as String? ?? '';
          return MaterialPageRoute(
            builder: (context) => LinkDetailsScreen(shortCode: shortCode),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
