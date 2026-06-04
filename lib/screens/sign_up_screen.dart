import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

// Sign-Up screen allowing new users to register an account
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _passwordScore = 0;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  String? _errorMessage;
  String? _successMessage;

  late TapGestureRecognizer _termsTapRecognizer;
  late TapGestureRecognizer _privacyTapRecognizer;
  late TapGestureRecognizer _agreeTermsTextRecognizer;
  late TapGestureRecognizer _agreePrivacyTextRecognizer;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
    _termsTapRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl('https://nanourls.com/Terms');
    _privacyTapRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl('https://nanourls.com/Privacy');
    _agreeTermsTextRecognizer = TapGestureRecognizer()
      ..onTap = () {
        setState(() {
          _agreeTerms = !_agreeTerms;
        });
      };
    _agreePrivacyTextRecognizer = TapGestureRecognizer()
      ..onTap = () {
        setState(() {
          _agreePrivacy = !_agreePrivacy;
        });
      };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _termsTapRecognizer.dispose();
    _privacyTapRecognizer.dispose();
    _agreeTermsTextRecognizer.dispose();
    _agreePrivacyTextRecognizer.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw 'Could not launch';
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n('error')}: $urlString'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _updatePasswordStrength() {
    final val = _passwordController.text;
    int score = 0;
    if (val.isNotEmpty) {
      if (val.length >= 8) score++;
      if (val.length >= 12) score++;
      if (RegExp(r'[A-Z]').hasMatch(val)) score++;
      if (RegExp(r'[a-z]').hasMatch(val)) score++;
      if (RegExp(r'[0-9]').hasMatch(val)) score++;
      if (RegExp(r'[@$!%*?&]').hasMatch(val)) score++;
    }
    setState(() {
      _passwordScore = score;
    });
  }

  Color _getStrengthColor() {
    if (_passwordScore == 0) return AppColors.textMuted;
    if (_passwordScore < 3) return Colors.redAccent;
    if (_passwordScore < 5) return Colors.yellow;
    return Colors.green;
  }

  String _getStrengthText() {
    if (_passwordController.text.isEmpty) return context.l10n('strength_weak');
    if (_passwordScore < 3) return context.l10n('strength_weak');
    if (_passwordScore < 5) return context.l10n('strength_medium');
    return context.l10n('strength_strong');
  }

  // Handle registration form submission
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final userEmail = _emailController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _apiService.signUp(
        _nameController.text.trim(),
        userEmail,
        _passwordController.text,
      );

      setState(() {
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _agreeTerms = false;
        _agreePrivacy = false;
        _passwordScore = 0;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: const BorderSide(color: AppColors.border),
              ),
              title: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n('signup_success_title'),
                    style: const TextStyle(
                      fontFamily: 'SplineSans',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
              content: Text(
                context.l10n('signup_success_message', args: [userEmail]),
                style: const TextStyle(
                  fontFamily: 'SplineSans',
                  color: AppColors.textMuted,
                  fontSize: 14.0,
                  height: 1.5,
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.of(context).pushReplacementNamed('/login'); // Return to login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
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
                // Header section styled like the login page
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
                          fontSize: 32.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.15,
                        ),
                        children: [
                          TextSpan(text: context.l10n('signup_header_title')),
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
                    const SizedBox(height: 8.0),
                    Text(
                      context.l10n('splash_tagline'),
                      style: const TextStyle(
                        fontFamily: 'SplineSans',
                        fontSize: 14.0,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36.0),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome Input
                      Text(
                        context.l10n('username_label'),
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          hintText: context.l10n('username_hint'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n('username_validation_empty');
                          }
                          if (value.trim().length > 36) {
                            return context.l10n('profile_validation_username_long');
                          }
                          if (!RegExp(r'^[a-zA-Z0-9\s_-]*$').hasMatch(value)) {
                            return context.l10n('username_validation_invalid');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // Email Input
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
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return context.l10n('email_validation_invalid');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // Senha Input
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
                          if (value.length < 8 || value.length > 36) {
                            return context.l10n('new_password_validation_weak');
                          }
                          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,36}$').hasMatch(value)) {
                            return context.l10n('new_password_validation_weak');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8.0),

                      // Password Strength Indicator Row
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: Container(
                          height: 6.0,
                          width: double.infinity,
                          color: Colors.white.withValues(alpha: 0.05),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _passwordScore / 6.0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: _getStrengthColor(),
                                boxShadow: _passwordScore >= 5
                                    ? [
                                        BoxShadow(
                                          color: Colors.green.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getStrengthText(),
                            style: TextStyle(
                              fontSize: 12.0,
                              color: _getStrengthColor(),
                              fontWeight: _passwordScore >= 5 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          Text(
                            context.l10n('security_rules'),
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        context.l10n('special_chars_legend'),
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Confirmar Senha Input
                      Text(
                        context.l10n('confirm_password_label'),
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          hintText: context.l10n('confirm_password_hint'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.l10n('confirm_password_validation_empty');
                          }
                          if (value != _passwordController.text) {
                            return context.l10n('confirm_password_validation_match');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),

                      // Error message banner
                      if (_errorMessage != null) ...[
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
                        const SizedBox(height: 20.0),
                      ],

                      // Success message banner
                      if (_successMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20.0),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: const TextStyle(color: Colors.green, fontSize: 13.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20.0),
                      ],

                      // Terms & Privacy Checkboxes
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _agreeTerms,
                              activeColor: AppColors.primary,
                              checkColor: AppColors.textLight,
                              onChanged: (val) {
                                setState(() {
                                  _agreeTerms = val ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: context.l10n('agree_terms_start'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.0,
                                  fontFamily: 'SplineSans',
                                ),
                                recognizer: _agreeTermsTextRecognizer,
                                children: [
                                  TextSpan(
                                    text: context.l10n('agree_terms_link'),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: _termsTapRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _agreePrivacy,
                              activeColor: AppColors.primary,
                              checkColor: AppColors.textLight,
                              onChanged: (val) {
                                setState(() {
                                  _agreePrivacy = val ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: context.l10n('agree_privacy_start'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.0,
                                  fontFamily: 'SplineSans',
                                ),
                                recognizer: _agreePrivacyTextRecognizer,
                                children: [
                                  TextSpan(
                                    text: context.l10n('agree_privacy_link'),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: _privacyTapRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),

                      // Sign up button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_isLoading || !_agreeTerms || !_agreePrivacy) ? null : _signUp,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.textLight,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(context.l10n('sign_up_btn')),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // Return to Login link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/login');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: context.l10n('already_have_account') + ' ',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'SplineSans',
                                fontSize: 14.0,
                              ),
                              children: [
                                TextSpan(
                                  text: context.l10n('login_here'),
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
