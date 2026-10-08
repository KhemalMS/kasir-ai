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

class StaffReportScreen extends StatefulWidget {
  const StaffReportScreen({Key? key}) : super(key: key);

  @override
  State<StaffReportScreen> createState() => _StaffReportScreenState();
}

class _StaffReportScreenState extends State<StaffReportScreen> {
  int _selectedTab = 0;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<String> _tabs = [
    'Performa Kasir',
    'Jam Kerja',
    'Komisi Sales',
    'Log Aktivitas',
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
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_selectedTab != 3) // Tab 3 doesn't use date range
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
                      _TabPerformaKasir(startDate: _startDate, endDate: _endDate),
                      _TabJamKerja(startDate: _startDate, endDate: _endDate),
                      _TabKomisiSales(startDate: _startDate, endDate: _endDate),
                      const _TabLogAktivitas(),
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
class _StaffDataTable extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<List<dynamic>> rows;
  final bool isLoading;
  final VoidCallback? onExportExcel;
  final VoidCallback? onExportPdf;
  final Color? Function(int rowIndex)? rowColorBuilder;

  const _StaffDataTable({
    required this.title,
    required this.columns,
    required this.rows,
    required this.isLoading,
    this.onExportExcel,
    this.onExportPdf,
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
          children: const [
            Icon(Icons.people_outline, size: 64, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text('Tidak ada data', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
          ],
        ),
      );
    }

    // Convert rows into plain text list of lists for exporting
    final plainRows = rows.map((r) => r.map((c) {
      if (c is Widget) {
        return '-'; 
      }
      return c.toString();
    }).toList()).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onExportExcel != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.table_chart, size: 18),
                  label: const Text('Export Excel'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    ExportService.exportToExcel(title, columns, plainRows);
                  },
                ),
              const SizedBox(width: 8),
              if (onExportPdf != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                  onPressed: () {
                    ExportService.exportToPdf(context, title, columns, plainRows);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.surfaceDark),
                  dataRowColor: WidgetStateProperty.resolveWith((states) => AppTheme.cardDark),
                  border: TableBorder.all(color: AppTheme.surfaceDark, width: 1),
                  columns: columns.map((e) => DataColumn(label: Text(e, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))).toList(),
                  rows: List.generate(rows.length, (rowIndex) {
                    final row = rows[rowIndex];
                    final rowColor = rowColorBuilder?.call(rowIndex);
                    return DataRow(
                      color: WidgetStateProperty.all(rowColor ?? AppTheme.cardDark),
                      cells: row.map((cell) {
                        Widget child;
                        if (cell is Widget) {
                          child = cell;
                        } else {
                          child = Text(cell.toString(), style: const TextStyle(color: Colors.white));
                        }
                        return DataCell(child);
                      }).toList(),
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

// ─── TAB 0: Performa Kasir ──────────────────────────────────────────────
class _TabPerformaKasir extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabPerformaKasir({required this.startDate, required this.endDate});
  @override
  State<_TabPerformaKasir> createState() => _TabPerformaKasirState();
}
class _TabPerformaKasirState extends State<_TabPerformaKasir> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void didUpdateWidget(covariant _TabPerformaKasir oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) { _fetch(); }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/staff/performance?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cols = ['Nama Kasir', 'Jumlah Transaksi', 'Total Penjualan', 'Rata-rata Layanan', 'Error Rate'];
    final rows = _data.map((e) => [
      e['staffName'] ?? '-',
      _n(e['transactionCount']).toString(),
      'Rp ${_fmt.format(_n(e['totalSales']))}',
      '${(_n(e['avgServiceSeconds']) / 60).toStringAsFixed(1)} menit',
      '${_n(e['errorRate']).toStringAsFixed(1)}%',
    ]).toList();

    return _StaffDataTable(
      title: 'Performa Kasir',
      columns: cols,
      rows: rows,
      isLoading: _isLoading,
      onExportExcel: () {},
      onExportPdf: () {},
      rowColorBuilder: (idx) {
        final errorRate = _n(_data[idx]['errorRate']);
        if (errorRate > 10) return Colors.red.withOpacity(0.15);
        return null;
      },
    );
  }
}

// ─── TAB 1: Jam Kerja ───────────────────────────────────────────────────
class _TabJamKerja extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabJamKerja({required this.startDate, required this.endDate});
  @override
  State<_TabJamKerja> createState() => _TabJamKerjaState();
}
class _TabJamKerjaState extends State<_TabJamKerja> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void didUpdateWidget(covariant _TabJamKerja oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) { _fetch(); }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/staff/attendance?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cols = ['Nama Pegawai', 'Tanggal', 'Jam Masuk', 'Jam Keluar', 'Durasi', 'Status'];
    final rows = _data.map((e) {
      final durationMinutes = _n(e['durationMinutes']);
      final durationStr = '${(durationMinutes ~/ 60)}j ${(durationMinutes % 60).toInt()}m';
      
      String clockIn = '-';
      if (e['clockInTime'] != null) {
          clockIn = DateFormat('HH:mm').format(DateTime.parse(e['clockInTime']).toLocal());
      }
      String clockOut = '-';
      if (e['clockOutTime'] != null) {
          clockOut = DateFormat('HH:mm').format(DateTime.parse(e['clockOutTime']).toLocal());
      }
        
      return [
        e['staffName'] ?? '-',
        _formatDate(e['date']),
        clockIn,
        clockOut,
        durationStr,
        e['status'] ?? '-',
      ];
    }).toList();

    return _StaffDataTable(
      title: 'Jam Kerja & Absensi',
      columns: cols,
      rows: rows,
      isLoading: _isLoading,
      onExportExcel: () {},
      onExportPdf: () {},
      rowColorBuilder: (idx) {
        final status = _data[idx]['status'];
        if (status == 'late') return Colors.orange.withOpacity(0.15);
        if (status == 'absent') return Colors.red.withOpacity(0.15);
        return null;
      },
    );
  }
}

// ─── TAB 2: Komisi Sales ────────────────────────────────────────────────
class _TabKomisiSales extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabKomisiSales({required this.startDate, required this.endDate});
  @override
  State<_TabKomisiSales> createState() => _TabKomisiSalesState();
}
class _TabKomisiSalesState extends State<_TabKomisiSales> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void didUpdateWidget(covariant _TabKomisiSales oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) { _fetch(); }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/staff/commissions?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cols = ['Nama Pegawai', 'Total Penjualan', 'Tarif Komisi', 'Estimasi Komisi'];
    num totalKomisi = 0;
    
    final rows = _data.map((e) {
      totalKomisi += _n(e['commissionAmount']);
      return [
        e['staffName'] ?? '-',
        'Rp ${_fmt.format(_n(e['totalSales']))}',
        e['commissionRate'] ?? '-',
        'Rp ${_fmt.format(_n(e['commissionAmount']))}',
      ];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_isLoading && _data.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceDark),
              ),
              child: Column(
                children: [
                  const Text('Total Komisi Bulan Ini', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Rp ${_fmt.format(totalKomisi)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        Expanded(
          child: _StaffDataTable(
            title: 'Komisi Sales',
            columns: cols,
            rows: rows,
            isLoading: _isLoading,
            onExportExcel: () {},
            onExportPdf: () {},
          ),
        ),
      ],
    );
  }
}

// ─── TAB 3: Log Aktivitas ───────────────────────────────────────────────
class _TabLogAktivitas extends StatefulWidget {
  const _TabLogAktivitas();
  @override
  State<_TabLogAktivitas> createState() => _TabLogAktivitasState();
}
class _TabLogAktivitasState extends State<_TabLogAktivitas> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/staff/activity-logs');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cols = ['Waktu', 'Nama Pegawai', 'Aktivitas', 'Keterangan'];
    final rows = _data.map((e) {
      String timeStr = '-';
      if (e['createdAt'] != null) {
        timeStr = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(e['createdAt']).toLocal());
      }
      return [
        timeStr,
        e['staffName'] ?? '-',
        e['action'] ?? '-',
        e['description'] ?? '-',
      ];
    }).toList();

    return _StaffDataTable(
      title: 'Log Aktivitas',
      columns: cols,
      rows: rows,
      isLoading: _isLoading,
      onExportExcel: () {},
      onExportPdf: () {},
      rowColorBuilder: (idx) {
        final action = _data[idx]['action']?.toString() ?? '';
        if (action == 'LOGIN') return Colors.blue.withOpacity(0.1);
        if (action == 'VOID_ORDER') return Colors.red.withOpacity(0.15);
        if (action.startsWith('EDIT_')) return Colors.orange.withOpacity(0.1);
        return null;
      },
    );
  }
}
