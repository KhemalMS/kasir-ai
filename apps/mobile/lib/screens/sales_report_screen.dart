import 'package:flutter/material.dart';
import '../services/error_notifier.dart';
import '../services/error_mapper.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../widgets/report_filter_drawer.dart';

num _n(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  int _selectedTab = 0;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final _formatter = NumberFormat('#,###', 'id_ID');


  // Filter state untuk Detail Transaksi
  ReportFilterState _txFilter = ReportFilterState(
    startDate: DateTime.now().subtract(const Duration(days: 7)),
    endDate:   DateTime.now(),
  );

  final List<String> _tabs = [
    'Ringkasan', 'Item Terlaris', 'Per Kategori', 'Metode Pembayaran',
    'Per Kasir', 'Per Shift', 'Per Cabang', 'Detail Transaksi',
    'Void/Batal', 'Retur/Refund', 'Diskon & Promo', 'Jam Tersibuk', 'Hari Tersibuk'
  ];

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
        // Sinkronkan tanggal ke filter transaksi juga
        _txFilter = _txFilter.copyWith(startDate: picked.start, endDate: picked.end);
      });
    }
  }

  void _openFilterDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: ReportFilterDrawer(
              initialFilter: _txFilter,
              onApply: _onTxFilterApply,
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeInOut)),
          child: child,
        );
      },
    );
  }

  void _onTxFilterApply(ReportFilterState newFilter) {
    setState(() => _txFilter = newFilter);
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
                    'Laporan Penjualan',
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    sizing: StackFit.expand,
                    children: [
                      _SummaryReport(start: _startDate, end: _endDate),
                      _BestSellersReport(start: _startDate, end: _endDate),
                      _CategoryReport(start: _startDate, end: _endDate),
                      _PaymentMethodReport(start: _startDate, end: _endDate),
                      _StaffReport(start: _startDate, end: _endDate),
                      _ShiftReport(start: _startDate, end: _endDate),
                      _BranchReport(start: _startDate, end: _endDate),
                      _TransactionDetailsReport(
                        start: _startDate,
                        end: _endDate,
                        filter: _txFilter,
                        onFilterApply: _onTxFilterApply,
                        onOpenFilter: _openFilterDrawer,
                      ),
                      _VoidReport(start: _startDate, end: _endDate),
                      _RefundReport(start: _startDate, end: _endDate),
                      _DiscountReport(start: _startDate, end: _endDate),
                      _HourlyReport(start: _startDate, end: _endDate),
                      _BusiestDaysReport(start: _startDate, end: _endDate),
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

class _SalesDataTable extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<List<dynamic>> rows;
  final bool isLoading;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;

  const _SalesDataTable({
    required this.title,
    required this.columns,
    required this.rows,
    required this.isLoading,
    required this.onExportExcel,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                  rows: rows.map((row) {
                    return DataRow(
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

// 0: Ringkasan
class _SummaryReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _SummaryReport({required this.start, required this.end});
  @override State<_SummaryReport> createState() => _SummaryReportState();
}
class _SummaryReportState extends State<_SummaryReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _SummaryReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/daily-sales?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final rows = _data.map((e) => [
      e['date'] ?? '-', e['totalTransactions'] ?? 0, 'Rp ${_fmt.format(_n(e['totalRevenue']))}'
    ]).toList();
    return _SalesDataTable(
      title: 'Ringkasan Penjualan', columns: const ['Tanggal', 'Transaksi', 'Pendapatan'], rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Ringkasan Penjualan', ['Tanggal', 'Transaksi', 'Pendapatan'], rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Ringkasan Penjualan', ['Tanggal', 'Transaksi', 'Pendapatan'], rows),
    );
  }
}

// 1: Item Terlaris
class _BestSellersReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _BestSellersReport({required this.start, required this.end});
  @override State<_BestSellersReport> createState() => _BestSellersReportState();
}
class _BestSellersReportState extends State<_BestSellersReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _BestSellersReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/best-sellers?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    int i = 1;
    final rows = _data.map((e) => [
      i++, e['productName'] ?? '-', e['categoryName'] ?? '-', e['totalSold'] ?? 0, 'Rp ${_fmt.format(_n(e['totalRevenue']))}'
    ]).toList();
    return _SalesDataTable(
      title: 'Item Terlaris', columns: const ['Rank', 'Produk', 'Kategori', 'Qty', 'Revenue'], rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Item Terlaris', ['Rank', 'Produk', 'Kategori', 'Qty', 'Revenue'], rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Item Terlaris', ['Rank', 'Produk', 'Kategori', 'Qty', 'Revenue'], rows),
    );
  }
}

// 2: Per Kategori
class _CategoryReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _CategoryReport({required this.start, required this.end});
  @override State<_CategoryReport> createState() => _CategoryReportState();
}
class _CategoryReportState extends State<_CategoryReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _CategoryReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/sales-by-category?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final rows = _data.map((e) => [
      e['categoryName'] ?? '-', e['totalQty'] ?? 0, 'Rp ${_fmt.format(_n(e['totalRevenue']))}'
    ]).toList();
    return _SalesDataTable(
      title: 'Per Kategori', columns: const ['Kategori', 'Qty Terjual', 'Pendapatan'], rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Per Kategori', ['Kategori', 'Qty Terjual', 'Pendapatan'], rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Per Kategori', ['Kategori', 'Qty Terjual', 'Pendapatan'], rows),
    );
  }
}

// 3: Metode Pembayaran
class _PaymentMethodReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _PaymentMethodReport({required this.start, required this.end});
  @override State<_PaymentMethodReport> createState() => _PaymentMethodReportState();
}
class _PaymentMethodReportState extends State<_PaymentMethodReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _PaymentMethodReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/payment-methods?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final rows = _data.map((e) => [
      e['paymentMethod'] ?? '-', e['totalTransactions'] ?? 0, '${e['percentage']}%', 'Rp ${_fmt.format(_n(e['totalRevenue']))}'
    ]).toList();
    return _SalesDataTable(
      title: 'Metode Pembayaran', columns: const ['Metode', 'Transaksi', 'Persentase', 'Pendapatan'], rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Metode Pembayaran', ['Metode', 'Transaksi', 'Persentase', 'Pendapatan'], rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Metode Pembayaran', ['Metode', 'Transaksi', 'Persentase', 'Pendapatan'], rows),
    );
  }
}

// 4: Per Kasir
class _StaffReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _StaffReport({required this.start, required this.end});
  @override State<_StaffReport> createState() => _StaffReportState();
}
class _StaffReportState extends State<_StaffReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _StaffReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/sales-by-staff?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final rows = _data.map((e) => [
      e['staffName'] ?? '-', e['staffRole'] ?? '-', e['totalOrders'] ?? 0, 'Rp ${_fmt.format(_n(e['avgOrderValue']))}', 'Rp ${_fmt.format(_n(e['totalRevenue']))}'
    ]).toList();
    return _SalesDataTable(
      title: 'Per Kasir', columns: const ['Nama', 'Role', 'Total Order', 'Rata-rata', 'Pendapatan'], rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Per Kasir', ['Nama', 'Role', 'Total Order', 'Rata-rata', 'Pendapatan'], rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Per Kasir', ['Nama', 'Role', 'Total Order', 'Rata-rata', 'Pendapatan'], rows),
    );
  }
}

// 5: Per Shift
class _ShiftReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _ShiftReport({required this.start, required this.end});
  @override State<_ShiftReport> createState() => _ShiftReportState();
}
class _ShiftReportState extends State<_ShiftReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _ShiftReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/shift-report?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final rows = _data.map((e) => [
      e['startedAt']?.toString().substring(0,16) ?? '-', e['staffName'] ?? '-', e['status'] ?? '-', 'Rp ${_fmt.format(_n(e['expectedCash']))}', 'Rp ${_fmt.format(_n(e['endingCash']))}', 'Rp ${_fmt.format(_n(e['cashDifference']))}'
    ]).toList();
    return _SalesDataTable(
      title: 'Per Shift', columns: const ['Mulai', 'Staff', 'Status', 'Expected', 'Actual', 'Selisih'], rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Per Shift', ['Mulai', 'Staff', 'Status', 'Expected', 'Actual', 'Selisih'], rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Per Shift', ['Mulai', 'Staff', 'Status', 'Expected', 'Actual', 'Selisih'], rows),
    );
  }
}

// 6: Per Cabang
class _BranchReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _BranchReport({required this.start, required this.end});
  @override State<_BranchReport> createState() => _BranchReportState();
}
class _BranchReportState extends State<_BranchReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _BranchReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/daily-sales?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    int totalTx = _data.fold(0, (sum, e) => sum + (_n(e['totalTransactions']) as int));
    num totalRev = _data.fold(0, (sum, e) => sum + _n(e['totalRevenue']));
    final rows = [
      ['Cabang Utama', totalTx, 'Rp ${_fmt.format(totalRev)}']
    ];
    return _SalesDataTable(
      title: 'Per Cabang', columns: const ['Cabang', 'Total Transaksi', 'Total Pendapatan'], rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Per Cabang', ['Cabang', 'Total Transaksi', 'Total Pendapatan'], rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Per Cabang', ['Cabang', 'Total Transaksi', 'Total Pendapatan'], rows),
    );
  }
}

// 7: Detail Transaksi
class _TransactionDetailsReport extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  final ReportFilterState filter;
  final void Function(ReportFilterState) onFilterApply;
  final VoidCallback onOpenFilter;

  const _TransactionDetailsReport({
    required this.start,
    required this.end,
    required this.filter,
    required this.onFilterApply,
    required this.onOpenFilter,
  });

  @override State<_TransactionDetailsReport> createState() => _TransactionDetailsReportState();
}

class _TransactionDetailsReportState extends State<_TransactionDetailsReport> {
  bool _loading = false;
  List<dynamic> _data = [];
  int _totalPages = 1;
  int _totalItems = 0;
  // Salinan lokal filter agar bisa track perubahan
  late ReportFilterState _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _TransactionDetailsReport oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dateChanged = oldWidget.start != widget.start || oldWidget.end != widget.end;
    final filterChanged = oldWidget.filter != widget.filter;
    if (dateChanged) {
      _filter = _filter.copyWith(startDate: widget.start, endDate: widget.end);
    }
    if (filterChanged) {
      _filter = widget.filter;
    }
    if (dateChanged || filterChanged) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/reports/transaction-details?${_filter.buildQueryString()}');
      if (mounted) {
        setState(() {
          _data        = res['data'] ?? [];
          _totalPages  = res['pagination']?['totalPages'] ?? 1;
          _totalItems  = res['pagination']?['total'] ?? 0;
          _loading     = false;
        });
      }
    } catch (e) {
      ErrorNotifier.show(ErrorMapper.from(e, null, module: 'report', action: 'fetchTransactionDetails'));
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _filter = _filter.copyWith(page: page));
    _fetch();
  }

  void _clearFilter(ReportFilterState cleared) {
    _filter = cleared;
    widget.onFilterApply(cleared);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final headers = ['No. Invoice', 'Waktu', 'Kasir', 'Tipe', 'Pembayaran', 'Status', 'Total'];
    final rows = _data.map((e) => [
      e['orderNumber']  ?? '-',
      e['createdAt']?.toString().substring(0, 16) ?? '-',
      e['staffName']    ?? '-',
      e['orderType']    ?? '-',
      e['paymentMethod'] ?? '-',
      e['status']       ?? '-',
      'Rp ${_fmt.format(_n(e['totalAmount']))}',
    ]).toList();

    // ─── Active Filter Chips ──────────────────────────────────────
    final f = _filter;
    final activeFilters = <Widget>[];
    if (f.branchName != null)
      activeFilters.add(_filterChip('Cabang: ${f.branchName}', () => _clearFilter(f.copyWith(clearBranch: true))));
    if (f.staffName != null)
      activeFilters.add(_filterChip('Kasir: ${f.staffName}', () => _clearFilter(f.copyWith(clearStaff: true))));
    if (f.paymentMethod != null)
      activeFilters.add(_filterChip('Bayar: ${f.paymentMethod}', () => _clearFilter(f.copyWith(clearPayment: true))));
    if (f.search != null && f.search!.isNotEmpty)
      activeFilters.add(_filterChip('Cari: "${f.search}"', () => _clearFilter(f.copyWith(search: ''))));

    return SizedBox.expand(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Toolbar ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: AppTheme.surfaceDark,
          child: Row(
            children: [
              // Active filter chips
              Expanded(
                child: Wrap(
                  spacing: 8, runSpacing: 4,
                  children: activeFilters.isEmpty
                    ? [const Text('Semua transaksi', style: TextStyle(color: AppTheme.textMuted, fontSize: 12))]
                    : activeFilters,
                ),
              ),
              const SizedBox(width: 8),
              // Export buttons
              ElevatedButton.icon(
                icon: const Icon(Icons.table_chart, size: 14),
                label: const Text('Excel', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                onPressed: () => ExportService.exportToExcel('Detail Transaksi', headers, rows),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, size: 14),
                label: const Text('PDF', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                onPressed: () => ExportService.exportToPdf(context, 'Detail Transaksi', headers, rows),
              ),
              const SizedBox(width: 8),
              // Filter Button
              ElevatedButton.icon(
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeFilters.isNotEmpty ? AppTheme.primary : AppTheme.cardDark,
                  foregroundColor: Colors.white,
                ),
                onPressed: widget.onOpenFilter,
              ),
            ],
          ),
        ),

        // ─── Info bar ─────────────────────────────────────────────
        if (!_loading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: AppTheme.cardDark,
            child: Row(
              children: [
                Text(
                  'Menampilkan ${_data.length} dari $_totalItems transaksi',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'Halaman ${_filter.page} dari $_totalPages',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),

        // ─── DataTable ─────────────────────────────────────────────
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _data.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text('Tidak ada transaksi ditemukan', style: TextStyle(color: AppTheme.textMuted)),
                ]))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.surfaceDark),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppTheme.surfaceDark),
                            headingTextStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                            dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
                            columns: headers.map((c) => DataColumn(label: Text(c))).toList(),
                            rows: List.generate(rows.length, (i) {
                              final status = _data[i]['status'] ?? '';
                              Color? rowColor;
                              if (status == 'Batal')  rowColor = AppTheme.danger.withOpacity(0.1);
                              if (status == 'Sukses') rowColor = AppTheme.success.withOpacity(0.05);
                              return DataRow(
                                color: rowColor != null ? WidgetStateProperty.all(rowColor) : null,
                                cells: rows[i].map((c) => DataCell(Text(c.toString()))).toList(),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                       _buildPagination(),
                    ],
                  ),
                ),
        ),
      ],
    ));
  }

  Widget _filterChip(String label, VoidCallback onRemove) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
      const SizedBox(width: 4),
      GestureDetector(onTap: onRemove, child: const Icon(Icons.close, color: AppTheme.primary, size: 14)),
    ]),
  );

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    final page = _filter.page;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page, color: Colors.white),
          onPressed: page > 1 ? () => _goToPage(1) : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: page > 1 ? () => _goToPage(page - 1) : null,
        ),
        ...List.generate(_totalPages, (i) => i + 1)
            .where((p) => (p - page).abs() <= 2)
            .map((p) => GestureDetector(
              onTap: () => _goToPage(p),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: p == page ? AppTheme.primary : AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text('$p', style: TextStyle(color: p == page ? Colors.white : AppTheme.textMuted, fontWeight: p == page ? FontWeight.bold : FontWeight.normal)),
              ),
            )),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: page < _totalPages ? () => _goToPage(page + 1) : null,
        ),
        IconButton(
          icon: const Icon(Icons.last_page, color: Colors.white),
          onPressed: page < _totalPages ? () => _goToPage(_totalPages) : null,
        ),
      ],
    );
  }
}

// 8: Void / Batal
class _VoidReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _VoidReport({required this.start, required this.end});
  @override State<_VoidReport> createState() => _VoidReportState();
}
class _VoidReportState extends State<_VoidReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _VoidReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/void-transactions?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final rows = _data.map((e) => [
      e['orderNumber'] ?? '-', e['createdAt']?.toString().substring(0,16) ?? '-', e['staffName'] ?? '-', e['reason'] ?? '-', 'Rp ${_fmt.format(_n(e['totalAmount']))}'
    ]).toList();
    return _SalesDataTable(
      title: 'Void / Batal Transaksi', columns: const ['Nomor Order', 'Waktu', 'Kasir', 'Alasan', 'Total'], rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Void Batal', ['Nomor Order', 'Waktu', 'Kasir', 'Alasan', 'Total'], rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Void Batal', ['Nomor Order', 'Waktu', 'Kasir', 'Alasan', 'Total'], rows),
    );
  }
}

// 9: Retur / Refund
class _RefundReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _RefundReport({required this.start, required this.end});
  @override State<_RefundReport> createState() => _RefundReportState();
}
class _RefundReportState extends State<_RefundReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _RefundReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/refund-transactions?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final rows = _data.map((e) => [
      e['orderNumber'] ?? '-', e['createdAt']?.toString().substring(0,16) ?? '-', e['staffName'] ?? '-', e['notes'] ?? '-', 'Rp ${_fmt.format(_n(e['totalAmount']))}'
    ]).toList();
    return _SalesDataTable(
      title: 'Retur / Refund', columns: const ['Nomor Order', 'Waktu', 'Kasir', 'Notes', 'Total'], rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Retur Refund', ['Nomor Order', 'Waktu', 'Kasir', 'Notes', 'Total'], rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Retur Refund', ['Nomor Order', 'Waktu', 'Kasir', 'Notes', 'Total'], rows),
    );
  }
}

// 10: Diskon & Promo
class _DiscountReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _DiscountReport({required this.start, required this.end});
  @override State<_DiscountReport> createState() => _DiscountReportState();
}
class _DiscountReportState extends State<_DiscountReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _DiscountReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/reports/discount-summary?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = (res as Map<String, dynamic>)['rows'] ?? []; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final rows = _data.map((e) => [
      e['orderNumber'] ?? '-', e['date']?.toString().substring(0,16) ?? '-', e['staffName'] ?? '-', 'Rp ${_fmt.format(_n(e['discountAmount']))}', 'Rp ${_fmt.format(_n(e['totalAmount']))}'
    ]).toList();
    return _SalesDataTable(
      title: 'Diskon & Promo', columns: const ['Nomor Order', 'Waktu', 'Kasir', 'Diskon', 'Total Transaksi'], rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Diskon Promo', ['Nomor Order', 'Waktu', 'Kasir', 'Diskon', 'Total Transaksi'], rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Diskon Promo', ['Nomor Order', 'Waktu', 'Kasir', 'Diskon', 'Total Transaksi'], rows),
    );
  }
}

// 11: Jam Tersibuk
class _HourlyReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _HourlyReport({required this.start, required this.end});
  @override State<_HourlyReport> createState() => _HourlyReportState();
}
class _HourlyReportState extends State<_HourlyReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _HourlyReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      // NOTE: hourly-sales usually takes just one date in API, but let's pass date from start
      final res = await ApiService.getList('/reports/hourly-sales?date=${_dateStr(widget.start)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    final maxVal = _data.fold<double>(0, (m, e) {
      final v = (e['totalTransactions'] ?? 0).toDouble();
      return v > m ? v : m;
    });
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Jam Tersibuk (Dari Tanggal Mulai)', style: TextStyle(color: Colors.white, fontSize: 16)),
              ElevatedButton.icon(
                onPressed: () {
                  final rows = _data.map((e) => [e['label'] ?? '-', e['totalTransactions'] ?? 0, 'Rp ${_fmt.format(_n(e['totalRevenue']))}']).toList();
                  ExportService.exportToExcel('Jam Tersibuk', ['Jam', 'Total Transaksi', 'Pendapatan'], rows);
                },
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
              )
            ]
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _data.map<Widget>((e) {
                final val = (e['totalTransactions'] ?? 0).toDouble();
                final ratio = maxVal > 0 ? val / maxVal : 0.0;
                final label = e['label'] ?? '';
                final hasValue = val > 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasValue) Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Container(
                          height: (300 * ratio).clamp(4, 300).toDouble(),
                          decoration: BoxDecoration(color: hasValue ? AppTheme.primary : AppTheme.surfaceDark, borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(height: 6),
                        Text(label.toString().substring(0,2), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// 12: Hari Tersibuk
class _BusiestDaysReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _BusiestDaysReport({required this.start, required this.end});
  @override State<_BusiestDaysReport> createState() => _BusiestDaysReportState();
}
class _BusiestDaysReportState extends State<_BusiestDaysReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _BusiestDaysReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/busiest-days?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    final maxVal = _data.fold<double>(0, (m, e) {
      final v = (e['totalTransactions'] ?? 0).toDouble();
      return v > m ? v : m;
    });
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hari Tersibuk', style: TextStyle(color: Colors.white, fontSize: 16)),
              ElevatedButton.icon(
                onPressed: () {
                  final rows = _data.map((e) => [e['dayName'] ?? '-', e['totalTransactions'] ?? 0, 'Rp ${_fmt.format(_n(e['totalRevenue']))}']).toList();
                  ExportService.exportToExcel('Hari Tersibuk', ['Hari', 'Total Transaksi', 'Pendapatan'], rows);
                },
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
              )
            ]
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _data.map<Widget>((e) {
                final val = (e['totalTransactions'] ?? 0).toDouble();
                final ratio = maxVal > 0 ? val / maxVal : 0.0;
                final label = e['dayName'] ?? '';
                final hasValue = val > 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasValue) Text(val.toInt().toString(), style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Container(
                          height: (300 * ratio).clamp(4, 300).toDouble(),
                          decoration: BoxDecoration(color: hasValue ? AppTheme.success : AppTheme.surfaceDark, borderRadius: BorderRadius.circular(6)),
                        ),
                        const SizedBox(height: 6),
                        Text(label.toString().substring(0,3), style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
