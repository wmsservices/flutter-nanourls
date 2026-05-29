import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dtos/dashboard_data_dto.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// Screen displaying stats and details of a selected shortened URL
class LinkDetailsScreen extends StatefulWidget {
  final String shortCode;

  const LinkDetailsScreen({
    super.key,
    required this.shortCode,
  });

  @override
  State<LinkDetailsScreen> createState() => _LinkDetailsScreenState();
}

class _LinkDetailsScreenState extends State<LinkDetailsScreen> {
  final ApiService _apiService = ApiService();
  DashboardDataDto? _analyticsData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _useHourlyChart = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _apiService.fetchUrlAnalytics(widget.shortCode, days: 7);
      setState(() {
        _analyticsData = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('HttpException: ', '').replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Copy helper
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copiado para a área de transferência!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    });
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
          title: const Text('Estatísticas do Link'),
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
                  _errorMessage ?? 'Erro ao carregar estatísticas.',
                  style: const TextStyle(color: Colors.white70, fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _loadAnalytics,
                  child: const Text('Tentar Novamente'),
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
        title: const Text('Estatísticas do Link'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Header / Shortcode details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Código Curto',
                        style: TextStyle(fontSize: 12.0, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        _data.shortCode,
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          shadows: [Shadow(color: AppColors.shadowGlow, blurRadius: 10)],
                        ),
                      ),
                    ],
                  ),
                ),
                // Created Date Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    _data.createdDate.toString().substring(0, 10),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Row 2: Metadata card (Description & Target Link)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('URL Original', style: TextStyle(color: AppColors.textMuted, fontSize: 12.0, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4.0),
                    InkWell(
                      onTap: () => _copyToClipboard(_data.targetUrl),
                      child: Text(
                        _data.targetUrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14.0, decoration: TextDecoration.underline),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Text('Link Encurtado Principal', style: TextStyle(color: AppColors.textMuted, fontSize: 12.0, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _data.shortGoUrl,
                            style: const TextStyle(color: AppColors.primary, fontSize: 15.0, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                          onPressed: () => _copyToClipboard(_data.shortGoUrl),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    if (_data.description.isNotEmpty) ...[
                      const Divider(color: AppColors.borderSubtle, height: 24.0),
                      const Text('Descrição', style: TextStyle(color: AppColors.textMuted, fontSize: 12.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4.0),
                      Text(
                        _data.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 13.0),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Row 3: Grid containing key metrics blocks
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                _buildMetricsBox('Cliques Totais', '${_data.totalClicks}', _data.totalClicksTrend, Icons.ads_click),
                _buildMetricsBox('Últimas 24h', '${_data.clicksToday}', _data.clicksTodayTrend, Icons.schedule),
                _buildMetricsBox('Visitantes Únicos', '${_data.uniqueVisitors}', _data.uniqueVisitorsTrend, Icons.group),
              ],
            ),
            const SizedBox(height: 20.0),

            // Row 4: Line Chart area
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cliques ao Longo do Tempo',
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        // Daily/Hourly Selector
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceInner,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(2.0),
                          child: Row(
                            children: [
                              _buildChartToggleButton('Diário', !_useHourlyChart),
                              _buildChartToggleButton('Horário', _useHourlyChart),
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
                      child: CustomPaint(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Origem do Tráfego',
                      style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 1.0),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _data.referrers.isEmpty ? 1 : _data.referrers.length,
                    separatorBuilder: (context, idx) => const Divider(color: AppColors.borderSubtle, height: 1.0),
                    itemBuilder: (context, index) {
                      if (_data.referrers.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text('Sem dados de origem disponíveis.', style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),
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
                            Text('${refItem.clicks} cliq.', style: const TextStyle(color: Colors.white70)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPositive ? AppColors.primary.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
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
            const SizedBox(height: 20.0),

            // Row 6: Top Countries progress indicators
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Principais Países',
                      style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16.0),
                    if (_data.locations.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('Sem dados geográficos.', style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),
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
            const SizedBox(height: 20.0),

            // Row 7: Top Cities progress indicators
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Principais Cidades',
                      style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16.0),
                    if (_data.topCities.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('Sem dados de cidades.', style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),
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
                  color: isPositive ? AppColors.primary.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
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

  // Segmented toggle button helper
  Widget _buildChartToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _useHourlyChart = label == 'Horário';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
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
                    color: Colors.white.withOpacity(0.08),
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
      ..color = Colors.white.withOpacity(0.03)
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

    // Draw grid columns & X-Axis labels
    for (int i = 0; i < labels.length; i++) {
      final x = paddingLeft + stepX * i;
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
        AppColors.primary.withOpacity(0.35),
        AppColors.primary.withOpacity(0.0),
      ],
    ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));
    
    paintFill.shader = gradientShader;
    canvas.drawPath(fillPath, paintFill);

    // Draw the neon border line
    canvas.drawPath(path, paintLine);

    // Draw node dots
    final paintCircle = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final paintCircleBorder = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var pt in points) {
      canvas.drawCircle(pt, 5.0, paintCircle);
      canvas.drawCircle(pt, 5.0, paintCircleBorder);
    }
  }

  @override
  bool shouldRepaint(covariant ClicksChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}
