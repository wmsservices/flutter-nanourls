import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'helpers/app_tracking_transparency_helper.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/my_analytics_screen.dart';
import 'screens/create_edit_url_screen.dart';
import 'screens/url_info_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/my_account_screen.dart';
import 'screens/account_deleted_screen.dart';
import 'screens/plans_screen.dart';
import 'screens/forgot_pass_screen.dart';
import 'screens/onboarding_screen.dart';
import 'dtos/dashboard_data_dto.dart';
import 'firebase_options.dart';

/// Inicializa o SDK do RevenueCat configurando a plataforma correta.
Future<void> initRevenueCat() async {
  // Habilita logs detalhados para facilitar o debug em ambiente de desenvolvimento
  await Purchases.setLogLevel(LogLevel.debug);

  PurchasesConfiguration? configuration;

  // Define a chave de API pública com base no sistema operacional do dispositivo
  if (Platform.isAndroid) {
    configuration = PurchasesConfiguration("goog_lMYvMOaDNQGHOcMOqkDzmMyJdss");
  } else if (Platform.isIOS) {
    configuration = PurchasesConfiguration("appl_oVJylrbeIqMOQJufOPwhOPuvIKS");
  }

  // Se a configuração for válida para a plataforma, aplica ao SDK
  if (configuration != null) {
    await Purchases.configure(configuration);
  }
}

void main() async {
  // Garante que os bindings do Flutter estão inicializados antes de chamar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // Solicita permissão de rastreamento (ATT) no iOS antes de qualquer renderização
  await AppTrackingTransparencyHelper.requestAppTrackingTransparency();

  // Inicializa o Firebase com as opções da plataforma atual
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa o RevenueCat para gerenciamento de assinaturas e compras in-app
  await initRevenueCat();

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
        '/my-analytics': (context) => const MyAnalyticsScreen(),
        '/url-info': (context) => const UrlInfoScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/account': (context) => const MyAccountScreen(),
        '/account-deleted': (context) => const AccountDeletedScreen(),
        '/plans': (context) => const PlansScreen(),
        '/forgot-password': (context) => const ForgotPassScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/details') {
          String shortCode = '';
          DashboardDataDto? preloadedData;
          if (settings.arguments is String) {
            shortCode = settings.arguments as String;
          } else if (settings.arguments is Map<String, dynamic>) {
            final args = settings.arguments as Map<String, dynamic>;
            shortCode = args['shortCode'] as String? ?? '';
            preloadedData = args['preloadedData'] as DashboardDataDto?;
          }
          return MaterialPageRoute(
            builder: (context) => AnalyticsScreen(
              shortCode: shortCode,
              preloadedData: preloadedData,
            ),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}