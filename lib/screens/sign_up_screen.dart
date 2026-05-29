import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
    if (_passwordController.text.isEmpty) return 'Senha fraca';
    if (_passwordScore < 3) return 'Senha fraca';
    if (_passwordScore < 5) return 'Senha Média';
    return 'Senha Forte';
  }

  // Handle registration form submission
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _apiService.signUp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _successMessage = 'Conta criada com sucesso! Verifique seu e-mail para confirmação.';
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _agreeTerms = false;
        _agreePrivacy = false;
        _passwordScore = 0;
      });

      // Automatically navigate back to Login after a short delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
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
                    const Text(
                      'Criar Conta',
                      style: TextStyle(
                        fontFamily: 'SplineSans',
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Registre-se para encurtar e gerenciar seus links com estilo.',
                      style: TextStyle(
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
                      const Text(
                        'Nome de Usuário',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: 'Digite seu nome',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O nome/apelido é obrigatório.';
                          }
                          if (value.trim().length > 36) {
                            return 'O nome deve ter no máximo 36 caracteres.';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9\s_-]*$').hasMatch(value)) {
                            return 'O nome deve conter apenas letras (sem acentos), números, espaços, hífen (-) e underscore (_).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // Email Input
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
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Por favor, insira um e-mail válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // Senha Input
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
                          hintText: 'Crie uma senha forte',
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
                            return 'A senha é obrigatória.';
                          }
                          if (value.length < 8 || value.length > 36) {
                            return 'A senha deve ter entre 8 e 36 caracteres.';
                          }
                          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,36}$').hasMatch(value)) {
                            return 'A senha deve conter: Maiúscula, Minúscula, Número e Especial (@\$!%*?&).';
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
                          color: Colors.white.withOpacity(0.05),
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
                                          color: Colors.green.withOpacity(0.5),
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
                          const Text(
                            'Regras de segurança',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'Caracteres Especiais Permitidos: @ \$ ! % * ? &',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Confirmar Senha Input
                      const Text(
                        'Confirmar Senha',
                        style: TextStyle(
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
                          hintText: 'Repita a senha',
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
                            return 'A confirmação de senha é obrigatória.';
                          }
                          if (value != _passwordController.text) {
                            return 'As senhas informadas não conferem.';
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
                        const SizedBox(height: 20.0),
                      ],

                      // Success message banner
                      if (_successMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.green.withOpacity(0.2)),
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
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreeTerms = !_agreeTerms;
                                });
                              },
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Li e concordo com os ',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14.0,
                                    fontFamily: 'SplineSans',
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Termos de Uso',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
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
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreePrivacy = !_agreePrivacy;
                                });
                              },
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Li e concordo com a ',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14.0,
                                    fontFamily: 'SplineSans',
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Política de Privacidade',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
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
                              : const Text('Criar Conta'),
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
                            text: const TextSpan(
                              text: 'Já tem uma conta? ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontFamily: 'SplineSans',
                                fontSize: 14.0,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Entrar.',
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
