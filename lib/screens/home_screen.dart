import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../entities/nano_url.dart';
import '../components/url_card.dart';
import '../components/qr_code_dialog.dart';
import '../components/about_dialog.dart';
import '../components/confirm_action.dart'; // Importação do componente modularizado
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../services/admob_controller.dart';
import '../components/banner_ad_widget.dart';
import '../components/native_ad_card.dart';
import '../theme/app_theme.dart';
import '../helpers/glyph_helper.dart';

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
  String _selectedGlyphFilter = 'todos'; // 'todos' or any specific glyph
  bool _filterPasswordOnly = false;
  bool _filterAnalyticsOnly = false;
  bool _isCompactViewMode = false;
  bool _showTrashOnly = false;
  bool _isLoading = false;
  String? _apiError;

  int _urlsLeft = 142;
  int _analyticsLeft = 15;

  @override
  void initState() {
    super.initState();
    _loadViewModePreference();
    _loadDashboardData();
    AdmobController.instance.addListener(_onAdmobStateChange);
  }

  void _onAdmobStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    AdmobController.instance.removeListener(_onAdmobStateChange);
    super.dispose();
  }

  Future<void> _loadViewModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompact = prefs.getBool('is_compact_view') ?? false;
      setState(() {
        _isCompactViewMode = isCompact;
      });
    } catch (_) {
      // Preferences error
    }
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
        final updatedUser = await _apiService.fetchCurrentUser();
        _sessionManager.saveSession(_sessionManager.token!, updatedUser);
      } catch (_) {}

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
            content: Text('${context.l10n('error')}: $_apiError'),
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

  bool _checkUserEnabled() {
    final user = _sessionManager.currentUser;
    if (user != null && !user.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n('account_disabled_snackbar')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _openCreateScreen() async {
    if (!_checkUserEnabled()) return;
    final result = await Navigator.pushNamed(context, '/create-edit');
    if (result is NanoUrl) {
      _addNewShortenedUrl(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n('create_success_snackbar')),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  // Triggers screen to edit metadata of a link using route navigation
  Future<void> _editUrl(NanoUrl url) async {
    if (!_checkUserEnabled()) return;
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
        SnackBar(
          content: Text(context.l10n('update_success_snackbar')),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  // Deletes URL permanently or sends it to trash using API
  Future<void> _deleteUrl(NanoUrl url) async {
    if (!_checkUserEnabled()) return;
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

          ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Remove pendentes
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n('delete_success_snackbar')),
              action: SnackBarAction(
                label: context.l10n('undo'),
                textColor: AppColors.textLight,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _restoreUrl(updatedUrl);
                },
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating, // Desgruda das bordas e ajuda contra bugs da UI nativa
              duration: const Duration(seconds: 3),
            ),
          );

          // TRUQUE: Força o encerramento da Snackbar após 3 segundos, contornando a acessibilidade do Android
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          });
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n('delete_error_snackbar', args: [e.toString().replaceAll('HttpException: ', '')])),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      // 2. Permanent Delete from Trash (requires confirmation)
      // Utilizando o nosso componente modularizado agora!
      final confirmed = await showDialog<dynamic>(
        context: context,
        builder: (context) => ConfirmActionDialog(
          title: context.l10n('delete_trash_confirm_title'),
          message: context.l10n('delete_trash_confirm_message'),
          confirmText: context.l10n('delete'),
          isDanger: true,
          requirePassword: false, // Sem exigir a senha do usuário
        ),
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
                content: Text(context.l10n('delete_success_snackbar')),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 3),
              ),
            );
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n('delete_error_snackbar', args: [e.toString().replaceAll('HttpException: ', '')])),
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
    if (!_checkUserEnabled()) return;
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
        SnackBar(
          content: Text(context.l10n('restore_success_snackbar')),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n('restore_error_snackbar', args: [e.toString().replaceAll('HttpException: ', '')])),
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

      // Filter by password protection toggle separately
      if (_filterPasswordOnly && !url.hasPassword) return false;

      // Filter by analytics toggle
      if (_filterAnalyticsOnly && !url.analytics) return false;

      // Filter by selected glyph from the dropdown
      if (_selectedGlyphFilter != 'todos') {
        if (url.glyph?.toLowerCase() != _selectedGlyphFilter.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  static const int _adInterval = 5;

  bool _isAdIndex(int index, int filteredLength) {
    if (AdmobController.instance.adsDisabled || filteredLength == 0) return false;
    return index > 0 && (index + 1) % _adInterval == 0;
  }

  int _getUrlIndex(int index, int filteredLength) {
    if (AdmobController.instance.adsDisabled) return index;
    final adCount = (index + 1) ~/ _adInterval;
    return index - adCount;
  }

  int _getListItemCount(int filteredLength) {
    if (AdmobController.instance.adsDisabled || filteredLength == 0) {
      return filteredLength;
    }
    return filteredLength + (filteredLength - 1) ~/ (_adInterval - 1);
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
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const AboutNanoUrlsDialog(),
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundDarker,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: SvgPicture.asset('assets/svg/logo.svg'),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                _sessionManager.isAuthenticated
                    ? context.l10n('hello_user', args: [_sessionManager.currentUser?.userName ?? ''])
                    : context.l10n('dashboard_demo'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          // Account Button
          if (_sessionManager.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.manage_accounts, color: AppColors.primary),
              tooltip: context.l10n('account_settings_title'),
              onPressed: () {
                Navigator.of(context).pushNamed('/account');
              },
            ),
          // Refresh Button
          if (_sessionManager.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              tooltip: context.l10n('refresh_tooltip'),
              onPressed: _loadDashboardData,
            ),
          // Logout button styled matching card mode & refresh
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            tooltip: context.l10n('logout_tooltip'),
            onPressed: () {
              _sessionManager.clearSession();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_sessionManager.currentUser?.enabled == false)
            Container(
              width: double.infinity,
              color: Colors.amber[900]!.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n('account_disabled_warning'),
                      style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _loadDashboardData,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.l10n('update_btn'),
                      style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
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
                          _showTrashOnly
                              ? Text.rich(
                            TextSpan(
                              text: context.l10n('trash_title'),
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(
                                  text: context.l10n('trash_title_highlight'),
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : Text.rich(
                            TextSpan(
                              text: context.l10n('dashboard_title'),
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(
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
                                  tooltip: context.l10n('links_available', args: [_urlsLeft]),
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: _buildStatBadge(
                                  icon: const Icon(Icons.bar_chart, color: AppColors.primary, size: 16),
                                  count: '$_analyticsLeft',
                                  tooltip: context.l10n('analytics_unlocked', args: [_analyticsLeft]),
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
                                      color: _showTrashOnly ? Colors.redAccent : Colors.redAccent.withValues(alpha: 0.6),
                                      size: 16,
                                    ),
                                    count: '$_trashCount',
                                    tooltip: context.l10n('trash_mode_btn', args: [_trashCount]),
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
                              hintText: context.l10n('search_hint'),
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

                          // Filter Controls: View Mode Toggle, Glyph Dropdown, Analytics, and Password
                          Row(
                            children: [
                              _buildViewModeToggle(),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: _buildGlyphDropdown(),
                              ),
                              const SizedBox(width: 8.0),
                              _buildAnalyticsToggle(),
                              const SizedBox(width: 8.0),
                              _buildPasswordToggle(),
                            ],
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
                                    ? context.l10n('empty_urls_title_search')
                                    : (_showTrashOnly ? context.l10n('empty_trash_title') : context.l10n('empty_urls_title')),
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white38,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? context.l10n('empty_urls_desc_search')
                                    : (_showTrashOnly ? context.l10n('empty_urls_desc_trash') : context.l10n('empty_urls_desc')),
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
                            if (_isAdIndex(index, filteredList.length)) {
                              return NativeAdCard(key: ValueKey('ad_$index'));
                            }
                            final urlIndex = _getUrlIndex(index, filteredList.length);
                            if (urlIndex >= filteredList.length) {
                              return const SizedBox.shrink();
                            }
                            final item = filteredList[urlIndex];
                            return UrlCard(
                              key: ValueKey(item.shortUrl),
                              url: item,
                              isCompact: _isCompactViewMode,
                              onDetails: () {
                                Navigator.pushNamed(
                                  context,
                                  '/url-info',
                                  arguments: item,
                                );
                              },
                              onQrCode: () {
                                // Track action for ad count
                                AdmobController.instance.trackAction(context);
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
                          childCount: _getListItemCount(filteredList.length),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        shape: const CircleBorder(),
        onPressed: _openCreateScreen,
        child:  SvgPicture.asset('assets/svg/black_logo.svg', width: 28, height: 28),
      ),
      bottomNavigationBar: AdmobController.instance.adsDisabled
          ? null
          : const SafeArea(
        child: SizedBox(
          height: 50,
          child: Center(
            child: BannerAdWidget(),
          ),
        ),
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
        color: isActive ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.4)
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

  Widget _buildGlyphDropdown() {
    return Container(
      height: 48.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGlyphFilter,
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedGlyphFilter = newValue;
              });
            }
          },
          items: [
            DropdownMenuItem<String>(
              value: 'todos',
              child: Row(
                children: [
                  const Icon(Icons.grid_view, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8.0),
                  Text(
                    context.l10n('filter_all_glyphs'),
                    style: TextStyle(
                      color: _selectedGlyphFilter == 'todos' ? AppColors.primary : Colors.white70,
                      fontSize: 14.0,
                      fontFamily: 'SplineSans',
                    ),
                  ),
                ],
              ),
            ),
            ...GlyphHelper.availableGlyphs.map((String glyph) {
              final icon = GlyphHelper.getIconData(glyph);
              final displayName = GlyphHelper.getGlyphLabel(glyph, context);
              final isSelected = _selectedGlyphFilter == glyph;
              return DropdownMenuItem<String>(
                value: glyph,
                child: Row(
                  children: [
                    Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted, size: 18),
                    const SizedBox(width: 8.0),
                    Text(
                      displayName,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.white70,
                        fontSize: 14.0,
                        fontFamily: 'SplineSans',
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    final isCompact = _isCompactViewMode;
    return Tooltip(
      message: context.l10n('filter_view_mode_only'),
      child: InkWell(
        onTap: () async {
          setState(() {
            _isCompactViewMode = !_isCompactViewMode;
          });
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_compact_view', _isCompactViewMode);
          } catch (_) {}
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: 48.0,
          height: 48.0,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: AppColors.border,
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              isCompact ? Icons.view_stream : Icons.view_list,
              color: AppColors.primary,
              size: 18.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsToggle() {
    final isSelected = _filterAnalyticsOnly;
    return Tooltip(
      message: context.l10n('filter_analytics_only'),
      child: InkWell(
        onTap: () {
          setState(() {
            _filterAnalyticsOnly = !_filterAnalyticsOnly;
          });
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: 48.0,
          height: 48.0,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.bar_chart,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 18.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordToggle() {
    final isSelected = _filterPasswordOnly;
    return Tooltip(
      message: context.l10n('filter_protected_only'),
      child: InkWell(
        onTap: () {
          setState(() {
            _filterPasswordOnly = !_filterPasswordOnly;
          });
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: 48.0,
          height: 48.0,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              isSelected ? Icons.lock : Icons.lock_open,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 18.0,
            ),
          ),
        ),
      ),
    );
  }
}