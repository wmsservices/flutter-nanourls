import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../dtos/my_analytics_dto.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../helpers/glyph_helper.dart';

// Screen displaying the Analytics Hub: comparison dashboard across the user's NanoUrls
class MyAnalyticsScreen extends StatefulWidget {
  const MyAnalyticsScreen({super.key});

  @override
  State<MyAnalyticsScreen> createState() => _MyAnalyticsScreenState();
}

class _MyAnalyticsScreenState extends State<MyAnalyticsScreen> {
  final ApiService _apiService = ApiService();

  MyAnalyticsDto? _data;
  bool _isLoading = true;
  bool _isReloading = false;
  String? _errorMessage;
  int _selectedDays = 7;
  int _topN = 0; // 0 = todas as posições do ranking
  List<String>? _selectedCodes; // null = padrão do backend (mais clicadas)

  // Métricas detalhadas (geo, origens, dispositivos) são exclusivas dos planos Pro/Max
  bool get _isFreePlan => SessionManager().currentUser?.planId == 1;

  // Paleta espelhada do gráfico comparativo do WebApp
  static const List<Color> _seriesPalette = [
    Color(0xFFB3E600),
    Color(0xFF00E6C3),
    Color(0xFFE6B300),
    Color(0xFF38BDF8),
    Color(0xFFE879F9),
    Color(0xFFFB7185),
    Color(0xFFA3E635),
    Color(0xFFF97316),
  ];

  static const List<Color> _devicePalette = [
    Color(0xFFB3E600),
    Color(0xFF00E6C3),
    Color(0xFFE6B300),
    Color(0xFF38BDF8),
    Color(0xFF64748B),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      if (_data == null) {
        _isLoading = true;
      } else {
        _isReloading = true;
      }
      _errorMessage = null;
    });

    try {
      final result = await _apiService.fetchMyAnalytics(days: _selectedDays, codes: _selectedCodes);
      setState(() {
        _data = result;
        _isLoading = false;
        _isReloading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
        _isLoading = false;
        _isReloading = false;
      });
    }
  }

  String _deviceLabel(String device) {
    switch (device) {
      case 'Desktop':
        return context.l10n('device_desktop');
      case 'Mobile':
        return context.l10n('device_mobile');
      case 'Tablet':
        return context.l10n('device_tablet');
      case 'Bot':
        return context.l10n('device_bot');
      default:
        return context.l10n('device_unknown');
    }
  }

  // Abre o seletor de NanoUrls (bottom sheet com busca e limite de seleção)
  Future<void> _openUrlSelector() async {
    final data = _data;
    if (data == null) return;

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _UrlSelectorSheet(
        options: data.availableUrls,
        maxSelectable: math.min(MyAnalyticsDto.maxComparisonUrls, data.analyticsUrlsCount),
      ),
    );

    if (result is List<String> && result.isNotEmpty) {
      setState(() => _selectedCodes = result);
      _loadData();
    } else if (result == 'most_clicked') {
      setState(() => _selectedCodes = null);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null || _data == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(context.l10n('my_analytics_title'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16.0),
                Text(
                  _errorMessage ?? context.l10n('error_loading_analytics'),
                  style: const TextStyle(color: Colors.white70, fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _loadData,
                  child: Text(context.l10n('try_again')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _data!;

    if (data.analyticsUrlsCount == 0) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(context.l10n('my_analytics_title'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.query_stats, size: 64, color: Colors.white12),
                const SizedBox(height: 16.0),
                Text(
                  context.l10n('my_analytics_empty_title'),
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white38),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6.0),
                Text(
                  context.l10n('my_analytics_empty_desc'),
                  style: const TextStyle(fontSize: 13.0, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n('my_analytics_manage_urls')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n('my_analytics_title'))),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _isReloading ? 0.5 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSelectorCard(data),
                const SizedBox(height: 20.0),
                _buildComparisonChartCard(data),
                const SizedBox(height: 20.0),
                _buildOverviewCard(data),
                const SizedBox(height: 20.0),
                _buildRankingCard(data),
                const SizedBox(height: 20.0),
                _buildCountriesCard(data),
                const SizedBox(height: 20.0),
                _buildCitiesCard(data),
                const SizedBox(height: 20.0),
                _buildReferrersCard(data),
                const SizedBox(height: 20.0),
                _buildDevicesCard(data),
                const SizedBox(height: 32.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== Seletor de NanoUrls =====
  Widget _buildSelectorCard(MyAnalyticsDto data) {
    final selected = data.availableUrls.where((u) => u.selected).toList();
    final maxSelectable = math.min(MyAnalyticsDto.maxComparisonUrls, data.analyticsUrlsCount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppColors.primary, size: 18),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    context.l10n('my_analytics_compare_urls'),
                    style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Text(
                  context.l10n('my_analytics_selected_of', args: [selected.length, maxSelectable]),
                  style: const TextStyle(fontSize: 11.0, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: selected
                  .map((option) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(GlyphHelper.getIconData(option.glyph), color: AppColors.primary, size: 13),
                            const SizedBox(width: 5.0),
                            Text(
                              option.shortCode,
                              style: const TextStyle(color: AppColors.primary, fontSize: 12.0, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14.0),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openUrlSelector,
                icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                label: Text(
                  context.l10n('my_analytics_edit_selection'),
                  style: const TextStyle(color: AppColors.primary, fontSize: 13.0, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Visão Geral (KPIs) =====
  Widget _buildOverviewCard(MyAnalyticsDto data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard, color: AppColors.primary, size: 18),
                const SizedBox(width: 8.0),
                Text(
                  context.l10n('my_analytics_overview'),
                  style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            _buildKpiGrid(data),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(MyAnalyticsDto data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _buildMetricsBox(
          context.l10n('clicks_count'),
          '${data.totalClicks}',
          trend: data.totalClicksTrend,
          icon: Icons.ads_click,
        ),
        _buildMetricsBox(
          context.l10n('unique_visitors'),
          '${data.uniqueVisitors}',
          trend: data.uniqueVisitorsTrend,
          icon: Icons.group,
        ),
        _buildMetricsBox(
          context.l10n('my_analytics_urls_compared'),
          '${data.selectedUrlsCount} / ${data.analyticsUrlsCount}',
          icon: Icons.query_stats,
        ),
        _buildMetricsBox(
          context.l10n('my_analytics_best_performer'),
          data.bestPerformerShortCode ?? '—',
          subtitle: data.bestPerformerShortCode != null
              ? context.l10n('clicks_abbr', args: [data.bestPerformerClicks])
              : context.l10n('my_analytics_no_clicks'),
          icon: Icons.emoji_events,
          highlight: true,
        ),
      ],
    );
  }

  Widget _buildMetricsBox(
    String title,
    String value, {
    String? trend,
    String? subtitle,
    required IconData icon,
    bool highlight = false,
  }) {
    final isPositive = trend != null && trend.contains('+');
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: highlight ? AppColors.primary.withValues(alpha: 0.25) : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: highlight ? AppColors.primary : AppColors.textMuted, size: 18),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive ? AppColors.primary.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppColors.primary : Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 19.0,
                  fontWeight: FontWeight.bold,
                  color: highlight ? AppColors.primary : Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2.0),
              Text(
                subtitle ?? title,
                style: const TextStyle(fontSize: 9.0, color: AppColors.textMutedGreenish, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== Gráfico comparativo =====
  Widget _buildComparisonChartCard(MyAnalyticsDto data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n('my_analytics_comparison_chart'),
              style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInner,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    children: [
                      _buildPeriodToggleButton(context.l10n('period_7_days'), 7),
                      _buildPeriodToggleButton(context.l10n('period_30_days'), 30),
                      _buildPeriodToggleButton(context.l10n('period_year'), 365),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // Legenda com as cores de cada NanoUrl
            Wrap(
              spacing: 12.0,
              runSpacing: 6.0,
              children: [
                for (int i = 0; i < data.series.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _seriesPalette[i % _seriesPalette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5.0),
                      Text(
                        data.series[i].shortCode,
                        style: const TextStyle(fontSize: 11.0, color: Colors.white70),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: _isReloading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : CustomPaint(
                      painter: ComparisonChartPainter(
                        series: data.series,
                        labels: data.chartLabels,
                        palette: _seriesPalette,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggleButton(String label, int days) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        if (days != _selectedDays) {
          setState(() => _selectedDays = days);
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.textLight : AppColors.textMutedGreenish,
          ),
        ),
      ),
    );
  }

  // ===== Ranking de Performance =====
  Widget _buildRankingCard(MyAnalyticsDto data) {
    final maxTop = math.min(MyAnalyticsDto.maxComparisonUrls, data.urls.length);
    // Se a seleção diminuiu e o Top escolhido ficou maior que a lista, volta para "Todas"
    final effectiveTop = _topN > maxTop ? 0 : _topN;
    final rows = effectiveTop > 0 ? data.urls.take(effectiveTop).toList() : data.urls;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.leaderboard, color: AppColors.primary, size: 18),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    context.l10n('my_analytics_ranking'),
                    style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                // Seletor de tamanho do ranking (Top 1..20)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInner,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: effectiveTop,
                      dropdownColor: AppColors.surface,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 18),
                      style: const TextStyle(fontSize: 12.0, color: Colors.white, fontFamily: 'SplineSans'),
                      onChanged: (value) {
                        if (value != null) setState(() => _topN = value);
                      },
                      items: [
                        DropdownMenuItem<int>(
                          value: 0,
                          child: Text(context.l10n('my_analytics_all')),
                        ),
                        for (int i = 1; i <= maxTop; i++)
                          DropdownMenuItem<int>(
                            value: i,
                            child: Text('Top $i'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderSubtle, height: 1.0),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (context, idx) => const Divider(color: AppColors.borderSubtle, height: 1.0),
            itemBuilder: (context, index) => _buildRankingRow(rows[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingRow(UrlComparisonItemDto item) {
    final isChampion = item.rank == 1 && item.clicksInPeriod > 0;
    final isPositive = item.trendPositive;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/details', arguments: item.shortCode),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isChampion ? AppColors.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.rank}',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: isChampion ? AppColors.primary : Colors.white60,
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Icon(GlyphHelper.getIconData(item.glyph), color: AppColors.primary, size: 16),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.shortCode,
                        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.topCountry.isNotEmpty)
                        Text(
                          item.topCountry,
                          style: const TextStyle(fontSize: 10.0, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.l10n('clicks_abbr', args: [item.clicksInPeriod]),
                      style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      context.l10n('my_analytics_unique_abbr', args: [item.uniqueVisitors]),
                      style: const TextStyle(fontSize: 10.0, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(width: 10.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive ? AppColors.primary.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.trend,
                    style: TextStyle(
                      color: isPositive ? AppColors.primary : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
              ],
            ),
            const SizedBox(height: 8.0),
            // Barra de participação no total do período
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.sharePercentage / 100.0,
                      backgroundColor: AppColors.surfaceInner,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${item.sharePercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 10.0, color: AppColors.textMuted),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== Top Países / Top Cidades / Origens / Dispositivos =====
  Widget _buildCountriesCard(MyAnalyticsDto data) {
    return _buildSectionCard(
      title: context.l10n('top_countries'),
      child: _isFreePlan
          ? _buildLockedPlaceholder(context)
          : data.locations.isEmpty
          ? _buildEmptySectionText(context.l10n('no_location_data'))
          : Column(
              children: data.locations
                  .map((loc) => _buildProgressIndicator(
                        title: loc.country,
                        suffix: '${loc.percentage}%',
                        percentage: loc.percentage / 100.0,
                        code: loc.flagCode,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildCitiesCard(MyAnalyticsDto data) {
    return _buildSectionCard(
      title: context.l10n('top_cities'),
      child: _isFreePlan
          ? _buildLockedPlaceholder(context)
          : data.topCities.isEmpty
          ? _buildEmptySectionText(context.l10n('no_location_data'))
          : Column(
              children: data.topCities
                  .map((city) => _buildProgressIndicator(
                        title: city.city,
                        suffix: '${city.percentage.toStringAsFixed(1)}%',
                        percentage: city.percentage / 100.0,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildReferrersCard(MyAnalyticsDto data) {
    return _buildSectionCard(
      title: context.l10n('top_referrers'),
      child: _isFreePlan
          ? _buildLockedPlaceholder(context)
          : data.referrers.isEmpty
          ? _buildEmptySectionText(context.l10n('no_referrer_data'))
          : Column(
              children: [
                for (int i = 0; i < data.referrers.length; i++) ...[
                  if (i > 0) const Divider(color: AppColors.borderSubtle, height: 16.0),
                  Row(
                    children: [
                      Icon(
                        data.referrers[i].source.toLowerCase().contains('google')
                            ? Icons.search
                            : (data.referrers[i].source.toLowerCase().contains('direto') ||
                                    data.referrers[i].source.toLowerCase().contains('direct')
                                ? Icons.alternate_email
                                : Icons.public),
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.referrers[i].source,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.0),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        context.l10n('clicks_abbr', args: [data.referrers[i].clicks]),
                        style: const TextStyle(color: Colors.white70, fontSize: 12.0),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildDevicesCard(MyAnalyticsDto data) {
    return _buildSectionCard(
      title: context.l10n('my_analytics_devices'),
      child: _isFreePlan
          ? _buildLockedPlaceholder(context)
          : data.devices.isEmpty
          ? _buildEmptySectionText(context.l10n('my_analytics_no_device_data'))
          : Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: DevicesDonutPainter(
                      values: data.devices.map((d) => d.count).toList(),
                      palette: _devicePalette,
                    ),
                  ),
                ),
                const SizedBox(width: 20.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < data.devices.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _devicePalette[i % _devicePalette.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  _deviceLabel(data.devices[i].device),
                                  style: const TextStyle(fontSize: 12.0, color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${data.devices[i].percentage.toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 12.0, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16.0),
            child,
          ],
        ),
      ),
    );
  }

  // Placeholder de upgrade exibido no lugar das métricas detalhadas (mesmo padrão da AnalyticsScreen)
  Widget _buildLockedPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n('analytics_locked_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n('analytics_locked_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.0,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/plans');
            },
            icon: const Icon(Icons.star, size: 16),
            label: Text(context.l10n('analytics_locked_btn')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textLight,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionText(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white24, fontStyle: FontStyle.italic, fontSize: 13.0),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator({
    required String title,
    required String suffix,
    required double percentage,
    String? code,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        children: [
          Row(
            children: [
              if (code != null) ...[
                Container(
                  width: 24,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    code.toUpperCase(),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
              ),
              Text(suffix, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.surfaceInner,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet para selecionar quais NanoUrls entram na comparação (com busca e limite)
class _UrlSelectorSheet extends StatefulWidget {
  final List<NanoUrlOptionDto> options;
  final int maxSelectable;

  const _UrlSelectorSheet({required this.options, required this.maxSelectable});

  @override
  State<_UrlSelectorSheet> createState() => _UrlSelectorSheetState();
}

class _UrlSelectorSheetState extends State<_UrlSelectorSheet> {
  late final Set<String> _selected;
  String _searchTerm = '';
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.options.where((o) => o.selected).map((o) => o.shortCode).toSet();
  }

  List<NanoUrlOptionDto> get _filteredOptions {
    if (_searchTerm.isEmpty) return widget.options;
    final term = _searchTerm.toLowerCase();
    return widget.options
        .where((o) => o.shortCode.toLowerCase().contains(term) || o.description.toLowerCase().contains(term))
        .toList();
  }

  void _toggle(NanoUrlOptionDto option) {
    setState(() {
      if (_selected.contains(option.shortCode)) {
        _selected.remove(option.shortCode);
        _limitReached = false;
      } else if (_selected.length < widget.maxSelectable) {
        _selected.add(option.shortCode);
        _limitReached = false;
      } else {
        _limitReached = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOptions;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            const SizedBox(height: 12.0),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      context.l10n('my_analytics_compare_urls'),
                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  Text(
                    context.l10n('my_analytics_selected_of', args: [_selected.length, widget.maxSelectable]),
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: _limitReached ? Colors.redAccent : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (_limitReached)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  context.l10n('my_analytics_max_reached', args: [widget.maxSelectable]),
                  style: const TextStyle(fontSize: 11.0, color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 8.0),
              child: TextField(
                onChanged: (val) => setState(() => _searchTerm = val),
                style: const TextStyle(color: Colors.white, fontSize: 14.0),
                decoration: InputDecoration(
                  hintText: context.l10n('my_analytics_search_hint'),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  fillColor: AppColors.surfaceInner,
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n('my_analytics_no_urls_found'),
                        style: const TextStyle(color: Colors.white24, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: filtered.length,
                      separatorBuilder: (context, idx) => const Divider(color: AppColors.borderSubtle, height: 1.0),
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final isSelected = _selected.contains(option.shortCode);
                        return ListTile(
                          onTap: () => _toggle(option),
                          dense: true,
                          leading: Icon(
                            GlyphHelper.getIconData(option.glyph),
                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                            size: 20,
                          ),
                          title: Text(
                            option.shortCode,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          subtitle: Text(
                            option.description.isNotEmpty
                                ? option.description
                                : context.l10n('clicks_abbr', args: [option.totalClicks]),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11.0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isSelected ? AppColors.primary : Colors.white24,
                            size: 20,
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop('most_clicked'),
                      child: Text(
                        context.l10n('my_analytics_most_clicked'),
                        style: const TextStyle(color: AppColors.textMutedGreenish, fontSize: 12.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_selected.toList()),
                      icon: const Icon(Icons.query_stats, size: 16),
                      label: Text(
                        context.l10n('my_analytics_apply', args: [_selected.length]),
                        style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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
  }
}

// Custom Painter que desenha o gráfico comparativo multi-linha (uma curva por NanoUrl)
class ComparisonChartPainter extends CustomPainter {
  final List<ComparisonSeriesDto> series;
  final List<String> labels;
  final List<Color> palette;

  ComparisonChartPainter({
    required this.series,
    required this.labels,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty || labels.length < 2) return;

    final paintGrid = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const double paddingLeft = 25.0;
    const double paddingRight = 10.0;
    const double paddingTop = 10.0;
    const double paddingBottom = 20.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Valor máximo entre todas as séries para normalizar o eixo Y
    int maxValue = 0;
    for (final serie in series) {
      for (final value in serie.values) {
        if (value > maxValue) maxValue = value;
      }
    }
    if (maxValue == 0) maxValue = 10;

    // Linhas horizontais de grade + labels do eixo Y
    for (int i = 0; i <= 3; i++) {
      final y = paddingTop + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        paintGrid,
      );

      final gridVal = ((maxValue / 3) * (3 - i)).round();
      textPainter.text = TextSpan(
        text: '$gridVal',
        style: const TextStyle(color: Colors.white24, fontSize: 9.0),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    final double stepX = chartWidth / (labels.length - 1);

    // Colunas de grade + labels do eixo X (com downsampling para períodos longos)
    final int labelCount = labels.length;
    final int skipStep = (labelCount / 7).ceil();

    for (int i = 0; i < labelCount; i++) {
      final x = paddingLeft + stepX * i;
      if (i % skipStep == 0 || i == labelCount - 1) {
        canvas.drawLine(
          Offset(x, paddingTop),
          Offset(x, paddingTop + chartHeight),
          paintGrid,
        );

        textPainter.text = TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.white30, fontSize: 9.0, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - (textPainter.width / 2), size.height - 12));
      }
    }

    final bool singleSeries = series.length == 1;

    for (int s = 0; s < series.length; s++) {
      final values = series[s].values;
      if (values.length < 2) continue;

      final color = palette[s % palette.length];
      final paintLine = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final List<Offset> points = [];
      final int count = math.min(values.length, labels.length);
      for (int i = 0; i < count; i++) {
        final x = paddingLeft + stepX * i;
        final y = paddingTop + chartHeight - (values[i] / maxValue) * chartHeight;
        points.add(Offset(x, y));
      }

      // Curva Bezier com tensão (mesmo estilo do gráfico individual)
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
        final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p2.dx, p2.dy,
        );
      }

      // Área preenchida apenas quando há uma única série (evita poluição visual)
      if (singleSeries) {
        final fillPath = Path.from(path);
        fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
        fillPath.lineTo(points.first.dx, paddingTop + chartHeight);
        fillPath.close();

        final paintFill = Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));
        canvas.drawPath(fillPath, paintFill);
      }

      canvas.drawPath(path, paintLine);

      // Pontos apenas em datasets curtos para não poluir a visão anual
      if (points.length <= 31) {
        final paintCircle = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        final paintCircleBorder = Paint()
          ..color = AppColors.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        for (var pt in points) {
          canvas.drawCircle(pt, 3.0, paintCircle);
          canvas.drawCircle(pt, 3.0, paintCircleBorder);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ComparisonChartPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.labels != labels;
  }
}

// Custom Painter que desenha o donut de distribuição por dispositivo
class DevicesDonutPainter extends CustomPainter {
  final List<int> values;
  final List<Color> palette;

  DevicesDonutPainter({required this.values, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return;

    const double strokeWidth = 18.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Pequeno espaçamento entre as fatias, como no donut do WebApp
    const double gapAngle = 0.06;
    double startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweepAngle = (values[i] / total) * (2 * math.pi) - gapAngle;
      final paint = Paint()
        ..color = palette[i % palette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, math.max(sweepAngle, 0.02), false, paint);
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DevicesDonutPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
