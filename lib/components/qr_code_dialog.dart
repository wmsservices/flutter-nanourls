import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../entities/nano_url.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class QrCodeDialog extends StatefulWidget {
  final NanoUrl url;

  const QrCodeDialog({super.key, required this.url});

  @override
  State<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<QrCodeDialog> {
  bool _isSharing = false;

  void _copyToClipboard(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    Clipboard.setData(ClipboardData(text: widget.url.goLink)).then((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n('link_copied', args: [widget.url.goLink])),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  Future<void> _shareQrCode() async {
    setState(() {
      _isSharing = true;
    });

    final String qrCodeUrl = widget.url.qrCodePngUrl?.isNotEmpty == true
        ? widget.url.qrCodePngUrl!
        : 'https://api.nanourls.com/v1/nano/qr/${widget.url.shortUrl}';

    try {
      final response = await http.get(Uri.parse(qrCodeUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/qrcode_${widget.url.shortUrl}.png').create();
        await file.writeAsBytes(response.bodyBytes);

        final box = context.findRenderObject() as RenderBox?;
        final rect = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

        await SharePlus.instance.share(
          ShareParams(
            text: context.l10n('qr_share_text', args: [widget.url.shortUrl]),
            files: [XFile(file.path)],
            sharePositionOrigin: rect,
          ),
        );
      } else {
        throw context.l10n('qr_code_download_failed');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n('qr_share_error', args: [e])),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String qrCodeUrl = widget.url.qrCodePngUrl?.isNotEmpty == true
        ? widget.url.qrCodePngUrl!
        : 'https://api.nanourls.com/v1/nano/qr/${widget.url.shortUrl}';

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
            Text(
              context.l10n('qr_code_dialog_title'),
              style: const TextStyle(
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
                widget.url.shortUrl,
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

            // Share Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSharing ? null : _shareQrCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _isSharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textLight,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Theme.of(context).platform == TargetPlatform.iOS
                                ? Icons.ios_share
                                : Icons.share,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(context.l10n('share')),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12.0),

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
                child: Text(
                  context.l10n('close'),
                  style: const TextStyle(
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
