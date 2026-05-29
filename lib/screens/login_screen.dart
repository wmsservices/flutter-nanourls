import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// Login screen to authenticate users with backend API signin integrations
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle API login submission
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Clean the exception header if present
          _errorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10.0),
                // Branding Header matching the site's homepage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceInner,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: SvgPicture.asset('assets/svg/logo.svg'),
                    ),
                    const SizedBox(height: 24.0),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'SplineSans',
                          fontSize: 36.0,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(text: 'Encurte suas\nURLs com\n'),
                          TextSpan(
                            text: 'NanoUrls',
                            style: TextStyle(
                              color: AppColors.primary,
                              shadows: [
                                Shadow(
                                  color: AppColors.shadowGlow,
                                  blurRadius: 15.0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'A maneira mais simples, rápida e segura de gerenciar seus links. '
                      'Transforme URLs longas em links curtos e poderosos.',
                      style: TextStyle(
                        fontFamily: 'SplineSans',
                        fontSize: 14.0,
                        height: 1.5,
                        fontWeight: FontWeight.normal,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32.0),
                
                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Endereço de E-mail',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'exemplo@email.com',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, insira seu e-mail.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      
                      const Text(
                        'Senha de Acesso',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: 'Digite sua senha',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira sua senha.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),
                      
                      // Forgot password link matching secondary links
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fluxo de recuperação disponível na WebApp.'),
                                backgroundColor: AppColors.surface,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text('Esqueceu a senha?'),
                        ),
                      ),
                      
                      // API Error container banner
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8.0),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.redAccent, size: 20.0),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ] else ...[
                        const SizedBox(height: 24.0),
                      ],

                      // Log in button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.textLight,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Entrar'),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // Register / SignUp transition link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/signup');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Não tem conta? ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontFamily: 'SplineSans',
                                fontSize: 14.0,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Cadastre-se.',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
