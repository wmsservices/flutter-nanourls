import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class ConfirmActionDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? confirmText;
  final bool isDanger;
  final bool requirePassword; // Adicionado para permitir reuso sem pedir senha
  final bool requireEmail;    // Adicionado para exigir a digitação do e-mail
  final String? expectedEmail; // E-mail esperado para validação

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.isDanger = false,
    this.requirePassword = false, // Falso por padrão
    this.requireEmail = false,    // Falso por padrão
    this.expectedEmail,
  });

  @override
  State<ConfirmActionDialog> createState() => _ConfirmActionDialogState();
}

class _ConfirmActionDialogState extends State<ConfirmActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedConfirmText = widget.confirmText ?? context.l10n('confirm');

    return AlertDialog(
      // Sem isso, o conteúdo não rola quando o teclado reduz o espaço vertical
      // disponível (ou a fonte do sistema está maior) — ele só estoura por baixo
      // do dialog em vez de virar scroll, como visto no campo de e-mail no S25 Ultra
      scrollable: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Row(
        children: [
          Icon(
            widget.isDanger ? Icons.warning_amber_rounded : Icons.info_outline,
            color: widget.isDanger ? Colors.redAccent : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: const TextStyle(color: Colors.white70, fontSize: 14.0),
            ),
            // Exibe o campo de senha SOMENTE se a ação exigir
            if (widget.requirePassword) ...[
              const SizedBox(height: 20.0),
              Text(
                context.l10n('confirm_action_dialog_message'),
                style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: context.l10n('confirm_action_dialog_password_prompt'),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n('confirm_action_dialog_password_empty');
                  }
                  return null;
                },
              ),
            ],
            // Exibe o campo de confirmação de e-mail se a ação exigir
            if (widget.requireEmail) ...[
              const SizedBox(height: 20.0),
              Text(
                context.l10n('confirm_action_dialog_email_prompt'),
                style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              if (widget.expectedEmail != null) ...[
                const SizedBox(height: 6.0),
                Text(
                  widget.expectedEmail!,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n('confirm_action_dialog_email_empty');
                  }
                  if (widget.expectedEmail != null &&
                      value.trim().toLowerCase() != widget.expectedEmail!.toLowerCase()) {
                    return context.l10n('confirm_action_dialog_email_mismatch');
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(context.l10n('cancel'), style: const TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.requirePassword) {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, _passwordController.text);
              }
            } else if (widget.requireEmail) {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            } else {
              // Se não pede senha nem e-mail, apenas retorna um bool confirmando a ação
              Navigator.pop(context, true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDanger ? Colors.redAccent : AppColors.primary,
            foregroundColor: widget.isDanger ? Colors.white : AppColors.textLight,
            disabledBackgroundColor: (widget.isDanger ? Colors.redAccent : AppColors.primary).withValues(alpha: 0.3),
            disabledForegroundColor: (widget.isDanger ? Colors.white : AppColors.textLight).withValues(alpha: 0.5),
            shadowColor: (widget.isDanger ? Colors.redAccent : AppColors.primary).withValues(alpha: 0.4),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          child: Text(resolvedConfirmText),
        ),
      ],
    );
  }
}