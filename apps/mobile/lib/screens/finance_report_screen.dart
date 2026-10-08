import 'package:flutter/material.dart';
import '../services/error_notifier.dart';
import '../services/error_mapper.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

num _n(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

class FinanceReportScreen extends StatefulWidget {
  const FinanceReportScreen({super.key});

  @override
  State<FinanceReportScreen> createState() => _FinanceReportScreenState();
}

class _FinanceReportScreenState extends State<FinanceReportScreen> {
  int _selectedTab = 0;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<String> _tabs = [
    'Laba Rugi', 'HPP (COGS)', 'Gross Margin', 'Arus Kas',
    'Rekonsiliasi Kas', 'Piutang', 'Utang Supplier'
  ];

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.cardDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.bgDark,
      child: Row(
        children: [
          // Left Panel
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: AppTheme.cardDark,
              border: Border(right: BorderSide(color: AppTheme.surfaceDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Laporan Keuangan',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _tabs.length,
                    itemBuilder: (context, i) {
                      final isActive = _selectedTab == i;
                      return InkWell(
                        onTap: () => setState(() => _selectedTab = i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isActive ? AppTheme.primary : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              color: isActive ? Colors.white : AppTheme.textMuted,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right Panel
          Expanded(
            child: Column(
              children: [
                // Header bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppTheme.cardDark,
                    border: Border(bottom: BorderSide(color: AppTheme.surfaceDark)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _tabs[_selectedTab],
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _pickDateRange,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.surfaceDark),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, color: AppTheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _ProfitLossReport(start: _startDate, end: _endDate),
                      _CogsReport(start: _startDate, end: _endDate),
                      _GrossMarginReport(start: _startDate, end: _endDate),
                      _CashFlowReport(start: _startDate, end: _endDate),
                      _CashReconciliationReport(start: _startDate, end: _endDate),
                      _AccountsReceivableReport(start: _startDate, end: _endDate),
                      _AccountsPayableReport(start: _startDate, end: _endDate),
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
}

class _FinanceDataTable extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<List<dynamic>> rows;
  final bool isLoading;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;
  final Widget? headerWidget;
  final Color? Function(int rowIndex)? rowColorBuilder;

  const _FinanceDataTable({
    required this.title,
    required this.columns,
    required this.rows,
    required this.isLoading,
    required this.onExportExcel,
    required this.onExportPdf,
    this.headerWidget,
    this.rowColorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: AppTheme.surfaceDark),
            const SizedBox(height: 16),
            Text('Tidak ada data', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (headerWidget != null) ...[
                headerWidget!,
                const Spacer(),
              ],
              ElevatedButton.icon(
                onPressed: onExportExcel,
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onExportPdf,
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceDark),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  dataTextStyle: const TextStyle(color: Colors.white),
                  columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
                  rows: rows.asMap().entries.map((entry) {
                    final rowIndex = entry.key;
                    final row = entry.value;
                    Color? rowColor;
                    if (rowColorBuilder != null) {
                      rowColor = rowColorBuilder!(rowIndex);
                    }
                    return DataRow(
                      color: rowColor != null ? WidgetStateProperty.all(rowColor) : null,
                      cells: row.map((cell) => DataCell(Text(cell.toString()))).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

final _fmt = NumberFormat('#,###', 'id_ID');
String _dateStr(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String _formatDateStr(String? d) {
  if (d == null) return '-';
  try {
    return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(d).toLocal());
  } catch(e) {
    return d;
  }
}

// 0: Laba Rugi
class _ProfitLossReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _ProfitLossReport({required this.start, required this.end});
  @override State<_ProfitLossReport> createState() => _ProfitLossReportState();
}
class _ProfitLossReportState extends State<_ProfitLossReport> {
  bool _loading = false; Map<String, dynamic>? _data;
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _ProfitLossReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/reports/finance/profit-loss?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }

  Widget _buildCard(String title, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceDark),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rp ${_fmt.format(_n(value))}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_data == null) return const Center(child: Text('Gagal memuat data', style: TextStyle(color: Colors.white)));

    final netProfit = _n(_data!['netProfit']);
    final isLoss = netProfit < 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                   ExportService.exportToExcel('Laba Rugi', ['Keterangan', 'Nilai'], [
                      ['Pendapatan Kotor', 'Rp ${_fmt.format(_n(_data!['totalRevenue']))}'],
                      ['HPP', 'Rp ${_fmt.format(_n(_data!['totalCogs']))}'],
                      ['Laba Kotor', 'Rp ${_fmt.format(_n(_data!['grossProfit']))}'],
                      ['Biaya Operasional', 'Rp ${_fmt.format(_n(_data!['totalExpenses']))}'],
                      ['Laba Bersih', 'Rp ${_fmt.format(netProfit)}'],
                   ]);
                },
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                   ExportService.exportToPdf(context, 'Laba Rugi', ['Keterangan', 'Nilai'], [
                      ['Pendapatan Kotor', 'Rp ${_fmt.format(_n(_data!['totalRevenue']))}'],
                      ['HPP', 'Rp ${_fmt.format(_n(_data!['totalCogs']))}'],
                      ['Laba Kotor', 'Rp ${_fmt.format(_n(_data!['grossProfit']))}'],
                      ['Biaya Operasional', 'Rp ${_fmt.format(_n(_data!['totalExpenses']))}'],
                      ['Laba Bersih', 'Rp ${_fmt.format(netProfit)}'],
                   ]);
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width > 800 ? 300 : double.infinity,
                  child: _buildCard('Pendapatan Kotor', _data!['totalRevenue'], Icons.attach_money, Colors.blue),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width > 800 ? 300 : double.infinity,
                  child: _buildCard('HPP (COGS)', _data!['totalCogs'], Icons.inventory, Colors.grey),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width > 800 ? 300 : double.infinity,
                  child: _buildCard('Laba Kotor', _data!['grossProfit'], Icons.trending_up, Colors.green),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width > 800 ? 300 : double.infinity,
                  child: _buildCard('Biaya Operasional', _data!['totalExpenses'], Icons.money_off, Colors.orange),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width > 800 ? 300 : double.infinity,
                  child: _buildCard('Laba Bersih', netProfit, isLoss ? Icons.trending_down : Icons.check_circle, isLoss ? Colors.red : Colors.lightGreenAccent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 1: HPP (COGS)
class _CogsReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _CogsReport({required this.start, required this.end});
  @override State<_CogsReport> createState() => _CogsReportState();
}
class _CogsReportState extends State<_CogsReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _CogsReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/finance/cogs?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Nama Produk', 'Qty Terjual', 'HPP/Unit', 'Total HPP'];
    final rows = _data.map((e) => [
      e['productName'] ?? '-', e['totalQtySold'] ?? 0,
      'Rp ${_fmt.format(_n(e['cogsPerUnit']))}', 'Rp ${_fmt.format(_n(e['totalCogs']))}'
    ]).toList();
    return _FinanceDataTable(
      title: 'HPP (COGS)', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('HPP (COGS)', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'HPP (COGS)', columns, rows),
    );
  }
}

// 2: Gross Margin
class _GrossMarginReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _GrossMarginReport({required this.start, required this.end});
  @override State<_GrossMarginReport> createState() => _GrossMarginReportState();
}
class _GrossMarginReportState extends State<_GrossMarginReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _GrossMarginReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/finance/gross-margin?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Nama Produk', 'Qty', 'Pendapatan', 'HPP', 'Margin Kotor', 'Margin %'];
    final rows = _data.map((e) => [
      e['productName'] ?? '-', e['totalQtySold'] ?? 0,
      'Rp ${_fmt.format(_n(e['totalRevenue']))}', 'Rp ${_fmt.format(_n(e['totalCogs']))}',
      'Rp ${_fmt.format(_n(e['grossMargin']))}', '${e['marginPct']}%'
    ]).toList();
    
    return _FinanceDataTable(
      title: 'Gross Margin', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Gross Margin', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Gross Margin', columns, rows),
      rowColorBuilder: (rowIndex) {
        final marginPct = _n(_data[rowIndex]['marginPct']);
        if (marginPct >= 40) return Colors.green.withValues(alpha: 0.2);
        if (marginPct >= 20) return Colors.orange.withValues(alpha: 0.2);
        return Colors.red.withValues(alpha: 0.2);
      },
    );
  }
}

// 3: Arus Kas
class _CashFlowReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _CashFlowReport({required this.start, required this.end});
  @override State<_CashFlowReport> createState() => _CashFlowReportState();
}
class _CashFlowReportState extends State<_CashFlowReport> {
  bool _loading = false; Map<String, dynamic>? _data;
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _CashFlowReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/reports/finance/cash-flow?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }

  Widget _buildTable(String title, List<dynamic> data, String nameCol, String valCol) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.surfaceDark)),
            ),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          DataTable(
            headingTextStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
            dataTextStyle: const TextStyle(color: Colors.white),
            columns: [
              DataColumn(label: Text(nameCol)),
              const DataColumn(label: Text('Total')),
            ],
            rows: data.map((e) => DataRow(cells: [
              DataCell(Text(e[nameCol == 'Metode' ? 'method' : 'category'] ?? '-')),
              DataCell(Text('Rp ${_fmt.format(_n(e['total']))}')),
            ])).toList(),
          ),
        ],
      ),
    );
  }

  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_data == null) return const Center(child: Text('Gagal memuat data', style: TextStyle(color: Colors.white)));

    final inflows = _data!['inflows'] as List<dynamic>? ?? [];
    final outflows = _data!['outflows'] as List<dynamic>? ?? [];
    final netCashFlow = _n(_data!['netCashFlow']);
    final isLoss = netCashFlow < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                   // Prepare data for export
                   final List<List<dynamic>> exportData = [];
                   exportData.add(['Net Cash Flow', 'Rp ${_fmt.format(netCashFlow)}']);
                   exportData.add([]);
                   exportData.add(['Uang Masuk (Inflows)', '']);
                   for(var item in inflows) exportData.add([item['method'] ?? '-', 'Rp ${_fmt.format(_n(item['total']))}']);
                   exportData.add([]);
                   exportData.add(['Uang Keluar (Outflows)', '']);
                   for(var item in outflows) exportData.add([item['category'] ?? '-', 'Rp ${_fmt.format(_n(item['total']))}']);

                   ExportService.exportToExcel('Arus Kas', ['Keterangan', 'Nilai'], exportData);
                },
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                   final List<List<dynamic>> exportData = [];
                   exportData.add(['Net Cash Flow', 'Rp ${_fmt.format(netCashFlow)}']);
                   exportData.add([]);
                   exportData.add(['Uang Masuk (Inflows)', '']);
                   for(var item in inflows) exportData.add([item['method'] ?? '-', 'Rp ${_fmt.format(_n(item['total']))}']);
                   exportData.add([]);
                   exportData.add(['Uang Keluar (Outflows)', '']);
                   for(var item in outflows) exportData.add([item['category'] ?? '-', 'Rp ${_fmt.format(_n(item['total']))}']);

                   ExportService.exportToPdf(context, 'Arus Kas', ['Keterangan', 'Nilai'], exportData);
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isLoss ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isLoss ? Colors.red : Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Net Cash Flow', style: TextStyle(color: isLoss ? Colors.redAccent : Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${_fmt.format(netCashFlow)}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Tables
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTable('Uang Masuk', inflows, 'Metode', 'total')),
                          const SizedBox(width: 20),
                          Expanded(child: _buildTable('Uang Keluar', outflows, 'Kategori', 'total')),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTable('Uang Masuk', inflows, 'Metode', 'total'),
                        const SizedBox(height: 20),
                        _buildTable('Uang Keluar', outflows, 'Kategori', 'total'),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 4: Rekonsiliasi Kas
class _CashReconciliationReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _CashReconciliationReport({required this.start, required this.end});
  @override State<_CashReconciliationReport> createState() => _CashReconciliationReportState();
}
class _CashReconciliationReportState extends State<_CashReconciliationReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _CashReconciliationReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/finance/cash-reconciliation?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Kasir', 'Tgl Mulai', 'Tgl Tutup', 'Kas Awal', 'Kas Diharapkan', 'Kas Aktual', 'Selisih', 'Status'];
    final rows = _data.map((e) => [
      e['staffName'] ?? '-', _formatDateStr(e['startedAt']), _formatDateStr(e['closedAt']),
      'Rp ${_fmt.format(_n(e['startingCash']))}', 'Rp ${_fmt.format(_n(e['expectedCash']))}',
      'Rp ${_fmt.format(_n(e['endingCash']))}', 'Rp ${_fmt.format(_n(e['cashDifference']))}', e['status'] ?? '-'
    ]).toList();
    
    return _FinanceDataTable(
      title: 'Rekonsiliasi Kas', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Rekonsiliasi Kas', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Rekonsiliasi Kas', columns, rows),
      rowColorBuilder: (rowIndex) {
        final diff = _n(_data[rowIndex]['cashDifference']);
        if (diff == 0) return Colors.green.withValues(alpha: 0.2);
        if (diff < 0) return Colors.red.withValues(alpha: 0.2);
        return Colors.orange.withValues(alpha: 0.2);
      },
    );
  }
}

// 5: Piutang
class _AccountsReceivableReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _AccountsReceivableReport({required this.start, required this.end});
  @override State<_AccountsReceivableReport> createState() => _AccountsReceivableReportState();
}
class _AccountsReceivableReportState extends State<_AccountsReceivableReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _AccountsReceivableReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/finance/accounts-receivable?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['No. Order', 'Tanggal', 'Total Tagihan', 'Sudah Dibayar', 'Sisa Tagihan'];
    final rows = _data.map((e) => [
      e['orderNumber'] ?? '-', _formatDateStr(e['date']),
      'Rp ${_fmt.format(_n(e['totalAmount']))}', 'Rp ${_fmt.format(_n(e['amountPaid']))}',
      'Rp ${_fmt.format(_n(e['balanceDue']))}'
    ]).toList();
    
    return _FinanceDataTable(
      title: 'Piutang', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Piutang', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Piutang', columns, rows),
      rowColorBuilder: (rowIndex) {
        final balance = _n(_data[rowIndex]['balanceDue']);
        if (balance > 0) return Colors.red.withValues(alpha: 0.2);
        return null;
      },
    );
  }
}

// 6: Utang Supplier
class _AccountsPayableReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _AccountsPayableReport({required this.start, required this.end});
  @override State<_AccountsPayableReport> createState() => _AccountsPayableReportState();
}
class _AccountsPayableReportState extends State<_AccountsPayableReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _AccountsPayableReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/finance/accounts-payable?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['No. Batch', 'Item', 'Supplier', 'Tgl Terima', 'Jatuh Tempo', 'Total', 'Dibayar', 'Sisa', 'Status'];
    final rows = _data.map((e) => [
      e['batchNumber'] ?? '-', e['inventoryName'] ?? '-', e['supplierName'] ?? '-', 
      _formatDateStr(e['receivedAt']), _formatDateStr(e['dueDate']),
      'Rp ${_fmt.format(_n(e['totalAmount']))}', 'Rp ${_fmt.format(_n(e['amountPaid']))}',
      'Rp ${_fmt.format(_n(e['balanceDue']))}', e['paymentStatus'] ?? '-'
    ]).toList();
    
    return _FinanceDataTable(
      title: 'Utang Supplier', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Utang Supplier', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Utang Supplier', columns, rows),
      rowColorBuilder: (rowIndex) {
        final status = _data[rowIndex]['paymentStatus'];
        if (status == 'Unpaid') return Colors.red.withValues(alpha: 0.2);
        if (status == 'Partial') return Colors.orange.withValues(alpha: 0.2);
        return null;
      },
    );
  }
}
