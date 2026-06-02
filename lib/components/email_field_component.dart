import 'package:flutter/material.dart';

class EmailFieldComponent extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const EmailFieldComponent({
    super.key,
    required this.controller,
    this.label = 'Endereço de E-mail',
    this.hintText = 'exemplo@email.com',
    this.prefixIcon = Icons.email_outlined,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
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
            hintText: hintText,
          ),
          validator: validator ?? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, insira seu e-mail.';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value.trim())) {
              return 'Por favor, insira um e-mail válido.';
            }
            return null;
          },
        ),
      ],
    );
  }
}
