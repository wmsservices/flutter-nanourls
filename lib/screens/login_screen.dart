import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

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
  bool _rememberMe = false;
  String? _errorMessage;
  bool _argsLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _emailController.text = args['email'] ?? '';
          _errorMessage = args['error'];
          _passwordController.clear();
          _rememberMe = true;
        });
      } else {
        _loadSavedCredentials();
      }
      _argsLoaded = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('remember_me') ?? false;
      if (remember) {
        final encryptedEmail = prefs.getString('saved_email');
        final encryptedPassword = prefs.getString('saved_password');
        if (encryptedEmail != null && encryptedPassword != null) {
          final crypto = CryptoService();
          final email = crypto.decryptEmail(encryptedEmail);
          final password = crypto.decryptPassword(encryptedPassword);
          setState(() {
            _rememberMe = true;
            _emailController.text = email;
            _passwordController.text = password;
          });
        }
      }
    } catch (_) {
      // Decryption or retrieval failure
    }
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

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        final crypto = CryptoService();
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_email', crypto.encryptEmail(_emailController.text.trim()));
        await prefs.setString('saved_password', crypto.encryptPassword(_passwordController.text));
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }
      
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
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'SplineSans',
                          fontSize: 36.0,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(text: context.l10n('login_header_title')),
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
                    Text(
                      context.l10n('login_header_desc'),
                      style: const TextStyle(
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
                      Text(
                        context.l10n('email_label'),
                        style: const TextStyle(
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
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          hintText: context.l10n('email_hint'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n('email_validation_empty');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      
                      Text(
                        context.l10n('password_label'),
                        style: const TextStyle(
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
                          hintText: context.l10n('password_hint'),
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
                            return context.l10n('password_validation_empty');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),
                      
                      // Remember me and Forgot password row
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppColors.primary,
                                  checkColor: AppColors.textLight,
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberMe = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: Text(
                                  context.l10n('remember_credentials'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14.0,
                                    fontFamily: 'SplineSans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                            child: Text(context.l10n('forgot_password')),
                          ),
                        ],
                      ),
                      
                      // API Error container banner
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8.0),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
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
                              : Text(context.l10n('sign_in_btn')),
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
                            text: TextSpan(
                              text: '${context.l10n('dont_have_account')} ',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'SplineSans',
                                fontSize: 14.0,
                              ),
                              children: [
                                TextSpan(
                                  text: context.l10n('register_now'),
                                  style: const TextStyle(
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
