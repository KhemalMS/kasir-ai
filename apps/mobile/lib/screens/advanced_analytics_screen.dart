import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() => _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen> {
  int _selectedTabIndex = 0;

  final List<String> _tabTitles = [
    'Perbandingan Periode',
    'Proyeksi Penjualan',
    'Analisis Keranjang',
    'Pertumbuhan Produk',
    'Tren Musiman',
  ];

  final List<IconData> _tabIcons = [
    Icons.compare_arrows,
    Icons.trending_up,
    Icons.shopping_basket,
    Icons.show_chart,
    Icons.calendar_month,
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    Widget content = _buildTabContent(_selectedTabIndex);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: AppTheme.cardDark,
              border: Border(right: BorderSide(color: AppTheme.surfaceDark, width: 2)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _tabTitles.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTabIndex == index;
                return ListTile(
                  leading: Icon(_tabIcons[index], color: isSelected ? AppTheme.primary : AppTheme.textMuted),
                  title: Text(
                    _tabTitles[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
                  onTap: () => setState(() => _selectedTabIndex = index),
                );
              },
            ),
          ),
          Expanded(child: content),
        ],
      );
    } else {
      return Column(
        children: [
          Container(
            color: AppTheme.cardDark,
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabTitles.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTabIndex == index;
                return InkWell(
                  onTap: () => setState(() => _selectedTabIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? AppTheme.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_tabIcons[index], size: 18, color: isSelected ? AppTheme.primary : AppTheme.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          _tabTitles[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(child: content),
        ],
      );
    }
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0: return const PeriodComparisonTab();
      case 1: return const SalesForecastTab();
      case 2: return const MarketBasketTab();
      case 3: return const ProductGrowthTab();
      case 4: return const SeasonalityTab();
      default: return const Center(child: Text('Tab tidak ditemukan', style: TextStyle(color: Colors.white)));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: PERBANDINGAN PERIODE
// ─────────────────────────────────────────────────────────────────────────────
class PeriodComparisonTab extends StatefulWidget {
  const PeriodComparisonTab({super.key});
  @override State<PeriodComparisonTab> createState() => _PeriodComparisonTabState();
}

class _PeriodComparisonTabState extends State<PeriodComparisonTab> {
  DateTimeRange? _period1;
  DateTimeRange? _period2;
  bool _isLoading = false;
  Map<String, dynamic>? _data;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  Future<void> _fetchData() async {
    if (_period1 == null || _period2 == null) return;
    setState(() => _isLoading = true);
    try {
      final s1 = DateFormat('yyyy-MM-dd').format(_period1!.start);
      final e1 = DateFormat('yyyy-MM-dd').format(_period1!.end);
      final s2 = DateFormat('yyyy-MM-dd').format(_period2!.start);
      final e2 = DateFormat('yyyy-MM-dd').format(_period2!.end);
      
      final branchId = context.read<AuthProvider>().branchId;
      String url = '/reports/period-comparison?start1=$s1&end1=$e1&start2=$s2&end2=$e2';
      if (branchId != null) url += '&branchId=$branchId';

      final res = await _AnalyticsCache.fetch(    url,    () => ApiService.get(url),    ttl: url.contains('market-basket') ? const Duration(hours: 1) : const Duration(minutes: 5),  );
      if (res['success'] == true) {
        setState(() => _data = res['data']);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectPeriod(int period) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary, surface: AppTheme.cardDark),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (period == 1) _period1 = picked;
        else _period2 = picked;
      });
      if (_period1 != null && _period2 != null) _fetchData();
    }
  }

  Widget _buildMetricCard(String title, double p1Val, double p2Val, double growthPct, bool isCurrency) {
    final formatVal = (double v) => isCurrency ? _currencyFormat.format(v) : v.toStringAsFixed(0);
    final isPositive = growthPct >= 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Periode 1', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  Text(formatVal(p1Val), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Periode 2', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  Text(formatVal(p2Val), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, 
                   size: 16, color: isPositive ? AppTheme.success : AppTheme.danger),
              const SizedBox(width: 4),
              Text('${growthPct.abs().toStringAsFixed(1)}%', 
                   style: TextStyle(color: isPositive ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('vs Periode 1', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Perbandingan Periode', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(_period1 == null ? 'Pilih Periode 1' : '${DateFormat('dd MMM yyyy').format(_period1!.start)} - ${DateFormat('dd MMM yyyy').format(_period1!.end)}'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark, foregroundColor: Colors.white),
                onPressed: () => _selectPeriod(1),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(_period2 == null ? 'Pilih Periode 2' : '${DateFormat('dd MMM yyyy').format(_period2!.start)} - ${DateFormat('dd MMM yyyy').format(_period2!.end)}'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark, foregroundColor: Colors.white),
                onPressed: () => _selectPeriod(2),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading) const Center(child: CircularProgressIndicator())
          else if (_data != null) Expanded(
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 600;
                  final growth = _data!['growth'];
                  final cards = [
                    _buildMetricCard('Pendapatan (Revenue)', 
                      (growth['revenue']['period1'] as num).toDouble(), 
                      (growth['revenue']['period2'] as num).toDouble(), 
                      (growth['revenue']['percentage'] as num).toDouble(), true),
                    _buildMetricCard('Estimasi Laba', 
                      (growth['estimatedProfit']['period1'] as num).toDouble(), 
                      (growth['estimatedProfit']['period2'] as num).toDouble(), 
                      (growth['estimatedProfit']['percentage'] as num).toDouble(), true),
                    _buildMetricCard('Jumlah Transaksi', 
                      (growth['transactions']['period1'] as num).toDouble(), 
                      (growth['transactions']['period2'] as num).toDouble(), 
                      (growth['transactions']['percentage'] as num).toDouble(), false),
                  ];
                  
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: c))).toList(),
                    );
                  } else {
                    return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList());
                  }
                }
              ),
            ),
          ) else const Expanded(child: Center(child: Text('Pilih kedua periode untuk melihat perbandingan.', style: TextStyle(color: AppTheme.textMuted)))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: PROYEKSI PENJUALAN
// ─────────────────────────────────────────────────────────────────────────────
class SalesForecastTab extends StatefulWidget {
  const SalesForecastTab({super.key});
  @override State<SalesForecastTab> createState() => _SalesForecastTabState();
}
class _SalesForecastTabState extends State<SalesForecastTab> {
  bool _isLoading = true;
  List<dynamic> _historical = [];
  List<dynamic> _forecast = [];
  final NumberFormat _currencyFormat = NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final branchId = context.read<AuthProvider>().branchId;
      String url = '/reports/sales-forecast?historicalDays=14&forecastDays=7';
      if (branchId != null) url += '&branchId=$branchId';

      final res = await _AnalyticsCache.fetch(    url,    () => ApiService.get(url),    ttl: url.contains('market-basket') ? const Duration(hours: 1) : const Duration(minutes: 5),  );
      if (res['success'] == true) {
        setState(() {
          _historical = res['data']['historical'] ?? [];
          _forecast = res['data']['forecast'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_historical.isEmpty && _forecast.isEmpty) return const Center(child: Text('Data tidak tersedia', style: TextStyle(color: Colors.white)));

    // Combine data for plotting
    List<FlSpot> histSpots = [];
    List<FlSpot> foreSpots = [];
    double maxY = 0;
    
    int index = 0;
    for (var item in _historical) {
      final rev = (item['revenue'] as num).toDouble();
      histSpots.add(FlSpot(index.toDouble(), rev));
      if (rev > maxY) maxY = rev;
      index++;
    }
    
    // To make line continuous, add last historical point to forecast
    if (_historical.isNotEmpty && _forecast.isNotEmpty) {
      final rev = (_historical.last['revenue'] as num).toDouble();
      foreSpots.add(FlSpot((index - 1).toDouble(), rev));
    }
    
    for (var item in _forecast) {
      final rev = (item['revenue'] as num).toDouble();
      foreSpots.add(FlSpot(index.toDouble(), rev));
      if (rev > maxY) maxY = rev;
      index++;
    }
    
    maxY = maxY * 1.2; // Add 20% headroom

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Proyeksi Penjualan 7 Hari Kedepan', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text('ESTIMASI WMA', style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Grafik garis putus-putus menunjukkan proyeksi/estimasi pendapatan berdasarkan performa masa lalu dan tren mingguan.', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceDark)),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide x-axis labels to save space
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) => Text(_currencyFormat.format(value), style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0, maxX: (histSpots.length + _forecast.length - 1).toDouble(),
                  minY: 0, maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: histSpots,
                      isCurved: true,
                      color: AppTheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: foreSpots,
                      isCurved: true,
                      color: AppTheme.warning,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dashArray: [5, 5], // Dashed line for forecast
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: ANALISIS KERANJANG (MARKET BASKET)
// ─────────────────────────────────────────────────────────────────────────────
class MarketBasketTab extends StatefulWidget {
  const MarketBasketTab({super.key});
  @override State<MarketBasketTab> createState() => _MarketBasketTabState();
}
class _MarketBasketTabState extends State<MarketBasketTab> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final branchId = context.read<AuthProvider>().branchId;
      String url = '/reports/market-basket?limit=20';
      if (branchId != null) url += '&branchId=$branchId';

      final res = await _AnalyticsCache.fetch(    url,    () => ApiService.get(url),    ttl: url.contains('market-basket') ? const Duration(hours: 1) : const Duration(minutes: 5),  );
      if (res['success'] == true) {
        setState(() {
          _data = res['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analisis Keranjang Belanja (Market Basket)', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Produk yang sering dibeli bersamaan dalam satu transaksi. Berguna untuk strategi bundling penawaran.', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 24),
          Expanded(
            child: _data.isEmpty 
              ? const Center(child: Text('Data tidak cukup. Butuh lebih banyak transaksi.', style: TextStyle(color: AppTheme.textMuted)))
              : Container(
                  decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceDark)),
                  child: ListView.separated(
                    itemCount: _data.length,
                    separatorBuilder: (context, index) => const Divider(color: AppTheme.surfaceDark, height: 1),
                    itemBuilder: (context, index) {
                      final item = _data[index];
                      final lift = (item['lift'] as num).toDouble();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.link, color: AppTheme.primary),
                        ),
                        title: Text('${item['productAName']} & ${item['productBName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text('Dibeli bersama ${item['frequency']} kali', style: TextStyle(color: AppTheme.textMuted)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Lift: ${lift.toStringAsFixed(2)}x', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Conf: ${((item['confidence'] as num)*100).toStringAsFixed(0)}%', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4: PERTUMBUHAN PRODUK (CHURN)
// ─────────────────────────────────────────────────────────────────────────────
class ProductGrowthTab extends StatefulWidget {
  const ProductGrowthTab({super.key});
  @override State<ProductGrowthTab> createState() => _ProductGrowthTabState();
}
class _ProductGrowthTabState extends State<ProductGrowthTab> {
  bool _isLoading = true;
  List<dynamic> _trendingUp = [];
  List<dynamic> _trendingDown = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final now = DateTime.now();
      final currentEnd = DateFormat('yyyy-MM-dd').format(now);
      final currentStart = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 30)));
      final previousEnd = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 31)));
      final previousStart = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 61)));

      final branchId = context.read<AuthProvider>().branchId;
      String url = '/reports/product-growth?currentStart=$currentStart&currentEnd=$currentEnd&previousStart=$previousStart&previousEnd=$previousEnd';
      if (branchId != null) url += '&branchId=$branchId';

      final res = await _AnalyticsCache.fetch(    url,    () => ApiService.get(url),    ttl: url.contains('market-basket') ? const Duration(hours: 1) : const Duration(minutes: 5),  );
      if (res['success'] == true) {
        setState(() {
          _trendingUp = res['data']['trending_up'] ?? [];
          _trendingDown = res['data']['trending_down'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildList(String title, List<dynamic> items, bool isUp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(isUp ? Icons.trending_up : Icons.trending_down, color: isUp ? AppTheme.success : AppTheme.danger),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: items.isEmpty 
            ? const Center(child: Text('Tidak ada data', style: TextStyle(color: AppTheme.textMuted)))
            : Container(
                decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceDark)),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(color: AppTheme.surfaceDark, height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final growth = (item['growth'] as num).toDouble();
                    return ListTile(
                      title: Text(item['productName'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text('Lalu: ${item['previousQty']} | Kini: ${item['currentQty']}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isUp ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${growth > 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                          style: TextStyle(color: isUp ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pertumbuhan & Churn Produk', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Perbandingan 30 Hari Terakhir vs 30 Hari Sebelumnya', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 24),
          Expanded(
            child: isDesktop 
              ? Row(
                  children: [
                    Expanded(child: _buildList('Paling Berkembang (Trending Up)', _trendingUp, true)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildList('Berisiko Churn (Trending Down)', _trendingDown, false)),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _buildList('Paling Berkembang', _trendingUp, true)),
                    const SizedBox(height: 24),
                    Expanded(child: _buildList('Berisiko Churn', _trendingDown, false)),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 5: TREN MUSIMAN
// ─────────────────────────────────────────────────────────────────────────────
class SeasonalityTab extends StatefulWidget {
  const SeasonalityTab({super.key});
  @override State<SeasonalityTab> createState() => _SeasonalityTabState();
}
class _SeasonalityTabState extends State<SeasonalityTab> {
  bool _isLoading = true;
  List<dynamic> _data = [];
  String _groupBy = 'day_of_week';
  final NumberFormat _currencyFormat = NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final branchId = context.read<AuthProvider>().branchId;
      String url = '/reports/seasonality?groupBy=$_groupBy';
      if (branchId != null) url += '&branchId=$branchId';

      final res = await _AnalyticsCache.fetch(    url,    () => ApiService.get(url),    ttl: url.contains('market-basket') ? const Duration(hours: 1) : const Duration(minutes: 5),  );
      if (res['success'] == true) {
        setState(() {
          _data = res['data']['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tren Musiman', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _groupBy,
                dropdownColor: AppTheme.cardDark,
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'day_of_week', child: Text('Hari dalam Seminggu')),
                  DropdownMenuItem(value: 'month', child: Text('Bulan dalam Setahun')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _groupBy = val);
                    _fetchData();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Rata-rata pendapatan berdasarkan ${_groupBy == 'day_of_week' ? 'hari' : 'bulan'}.', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 24),
          if (_isLoading) const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_data.isEmpty) const Expanded(child: Center(child: Text('Data tidak tersedia', style: TextStyle(color: Colors.white))))
          else Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceDark)),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _data.map((e) => (e['avgRevenue'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          _currencyFormat.format(rod.toY),
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, _) {
                          final int idx = value.toInt();
                          if (idx >= 0 && idx < _data.length) {
                            String label = _data[idx]['label'];
                            if (_groupBy == 'day_of_week') label = label.substring(0, 3);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, _) => Text(_currencyFormat.format(value), style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _data.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: (e.value['avgRevenue'] as num).toDouble(),
                          color: AppTheme.primary,
                          width: _groupBy == 'month' ? 16 : 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple in-memory cache
class _AnalyticsCache {
  static final Map<String, _CacheEntry> _cache = {};
  
  static Future<T> fetch<T>(String key, Future<T> Function() fetcher, {Duration ttl = const Duration(minutes: 5)}) async {
    final entry = _cache[key];
    if (entry != null && DateTime.now().difference(entry.timestamp) < ttl) {
      return entry.data as T;
    }
    final data = await fetcher();
    _cache[key] = _CacheEntry(data, DateTime.now());
    return data;
  }
  
  static void invalidate(String key) => _cache.remove(key);
  static void clear() => _cache.clear();
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  _CacheEntry(this.data, this.timestamp);
}
