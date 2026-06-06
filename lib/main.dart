import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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
import 'screens/onboarding_screen.dart';
import 'firebase_options.dart';

void main() async {
  // Garante que os bindings do Flutter estão inicializados antes de chamar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as opções da plataforma atual
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Instancia o serviço de Analytics e o Observer para rastrear a navegação de telas automaticamente
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NanoUrls',
      debugShowCheckedModeBanner: false,

      // Injeta o Observer no ciclo de vida de navegação do app
      navigatorObservers: <NavigatorObserver>[observer],

      // Configuração de localização
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

      // Usa o tema escuro mapeado do Tailwind WebApp
      theme: AppTheme.darkTheme,

      // Rota inicial começando na Splash Screen
      initialRoute: '/',

      // Tabela de rotas nomeadas. O Observer usará esses nomes (ex: '/home') no painel do Firebase
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/create-edit': (context) => const CreateEditUrlScreen(),
        '/url-info': (context) => const UrlInfoScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/account': (context) => const MyAccountScreen(),
        '/forgot-password': (context) => const ForgotPassScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },

      // Lida com passagem de argumentos dinâmicos para a tela de detalhes
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