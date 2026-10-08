import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../widgets/dashboard_helpers.dart';


class DashboardTab extends StatefulWidget {
  final NumberFormat? formatter;
  const DashboardTab({super.key, this.formatter});
  @override State<DashboardTab> createState() => DashboardTabState();
}

class DashboardTabState extends State<DashboardTab> {
  String _n(num value) => NumberFormat.compact(locale: 'id').format(value);
  Map<String, dynamic>? _daily;
  List<dynamic> _topProducts = [];
  List<dynamic> _revenueChart = [];
  List<dynamic> _hourlyChart = [];
  List<dynamic> _monthlyChart = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/reports/daily'),
        ApiService.getList('/reports/top-products?limit=5'),
        ApiService.getList('/reports/revenue-chart?days=7'),
        ApiService.getList('/reports/hourly'),
        ApiService.getList('/reports/monthly'),
      ]);
      if (mounted) {
        setState(() {
        _daily = results[0] as Map<String, dynamic>;
        _topProducts = results[1] as List;
        _revenueChart = results[2] as List;
        _hourlyChart = results[3] as List;
        _monthlyChart = results[4] as List;
        _isLoading = false;
      });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Ringkasan hari ini • ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 24),

          // Summary cards (2 cards: Pendapatan + Transaksi)
          Row(
            children: [
              _summaryCard('Total Pendapatan', 'Rp ${widget.formatter!.format(_n(_daily?['totalRevenue']))}',
                Icons.account_balance_wallet, AppTheme.success),
              const SizedBox(width: 16),
              _summaryCard('Transaksi', '${_daily?['totalTransactions'] ?? 0}',
                Icons.receipt_long, AppTheme.primary),
            ],
          ),
          const SizedBox(height: 24),

          // Hourly revenue chart
          sectionCard(
            title: 'Pendapatan Per Jam (Hari Ini)',
            icon: Icons.access_time,
            child: SizedBox(
              height: 200,
              child: _hourlyChart.isEmpty
                ? const Center(child: Text('Belum ada data', style: TextStyle(color: AppTheme.textMuted)))
                : _buildHourlyChart(),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly revenue chart
          sectionCard(
            title: 'Pendapatan Per Bulan (${DateTime.now().year})',
            icon: Icons.calendar_month,
            child: SizedBox(
              height: 200,
              child: _monthlyChart.isEmpty
                ? const Center(child: Text('Belum ada data', style: TextStyle(color: AppTheme.textMuted)))
                : _buildMonthlyChart(),
            ),
          ),
          const SizedBox(height: 16),

          // Revenue 7 days chart
          sectionCard(
            title: 'Pendapatan 7 Hari Terakhir',
            icon: Icons.bar_chart,
            child: SizedBox(
              height: 180,
              child: _revenueChart.isEmpty
                ? const Center(child: Text('Belum ada data', style: TextStyle(color: AppTheme.textMuted)))
                : _buildDailyChart(),
            ),
          ),
          const SizedBox(height: 16),

          // Top products
          sectionCard(
            title: 'Produk Terlaris',
            icon: Icons.emoji_events,
            child: _topProducts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Belum ada data', style: TextStyle(color: AppTheme.textMuted)),
                )
              : Column(
                  children: List.generate(_topProducts.length, (i) {
                    final p = _topProducts[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(p['productName'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      subtitle: Text('${p['totalQuantity'] ?? 0} terjual', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      trailing: Text('Rp ${widget.formatter!.format(_n(p['totalRevenue']))}',
                        style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
                    );
                  }),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart() {
    final maxVal = _hourlyChart.fold<double>(0, (m, e) {
      final v = (e['totalRevenue'] ?? 0).toDouble();
      return v > m ? v : m;
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _hourlyChart.map<Widget>((e) {
          final val = (e['totalRevenue'] ?? 0).toDouble();
          final ratio = maxVal > 0 ? val / maxVal : 0.0;
          final hour = e['hour'] as int? ?? 0;
          final hasValue = val > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: (150 * ratio).clamp(3, 150).toDouble(),
                    decoration: BoxDecoration(
                      color: hasValue ? AppTheme.success.withValues(alpha: 0.7) : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(hour % 3 == 0 ? hour.toString().padLeft(2, '0') : '',
                    style: const TextStyle(fontSize: 8, color: AppTheme.textMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    final maxVal = _monthlyChart.fold<double>(0, (m, e) {
      final v = (e['totalRevenue'] ?? 0).toDouble();
      return v > m ? v : m;
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _monthlyChart.map<Widget>((e) {
          final val = (e['totalRevenue'] ?? 0).toDouble();
          final ratio = maxVal > 0 ? val / maxVal : 0.0;
          final label = e['label']?.toString() ?? '';
          final hasValue = val > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasValue) Text(widget.formatter!.format(val.toInt()),
                    style: const TextStyle(fontSize: 8, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  Container(
                    height: (145 * ratio).clamp(3, 145).toDouble(),
                    decoration: BoxDecoration(
                      color: hasValue ? AppTheme.primary.withValues(alpha: 0.7) : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailyChart() {
    final maxVal = _revenueChart.fold<double>(0, (m, e) {
      final v = (e['totalRevenue'] ?? 0).toDouble();
      return v > m ? v : m;
    });
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _revenueChart.map<Widget>((e) {
        final val = (e['totalRevenue'] ?? 0).toDouble();
        final ratio = maxVal > 0 ? val / maxVal : 0.0;
        final date = e['date']?.toString() ?? '';
        final dayLabel = date.length >= 10 ? date.substring(8, 10) : '';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(widget.formatter!.format(val.toInt()), style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Container(
                  height: (140 * ratio).clamp(4, 140).toDouble(),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(dayLabel, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

}