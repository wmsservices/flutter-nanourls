import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import '../services/keycloak_auth_service.dart';
import '../services/admob_controller.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Splash Screen displaying the SVG logo with premium pulsing animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Repeat the pulse back and forth
    _controller.repeat(reverse: true);

    // Process initialization and auto-login check after frame rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppAndCheckAutoLogin();
    });
  }

  Future<void> _initializeAppAndCheckAutoLogin() async {
    final startTime = DateTime.now();
    bool loginSuccess = false;
    bool hasSeenOnboarding = false;
    String? emailToPrefill;
    String? loginError;

    // 1. Aguarda um delay para garantir que a interface do iOS esteja totalmente visível e ativa (UIApplicationStateActive)
    await Future.delayed(const Duration(milliseconds: 1000));

    // 2. Inicializa o Mobile Ads SDK e solicita permissão de rastreamento (ATT) via AdmobController
    try {
      await AdmobController.instance.init();
    } catch (_) {
      // Ignora se falhar
    }

    // 3. Aguarda um pequeno delay (800ms) para permitir a transição suave do diálogo de ATT antes do próximo prompt
    await Future.delayed(const Duration(milliseconds: 800));

    // 4. Solicita permissão para notificações push (FCM) após o encerramento do diálogo de ATT
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (_) {
      // Ignora se a plataforma não suportar ou se a requisição falhar
    }

    // 4.5. Tenta restaurar a sessão SSO (Keycloak) com o refresh token do armazenamento seguro
    try {
      loginSuccess = await KeycloakAuthService().restoreSession();
    } catch (_) {
      // Sem sessão SSO válida: segue para o auto-login legado
    }

    // 5. Processa a verificação de auto-login e leitura do SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      final remember = prefs.getBool('remember_me') ?? false;
      if (!loginSuccess && remember) {
        final encryptedEmail = prefs.getString('saved_email');
        final encryptedPassword = prefs.getString('saved_password');
        if (encryptedEmail != null && encryptedPassword != null) {
          final crypto = CryptoService();
          final email = crypto.decryptEmail(encryptedEmail);
          final password = crypto.decryptPassword(encryptedPassword);
          emailToPrefill = email;

          // Tentativa de login na API
          final apiService = ApiService();
          await apiService.signIn(email, password);
          loginSuccess = true;
        }
      }
    } catch (e) {
      loginError = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
      // Limpa a senha salva em caso de falha para evitar novas tentativas incorretas
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_password');
      } catch (_) {}
    }

    // 6. Garante que a Splash Screen seja exibida por pelo menos 2500ms no total para preservar a fluidez visual
    final elapsed = DateTime.now().difference(startTime);
    final remainingDelay = const Duration(milliseconds: 2500) - elapsed;
    if (remainingDelay > Duration.zero) {
      await Future.delayed(remainingDelay);
    }

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      Navigator.of(context).pushReplacementNamed(
        '/onboarding',
        arguments: {
          'targetRoute': loginSuccess ? '/home' : '/login',
          'targetArguments': loginSuccess
              ? null
              : (emailToPrefill != null
                  ? {
                      'email': emailToPrefill,
                      'error': loginError ?? context.l10n('auto_login_failed'),
                    }
                  : null),
        },
      );
    } else {
      if (loginSuccess) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed(
          '/login',
          arguments: emailToPrefill != null
              ? {
                  'email': emailToPrefill,
                  'error': loginError ?? context.l10n('auto_login_failed'),
                }
              : null,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient glows (top-left & bottom-right)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
              child: const SizedBox(),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.03),
              ),
              child: const SizedBox(),
            ),
          ),
          
          // Centered pulsing logo and label
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with dynamic shadows
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInner,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: SvgPicture.asset(
                      'assets/svg/logo.svg',
                      placeholderBuilder: (BuildContext context) => const CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Brand Name Text
                  const Text(
                    'NanoUrls',
                    style: TextStyle(
                      fontFamily: 'SplineSans',
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.0,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: AppColors.shadowGlow,
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  
                  // Subtitle description matching site headers
                  Text(
                    context.l10n('splash_tagline'),
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
