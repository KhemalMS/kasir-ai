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

class CustomerReportScreen extends StatefulWidget {
  const CustomerReportScreen({Key? key}) : super(key: key);

  @override
  State<CustomerReportScreen> createState() => _CustomerReportScreenState();
}

class _CustomerReportScreenState extends State<CustomerReportScreen> {
  int _selectedTab = 0;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<String> _tabs = [
    'Data Pelanggan',
    'Paling Sering Beli',
    'Top Spender',
    'Analisis RFM',
    'Loyalty Poin',
    'Retensi Pelanggan',
    'Akuisisi Baru',
    'Ulang Tahun',
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
                      if (_selectedTab != 7) // Tab 7 doesn't use date range
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
                      _TabListPelanggan(startDate: _startDate, endDate: _endDate),
                      _TabTopFrequency(startDate: _startDate, endDate: _endDate),
                      _TabTopSpender(startDate: _startDate, endDate: _endDate),
                      _TabRFM(startDate: _startDate, endDate: _endDate),
                      _TabLoyalty(startDate: _startDate, endDate: _endDate),
                      _TabRetensi(startDate: _startDate, endDate: _endDate),
                      _TabAkuisisi(startDate: _startDate, endDate: _endDate),
                      const _TabUlangTahun(),
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
class _CustomerDataTable extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<List<dynamic>> rows;
  final bool isLoading;
  final VoidCallback? onExportExcel;
  final VoidCallback? onExportPdf;
  final Color? Function(int rowIndex)? rowColorBuilder;

  const _CustomerDataTable({
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
        return '-'; // or custom representation, though typically we format it before passing
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

// ─── UTILS ─────────────────────────────────────────────────────────────
Widget _buildTierBadge(String tier) {
  Color c;
  if (tier == 'Gold') c = Colors.amber;
  else if (tier == 'Silver') c = Colors.blueGrey;
  else c = Colors.brown[300] ?? Colors.brown;
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: c.withOpacity(0.2), 
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: c.withOpacity(0.5)),
    ),
    child: Text(tier, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
  );
}

// ─── TAB 0: Data Pelanggan ──────────────────────────────────────────────
class _TabListPelanggan extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabListPelanggan({required this.startDate, required this.endDate});
  @override
  State<_TabListPelanggan> createState() => _TabListPelangganState();
}
class _TabListPelangganState extends State<_TabListPelanggan> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void didUpdateWidget(covariant _TabListPelanggan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) { _fetch(); }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/customers/list?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cols = ['Nama', 'Telepon', 'Email', 'Bergabung', 'Total Transaksi', 'Total Belanja', 'Tier'];
    final rows = _data.map((e) => [
      e['name'] ?? '-',
      e['phone'] ?? '-',
      e['email'] ?? '-',
      _formatDate(e['createdAt']),
      _n(e['orderCount']).toString(),
      'Rp ${_fmt.format(_n(e['totalSpent']))}',
      _buildTierBadge(e['tier'] ?? 'Bronze'),
    ]).toList();

    return _CustomerDataTable(
      title: 'Data Pelanggan',
      columns: cols,
      rows: rows,
      isLoading: _isLoading,
      onExportExcel: () {},
      onExportPdf: () {},
    );
  }
}

// ─── TAB 1: Paling Sering Beli ──────────────────────────────────────────
class _TabTopFrequency extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabTopFrequency({required this.startDate, required this.endDate});
  @override
  State<_TabTopFrequency> createState() => _TabTopFrequencyState();
}
class _TabTopFrequencyState extends State<_TabTopFrequency> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void didUpdateWidget(covariant _TabTopFrequency oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) { _fetch(); }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/customers/top-frequency?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cols = ['No.', 'Nama', 'Telepon', 'Tier', 'Jumlah Transaksi'];
    final rows = _data.asMap().entries.map((entry) {
      int idx = entry.key;
      var e = entry.value;
      return [
        (idx + 1).toString(),
        e['name'] ?? '-',
        e['phone'] ?? '-',
        _buildTierBadge(e['tier'] ?? 'Bronze'),
        _n(e['orderCount']).toString(),
      ];
    }).toList();

    return _CustomerDataTable(
      title: 'Paling Sering Beli',
      columns: cols,
      rows: rows,
      isLoading: _isLoading,
      onExportExcel: () {},
      onExportPdf: () {},
    );
  }
}

// ─── TAB 2: Top Spender ─────────────────────────────────────────────────
class _TabTopSpender extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabTopSpender({required this.startDate, required this.endDate});
  @override
  State<_TabTopSpender> createState() => _TabTopSpenderState();
}
class _TabTopSpenderState extends State<_TabTopSpender> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void didUpdateWidget(covariant _TabTopSpender oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) { _fetch(); }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/customers/top-spender?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cols = ['No.', 'Nama', 'Telepon', 'Tier', 'Jumlah Transaksi', 'Total Belanja'];
    final rows = _data.asMap().entries.map((entry) {
      int idx = entry.key;
      var e = entry.value;
      return [
        (idx + 1).toString(),
        e['name'] ?? '-',
        e['phone'] ?? '-',
        _buildTierBadge(e['tier'] ?? 'Bronze'),
        _n(e['orderCount']).toString(),
        'Rp ${_fmt.format(_n(e['totalSpent']))}',
      ];
    }).toList();

    return _CustomerDataTable(
      title: 'Top Spender',
      columns: cols,
      rows: rows,
      isLoading: _isLoading,
      onExportExcel: () {},
      onExportPdf: () {},
    );
  }
}

// ─── TAB 3: Analisis RFM ────────────────────────────────────────────────
class _TabRFM extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabRFM({required this.startDate, required this.endDate});
  @override
  State<_TabRFM> createState() => _TabRFMState();
}
class _TabRFMState extends State<_TabRFM> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void didUpdateWidget(covariant _TabRFM oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) { _fetch(); }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/customers/rfm?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cols = ['Nama', 'Telepon', 'Recency (hari)', 'Frekuensi', 'Monetary'];
    final rows = _data.map((e) => [
      e['name'] ?? '-',
      e['phone'] ?? '-',
      _n(e['recencyDays']).toString(),
      _n(e['frequency']).toString(),
      'Rp ${_fmt.format(_n(e['monetary']))}',
    ]).toList();

    return _CustomerDataTable(
      title: 'Analisis RFM',
      columns: cols,
      rows: rows,
      isLoading: _isLoading,
      onExportExcel: () {},
      onExportPdf: () {},
      rowColorBuilder: (idx) {
        final recencyDays = _n(_data[idx]['recencyDays']);
        if (recencyDays <= 30) return Colors.green.withOpacity(0.2);
        if (recencyDays <= 90) return Colors.orange.withOpacity(0.2);
        return Colors.red.withOpacity(0.2);
      },
    );
  }
}

// ─── TAB 4: Loyalty Poin ────────────────────────────────────────────────
class _TabLoyalty extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabLoyalty({required this.startDate, required this.endDate});
  @override
  State<_TabLoyalty> createState() => _TabLoyaltyState();
}
class _TabLoyaltyState extends State<_TabLoyalty> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void didUpdateWidget(covariant _TabLoyalty oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) { _fetch(); }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/customers/loyalty?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cols = ['Nama', 'Telepon', 'Poin', 'Tier', 'Jumlah Order'];
    final rows = _data.map((e) => [
      e['name'] ?? '-',
      e['phone'] ?? '-',
      _fmt.format(_n(e['points'])),
      _buildTierBadge(e['tier'] ?? 'Bronze'),
      _n(e['orderCount']).toString(),
    ]).toList();

    return _CustomerDataTable(
      title: 'Loyalty Poin',
      columns: cols,
      rows: rows,
      isLoading: _isLoading,
      onExportExcel: () {},
      onExportPdf: () {},
      rowColorBuilder: (idx) {
        final tier = _data[idx]['tier'];
        if (tier == 'Gold') return Colors.amber.withOpacity(0.2);
        if (tier == 'Silver') return Colors.blueGrey.withOpacity(0.2);
        return null;
      },
    );
  }
}

// ─── TAB 5: Retensi Pelanggan ───────────────────────────────────────────
class _TabRetensi extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabRetensi({required this.startDate, required this.endDate});
  @override
  State<_TabRetensi> createState() => _TabRetensiState();
}
class _TabRetensiState extends State<_TabRetensi> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void didUpdateWidget(covariant _TabRetensi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) { _fetch(); }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/reports/customers/retention?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  Widget _buildCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 16)),
            const SizedBox(height: 16),
            Text(value, style: TextStyle(color: color, fontSize: 48, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_data == null) return const Center(child: Text('Gagal memuat data', style: TextStyle(color: Colors.white)));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCard('Retention Rate', '${_data!['retentionRatePct'] ?? 0}%', AppTheme.primary),
              const SizedBox(width: 16),
              _buildCard('Returning Customers', '${_n(_data!['returningCount'])}', AppTheme.success),
              const SizedBox(width: 16),
              _buildCard('One-Time Customers', '${_n(_data!['oneTimeCount'])}', AppTheme.warning),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── TAB 6: Akuisisi Baru ───────────────────────────────────────────────
class _TabAkuisisi extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const _TabAkuisisi({required this.startDate, required this.endDate});
  @override
  State<_TabAkuisisi> createState() => _TabAkuisisiState();
}
class _TabAkuisisiState extends State<_TabAkuisisi> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void didUpdateWidget(covariant _TabAkuisisi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) { _fetch(); }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/reports/customers/acquisition?start=${_dateStr(widget.startDate)}&end=${_dateStr(widget.endDate)}');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_data == null) return const Center(child: Text('Gagal memuat data', style: TextStyle(color: Colors.white)));

    final list = (_data!['dailyBreakdown'] as List?) ?? [];
    final cols = ['Tanggal', 'Pelanggan Baru'];
    final rows = list.map((e) => [
      _formatDate(e['date']),
      _n(e['newCustomers']).toString(),
    ]).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                const Text('Total Pelanggan Baru', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                const SizedBox(height: 8),
                Text('${_n(_data!['total'])}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        Expanded(
          child: _CustomerDataTable(
            title: 'Akuisisi Baru',
            columns: cols,
            rows: rows,
            isLoading: false,
            onExportExcel: () {},
            onExportPdf: () {},
          ),
        ),
      ],
    );
  }
}

// ─── TAB 7: Ulang Tahun ─────────────────────────────────────────────────
class _TabUlangTahun extends StatefulWidget {
  const _TabUlangTahun();
  @override
  State<_TabUlangTahun> createState() => _TabUlangTahunState();
}
class _TabUlangTahunState extends State<_TabUlangTahun> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getList('/reports/customers/birthdays');
      setState(() => _data = res);
    } catch (e, stack) { ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetch')); } 
    finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cols = ['Nama', 'Telepon', 'Tanggal Lahir', 'Tier'];
    final rows = _data.map((e) {
      final isThisMonth = e['isBirthdayThisMonth'] == true;
      return [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e['name'] ?? '-', style: const TextStyle(color: Colors.white)),
            if (isThisMonth) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.pink.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: const Text('🎂 Bulan Ini', style: TextStyle(color: Colors.pinkAccent, fontSize: 12)),
              ),
            ]
          ],
        ),
        e['phone'] ?? '-',
        _formatDate(e['birthdate']),
        _buildTierBadge(e['tier'] ?? 'Bronze'),
      ];
    }).toList();

    return _CustomerDataTable(
      title: 'Ulang Tahun',
      columns: cols,
      rows: rows,
      isLoading: _isLoading,
      onExportExcel: () {},
      onExportPdf: () {},
    );
  }
}
