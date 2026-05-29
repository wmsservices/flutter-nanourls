import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../entities/nano_url.dart';
import '../theme/app_theme.dart';

// Card displaying shortened URL details, stats, and actions
class UrlCard extends StatefulWidget {
  final NanoUrl url;
  final VoidCallback onDetails;
  final VoidCallback onAnalytics;
  final VoidCallback onQrCode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onRestore;

  const UrlCard({
    super.key,
    required this.url,
    required this.onDetails,
    required this.onAnalytics,
    required this.onQrCode,
    required this.onEdit,
    required this.onDelete,
    this.onRestore,
  });

  @override
  State<UrlCard> createState() => _UrlCardState();
}

class _UrlCardState extends State<UrlCard> {
  bool _isCopied = false;

  // Resolves the string icon name to a Flutter IconData
  IconData _getIconData(String? glyph) {
    switch (glyph?.toLowerCase()) {
      case 'link': return Icons.link;
      case 'star': return Icons.star;
      case 'favorite': return Icons.favorite;
      case 'home': return Icons.home;
      case 'work': return Icons.work;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'rocket_launch': return Icons.rocket_launch;
      case 'bolt': return Icons.bolt;
      case 'mail': return Icons.mail;
      case 'person': return Icons.person;
      case 'verified': return Icons.verified;
      case 'lock': return Icons.lock;
      case 'schedule': return Icons.schedule;
      case 'group': return Icons.group;
      case 'photo_camera': return Icons.photo_camera;
      case 'music_note': return Icons.music_note;
      case 'flight': return Icons.flight;
      case 'restaurant': return Icons.restaurant;
      case 'school': return Icons.school;
      case 'code': return Icons.code;
      case 'search': return Icons.search;
      case 'settings': return Icons.settings;
      case 'notifications': return Icons.notifications;
      case 'share': return Icons.share;
      case 'delete': return Icons.delete;
      case 'edit': return Icons.edit;
      case 'check_circle': return Icons.check_circle;
      case 'warning': return Icons.warning;
      case 'info': return Icons.info;
      case 'help': return Icons.help;
      default: return Icons.link;
    }
  }

  // Copies the short URL to the clipboard and runs a visual feedback animation
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.url.goLink)).then((_) {
      if (!mounted) return;
      setState(() {
        _isCopied = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isCopied = false;
          });
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link copiado: ${widget.url.shortUrl}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = widget.url.isExpired;
    final isEnabled = widget.url.enabled;

    // Build the visual card boundary
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: !isEnabled
              ? Colors.redAccent.withOpacity(0.2)
              : (isExpired
                  ? AppColors.border
                  : AppColors.primary.withOpacity(0.1)),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon, Link Title, Actions Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconData(widget.url.glyph),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12.0),
                // Titles and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.url.shortUrl,
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.url.hasPassword) ...[
                            const SizedBox(width: 4.0),
                            const Icon(
                              Icons.lock,
                              color: Colors.amber,
                              size: 14.0,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      // Status Label
                      Text(
                        !isEnabled
                            ? 'LIXEIRA'
                            : (isExpired ? 'EXPIRADO' : 'ATIVO'),
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: !isEnabled
                              ? Colors.redAccent
                              : (isExpired ? Colors.redAccent : AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions popup/menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: const BorderSide(color: AppColors.border, width: 1.0),
                  ),
                  onSelected: (value) {
                    if (value == 'details') {
                      widget.onDetails();
                    } else if (value == 'qrcode') {
                      widget.onQrCode();
                    } else if (value == 'edit') {
                      widget.onEdit();
                    } else if (value == 'delete') {
                      widget.onDelete();
                    } else if (value == 'restore') {
                      widget.onRestore?.call();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      if (isEnabled) ...[
                        const PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18.0, color: AppColors.primary),
                              SizedBox(width: 8.0),
                              Text('Detalhes', style: TextStyle(fontSize: 14.0)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'qrcode',
                          child: Row(
                            children: [
                              Icon(Icons.qr_code, size: 18.0, color: Colors.blueAccent),
                              SizedBox(width: 8.0),
                              Text('Código QR', style: TextStyle(fontSize: 14.0)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18.0, color: Colors.white70),
                              SizedBox(width: 8.0),
                              Text('Editar', style: TextStyle(fontSize: 14.0)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18.0, color: Colors.redAccent),
                              SizedBox(width: 8.0),
                              Text('Excluir', style: TextStyle(fontSize: 14.0)),
                            ],
                          ),
                        ),
                      ] else ...[
                        const PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              Icon(Icons.restore_from_trash, size: 18.0, color: Colors.greenAccent),
                              SizedBox(width: 8.0),
                              Text('Restaurar', style: TextStyle(fontSize: 14.0)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever, size: 18.0, color: Colors.redAccent),
                              SizedBox(width: 8.0),
                              Text('Excluir Definitivo', style: TextStyle(fontSize: 14.0)),
                            ],
                          ),
                        ),
                      ],
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            
            // Row 2: Target/Original URL Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceInner,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                widget.url.realUrl,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13.0,
                  color: AppColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8.0),

            // Row 3: Description text
            if (widget.url.description.isNotEmpty)
              Text(
                widget.url.description,
                style: const TextStyle(
                  fontSize: 13.0,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else
              const Text(
                'Sem descrição',
                style: TextStyle(
                  fontSize: 13.0,
                  fontStyle: FontStyle.italic,
                  color: Colors.white24,
                ),
              ),
            const SizedBox(height: 8.0),

            // Row 4: Expiration warning if set
            if (widget.url.expiresAt != null) ...[
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Icon(
                    isExpired ? Icons.timer_off : Icons.timer,
                    size: 14.0,
                    color: isExpired ? Colors.redAccent : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    isExpired
                        ? 'Expirou em: ${widget.url.expiresAt!.toLocal().toString().substring(0, 16)}'
                        : 'Expira em: ${widget.url.expiresAt!.toLocal().toString().substring(0, 16)}',
                    style: TextStyle(
                      fontSize: 11.0,
                      color: isExpired ? Colors.redAccent : Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12.0),
            const Divider(color: AppColors.borderSubtle, height: 1.0),
            const SizedBox(height: 12.0),

            // Row 5: Click Counter (Secondary CTA) & Copy Link Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Analytics Click Pill
                InkWell(
                  onTap: widget.url.analytics && isEnabled ? widget.onAnalytics : null,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 16.0,
                          color: widget.url.analytics ? AppColors.primary : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          '${widget.url.clicks}',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        const Text(
                          'cliques',
                          style: TextStyle(
                            fontSize: 11.0,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Copy Action Button
                InkWell(
                  onTap: _copyToClipboard,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _isCopied
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.1),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isCopied ? Icons.check : Icons.copy,
                          size: 12.0,
                          color: _isCopied ? AppColors.primary : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          _isCopied ? 'Copiado!' : 'Copiar',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: _isCopied ? Colors.white : AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
