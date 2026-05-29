import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../entities/nano_url.dart';
import '../theme/app_theme.dart';

class QrCodeDialog extends StatelessWidget {
  final NanoUrl url;

  const QrCodeDialog({super.key, required this.url});

  void _copyToClipboard(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    Clipboard.setData(ClipboardData(text: url.goLink)).then((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Link copiado: ${url.goLink}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String qrCodeUrl = url.qrCodePngUrl?.isNotEmpty == true
        ? url.qrCodePngUrl!
        : 'https://api.nanourls.com/v1/nano/qr/${url.shortUrl}';

    return Dialog(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            const Text(
              'Código QR',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20.0),

            // White QR Code Image Container
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  qrCodeUrl,
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      width: 180,
                      height: 180,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
                          SizedBox(height: 8.0),
                          Text(
                            'Erro ao carregar QR Code',
                            style: TextStyle(color: Colors.grey, fontSize: 12.0),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Link text below the image
            GestureDetector(
              onTap: () => _copyToClipboard(context),
              child: Text(
                url.shortUrl,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24.0),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: AppColors.border, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Fechar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
