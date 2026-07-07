import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/email_field_component.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ForgotPassScreen extends StatefulWidget {
  const ForgotPassScreen({super.key});

  @override
  State<ForgotPassScreen> createState() => _ForgotPassScreenState();
}

class _ForgotPassScreenState extends State<ForgotPassScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _confirmEmailController.dispose();
    super.dispose();
  }

  Future<void> _submitForgotPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();

    try {
      await _apiService.requestPasswordReset(email);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      // Clear controllers
      _emailController.clear();
      _confirmEmailController.clear();

      // Show custom premium success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final successMsg = context.l10n('forgot_pass_success_message', args: ['{EMAIL}']);
          final msgParts = successMsg.split('{EMAIL}');
          final msgBefore = msgParts.isNotEmpty ? msgParts[0] : '';
          final msgAfter = msgParts.length > 1 ? msgParts[1] : '';

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
                  context.l10n('forgot_pass_success_title'),
                  style: const TextStyle(
                    fontFamily: 'SplineSans',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
            content: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'SplineSans',
                  color: AppColors.textMuted,
                  fontSize: 14.0,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: msgBefore),
                  TextSpan(
                    text: email,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: msgAfter),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.of(context).pushReplacementNamed('/login'); // Return to login screen
                  },
                  child: const Text('OK'),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Container
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
                // Title
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
                      TextSpan(text: context.l10n('forgot_pass_title')),
                      const TextSpan(
                        text: 'NanoUrls',
                        style: TextStyle(
                          color: AppColors.primary,
                          shadows: [
                            Shadow(
                              color: AppColors.shadowGlow,
                              blurRadius: 15.0,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  context.l10n('forgot_pass_desc'),
                  style: const TextStyle(
                    color: AppColors.textMutedGreenish,
                    fontSize: 16.0,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32.0),

                // E-mail Field
                EmailFieldComponent(
                  controller: _emailController,
                  label: context.l10n('email_label'),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20.0),

                // Confirm E-mail Field
                EmailFieldComponent(
                  controller: _confirmEmailController,
                  label: context.l10n('email_confirm_label'),
                  prefixIcon: Icons.mark_email_read_outlined,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n('email_confirm_validation_empty');
                    }
                    if (value.trim() != _emailController.text.trim()) {
                      return context.l10n('email_confirm_validation_match');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // API Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ],

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52.0,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForgotPassword,
                    style: ElevatedButton.styleFrom(
                      elevation: _isLoading ? 0 : 8,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send, size: 18),
                              const SizedBox(width: 8),
                              Text(context.l10n('send_btn')),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32.0),

                // Transition link
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'SplineSans',
                          fontSize: 14.0,
                          color: AppColors.textMuted,
                        ),
                        children: [
                          TextSpan(text: context.l10n('remembered_password_question')),
                          TextSpan(
                            text: context.l10n('login_action_dot'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
