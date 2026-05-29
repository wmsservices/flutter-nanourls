import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../entities/nano_url.dart';
import '../theme/app_theme.dart';

class UrlInfoScreen extends StatelessWidget {
  const UrlInfoScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    final messenger = ScaffoldMessenger.of(context);
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$label copiado para a área de transferência!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = ModalRoute.of(context)!.settings.arguments as NanoUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalhes da URL'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Short URL Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInner,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'URL ENCURTADA',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      GestureDetector(
                        onTap: () => _copyToClipboard(context, url.goLink, 'Link encurtado'),
                        child: Text(
                          url.goLink,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),

                // Original Destination Link
                const Text(
                  'DESTINO ORIGINAL',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6.0),
                GestureDetector(
                  onTap: () => _copyToClipboard(context, url.realUrl, 'Destino original'),
                  child: Text(
                    url.realUrl,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.white70,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Description
                const Text(
                  'DESCRIÇÃO',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  url.description.isNotEmpty ? url.description : 'Sem descrição',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: url.description.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 24.0),

                // Password Protected Warning
                if (url.hasPassword) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.amber.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock, color: Colors.amber, size: 16.0),
                        SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            'URL protegida por senha',
                            style: TextStyle(
                              fontSize: 13.0,
                              color: Colors.amber,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ],

                const Divider(color: AppColors.border, height: 1.0),
                const SizedBox(height: 24.0),

                // Total Clicks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total de Cliques',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${url.clicks}',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),

            // Back Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'Voltar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
