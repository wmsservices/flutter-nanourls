import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfirmActionDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final bool isDanger;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.isDanger = false,
  });

  @override
  State<ConfirmActionDialog> createState() => _ConfirmActionDialogState();
}

class _ConfirmActionDialogState extends State<ConfirmActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            const SizedBox(height: 20.0),
            const Text(
              'Confirme sua senha para prosseguir:',
              style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Senha de acesso',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'A senha é obrigatória para confirmar.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _passwordController.text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDanger ? Colors.redAccent : AppColors.primary,
            foregroundColor: widget.isDanger ? Colors.white : AppColors.textLight,
            disabledBackgroundColor: (widget.isDanger ? Colors.redAccent : AppColors.primary).withOpacity(0.3),
            disabledForegroundColor: (widget.isDanger ? Colors.white : AppColors.textLight).withOpacity(0.5),
            shadowColor: (widget.isDanger ? Colors.redAccent : AppColors.primary).withOpacity(0.4),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
