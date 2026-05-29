import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../entities/nano_url.dart';
import '../theme/app_theme.dart';
import '../helpers/glyph_helper.dart';

// Card displaying shortened URL details, stats, and actions
class UrlCard extends StatefulWidget {
  final NanoUrl url;
  final bool isCompact;
  final VoidCallback onDetails;
  final VoidCallback onAnalytics;
  final VoidCallback onQrCode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onRestore;

  const UrlCard({
    super.key,
    required this.url,
    required this.isCompact,
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
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.isCompact;
  }

  @override
  void didUpdateWidget(covariant UrlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompact != oldWidget.isCompact) {
      _isExpanded = !widget.isCompact;
    }
  }

  void _shareLink(BuildContext context, String urlString) {
    final box = context.findRenderObject() as RenderBox?;
    final rect = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;
    SharePlus.instance.share(
      ShareParams(
        text: urlString,
        sharePositionOrigin: rect,
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    final meLink = widget.url.meLink;
    final goLink = widget.url.goLink;

    if (meLink == null || meLink.isEmpty) {
      _shareLink(context, goLink);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDarker,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Escolha o link para compartilhar',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                // GO Link Option
                InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _shareLink(context, goLink);
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Redirecionamento (GO)',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                goLink,
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                // ME Link Option
                InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _shareLink(context, meLink);
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blueAccent, size: 24),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Página de Detalhes (ME)',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                meLink,
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = widget.url.isExpired;
    final isEnabled = widget.url.enabled;

    return GestureDetector(
      onTap: widget.isCompact
          ? () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          : null,
      child: Container(
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
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            sizeCurve: Curves.easeInOut,
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: _buildCompactChild(),
            secondChild: _buildFullChild(isEnabled, isExpired),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChild() {
    return Row(
      children: [
        // Icon circle
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            GlyphHelper.getIconData(widget.url.glyph),
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12.0),
        // Titles and Status
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.url.shortUrl,
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.url.hasPassword) ...[
                const SizedBox(width: 6.0),
                const Icon(
                  Icons.lock,
                  color: Colors.amber,
                  size: 14.0,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white30,
            size: 20.0,
          ),
        ),
      ],
    );
  }

  Widget _buildFullChild(bool isEnabled, bool isExpired) {
    return Column(
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
                GlyphHelper.getIconData(widget.url.glyph),
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

            // Share Action Button
            InkWell(
              onTap: () => _showShareOptions(context),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Theme.of(context).platform == TargetPlatform.iOS
                          ? Icons.ios_share
                          : Icons.share,
                      size: 12.0,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6.0),
                    const Text(
                      'Compartilhar',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: AppColors.textMuted,
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
    );
  }
}
