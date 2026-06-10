import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../entities/plan.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../services/crypto_service.dart';
import '../theme/app_theme.dart';
import '../components/confirm_action.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();
  final CryptoService _cryptoService = CryptoService();

  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoadingPlan = true;
  Plan? _plan;
  String? _planError;

  bool _isProfileSaving = false;
  bool _isPasswordSaving = false;
  bool _isDeletingAccount = false;

  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  String? _profileSuccessMessage;
  String? _profileErrorMessage;

  String? _passwordSuccessMessage;
  String? _passwordErrorMessage;

  String _getDecryptedEmail(String? email) {
    if (email == null || email.isEmpty) return '';
    try {
      return _cryptoService.decryptEmail(email);
    } catch (_) {
      return email;
    }
  }

  @override
  void initState() {
    super.initState();
    final user = _sessionManager.currentUser;
    _nameController = TextEditingController(text: user?.userName ?? '');
    _emailController = TextEditingController(text: _getDecryptedEmail(user?.email));
    _loadUserPlan();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPlan() async {
    final user = _sessionManager.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingPlan = true;
      _planError = null;
    });

    try {
      final fetchedPlan = await _apiService.fetchPlanById(user.planId);
      setState(() {
        _plan = fetchedPlan;
        _isLoadingPlan = false;
      });
    } catch (e) {
      setState(() {
        _planError = context.l10n('plan_error');
        _isLoadingPlan = false;
      });
    }
  }

  // Visual dialog to confirm user action (update profile / change password / delete account)
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Row(
            children: [
              Icon(
                isDanger ? Icons.priority_high : Icons.help_outline,
                color: isDanger ? Colors.redAccent : AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                title,
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
            message,
            style: const TextStyle(
              fontFamily: 'SplineSans',
              color: AppColors.textMuted,
              fontSize: 14.0,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n('cancel'), style: const TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDanger ? Colors.redAccent : AppColors.primary,
                foregroundColor: isDanger ? Colors.white : AppColors.textLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // Update Profile flow
  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    final user = _sessionManager.currentUser;
    if (user == null) return;

    final nameInput = _nameController.text.trim();
    final emailInput = _emailController.text.trim();

    final decryptedEmail = _getDecryptedEmail(user.email);
    final isEmailChange = emailInput.toLowerCase() != decryptedEmail.toLowerCase();
    final isNameChange = nameInput != user.userName;

    if (!isEmailChange && !isNameChange) {
      setState(() {
        _profileSuccessMessage = context.l10n('profile_success_no_changes');
        _profileErrorMessage = null;
      });
      return;
    }

    final currentPassword = await showDialog<String>(
      context: context,
      builder: (context) => ConfirmActionDialog(
        title: context.l10n('save_profile_dialog_title'),
        message: isEmailChange
            ? context.l10n('save_profile_dialog_message_email')
            : context.l10n('save_profile_dialog_message_normal'),
        confirmText: context.l10n('confirm'),
        requirePassword: true, // Adicionado para exibir o campo de senha no modal
      ),
    );

    if (currentPassword == null) return;

    setState(() {
      _isProfileSaving = true;
      _profileSuccessMessage = null;
      _profileErrorMessage = null;
    });

    // Verify password against backend using signin API to avoid CPU-intensive local PBKDF2 hashing delays
    try {
      final decryptedEmail = _getDecryptedEmail(user.email);
      await _apiService.signIn(decryptedEmail, currentPassword);
    } catch (_) {
      setState(() {
        _profileErrorMessage = context.l10n('confirm_action_dialog_wrong_password');
        _isProfileSaving = false;
      });
      return;
    }

    try {
      await _apiService.updatePersonalData(
        userName: isNameChange ? nameInput : null,
        email: isEmailChange ? emailInput : null,
      );

      if (isEmailChange) {
        // Force logout
        _sessionManager.clearSession();
        // Clear saved credentials in SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n('email_changed_success_snackbar')),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      setState(() {
        _profileSuccessMessage = context.l10n('profile_success_updated');
        _isProfileSaving = false;
      });
    } catch (e) {
      setState(() {
        _profileErrorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
        _isProfileSaving = false;
      });
    }
  }

  // Change Password flow
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final user = _sessionManager.currentUser;
    if (user == null) return;

    if (_currentPasswordController.text == _newPasswordController.text) {
      setState(() {
        _passwordErrorMessage = context.l10n('password_validation_different');
      });
      return;
    }

    final confirm = await _showConfirmDialog(
      title: context.l10n('change_password_dialog_title'),
      message: context.l10n('change_password_dialog_message'),
      confirmText: context.l10n('change_password_dialog_btn'),
    );

    if (!confirm) return;

    setState(() {
      _isPasswordSaving = true;
      _passwordSuccessMessage = null;
      _passwordErrorMessage = null;
    });

    try {
      // Verify current password against backend using signin API to avoid CPU-intensive local PBKDF2 hashing delays
      final decryptedEmail = _getDecryptedEmail(user.email);
      await _apiService.signIn(decryptedEmail, _currentPasswordController.text);
    } catch (_) {
      setState(() {
        _passwordErrorMessage = context.l10n('confirm_action_dialog_wrong_password');
        _isPasswordSaving = false;
      });
      return;
    }

    try {
      await _apiService.changePassword(_newPasswordController.text);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _isPasswordSaving = false;
      });

      // Force logout after password change
      _sessionManager.clearSession();
      // Clear saved password in SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_password');
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n('password_changed_success_snackbar')),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      setState(() {
        _passwordErrorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
        _isPasswordSaving = false;
      });
    }
  }

  // Delete Account permanently flow
  Future<void> _deleteAccount() async {
    final user = _sessionManager.currentUser;
    if (user == null) return;

    final decryptedEmail = _getDecryptedEmail(user.email);

    final confirmed = await showDialog<dynamic>(
      context: context,
      builder: (context) => ConfirmActionDialog(
        title: context.l10n('delete_account_dialog_title'),
        message: context.l10n('delete_account_dialog_message'),
        confirmText: context.l10n('delete_account_dialog_btn'),
        isDanger: true,
        requireEmail: true, // Solicita a digitação do e-mail cadastrado
        expectedEmail: decryptedEmail, // Valida se coincide com o cadastrado
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await _apiService.deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n('delete_account_success_snackbar')),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n('error')}: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() {
        _isDeletingAccount = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _sessionManager.currentUser;
    final initial = user?.userName.isNotEmpty == true
        ? user!.userName.substring(0, 1).toUpperCase()
        : 'U';
    final memberSinceStr = user != null
        ? '${_getMonthName(user.createdAt.month)} ${user.createdAt.year}'
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n('account_settings_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Header Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 32,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface, width: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      user?.userName ?? context.l10n('user'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      _getDecryptedEmail(user?.email),
                      style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16.0),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.l10n('member_since'), style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
                        Text(
                          memberSinceStr,
                          style: const TextStyle(fontSize: 14, color: Colors.white, fontFamily: 'SplineSans', fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // 2. User Plan Details Card
              _buildPlanCard(),
              const SizedBox(height: 24.0),

              // 3. Personal Data Form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.badge, color: AppColors.textMuted),
                          const SizedBox(width: 8.0),
                          Text(context.l10n('personal_data_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 20.0),

                      if (_profileSuccessMessage != null) ...[
                        Text(_profileSuccessMessage!, style: const TextStyle(color: AppColors.primary, fontSize: 13.0)),
                        const SizedBox(height: 12.0),
                      ],
                      if (_profileErrorMessage != null) ...[
                        Text(_profileErrorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13.0)),
                        const SizedBox(height: 12.0),
                      ],

                      Text(context.l10n('username_label'), style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          hintText: context.l10n('username_hint'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return context.l10n('profile_validation_username_empty');
                          if (value.trim().length > 50) return context.l10n('profile_validation_username_long');
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      Text(context.l10n('email_label'), style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white)),
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
                          if (value == null || value.trim().isEmpty) return context.l10n('email_validation_empty');
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return context.l10n('email_validation_invalid');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isProfileSaving ? null : _updateProfile,
                          child: _isProfileSaving
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.textLight,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save, size: 18),
                              const SizedBox(width: 8),
                              Text(context.l10n('save_changes')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // 4. Security Password Form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock, color: AppColors.textMuted),
                          const SizedBox(width: 8.0),
                          Text(context.l10n('security_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 20.0),

                      if (_passwordSuccessMessage != null) ...[
                        Text(_passwordSuccessMessage!, style: const TextStyle(color: AppColors.primary, fontSize: 13.0)),
                        const SizedBox(height: 12.0),
                      ],
                      if (_passwordErrorMessage != null) ...[
                        Text(_passwordErrorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13.0)),
                        const SizedBox(height: 12.0),
                      ],

                      Text(context.l10n('current_password_label'), style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPass,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: context.l10n('current_password_hint'),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrentPass ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureCurrentPass = !_obscureCurrentPass),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return context.l10n('current_password_validation_empty');
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      Text(context.l10n('new_password_label'), style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPass,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: context.l10n('new_password_hint'),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNewPass ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return context.l10n('new_password_validation_empty');
                          if (value.length < 8) return context.l10n('new_password_validation_weak');
                          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(value)) {
                            return context.l10n('new_password_validation_weak');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        context.l10n('new_password_validation_weak'),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                      ),
                      const SizedBox(height: 20.0),

                      Text(context.l10n('confirm_password_label'), style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPass,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_reset),
                          hintText: context.l10n('confirm_password_hint'),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return context.l10n('confirm_new_password_validation_empty');
                          if (value != _newPasswordController.text) {
                            return context.l10n('confirm_new_password_validation_match');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isPasswordSaving ? null : _changePassword,
                          child: _isPasswordSaving
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.textLight,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.key, size: 18),
                              const SizedBox(width: 8),
                              Text(context.l10n('change_password_btn')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // 5. Danger Zone (Delete Account)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.redAccent),
                        const SizedBox(width: 8.0),
                        Text(context.l10n('danger_zone_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      context.l10n('danger_zone_desc'),
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 20.0),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isDeletingAccount ? null : _deleteAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.redAccent.withValues(alpha: 0.3),
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                          shadowColor: Colors.redAccent.withValues(alpha: 0.4),
                          elevation: 8,
                          textStyle: const TextStyle(
                            fontFamily: 'SplineSans',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        child: _isDeletingAccount
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_forever, size: 18),
                            const SizedBox(width: 8),
                            Text(context.l10n('delete_account_btn')),
                          ],
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
    );
  }

  // Plan Details Card builder
  Widget _buildPlanCard() {
    if (_isLoadingPlan) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_planError != null || _plan == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _planError ?? context.l10n('plan_error'),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
    }

    final plan = _plan!;
    final linksStr = plan.maxLinks == -1 ? context.l10n('unlimited_links') : context.l10n('max_links_limit', args: [plan.maxLinks]);
    final analyticsStr = plan.maxAnalytics == -1 ? context.l10n('unlimited_analytics') : context.l10n('max_analytics_limit', args: [plan.maxAnalytics]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n('plan_current'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2),
              ),
              Icon(Icons.rocket_launch, color: AppColors.primary.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            plan.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16.0),
          _buildPlanFeatureRow(linksStr),
          _buildPlanFeatureRow(analyticsStr),
          if (plan.hasDetailedAnalytics) _buildPlanFeatureRow(context.l10n('features_geo')),
          if (plan.hasCustomDomain) _buildPlanFeatureRow(context.l10n('features_domain')),
          if (plan.hasCustomQrCode) _buildPlanFeatureRow(context.l10n('features_qr')),
          if (plan.hasApiAccess) _buildPlanFeatureRow(context.l10n('features_api')),
        ],
      ),
    );
  }

  Widget _buildPlanFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    final locale = Localizations.localeOf(context).languageCode;
    const months = {
      'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      'pt': ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
      'es': ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'],
      'fr': ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'],
    };
    final list = months[locale] ?? months['en']!;
    if (month >= 1 && month <= 12) {
      return list[month - 1];
    }
    return '';
  }
}