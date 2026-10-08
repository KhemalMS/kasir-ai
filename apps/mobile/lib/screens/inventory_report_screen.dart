import 'package:flutter/material.dart';
import '../services/error_notifier.dart';
import '../services/error_mapper.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

num _n(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  int _selectedTab = 0;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<String> _tabs = [
    'Stok Saat Ini', 'Stok Masuk', 'Stok Keluar', 'Stok Menipis',
    'Stok Kadaluarsa', 'Penyesuaian Stok', 'Perputaran Stok', 'Dead Stock', 'Nilai Inventori'
  ];

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)), // For expired we might look forward
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
                    'Laporan Inventori',
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
                      _CurrentStockReport(start: _startDate, end: _endDate),
                      _StockInReport(start: _startDate, end: _endDate),
                      _StockOutReport(start: _startDate, end: _endDate),
                      _LowStockReport(start: _startDate, end: _endDate),
                      _ExpiredStockReport(start: _startDate, end: _endDate),
                      _AdjustmentsReport(start: _startDate, end: _endDate),
                      _TurnoverReport(start: _startDate, end: _endDate),
                      _DeadStockReport(start: _startDate, end: _endDate),
                      _ValuationReport(start: _startDate, end: _endDate),
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

class _InventoryDataTable extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<List<dynamic>> rows;
  final bool isLoading;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;
  final Widget? headerWidget;
  final Color? Function(int rowIndex)? rowColorBuilder;

  const _InventoryDataTable({
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

// 0: Stok Saat Ini
class _CurrentStockReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _CurrentStockReport({required this.start, required this.end});
  @override State<_CurrentStockReport> createState() => _CurrentStockReportState();
}
class _CurrentStockReportState extends State<_CurrentStockReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _CurrentStockReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/inventory/current?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Nama Item', 'SKU', 'Unit', 'Stok', 'Ambang Batas', 'Nilai Aset'];
    final rows = _data.map((e) => [
      e['name'] ?? '-', e['sku'] ?? '-', e['unit'] ?? '-', 
      e['quantity'] ?? 0, e['reorderThreshold'] ?? 0, 
      'Rp ${_fmt.format(_n(e['assetValue']))}'
    ]).toList();
    return _InventoryDataTable(
      title: 'Stok Saat Ini', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Stok Saat Ini', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Stok Saat Ini', columns, rows),
    );
  }
}

// 1: Stok Masuk
class _StockInReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _StockInReport({required this.start, required this.end});
  @override State<_StockInReport> createState() => _StockInReportState();
}
class _StockInReportState extends State<_StockInReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _StockInReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/inventory/in?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Nama Item', 'No. Batch', 'Supplier', 'Qty Diterima', 'Harga Beli', 'Total Nilai', 'Tgl Terima', 'Kadaluarsa'];
    final rows = _data.map((e) => [
      e['inventoryName'] ?? '-', e['batchNumber'] ?? '-', e['supplierName'] ?? '-', 
      e['quantityReceived'] ?? 0, 'Rp ${_fmt.format(_n(e['costPrice']))}', 'Rp ${_fmt.format(_n(e['totalValue']))}',
      _formatDateStr(e['receivedAt']), _formatDateStr(e['expirationDate'])
    ]).toList();
    return _InventoryDataTable(
      title: 'Stok Masuk', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Stok Masuk', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Stok Masuk', columns, rows),
    );
  }
}

// 2: Stok Keluar
class _StockOutReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _StockOutReport({required this.start, required this.end});
  @override State<_StockOutReport> createState() => _StockOutReportState();
}
class _StockOutReportState extends State<_StockOutReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _StockOutReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/inventory/out?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Nama Item', 'Tipe', 'Jumlah', 'Alasan', 'Staf', 'Tanggal'];
    final rows = _data.map((e) => [
      e['inventoryName'] ?? '-', e['type'] ?? '-', e['quantity'] ?? 0, 
      e['reason'] ?? '-', e['staffName'] ?? '-', _formatDateStr(e['createdAt'])
    ]).toList();
    return _InventoryDataTable(
      title: 'Stok Keluar', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Stok Keluar', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Stok Keluar', columns, rows),
    );
  }
}

// 3: Stok Menipis
class _LowStockReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _LowStockReport({required this.start, required this.end});
  @override State<_LowStockReport> createState() => _LowStockReportState();
}
class _LowStockReportState extends State<_LowStockReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _LowStockReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/inventory/low-stock?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Nama Item', 'SKU', 'Unit', 'Stok Saat Ini', 'Ambang Batas', 'Kekurangan'];
    final rows = _data.map((e) => [
      e['name'] ?? '-', e['sku'] ?? '-', e['unit'] ?? '-', 
      e['quantity'] ?? 0, e['reorderThreshold'] ?? 0, e['deficit'] ?? 0
    ]).toList();
    
    return _InventoryDataTable(
      title: 'Stok Menipis', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Stok Menipis', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Stok Menipis', columns, rows),
      rowColorBuilder: (rowIndex) {
        final rowData = _data[rowIndex];
        final qty = _n(rowData['quantity']);
        final threshold = _n(rowData['reorderThreshold']);
        if (qty == 0) return Colors.red.withValues(alpha: 0.2);
        if (qty <= threshold) return Colors.orange.withValues(alpha: 0.2);
        return null;
      },
    );
  }
}

// 4: Stok Kadaluarsa
class _ExpiredStockReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _ExpiredStockReport({required this.start, required this.end});
  @override State<_ExpiredStockReport> createState() => _ExpiredStockReportState();
}
class _ExpiredStockReportState extends State<_ExpiredStockReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _ExpiredStockReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/inventory/expired?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Nama Item', 'No. Batch', 'Sisa Qty', 'Kadaluarsa', 'Hari Tersisa', 'Status'];
    final rows = _data.map((e) => [
      e['inventoryName'] ?? '-', e['batchNumber'] ?? '-', e['quantityRemaining'] ?? 0, 
      _formatDateStr(e['expirationDate']), e['daysUntilExpiry'] ?? '-', e['status'] ?? '-'
    ]).toList();
    
    return _InventoryDataTable(
      title: 'Stok Kadaluarsa', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Stok Kadaluarsa', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Stok Kadaluarsa', columns, rows),
      rowColorBuilder: (rowIndex) {
        final status = _data[rowIndex]['status'];
        if (status == 'Expired') return Colors.red.withValues(alpha: 0.2);
        if (status == 'Expiring Soon') return Colors.orange.withValues(alpha: 0.2);
        return null;
      },
    );
  }
}

// 5: Penyesuaian Stok
class _AdjustmentsReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _AdjustmentsReport({required this.start, required this.end});
  @override State<_AdjustmentsReport> createState() => _AdjustmentsReportState();
}
class _AdjustmentsReportState extends State<_AdjustmentsReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _AdjustmentsReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/inventory/adjustments?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Nama Item', 'Qty Penyesuaian', 'Alasan', 'Staf', 'Tanggal'];
    final rows = _data.map((e) => [
      e['inventoryName'] ?? '-', e['quantity'] ?? 0, e['reason'] ?? '-', 
      e['staffName'] ?? '-', _formatDateStr(e['createdAt'])
    ]).toList();
    return _InventoryDataTable(
      title: 'Penyesuaian Stok', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Penyesuaian Stok', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Penyesuaian Stok', columns, rows),
    );
  }
}

// 6: Perputaran Stok
class _TurnoverReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _TurnoverReport({required this.start, required this.end});
  @override State<_TurnoverReport> createState() => _TurnoverReportState();
}
class _TurnoverReportState extends State<_TurnoverReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _TurnoverReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/inventory/turnover?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Nama Item', 'Total Keluar', 'Rata-rata Stok', 'Rasio Perputaran'];
    final rows = _data.map((e) => [
      e['name'] ?? '-', e['totalOut'] ?? 0, e['avgStock'] ?? 0, e['turnoverRatio'] ?? 0
    ]).toList();
    return _InventoryDataTable(
      title: 'Perputaran Stok', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Perputaran Stok', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Perputaran Stok', columns, rows),
    );
  }
}

// 7: Dead Stock
class _DeadStockReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _DeadStockReport({required this.start, required this.end});
  @override State<_DeadStockReport> createState() => _DeadStockReportState();
}
class _DeadStockReportState extends State<_DeadStockReport> {
  bool _loading = false; List<dynamic> _data = [];
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _DeadStockReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getList('/reports/inventory/dead-stock?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Nama Item', 'SKU', 'Unit', 'Stok', 'Pergerakan Terakhir'];
    final rows = _data.map((e) => [
      e['name'] ?? '-', e['sku'] ?? '-', e['unit'] ?? '-', 
      e['quantity'] ?? 0, _formatDateStr(e['lastMovement'])
    ]).toList();
    return _InventoryDataTable(
      title: 'Dead Stock', columns: columns, rows: rows, isLoading: _loading,
      onExportExcel: () => ExportService.exportToExcel('Dead Stock', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Dead Stock', columns, rows),
    );
  }
}

// 8: Nilai Inventori
class _ValuationReport extends StatefulWidget {
  final DateTime start; final DateTime end;
  const _ValuationReport({required this.start, required this.end});
  @override State<_ValuationReport> createState() => _ValuationReportState();
}
class _ValuationReportState extends State<_ValuationReport> {
  bool _loading = false; List<dynamic> _data = [];
  dynamic _summary;
  @override void initState() { super.initState(); _fetch(); }
  @override void didUpdateWidget(covariant _ValuationReport oldWidget) {
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _fetch();
    super.didUpdateWidget(oldWidget);
  }
  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/reports/inventory/valuation?start=${_dateStr(widget.start)}&end=${_dateStr(widget.end)}');
      if (mounted && res != null) setState(() { 
        _data = res['items'] ?? []; 
        _summary = res['summary'];
        _loading = false; 
      });
    } catch (e, stack) { if (mounted) setState(() => _loading = false); ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'load')); }
  }
  @override Widget build(BuildContext context) {
    final columns = ['Nama Item', 'Stok', 'Harga Beli Rata-rata', 'Total Nilai'];
    final rows = _data.map((e) => [
      e['name'] ?? '-', e['quantity'] ?? 0, 
      'Rp ${_fmt.format(_n(e['avgCostPrice']))}', 'Rp ${_fmt.format(_n(e['totalValue']))}'
    ]).toList();
    
    Widget? header;
    if (_summary != null) {
      header = Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Nilai Inventori', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Rp ${_fmt.format(_n(_summary['grandTotalValue']))}', 
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return _InventoryDataTable(
      title: 'Nilai Inventori', columns: columns, rows: rows, isLoading: _loading,
      headerWidget: header,
      onExportExcel: () => ExportService.exportToExcel('Nilai Inventori', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Nilai Inventori', columns, rows),
    );
  }
}
