import 'dart:async';
import 'package:flutter/material.dart';
import '../entities/nano_url.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';

class CreateEditUrlScreen extends StatefulWidget {
  const CreateEditUrlScreen({super.key});

  @override
  State<CreateEditUrlScreen> createState() => _CreateEditUrlScreenState();
}

class _CreateEditUrlScreenState extends State<CreateEditUrlScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();

  late final TextEditingController _realUrlController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _shortUrlController;
  late final TextEditingController _passwordController;

  NanoUrl? _initialUrl;
  bool _isInit = false;

  String _selectedGlyph = 'link';
  bool _showGlyphGrid = false;
  bool _checkExpires = false;
  DateTime? _expiresAt;
  bool _checkPassword = false;
  bool _analytics = true;

  bool _isSubmitting = false;
  String? _errorMessage;

  // Debounce alias verification
  Timer? _debounceTimer;
  bool _isCheckingAlias = false;
  bool? _aliasAvailable;
  String? _aliasFeedbackText;

  final List<String> _availableGlyphs = [
    "link", "star", "favorite", "home", "work",
    "shopping_cart", "rocket_launch", "bolt", "mail", "person",
    "verified", "lock", "schedule", "group", "photo_camera",
    "music_note", "flight", "restaurant", "school", "code",
    "search", "settings", "notifications", "share", "delete",
    "edit", "check_circle", "warning", "info", "help"
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _initialUrl = ModalRoute.of(context)!.settings.arguments as NanoUrl?;
      final isEdit = _initialUrl != null;

      _realUrlController = TextEditingController(text: _initialUrl?.realUrl ?? '');
      _descriptionController = TextEditingController(text: _initialUrl?.description ?? '');
      _shortUrlController = TextEditingController(text: _initialUrl?.shortUrl ?? '');
      _passwordController = TextEditingController();

      if (isEdit) {
        _selectedGlyph = _initialUrl!.glyph ?? 'link';
        _checkExpires = _initialUrl!.expiresAt != null;
        _expiresAt = _initialUrl!.expiresAt;
        _checkPassword = _initialUrl!.hasPassword;
        _analytics = _initialUrl!.analytics;
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _realUrlController.dispose();
    _descriptionController.dispose();
    _shortUrlController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  IconData _getIconData(String name) {
    switch (name) {
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

  // Debounced check for short URL availability
  void _onShortUrlChanged(String value) {
    if (_initialUrl != null) return; // Do not check alias on edit mode
    final alias = value.trim();

    _debounceTimer?.cancel();
    if (alias.isEmpty) {
      setState(() {
        _isCheckingAlias = false;
        _aliasAvailable = null;
        _aliasFeedbackText = null;
      });
      return;
    }

    setState(() {
      _isCheckingAlias = true;
      _aliasAvailable = null;
      _aliasFeedbackText = null;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final available = await _apiService.checkAlias(alias);
        if (!mounted) return;
        setState(() {
          _isCheckingAlias = false;
          _aliasAvailable = available;
          if (!available) {
            _aliasFeedbackText = 'Este alias já está em uso.';
          }
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isCheckingAlias = false;
          // Fail safely: unlock the submit button in case of network issues checking
          _aliasAvailable = true;
        });
      }
    });
  }

  Future<void> _selectExpiresDateTime() async {
    final now = DateTime.now();
    final minDate = now.add(const Duration(hours: 24));
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expiresAt != null && _expiresAt!.isAfter(minDate) ? _expiresAt! : minDate,
      firstDate: minDate,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.textLight,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiresAt ?? minDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.textLight,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      _expiresAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isCheckingAlias) return;
    if (_initialUrl == null && _aliasAvailable == false) return; // Cannot save if alias is taken

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final isEdit = _initialUrl != null;
    final realUrl = _realUrlController.text.trim();
    final description = _descriptionController.text.trim();
    final shortUrl = _shortUrlController.text.trim();
    final password = _checkPassword
        ? (_passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : null)
        : '';
    final expiresAt = _checkExpires ? _expiresAt : null;

    // Custom expiration check: must be at least 24h
    if (_checkExpires && expiresAt != null) {
      final minimum = DateTime.now().add(const Duration(hours: 24));
      if (expiresAt.isBefore(minimum)) {
        setState(() {
          _errorMessage = 'A data de expiração deve ser de pelo menos 24 horas no futuro.';
          _isSubmitting = false;
        });
        return;
      }
    }

    try {
      if (isEdit) {
        await _apiService.updateNanoUrl(
          shortUrl: shortUrl,
          realUrl: realUrl,
          description: description,
          glyph: _selectedGlyph,
          password: password,
          expiresAt: expiresAt,
          analytics: _analytics,
          enabled: _initialUrl!.enabled,
        );
      } else {
        await _apiService.saveNanoUrl(
          shortUrl: shortUrl,
          realUrl: realUrl,
          description: description,
          glyph: _selectedGlyph,
          password: password,
          expiresAt: expiresAt,
          analytics: _analytics,
        );
      }

      final generatedCode = shortUrl.isNotEmpty
          ? shortUrl
          : (_initialUrl?.shortUrl ?? 'nano-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}');

      final newUrl = NanoUrl(
        userId: _initialUrl?.userId ?? _sessionManager.currentUser?.userId ?? '',
        shortUrl: generatedCode,
        glyph: _selectedGlyph,
        description: description,
        realUrl: realUrl,
        password: password ?? _initialUrl?.password ?? '',
        createdAt: _initialUrl?.createdAt ?? DateTime.now(),
        lastModified: DateTime.now(),
        expiresAt: expiresAt,
        clicks: _initialUrl?.clicks ?? 0,
        enabled: _initialUrl?.enabled ?? true,
        analytics: _analytics,
        goLink: 'https://nanourls.com/go/$generatedCode',
        meLink: 'https://nanourls.com/me/$generatedCode',
        qrCodeSvgUrl: _initialUrl?.qrCodeSvgUrl ?? '',
        qrCodePngUrl: _initialUrl?.qrCodePngUrl ?? '',
        hasPassword: _checkPassword && (password == null || password.isNotEmpty),
      );

      if (mounted) Navigator.pop(context, newUrl);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _initialUrl != null;
    
    // Dynamic styles based on alias checks
    Color? aliasBorderColor;
    Widget? aliasSuffixIcon;

    if (_initialUrl == null) {
      if (_isCheckingAlias) {
        aliasSuffixIcon = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.textMuted),
        );
      } else if (_aliasAvailable == true) {
        aliasBorderColor = Colors.green;
        aliasSuffixIcon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
      } else if (_aliasAvailable == false) {
        aliasBorderColor = Colors.redAccent;
        aliasSuffixIcon = const Icon(Icons.cancel, color: Colors.redAccent, size: 20);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Editar NanoUrl' : 'Criar NanoUrl'),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon / Glyph Selector Row
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'ÍCONE DO LINK',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showGlyphGrid = !_showGlyphGrid;
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceInner,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _showGlyphGrid ? AppColors.primary : Colors.white.withOpacity(0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  _getIconData(_selectedGlyph),
                                  color: AppColors.primary,
                                  size: 36.0,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 12),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Animated Glyph Grid Toggle
                        if (_showGlyphGrid) ...[
                          const SizedBox(height: 12.0),
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceInner,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _availableGlyphs.length,
                              itemBuilder: (context, index) {
                                final glyphName = _availableGlyphs[index];
                                final isSelected = _selectedGlyph == glyphName;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedGlyph = glyphName;
                                      _showGlyphGrid = false;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : Colors.transparent,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Icon(
                                      _getIconData(glyphName),
                                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                                      size: 20,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Original Destination Link
                  Row(
                    children: [
                      const Text(
                        'URL ORIGINAL',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '*',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  TextFormField(
                    controller: _realUrlController,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(color: Colors.white, fontSize: 14.0),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.link, size: 20.0),
                      hintText: 'https://exemplo.com/pagina-longa',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira a URL original.';
                      }
                      final lower = value.toLowerCase();
                      if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
                        return 'A URL deve começar com http:// ou https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Description input
                  const Text(
                    'DESCRIÇÃO',
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white, fontSize: 14.0),
                    decoration: const InputDecoration(
                      hintText: 'Descrição amigável deste link...',
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Custom Alias field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ALIAS PERSONALIZADO',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        isEdit ? 'Não editável' : 'Opcional',
                        style: const TextStyle(
                          fontSize: 10.0,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  TextFormField(
                    controller: _shortUrlController,
                    enabled: !isEdit,
                    style: TextStyle(
                      color: isEdit ? AppColors.textMuted : Colors.white,
                      fontSize: 14.0,
                    ),
                    onChanged: _onShortUrlChanged,
                    decoration: InputDecoration(
                      hintText: isEdit ? '' : 'ex: cupom-natal',
                      suffixIcon: aliasSuffixIcon != null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: aliasSuffixIcon,
                            )
                          : null,
                      enabledBorder: aliasBorderColor != null
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(color: aliasBorderColor, width: 1.0),
                            )
                          : null,
                      focusedBorder: aliasBorderColor != null
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(color: aliasBorderColor, width: 2.0),
                            )
                          : null,
                    ),
                  ),
                  if (_aliasFeedbackText != null) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      _aliasFeedbackText!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12.0),
                    ),
                  ],
                  const SizedBox(height: 20.0),

                  // Expiration Toggle & Selector Box (Horizontal Overflow Bug Fixes)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInner,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.white.withOpacity(0.02)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer, color: Colors.white70, size: 18),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Definir Expiração',
                                    style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const Text(
                                    'O link deixará de funcionar na data',
                                    style: TextStyle(fontSize: 11.0, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _checkExpires,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _checkExpires = val;
                                  if (val && _expiresAt == null) {
                                    _expiresAt = DateTime.now().add(const Duration(hours: 24));
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (_checkExpires && _expiresAt != null) ...[
                          const SizedBox(height: 12.0),
                          const Divider(color: Colors.white10, height: 1.0),
                          const SizedBox(height: 12.0),
                          GestureDetector(
                            onTap: _selectExpiresDateTime,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_expiresAt!.toLocal().toString().substring(0, 16)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 13.0),
                                  ),
                                  const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Password toggle container (Horizontal Overflow Bug Fixes)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInner,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.white.withOpacity(0.02)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock, color: Colors.white70, size: 18),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Proteger com Senha',
                                    style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const Text(
                                    'Requer senha para redirecionar',
                                    style: TextStyle(fontSize: 11.0, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _checkPassword,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _checkPassword = val;
                                });
                              },
                            ),
                          ],
                        ),
                        if (_checkPassword) ...[
                          const SizedBox(height: 12.0),
                          const Divider(color: Colors.white10, height: 1.0),
                          const SizedBox(height: 12.0),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white, fontSize: 14.0),
                            decoration: InputDecoration(
                              hintText: isEdit ? 'Digite nova senha (ou deixe em branco)' : 'Senha de acesso',
                            ),
                            validator: (value) {
                              if (_checkPassword && !isEdit && (value == null || value.trim().isEmpty)) {
                                  return 'Por favor, defina uma senha.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Analytics container (Horizontal Overflow Bug Fixes)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInner,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.white.withOpacity(0.02)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.bar_chart, color: Colors.white70, size: 18),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ativar Analytics',
                                style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const Text(
                                'Coletar dados estatísticos de acessos',
                                style: TextStyle(fontSize: 11.0, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _analytics,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _analytics = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Error Message banner
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20.0),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24.0),

                  // Footer Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 12.0),
                      ElevatedButton(
                        onPressed: (_isSubmitting || (!isEdit && (_isCheckingAlias || _aliasAvailable == false))) ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: (_isSubmitting || (!isEdit && (_isCheckingAlias || _aliasAvailable == false))) ? 0 : 4,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.textLight),
                              )
                            : Row(
                                children: [
                                  const Icon(Icons.save, size: 16),
                                  const SizedBox(width: 6.0),
                                  Text(isEdit ? 'Salvar' : 'Criar'),
                                ],
                              ),
                      ),
                    ],
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
