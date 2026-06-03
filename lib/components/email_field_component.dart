import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class EmailFieldComponent extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const EmailFieldComponent({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.prefixIcon = Icons.email_outlined,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = label ?? context.l10n('email_label');
    final resolvedHint = hintText ?? context.l10n('email_hint');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resolvedLabel.isNotEmpty) ...[
          Text(
            resolvedLabel,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8.0),
        ],
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          enabled: enabled,
          onChanged: onChanged,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon),
            hintText: resolvedHint,
          ),
          validator: validator ?? (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n('email_validation_empty');
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value.trim())) {
              return context.l10n('email_validation_invalid');
            }
            return null;
          },
        ),
      ],
    );
  }
}
