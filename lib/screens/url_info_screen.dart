import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../entities/nano_url.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class UrlInfoScreen extends StatelessWidget {
  const UrlInfoScreen({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n('copy_success_snackbar');
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
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
        title: Text(context.l10n('url_details_title')),
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
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n('shortened_url_label').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      GestureDetector(
                        onTap: () => _copyToClipboard(context, url.goLink),
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
                Text(
                  context.l10n('original_destination_label').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6.0),
                GestureDetector(
                  onTap: () => _copyToClipboard(context, url.realUrl),
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
                Text(
                  context.l10n('description').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  url.description.isNotEmpty ? url.description : context.l10n('no_description'),
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontStyle: url.description.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 24.0),

                // Password Protected Warning
                if (url.hasPassword) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.amber, size: 16.0),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            context.l10n('password_protected_url'),
                            style: const TextStyle(
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
                    Text(
                      context.l10n('clicks_count'),
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
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
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  context.l10n('back'),
                  style: const TextStyle(
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
