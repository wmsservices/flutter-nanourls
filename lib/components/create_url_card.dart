import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../entities/nano_url.dart';
import '../theme/app_theme.dart';

// Prominent form card to create a new shortened URL
class CreateUrlCard extends StatefulWidget {
  final Future<NanoUrl?> Function(String originalUrl) onShorten;
  final Function(NanoUrl url) onSuccess;

  const CreateUrlCard({
    super.key,
    required this.onShorten,
    required this.onSuccess,
  });

  @override
  State<CreateUrlCard> createState() => _CreateUrlCardState();
}

class _CreateUrlCardState extends State<CreateUrlCard> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  NanoUrl? _createdUrl;
  bool _isCopied = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // Validates the inputs and triggers the shorten callback
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _createdUrl = null;
    });

    try {
      final result = await widget.onShorten(_urlController.text.trim());
      if (result != null) {
        setState(() {
          _createdUrl = result;
          _urlController.clear();
        });
        widget.onSuccess(result);
      } else {
        setState(() {
          _errorMessage = 'Ocorreu um erro ao encurtar o link. Tente novamente.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de rede ou servidor. Verifique a conexão.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Copy helper for the successfully created URL
  void _copyCreatedUrl() {
    if (_createdUrl == null) return;
    Clipboard.setData(ClipboardData(text: _createdUrl!.goLink)).then((_) {
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
          content: Text('Copiado: ${_createdUrl!.goLink}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0), // lg (1.5rem)
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Encurte um link longo',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12.0),
            
            // Input field
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              style: const TextStyle(color: Colors.white, fontSize: 15.0),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.link, size: 20.0),
                hintText: 'Cole a URL original aqui...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira um link original.';
                }
                // Basic URL format validation
                final lowercase = value.toLowerCase();
                if (!lowercase.startsWith('http://') && !lowercase.startsWith('https://')) {
                  return 'O link deve começar com http:// ou https://';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  elevation: _isLoading ? 0 : 8,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.textLight,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt, size: 20.0),
                          SizedBox(width: 8.0),
                          Text('Encurtar URL'),
                        ],
                      ),
              ),
            ),

            // Error display banner
            if (_errorMessage != null) ...[
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.redAccent, size: 20.0),
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

            // Success display banner
            if (_createdUrl != null) ...[
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.primary, size: 20.0),
                        SizedBox(width: 8.0),
                        Text(
                          'Sucesso! Link Encurtado',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _copyCreatedUrl,
                            child: Text(
                              _createdUrl!.goLink,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isCopied ? Icons.check : Icons.copy,
                            color: _isCopied ? AppColors.primary : Colors.white70,
                            size: 18.0,
                          ),
                          onPressed: _copyCreatedUrl,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
