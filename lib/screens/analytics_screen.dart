import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dtos/dashboard_data_dto.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';

// Screen displaying stats and details of a selected shortened URL
class AnalyticsScreen extends StatefulWidget {
  final String shortCode;
  final DashboardDataDto? preloadedData;

  const AnalyticsScreen({
    super.key,
    required this.shortCode,
    this.preloadedData,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService _apiService = ApiService();
  DashboardDataDto? _analyticsData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _useHourlyChart = false;
  int _selectedDays = 7;
  bool _isCardExpanded = false;
  bool _isFirstLoad = true;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedData != null) {
      _analyticsData = widget.preloadedData;
      _isLoading = false;
      _isFirstLoad = false;
    } else {
      _loadAnalytics();
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      if (_analyticsData == null || _isFirstLoad) {
        _isLoading = true;
      } else {
        _isReloading = true;
      }
      _errorMessage = null;
    });

    try {
      final stats = await _apiService.fetchUrlAnalytics(widget.shortCode, days: _selectedDays);
      setState(() {
        _analyticsData = stats;
        _isLoading = false;
        _isReloading = false;
        _isFirstLoad = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
        _isLoading = false;
        _isReloading = false;
      });
    }
  }

  // Copy helper
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n('copy_success_snackbar')),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  Widget _buildCardCompactChild(DashboardDataDto data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n('short_code'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4.0),
              Text(
                data.shortCode,
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  shadows: [Shadow(color: AppColors.shadowGlow, blurRadius: 8)],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            context.l10n('status_active'),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        AnimatedRotation(
          turns: _isCardExpanded ? 0.5 : 0.0,
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

  Widget _buildCardFullChild(DashboardDataDto data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n('short_code'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.0, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4.0),
                  Text(
                    data.shortCode,
                    style: const TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      shadows: [Shadow(color: AppColors.shadowGlow, blurRadius: 8)],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

            ),
            const SizedBox(width: 8.0),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                context.l10n('status_active'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            AnimatedRotation(
              turns: _isCardExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white30,
                size: 20.0,
              ),
            ),
          ],
        ),
        const Divider(color: AppColors.borderSubtle, height: 24.0),

        // URL Original
        Text(context.l10n('original_url'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.0, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4.0),
        InkWell(
          onTap: () => _copyToClipboard(data.targetUrl),
          child: Text(
            data.targetUrl,
            style: const TextStyle(color: Colors.white, fontSize: 14.0, decoration: TextDecoration.underline),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 16.0),

        // Link Encurtado Principal (GO)
        Text(context.l10n('main_shortlink'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.0, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                data.shortGoUrl,
                style: const TextStyle(color: AppColors.primary, fontSize: 15.0, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
              onPressed: () => _copyToClipboard(data.shortGoUrl),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Link Encurtado Alternativo (ME)
        if (data.shortMeUrl.isNotEmpty) ...[
          Text(context.l10n('alt_shortlink'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.shortMeUrl,
                  style: const TextStyle(color: AppColors.primary, fontSize: 15.0, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                onPressed: () => _copyToClipboard(data.shortMeUrl),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
        ],

        // Description
        if (data.description.isNotEmpty) ...[
          Text(context.l10n('description'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4.0),
          Text(
            data.description,
            style: const TextStyle(color: Colors.white70, fontSize: 13.0),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
          const SizedBox(height: 16.0),
        ],

        const Divider(color: AppColors.borderSubtle, height: 16.0),

        // Created at / Last modified dates row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n('created_at'), style: const TextStyle(color: AppColors.textMuted, fontSize: 11.0, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2.0),
                Text(
                  _formatDate(data.createdDate),
                  style: const TextStyle(color: Colors.white70, fontSize: 12.0),
                ),
              ],
            ),
            if (!_isSameDay(data.createdDate, data.lastModifiedDate))
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(context.l10n('modified_at'), style: const TextStyle(color: AppColors.textMuted, fontSize: 11.0, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2.0),
                  Text(
                    _formatDate(data.lastModifiedDate),
                    style: const TextStyle(color: Colors.white70, fontSize: 12.0),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_errorMessage != null || _analyticsData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(context.l10n('analytics_screen_title')),
        ),
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
                  onPressed: _loadAnalytics,
                  child: Text(context.l10n('try_again')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ignore: no_leading_underscores_for_local_identifiers
    final _data = _analyticsData!;
    final chartLabels = _useHourlyChart ? _data.hourlyChartLabels : _data.chartLabels;
    final chartValues = _useHourlyChart ? _data.hourlyChartValues : _data.chartValues;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n('analytics_screen_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1 & 2: Metadata card (Description, Target Link, shortcode, GO/ME links, creation/modified dates)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isCardExpanded = !_isCardExpanded;
                });
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    firstCurve: Curves.easeInOut,
                    secondCurve: Curves.easeInOut,
                    sizeCurve: Curves.easeInOut,
                    crossFadeState: _isCardExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: _buildCardCompactChild(_data),
                    secondChild: _buildCardFullChild(_data),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Row 3: Grid containing key metrics blocks
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _isReloading ? 0.5 : 1.0,
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
                children: [
                  _buildMetricsBox(context.l10n('clicks_count'), '${_data.totalClicks}', _data.totalClicksTrend, Icons.ads_click),
                  _buildMetricsBox(context.l10n('last_24h'), '${_data.clicksToday}', _data.clicksTodayTrend, Icons.schedule),
                  _buildMetricsBox(context.l10n('unique_visitors'), '${_data.uniqueVisitors}', _data.uniqueVisitorsTrend, Icons.group),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // Row 4: Line Chart area (with title, Daily/Hourly below, and Period toggles)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n('clicks_over_time'),
                      style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8.0),
                    // Daily/Hourly Selector
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
                              _buildChartToggleButton(context.l10n('daily_toggle'), !_useHourlyChart),
                              _buildChartToggleButton(context.l10n('hourly_toggle'), _useHourlyChart),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    // Period Selector Label
                    Text(
                      context.l10n('periods_label'),
                      style: const TextStyle(fontSize: 12.0, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6.0),
                    // Period Toggles: 7 Dias / 30 Dias / Ano
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
                              _buildPeriodToggleButton(context.l10n('period_7_days'), _selectedDays == 7),
                              _buildPeriodToggleButton(context.l10n('period_30_days'), _selectedDays == 30),
                              _buildPeriodToggleButton(context.l10n('period_year'), _selectedDays == 365),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    // Line chart painter box
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: _isReloading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : CustomPaint(
                              painter: ClicksChartPainter(
                                values: chartValues,
                                labels: chartLabels,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Row 5: Traffic Source Table
            Card(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _isReloading ? 0.5 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        context.l10n('top_referrers'),
                        style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1.0),
                    if (SessionManager().currentUser?.planId == 1)
                      _buildLockedPlaceholder(context)
                    else
                      ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _data.referrers.isEmpty ? 1 : _data.referrers.length,
                      separatorBuilder: (context, idx) => const Divider(color: AppColors.borderSubtle, height: 1.0),
                      itemBuilder: (context, index) {
                        if (_data.referrers.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(context.l10n('no_referrer_data'), style: const TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),
                            ),
                          );
                        }
                        final refItem = _data.referrers[index];
                        final isPositive = refItem.trendPositive;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Icon(
                                refItem.source.toLowerCase() == 'direto'
                                    ? Icons.link
                                    : (refItem.source.toLowerCase() == 'google search'
                                        ? Icons.search
                                        : Icons.share),
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(refItem.source, style: const TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              Text(context.l10n('clicks_abbr', args: [refItem.clicks]), style: const TextStyle(color: Colors.white70)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPositive ? AppColors.primary.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  refItem.trend,
                                  style: TextStyle(
                                    color: isPositive ? AppColors.primary : Colors.redAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Row 6: Top Countries progress indicators
            Card(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _isReloading ? 0.5 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n('top_countries'),
                        style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16.0),
                      if (SessionManager().currentUser?.planId == 1)
                        _buildLockedPlaceholder(context)
                      else if (_data.locations.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(context.l10n('no_location_data'), style: const TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),
                          ),
                        )
                      else
                        ..._data.locations.map((loc) => _buildProgressIndicator(
                              title: loc.country,
                              suffix: '${loc.percentage}%',
                              percentage: loc.percentage / 100.0,
                              code: loc.flagCode,
                            )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Row 7: Top Cities progress indicators
            Card(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _isReloading ? 0.5 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n('top_cities'),
                        style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16.0),
                      if (SessionManager().currentUser?.planId == 1)
                        _buildLockedPlaceholder(context)
                      else if (_data.topCities.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(context.l10n('no_location_data'), style: const TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),
                          ),
                        )
                      else
                        ..._data.topCities.map((city) => _buildProgressIndicator(
                              title: city.city,
                              suffix: '${city.percentage.toStringAsFixed(1)}%',
                              percentage: city.percentage / 100.0,
                            )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  // Build the metrics boxes
  Widget _buildMetricsBox(String title, String value, String trend, IconData icon) {
    final isPositive = trend.contains('+');
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppColors.textMuted, size: 18),
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
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 2.0),
              Text(
                title,
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

  // Segmented toggle button helper for Daily/Hourly
  Widget _buildChartToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _useHourlyChart = label == context.l10n('hourly_toggle');
        });
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

  // Segmented toggle button helper for Period selection (7 Days, 30 Days, Year)
  Widget _buildPeriodToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        int days = 7;
        if (label == context.l10n('period_30_days')) days = 30;
        if (label == context.l10n('period_year')) days = 365;
        if (days != _selectedDays) {
          setState(() {
            _selectedDays = days;
          });
          _loadAnalytics();
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

  // Date formatting helpers
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month, context)}. ${date.year}";
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _getMonthName(int month, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    const months = {
      'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      'pt': ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
      'es': ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'],
      'fr': ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'],
    };
    final list = months[locale] ?? months['en']!;
    if (month >= 1 && month <= 12) {
      return list[month - 1];
    }
    return '';
  }

  // Country/City progress visualizer
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
                    code,
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
}

// Custom Painter to draw a sleek, curved line graph for click trends
class ClicksChartPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;

  ClicksChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paintLine = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Padding parameters
    const double paddingLeft = 25.0;
    const double paddingRight = 10.0;
    const double paddingTop = 10.0;
    const double paddingBottom = 20.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Find min and max
    int maxValue = values.reduce((curr, next) => curr > next ? curr : next);
    if (maxValue == 0) maxValue = 10; // Avoid divide by zero

    // Draw horizontal grid lines (3 rows)
    for (int i = 0; i <= 3; i++) {
      final y = paddingTop + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        paintGrid,
      );

      // Draw value text labels on the Y-Axis
      final gridVal = ((maxValue / 3) * (3 - i)).round();
      textPainter.text = TextSpan(
        text: '$gridVal',
        style: const TextStyle(color: Colors.white24, fontSize: 9.0),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    final double stepX = chartWidth / (values.length - 1);
    final List<Offset> points = [];

    // Calculate chart node coordinates
    for (int i = 0; i < values.length; i++) {
      final x = paddingLeft + stepX * i;
      final y = paddingTop + chartHeight - (values[i] / maxValue) * chartHeight;
      points.add(Offset(x, y));
    }

    // Draw grid columns & X-Axis labels (downsampled step intervals for dense datasets)
    final int labelCount = labels.length;
    final int skipStep = (labelCount / 7).ceil();

    for (int i = 0; i < labelCount; i++) {
      final x = paddingLeft + stepX * i;
      
      if (i % skipStep == 0 || i == labelCount - 1) {
        // Draw grid vertical lines
        canvas.drawLine(
          Offset(x, paddingTop),
          Offset(x, paddingTop + chartHeight),
          paintGrid,
        );

        // Draw X-Axis label
        textPainter.text = TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.white30, fontSize: 9.0, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - (textPainter.width / 2), size.height - 12));
      }
    }

    // Generate Path curve (tension Bezier curve)
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

    // Draw the gradient filled region below the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
    fillPath.lineTo(points.first.dx, paddingTop + chartHeight);
    fillPath.close();

    final gradientShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary.withValues(alpha: 0.35),
        AppColors.primary.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));
    
    paintFill.shader = gradientShader;
    canvas.drawPath(fillPath, paintFill);

    // Draw the neon border line
    canvas.drawPath(path, paintLine);

    // Draw node dots (only for small datasets <= 31 points to avoid clutter in Year view)
    if (points.length <= 31) {
      final paintCircle = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;
      final paintCircleBorder = Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (var pt in points) {
        canvas.drawCircle(pt, 4.0, paintCircle);
        canvas.drawCircle(pt, 4.0, paintCircleBorder);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ClicksChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}
