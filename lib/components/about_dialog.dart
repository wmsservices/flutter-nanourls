import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class AboutNanoUrlsDialog extends StatelessWidget {
  const AboutNanoUrlsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo with outer circle and neon glow
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.backgroundDarker,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 16.0,
                  spreadRadius: 2.0,
                ),
              ],
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
            ),
            padding: const EdgeInsets.all(14),
            child: SvgPicture.asset('assets/svg/logo.svg'),
          ),
          const SizedBox(height: 18.0),
          
          // App Title with styling
          Text.rich(
            TextSpan(
              text: 'Sobre ',
              style: const TextStyle(
                fontFamily: 'SplineSans',
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              children: [
                TextSpan(
                  text: 'NanoUrls',
                  style: TextStyle(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4.0),
          
          // Version Number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: const Text(
              'Versão 1.0.0',
              style: TextStyle(
                fontFamily: 'SplineSans',
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20.0),
          
          // Description
          const Text(
            'O NanoUrls é um encurtador de links completo, rápido e seguro. Ele foi projetado para encurtar suas URLs, gerar códigos QR dinâmicos e fornecer estatísticas detalhadas de cliques em tempo real.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SplineSans',
              color: AppColors.textMuted,
              fontSize: 14.0,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16.0),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16.0),

          // Details List
          _buildDetailRow(Icons.offline_bolt_outlined, 'Performance otimizada'),
          _buildDetailRow(Icons.security_outlined, 'Segurança de credenciais'),
          _buildDetailRow(Icons.qr_code_2_outlined, 'QR Code integrado'),
          _buildDetailRow(Icons.analytics_outlined, 'Relatórios de cliques e geolocalização'),

          const SizedBox(height: 24.0),
          
          // Close button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: const Text('Fechar'),
            ),
          ),
          const SizedBox(height: 12.0),
          
          // Footer
          const Text(
            '© 2026 NanoUrls. Todos os direitos reservados.',
            style: TextStyle(
              fontFamily: 'SplineSans',
              color: Colors.white38,
              fontSize: 11.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'SplineSans',
                color: Colors.white70,
                fontSize: 13.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
