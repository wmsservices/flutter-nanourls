import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../entities/nano_url.dart';
import '../components/url_card.dart';
import '../components/qr_code_dialog.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';

// Main Dashboard screen for NanoUrls containing URL creation and managing
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();

  late List<NanoUrl> _urls = [];
  String _searchQuery = '';
  String _selectedGlyphFilter = 'todos'; // 'todos', 'link', 'bolt', 'security', 'lock'
  bool _showTrashOnly = false;
  bool _isLoading = false;
  String? _apiError;

  int _urlsLeft = 142;
  int _analyticsLeft = 15;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Load URLs from the API
  Future<void> _loadDashboardData() async {
    if (!_sessionManager.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    setState(() {
      _isLoading = true;
      _apiError = null;
    });

    try {
      final list = await _apiService.fetchUserUrls();
      int urlsLeft = _urlsLeft;
      int analyticsLeft = _analyticsLeft;

      try {
        urlsLeft = await _apiService.fetchNanoUrlsLeft();
      } catch (_) {}

      try {
        analyticsLeft = await _apiService.fetchAnalyticsLeft();
      } catch (_) {}

      setState(() {
        _urls = list;
        _urlsLeft = urlsLeft;
        _analyticsLeft = analyticsLeft;
      });
    } catch (e) {
      setState(() {
        _apiError = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
        _urls = [];
      });
      
      // Notify user about API error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados da API: $_apiError'),
            backgroundColor: Colors.red[800],
            duration: const Duration(seconds: 4),
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Calculate trash count dynamically
  int get _trashCount => _urls.where((u) => !u.enabled).length;



  // Prepends the new URL to the list and updates user remaining balance
  void _addNewShortenedUrl(NanoUrl url) {
    setState(() {
      _urls.insert(0, url);
      if (_urlsLeft > 0) _urlsLeft--;
    });
  }

  Future<void> _openCreateScreen() async {
    final result = await Navigator.pushNamed(context, '/create-edit');
    if (result is NanoUrl) {
      _addNewShortenedUrl(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NanoUrl criada com sucesso!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  // Triggers screen to edit metadata of a link using route navigation
  Future<void> _editUrl(NanoUrl url) async {
    final result = await Navigator.pushNamed(
      context,
      '/create-edit',
      arguments: url,
    );
    if (result is NanoUrl) {
      setState(() {
        final index = _urls.indexWhere((u) => u.shortUrl == url.shortUrl);
        if (index != -1) {
          _urls[index] = result;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações salvas com sucesso!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  // Deletes URL permanently or sends it to trash using API
  Future<void> _deleteUrl(NanoUrl url) async {
    final isAuthenticated = _sessionManager.isAuthenticated;

    if (url.enabled) {
      // 1. Move to Trash (Active -> Trash)
      try {
        if (isAuthenticated) {
          await _apiService.updateNanoUrl(
            shortUrl: url.shortUrl,
            realUrl: url.realUrl,
            description: url.description,
            glyph: url.glyph,
            password: url.password.isNotEmpty ? url.password : null,
            expiresAt: url.expiresAt,
            analytics: url.analytics,
            enabled: false, // Move to trash
          );
        }

        setState(() {
          final updatedUrl = NanoUrl(
            userId: url.userId,
            shortUrl: url.shortUrl,
            glyph: url.glyph,
            description: url.description,
            realUrl: url.realUrl,
            password: url.password,
            createdAt: url.createdAt,
            lastModified: DateTime.now(),
            expiresAt: url.expiresAt,
            clicks: url.clicks,
            enabled: false, // Disabled
            analytics: url.analytics,
            goLink: url.goLink,
            meLink: url.meLink,
            qrCodeSvgUrl: url.qrCodeSvgUrl,
            qrCodePngUrl: url.qrCodePngUrl,
            hasPassword: url.hasPassword,
          );

          final index = _urls.indexWhere((u) => u.shortUrl == url.shortUrl);
          if (index != -1) {
            _urls[index] = updatedUrl;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${url.shortUrl}" enviado para a lixeira.'),
              action: SnackBarAction(
                label: 'DESFAZER',
                textColor: AppColors.textLight,
                onPressed: () => _restoreUrl(updatedUrl),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao enviar para a lixeira: ${e.toString().replaceAll('HttpException: ', '')}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      // 2. Permanent Delete from Trash (requires confirmation)
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: const BorderSide(color: AppColors.border),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                SizedBox(width: 8),
                Text(
                  'Confirmar Exclusão',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
                ),
              ],
            ),
            content: Text(
              'Esta ação é irreversível e o redirecionamento para "${url.shortUrl}" deixará de funcionar imediatamente. Deseja continuar?',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14.0),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Excluir'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        try {
          if (isAuthenticated) {
            await _apiService.deleteNanoUrl(url.shortUrl);
          }

          setState(() {
            _urls.removeWhere((u) => u.shortUrl == url.shortUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${url.shortUrl}" excluído permanentemente.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao excluir: ${e.toString().replaceAll('HttpException: ', '')}'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    }
  }

  // Restores items from trash to active state using API
  Future<void> _restoreUrl(NanoUrl url) async {
    final isAuthenticated = _sessionManager.isAuthenticated;

    try {
      if (isAuthenticated) {
        await _apiService.updateNanoUrl(
          shortUrl: url.shortUrl,
          realUrl: url.realUrl,
          description: url.description,
          glyph: url.glyph,
          password: url.password.isNotEmpty ? url.password : null,
          expiresAt: url.expiresAt,
          analytics: url.analytics,
          enabled: true, // Reactivated
        );
      }

      setState(() {
        final index = _urls.indexWhere((u) => u.shortUrl == url.shortUrl);
        if (index != -1) {
          _urls[index] = NanoUrl(
            userId: url.userId,
            shortUrl: url.shortUrl,
            glyph: url.glyph,
            description: url.description,
            realUrl: url.realUrl,
            password: url.password,
            createdAt: url.createdAt,
            lastModified: DateTime.now(),
            expiresAt: url.expiresAt,
            clicks: url.clicks,
            enabled: true, // Reactivated
            analytics: true,
            goLink: url.goLink,
            meLink: url.meLink,
            qrCodeSvgUrl: url.qrCodeSvgUrl,
            qrCodePngUrl: url.qrCodePngUrl,
            hasPassword: url.hasPassword,
          );
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link restaurado com sucesso!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao restaurar: ${e.toString().replaceAll('HttpException: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Filter logic helper
  List<NanoUrl> get _filteredUrls {
    return _urls.where((url) {
      if (_showTrashOnly) {
        if (url.enabled) return false;
      } else {
        if (!url.enabled) return false;
      }

      final matchQuery = url.shortUrl.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          url.realUrl.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          url.description.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchQuery) return false;

      if (_selectedGlyphFilter == 'todos') return true;
      if (_selectedGlyphFilter == 'lock') return url.hasPassword;
      return url.glyph?.toLowerCase() == _selectedGlyphFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredUrls;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.backgroundDarker,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: SvgPicture.asset('assets/svg/logo.svg'),
            ),
            const SizedBox(width: 8.0),
            Text(
              _sessionManager.isAuthenticated 
                  ? 'Olá, ${_sessionManager.currentUser?.userName}' 
                  : 'Dashboard Demo',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Refresh Button
          if (_sessionManager.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _loadDashboardData,
            ),
          // Account Profile circle button (Logs out)
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.logout, size: 16, color: Colors.white70),
            ),
            onPressed: () {
              _sessionManager.clearSession();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Search Field & Filter Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'Minhas ',
                        style: const TextStyle(
                          fontSize: 20.0,
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
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildStatBadge(
                            icon: SvgPicture.asset('assets/svg/logo.svg', width: 14, height: 14),
                            count: '$_urlsLeft',
                            tooltip: 'Links disponíveis',
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: _buildStatBadge(
                            icon: const Icon(Icons.bar_chart, color: AppColors.primary, size: 16),
                            count: '$_analyticsLeft',
                            tooltip: 'Analytics liberados',
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showTrashOnly = !_showTrashOnly;
                              });
                            },
                            child: _buildStatBadge(
                              icon: Icon(
                                Icons.delete,
                                color: _showTrashOnly ? Colors.redAccent : Colors.redAccent.withOpacity(0.6),
                                size: 16,
                              ),
                              count: '$_trashCount',
                              tooltip: 'Lixeira',
                              isActive: _showTrashOnly,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    
                    TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Pesquise pelo link ou descrição...',
                        prefixIcon: const Icon(Icons.search),
                        fillColor: AppColors.surfaceInner,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Horizontal Category Pills
                    SizedBox(
                      height: 38.0,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryPill('Todos', 'todos', Icons.grid_view),
                          _buildCategoryPill('Gerais', 'link', Icons.link),
                          _buildCategoryPill('Rápidos', 'bolt', Icons.bolt),
                          _buildCategoryPill('Seguros', 'security', Icons.security),
                          _buildCategoryPill('Protegidos', 'lock', Icons.lock),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),

            // Dynamic lists of cards or loading state
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else if (filteredList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.link_off,
                          size: 64,
                          color: Colors.white12,
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          _searchQuery.isNotEmpty 
                              ? 'Nenhum resultado encontrado' 
                              : (_showTrashOnly ? 'Lixeira vazia!' : 'Você não possui links criados'),
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          _searchQuery.isNotEmpty 
                              ? 'Tente alterar os termos ou filtros de pesquisa.' 
                              : (_showTrashOnly ? 'Links movidos para a lixeira aparecerão aqui.' : 'Cole um link longo na caixa acima para encurtar.'),
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredList[index];
                      return UrlCard(
                        key: ValueKey(item.shortUrl),
                        url: item,
                        onDetails: () {
                          Navigator.pushNamed(
                            context,
                            '/url-info',
                            arguments: item,
                          );
                        },
                        onQrCode: () {
                          showDialog(
                            context: context,
                            builder: (context) => QrCodeDialog(url: item),
                          );
                        },
                        onAnalytics: () {
                          Navigator.of(context).pushNamed(
                            '/details',
                            arguments: item.shortUrl,
                          );
                        },
                        onEdit: () => _editUrl(item),
                        onDelete: () => _deleteUrl(item),
                        onRestore: () => _restoreUrl(item),
                      );
                    },
                    childCount: filteredList.length,
                  ),
                ),
              ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: 32.0),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        shape: const CircleBorder(),
        onPressed: _openCreateScreen,
        child:  SvgPicture.asset('assets/svg/black_logo.svg', width: 28, height: 28),
      ),
    );
  }

  Widget _buildStatBadge({
    required Widget icon,
    required String count,
    required String tooltip,
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive 
              ? AppColors.primary.withOpacity(0.4) 
              : AppColors.border,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8.0),
          Text(
            count,
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String title, String value, IconData icon) {
    final isSelected = _selectedGlyphFilter == value;
    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 16.0,
          color: isSelected ? AppColors.textLight : AppColors.textMuted,
        ),
        label: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.textLight : Colors.white70,
            fontSize: 13.0,
            fontFamily: 'SplineSans',
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        onSelected: (bool selected) {
          setState(() {
            _selectedGlyphFilter = selected ? value : 'todos';
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.0,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }
}
