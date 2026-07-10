import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

// Tela de confirmação exibida após a exclusão de conta bem-sucedida, espelhando
// AccountDeleted.cshtml do WebApp: mensagem de sucesso + aviso sobre revogar o
// Sign In with Apple, já que a exclusão local/Keycloak não afeta o consentimento
// dado do lado da Apple.
class AccountDeletedScreen extends StatelessWidget {
  const AccountDeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Não deixa voltar pra tela anterior (a conta já não existe mais)
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceInner,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(14.0),
                    child: SvgPicture.asset('assets/svg/logo.svg'),
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    context.l10n('account_deleted_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    context.l10n('account_deleted_message'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15.0, color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 24.0),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Icon(Icons.apple, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n('account_deleted_apple_title'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14.0,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                context.l10n('account_deleted_apple_desc'),
                                style: const TextStyle(fontSize: 13.0, color: Colors.white70, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      ),
                      child: Text(
                        context.l10n('account_deleted_btn'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
