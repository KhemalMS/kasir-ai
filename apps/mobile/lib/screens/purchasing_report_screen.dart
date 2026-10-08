import 'package:flutter/material.dart';
import '../services/error_notifier.dart';
import '../services/error_mapper.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

// Helper functions
num _n(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;
final _fmt = NumberFormat('#,###', 'id_ID');
String _dateStr(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String _formatDate(String? d) {
  if (d == null) return '-';
  try { return DateFormat('dd MMM yyyy').format(DateTime.parse(d).toLocal()); }
  catch(e) { return d; }
}

class PurchasingReportScreen extends StatefulWidget {
  const PurchasingReportScreen({super.key});

  @override
  State<PurchasingReportScreen> createState() => _PurchasingReportScreenState();
}

class _PurchasingReportScreenState extends State<PurchasingReportScreen> {
  int _selectedTab = 0;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<String> _tabs = [
    'Purchase Orders',
    'Pembelian per Supplier',
    'Retur Supplier',
    'Performa Supplier',
  ];

  Future<void> _selectDateRange() async {
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.bgDark,
      child: Row(
        children: [
          // Sidebar Kiri
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: AppTheme.cardDark,
              border: Border(right: BorderSide(color: AppTheme.surfaceDark)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTab == index;
                return ListTile(
                  title: Text(
                    _tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppTheme.primary.withOpacity(0.2),
                  onTap: () => setState(() => _selectedTab = index),
                );
              },
            ),
          ),
          // Panel Kanan
          Expanded(
            child: Column(
              children: [
                // Header Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceDark,
                    border: Border(bottom: BorderSide(color: AppTheme.surfaceDark)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _tabs[_selectedTab],
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.date_range, size: 18),
                        label: Text('${_dateStr(_startDate)}  s/d  ${_dateStr(_endDate)}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cardDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _selectDateRange,
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _TabPurchaseOrders(start: _startDate, end: _endDate),
                      _TabPembelianSupplier(start: _startDate, end: _endDate),
                      _TabReturSupplier(start: _startDate, end: _endDate),
                      _TabPerformaSupplier(start: _startDate, end: _endDate),
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

// Reusable DataTable Widget
class _PurchasingDataTable extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<List<dynamic>> rows;
  final bool isLoading;
  final VoidCallback? onExportExcel;
  final VoidCallback? onExportPdf;
  final Color? Function(int rowIndex)? rowColorBuilder;
  final Widget? summaryCard;

  const _PurchasingDataTable({
    required this.title,
    required this.columns,
    required this.rows,
    required this.isLoading,
    this.onExportExcel,
    this.onExportPdf,
    this.rowColorBuilder,
    this.summaryCard,
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
          children: const [
            Icon(Icons.local_shipping_outlined, size: 64, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text('Tidak ada data pembelian', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summaryCard != null) ...[
            summaryCard!,
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  if (onExportExcel != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.table_chart, size: 16),
                      label: const Text('Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onExportExcel,
                    ),
                  const SizedBox(width: 8),
                  if (onExportPdf != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onExportPdf,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceDark),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(AppTheme.surfaceDark),
                  border: TableBorder.all(color: AppTheme.surfaceDark),
                  columns: columns.map((c) => DataColumn(label: Text(c, style: const TextStyle(color: AppTheme.textMuted)))).toList(),
                  rows: List.generate(rows.length, (rowIndex) {
                    final row = rows[rowIndex];
                    final color = rowColorBuilder?.call(rowIndex);
                    return DataRow(
                      color: color != null ? MaterialStateProperty.all(color) : null,
                      cells: row.map((cell) => DataCell(Text(cell.toString(), style: const TextStyle(color: Colors.white)))).toList(),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 0: Purchase Orders ───────────────────────────────────────────
class _TabPurchaseOrders extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  const _TabPurchaseOrders({required this.start, required this.end});

  @override
  State<_TabPurchaseOrders> createState() => _TabPurchaseOrdersState();
}

class _TabPurchaseOrdersState extends State<_TabPurchaseOrders> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _TabPurchaseOrders oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final s = _dateStr(widget.start);
      final e = _dateStr(widget.end);
      final res = await ApiService.getList('/reports/purchasing/po?start=$s&end=$e');
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      ErrorNotifier.show(ErrorMapper.from(e, null, module: 'report', action: 'fetch'));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headers = ['Tanggal', 'No. PO', 'Supplier', 'Status', 'Nilai'];
    final rows = _data.map((e) {
      return [
        _formatDate(e['createdAt']),
        e['poNumber'] ?? '-',
        e['supplierName'] ?? '-',
        e['status'] ?? '-',
        'Rp ${_fmt.format(_n(e['totalAmount']))}',
      ];
    }).toList();

    return _PurchasingDataTable(
      title: 'Daftar Purchase Orders',
      columns: headers,
      rows: rows,
      isLoading: _isLoading,
      rowColorBuilder: (index) {
        final status = _data[index]['status'] ?? '';
        if (status == 'Pending')   return AppTheme.warning.withOpacity(0.12);
        if (status == 'Batal')     return AppTheme.danger.withOpacity(0.12);
        if (status == 'Diterima')  return AppTheme.success.withOpacity(0.12);
        return null;
      },
      onExportExcel: () => ExportService.exportToExcel('Laporan PO', headers, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Laporan PO', headers, rows),
    );
  }
}

// ─── TAB 1: Pembelian per Supplier ───────────────────────────────────────
class _TabPembelianSupplier extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  const _TabPembelianSupplier({required this.start, required this.end});

  @override
  State<_TabPembelianSupplier> createState() => _TabPembelianSupplierState();
}

class _TabPembelianSupplierState extends State<_TabPembelianSupplier> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _TabPembelianSupplier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final s = _dateStr(widget.start);
      final e = _dateStr(widget.end);
      final res = await ApiService.getList('/reports/purchasing/by-supplier?start=$s&end=$e');
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      ErrorNotifier.show(ErrorMapper.from(e, null, module: 'report', action: 'fetch'));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headers = ['Nama Supplier', 'Jml. Transaksi', 'Total Pembelian'];
    final rows = _data.map((e) {
      return [
        e['supplierName'] ?? '-',
        e['transactionCount'].toString(),
        'Rp ${_fmt.format(_n(e['totalAmount']))}',
      ];
    }).toList();

    num totalKeseluruhan = _data.fold(0, (sum, e) => sum + _n(e['totalAmount']));
    final summaryCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Pembelian Keseluruhan', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Text('Rp ${_fmt.format(totalKeseluruhan)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ]
      ),
    );

    return _PurchasingDataTable(
      title: 'Pembelian per Supplier',
      columns: headers,
      rows: rows,
      isLoading: _isLoading,
      summaryCard: summaryCard,
      onExportExcel: () => ExportService.exportToExcel('Pembelian Supplier', headers, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Pembelian Supplier', headers, rows),
    );
  }
}

// ─── TAB 2: Retur Supplier ───────────────────────────────────────────
class _TabReturSupplier extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  const _TabReturSupplier({required this.start, required this.end});

  @override
  State<_TabReturSupplier> createState() => _TabReturSupplierState();
}

class _TabReturSupplierState extends State<_TabReturSupplier> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _TabReturSupplier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final s = _dateStr(widget.start);
      final e = _dateStr(widget.end);
      final res = await ApiService.getList('/reports/purchasing/returns?start=$s&end=$e');
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      ErrorNotifier.show(ErrorMapper.from(e, null, module: 'report', action: 'fetch'));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headers = ['Tanggal', 'No. Retur', 'Supplier', 'Alasan', 'Nilai Retur'];
    final rows = _data.map((e) {
      return [
        _formatDate(e['createdAt']),
        e['returnNumber'] ?? '-',
        e['supplierName'] ?? '-',
        e['reason'] ?? '-',
        'Rp ${_fmt.format(_n(e['totalAmount']))}',
      ];
    }).toList();

    num totalKeseluruhan = _data.fold(0, (sum, e) => sum + _n(e['totalAmount']));
    final summaryCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Nilai Retur', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Text('Rp ${_fmt.format(totalKeseluruhan)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ]
      ),
    );

    return _PurchasingDataTable(
      title: 'Daftar Retur Supplier',
      columns: headers,
      rows: rows,
      isLoading: _isLoading,
      summaryCard: summaryCard,
      onExportExcel: () => ExportService.exportToExcel('Retur Supplier', headers, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Retur Supplier', headers, rows),
    );
  }
}

// ─── TAB 3: Performa Supplier ─────────────────────────────────────────
class _TabPerformaSupplier extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  const _TabPerformaSupplier({required this.start, required this.end});

  @override
  State<_TabPerformaSupplier> createState() => _TabPerformaSupplierState();
}

class _TabPerformaSupplierState extends State<_TabPerformaSupplier> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _TabPerformaSupplier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final s = _dateStr(widget.start);
      final e = _dateStr(widget.end);
      final res = await ApiService.getList('/reports/purchasing/performance?start=$s&end=$e');
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      ErrorNotifier.show(ErrorMapper.from(e, null, module: 'report', action: 'fetch'));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headers = ['Nama Supplier', 'Total PO', 'Total Retur', 'Tingkat Retur (%)'];
    final rows = _data.map((e) {
      return [
        e['supplierName'] ?? '-',
        e['totalPoCount'].toString(),
        e['totalReturnCount'].toString(),
        '${_n(e['returnRate']).toStringAsFixed(1)} %',
      ];
    }).toList();

    return _PurchasingDataTable(
      title: 'Performa Supplier',
      columns: headers,
      rows: rows,
      isLoading: _isLoading,
      rowColorBuilder: (index) {
        final rate = _n(_data[index]['returnRate']);
        if (rate >= 20) return AppTheme.danger.withOpacity(0.12);
        if (rate >= 10) return AppTheme.warning.withOpacity(0.12);
        return AppTheme.success.withOpacity(0.08);
      },
      onExportExcel: () => ExportService.exportToExcel('Performa Supplier', headers, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Performa Supplier', headers, rows),
    );
  }
}
