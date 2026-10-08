import 'package:flutter/material.dart';
import '../services/error_notifier.dart';
import '../services/error_mapper.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

num _n(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;
final _fmt = NumberFormat('#,###', 'id_ID');
String _dateStr(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String _formatDate(String? d) {
  if (d == null) return '-';
  try { return DateFormat('dd MMM yyyy').format(DateTime.parse(d).toLocal()); }
  catch(e) { return d; }
}

class TaxReportScreen extends StatefulWidget {
  const TaxReportScreen({Key? key}) : super(key: key);

  @override
  State<TaxReportScreen> createState() => _TaxReportScreenState();
}

class _TaxReportScreenState extends State<TaxReportScreen> {
  int _selectedTab = 0;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<String> _tabs = [
    'Ringkasan PPN',
    'Faktur Pajak',
    'Rekap Bulanan',
  ];

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.cardDark,
              onSurface: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Kiri
          Container(
            width: 220,
            color: AppTheme.cardDark,
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
                  color: AppTheme.surfaceDark,
                  child: Row(
                    children: [
                      Text(
                        _tabs[_selectedTab],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range, color: Colors.white, size: 18),
                        label: Text(
                          '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.textMuted),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _selectDateRange,
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _TabRingkasanPpn(startDate: _startDate, endDate: _endDate),
                      _TabFakturPajak(startDate: _startDate, endDate: _endDate),
                      _TabRekapBulanan(startDate: _startDate, endDate: _endDate),
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

class _TaxDataTable extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<List<dynamic>> rows;
  final bool isLoading;
  final VoidCallback? onExportExcel;
  final VoidCallback? onExportPdf;
  final Color? Function(int rowIndex)? rowColorBuilder;
  final Widget? summaryCard;

  const _TaxDataTable({
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
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada data pajak',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
                      onPressed: onExportExcel,
                    ),
                  const SizedBox(width: 8),
                  if (onExportPdf != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('PDF'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
                      onPressed: onExportPdf,
                    ),
                ],
              )
            ],
          ),
          if (summaryCard != null) ...[
            const SizedBox(height: 16),
            summaryCard!,
          ],
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.surfaceDark),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppTheme.surfaceDark),
                border: TableBorder.all(color: AppTheme.surfaceDark),
                columns: columns.map((c) => DataColumn(label: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                rows: rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  return DataRow(
                    color: rowColorBuilder != null ? MaterialStateProperty.all(rowColorBuilder!(index)) : null,
                    cells: row.map((cell) => DataCell(Text(cell.toString(), style: const TextStyle(color: Colors.white)))).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabRingkasanPpn extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabRingkasanPpn({required this.startDate, required this.endDate});
  @override
  State<_TabRingkasanPpn> createState() => _TabRingkasanPpnState();
}

class _TabRingkasanPpnState extends State<_TabRingkasanPpn> {
  bool _isLoading = false;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _TabRingkasanPpn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/tax/ppn?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = ['Tanggal', 'Jml. Transaksi', 'DPP (Subtotal)', 'PPN', 'Total'];
    num totalPpn = 0;
    final rows = _data.map((e) {
      totalPpn += _n(e['totalTax']);
      return [
        _formatDate(e['date']),
        e['transactionCount'].toString(),
        'Rp ${_fmt.format(_n(e['totalSubtotal']))}',
        'Rp ${_fmt.format(_n(e['totalTax']))}',
        'Rp ${_fmt.format(_n(e['totalAmount']))}',
      ];
    }).toList();

    return _TaxDataTable(
      title: 'Ringkasan PPN',
      columns: columns,
      rows: rows,
      isLoading: _isLoading,
      summaryCard: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total PPN Terkumpul', style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Text('Rp ${_fmt.format(totalPpn)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      onExportExcel: () => ExportService.exportToExcel('Ringkasan PPN', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Ringkasan PPN', columns, rows),
    );
  }
}

class _TabFakturPajak extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabFakturPajak({required this.startDate, required this.endDate});
  @override
  State<_TabFakturPajak> createState() => _TabFakturPajakState();
}

class _TabFakturPajakState extends State<_TabFakturPajak> {
  bool _isLoading = false;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _TabFakturPajak oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/tax/invoices?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = ['Tanggal', 'No. Transaksi', 'No. Seri Faktur', 'DPP', 'PPN', 'Total'];
    final rows = _data.map((e) {
      return [
        DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(e['createdAt']).toLocal()),
        e['orderNumber'].toString(),
        e['taxInvoiceNumber'] ?? '-',
        'Rp ${_fmt.format(_n(e['subtotal']))}',
        'Rp ${_fmt.format(_n(e['taxAmount']))}',
        'Rp ${_fmt.format(_n(e['totalAmount']))}',
      ];
    }).toList();

    return _TaxDataTable(
      title: 'Faktur Pajak',
      columns: columns,
      rows: rows,
      isLoading: _isLoading,
      rowColorBuilder: (index) {
        final val = _data[index]['taxInvoiceNumber'];
        if (val == null || val.toString().trim().isEmpty) {
          return Colors.orange.withOpacity(0.1);
        }
        return null;
      },
      onExportExcel: () => ExportService.exportToExcel('Faktur Pajak', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Faktur Pajak', columns, rows),
    );
  }
}

class _TabRekapBulanan extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabRekapBulanan({required this.startDate, required this.endDate});
  @override
  State<_TabRekapBulanan> createState() => _TabRekapBulananState();
}

class _TabRekapBulananState extends State<_TabRekapBulanan> {
  bool _isLoading = false;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _TabRekapBulanan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/tax/summary?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = ['Bulan', 'Jml. Transaksi', 'Total DPP', 'Total PPN', 'Total Nilai'];
    num totalPpn = 0;
    final rows = _data.map((e) {
      totalPpn += _n(e['totalTax']);
      final monthParts = (e['month'] as String).split('-');
      final monthDate = DateTime(int.parse(monthParts[0]), int.parse(monthParts[1]));
      final monthStr = DateFormat('MMMM yyyy', 'id_ID').format(monthDate);
      return [
        monthStr,
        e['transactionCount'].toString(),
        'Rp ${_fmt.format(_n(e['totalSubtotal']))}',
        'Rp ${_fmt.format(_n(e['totalTax']))}',
        'Rp ${_fmt.format(_n(e['totalAmount']))}',
      ];
    }).toList();

    return _TaxDataTable(
      title: 'Rekap Bulanan',
      columns: columns,
      rows: rows,
      isLoading: _isLoading,
      summaryCard: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Kewajiban PPN', style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Text('Rp ${_fmt.format(totalPpn)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      onExportExcel: () => ExportService.exportToExcel('Rekap Bulanan', columns, rows),
      onExportPdf: () => ExportService.exportToPdf(context, 'Rekap Bulanan', columns, rows),
    );
  }
}
